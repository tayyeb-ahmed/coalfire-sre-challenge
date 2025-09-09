#!/bin/bash
# Mgmt/bastion host setup
# Installing useful tools and setting up access to app servers

# Update everything first
dnf update -y

# Install the usual suspects for mgmt tasks
dnf install -y htop tree wget curl git vim

# Get AWS CLI v2 - more reliable than the v1 that comes with AL2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# SSM plugin install
dnf install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm

# Create welcome banner
cat > /etc/motd << EOF

=== Coalfire SRE Challenge - Management Box ===

Project: ${project_name}
Role: Bastion/Management Host
Access: SSH to application servers

Tools installed:
  - AWS CLI v2
  - htop, tree, wget, curl, git, vim
  - Session Manager plugin

Security notes:
  - This box can SSH to app servers
  - Only accessible from your specified IP
  - SSH activities are logged

Helper scripts:
  - ./list-app-instances.sh - show running app servers
  - ./ssh-to-app.sh <instance-id> - connect to app server

EOF

# SSH config to make connecting to app servers easier
cat >> /home/ec2-user/.ssh/config << EOF
Host app-*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF

chown ec2-user:ec2-user /home/ec2-user/.ssh/config
chmod 600 /home/ec2-user/.ssh/config

# CloudWatch agent for basic monitoring
dnf install -y amazon-cloudwatch-agent

# Basic CloudWatch config for the management box
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
                        "file_path": "/var/log/secure",
                        "log_group_name": "/aws/ec2/${project_name}/mgmt/secure",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "/aws/ec2/${project_name}/mgmt/messages",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    }
}
EOF

# Fire up the CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Helper script to list the app servers
cat > /home/ec2-user/list-app-instances.sh << 'EOF'
#!/bin/bash
echo "=== Web Server Instances ==="
aws ec2 describe-instances \
    --filters "Name=tag:Type,Values=WebServer" "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].{InstanceId:InstanceId,PrivateIP:PrivateIpAddress,AZ:Placement.AvailabilityZone,State:State.Name}' \
    --output table
EOF

chmod +x /home/ec2-user/list-app-instances.sh
chown ec2-user:ec2-user /home/ec2-user/list-app-instances.sh

# Create a script to SSH to application instances
cat > /home/ec2-user/ssh-to-app.sh << 'EOF'
#!/bin/bash
if [ $# -eq 0 ]; then
    echo "Usage: $0 <instance-id-or-private-ip>"
    echo "Example: $0 i-1234567890abcdef0"
    echo "Example: $0 10.1.10.100"
    exit 1
fi

TARGET=$1

# Check if it's an instance ID or IP
if [[ $TARGET =~ ^i-[0-9a-f]{8,17}$ ]]; then
    # It's an instance ID, get the private IP
    PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $TARGET --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    if [ "$PRIVATE_IP" = "None" ] || [ -z "$PRIVATE_IP" ]; then
        echo "Error: Could not find private IP for instance $TARGET"
        exit 1
    fi
    echo "Connecting to instance $TARGET ($PRIVATE_IP)..."
    ssh ec2-user@$PRIVATE_IP
else
    # Assume it's an IP address
    echo "Connecting to $TARGET..."
    ssh ec2-user@$TARGET
fi
EOF

chmod +x /home/ec2-user/ssh-to-app.sh
chown ec2-user:ec2-user /home/ec2-user/ssh-to-app.sh

# Log that we're done
echo "$(date): Management box setup completed" >> /var/log/user-data.log

# Show welcome message when users log in
echo "cat /etc/motd" >> /home/ec2-user/.bashrc
