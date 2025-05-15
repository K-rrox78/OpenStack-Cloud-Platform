#!/usr/bin/env python3
# OpenStack Cloud Platform - Web UI
# Flask application for deploying and managing OpenStack VMs

from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
import os
import requests
import json
import yaml
import subprocess
from datetime import datetime

app = Flask(__name__)
app.secret_key = os.urandom(24)

# Configuration
OPENSTACK_AUTH_URL = "http://controller:5000/v3"
OPENSTACK_USER = "admin"
OPENSTACK_PASSWORD = "ADMIN_PASS"  # Should be in a secure config file
OPENSTACK_PROJECT = "admin"
OPENSTACK_DOMAIN = "Default"

# VM Configuration Templates
LINUX_FLAVORS = {
    "small": {"name": "m1.small", "ram": 2048, "vcpus": 1, "disk": 20},
    "medium": {"name": "m1.medium", "ram": 4096, "vcpus": 2, "disk": 40},
    "large": {"name": "m1.large", "ram": 8192, "vcpus": 4, "disk": 80}
}

WINDOWS_FLAVORS = {
    "small": {"name": "w1.small", "ram": 4096, "vcpus": 2, "disk": 40},
    "medium": {"name": "w1.medium", "ram": 8192, "vcpus": 4, "disk": 80},
    "large": {"name": "w1.large", "ram": 16384, "vcpus": 8, "disk": 160}
}

LINUX_IMAGES = [
    {"name": "Ubuntu 22.04", "id": "ubuntu-22.04"},
    {"name": "AlmaLinux 9", "id": "almalinux-9"},
    {"name": "Debian 12", "id": "debian-12"}
]

WINDOWS_IMAGES = [
    {"name": "Windows Server 2016", "id": "win-server-2016"},
    {"name": "Windows Server 2019", "id": "win-server-2019"}
]

# Routes
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/dashboard')
def dashboard():
    # In a real implementation, this would fetch data from OpenStack APIs
    vm_stats = {
        "total": 60,
        "running": 45,
        "stopped": 15,
        "linux": 30,
        "windows": 30
    }
    return render_template('dashboard.html', stats=vm_stats)

@app.route('/deploy', methods=['GET', 'POST'])
def deploy():
    if request.method == 'POST':
        # Get form data
        vm_name = request.form.get('vm_name')
        vm_type = request.form.get('vm_type')
        vm_flavor = request.form.get('vm_flavor')
        vm_image = request.form.get('vm_image')
        vm_count = int(request.form.get('vm_count', 1))
        
        # This would call OpenStack APIs or run Ansible/Terraform scripts
        flash(f"Deploying {vm_count} {vm_type} VM(s) with {vm_flavor} flavor using {vm_image} image")
        return redirect(url_for('deployment_status'))
    
    return render_template('deploy.html', 
                          linux_flavors=LINUX_FLAVORS, 
                          windows_flavors=WINDOWS_FLAVORS,
                          linux_images=LINUX_IMAGES,
                          windows_images=WINDOWS_IMAGES)

@app.route('/deployment_status')
def deployment_status():
    # In a real implementation, this would check the status of deployments
    deployments = [
        {"id": 1, "name": "Ubuntu-VM-1", "status": "Running", "ip": "192.168.1.101"},
        {"id": 2, "name": "Ubuntu-VM-2", "status": "Deploying", "ip": "Pending"},
        {"id": 3, "name": "Windows-VM-1", "status": "Running", "ip": "192.168.1.201"}
    ]
    return render_template('deployment_status.html', deployments=deployments)

@app.route('/api/vms', methods=['GET'])
def get_vms():
    # This would use the OpenStack API to get VM data
    # Mocked data for demonstration
    vms = [
        {"id": 1, "name": "Ubuntu-VM-1", "status": "ACTIVE", "ip": "192.168.1.101", "type": "Linux"},
        {"id": 2, "name": "Ubuntu-VM-2", "status": "BUILDING", "ip": "Pending", "type": "Linux"},
        {"id": 3, "name": "Windows-VM-1", "status": "ACTIVE", "ip": "192.168.1.201", "type": "Windows"}
    ]
    return jsonify(vms)

@app.route('/api/deploy', methods=['POST'])
def api_deploy():
    data = request.get_json()
    # This would call Ansible or Terraform to deploy VMs
    # For now, we just return a success message
    return jsonify({"status": "deploying", "message": "Deployment started"})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
