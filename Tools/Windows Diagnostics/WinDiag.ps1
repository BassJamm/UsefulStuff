[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $AllTests
)

<# ##############  ----- # Globally used variables # ----- ##############  #>
$date = (Get-Date).ToString("dd-MM-yyyy_hh-mm-ss")
$exportFolderLocation = "C:\Temp\Computer-Report-$($date)\"
$excelReportFileName = "System_Diagnostic_Report-$($date).xlsx"

# Create the folder location
New-Item -Path C:\Temp\ -Name "Computer-Report-$($date)" -ItemType Directory

<# ############## ----- # Function to create the console messages. # ----- ##############  #>
Function WriteToConsole ($Action, $Description, $logit) {

    Write-Host "$(Get-Date -Format "dd-MM-yyyy hh:mm:ss") " -ForegroundColor cyan -NoNewline            # Write the date\time first.
    if ($Action -match 'skipped') {Write-Host "$($Action): $($Description)" -ForegroundColor yellow}    # Append write-host action depending on the action.
    if ($Action -match 'Starting') {Write-Host "$($Action): $($Description)" -ForegroundColor green}
    if ($Action -match 'In-Progress') {Write-Host "$($Action): $($Description)" -ForegroundColor green}
    if ($Action -match 'Completed') {Write-Host "$($Action): $($Description)" -ForegroundColor green}
    if ($Action -match 'Error|Failed') {Write-Host "$($Action): $($Description)" -ForegroundColor red}

    try {
        if ($logit -eq 'Yes'){
            # Append entry to log file.
            Add-Content $exportFolderLocation\LogFile_$date.log -Value "$($date): $($Action) - $($Description)" -ErrorAction Continue
        }       
    }
    catch {
        Write-Host "Failed to write to log file."
        $_
    }
}

Function Convert-FromUnixDate ($UnixDate) {
    [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($UnixDate))
 }

function CollectSystemInfo {
    WriteToConsole -Action 'Starting' -Description "Collecting System Information." -logit Yes

    try {
        $computerInfo = Get-Computerinfo -Property *
        $windowsUpdateLastResults = Get-WULastResults

        $WinSysInfoHashTable = [PSCustomObject]@{
            MachineName = $computerInfo.CsDNSHostName
            InstallDate = $computerInfo.WindowsInstallDateFromRegistry
            OS_LastBootTime = $computerInfo.OsLastBootUpTime
            OS_Version = $computerInfo.OsName
            OS_VersionNumber = $computerInfo.OsVersion
            OS_BootDevice = ($computerInfo.OsBootDevice).split("\")[-1]
            OS_HotFixes =$computerInfo.OsHotFixes.HotFixID -join ","
            BIOS_Version =$computerInfo.BiosSMBIOSBIOSVersion
            Manufacturer =$computerInfo.CsManufacturer
            Model =$computerInfo.CsSystemFamily
            Model_Number =($computerInfo.CsModel -split " ")[-1]
            Processor_Name =$computerInfo.CsProcessors.Name
            Processor_NumberOfCores = $computerInfo.CsProcessors.NumberOfCores
            Processor_NumberOfLogicalCores =$computerInfo.CsProcessors.NumberOfLogicalProcessors
            Memory_TotalInstalled = $computerInfo.CsPhysicallyInstalledMemory /1024
            WindowsUpdateLastResult = $windowsUpdateLastResults.LastInstallationSuccessDate
            WindowsUpdateLastSearch = $windowsUpdateLastResults.LastSearchSuccessDate
        }
    }
    catch {
        WriteToConsole -Action "Error" -Description "Something went wrong capturing the computer information." -logit "Yes"
        $_
    }

    ############## Create the DSREGCMD object.
    try {
        WriteToConsole -Action "Starting" -Description "Capturing the information from the DSREGCMD command." -logit "YES"
        $Dsregcmd = New-Object PSObject; Dsregcmd /status | Where-Object {$_ -match ' : '} | ForEach-Object {$Item = $_.Trim() -split '\s:\s'
        $Dsregcmd | Add-Member -MemberType NoteProperty -Name $($Item[0] -replace '[:\s]','') -Value $Item[1] -EA SilentlyContinue}     
    }
    catch {
       WriteToConsole -Action "Failed" -Description "Unable to capture the information from the DSREGCMD command." -logit "YES"
    }
    WriteToConsole -Action "Completed" -Description "Capturing the information from the DSREGCMD command." -logit "YES"

    ##############  Create the new hashtable objects from the above.
    WriteToConsole -Action "Starting" -Description "Organising the information gathered." -logit "YES"
    try {
        $aadJoinInfoHashtable = [PSCustomObject]@{
            DomainJoined = $Dsregcmd.DomainJoined
            EnterPriseJoined = $Dsregcmd.EnterpriseJoined
            AzureAdJoined = $Dsregcmd.AzureAdJoined
            TenantName = $Dsregcmd.TenantName
            TenantID = $Dsregcmd.TenantId
            DeviceName = $Dsregcmd.DeviceName
            DeviceID = $Dsregcmd.DeviceId
            DeviceAuthStatus = $Dsregcmd.DeviceAuthStatus
        }

        $aadPRTInfoHashtable = [PSCustomObject]@{
            PRT_Authority = $Dsregcmd.TenantName + " (URI:" + $Dsregcmd.AzureAdPrtAuthority + ")"
            PRT_Aquired = $Dsregcmd.AzureAdPrt
            PRTPreviousUpdateAttemp = $Dsregcmd.PreviousPrtAttempt
            PRT_AttemptStatus = $Dsregcmd.AttemptStatus
            PRT_UpdateTime = $Dsregcmd.AzureAdPrtUpdateTime
            PRT_ExpiryTime = $Dsregcmd.AzureAdPrtExpiryTime
            PRT_DiagnosticsOn = $Dsregcmd.AcquirePrtDiagnostics
            User_UserID = $Dsregcmd.UserIdentity
            User_OnPremAuthority = $Dsregcmd.OnPremTgt
            User_InCloudAuthority = $Dsregcmd.cloudtgt
            User_CorrolationID = $Dsregcmd.CorrelationID
            User_HTTPStatus = $Dsregcmd.HTTPStatus
            User_HTTPError = $Dsregcmd.HTTPError
        }

        $aadDiagnsticDataHashtable = [PSCustomObject]@{
            User_ExecutingAccName = $Dsregcmd.ExecutingAccountName
            User_KeySigningtest = $Dsregcmd.KeySignTest
            User_ProxyAutoDetect = $Dsregcmd.AutoDetectSettings
            User_ProxyConfigURL = $Dsregcmd.'Auto-ConfigurationURL'
            User_ProxyServerList = $Dsregcmd.ProxyServerList
            User_ProxyByPassList = $Dsregcmd.ProxyBypassList
            Device_DisplayNameUpdated = $Dsregcmd.DisplayNameUpdated
            Device_OSUpdated = $Dsregcmd.OsVersionUpdated
            Device_ProxyAccessType = $Dsregcmd.AccessType
        }
      
    }
    catch {
        WriteToConsole -Action "Error" -Description "Something went wrong capturing the AzureAD information." -logit "Yes"
    }

    ##############  Get the network Config.

    try {
        WriteToConsole -Action "Starting" -Description "Collecting Ip Configuration info." -logit "YES"
        # Array below captures the properties to use in the $netIPConfig variable command.
        $netIPConfigProperties = @(
            'name',
            'interfacedescription',
            'status',
            'macaddress',
            'linkspeed',
            @{l='AssociatedIPv4Address';e={ (get-netipaddress -InterfaceAlias $_.name -AddressFamily IPv4).IPAddress -join ',' }},
            @{l='AssociatedIPv6Address';e={ (get-netipaddress -InterfaceAlias $_.name -AddressFamily IPv6).IPAddress -join ',' }} 
        )
        $netIPConfig = Get-NetIPConfiguration -All | Select-Object -ExpandProperty NetAdapter | Select-Object $netIPConfigProperties
         
    }
    catch {
        WriteToConsole -Action "Error" -Description "Error when collecting Ip Configuration info." -logit "YES"
        $_
    }
    WriteToConsole -Action "Completed" -Description "Collecting Ip Configuration info." -logit "YES"
    Start-Sleep 2
    WriteToConsole -Action "Completd" -Description "Organising the information gathered." -logit "YES"
    
    ##############  Appending the data collected to the Export excel sheet.
    try {
        Add-Content -PassThru $exportFolderLocation\Windows_System_Info.txt -Value "----- Windows Device Information ----- "
        $WinSysInfoHashTable | Out-File $exportFolderLocation\Windows_System_Info.txt -Append
        Add-Content -PassThru $exportFolderLocation\Windows_System_Info.txt -Value "----- Azure Active Directory Information ----- "
        $aadJoinInfoHashtable | Out-File $exportFolderLocation\Windows_System_Info.txt -Append
        Add-Content -PassThru $exportFolderLocation\Windows_System_Info.txt -Value "----- AzureAD Primary Refresh Token Information ----- "
        $aadPRTInfoHashtable | Out-File $exportFolderLocation\Windows_System_Info.txt -Append
        Add-Content -PassThru $exportFolderLocation\Windows_System_Info.txt -Value "----- AzureAD Diagnostic Information ----- "
        $aadDiagnsticDataHashtable | Out-File $exportFolderLocation\Windows_System_Info.txt -Append
        Add-Content -PassThru $exportFolderLocation\Windows_System_Info.txt -Value "----- IP Configuration Data ----- "
        $netIPConfig | Out-File $exportFolderLocation\Windows_System_Info.txt -Append

    }
    catch {
        WriteToConsole -Action "Error" -Description "Something went wrong created & appending the data to the report file." -logit "YES"
        $_
    }
}

function AppsAndEventsInfo {

    # ##############  Get a list of events.
    WriteToConsole -Action "Starting" -Description "Collecting System, Application and Security event logs." -logit "YES"
    try {
        # Get the event logs.
        $systemEventLogsSystem = Get-WinEvent -LogName System -MaxEvents 250 | Select-Object TimeCreated,ProviderName,Id,Message
        $applicationEventLogsSystem = Get-WinEvent -LogName Application -MaxEvents 250 | Select-Object TimeCreated,ProviderName,Id,Message
        $securityEventLogsSystem = Get-WinEvent -LogName Security -MaxEvents 250 | Select-Object TimeCreated,ProviderName,Id,Message
    } catch {
        WriteToConsole -Action "Error" -Description "Unable to collect event logs, see error below." -logit "YES"
        $_
    }
    WriteToConsole -Action "Completed" -Description "Successfully collected event logs from all sources." -logit "YES"
    try {
        # Export the logs.
        $systemEventLogsSystem | Export-Excel "$exportFolderLocation\$excelReportFileName" -Append -WorksheetName 'SystemEvents' -TableStyle Medium16 -AutoSize
        $applicationEventLogsSystem | Export-Excel "$exportFolderLocation\$excelReportFileName" -Append -WorksheetName 'AppEvents' -TableStyle Medium16 -AutoSize
        $securityEventLogsSystem | Export-Excel "$exportFolderLocation\$excelReportFileName" -Append -WorksheetName 'SecurityEvents' -TableStyle Medium16 -AutoSize
    }
    catch {
        WriteToConsole -Action "Error" -Description "Unable to export the event logs to the report file, see error below." -logit "YES"
        $_
    }

    # ##############  Get a list of applications.

    WriteToConsole -Action "Starting" -Description "Collecting information on installed applications." -logit "YES"

    $allInstalledApps = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
    $listOfAppInformation = foreach ($app in $allInstalledApps) {

        [PSCustomObject]@{
            App_Name = $app.GetValue('DisplayName')
            App_Publisher = $app.GetValue('Publisher')
            App_Version = $app.GetValue('DisplayVersion')
            App_InstallDate = $app.GetValue('InstallDate')
            IntallLocation = $app.GetValue('InstallLocation')
            UninstallString = $app.GetValue('UninstallString')
            SizeEstimate = $app.GetValue('EstimatedSize')
            AboutAppURL = $app.GetValue('URLInfoAbout')
            AppRegKeyName = $app.Name
        }
    }
    WriteToConsole -Action "Completed" -Description "Collected information on installed applications." -logit "YES"

    try {
        $listOfAppInformation | Export-Excel "$exportFolderLocation\$excelReportFileName" -Append -WorksheetName 'InstalledApps' -TableStyle Medium16 -AutoSize
        WriteToConsole -Action "Completed" -Description "Exported Appliaiton info to export file." -logit "YES"
    }
    catch {
        WriteToConsole -Action "Error" -Description "Unable to export appliaiton info to export file." -logit "YES"
        $_
    }

}

function AVinformation {
    # ##############  Get Defender Information.

    WriteToConsole -Action "Starting" -Description "Getting Defender information" -logit "YES"

    $defenderStatusInfo = Get-MpComputerStatus
    $defenderPreferences = Get-MpPreference
    $defenderThreatHistory = Get-MpThreat
    $malwareThreatHistory = Get-MpThreatDetection

    WriteToConsole -Action "Completed" -Description "Getting Defender information" -logit "YES"

    WriteToConsole -Action "Starting" -Description "Exporting Defender information" -logit "YES"

    try {
        Add-Content -PassThru $exportFolderLocation\Defender_Info_Report.txt -Value "----- Defender Computer Status ----- "
        $defenderStatusInfo | Out-File $exportFolderLocation\Defender_Info_Report.txt -Append
        Add-Content -PassThru $exportFolderLocation\Defender_Info_Report.txt -Value "----- Defender Preferences ----- "
        $defenderPreferences | Out-File $exportFolderLocation\Defender_Info_Report.txt -Append
        Add-Content -PassThru $exportFolderLocation\Defender_Info_Report.txt -Value "----- Defender Threat History ----- "
        $defenderThreatHistory | Out-File $exportFolderLocation\Defender_Info_Report.txt -Append
        Add-Content -PassThru $exportFolderLocation\Defender_Info_Report.txt -Value "----- Defender Malware History ----- "
        $malwareThreatHistory | Out-File $exportFolderLocation\Defender_Info_Report.txt -Append

        WriteToConsole -Action "Completed" -Description "Exporting Defender information" -logit "YES"
    }
    catch {
        WriteToConsole -Action "Error" -Description "Unable to export Defender information" -logit "YES"
        $_
    }


}

function WinUpdate {
    # ##############  Get Defender Information.
    WriteToConsole -Action "Starting" -Description "Getting Windows Update information" -logit "YES"

    $lastWindowsUpdateResult = Get-WULastResults
    $windowsUpdateHistory = Get-WUHistory -Last 200
    $availableWindowsUpdates = Get-WUList
    
    try {
        $lastWindowsUpdateResult | Export-Excel "$exportFolderLocation\$excelReportFileName" -Append -WorksheetName 'WU-LastResults' -TableStyle Medium16 -AutoSize
        $windowsUpdateHistory | Export-Excel "$exportFolderLocation\$excelReportFileName" -Append -WorksheetName 'WU-UpdateHistory' -TableStyle Medium16 -AutoSize
        $availableWindowsUpdates | Export-Excel "$exportFolderLocation\$excelReportFileName" -Append -WorksheetName 'WU-AvailableUpdates' -TableStyle Medium16 -AutoSize     
    }
    catch {
        WriteToConsole -Action "Error" -Description "Unable to export the data to teh log file." -logit "YES"
        $_

    }
    WriteToConsole -Action "Completed" -Description "Getting Windows Update information" -logit "YES"

    
}

function NetworkTests {

    # ##############  Get IP addressing Information.

    WriteToConsole -Action "Starting" -Description "Starting network tests." -logit "YES"

    $pingTestProperties = @(
        @{n='TimeStamp';e={Get-Date}}
        @{l='SourceAddress';e={$_.__Server}}
        @{l='DestinationAddress';e={$_.Address}}
        'ResponseTime'
    )
    $connectionTest = Test-Connection 'www.google.com' -count 3 | Select-Object $pingTestProperties

    try {
        Add-Content -PassThru $exportFolderLocation\Network_Tests.txt -Value "----- Ping to Google.com Test----- "
        $connectionTest | Out-File $exportFolderLocation\Network_Tests.txt
        
    }
    catch {
        <#Do this if a terminating exception happens#>
    }
    WriteToConsole -Action "Completed" -Description "Network Tests Exported to file." -logit "YES"

}

<# Check for the relevant modules to be installed on the device.#>
if (Get-InstalledModule -Name ImportExcel) {
    Write-Host "All modules needed for script are installed." -ForegroundColor Green
} else {
    Write-Host "The module ImportExcel is required for this script and is not installed, please install the module." -ForegroundColor Red
    Start-sleep 2
    Install-Module -Name ImportExcel -Repository PSGallery -Verbose
}

if (Get-InstalledModule -Name PSWindowsUpdate) {
    Write-Host "PSWindowsUpdate module is already installed." -ForegroundColor Green
} else {
    Write-Host "The module PSWindowsUpdate is required for this script and is not installed, please install the module." -ForegroundColor Red
    Start-sleep 2
    Install-Module -Name PSWindowsUpdate -Repository PSGallery -Verbose -Scope CurrentUser
}

<# Run Functions #>
if ($AllTests) {
    CollectSystemInfo
    AppsAndEventsInfo
    AVinformation
    WinUpdate
    NetworkTests
}
