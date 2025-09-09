# Architecture Design

## Overview

This doc describes the architecture design for the Coalfire SRE Technical Challenge. The solution implements a secure, scalable web app environment on AWS using Infrastructure as Code (Terraform).

## Architecture Principles

- **Security First**: Layered security w/ defense in depth
- **High Availability**: Multi-AZ deployment for resilience
- **Scalability**: Auto Scaling Group for dynamic capacity
- **Least Privilege**: Minimal required perms and access
- **Monitoring**: Comprehensive logging and monitoring

## Network Architecture

### VPC Design
- **CIDR Block**: 10.1.0.0/16
- **Availability Zones**: 2 (us-east-1a, us-east-1b)
- **Subnets**: 3-tier architecture across both AZs

### Subnet Layout

| Subnet Type | AZ A CIDR | AZ B CIDR | Purpose |
|-------------|-----------|-----------|---------|
| Mgmt | 10.1.1.0/24 | 10.1.2.0/24 | Public subnets for bastion host and ALB |
| App | 10.1.10.0/24 | 10.1.11.0/24 | Private subnets for web servers |
| Backend | 10.1.20.0/24 | 10.1.21.0/24 | Private subnets for future database/services |

### Routing
- **Public Route Table**: Routes to Internet Gateway for mgmt subnets
- **Private Route Table**: Routes to NAT Gateway for app/backend subnets
- **NAT Gateway**: Deployed in mgmt subnet for outbound internet access

## Security Architecture

### Security Groups

#### Mgmt Security Group
- **Inbound**: SSH (22) from specified IP/CIDR only
- **Outbound**: All traffic (for updates and mgmt)

#### ALB Security Group
- **Inbound**: HTTP (80) and HTTPS (443) from internet
- **Outbound**: HTTP (80) to app instances

#### App Security Group
- **Inbound**: 
  - SSH (22) from mgmt security group
  - HTTP (80) from ALB security group
- **Outbound**: All traffic (for updates and package installation)

### Network ACLs
- **App NACL**: Additional layer of security for app subnets
- **Mgmt NACL**: Controls traffic to/from mgmt subnets
- **Stateless rules**: Complement stateful security group rules

## Compute Architecture

### Auto Scaling Group
- **Instance Type**: t2.micro
- **Capacity**: 2 minimum, 6 maximum, 2 desired
- **Health Checks**: ELB health checks w/ 5-minute grace period
- **Scaling Policies**: CPU-based scaling (scale up at 80%, scale down at 10%)

### Mgmt Instance
- **Purpose**: Bastion host for SSH access to app instances
- **Instance Type**: t2.micro
- **Placement**: Mgmt subnet w/ public IP
- **Tools**: AWS CLI, monitoring tools, SSH utilities

### Launch Template
- **AMI**: Latest Amazon Linux 2
- **User Data**: Automated Apache installation and config
- **IAM Role**: CloudWatch and basic EC2 perms
- **Security**: App security group attached

## Load Balancing

### Application Load Balancer
- **Type**: Application Load Balancer (Layer 7)
- **Scheme**: Internet-facing
- **Subnets**: Deployed in mgmt (public) subnets
- **Health Checks**: HTTP health checks on `/health` endpoint
- **Listeners**: HTTP on port 80 (HTTPS ready for future implementation)

### Target Group
- **Protocol**: HTTP on port 80
- **Health Check**: `/health` endpoint w/ 30-second intervals
- **Thresholds**: 2 healthy, 2 unhealthy
- **Stickiness**: Disabled (stateless app)

## Monitoring and Logging

### CloudWatch Integration
- **Metrics**: CPU, memory, disk utilization via CloudWatch agent
- **Alarms**: Auto Scaling triggers based on CPU utilization
- **Log Groups**: Separate log groups for different services

### Access Logging
- **ALB Logs**: Stored in S3 bucket w/ encryption
- **App Logs**: Apache access and error logs to CloudWatch
- **System Logs**: Security and system logs from mgmt instance

## High Availability Features

### Multi-AZ Deployment
- Application instances distributed across 2 availability zones
- Load balancer spans multiple AZs
- Auto Scaling Group ensures instance replacement

### Auto Scaling
- Automatic instance replacement on failure
- Dynamic scaling based on demand
- Rolling updates for zero-downtime deployments

### Health Monitoring
- ELB health checks ensure traffic only goes to healthy instances
- CloudWatch alarms for proactive monitoring
- Auto Scaling Group health checks for instance replacement

## Security Controls

### Network Segmentation
- Private app subnets w/ no direct internet access
- Mgmt subnet isolation
- Backend subnet reserved for future database services

### Access Control
- SSH access only through mgmt instance
- Restricted mgmt access from specific IP/CIDR
- Security groups w/ least privilege rules

### Data Protection
- S3 bucket encryption for log storage
- VPC flow logs capability (can be enabled)
- CloudWatch log encryption

## Scalability Considerations

### Horizontal Scaling
- Auto Scaling Group handles demand fluctuations
- Load balancer distributes traffic evenly
- Stateless app design

### Vertical Scaling
- Instance types can be easily changed via launch template
- EBS volume optimization available
- Enhanced networking capabilities

### Future Expansion
- Backend subnets ready for database deployment
- Additional AZs can be added
- Microservices architecture support

## Cost Optimization

### Resource Sizing
- t2.micro instances for cost-effective compute
- Minimal required resources for proof of concept
- Auto Scaling prevents over-provisioning

### Storage Optimization
- S3 lifecycle policies for log retention
- EBS volume optimization
- CloudWatch log retention policies

## Disaster Recovery

### Backup Strategy
- AMI snapshots for instance recovery
- S3 cross-region replication capability
- Infrastructure as Code for environment recreation

### Recovery Procedures
- Auto Scaling Group automatic instance replacement
- Multi-AZ deployment for zone failures
- Terraform state mgmt for infrastructure recovery

## Compliance and Governance

### Tagging Strategy
- Consistent resource tagging for cost allocation
- Environment and project identification
- Automated compliance checking capability

### Access Auditing
- CloudTrail integration ready
- VPC Flow Logs capability
- Security group change monitoring

## Future Enhancements

### Security Improvements
- WAF integration w/ ALB
- SSL/TLS certificate implementation
- Secrets Manager for sensitive data

### Monitoring Enhancements
- Application Performance Monitoring (APM)
- Custom CloudWatch dashboards
- SNS notifications for alerts

### Automation
- CI/CD pipeline integration
- Automated security scanning
- Infrastructure drift detection
