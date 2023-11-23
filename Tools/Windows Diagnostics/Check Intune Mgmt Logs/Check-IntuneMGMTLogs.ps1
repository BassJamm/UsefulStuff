<# Script checks the intune Win logs for applicaiton download times. #>
$logFileContent = Get-Content -Path (Get-ChildItem -Path C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ -Filter "IntuneManagement*.log").FullName

###### Identify each row. ######
$filteredLogs = $logFileContent | Where-Object { $_ -match "<!\[LOG\[\[(.+)<time=(.+)>" }

###### Identify the column data. ######
$regexDate = "[0-9]{2}-[0-9]{2}-[0-9]{4}"
$regexTime = "[0-9]{2}:[0-9]{2}:[0-9]{2}"

function Get-Pattern ( $pattern ) {

    switch -Regex  ( $pattern ) {
        '<!\[LOG\[\[StatusService\]\sDownloading\sapp\s\(id\s=\s[\w]{8}-[\w]{4}-[\w]{4}-[\w]{4}-[0-9A-Fa-f]{12},\sname\s(.+?)\)' { "Downloading App" } # Finds application downloading notifications.
        '<!\[LOG\[\[StatusService\]\sProgress\sreport\sis\sbeing\sskipped\sas\sit\sis\snot\sassociated\swith\san\sIntune user.(.+)>' { "Skipping App" } # Finds the downloaded application skipped notifcation that follows after.
        Default {}
    }
}

############ Search for Application Installs ############
$output = foreach ($row in $filteredLogs) {

    [PSCustomObject]@{
        Date    = ( $row | Select-String -Pattern $regexDate ).Matches.Value
        Time    = ( $row | Select-String -Pattern $regexTime ).Matches.Value
        Message = ( $row | Select-String -Pattern "\s(.*?)\]" ).Matches.Value -replace "]", ""
    }
}

$output | Out-File C:\Temp\IntuneLogs\IntuneWinOutput.txt
Write-Host "Log Exported to C:\Temp\IntuneLogs\IntuneWinOutput.txt"
$output | Where-Object { ( $_.Message -Like "*Downloading app (id*" ) -or ( $_.Message -like "*application poller starts.*" ) -or ( $_.Message -like "*application poller stopped.*" ) } | Format-Table -AutoSize