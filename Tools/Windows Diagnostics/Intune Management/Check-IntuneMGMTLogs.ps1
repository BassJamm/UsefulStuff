function installIntent ($intent) {
    switch ($intent) {
        '3' { "Required" }
        '0' { "None" }
        Default {}
    }
}

############ Switch to denote if app is applicable to machine ############
function installApplicable ($applicable) {
    switch ($applicable) {
        '1' { "Yes" }
        '0' { "No" }
        Default {}
    }
} 

############ Search for Application Installs ############
foreach ($row in $filteredLogs) {

    $policyData = ($row | Select-String -Pattern "\s=\s(.+)]]LOG]").Matches.Value -replace "=\s", "" -replace "\]LOG\]", "" | ConvertFrom-Json

    $outputAppInfo = foreach ($item in $policyData) {

        [PSCustomObject]@{
            Id              = $item.Id
            Name            = $item.Name
            Install_Intent  = installintent -intent $item.Intent
            TargetType      = $item.TargetType
            IsItApplicable  = installApplicable -applicable $item.Targeted
            SetupFile_Info  = $item.SetUpFilePath
            Install_CMD     = $item.InstallCommandLine
            Uninstall_CMD   = $item.UninstallCommandLine
            Notifications   = $item.ToastState
            RebootBehaviour = $item.RebootEx -join ","
            Detection_Rule  = ($item.DetectionRule | ConvertFrom-Json).DetectionText | ConvertFrom-Json
        }
    } 
}

$outputAppInfo | Sort-Object Name | Format-Table * -AutoSize