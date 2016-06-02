#
# ChangeVersion.ps1
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

# Save current path
$wd = $pwd

# The general param of 1C's command line 
$param1c_general = " DESIGNER /F " + [String]$wd + " /ConfigurationRepositoryF" + $rep + " /ConfigurationRepositoryN" + $repu + " /ConfigurationRepositoryP" + $repp + " "
Write-Debug "General params: $param1c_general"

# Lock configuration
Write-Host "##teamcity[progressStart 'Locking the configuration']"

## Create objects file
$object = @"
<Objects xmlns="http://v8.1c.ru/8.3/config/objects" version="1.0">
	<Configuration includeChildObjects = "false"/>
</Objects>
"@

$object | Out-File objects.xml -encoding UTF8

## Lock configuration
$param1c_lock = $param1c_general + " /ConfigurationRepositoryLock -objects .\objects.xml -revised"
$res_lock = Start-Process $bin $param1c_lock -Wait -PassThru
Start-Sleep -s 1
Write-Debug ("Exit code of lock process: " + $res_lock.ExitCode)

if ($res_lock.ExitCode -eq 1)
{
	Write-Host "##teamcity[message text='The configuration has not been locked' errorDetails='May be another user has locked configuration' status='WARNING']"
	Write-Host "##teamcity[progressFinish 'Locking the configuration']"
	exit(1)
}

Write-Host "##teamcity[progressFinish 'Locking the configuration']"


#Get version

## Dump configuration
Write-Host "##teamcity[progressStart 'Getting version']"
$param1c_dump = $param1c_general + " /DumpConfigToFiles .\dump1c"
Write-Debug "Dump params: $param1c_dump"

Start-Process $bin $param1c_dump -Wait
Start-Sleep -s 1

## Read configuration
$configfile = [String]$wd + "\dump1c\Configuration.xml"
Write-Debug "Congiguration file: $configfile"

if (-not (Test-Path $configfile)) {
	Write-Host "##teamcity[message text='The configuration dump has not been created. The configuration dose not exist' errorDetails='May be the information base was locked' status='FAILURE']"
	Write-Host "##teamcity[progressFinish 'Getting version']"
	exit(1)
}

[xml]$config = Get-Content $configfile
$version = $config.MetaDataObject.Configuration.Properties.Version
Write-Debug "Version: $version"


## Version
$match = [regex]::Match($version, '(\d+\.\d+\.\d+)\.(\d+)')
$version_major = $match.Groups[1].Value
$version_minor = $match.Groups[2].Value
$version_next = "$version_major." + ([int]$version_minor + 1)

Write-Debug "Major: $version_major"
Write-Debug "Minor: $version_minor"
Write-Debug "Next: $version_next"
Write-Host "##teamcity[progressFinish 'Getting version']"

## Set version
Write-Host "##teamcity[progressStart 'Setting new version']"
$config.MetaDataObject.Configuration.Properties.Version = $version_next
$config.Save("$wd\dump1c\Configuration.xml")

$param1c_load = $param1c_general + " /LoadConfigFromFiles .\dump1c"
Write-Debug "Load params: $param1c_load"
Start-Process $bin $param1c_load -Wait
Start-Sleep -s 1

Write-Host "##teamcity[progressFinish 'Setting new version']"


## Commit
Write-Host "##teamcity[progressStart 'Committing']"
$param1c_commit = $param1c_general + ' /ConfigurationRepositoryCommit -objects objects.xml -comment "//change version" -force'
Write-Debug "Commit params: $param1c_commit"
Start-Process $bin $param1c_commit -Wait
Start-Sleep -s 1

Write-Host "##teamcity[progressFinish 'Committing']"

## Clean
try {
	Remove-Item .\dump1c -Force
	Remove-Item .\objects.xml -Force
} catch{}