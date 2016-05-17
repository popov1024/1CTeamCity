#
# Check.ps1
#
# Usage exaple: "%env.1cbin%" "%system.1c-rep%" "%system.1c-rep-login%" "%system.1c-rep-password%" "%system.1c-checks%"
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
	[string]$repp,

	[Parameter(Mandatory=$True)]
	[string]$checks
)

#$DebugPreference = "Continue"

# The general param of 1C's command line 
$param1c_general = " DESIGNER /F " + [String]$pwd + " /ConfigurationRepositoryF" + $rep + " /ConfigurationRepositoryN" + $repu + " /ConfigurationRepositoryP" + $repp + " "
Write-Debug "General params: $param1c_general"

if ($checks -eq "") {
	Write-Host "##teamcity[message text='Test types not selected' status='NORMAL']"
	exit(1)
}

$checks -split ',' | foreach {
	Write-Host "##teamcity[testStarted name='$_']"
	Write-Debug "Check: $_"

	$error_file = "error-$_.txt";
	Write-Debug "Error file: $error_file"

	$param1c_check = $param1c_general + " /CheckConfig -$_  /DumpResult $error_file"
	Write-Debug "Chech param: $param1c_check"

	Start-Process $bin $param1c_check -Wait
	Start-Sleep -s 5

	$error_code = Get-Content $error_file | Select-Object -First 1;
	Write-Debug "Error code: $error_code"
	if ($error_code -ne "0") {
		Write-Host "Error $error_code"
		Write-Host "##teamcity[testFailed name='$_']"
	} else {
		Write-Host "Ok"
	}

	## Clean
	try {
		Remove-Item $error_file -Force
	} catch{}

	Write-Host "##teamcity[testFinished name='$_']"
}