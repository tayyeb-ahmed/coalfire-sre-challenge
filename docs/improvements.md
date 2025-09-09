# Improvement Plan

## Overview

This doc outlines specific improvements to enhance the security, reliability, cost-effectiveness, and maintainability of the infrastructure. Improvements are prioritized based on impact, cost, and implementation complexity.

## Priority Matrix

| Priority | Criteria |
|----------|----------|
| **P0 - Critical** | Security vulnerabilities, compliance requirements |
| **P1 - High** | Availability issues, significant cost savings |
| **P2 - Medium** | Operational efficiency, moderate improvements |
| **P3 - Low** | Nice-to-have features, future enhancements |

## Security Improvements

### P0 - Critical Security Issues

#### 1. Implement HTTPS/TLS Encryption
**Problem**: HTTP traffic is unencrypted, vulnerable to interception
**Solution**: Deploy SSL/TLS certificates and enforce HTTPS

**Implementation**:
```hcl
# Add to load-balancer module
resource "aws_acm_certificate" "main" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.application.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }
}
```

**Effort**: 1-2 hours
**Cost Impact**: Free (ACM certificates)
**Risk Reduction**: High

#### 2. Restrict Outbound Security Group Rules
**Problem**: App instances have unrestricted outbound access
**Solution**: Implement specific outbound rules

**Implementation**:
```hcl
# Replace in security module
resource "aws_security_group" "application" {
  # ... existing config ...
  
  # Remove broad outbound rule, add specific ones
  egress {
    description = "HTTPS for package updates"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    description = "HTTP for package updates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    description = "DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**Effort**: 1-2 hours
**Cost Impact**: None
**Risk Reduction**: Medium

### P1 - High Priority Security

#### 3. Enable VPC Flow Logs
**Problem**: No network traffic visibility
**Solution**: Enable VPC Flow Logs to CloudWatch

**Implementation**:
```hcl
# Add to vpc module
resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flowlogs"
  retention_in_days = 30
}
```

**Effort**: 2-3 hours
**Cost Impact**: ~$10/month
**Risk Reduction**: Medium

#### 4. Deploy AWS WAF
**Problem**: No web app firewall protection
**Solution**: Implement AWS WAF w/ common rule sets

**Implementation**:
```hcl
# Add new module: modules/waf
resource "aws_wafv2_web_acl" "main" {
  name  = "${var.project_name}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }
}
```

**Effort**: 2-3 hours
**Cost Impact**: ~$20/month
**Risk Reduction**: High

## Availability Improvements

### P1 - High Priority Availability

#### 5. Implement Multi-Region Backup
**Problem**: Single region deployment, no disaster recovery
**Solution**: Automated AMI snapshots and cross-region replication

**Implementation**:
```hcl
# Add to compute module
resource "aws_dlm_lifecycle_policy" "backup" {
  description        = "EC2 backup policy"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state             = "ENABLED"

  policy_details {
    resource_types   = ["INSTANCE"]
    target_tags = {
      Project = var.project_name
    }

    schedule {
      name = "Daily snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["03:00"]
      }

      retain_rule {
        count = 7
      }

      copy_tags = true
    }
  }
}
```

**Effort**: 3-4 hours
**Cost Impact**: ~$15/month
**Risk Reduction**: High

#### 6. Enhanced Health Checks
**Problem**: Basic health checks may not catch app issues
**Solution**: Implement comprehensive health check endpoint

**Implementation**:
```bash
# Add to user-data.sh
cat > /var/www/html/health-detailed << 'EOF'
#!/bin/bash
# Comprehensive health check script

# Check Apache status
if ! systemctl is-active --quiet httpd; then
    echo "FAIL: Apache not running"
    exit 1
fi

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 90 ]; then
    echo "FAIL: Disk usage too high: ${DISK_USAGE}%"
    exit 1
fi

# Check memory usage
MEM_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ $MEM_USAGE -gt 90 ]; then
    echo "FAIL: Memory usage too high: ${MEM_USAGE}%"
    exit 1
fi

echo "OK: All checks passed"
EOF

chmod +x /var/www/html/health-detailed
```

**Effort**: 1-2 hours
**Cost Impact**: None
**Risk Reduction**: Medium

## Cost Optimization

### P2 - Medium Priority Cost Optimization

#### 7. Implement Spot Instances for Non-Critical Workloads
**Problem**: Using on-demand instances for all workloads
**Solution**: Mixed instance types w/ Spot instances

**Implementation**:
```hcl
# Modify launch template in compute module
resource "aws_launch_template" "application" {
  # ... existing config ...
  
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = "0.01"  # Adjust based on requirements
    }
  }
}

# Add mixed instances policy to ASG
resource "aws_autoscaling_group" "application" {
  # ... existing config ...
  
  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 1
      on_demand_percentage_above_base_capacity = 25
      spot_allocation_strategy                 = "capacity-optimized"
    }
    
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.application.id
        version           = "$Latest"
      }
      
      override {
        instance_type = "t3.micro"
      }
      
      override {
        instance_type = "t3a.micro"
      }
    }
  }
}
```

**Effort**: 3-4 hours
**Cost Impact**: 30-50% reduction in compute costs
**Risk Reduction**: None (cost optimization)

#### 8. S3 Lifecycle Policies
**Problem**: Log files stored indefinitely in S3
**Solution**: Implement lifecycle policies for cost optimization

**Implementation**:
```hcl
# Add to load-balancer module
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "log_lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}
```

**Effort**: 1-2 hours
**Cost Impact**: 20-40% reduction in storage costs
**Risk Reduction**: None (cost optimization)

## Operational Improvements

### P1 - High Priority Operational

#### 9. Implement Systems Manager Session Manager
**Problem**: SSH key mgmt and bastion host dependency
**Solution**: Replace SSH w/ Session Manager

**Implementation**:
```hcl
# Add to compute module IAM policy
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Remove SSH access from security groups
resource "aws_security_group" "application" {
  # Remove SSH ingress rule
  # Keep only HTTP from ALB
}
```

**Effort**: 2-3 hours
**Cost Impact**: None
**Risk Reduction**: Medium

#### 10. Enhanced Monitoring Dashboard
**Problem**: Limited visibility into system performance
**Solution**: Comprehensive CloudWatch dashboard

**Implementation**:
```hcl
# Add new module: modules/monitoring
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.application.arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB Metrics"
        }
      }
    ]
  })
}
```

**Effort**: 4-6 hours
**Cost Impact**: ~$3/month
**Risk Reduction**: Low (operational improvement)

### P2 - Medium Priority Operational

#### 11. Automated Patching
**Problem**: Manual patching process
**Solution**: AWS Systems Manager Patch Manager

**Implementation**:
```hcl
# Add to compute module
resource "aws_ssm_maintenance_window" "patching" {
  name     = "${var.project_name}-patching"
  duration = 3
  cutoff   = 1
  schedule = "cron(0 2 ? * SUN *)"  # Sunday 2 AM
}

resource "aws_ssm_maintenance_window_target" "patching" {
  window_id     = aws_ssm_maintenance_window.patching.id
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Project"
    values = [var.project_name]
  }
}
```

**Effort**: 3-4 hours
**Cost Impact**: None
**Risk Reduction**: Medium

#### 12. Log Aggregation and Analysis
**Problem**: Logs scattered across multiple services
**Solution**: Centralized logging with CloudWatch Insights

**Implementation**:
```hcl
# Add to monitoring module
resource "aws_cloudwatch_query_definition" "error_analysis" {
  name = "${var.project_name}-error-analysis"

  log_group_names = [
    "/aws/ec2/${var.project_name}/apache/error",
    "/aws/alb/${var.project_name}"
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
EOF
}
```

**Effort**: 2-3 hours
**Cost Impact**: ~$5/month
**Risk Reduction**: Low (operational improvement)

## Implementation Roadmap

### Phase 1: Critical Security (Week 1-2)
1. Implement HTTPS/TLS encryption
2. Restrict outbound security group rules
3. Enable VPC Flow Logs
4. Deploy basic AWS WAF

### Phase 2: High Priority Items (Week 3-4)
1. Implement backup strategy
2. Deploy Session Manager
3. Enhanced health checks
4. Basic monitoring dashboard

### Phase 3: Cost Optimization (Week 5-6)
1. Implement Spot instances
2. S3 lifecycle policies
3. Right-sizing analysis
4. Reserved instance planning

### Phase 4: Advanced Features (Week 7-8)
1. Advanced monitoring and alerting
2. Automated patching
3. Log aggregation
4. Performance optimization

## Implementation Examples

### Example 1: VPC Flow Logs Implementation

```hcl
# File: modules/vpc/flow-logs.tf
resource "aws_iam_role" "flow_log" {
  name = "${var.project_name}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_log" {
  name = "${var.project_name}-flow-log-policy"
  role = aws_iam_role.flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/${var.project_name}/flowlogs"
  retention_in_days = 30

  tags = var.common_tags
}

resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc-flow-logs"
  })
}
```

### Example 2: Enhanced Security Group Rules

```hcl
# File: modules/security/enhanced-rules.tf
resource "aws_security_group" "application_enhanced" {
  name_prefix = "${var.project_name}-app-enhanced-"
  vpc_id      = var.vpc_id

  # SSH from management only
  ingress {
    description     = "SSH from management"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.management.id]
  }

  # HTTP from ALB only
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Specific outbound rules instead of allowing all
  egress {
    description = "HTTPS for package updates"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP for package updates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS queries"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "NTP"
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-application-enhanced-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}
```

## Success Metrics

### Security Metrics
- Reduction in security findings: Target 80% reduction
- HTTPS adoption: 100% of traffic encrypted
- Failed authentication attempts: Monitored and alerted

### Availability Metrics
- Uptime: Target 99.9%
- Mean Time to Recovery (MTTR): < 15 minutes
- Successful health checks: > 99%

### Cost Metrics
- Infrastructure cost reduction: Target 20-30%
- Resource utilization: > 70% average
- Waste elimination: Unused resources < 5%

### Operational Metrics
- Deployment time: < 30 minutes
- Manual interventions: < 2 per month
- Monitoring coverage: 100% of critical components

## Conclusion

This improvement plan provides a structured approach to enhancing the infrastructure across security, availability, cost, and operational dimensions. The phased implementation ensures critical issues are addressed first while building toward a more robust and efficient system.

Each improvement includes specific implementation details, effort estimates, and expected outcomes to facilitate planning and execution.
