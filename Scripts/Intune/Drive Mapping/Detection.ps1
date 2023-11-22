########## Create log file. ##########
$logFileLocation = "C:\ProgramData\Remediations\DriveMapping\X-Drive"
$logFileName = "Detect-X-Drive-Scheduled-Task.log"

# Remove log file if found.
if (Test-Path -path $logFileLocation\$logfileName) {
    Remove-Item -Path $logFileLocation\$logfileName 
}

New-Item -Path $logFileLocation -Name $logFileName -ItemType File -Force
function WriteToLogFile($message) {
    Add-Content "$logFileLocation\$logFileName" -Value "$(Get-Date) - $($message)"
}
WriteToLogFile "Log Created\Updated."
WriteToLogFile "Script begins now."

$task = Get-scheduledTask -TaskName "Map-X-Drive" -ErrorAction SilentlyContinue

if ( ($task).Count -gt 0 ) {
    WriteToLogFile "$($task.TaskName) task already exists."
    WriteToLogFile "Exiting with Code 0, nothing to remediate."
    Exit 0
}else {
    WriteToLogFile "Task does not exist."
    WriteToLogFile "Exiting with Code 1, remediation script should run."
    Exit 1
}
