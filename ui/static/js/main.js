// OpenStack Cloud Platform - Main JavaScript file

// Wait for the DOM to be fully loaded
document.addEventListener('DOMContentLoaded', function() {
    
    // VM Type selection handling in the deployment form
    const vmTypeSelect = document.getElementById('vm_type');
    const linuxOptions = document.getElementById('linux_options');
    const windowsOptions = document.getElementById('windows_options');
    
    if (vmTypeSelect && linuxOptions && windowsOptions) {
        vmTypeSelect.addEventListener('change', function() {
            if (this.value === 'linux') {
                linuxOptions.style.display = 'block';
                windowsOptions.style.display = 'none';
            } else if (this.value === 'windows') {
                linuxOptions.style.display = 'none';
                windowsOptions.style.display = 'block';
            }
        });
    }
    
    // Auto-refresh for deployment status page
    const deploymentStatusTable = document.getElementById('deployment-status-table');
    if (deploymentStatusTable) {
        // Refresh deployment status every 30 seconds
        setInterval(function() {
            fetchDeploymentStatus();
        }, 30000);
    }
    
    // Dashboard stats animations
    const statNumbers = document.querySelectorAll('.stat-number');
    if (statNumbers.length > 0) {
        statNumbers.forEach(function(statEl) {
            const targetValue = parseInt(statEl.getAttribute('data-value'));
            animateValue(statEl, 0, targetValue, 1500);
        });
    }
});

// Function to animate counting up for statistics
function animateValue(obj, start, end, duration) {
    let startTimestamp = null;
    const step = (timestamp) => {
        if (!startTimestamp) startTimestamp = timestamp;
        const progress = Math.min((timestamp - startTimestamp) / duration, 1);
        obj.innerHTML = Math.floor(progress * (end - start) + start);
        if (progress < 1) {
            window.requestAnimationFrame(step);
        }
    };
    window.requestAnimationFrame(step);
}

// Function to fetch deployment status from the API
function fetchDeploymentStatus() {
    fetch('/api/vms')
        .then(response => response.json())
        .then(data => {
            updateDeploymentTable(data);
        })
        .catch(error => {
            console.error('Error fetching deployment status:', error);
        });
}

// Function to update the deployment status table
function updateDeploymentTable(vms) {
    const tableBody = document.querySelector('#deployment-status-table tbody');
    if (!tableBody) return;
    
    // Clear existing rows
    tableBody.innerHTML = '';
    
    // Add new rows
    vms.forEach(vm => {
        const row = document.createElement('tr');
        
        // Create status class based on VM status
        let statusClass = '';
        if (vm.status === 'ACTIVE') {
            statusClass = 'status-running';
        } else if (vm.status === 'BUILDING') {
            statusClass = 'status-deploying';
        } else if (vm.status === 'ERROR') {
            statusClass = 'status-error';
        }
        
        row.innerHTML = `
            <td>${vm.id}</td>
            <td>${vm.name}</td>
            <td class="${statusClass}">${vm.status}</td>
            <td>${vm.ip}</td>
            <td>${vm.type}</td>
            <td>
                <button class="btn btn-sm btn-primary">Details</button>
                <button class="btn btn-sm btn-danger">Supprimer</button>
            </td>
        `;
        
        tableBody.appendChild(row);
    });
}
