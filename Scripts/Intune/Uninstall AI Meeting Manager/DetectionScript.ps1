#########################################
#              Create Log.              #
#########################################
$logFileLocation = "C:\ProgramData\Remediations\AIMeetingManager"
$logFileName = "Detect-aimeetingmanager.log"
# Remove log file if found by overwriting it.
New-Item -Path $logFileLocation -Name $logFileName -ItemType File -Force
function WriteToLogFile($message) { Add-Content "$logFileLocation\$logFileName" -Value "$(Get-Date) - $($message)" }
WriteToLogFile "Log Created\Updated. Script begins now."

#########################################
#               Detect App              #
#########################################
$regkeyLocation = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$appDisplayName = 'Ai Meeting Manager Service'
WriteToLogFile "RegKey Location set, $($regkeyLocation)."
WriteToLogFile "App name set, $($appDisplayName)."
try {
    # Grab uninstall string from registry
    $uninstallString = (Get-ItemProperty $regkeyLocation | Where-Object displayname -like $appDisplayName).UninstallString
    WriteToLogFile "Checking for $($appDisplayName)"
    if (($uninstallString).Count -gt 0){
        WriteToLogFile "App detected, exiting with code 1, remediation needs to run."
        Exit 1
    } else {
        WriteToLogFile "App does not exist, Exiting with code 0, nothing to uninstall."
        Exit 0
    }
}
catch {
    WriteToLogFile "Something went wrong with the detection."
    WriteToLogFile $_
    # Exit code denotes to MDM of failure to run.
    Exit 1
}
