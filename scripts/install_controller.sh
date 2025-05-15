#!/bin/bash
# OpenStack Controller Node Installation Script
# This script installs and configures a controller node for OpenStack
# Based on Ubuntu Server 22.04 LTS

set -e

# Configuration variables - modify these according to your environment
CONTROLLER_IP="192.168.1.10"
CONTROLLER_HOSTNAME="controller"
ADMIN_PASS="ADMIN_PASS"
MARIADB_PASS="openstack"
RABBIT_PASS="openstack"
KEYSTONE_DBPASS="openstack"
GLANCE_DBPASS="openstack"
NOVA_DBPASS="openstack"
NEUTRON_DBPASS="openstack"
CINDER_DBPASS="openstack"
DOMAIN_NAME="example.com"

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
echo_progress "Setting hostname to $CONTROLLER_HOSTNAME..."
hostnamectl set-hostname $CONTROLLER_HOSTNAME
echo "$CONTROLLER_IP $CONTROLLER_HOSTNAME" >> /etc/hosts

# Install NTP for time synchronization
echo_progress "Installing and configuring NTP..."
apt install -y chrony
sed -i 's/pool .*/server 0.pool.ntp.org iburst\nserver 1.pool.ntp.org iburst/g' /etc/chrony/chrony.conf
systemctl restart chrony

# Install and configure MariaDB
echo_progress "Installing MariaDB..."
apt install -y mariadb-server
cat > /etc/mysql/mariadb.conf.d/99-openstack.cnf << EOF
[mysqld]
bind-address = $CONTROLLER_IP
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 500
collation-server = utf8_general_ci
character-set-server = utf8
EOF

systemctl restart mariadb

# Secure MariaDB installation
echo_progress "Securing MariaDB installation..."
mysql -e "UPDATE mysql.user SET Password=PASSWORD('$MARIADB_PASS') WHERE User='root';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "FLUSH PRIVILEGES;"

# Install RabbitMQ
echo_progress "Installing RabbitMQ..."
apt install -y rabbitmq-server
rabbitmqctl add_user openstack $RABBIT_PASS
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

# Install Memcached
echo_progress "Installing Memcached..."
apt install -y memcached python3-memcache
sed -i "s/-l 127.0.0.1/-l $CONTROLLER_IP/g" /etc/memcached.conf
systemctl restart memcached

# Install and configure Keystone (Identity Service)
echo_progress "Installing Keystone (Identity Service)..."
mysql -u root -p$MARIADB_PASS -e "CREATE DATABASE keystone;"
mysql -u root -p$MARIADB_PASS -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS';"
mysql -u root -p$MARIADB_PASS -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';"

apt install -y keystone python3-openstackclient apache2 libapache2-mod-wsgi-py3

cat > /etc/keystone/keystone.conf << EOF
[database]
connection = mysql+pymysql://keystone:$KEYSTONE_DBPASS@$CONTROLLER_HOSTNAME/keystone

[token]
provider = fernet
EOF

su -s /bin/bash keystone -c "keystone-manage db_sync"
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

keystone-manage bootstrap --bootstrap-password $ADMIN_PASS \
  --bootstrap-admin-url http://$CONTROLLER_HOSTNAME:5000/v3/ \
  --bootstrap-internal-url http://$CONTROLLER_HOSTNAME:5000/v3/ \
  --bootstrap-public-url http://$CONTROLLER_HOSTNAME:5000/v3/ \
  --bootstrap-region-id RegionOne

# Configure Apache for Keystone
echo "ServerName $CONTROLLER_HOSTNAME" >> /etc/apache2/apache2.conf
systemctl restart apache2

# Create OpenStack environment script
echo_progress "Creating OpenStack environment script..."
cat > /root/admin-openrc << EOF
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://$CONTROLLER_HOSTNAME:5000/v3
export OS_IDENTITY_API_VERSION=3
EOF

# Source the admin credentials
echo_progress "Setting up admin credentials..."
source /root/admin-openrc

# Install and configure Glance (Image Service)
echo_progress "Installing Glance (Image Service)..."
mysql -u root -p$MARIADB_PASS -e "CREATE DATABASE glance;"
mysql -u root -p$MARIADB_PASS -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$GLANCE_DBPASS';"
mysql -u root -p$MARIADB_PASS -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$GLANCE_DBPASS';"

openstack user create --domain default --password $GLANCE_DBPASS glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image

openstack endpoint create --region RegionOne image public http://$CONTROLLER_HOSTNAME:9292
openstack endpoint create --region RegionOne image internal http://$CONTROLLER_HOSTNAME:9292
openstack endpoint create --region RegionOne image admin http://$CONTROLLER_HOSTNAME:9292

apt install -y glance

cat > /etc/glance/glance-api.conf << EOF
[database]
connection = mysql+pymysql://glance:$GLANCE_DBPASS@$CONTROLLER_HOSTNAME/glance

[keystone_authtoken]
www_authenticate_uri = http://$CONTROLLER_HOSTNAME:5000
auth_url = http://$CONTROLLER_HOSTNAME:5000
memcached_servers = $CONTROLLER_HOSTNAME:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = $GLANCE_DBPASS

[paste_deploy]
flavor = keystone

[glance_store]
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/
EOF

su -s /bin/bash glance -c "glance-manage db_sync"
systemctl restart glance-api

# Set up Nova on the controller node
echo_progress "Setting up Nova (Compute Service) on controller node..."
mysql -u root -p$MARIADB_PASS -e "CREATE DATABASE nova_api;"
mysql -u root -p$MARIADB_PASS -e "CREATE DATABASE nova;"
mysql -u root -p$MARIADB_PASS -e "CREATE DATABASE nova_cell0;"

mysql -u root -p$MARIADB_PASS -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS';"
mysql -u root -p$MARIADB_PASS -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS';"
mysql -u root -p$MARIADB_PASS -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS';"
mysql -u root -p$MARIADB_PASS -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS';"
mysql -u root -p$MARIADB_PASS -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS';"
mysql -u root -p$MARIADB_PASS -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS';"

# Create Nova user and service
openstack user create --domain default --password $NOVA_DBPASS nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute

# Create Nova endpoints
openstack endpoint create --region RegionOne compute public http://$CONTROLLER_HOSTNAME:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://$CONTROLLER_HOSTNAME:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://$CONTROLLER_HOSTNAME:8774/v2.1

# Install Nova packages
apt install -y nova-api nova-conductor nova-novncproxy nova-scheduler

# Setup Horizon (Dashboard)
echo_progress "Setting up Horizon (Dashboard)..."
apt install -y openstack-dashboard

# Configure Horizon
cat > /etc/openstack-dashboard/local_settings.py << EOF
import os
from django.utils.translation import ugettext_lazy as _
from horizon.utils import secret_key
from openstack_dashboard.settings import HORIZON_CONFIG
DEBUG = False
LOCAL_PATH = os.path.dirname(os.path.abspath(__file__))
SECRET_KEY = secret_key.generate_or_read_from_file('/var/lib/openstack-dashboard/secret_key')
ALLOWED_HOSTS = ['*']
WEBROOT = '/dashboard/'
LOGIN_URL = '/dashboard/auth/login/'
LOGOUT_URL = '/dashboard/auth/logout/'
LOGIN_REDIRECT_URL = '/dashboard/'
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 3,
}
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST
OPENSTACK_HOST = "$CONTROLLER_HOSTNAME"
OPENSTACK_NEUTRON_NETWORK = {
    'enable_router': True,
    'enable_quotas': True,
    'enable_distributed_router': False,
    'enable_ha_router': False,
    'enable_lb': True,
    'enable_firewall': True,
    'enable_vpn': True,
    'enable_fip_topology_check': True,
}
TIME_ZONE = "UTC"
EOF

systemctl reload apache2.service

echo_progress "Controller node setup completed successfully!"
echo "Access Horizon Dashboard at: http://$CONTROLLER_IP/dashboard"
echo "Username: admin"
echo "Password: $ADMIN_PASS"
