# Coalfire SRE AWS Technical Challenge

## Overview

This repo contains a comprehensive Terraform-based AWS infrastructure solution for the Coalfire SRE Technical Challenge. The solution implements a secure, scalable web app environment with proper network segmentation, operational monitoring, and follows AWS best practices.

## Architecture

The infrastructure implements a 3-tier architecture with the following components:

### Network Layer
- **VPC**: 10.1.0.0/16 CIDR block across 2 AZs
- **Mgmt Subnets**: 10.1.1.0/24, 10.1.2.0/24 (Public)
- **App Subnets**: 10.1.10.0/24, 10.1.11.0/24 (Private)
- **Backend Subnets**: 10.1.20.0/24, 10.1.21.0/24 (Private, for future use)

### Compute Layer
- **Auto Scaling Group**: 2-6 t2.micro instances running Apache
- **Mgmt Instance**: t2.micro bastion host for SSH access
- **Launch Template**: Automated Apache install and config

### Load Balancing & Security
- **Application Load Balancer**: Internet-facing w/ health checks
- **Security Groups**: Layered security with least privilege access
- **Network ACLs**: Additional stateless security controls
- **IAM Roles**: Proper permissions for CloudWatch and management

## Quick Start

### Prerequisites
- AWS CLI configured w/ appropriate creds
- Terraform >= 1.0 installed
- An AWS key pair for EC2 access
- Your public IP address for mgmt access

### Deployment Steps

1. **Clone and configure**:
   ```bash
   git clone <repository-url>
   cd coalfire-terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Update terraform.tfvars**:
   ```hcl
   # Required: Update these values
   management_allowed_cidr = "YOUR_IP_ADDRESS/32"  # Get with: curl ifconfig.me
   key_pair_name = "your-aws-key-pair-name"
   
   # Optional: Customize these
   aws_region = "us-east-1"
   project_name = "coalfire-sre-challenge"
   ```

3. **Deploy infrastructure**:
   ```bash
   terraform init
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

4. **Verify deployment**:
   ```bash
   # Get website URL
   terraform output website_url
   
   # Test website
   curl -I $(terraform output -raw website_url)
   
   # Get SSH command for mgmt instance
   terraform output ssh_connection_command
   ```

## Project Structure

```
coalfire-terraform/
├── main.tf                           # Main Terraform config
├── variables.tf                      # Variable definitions
├── outputs.tf                        # Output definitions
├── terraform.tfvars.example          # Example variables file
├── modules/                          # Custom Terraform modules
│   ├── vpc/                         # VPC, subnets, routing
│   ├── security/                    # Security groups, NACLs
│   ├── compute/                     # EC2, ASG, launch templates
│   └── load-balancer/               # ALB, target groups
├── diagrams/                        # Architecture diagrams
│   └── architecture.py              # Diagram generation script
├── docs/                           # Documentation
│   ├── architecture.md             # Architecture design details
│   ├── security-analysis.md        # Security assessment
│   ├── improvements.md             # Improvement recommendations
│   └── runbook.md                  # Operational procedures
└── CS SRE AWS Tech Challenge july2025 (1).pdf  # Original requirements
```

## Key Features

### Security
- Private app subnets (no direct internet access)
- Bastion host for secure SSH access
- Security groups w/ least privilege rules
- Network ACLs for additional security layer
- S3 bucket encryption and public access blocking
- IAM roles instead of access keys

### High Availability
- Multi-AZ deployment across 2 AZs
- Auto Scaling Group w/ health checks
- Application Load Balancer w/ health monitoring
- Automated instance replacement on failure

### Monitoring & Logging
- CloudWatch agent for system metrics
- App and system log collection
- Auto Scaling policies based on CPU utilization
- S3 bucket for ALB access logs

### Operational Excellence
- Infrastructure as Code w/ Terraform modules
- Comprehensive docs and runbooks
- Automated deployment and config
- Consistent resource tagging

## Accessing the Application

After successful deployment:

1. **Website Access**: 
   ```bash
   # Get the URL
   terraform output website_url
   # Example: http://coalfire-sre-challenge-alb-123456789.us-east-1.elb.amazonaws.com
   ```

2. **Mgmt Access**:
   ```bash
   # SSH to mgmt instance
   terraform output ssh_connection_command
   # From mgmt instance, you can SSH to app instances
   ```

3. **Monitoring**:
   - CloudWatch Console: View metrics and logs
   - S3 Console: Access ALB logs in the created bucket

## Operational Analysis

### Security Assessment
The current implementation provides a solid security foundation but has areas for improvement:

**Strengths**:
- Network segmentation w/ private subnets
- Layered security controls (Security Groups + NACLs)
- Bastion host architecture
- Encrypted S3 storage

**Critical Gaps**:
- HTTP traffic not encrypted (no HTTPS/TLS)
- Overly permissive outbound security group rules
- No Web Application Firewall (WAF)
- Missing VPC Flow Logs

**See [Security Analysis](docs/security-analysis.md) for detailed assessment**

### Availability Analysis
**Strengths**:
- Multi-AZ deployment
- Auto Scaling Group w/ health checks
- Load balancer health monitoring

**Improvement Areas**:
- No automated backup strategy
- Single region deployment
- Basic health checks only

### Cost Optimization Opportunities
- Implement Spot instances for cost savings or purchase an instance savings plan
- S3 lifecycle policies for log retention
- Right-sizing analysis for instance types
- Reserved instances for predictable workloads

## Improvement Plan

The infrastructure includes a comprehensive improvement plan w/ prioritized enhancements:

### Phase 1: Critical Security (Immediate)
1. **Implement HTTPS/TLS encryption** - Deploy SSL certificates
2. **Restrict outbound security rules** - Limit to specific ports/protocols
3. **Enable VPC Flow Logs** - Network traffic visibility
4. **Deploy AWS WAF** - Web app firewall protection

### Phase 2: High Priority (1-2 weeks)
1. **Backup strategy** - Automated AMI snapshots
2. **Enhanced monitoring** - Comprehensive CloudWatch dashboards
3. **Session Manager** - Replace SSH w/ AWS Systems Manager
4. **Performance optimization** - Enhanced health checks

**See [Improvement Plan](docs/improvements.md) for detailed implementation**

## Documentation

### Architecture & Design
- **[Architecture Design](docs/architecture.md)**: Detailed technical architecture
- **[Security Analysis](docs/security-analysis.md)**: Security assessment and gaps
- **[Improvement Plan](docs/improvements.md)**: Prioritized enhancement roadmap

### Operations
- **[Operational Runbook](docs/runbook.md)**: Deployment, monitoring, and troubleshooting procedures

### Diagrams
- **[Architecture Diagram](diagrams/architecture.py)**: Visual representation of the infrastructure

## Design Decisions & Assumptions

### Network Design
- **3-tier architecture**: Separates mgmt, app, and backend concerns
- **/24 subnets**: Provides adequate IP space while maintaining clear boundaries
- **NAT Gateway**: Single NAT Gateway for cost optimization (production would use multiple)

### Security Approach
- **Defense in depth**: Multiple security layers (SG + NACL + private subnets)
- **Least privilege**: Minimal required access permissions
- **Bastion host**: Centralized access control point

### Compute Strategy
- **t2.micro instances**: Cost-effective for proof of concept
- **Auto Scaling**: Handles demand fluctuations and failures
- **Amazon Linux 2023**: Latest version w/ long-term support and enhanced security

### Monitoring Philosophy
- **CloudWatch integration**: Native AWS monitoring
- **Centralized logging**: Aggregated logs for analysis
- **Proactive alerting**: CPU-based scaling triggers

## Testing & Validation

### Deployment Validation
```bash
# Verify all components are healthy
terraform output deployment_summary

# Test website functionality
curl -v $(terraform output -raw website_url)

# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw autoscaling_group_id)

# Verify security groups
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw application_security_group_id)
```

### Health Checks
- ALB health checks on `/health` endpoint
- Auto Scaling Group health checks
- CloudWatch monitoring for system metrics

## Troubleshooting

### Common Issues

1. **Website not accessible**:
   - Check security group rules
   - Verify target group health
   - Confirm instances are running

2. **SSH access denied**:
   - Verify your IP in `management_allowed_cidr`
   - Check key pair name matches
   - Confirm security group rules

3. **Auto Scaling not working**:
   - Check CloudWatch agent installation
   - Verify IAM perms
   - Review scaling policies

**See [Operational Runbook](docs/runbook.md) for detailed troubleshooting**

## Cost Considerations

### Current Monthly Costs (Estimated)
- **EC2 Instances**: ~$15-45 (2-6 t2.micro instances)
- **NAT Gateway**: ~$45
- **Application Load Balancer**: ~$20
- **Data Transfer**: ~$5-15
- **CloudWatch/Logs**: ~$5-10
- **S3 Storage**: ~$1-5

**Total Estimated**: ~$90-140/month

### Cost Optimization Opportunities
- Spot instances: 30-50% savings on compute
- Reserved instances: 30-60% savings for predictable workloads
- S3 lifecycle policies: 20-40% savings on storage
- Right-sizing: 10-30% savings through optimization

## Cleanup

To destroy the infrastructure:

```bash
# Plan destruction
terraform plan -destroy

# Destroy infrastructure
terraform destroy

# Confirm all resources are removed
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=coalfire-sre-challenge
```

## Support & Resources

### References Used
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [Coalfire Terraform Modules](https://github.com/orgs/Coalfire-CF/repositories?q=visibility:public+terraform-aws)

### Assumptions Made
- Single environment deployment (dev/proof-of-concept)
- HTTP-only traffic acceptable for initial implementation
- Basic monitoring sufficient for initial deployment
- Cost optimization prioritized over advanced features
- Manual DNS mgmt (no Route 53 integration)

### Future Enhancements
- HTTPS/TLS implementation w/ ACM certificates
- Multi-region deployment for disaster recovery
- Database integration (RDS) in backend subnets
- CI/CD pipeline integration
- Advanced monitoring and alerting
- WAF and advanced security controls

---

## Challenge Requirements Compliance

**Network Requirements**:
- VPC w/ 10.1.0.0/16 CIDR
- 3 subnets across 2 AZs (Mgmt, App, Backend)
- Mgmt subnet accessible from internet
- App/Backend subnets private

**Compute Requirements**:
- Auto Scaling Group (2-6 t2.micro instances)
- Apache web server installation
- SSH access from mgmt instance only
- Mgmt instance in public subnet

**Load Balancer Requirements**:
- Application Load Balancer
- Health checks configured
- Traffic distribution to ASG instances

**Security Requirements**:
- Proper security group config
- SSH restrictions implemented
- Network segmentation achieved

**Operational Requirements**:
- Infrastructure as Code (Terraform)
- Modular design
- Comprehensive docs
- Operational analysis and improvements

---

*This solution demonstrates enterprise-grade infrastructure design principles while meeting all specified requirements for the Coalfire SRE Technical Challenge.*
