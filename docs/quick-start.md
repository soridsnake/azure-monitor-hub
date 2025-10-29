# ⚡ Quick Start Guide

Get Azure Monitor Hub up and running in 5 minutes!

---

## 🎯 Goal

Deploy complete VM monitoring with:
- ✅ Log Analytics Workspace
- ✅ Automatic VM discovery
- ✅ Pre-configured alerts
- ✅ Real-time dashboard
- ✅ Email notifications

**Time Required**: ~5 minutes + 10 minutes for data ingestion

---

## 📋 Prerequisites

- Azure subscription
- 1+ Virtual Machines running
- Your email address for alerts

---

## 🚀 Deployment (Choose One Method)

### Option A: Azure Portal (Easiest)

1. **Click the button**:

   [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template)

2. **Fill the form**:
   - Deployment Name: `my-monitoring`
   - Resource Group: Create new
   - Log Analytics: Create new
   - Select your VMs
   - Enter your email
   - Keep default thresholds (85%)

3. **Click "Create"**

4. **Wait 5-10 minutes**

5. **Done!** Check your email for the dashboard link

---

### Option B: PowerShell (Fastest)
```powershell
# 1. Download script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/YOUR-ORG/azure-monitor-hub/main/workload/scripts/Deploy-MonitorHub.ps1" -OutFile "Deploy-MonitorHub.ps1"

# 2. Run deployment
.\Deploy-MonitorHub.ps1 `
    -SubscriptionId "YOUR-SUB-ID" `
    -DeploymentName "my-monitoring" `
    -Location "westeurope" `
    -EmailRecipients "your-email@company.com"

# 3. Done!
```

---

## ✅ Verification

### Check Dashboard

1. Go to Azure Portal
2. Navigate to **Monitor → Workbooks**
3. Find "VM Monitoring Dashboard"
4. Click to open

You should see:
- 🟢 Green = Healthy VMs
- 🟡 Yellow = Warning
- 🔴 Red = Critical
- ⚫ Black = Offline

### Check Alerts

Trigger a test alert:
1. SSH/RDP to a VM
2. Run CPU stress test:
```bash
   # Linux
   stress --cpu 4 --timeout 300s
   
   # Windows
   # Run multiple PowerShell windows with: while($true){}
```
3. Wait 5-10 minutes
4. Check your email for alert

---

## 🎨 What's Next?

- [Customize Alert Thresholds](deployment-guide.md#post-deployment-configuration)
- [Add More Recipients](deployment-guide.md#configure-additional-recipients)
- [Customize Dashboard](customization-guide.md)
- [Set Up Multi-Client](multi-client-setup.md)

---

## 🆘 Need Help?

**Common Issues**:

❌ **No VMs in dashboard after 10 mins**
→ Check if Azure Monitor Agent is installed: `Get-AzVMExtension`

❌ **No alert emails**
→ Check spam folder, verify email in Action Group

❌ **Deployment failed**
→ Check quota limits, verify permissions

[Full Troubleshooting Guide →](troubleshooting.md)

---

**That's it! You now have enterprise-grade VM monitoring! 🎉**