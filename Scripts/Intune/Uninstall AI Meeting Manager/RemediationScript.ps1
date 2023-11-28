#########################################
#            Create Log File            #
#########################################
$logFileLocation = "C:\ProgramData\ScriptsAndRemediations\AIMeetingManager"
$logFileName = "Remove-aimeetingmanager.log"
# Remove log file if found by overwriting it.
New-Item -Path $logFileLocation -Name $logFileName -ItemType File -Force
function WriteToLogFile($message) { Add-Content "$logFileLocation\$logFileName" -Value "$(Get-Date) - $($message)" }
WriteToLogFile "Log Created\Updated. Script begins now."

#########################################
#          Try Uninstall of App         #
#########################################
$regkeyLocation = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$appDisplayName = 'Ai Meeting Manager Service'
WriteToLogFile "RegKey Location set, $($regkeyLocation)."
WriteToLogFile "App name set, $($appDisplayName)."
try {
    # Grab uninstall string from registry
    $uninstallString = (Get-ItemProperty $regkeyLocation | Where-Object displayname -like $appDisplayName).UninstallString
    WriteToLogFile "Uninstall string found, $($uninstallString)."
    # Begin the uninstaller silently.
    $process = Start-process $uninstallString -ArgumentList "/SILENT" -PassThru
    WriteToLogFile "$($process.ProcessName) started."
    # Check the application is uninstalling.
    while (Test-Path -Path "C:\Program Files\Lenovo\Ai Meeting Manager Service\Ammbkproc.exe") {
        WriteTologFile "Uninstalling still running."
        Start-Sleep 15
    }
    WriteToLogFile "App removed successfully, exiting with code 0."
    # Exit code denotes to MDM of successfully running.
    Exit 0
}
catch {
    WriteToLogFile "App uninstall failed, exiting with code 1."
    WriteToLogFile $_
    # Exit code denotes to MDM of failure to run.
    Exit 1
}
