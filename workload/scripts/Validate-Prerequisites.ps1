<#
.SYNOPSIS
    Validate prerequisites for Azure Monitor Hub deployment

.DESCRIPTION
    Checks if all required tools and permissions are in place before deployment
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"

function Write-ValidationResult {
    param(
        [string]$Check,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    if ($Passed) {
        Write-Host "✅ $Check" -ForegroundColor Green
        if ($Message) {
            Write-Host "   $Message" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "❌ $Check" -ForegroundColor Red
        if ($Message) {
            Write-Host "   $Message" -ForegroundColor Yellow
        }
    }
}

Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         PREREQUISITES VALIDATION                          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

$allChecksPassed = $true

# Check 1: PowerShell Version
Write-Host "`n🔍 Checking PowerShell version..." -ForegroundColor Cyan
$psVersion = $PSVersionTable.PSVersion
$minVersion = [Version]"7.0"
if ($psVersion -ge $minVersion) {
    Write-ValidationResult -Check "PowerShell $psVersion" -Passed $true
}
else {
    Write-ValidationResult -Check "PowerShell version" -Passed $false -Message "PowerShell 7.0 or higher required. Current: $psVersion"
    $allChecksPassed = $false
}

# Check 2: Az PowerShell Module
Write-Host "`n🔍 Checking Azure PowerShell modules..." -ForegroundColor Cyan
$requiredModules = @(
    'Az.Accounts',
    'Az.Resources',
    'Az.OperationalInsights',
    'Az.Monitor',
    'Az.Compute'
)

foreach ($module in $requiredModules) {
    $installed = Get-Module -ListAvailable -Name $module
    if ($installed) {
        $version = $installed[0].Version
        Write-ValidationResult -Check "$module ($version)" -Passed $true
    }
    else {
        Write-ValidationResult -Check "$module" -Passed $false -Message "Run: Install-Module -Name $module -AllowClobber -Scope CurrentUser"
        $allChecksPassed = $false
    }
}

# Check 3: Bicep CLI
Write-Host "`n🔍 Checking Bicep CLI..." -ForegroundColor Cyan
try {
    $bicepVersion = & bicep --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-ValidationResult -Check "Bicep CLI" -Passed $true -Message $bicepVersion
    }
    else {
        throw
    }
}
catch {
    Write-ValidationResult -Check "Bicep CLI" -Passed $false -Message "Install from: https://learn.microsoft.com/azure/azure-resource-manager/bicep/install"
    $allChecksPassed = $false
}

# Check 4: Azure CLI (optional but recommended)
Write-Host "`n🔍 Checking Azure CLI (optional)..." -ForegroundColor Cyan
try {
    $azVersion = & az --version 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -eq 0) {
        Write-ValidationResult -Check "Azure CLI" -Passed $true -Message $azVersion
    }
    else {
        throw
    }
}
catch {
    Write-Host "⚠️  Azure CLI not found (optional)" -ForegroundColor Yellow
    Write-Host "   Install from: https://learn.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Gray
}

# Check 5: Azure Connection
Write-Host "`n🔍 Checking Azure connection..." -ForegroundColor Cyan
try {
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if ($context) {
        Write-ValidationResult -Check "Azure Connection" -Passed $true -Message "Connected to: $($context.Subscription.Name)"
    }
    else {
        Write-ValidationResult -Check "Azure Connection" -Passed $false -Message "Run: Connect-AzAccount"
        $allChecksPassed = $false
    }
}
catch {
    Write-ValidationResult -Check "Azure Connection" -Passed $false -Message "Run: Connect-AzAccount"
    $allChecksPassed = $false
}

# Check 6: Required Permissions
Write-Host "`n🔍 Checking Azure permissions..." -ForegroundColor Cyan
if ($context) {
    try {
        $subscriptionId = $context.Subscription.Id
        $assignments = Get-AzRoleAssignment -SignInName $context.Account.Id -Scope "/subscriptions/$subscriptionId" -ErrorAction SilentlyContinue
        
        $hasContributor = $assignments | Where-Object { $_.RoleDefinitionName -in @('Contributor', 'Owner') }
        
        if ($hasContributor) {
            Write-ValidationResult -Check "Azure Permissions" -Passed $true -Message "Sufficient permissions detected"
        }
        else {
            Write-ValidationResult -Check "Azure Permissions" -Passed $false -Message "Contributor or Owner role required on subscription"
            $allChecksPassed = $false
        }
    }
    catch {
        Write-Host "⚠️  Could not verify permissions" -ForegroundColor Yellow
    }
}

# Final Summary
Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
if ($allChecksPassed) {
    Write-Host "✅ ALL CHECKS PASSED - Ready to deploy!" -ForegroundColor Green
    Write-Host "`nYou can now run:" -ForegroundColor Cyan
    Write-Host "  .\Deploy-MonitorHub.ps1 -SubscriptionId '<sub-id>' -DeploymentName '<name>' -Location '<region>' -EmailRecipients '<email>'" -ForegroundColor Yellow
}
else {
    Write-Host "❌ SOME CHECKS FAILED - Please fix the issues above before deploying" -ForegroundColor Red
}
Write-Host ("=" * 60) -ForegroundColor Cyan