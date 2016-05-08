#
# Update.ps1
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

#Update
$param1c_update = $param1c_general + " /ConfigurationRepositoryUpdateCfg -force /UpdateDBCfg"
Write-Debug "General params: $param1c_update"

Start-Process $bin $param1c_update -Wait
Start-Sleep -s 1