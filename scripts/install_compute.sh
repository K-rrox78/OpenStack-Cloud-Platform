#!/bin/bash
# OpenStack Compute Node Installation Script
# This script installs and configures a compute node for OpenStack
# Based on Ubuntu Server 22.04 LTS

set -e

# Configuration variables - modify these according to your environment
COMPUTE_IP="192.168.1.11"
COMPUTE_HOSTNAME="compute1"
CONTROLLER_IP="192.168.1.10"
CONTROLLER_HOSTNAME="controller"
RABBIT_PASS="openstack"
NOVA_PASS="openstack"
NEUTRON_PASS="openstack"

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to display progress
function echo_progress {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or with sudo"
    exit 1
fi

# Update system packages
echo_progress "Updating system packages..."
apt update && apt upgrade -y

# Set correct hostname
echo_progress "Setting hostname to $COMPUTE_HOSTNAME..."
hostnamectl set-hostname $COMPUTE_HOSTNAME
echo "$COMPUTE_IP $COMPUTE_HOSTNAME" >> /etc/hosts
echo "$CONTROLLER_IP $CONTROLLER_HOSTNAME" >> /etc/hosts

# Install NTP for time synchronization
echo_progress "Installing and configuring NTP..."
apt install -y chrony
sed -i 's/pool .*/server '$CONTROLLER_HOSTNAME' iburst/g' /etc/chrony/chrony.conf
systemctl restart chrony

# Install and configure Nova Compute
echo_progress "Installing Nova Compute..."
apt install -y nova-compute

# Configure Nova
cat > /etc/nova/nova.conf << EOF
[DEFAULT]
transport_url = rabbit://openstack:$RABBIT_PASS@$CONTROLLER_HOSTNAME
my_ip = $COMPUTE_IP
use_neutron = true
firewall_driver = nova.virt.firewall.NoopFirewallDriver

[api]
auth_strategy = keystone

[keystone_authtoken]
www_authenticate_uri = http://$CONTROLLER_HOSTNAME:5000/
auth_url = http://$CONTROLLER_HOSTNAME:5000/
memcached_servers = $CONTROLLER_HOSTNAME:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = $NOVA_PASS

[vnc]
enabled = true
server_listen = 0.0.0.0
server_proxyclient_address = $COMPUTE_IP
novncproxy_base_url = http://$CONTROLLER_HOSTNAME:6080/vnc_auto.html

[glance]
api_servers = http://$CONTROLLER_HOSTNAME:9292

[oslo_concurrency]
lock_path = /var/lib/nova/tmp

[placement]
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://$CONTROLLER_HOSTNAME:5000/v3
username = placement
password = $NOVA_PASS
EOF

# Check if KVM virtualization is supported
if egrep -c '(vmx|svm)' /proc/cpuinfo > 0; then
    echo_progress "KVM virtualization is supported"
else
    echo_progress "KVM virtualization is not supported. Using QEMU instead..."
    sed -i 's/virt_type=kvm/virt_type=qemu/g' /etc/nova/nova-compute.conf
fi

# Restart the compute service
echo_progress "Restarting Nova Compute service..."
systemctl restart nova-compute

# Install and configure Neutron (OpenStack Networking)
echo_progress "Installing Neutron (Networking)..."
apt install -y neutron-linuxbridge-agent

# Configure Neutron
cat > /etc/neutron/neutron.conf << EOF
[DEFAULT]
transport_url = rabbit://openstack:$RABBIT_PASS@$CONTROLLER_HOSTNAME
auth_strategy = keystone

[keystone_authtoken]
www_authenticate_uri = http://$CONTROLLER_HOSTNAME:5000
auth_url = http://$CONTROLLER_HOSTNAME:5000
memcached_servers = $CONTROLLER_HOSTNAME:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = $NEUTRON_PASS

[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
EOF

# Configure Linux Bridge Agent
cat > /etc/neutron/plugins/ml2/linuxbridge_agent.ini << EOF
[linux_bridge]
physical_interface_mappings = provider:eth0

[vxlan]
enable_vxlan = true
local_ip = $COMPUTE_IP
l2_population = true

[securitygroup]
enable_security_group = true
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
EOF

# Configure sysctl for network forwarding
cat > /etc/sysctl.conf << EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl -p

# Configure Nova to use Neutron
cat >> /etc/nova/nova.conf << EOF
[neutron]
auth_url = http://$CONTROLLER_HOSTNAME:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = $NEUTRON_PASS
EOF

# Restart all the services
echo_progress "Restarting all services..."
systemctl restart nova-compute
systemctl restart neutron-linuxbridge-agent

echo_progress "Compute node setup completed successfully!"
echo "This compute node ($COMPUTE_HOSTNAME) is now registered with the OpenStack controller."
echo "To verify the setup, on the controller node, run: 'openstack compute service list --service nova-compute'"
