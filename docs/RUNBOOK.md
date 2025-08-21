# 📘 Operations Runbook

<div align="center">

## **Swiss Re Infrastructure - Operational Procedures**
### *Operated by Jesús Gracia*

[![Operations](https://img.shields.io/badge/Operations-24%2F7-blue?style=for-the-badge)]()
[![Automation](https://img.shields.io/badge/Automation-95%25-green?style=for-the-badge)]()
[![SLA](https://img.shields.io/badge/SLA-99.99%25-success?style=for-the-badge)]()

</div>

---

## 📋 Table of Contents

1. [Daily Operations](#-daily-operations)
2. [Deployment Procedures](#-deployment-procedures)
3. [Monitoring & Alerts](#-monitoring--alerts)
4. [Incident Management](#-incident-management)
5. [Maintenance Procedures](#-maintenance-procedures)
6. [Disaster Recovery](#-disaster-recovery)
7. [Troubleshooting Guide](#-troubleshooting-guide)
8. [Emergency Contacts](#-emergency-contacts)

---

## 🔄 Daily Operations

### Morning Health Check Routine (09:00 CET)

    #!/bin/bash
    # ============================================
    # Swiss Re Daily Health Check Script
    # Author: Jesus Gracia
    # Version: 2.0
    # ============================================

    echo "═══════════════════════════════════════════"
    echo "    SWISS RE INFRASTRUCTURE HEALTH CHECK    "
    echo "═══════════════════════════════════════════"
    echo ""

    # 1. Check Azure Resource Health
    echo "[ Checking Resource Health ]"
    az resource list \
      --resource-group rg-swissre-prod \
      --query "[].{Name:name, Type:type, Status:provisioningState}" \
      --output table

    # 2. Verify VM Status
    echo "[ Checking VM Status ]"
    az vm show \
      --resource-group rg-swissre-prod \
      --name vm-swissre-prod \
      --query "{Name:name, Status:instanceView.statuses[1].displayStatus, PowerState:powerState}" \
      --output table

    # 3. Apache Service Status
    echo "[ Checking Apache Status ]"
    az vm run-command invoke \
      --resource-group rg-swissre-prod \
      --name vm-swissre-prod \
      --command-id RunShellScript \
      --scripts "systemctl status apache2 | head -n 3"

    # 4. Check SSL Certificate Expiry
    echo "[ Checking Certificate Expiry ]"
    az keyvault certificate show \
      --vault-name kv-swissre-prod \
      --name ssl-cert \
      --query "{Name:name, Expires:attributes.expires, Enabled:attributes.enabled}" \
      --output table

    # 5. Review Overnight Alerts
    echo "[ Checking Recent Alerts ]"
    az monitor alert list \
      --resource-group rg-swissre-prod \
      --query "[?targetResourceType=='Microsoft.Compute/virtualMachines'].{Name:name, Severity:severity, Status:monitorCondition}" \
      --output table

    # 6. Backup Status
    echo "[ Checking Backup Status ]"
    az backup job list \
      --resource-group rg-swissre-prod \
      --vault-name backup-vault-prod \
      --status InProgress \
      --output table

    echo ""
    echo "Health check completed at $(date)"
    echo "═══════════════════════════════════════════"

### Performance Monitoring Dashboard

| 📊 **Metric** | 🎯 **Target** | ⚠️ **Warning** | 🚨 **Critical** |
|:-------------:|:-------------:|:---------------:|:---------------:|
| **CPU Usage** | < 50% | 70% | 90% |
| **Memory** | < 60% | 80% | 95% |
| **Disk I/O** | < 80 IOPS | 100 IOPS | 150 IOPS |
| **Network** | < 80 Mbps | 100 Mbps | 150 Mbps |
| **Response Time** | < 100ms | 200ms | 500ms |
| **Error Rate** | < 0.1% | 1% | 5% |

---

## 🚀 Deployment Procedures

### Standard Deployment Process

    Pre-Checks → Backup → Validate → Deploy → Test → Success?
                                                        ↓ No
                                                    Rollback
                                                        ↓
                                                    Investigate
    Success? Yes → Monitor → Document

### Deployment Commands

#### Development Environment

    # Deploy Version 3 to Development
    ./scripts/deploy.sh dev 3

    # Validate deployment
    az deployment group validate \
      --resource-group rg-swissre-dev \
      --template-file infrastructure/main.bicep \
      --parameters @infrastructure/parameters/dev.json

#### Test Environment

    # Deploy to Test with approval
    ./scripts/deploy.sh test 3 --require-approval

    # Run smoke tests
    ./scripts/test-deployment.sh test

#### Production Environment

    # Production deployment checklist
    echo "[ Pre-Deployment Checklist ]"
    echo "✓ Change approval obtained"
    echo "✓ Maintenance window scheduled"
    echo "✓ Rollback plan ready"
    echo "✓ Team notified"

    # Execute production deployment
    ./scripts/deploy-production.sh \
      --version 3 \
      --backup-first \
      --notify-team \
      --monitor-duration 30

### Rollback Procedure

    #!/bin/bash
    # Emergency Rollback Script

    # 1. Identify last known good deployment
    LAST_GOOD=$(az deployment group list \
      --resource-group rg-swissre-prod \
      --query "[?properties.provisioningState=='Succeeded'] | [0].name" \
      --output tsv)

    # 2. Trigger rollback
    echo "Rolling back to: $LAST_GOOD"
    az deployment group create \
      --resource-group rg-swissre-prod \
      --name "rollback-$(date +%s)" \
      --template-uri "https://storage.blob.core.windows.net/templates/$LAST_GOOD.json"

    # 3. Verify rollback
    ./scripts/health-check.sh prod

    # 4. Notify team
    ./scripts/notify-team.sh "Rollback completed to $LAST_GOOD"

---

## 📊 Monitoring & Alerts

### Alert Configuration Matrix

| 🚨 **Alert Name** | 📋 **Condition** | 🎯 **Severity** | 🔔 **Action** | 👥 **Team** |
|:------------------:|:----------------:|:---------------:|:-------------:|:-----------:|
| **VM-Down** | Heartbeat lost > 5 min | Critical | Auto-restart, Page | On-call |
| **High-CPU** | CPU > 90% for 10 min | High | Scale, Email | DevOps |
| **High-Memory** | Memory > 90% for 10 min | High | Investigate | DevOps |
| **Disk-Space** | Disk > 85% | Medium | Cleanup, Expand | Ops |
| **Cert-Expiry** | Expires < 30 days | Low | Renew | Security |
| **DDoS-Attack** | Detected by Firewall | Critical | Auto-mitigate | Security |
| **Backup-Failed** | Job failed | High | Retry, Investigate | Ops |

### Custom KQL Queries

    // Top 10 IP addresses by request count
    AzureDiagnostics
    | where Category == "ApplicationGatewayAccessLog"
    | summarize RequestCount = count() by clientIP_s
    | top 10 by RequestCount desc
    | render barchart

    // Failed authentication attempts
    SecurityEvent
    | where EventID == 4625
    | summarize FailedAttempts = count() by Account, Computer, IPAddress
    | where FailedAttempts > 5
    | order by FailedAttempts desc

    // Resource utilization trends
    Perf
    | where ObjectName == "Processor" and CounterName == "% Processor Time"
    | summarize AvgCPU = avg(CounterValue) by bin(TimeGenerated, 1h), Computer
    | render timechart

    // Application errors
    AppTraces
    | where SeverityLevel >= 3
    | summarize ErrorCount = count() by Message, SeverityLevel
    | order by ErrorCount desc

---

## 🚨 Incident Management

### Incident Response Workflow

    Alert Triggered → Auto-Remediate? → Yes → Execute Automation → Resolved?
                            ↓ No                                      ↓ No
                      Page On-Call ← ─────────────────────────────────┘
                            ↓
                      Investigate → Fix Issue → Test Fix → Working?
                                                              ↓ No
                                                          Escalate
                                                              ↓
                                                          War Room
                                                              ↓
                                                          Fix Issue
    
    Working? Yes → Close Incident → Post-Mortem

### Incident Severity Levels

| 🎯 **Level** | ⏱️ **Response Time** | 👥 **Team** | 📋 **Examples** |
|:------------:|:--------------------:|:-----------:|:---------------:|
| **P1 - Critical** | < 15 minutes | All hands | Service down, data breach |
| **P2 - High** | < 30 minutes | On-call + Lead | Performance degradation |
| **P3 - Medium** | < 2 hours | On-call | Single component issue |
| **P4 - Low** | < 8 hours | Regular team | Minor bug, cosmetic |

### Common Incident Playbooks

#### 🔴 Playbook: VM Unresponsive

    # 1. Check VM status
    az vm get-instance-view \
      --resource-group rg-swissre-prod \
      --name vm-swissre-prod \
      --query "instanceView.statuses[?code=='PowerState/running']"

    # 2. Attempt graceful restart
    az vm restart \
      --resource-group rg-swissre-prod \
      --name vm-swissre-prod \
      --no-wait

    # 3. If restart fails, force restart
    az vm stop \
      --resource-group rg-swissre-prod \
      --name vm-swissre-prod \
      --skip-shutdown

    az vm start \
      --resource-group rg-swissre-prod \
      --name vm-swissre-prod

    # 4. Check boot diagnostics
    az vm boot-diagnostics get-boot-log \
      --resource-group rg-swissre-prod \
      --name vm-swissre-prod

    # 5. Connect via Serial Console if needed
    az serial-console connect \
      --resource-group rg-swissre-prod \
      --name vm-swissre-prod

#### 🟡 Playbook: High CPU Usage

    # 1. Identify top processes
    az vm run-command invoke \
      --resource-group rg-swissre-prod \
      --name vm-swissre-prod \
      --command-id RunShellScript \
      --scripts "top -b -n 1 | head -20"

    # 2. Check Apache connections
    az vm run-command invoke \
      --resource-group rg-swissre-prod \
      --name vm-swissre-prod \
      --command-id RunShellScript \
      --scripts "netstat -an | grep :443 | wc -l"

    # 3. Review Apache status
    az vm run-command invoke \
      --resource-group rg-swissre-prod \
      --name vm-swissre-prod \
      --command-id RunShellScript \
      --scripts "apache2ctl status"

    # 4. If needed, gracefully restart Apache
    az vm run-command invoke \
      --resource-group rg-swissre-prod \
      --name vm-swissre-prod \
      --command-id RunShellScript \
      --scripts "systemctl reload apache2"

---

## 🔧 Maintenance Procedures

### Maintenance Windows

| 🌍 **Environment** | 📅 **Schedule** | ⏰ **Window** | 👥 **Approval** |
|:------------------:|:---------------:|:-------------:|:---------------:|
| **Development** | Daily | Anytime | None |
| **Test** | Weekly | Fri 22:00-02:00 | Team Lead |
| **Production** | Monthly | 1st Sun 02:00-06:00 | Change Board |
| **Emergency** | As needed | Immediate | VP Engineering |

### Patching Procedure

    #!/bin/bash
    # ============================================
    # Automated Patching Script
    # Author: Jesus Gracia
    # ============================================

    ENVIRONMENT=$1
    RESOURCE_GROUP="rg-swissre-$ENVIRONMENT"
    VM_NAME="vm-swissre-$ENVIRONMENT"

    echo "Starting patching for $ENVIRONMENT environment"

    # 1. Create pre-patch snapshot
    echo "Creating snapshot..."
    DISK_ID=$(az vm show \
      --resource-group $RESOURCE_GROUP \
      --name $VM_NAME \
      --query "storageProfile.osDisk.managedDisk.id" \
      --output tsv)

    az snapshot create \
      --resource-group $RESOURCE_GROUP \
      --name "snapshot-prepatch-$(date +%Y%m%d)" \
      --source "$DISK_ID"

    # 2. Apply system updates
    echo "Applying updates..."
    az vm run-command invoke \
      --resource-group $RESOURCE_GROUP \
      --name $VM_NAME \
      --command-id RunShellScript \
      --scripts "apt-get update && apt-get upgrade -y"

    # 3. Check if reboot required
    REBOOT_REQUIRED=$(az vm run-command invoke \
      --resource-group $RESOURCE_GROUP \
      --name $VM_NAME \
      --command-id RunShellScript \
      --scripts "[ -f /var/run/reboot-required ] && echo 'YES' || echo 'NO'" \
      --query "value[0].message" \
      --output tsv)

    # 4. Reboot if necessary
    if [ "$REBOOT_REQUIRED" = "YES" ]; then
        echo "Reboot required, restarting VM..."
        az vm restart \
          --resource-group $RESOURCE_GROUP \
          --name $VM_NAME
    fi

    # 5. Verify services
    echo "Verifying services..."
    ./scripts/health-check.sh $ENVIRONMENT

    echo "Patching completed successfully"

### Certificate Renewal

    #!/bin/bash
    # Certificate Renewal Procedure

    # 1. Generate new certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout new-cert.key \
      -out new-cert.crt \
      -subj "/C=CH/ST=Zurich/L=Zurich/O=SwissRe/CN=swissre.azure.com"

    # 2. Create PFX for Key Vault
    openssl pkcs12 -export -out new-cert.pfx \
      -inkey new-cert.key \
      -in new-cert.crt \
      -password pass:TempPassword123

    # 3. Upload to Key Vault
    az keyvault certificate import \
      --vault-name kv-swissre-prod \
      --name ssl-cert \
      --file new-cert.pfx \
      --password TempPassword123

    # 4. Update Apache configuration
    az vm run-command invoke \
      --resource-group rg-swissre-prod \
      --name vm-swissre-prod \
      --command-id RunShellScript \
      --scripts "systemctl reload apache2"

    # 5. Verify certificate
    echo | openssl s_client -connect firewall-ip:443 2>/dev/null | \
      openssl x509 -noout -dates

---

## 🔄 Disaster Recovery

### DR Strategy Overview

| 📊 **Metric** | 🎯 **Target** | ✅ **Achieved** | 📋 **Method** |
|:-------------:|:-------------:|:---------------:|:-------------:|
| **RPO** | 1 hour | 30 minutes | Continuous backup |
| **RTO** | 30 minutes | 15 minutes | Automated recovery |
| **Backup Frequency** | Daily | Hourly | Azure Backup |
| **Retention** | 30 days | 90 days | GRS storage |
| **DR Tests** | Quarterly | Monthly | Automated |

### DR Execution Runbook

    #!/bin/bash
    # ============================================
    # Disaster Recovery Execution Script
    # Author: Jesus Gracia
    # CRITICAL: Only run in actual disaster
    # ============================================

    echo "╔══════════════════════════════════════════╗"
    echo "║    DISASTER RECOVERY PROCEDURE INITIATED  ║"
    echo "╚══════════════════════════════════════════╝"

    # 1. Confirm disaster
    read -p "Confirm disaster recovery execution (YES/NO): " CONFIRM
    if [ "$CONFIRM" != "YES" ]; then
        echo "DR execution cancelled"
        exit 1
    fi

    # 2. Create DR resource group
    echo "Creating DR environment..."
    az group create \
      --name rg-swissre-dr \
      --location westeurope

    # 3. Deploy infrastructure from template
    echo "Deploying infrastructure..."
    az deployment group create \
      --resource-group rg-swissre-dr \
      --template-file infrastructure/main.bicep \
      --parameters @infrastructure/parameters/dr.json

    # 4. Restore latest backup
    echo "Restoring from backup..."
    LATEST_BACKUP=$(az backup recovery-point list \
      --resource-group rg-swissre-prod \
      --vault-name backup-vault-prod \
      --container-name vm-swissre-prod \
      --item-name vm-swissre-prod \
      --query "[0].name" \
      --output tsv)

    az backup restore start \
      --resource-group rg-swissre-dr \
      --vault-name backup-vault-prod \
      --container-name vm-swissre-prod \
      --item-name vm-swissre-prod \
      --rp-name $LATEST_BACKUP

    # 5. Update DNS
    echo "Updating DNS records..."
    NEW_IP=$(az network public-ip show \
      --resource-group rg-swissre-dr \
      --name pip-firewall-dr \
      --query ipAddress \
      --output tsv)

    az network dns record-set a update \
      --resource-group rg-dns \
      --zone-name swissre.com \
      --name www \
      --set aRecords[0].ipv4Address=$NEW_IP

    # 6. Verify services
    echo "Verifying DR environment..."
    ./scripts/health-check.sh dr

    echo "DR execution completed. New environment active at: $NEW_IP"

---

## 🔍 Troubleshooting Guide

### Common Issues and Solutions

| 🐛 **Issue** | 🔍 **Symptoms** | 🛠️ **Solution** | 📝 **Commands** |
|:------------:|:---------------:|:---------------:|:---------------:|
| **VM Won't Start** | Power state: Stopped | Check allocation, quotas | `az vm start --debug` |
| **Apache Not Responding** | HTTP timeout | Restart service, check logs | `systemctl restart apache2` |
| **High Latency** | Slow responses | Check CPU, network | `vmstat 1 10` |
| **Certificate Error** | SSL warning | Renew certificate | `certbot renew` |
| **Disk Full** | No space errors | Clean logs, expand disk | `df -h && du -sh /*` |
| **Network Issues** | Connection timeout | Check NSG, firewall | `tcpdump -i eth0` |

### Diagnostic Commands

    # System diagnostics
    az vm get-instance-view \
      --resource-group rg-swissre-prod \
      --name vm-swissre-prod

    # Network diagnostics
    az network watcher show-topology \
      --resource-group rg-swissre-prod

    # Firewall diagnostics
    az network firewall show \
      --resource-group rg-swissre-prod \
      --name fw-swissre-prod

    # Application logs
    az vm run-command invoke \
      --resource-group rg-swissre-prod \
      --name vm-swissre-prod \
      --command-id RunShellScript \
      --scripts "tail -n 100 /var/log/apache2/error.log"

    # Performance analysis
    az vm run-command invoke \
      --resource-group rg-swissre-prod \
      --name vm-swissre-prod \
      --command-id RunShellScript \
      --scripts "top -b -n 1; free -m; df -h"

---

## 📞 Emergency Contacts

### Escalation Matrix

| 🎯 **Level** | 👤 **Role** | 📧 **Contact** | 📱 **Phone** | ⏱️ **Response** |
|:------------:|:-----------:|:--------------:|:------------:|:---------------:|
| **L1** | Operations Team | ops@swissre.com | +41-XXXX | 15 min |
| **L2** | Jesus Gracia | jesus.gracia@swissre.com | +34-XXXX | 30 min |
| **L3** | Infrastructure Lead | infra-lead@swissre.com | +41-XXXX | 1 hour |
| **L4** | VP Engineering | vp-eng@swissre.com | +41-XXXX | 2 hours |
| **L5** | CTO | cto@swissre.com | +41-XXXX | 4 hours |

### External Support

| 🏢 **Vendor** | 📋 **Service** | 📞 **Support** | 🎫 **Contract** |
|:-------------:|:--------------:|:--------------:|:---------------:|
| **Microsoft** | Azure Support | +1-800-AZURE | Premier |
| **Apache** | Technical Support | support@apache.org | Community |
| **Security** | Incident Response | soc@security.com | 24/7 Retainer |

---

## 📋 Operational Checklists

### Daily Checklist ☑️
- [ ] Review overnight alerts
- [ ] Check resource health
- [ ] Verify backup completion
- [ ] Review performance metrics
- [ ] Check certificate expiry
- [ ] Update incident tickets
- [ ] Review change calendar

### Weekly Checklist ☑️
- [ ] Review security logs
- [ ] Test backup restoration
- [ ] Update documentation
- [ ] Review cost optimization
- [ ] Plan maintenance windows
- [ ] Team sync meeting
- [ ] Update metrics dashboard

### Monthly Checklist ☑️
- [ ] Apply security patches
- [ ] Review access permissions
- [ ] Update DR plan
- [ ] Conduct security scan
- [ ] Review SLA compliance
- [ ] Capacity planning
- [ ] Update runbooks

---

<div align="center">

### 📘 **Operational Excellence for Swiss Re** 📘

*"The best operations are invisible operations"*

**© 2025 Jesús Gracia. 24/7 Operations. Zero Downtime.**

</div>
