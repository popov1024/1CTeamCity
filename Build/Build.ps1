#
# Build.ps1
#
# Usage exaple: "%env.1cbin%" "%system.1c-rep%" "%system.1c-rep-login%" "%system.1c-rep-password%" "%system.1c-builds%"
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
	[string]$builds_path
)


#$DebugPreference = "Continue"

# Save current path
$wd = $pwd

# The general param of 1C's command line 
$param1c_general = " DESIGNER /F " + [String]$wd + " /ConfigurationRepositoryF" + $rep + " /ConfigurationRepositoryN" + $repu + " /ConfigurationRepositoryP" + $repp + " "
Write-Debug "General params: $param1c_general"

#Get version

##Dump configuration
Write-Host "##teamcity[progressStart 'Getting version']"
$param1c_dump = $param1c_general + " /DumpConfigToFiles .\dump1c"
Write-Debug "General params: $param1c_dump"

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

## Clean
try {
	Remove-Item .\dump1c -Force
} catch{}

## Version
$match = [regex]::Match($version, '(\d+\.\d+\.\d+)\.(\d+)')
$version_major = $match.Groups[1].Value
$version_minor = $match.Groups[2].Value

Write-Debug "Major: $version_major"
Write-Debug "Minor: $version_minor"
Write-Host "##teamcity[buildNumber '$version']"
Write-Host "##teamcity[progressFinish 'Getting version']"

#Build
Write-Host "##teamcity[progressStart 'Building']"

## Check paths
$build_path = $builds_path + '\' + $version_major
$build_path_version = $build_path + '\' + $version
Write-Debug "Build path: $build_path"
Write-Debug "Build path version: $build_path_version"

if (Test-Path $build_path_version) {
	Write-Host "##teamcity[message text='The build with this version has existed' errorDetails='Perhaps need to change version of configuration' status='FAILURE']"
	Write-Host "##teamcity[progressFinish 'Building']"
    exit(1)
}

## Get pervision versions
cd $build_path
$preversions = ""

$cfs = ls * -Include 1cv8.cf -Recurse | split-path -parent | split-path -leaf
$cfs | foreach {$preversions = $preversions + " -f $_\1cv8.cf -v $_ "}

## Buld!
Write-Host "Build from versions: $cfs"
$param1c_build = $param1c_general + " /CreateDistributionFiles -cffile " + $version + "\1cv8.cf -cfufile " + $version + "\1cv8.cfu " + $preversions + ""
Write-Debug "Buld param: $param1c_build"

Start-Process $bin $param1c_build -Wait
Start-Sleep -s 5
Write-Host "##teamcity[publishArtifacts '$build_path_version']"

cd $wd
Write-Host "##teamcity[progressFinish 'Building']"