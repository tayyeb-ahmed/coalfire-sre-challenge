# Operational Runbook

## Overview

This runbook provides step-by-step procedures for deploying, operating, and troubleshooting the Coalfire SRE Challenge infrastructure. It serves as a comprehensive guide for SREs and ops teams.

## Table of Contents

1. [Deployment Procedures](#deployment-procedures)
2. [Operational Tasks](#operational-tasks)
3. [Monitoring and Alerting](#monitoring-and-alerting)
4. [Troubleshooting Guide](#troubleshooting-guide)
5. [Incident Response](#incident-response)
6. [Maintenance Procedures](#maintenance-procedures)
7. [Disaster Recovery](#disaster-recovery)

## Deployment Procedures

### Prerequisites

Before deploying the infrastructure, ensure you have:

- AWS CLI configured w/ appropriate creds
- Terraform >= 1.0 installed
- An AWS key pair created for EC2 access
- Your public IP address for mgmt access

### Initial Deployment

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd coalfire-terraform
   ```

2. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan -out=tfplan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply tfplan
   ```

6. **Verify deployment**:
   ```bash
   # Check outputs
   terraform output
   
   # Test website access
   curl -I $(terraform output -raw website_url)
   ```

### Deployment Validation Checklist

- [ ] VPC and subnets created successfully
- [ ] Security groups configured correctly
- [ ] Load balancer is healthy
- [ ] Auto Scaling Group has desired capacity
- [ ] Mgmt instance is accessible
- [ ] App instances are healthy
- [ ] Website responds to HTTP requests
- [ ] CloudWatch logs are being generated

## Operational Tasks

### Daily Operations

#### Health Check Verification
```bash
# Check ALB target health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn)

# Check Auto Scaling Group status
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw autoscaling_group_id)
```

#### Log Review
```bash
# View recent app logs
aws logs tail /aws/ec2/coalfire-sre-challenge/apache/access --follow

# Check for errors
aws logs filter-log-events \
  --log-group-name /aws/ec2/coalfire-sre-challenge/apache/error \
  --start-time $(date -d '1 hour ago' +%s)000
```

### Weekly Operations

#### Security Review
- Review VPC Flow Logs for unusual traffic patterns
- Check CloudTrail logs for unauthorized API calls
- Verify security group rules haven't been modified
- Review S3 bucket access logs

#### Performance Review
- Analyze CloudWatch metrics for performance trends
- Review Auto Scaling activities
- Check resource utilization and right-sizing opportunities
- Monitor cost trends in AWS Cost Explorer

### Monthly Operations

#### Backup Verification
- Verify AMI snapshots are being created
- Test restore procedures
- Review backup retention policies
- Document any backup failures

#### Security Updates
- Review and apply security patches
- Update AMI with latest security updates
- Review and update security group rules if needed
- Conduct security assessment

## Monitoring and Alerting

### Key Metrics to Monitor

#### Application Load Balancer
- Request count
- Response time
- HTTP 4xx/5xx error rates
- Healthy target count

#### Auto Scaling Group
- Instance count
- CPU utilization
- Memory utilization
- Scaling activities

#### Individual Instances
- CPU utilization
- Memory usage
- Disk space
- Network I/O

### CloudWatch Alarms

#### Critical Alarms
```bash
# High CPU utilization (already configured)
aws cloudwatch describe-alarms --alarm-names "coalfire-sre-challenge-cpu-high"

# Low healthy targets
aws cloudwatch put-metric-alarm \
  --alarm-name "coalfire-sre-challenge-unhealthy-targets" \
  --alarm-description "ALB has unhealthy targets" \
  --metric-name HealthyHostCount \
  --namespace AWS/ApplicationELB \
  --statistic Average \
  --period 60 \
  --threshold 1 \
  --comparison-operator LessThanThreshold \
  --evaluation-periods 2
```

#### Warning Alarms
- Disk space > 80%
- Memory usage > 85%
- High response time (> 2 seconds)

### Log Analysis Queries

#### Common CloudWatch Insights Queries

**Error Analysis**:
```sql
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
```

**Traffic Analysis**:
```sql
fields @timestamp, @message
| filter @message like /GET/
| stats count() by bin(5m)
```

**Response Time Analysis**:
```sql
fields @timestamp, @message
| filter @message like /response_time/
| stats avg(response_time) by bin(5m)
```

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue: Website Not Accessible

**Symptoms**: HTTP requests to ALB DNS name fail or timeout

**Troubleshooting Steps**:
1. Check ALB status:
   ```bash
   aws elbv2 describe-load-balancers \
     --load-balancer-arns $(terraform output -raw alb_arn)
   ```

2. Check target health:
   ```bash
   aws elbv2 describe-target-health \
     --target-group-arn $(terraform output -raw target_group_arn)
   ```

3. Check security groups:
   ```bash
   aws ec2 describe-security-groups \
     --group-ids $(terraform output -raw alb_security_group_id)
   ```

4. Test from mgmt instance:
   ```bash
   # SSH to mgmt instance
   ssh -i ~/.ssh/your-key.pem ec2-user@$(terraform output -raw management_instance_public_ip)
   
   # Test internal connectivity
   curl -I http://10.1.10.x  # Replace w/ actual instance IP
   ```

**Common Causes**:
- Security group rules blocking traffic
- Target group health check failures
- App not running on instances
- Network connectivity issues

#### Issue: Auto Scaling Not Working

**Symptoms**: Instances not scaling up/down despite CPU thresholds

**Troubleshooting Steps**:
1. Check scaling policies:
   ```bash
   aws autoscaling describe-policies \
     --auto-scaling-group-name $(terraform output -raw autoscaling_group_id)
   ```

2. Check CloudWatch alarms:
   ```bash
   aws cloudwatch describe-alarms \
     --alarm-names "coalfire-sre-challenge-cpu-high" "coalfire-sre-challenge-cpu-low"
   ```

3. Review scaling activities:
   ```bash
   aws autoscaling describe-scaling-activities \
     --auto-scaling-group-name $(terraform output -raw autoscaling_group_id)
   ```

**Common Causes**:
- CloudWatch agent not installed/configured
- Insufficient perms for scaling
- Cooldown periods preventing scaling
- Instance launch failures

#### Issue: SSH Access Problems

**Symptoms**: Cannot SSH to mgmt or app instances

**Troubleshooting Steps**:
1. Verify key pair:
   ```bash
   aws ec2 describe-key-pairs --key-names your-key-name
   ```

2. Check security group rules:
   ```bash
   aws ec2 describe-security-groups \
     --group-ids $(terraform output -raw management_security_group_id)
   ```

3. Verify instance status:
   ```bash
   aws ec2 describe-instances \
     --instance-ids $(terraform output -raw management_instance_id)
   ```

4. Check your public IP:
   ```bash
   curl ifconfig.me
   # Compare w/ allowed CIDR in terraform.tfvars
   ```

**Common Causes**:
- Incorrect key pair specified
- Security group not allowing SSH from your IP
- Instance not running or in failed state
- Network connectivity issues

### Performance Issues

#### High Response Times

**Investigation Steps**:
1. Check ALB metrics in CloudWatch
2. Review app logs for errors
3. Check instance CPU/memory utilization
4. Analyze database queries (if applicable)
5. Review network latency

**Potential Solutions**:
- Scale up instance types
- Increase Auto Scaling Group capacity
- Optimize app code
- Add caching layer
- Review database performance

#### High Error Rates

**Investigation Steps**:
1. Review ALB access logs
2. Check app error logs
3. Analyze error patterns and timing
4. Review recent deployments or changes

**Potential Solutions**:
- Fix app bugs
- Increase resource limits
- Review config changes
- Implement circuit breakers

## Incident Response

### Incident Classification

#### Severity 1 (Critical)
- Complete service outage
- Security breach
- Data loss

#### Severity 2 (High)
- Partial service degradation
- Performance issues affecting users
- Security vulnerabilities

#### Severity 3 (Medium)
- Minor functionality issues
- Non-critical component failures

#### Severity 4 (Low)
- Cosmetic issues
- Documentation updates

### Incident Response Procedures

#### Immediate Response (0-15 minutes)
1. **Acknowledge the incident**
2. **Assess severity and impact**
3. **Notify stakeholders** (if Sev 1 or 2)
4. **Begin investigation**

#### Investigation Phase (15-60 minutes)
1. **Gather information**:
   - Check monitoring dashboards
   - Review recent changes
   - Analyze logs and metrics
   
2. **Identify root cause**:
   - Use troubleshooting guides
   - Check system dependencies
   - Review error patterns

3. **Implement temporary fix** (if possible):
   - Scale resources if needed
   - Restart failed services
   - Route traffic away from failed components

#### Resolution Phase
1. **Implement permanent fix**
2. **Test the solution**
3. **Monitor for stability**
4. **Update documentation**

#### Post-Incident Review
1. **Document timeline and actions**
2. **Identify root cause**
3. **Create action items for prevention**
4. **Update runbooks and procedures**

### Emergency Contacts

- **Primary On-Call Engineer**: tayyeb@hotmail.com

## Maintenance Procedures

### Planned Maintenance

#### App Updates
1. **Pre-maintenance checklist**:
   - [ ] Backup current state
   - [ ] Test update in staging
   - [ ] Schedule maintenance window
   - [ ] Notify stakeholders

2. **Update procedure**:
   ```bash
   # Update launch template w/ new AMI
   terraform plan -var="ami_id=ami-newversion"
   terraform apply
   
   # Trigger instance refresh
   aws autoscaling start-instance-refresh \
     --auto-scaling-group-name $(terraform output -raw autoscaling_group_id)
   ```

3. **Post-maintenance verification**:
   - [ ] Verify all instances are healthy
   - [ ] Test app functionality
   - [ ] Monitor for errors
   - [ ] Update docs

#### Infrastructure Updates
1. **Terraform updates**:
   ```bash
   # Always plan first
   terraform plan -out=tfplan
   
   # Review changes carefully
   terraform show tfplan
   
   # Apply if changes are acceptable
   terraform apply tfplan
   ```

2. **Rollback procedure**:
   ```bash
   # If issues occur, rollback
   terraform plan -destroy -target=resource.name
   terraform apply -target=resource.name
   ```

### Patching Procedures

#### Security Patches
1. **Create new AMI with patches**:
   ```bash
   # Launch temporary instance
   aws ec2 run-instances --image-id ami-12345 --instance-type t2.micro
   
   # Apply patches
   sudo yum update -y
   
   # Create new AMI
   aws ec2 create-image --instance-id i-12345 --name "patched-ami-$(date +%Y%m%d)"
   ```

2. **Update launch template**:
   ```bash
   terraform apply -var="ami_id=ami-newpatched"
   ```

3. **Rolling update**:
   ```bash
   aws autoscaling start-instance-refresh \
     --auto-scaling-group-name $(terraform output -raw autoscaling_group_id) \
     --preferences MinHealthyPercentage=50
   ```

## Disaster Recovery

### Backup Strategy

#### Automated Backups
- **AMI Snapshots**: Daily snapshots of instances
- **Config Backup**: Terraform state stored in S3
- **Log Backup**: CloudWatch logs w/ retention policies

#### Manual Backups
- **Database Exports**: If databases are added
- **Config Files**: Critical config backups
- **Documentation**: Keep offline copies

### Recovery Procedures

#### Complete Infrastructure Loss

1. **Assess the situation**:
   - Determine scope of loss
   - Identify available backups
   - Estimate recovery time

2. **Restore infrastructure**:
   ```bash
   # Clone repository
   git clone <repository-url>
   cd coalfire-terraform
   
   # Configure variables
   cp terraform.tfvars.example terraform.tfvars
   # Edit with appropriate values
   
   # Deploy infrastructure
   terraform init
   terraform plan
   terraform apply
   ```

3. **Restore data** (if applicable):
   - Restore from AMI snapshots
   - Import database backups
   - Verify data integrity

4. **Verify recovery**:
   - Test all functionality
   - Verify monitoring is working
   - Update DNS if needed

#### Partial Service Loss

1. **Identify affected components**
2. **Use Auto Scaling for instance failures**:
   ```bash
   # Terminate unhealthy instances
   aws autoscaling terminate-instance-in-auto-scaling-group \
     --instance-id i-12345 \
     --should-decrement-desired-capacity
   ```

3. **Replace failed infrastructure components**:
   ```bash
   # Target specific resources for replacement
   terraform taint aws_instance.management
   terraform apply
   ```

### Recovery Testing

#### Monthly DR Tests
- Test AMI restoration process
- Verify backup integrity
- Practice recovery procedures
- Update recovery documentation

#### Quarterly Full DR Tests
- Complete infrastructure rebuild
- End-to-end functionality testing
- Performance validation
- Documentation updates

## Appendices

### Appendix A: Useful Commands

#### AWS CLI Commands
```bash
# List all resources with project tag
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=coalfire-sre-challenge

# Get instance IDs in Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw autoscaling_group_id) \
  --query 'AutoScalingGroups[0].Instances[].InstanceId' \
  --output text

# Check security group rules
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw application_security_group_id) \
  --query 'SecurityGroups[0].IpPermissions'
```

#### Terraform Commands
```bash
# Show current state
terraform show

# List all resources
terraform state list

# Get specific output
terraform output -raw website_url

# Refresh state
terraform refresh

# Import existing resource
terraform import aws_instance.example i-12345
```

### Appendix B: Log Locations

#### System Logs
- `/var/log/messages` - System messages
- `/var/log/secure` - Authentication logs
- `/var/log/yum.log` - Package mgmt logs

#### App Logs
- `/var/log/httpd/access_log` - Apache access logs
- `/var/log/httpd/error_log` - Apache error logs
- `/var/log/user-data.log` - User data script logs

#### CloudWatch Log Groups
- `/aws/ec2/coalfire-sre-challenge/apache/access`
- `/aws/ec2/coalfire-sre-challenge/apache/error`
- `/aws/ec2/coalfire-sre-challenge/management/secure`
- `/aws/alb/coalfire-sre-challenge`

### Appendix C: Network Diagram

```
Internet
    |
    v
Internet Gateway
    |
    v
Application Load Balancer (Public Subnets)
    |
    v
App Instances (Private Subnets)
    ^
    |
Mgmt Instance (Public Subnet) --> NAT Gateway --> Internet
```

### Appendix D: Port Reference

| Service | Port | Protocol | Source | Destination |
|---------|------|----------|--------|-------------|
| HTTP | 80 | TCP | Internet | ALB |
| HTTPS | 443 | TCP | Internet | ALB |
| HTTP | 80 | TCP | ALB | App Instances |
| SSH | 22 | TCP | Your IP | Mgmt |
| SSH | 22 | TCP | Mgmt | App Instances |

This runbook will be updated regularly as the infrastructure evolves and new procedures are developed.
