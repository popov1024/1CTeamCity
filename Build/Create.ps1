#
# Create.ps1
#
# Usage exaple: "%env.1cbin%" "%system.1c-rep%" "%system.1c-rep-login%" "%system.1c-rep-password%"
#
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$True)]
	[string]$bin,
	
	[Parameter(Mandatory=$True)]
	[string]$rep,

	[Parameter(Mandatory=$True)]
	[string]$repu,

	[Parameter(Mandatory=$True)]
	[string]$repp
)

#$DebugPreference = "Continue"

# The general param of 1C's command line 
$param1c_general = " DESIGNER /F " + [String]$pwd + " /ConfigurationRepositoryF" + $rep + " /ConfigurationRepositoryN" + $repu + " /ConfigurationRepositoryP" + $repp + " "
Write-Debug "General params: $param1c_general"

if (Test-Path "1Cv8.1CD") {
	Write-Host "The information base has been created"
	exit
}


# Create infobase
Write-Host "##teamcity[progressStart 'Creating']"
$param1c_create = " CREATEINFOBASE File=. "
Write-Debug "Create params: $param1c_create"
Start-Process $bin $param1c_create -Wait
Start-Sleep -s 1
Write-Host "##teamcity[progressFinish 'Creating']"


# Bind to repository
Write-Host "##teamcity[progressStart 'Binding']"
$param1c_bind = $param1c_general + " /ConfigurationRepositoryBindCfg -forceBindAlreadyBindedUser -forceReplaceCfg"
Write-Debug "Bind params: $param1c_bind"

Start-Process $bin $param1c_bind -Wait
Start-Sleep -s 1
Write-Host "##teamcity[progressFinish 'Binding']"

# Update
Write-Host "##teamcity[progressStart 'Updating']"
$param1c_update = $param1c_general + " /ConfigurationRepositoryUpdateCfg -force /UpdateDBCfg"
Write-Debug "Update params: $param1c_update"

Start-Process $bin $param1c_update -Wait
Start-Sleep -s 1
Write-Host "##teamcity[progressFinish 'Updating']"