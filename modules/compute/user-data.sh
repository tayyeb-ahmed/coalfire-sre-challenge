#!/bin/bash
# Web server setup script
# Installing Apache and setting up a basic page

# Update packages first
dnf update -y

# Install Apache web server
dnf install -y httpd

# Start Apache and make sure it starts on boot
systemctl start httpd
systemctl enable httpd

# Create a basic landing page
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Coalfire SRE Challenge</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px; 
            background-color: #f5f5f5; 
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            background: white; 
            padding: 30px; 
            border-radius: 10px; 
            box-shadow: 0 2px 10px rgba(0,0,0,0.1); 
        }
        h1 { color: #2c3e50; }
        .info { 
            background: #ecf0f1; 
            padding: 15px; 
            border-radius: 5px; 
            margin: 20px 0; 
        }
        .status { color: #27ae60; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Coalfire SRE Challenge Demo</h1>
        <div class="info">
            <p><strong>Project:</strong> ${project_name}</p>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>AZ:</strong> <span id="az">Loading...</span></p>
            <p><strong>Status:</strong> <span class="status">Web Server Online</span></p>
        </div>
        
        <h2>What's Running Here</h2>
        <ul>
            <li>VPC with 3-tier subnets (mgmt, app, backend)</li>
            <li>Auto Scaling Group (2-6 instances)</li>
            <li>Application Load Balancer</li>
            <li>Security groups with restricted access</li>
            <li>Management bastion host</li>
        </ul>
        
        <h2>Security Setup</h2>
        <ul>
            <li>Private app subnets (no direct internet)</li>
            <li>SSH only from management box</li>
            <li>Web traffic only from ALB</li>
            <li>Network ACLs for defense in depth</li>
        </ul>
        
        <p><em>Built with Terraform • $(date)</em></p>
    </div>

    <script>
        // Get instance metadata from AWS
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(error => document.getElementById('instance-id').textContent = 'N/A');

        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(response => response.text())
            .then(data => document.getElementById('az').textContent = data)
            .catch(error => document.getElementById('az').textContent = 'N/A');
    </script>
</body>
</html>
EOF

# Simple health check endpoint for the ALB
cat > /var/www/html/health << EOF
OK
EOF

# Install CloudWatch agent - useful for monitoring
dnf install -y amazon-cloudwatch-agent

# Basic CloudWatch config - keeping it simple for now
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/httpd/access_log",
                        "log_group_name": "/aws/ec2/${project_name}/apache/access",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/httpd/error_log",
                        "log_group_name": "/aws/ec2/${project_name}/apache/error",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    }
}
EOF

# Start the CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Make sure Apache is still running
systemctl restart httpd

# Log that we're done
echo "$(date): Web server setup completed" >> /var/log/user-data.log
