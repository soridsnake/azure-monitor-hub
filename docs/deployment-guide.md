# 📖 Azure Monitor Hub - Deployment Guide

Complete step-by-step guide for deploying Azure Monitor Hub in any environment.

---

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Deployment Scenarios](#deployment-scenarios)
3. [Step-by-Step Deployment](#step-by-step-deployment)
4. [Post-Deployment Configuration](#post-deployment-configuration)
5. [Verification Steps](#verification-steps)
6. [Rollback Procedure](#rollback-procedure)

---

## Pre-Deployment Checklist

### ✅ Azure Requirements

- [ ] Azure Subscription with active credits
- [ ] Contributor or Owner role on subscription
- [ ] Sufficient quota for:
  - Log Analytics Workspace
  - Data Collection Rules
  - Alert Rules
  - Workbooks
- [ ] No conflicting Azure Policies that block deployments

### ✅ Network Requirements

- [ ] VMs can communicate with Azure Monitor endpoints
- [ ] No firewall rules blocking agent communication
- [ ] Required endpoints whitelisted (if using proxy):
```
  *.ods.opinsights.azure.com
  *.oms.opinsights.azure.com
  *.blob.core.windows.net
  *.azure-automation.net
```

### ✅ Permission Requirements

Minimum required roles:

| Resource Type | Required Role |
|--------------|---------------|
| Subscription | Contributor |
| Resource Group | Contributor |
| Virtual Machines | Virtual Machine Contributor |
| Log Analytics | Log Analytics Contributor |
| Monitoring | Monitoring Contributor |

### ✅ Tool Requirements

Run validation script:
```powershell
.\workload\scripts\Validate-Prerequisites.ps1
```

Expected output:
```
✅ PowerShell 7.x
✅ Az.Accounts
✅ Az.Resources
✅ Az.Monitor
✅ Bicep CLI
✅ Azure Connection
✅ Azure Permissions
```

---

## Deployment Scenarios

### Scenario 1: Greenfield Deployment (New Environment)

**Use Case**: New Azure subscription, no existing monitoring infrastructure

**Components Created**:
- New Resource Group
- New Log Analytics Workspace
- New Data Collection Rules
- New Alert Rules
- New Action Group
- New Dashboard

**Command**:
```powershell
.\workload\scripts\Deploy-MonitorHub.ps1 `
    -SubscriptionId "YOUR-SUB-ID" `
    -DeploymentName "prod-monitoring" `
    -Location "westeurope" `
    -EmailRecipients "admin@company.com"
```

---

### Scenario 2: Brownfield Deployment (Existing Infrastructure)

**Use Case**: Existing Log Analytics Workspace, want to add VM monitoring

**Components Created**:
- Uses existing Resource Group
- Uses existing Log Analytics Workspace
- New Data Collection Rules
- New Alert Rules
- New Action Group
- New Dashboard

**Command**:
```powershell
.\workload\scripts\Deploy-MonitorHub.ps1 `
    -SubscriptionId "YOUR-SUB-ID" `
    -DeploymentName "prod-monitoring" `
    -Location "westeurope" `
    -UseExistingResourceGroup `
    -ExistingResourceGroupName "rg-existing" `
    -UseExistingLogAnalytics `
    -ExistingLogAnalyticsWorkspaceId "/subscriptions/xxx/resourceGroups/rg-existing/providers/Microsoft.OperationalInsights/workspaces/law-central" `
    -EmailRecipients "admin@company.com"
```

---

### Scenario 3: Multi-Client MSP Deployment

**Use Case**: MSP managing multiple clients, standardized monitoring

**Strategy**: Deploy one instance per client with naming convention

**Client 1**:
```powershell
.\workload\scripts\Deploy-MonitorHub.ps1 `
    -SubscriptionId "CLIENT1-SUB-ID" `
    -DeploymentName "client1-monitoring" `
    -Location "westeurope" `
    -EmailRecipients "client1@company.com;msp@company.com" `
    -Tags @{
        Client = "Client1"
        Environment = "Production"
        ManagedBy = "MSP"
    }
```

**Client 2**:
```powershell
.\workload\scripts\Deploy-MonitorHub.ps1 `
    -SubscriptionId "CLIENT2-SUB-ID" `
    -DeploymentName "client2-monitoring" `
    -Location "northeurope" `
    -EmailRecipients "client2@company.com;msp@company.com" `
    -Tags @{
        Client = "Client2"
        Environment = "Production"
        ManagedBy = "MSP"
    }
```

---

### Scenario 4: Development/Test Environment

**Use Case**: Lower cost monitoring for non-production VMs

**Configuration**:
- Lower retention (30 days)
- Higher alert thresholds
- Reduced sampling frequency

**Command**:
```powershell
.\workload\scripts\Deploy-MonitorHub.ps1 `
    -SubscriptionId "DEV-SUB-ID" `
    -DeploymentName "dev-monitoring" `
    -Location "westeurope" `
    -RetentionInDays 30 `
    -CPUThreshold 90 `
    -MemoryThreshold 90 `
    -DiskThreshold 90 `
    -EmailRecipients "dev-team@company.com"
```

---

## Step-by-Step Deployment

### Method 1: PowerShell Script (Recommended)

#### Step 1: Clone Repository
```powershell
# Clone from GitHub (replace with your repo URL)
git clone https://github.com/YOUR-ORG/azure-monitor-hub.git
cd azure-monitor-hub
```

#### Step 2: Review Configuration

Edit parameters if needed:
```powershell
# Open in VS Code
code .\workload\scripts\Deploy-MonitorHub.ps1
```

#### Step 3: Connect to Azure
```powershell
# Login to Azure
Connect-AzAccount

# Select subscription
Set-AzContext -SubscriptionId "YOUR-SUBSCRIPTION-ID"

# Verify context
Get-AzContext
```

#### Step 4: Run Deployment
```powershell
# Basic deployment
.\workload\scripts\Deploy-MonitorHub.ps1 `
    -SubscriptionId "YOUR-SUB-ID" `
    -DeploymentName "my-monitoring" `
    -Location "westeurope" `
    -EmailRecipients "your-email@company.com" `
    -Verbose
```

#### Step 5: Monitor Progress

The script will output:
```
[2025-01-15 10:00:00] [Info] Checking prerequisites...
[2025-01-15 10:00:05] [Success] Prerequisites check completed
[2025-01-15 10:00:10] [Info] Connecting to Azure...
[2025-01-15 10:00:15] [Success] Connected to subscription: Production (xxx-xxx)
[2025-01-15 10:00:20] [Info] Discovering Virtual Machines...
[2025-01-15 10:00:30] [Success] Found 5 Virtual Machine(s)
[2025-01-15 10:00:35] [Info] Starting deployment...
[2025-01-15 10:15:00] [Success] Deployment completed successfully!
```

#### Step 6: Review Outputs
```
========================================
  DEPLOYMENT COMPLETED SUCCESSFULLY
========================================

📊 Deployment Outputs:
  Resource Group: rg-my-monitoring
  Log Analytics Workspace: law-my-monitoring
  Workspace ID: xxx-xxx-xxx-xxx-xxx

🎨 Dashboard URL:
  https://portal.azure.com/#blade/AppInsightsExtension/...

✅ Next Steps:
  1. Wait 5-10 minutes for data to start flowing
  2. Open the Dashboard URL above to view VM status
  3. Check your email for alert notifications
  4. Review the deployed resources in the Azure Portal
```

---

### Method 2: Azure Portal Deployment

#### Step 1: Click Deploy Button

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template)

#### Step 2: Fill Basics Tab

![Basics](../images/portal-step1-basics.png)

- **Subscription**: Select your subscription
- **Deployment Name**: Enter unique name (e.g., `prod-monitoring`)

#### Step 3: Configure Infrastructure

![Infrastructure](../images/portal-step2-infrastructure.png)

**Resource Group**:
- ○ Create new
- ○ Use existing → Select from dropdown

**Log Analytics Workspace**:
- ○ Create new → Enter name
- ○ Use existing → Select from dropdown
- **Retention**: 90 days (adjust as needed)

#### Step 4: Configure Monitoring

![Monitoring](../images/portal-step3-monitoring.png)

**Virtual Machines**:
- ☑ Monitor existing VMs
- Select VMs from dropdown
- ☑ Auto-enroll new VMs

**Metrics & Alerts**:
- ☑ CPU Usage Alerts → Threshold: 85%
- ☑ Memory Usage Alerts → Threshold: 85%
- ☑ Disk Space Alerts → Threshold: 85%
- ☑ VM Heartbeat Alerts

#### Step 5: Configure Notifications

![Notifications](../images/portal-step4-notifications.png)

- ☑ Create Action Group
- **Action Group Name**: `ag-prod-monitoring`
- **Email Recipients**: `admin@company.com;ops@company.com`

#### Step 6: Configure Dashboard

![Dashboard](../images/portal-step5-dashboard.png)

- ☑ Deploy Nagios-style Dashboard
- **Dashboard Name**: `VM Monitoring Dashboard`

#### Step 7: Add Tags

![Tags](../images/portal-step6-tags.png)

Add organizational tags:
```
Environment: Production
ManagedBy: IT-Operations
CostCenter: 12345
```

#### Step 8: Review + Create

- Review all settings
- Click **Create**
- Wait 5-10 minutes for deployment

---

### Method 3: Azure CLI Deployment

#### Step 1: Prepare Parameters File

Create `parameters.json`:
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "deploymentName": {
      "value": "prod-monitoring"
    },
    "location": {
      "value": "westeurope"
    },
    "emailRecipients": {
      "value": "admin@company.com"
    },
    "cpuThreshold": {
      "value": 85
    },
    "memoryThreshold": {
      "value": 85
    },
    "diskThreshold": {
      "value": 85
    }
  }
}
```

#### Step 2: Deploy
```bash
# Login
az login

# Set subscription
az account set --subscription "YOUR-SUBSCRIPTION-ID"

# Deploy
az deployment sub create \
  --name "monitor-hub-$(date +%Y%m%d-%H%M%S)" \
  --location "westeurope" \
  --template-file ./workload/bicep/deploy.bicep \
  --parameters ./parameters.json \
  --verbose
```

#### Step 3: Monitor Deployment
```bash
# Check deployment status
az deployment sub show \
  --name "monitor-hub-20250115-100000" \
  --query "properties.provisioningState"

# Get outputs
az deployment sub show \
  --name "monitor-hub-20250115-100000" \
  --query "properties.outputs"
```

---

## Post-Deployment Configuration

### 1. Verify Agent Installation

Check if Azure Monitor Agent is installed on VMs:
```powershell
# PowerShell
Get-AzVM | ForEach-Object {
    $vm = $_
    $extensions = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
    $amaExtension = $extensions | Where-Object { $_.Publisher -eq "Microsoft.Azure.Monitor" }
    
    [PSCustomObject]@{
        VMName = $vm.Name
        AMAInstalled = ($null -ne $amaExtension)
        ExtensionStatus = $amaExtension.ProvisioningState
    }
}
```
```bash
# Azure CLI
az vm extension list \
  --resource-group "rg-name" \
  --vm-name "vm-name" \
  --query "[?publisher=='Microsoft.Azure.Monitor']"
```

### 2. Test Alert Rules

Manually trigger an alert to test:
```powershell
# Simulate high CPU on a test VM
# (Run this on the VM itself)

# Windows
Start-Process powershell -ArgumentList {
    while($true) {
        Get-Process | Out-Null
    }
}

# Linux
yes > /dev/null &
```

Wait 5-10 minutes and check if alert email arrives.

### 3. Customize Dashboard

1. Navigate to Azure Portal → Monitor → Workbooks
2. Find your dashboard
3. Click "Edit"
4. Modify queries, add charts, change colors
5. Click "Save"

### 4. Configure Additional Recipients

Add more email addresses to Action Group:
```powershell
# Get Action Group
$actionGroup = Get-AzActionGroup -ResourceGroupName "rg-name" -Name "ag-name"

# Add email receiver
$actionGroup.EmailReceivers += @{
    name = "ops-team"
    emailAddress = "ops@company.com"
    useCommonAlertSchema = $true
}

# Update
Set-AzActionGroup -ResourceGroupName "rg-name" -Name "ag-name" -ActionGroup $actionGroup
```

### 5. Fine-Tune Alert Thresholds

Based on observed baselines, adjust thresholds:
```powershell
# Update CPU alert threshold
Update-AzScheduledQueryRule `
    -ResourceGroupName "rg-name" `
    -Name "alert-cpu" `
    -Criteria @{
        threshold = 90  # Changed from 85 to 90
    }
```

---

## Verification Steps

### ✅ Checklist

After deployment, verify:

- [ ] **Resource Group created** (or existing one used)
```powershell
  Get-AzResourceGroup -Name "rg-my-monitoring"
```

- [ ] **Log Analytics Workspace operational**
```powershell
  Get-AzOperationalInsightsWorkspace -ResourceGroupName "rg-name" -Name "law-name"
```

- [ ] **Data Collection Rules deployed**
```powershell
  Get-AzDataCollectionRule -ResourceGroupName "rg-name"
```

- [ ] **VMs associated with DCR**
```powershell
  Get-AzDataCollectionRuleAssociation -TargetResourceId "/subscriptions/.../virtualMachines/vm-name"
```

- [ ] **Azure Monitor Agent installed on VMs**
```powershell
  Get-AzVMExtension -ResourceGroupName "rg-name" -VMName "vm-name" | Where-Object { $_.Publisher -eq "Microsoft.Azure.Monitor" }
```

- [ ] **Alert Rules created**
```powershell
  Get-AzScheduledQueryRule -ResourceGroupName "rg-name"
```

- [ ] **Action Group configured**
```powershell
  Get-AzActionGroup -ResourceGroupName "rg-name" -Name "ag-name"
```

- [ ] **Dashboard deployed**
```powershell
  Get-AzApplicationInsightsWorkbook -ResourceGroupName "rg-name"
```

- [ ] **Data flowing to Log Analytics** (wait 10-15 mins)
```kusto
  Heartbeat
  | where TimeGenerated > ago(30m)
  | summarize count() by Computer
```

- [ ] **Test alert triggered** (optional)

---

## Troubleshooting Common Issues

### Issue 1: Deployment Fails with "QuotaExceeded"

**Error**:
```
Code: QuotaExceeded
Message: Operation could not be completed as it results in exceeding approved quota
```

**Solution**:
1. Check current quota usage:
```powershell
   Get-AzVMUsage -Location "westeurope"
```
2. Request quota increase:
   - Azure Portal → Subscriptions → Usage + quotas
   - Select resource type
   - Request increase

---

### Issue 2: VMs Not Sending Data

**Symptoms**:
- VMs don't appear in dashboard
- No data in Log Analytics

**Solution**:
1. Check agent status on VM:
```powershell
   # Windows
   Get-Service -Name AzureMonitorAgent
   
   # Linux
   systemctl status azuremonitoragent
```

2. Check DCR association:
```powershell
   Get-AzDataCollectionRuleAssociation -TargetResourceId "/subscriptions/.../virtualMachines/vm-name"
```

3. Check network connectivity:
```powershell
   # From VM, test connectivity
   Test-NetConnection -ComputerName "global.handler.control.monitor.azure.com" -Port 443
```

4. Review agent logs:
   - Windows: `C:\WindowsAzure\Logs\Plugins\Microsoft.Azure.Monitor.AzureMonitorWindowsAgent`
   - Linux: `/var/log/azure/Microsoft.Azure.Monitor.AzureMonitorLinuxAgent/`

---

### Issue 3: No Alerts Received

**Symptoms**:
- Metrics exceed thresholds but no emails

**Solution**:
1. Verify Action Group email:
```powershell
   Get-AzActionGroup -ResourceGroupName "rg-name" -Name "ag-name" | Select-Object -ExpandProperty EmailReceivers
```

2. Check spam folder

3. Test Action Group manually:
```powershell
   Test-AzActionGroup -ActionGroupResourceId "/subscriptions/.../actionGroups/ag-name" -EmailReceiver "email@company.com"
```

4. Check alert rule status:
```powershell
   Get-AzScheduledQueryRule -ResourceGroupName "rg-name" | Select-Object Name, Enabled
```

---

## Rollback Procedure

If deployment has issues and you need to rollback:

### Full Rollback (Remove Everything)
```powershell
# Delete entire Resource Group
Remove-AzResourceGroup -Name "rg-my-monitoring" -Force
```

### Partial Rollback (Keep Log Analytics)
```powershell
# Remove only specific resources
Remove-AzDataCollectionRule -ResourceGroupName "rg-name" -Name "dcr-name"
Remove-AzScheduledQueryRule -ResourceGroupName "rg-name" -Name "alert-name"
Remove-AzActionGroup -ResourceGroupName "rg-name" -Name "ag-name"
```

### Rollback Azure Policy
```powershell
# Remove policy assignment
Remove-AzPolicyAssignment -Name "assign-auto-enroll" -Scope "/subscriptions/xxx"

# Remove policy definition
Remove-AzPolicySetDefinition -Name "policy-auto-enroll" -ManagementGroupName "xxx"
```

---

## Next Steps

After successful deployment:

1. 📊 **Review Dashboard** - Open the dashboard URL and explore metrics
2. 📧 **Test Alerts** - Trigger a test alert to verify notifications
3. 🎨 **Customize** - Adjust thresholds and dashboard to your needs
4. 📚 **Documentation** - Document your specific configuration
5. 🔄 **Iterate** - Monitor costs and adjust retention/sampling as needed

---

**Need Help?**
- [Troubleshooting Guide](troubleshooting.md)
- [FAQ](faq.md)
- [GitHub Issues](https://github.com/YOUR-ORG/azure-monitor-hub/issues)