<# Never used\tested this detection script in the end, use with care. #>

########################## Create a log file. ####################################################
$logFileLocation = "C:\ProgramData\Remediations\McAfee"
$logFileName = "DetectMcAfee.log"
# Remove log file if found.
if (Test-Path -path $logFileLocation\$logfileName) { Remove-Item -Path $logFileLocation\$logfileName }
New-Item -Path $logFileLocation -Name $logFileName -ItemType File -Force
function WriteToLogFile($message) { Add-Content $logFileLocation\$logFileName -Value "$(Get-Date) - $($message)" }
WriteToLogFile "Log File Created, script begins now."

########################## Detection Logic. ####################################################
$item = "C:\ProgramData\McAfee\MCS"

try {
    WriteToLogFile "Checking for detection method, $($item)"
    if (Test-Path -path $item){
        WriteToLogFile "McAfee has been detected."
        Write-Host "McAfee detected, exit code 1."
        Exit 1
    } else {
        WriteToLogFile "McAfee not detected."
        Write-Host "McAfee NOT detected, exit code 0."
        Exit 0
    }
}
catch {
    Write-Host "An Error occurred."
    WriteToLogFile "An Error occurred."
    Write-Host $_
    WriteToLogFile $_
}
