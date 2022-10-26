<#
.SYNOPSIS
Handle user interaction from shortcuts and show a Toast

.DESCRIPTION
Act on shortcut run (DEFAULT: Check for updated Apps)

.PARAMETER Logs
Open the Log file from Winget-AutoUpdate installation location

.PARAMETER Help
Open the Web Help page
https://github.com/Romanitho/Winget-AutoUpdate

.EXAMPLE
.\user-run.ps1 -Logs

#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $False)] [Switch] $Logs = $false,
	[Parameter(Mandatory = $False)] [Switch] $Help = $false
)

function Test-WAUisRunning {
	If (((Get-ScheduledTask -TaskName 'Winget-AutoUpdate').State -eq 'Running') -or ((Get-ScheduledTask -TaskName 'Winget-AutoUpdate-UserContext').State -eq 'Running')) {
		Return $True
	}
}

<# MAIN #>

#Get Working Dir
$Script:WorkingDir = $PSScriptRoot

#Load external functions
. $WorkingDir\functions\Get-NotifLocale.ps1
. $WorkingDir\functions\Start-NotifTask.ps1

#Set common variables
$OnClickAction = "$WorkingDir\logs\updates.log"
$Title = "Winget-AutoUpdate (WAU)"
$Balise = "Winget-AutoUpdate (WAU)"
$UserRun = $True

#Get Toast Locale function
Get-NotifLocale

if ($Logs) {
	if ((Test-Path "$WorkingDir\logs\updates.log")) {
		Invoke-Item "$WorkingDir\logs\updates.log"
	}
	else {
		#Not available yet
		$Message = $NotifLocale.local.outputs.output[5].message
		$MessageType = "warning"
		Start-NotifTask -Message $Message -MessageType $MessageType
	}
}
elseif ($Help) {
	Start-Process "https://github.com/Romanitho/Winget-AutoUpdate"
}
else {
	try {
		#Check if WAU is currently running
		if (Test-WAUisRunning) {
			$Message = $NotifLocale.local.outputs.output[8].message
			$MessageType = "warning"
			Start-NotifTask -Message $Message -MessageType $MessageType
			break
		}
		#Run scheduled task
		Get-ScheduledTask -TaskName "Winget-AutoUpdate" -ErrorAction Stop | Start-ScheduledTask -ErrorAction Stop
		#Starting check - Send notification
		$Message = $NotifLocale.local.outputs.output[6].message
		$MessageType = "info"
		Start-NotifTask -Message $Message -MessageType $MessageType
		#Sleep until the task is done
		While (Test-WAUisRunning) {
			Start-Sleep 3
		}
		$Message = $NotifLocale.local.outputs.output[9].message
		$MessageType = "success"
		Start-NotifTask -Message $Message -MessageType $MessageType
	}
	catch {
		#Check failed - Just send notification
		$Message = $NotifLocale.local.outputs.output[7].message
		$MessageType = "error"
		Start-NotifTask -Message $Message -MessageType $MessageType
	}
}
