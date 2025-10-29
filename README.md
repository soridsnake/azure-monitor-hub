# 🖥️ Azure Monitor Hub

**Complete Azure VM Monitoring Solution** - Deploy enterprise-grade monitoring for your Azure Virtual Machines in minutes with automated alerts, dashboards, and compliance reporting.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fsoridsnake%2Fazure-monitor-hub%2Fmain%2Fportal-ui%2Fdeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Fsoridsnake%2Fazure-monitor-hub%2Fmain%2Fportal-ui%2FcreateUiDefinition.json%3Fv%3D5)



---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Deployment Options](#deployment-options)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Dashboard](#dashboard)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## 🎯 Overview

Azure Monitor Hub is an **Infrastructure-as-Code accelerator** that deploys a complete VM monitoring solution including:

- ✅ Log Analytics Workspace with VM Insights
- ✅ Data Collection Rules (DCR) for Windows and Linux VMs
- ✅ Azure Monitor Agent automatic installation
- ✅ Pre-configured alert rules (CPU, Memory, Disk, Heartbeat)
- ✅ Email notification system
- ✅ Real-time dashboard (Nagios-style)
- ✅ Azure Policy for automatic VM enrollment
- ✅ Multi-environment support

**Perfect for:**
- System Engineers managing Azure infrastructure
- IT Operations teams needing standardized monitoring
- MSPs serving multiple clients
- DevOps teams implementing observability

---

## ✨ Features

### 🔍 **Comprehensive Monitoring**
- CPU utilization tracking
- Memory usage monitoring
- Disk space alerts
- Network performance metrics
- VM heartbeat/health checks

### 🚨 **Intelligent Alerting**
- Configurable thresholds for all metrics
- Multi-channel notifications (Email, SMS, webhooks)
- Severity-based alert routing
- Alert suppression and grouping

### 📊 **Visual Dashboards**
- **Nagios-style status view** with color-coded health indicators
- Real-time metric charts
- Top resource consumers
- Historical trend analysis
- Drill-down capabilities

### 🤖 **Automation**
- Automatic VM discovery and enrollment
- Azure Policy-based compliance
- Self-healing capabilities
- Zero-touch VM onboarding

### 🏢 **Enterprise-Ready**
- Multi-tenant support
- RBAC integration
- Tag-based resource organization
- Audit logging
- Cost optimization

---

## 🏗️ Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Subscription                      │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           Log Analytics Workspace                    │  │
│  │  • VM Insights Solution                              │  │
│  │  • Custom Logs & Metrics                             │  │
│  └──────────────────────────────────────────────────────┘  │
│                          ▲                                  │
│                          │                                  │
│  ┌───────────────────────┴──────────────────────────────┐  │
│  │        Data Collection Rules (DCR)                   │  │
│  │  • Performance Counters                              │  │
│  │  • Event Logs                                        │  │
│  │  • Syslog (Linux)                                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                          ▲                                  │
│           ┌──────────────┼──────────────┐                  │
│           │              │              │                  │
│  ┌────────▼─────┐ ┌─────▼──────┐ ┌────▼─────────┐         │
│  │   VM 1       │ │   VM 2     │ │   VM N       │         │
│  │ (AMA Agent)  │ │ (AMA Agent)│ │ (AMA Agent)  │         │
│  └──────────────┘ └────────────┘ └──────────────┘         │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Alert Rules                             │  │
│  │  • CPU > 85%                                         │  │
│  │  • Memory > 85%                                      │  │
│  │  • Disk > 85%                                        │  │
│  │  • Heartbeat Missing                                 │  │
│  └───────────────────┬──────────────────────────────────┘  │
│                      │                                     │
│                      ▼                                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │            Action Group                              │  │
│  │  • Email Notifications                               │  │
│  │  • SMS (optional)                                    │  │
│  │  • Webhook (optional)                                │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Azure Workbook Dashboard                     │  │
│  │  • Real-time VM Status                               │  │
│  │  • Performance Metrics                               │  │
│  │  • Health Indicators                                 │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │            Azure Policy                              │  │
│  │  • Auto-install AMA on new VMs                       │  │
│  │  • Associate VMs with DCR                            │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Prerequisites

### Required Tools
- **Azure Subscription** with Contributor or Owner role
- **PowerShell 7.0+** (for script-based deployment)
- **Azure PowerShell Module** (`Az`)
- **Bicep CLI** 0.20.0+

### Optional Tools
- **Azure CLI** (alternative deployment method)
- **Git** (for cloning repository)
- **VS Code** with Bicep extension (for customization)

### Validation Script
Run this to check if you have everything:
```powershell
.\workload\scripts\Validate-Prerequisites.ps1
```

---

## 🚀 Deployment Options

### Option 1: Azure Portal (Recommended for Beginners)

Click the button below and follow the wizard:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fsoridsnake%2Fazure-monitor-hub%2Fmain%2Fportal-ui%2Fdeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Fsoridsnake%2Fazure-monitor-hub%2Fmain%2Fportal-ui%2FcreateUiDefinition.json%3Fv%3D5)




**Steps:**
1. Click "Deploy to Azure"
2. Sign in to Azure Portal
3. Fill in the deployment form:
   - **Deployment Name**: Unique name (e.g., `prod-monitoring`)
   - **Resource Group**: Create new or use existing
   - **Log Analytics**: Create new or use existing
   - **VMs to Monitor**: Select VMs from dropdown
   - **Alert Thresholds**: Configure CPU/Memory/Disk limits
   - **Email Recipients**: Enter notification emails
4. Review and click "Create"
5. Wait 5-10 minutes for deployment

---

### Option 2: PowerShell Script (Recommended for Automation)
```powershell
# Clone repository
git clone https://github.com/soridsnake/azure-monitor-hub.git
cd azure-monitor-hub

# Validate prerequisites
.\workload\scripts\Validate-Prerequisites.ps1

# Deploy
.\workload\scripts\Deploy-MonitorHub.ps1 `
    -SubscriptionId "YOUR-SUBSCRIPTION-ID" `
    -DeploymentName "prod-monitoring" `
    -Location "westeurope" `
    -EmailRecipients "admin@company.com;ops@company.com"
```

**Advanced Example with Existing Resources:**
```powershell
.\workload\scripts\Deploy-MonitorHub.ps1 `
    -SubscriptionId "YOUR-SUBSCRIPTION-ID" `
    -DeploymentName "prod-monitoring" `
    -Location "westeurope" `
    -UseExistingLogAnalytics `
    -ExistingLogAnalyticsWorkspaceId "/subscriptions/xxx/resourceGroups/rg-logs/providers/Microsoft.OperationalInsights/workspaces/law-central" `
    -CPUThreshold 90 `
    -MemoryThreshold 90 `
    -DiskThreshold 80 `
    -EmailRecipients "admin@company.com"
```

---

### Option 3: Azure CLI + Bicep
```bash
# Login
az login

# Set subscription
az account set --subscription "YOUR-SUBSCRIPTION-ID"

# Deploy
az deployment sub create \
  --name "monitor-hub-deployment" \
  --location "westeurope" \
  --template-file ./workload/bicep/deploy.bicep \
  --parameters \
    deploymentName="prod-monitoring" \
    location="westeurope" \
    emailRecipients="admin@company.com"
```

---

### Option 4: Azure DevOps Pipeline

Create a pipeline with this YAML:
```yaml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  - name: subscriptionId
    value: 'YOUR-SUBSCRIPTION-ID'
  - name: deploymentName
    value: 'prod-monitoring'
  - name: location
    value: 'westeurope'

steps:
  - task: AzureCLI@2
    displayName: 'Deploy Azure Monitor Hub'
    inputs:
      azureSubscription: 'YOUR-SERVICE-CONNECTION'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        az deployment sub create \
          --name "monitor-hub-$(Build.BuildId)" \
          --location $(location) \
          --template-file ./workload/bicep/deploy.bicep \
          --parameters \
            deploymentName=$(deploymentName) \
            location=$(location) \
            emailRecipients="$(emailRecipients)"
```

---

## ⚙️ Configuration

### Alert Thresholds

Default values (can be customized):

| Metric | Warning | Critical |
|--------|---------|----------|
| CPU | 80% | 85% |
| Memory | 80% | 85% |
| Disk | 80% | 85% |
| Heartbeat | 5 min | 10 min |

### Data Retention

- **Default**: 90 days
- **Range**: 30-730 days
- **Cost Impact**: Higher retention = higher costs

### Auto-Enrollment

When enabled, new VMs are automatically:
- Assigned to Data Collection Rules
- Equipped with Azure Monitor Agent
- Added to alert rules
- Visible in dashboard

---

## 📊 Dashboard

The **Nagios-style dashboard** provides:

### Status Overview
- 🟢 **Healthy**: All metrics normal
- 🟡 **Warning**: Approaching threshold
- 🔴 **Critical**: Threshold exceeded
- ⚫ **Offline**: No heartbeat

### Sections
1. **VM Status Grid**: Real-time health for all VMs
2. **Performance Charts**: CPU, Memory, Disk over time
3. **Top Consumers**: Most resource-intensive VMs
4. **Alert History**: Recent alerts and resolutions

### Accessing Dashboard

After deployment:
```
https://portal.azure.com/#blade/AppInsightsExtension/UsageNotebookBlade/ComponentId/<WORKBOOK-ID>
```

Or navigate: **Azure Portal → Monitor → Workbooks → Your Dashboard**

---

## 🎨 Customization

### Add Custom Metrics

Edit `workload/bicep/modules/data-collection-rules.bicep`:
```bicep
counterSpecifiers: [
  '\\Processor(_Total)\\% Processor Time'
  '\\YourCustomCounter\\YourMetric'  // Add here
]
```

### Modify Alert Logic

Edit `workload/bicep/modules/alert-rules.bicep`:
```bicep
query: 'Perf | where ... | your custom KQL query'
```

### Change Dashboard

Edit `dashboards/workbooks/vm-monitoring-dashboard.json` using:
- Azure Portal Workbook editor
- VS Code with JSON editor

---

## 🔧 Troubleshooting

### Issue: VMs not appearing in dashboard

**Solution:**
1. Check if Azure Monitor Agent is installed:
```powershell
   Get-AzVMExtension -ResourceGroupName "rg-name" -VMName "vm-name"
```
2. Verify DCR association:
```powershell
   Get-AzDataCollectionRuleAssociation -TargetResourceId "/subscriptions/.../virtualMachines/vm-name"
```
3. Wait 10-15 minutes for data ingestion

### Issue: No alerts being sent

**Solution:**
1. Check Action Group configuration
2. Verify email addresses are correct
3. Check spam folder
4. Test Action Group manually

### Issue: High costs

**Solution:**
1. Reduce data retention period
2. Adjust sampling frequency in DCR
3. Filter unwanted logs
4. Use log queries to analyze ingestion

---

## 📚 Documentation

- [Architecture Guide](docs/architecture.md)
- [Deployment Guide](docs/deployment-guide.md)
- [Customization Guide](docs/customization-guide.md)
- [Cost Optimization](docs/cost-optimization.md)
- [Multi-Client Setup](docs/multi-client-setup.md)

---

## 🤝 Contributing

We welcome contributions! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file.

---

## 🙏 Acknowledgments

- Inspired by [AVD Accelerator](https://github.com/Azure/avdaccelerator)
- Built with ❤️ for the Azure community

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/soridsnake/azure-monitor-hub/issues)
- **Discussions**: [GitHub Discussions](https://github.com/soridsnake/azure-monitor-hub/discussions)
- **Email**: support@yourcompany.com

---

**Made with 🖥️ by System Engineers, for System Engineers**