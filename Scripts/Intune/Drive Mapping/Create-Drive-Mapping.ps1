##################################################################################
#                   Remove and create drive mapping using Registry Key           #
##################################################################################

########## Create log file. ##########
$logFileLocation = "C:\ProgramData\Remediations\DriveMapping\J-Drive"
$logFileName = "Create-J-Drive-Regkeys.log"
# Remove log file if found.
if (Test-Path -path $logFileLocation\$logfileName) { Remove-Item -Path $logFileLocation\$logfileName }
New-Item -Path $logFileLocation -Name $logFileName -ItemType File -Force
function WriteToLogFile($message) { Add-Content "$logFileLocation\$logFileName" -Value "$(Get-Date) - $($message)"} 
WriteToLogFile "Log Created\Updated."
WriteToLogFile "Script begins now."

######################### Function to set Registry Keys ###################################
function setRegKeys {

    # Add the relevant information to Key.
    $ConnectionType = "00000001"
    $DeferFlags = "00000004"
    $ProviderFlags = "00000000"
    $ProviderName = "Microsoft Windows Network"
    $ProviderType = "00000001"
    $UseOptions = ([byte[]](0x44, 0x65, 0x66, 0x43, 0x7c, 0x00, 0x00, 0x00, 0x04, 0x00, 0x74, 0x00, 0x00, 0x00, 0x02, 0x00, 0x03, 0x00, 0x01, 0x00, 01, 0x00, 0x00, 0x00, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x6f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 00, 0x00, 0x80, 0x00))
    $UserName = "00000000"
    $lastWriteTime = Get-Date -UFormat "%A %m/%d/%Y %R %Z"

    try {
        New-ItemProperty -Path $registryPath\$keyName -Name "ConnectionType" -Value $ConnectionType -PropertyType DWORD -Force | Out-Null
        New-ItemProperty -Path $registryPath\$keyName -Name "DeferFlags" -Value $DeferFlags -PropertyType DWORD -Force | Out-Null
        New-ItemProperty -Path $registryPath\$keyName -Name "ProviderFlags" -Value $ProviderFlags -PropertyType DWORD -Force | Out-Null
        New-ItemProperty -Path $registryPath\$keyName -Name "ProviderName" -Value $ProviderName -PropertyType STRING -Force | Out-Null
        New-ItemProperty -Path $registryPath\$keyName -Name "ProviderType" -Value $ProviderType -PropertyType DWORD -Force | Out-Null
        New-ItemProperty -Path $registryPath\$keyName -Name "RemotePath" -Value $RemotePath -PropertyType ExpandString -Force | Out-Null
        New-ItemProperty -Path $registryPath\$keyName -Name "UseOptions" -Value $UseOptions -PropertyType Binary -Force
        New-ItemProperty -Path $registryPath\$keyName -Name "UserName" -Value $UserName -PropertyType DWORD -Force | Out-Null
        New-ItemProperty -Path $registryPath\$keyName -Name "lastWriteTime" -Value $lastWriteTime -PropertyType ExpandString -Force | Out-Null
    }
    catch {
        WriteToLogFile "Error, script failed."
        WriteToLogFile $_
    }
}

######################### Set the Drive Mappings. #########################

# CSV Data to be converted.
$csv = @"
Name,Path
X, \\hostname.domain.com\sharename
"@
# Convert from CSV to objects.
$drives = $csv | ConvertFrom-Csv
WriteToLogFile "Ingesting CSV Data."
# Loop through each entry in the CSV.
WriteToLogFile "Creating new registry keys at, $($registryPath)."

try {

    foreach ($Drive in $Drives) {

        # Set variables.
        $keyName = $drive.Name
        $RemotePath = $drive.Path
        $registryPath = "Registry::HKEY_CURRENT_USER\Network"
        
        # Check for current drive mapping and remove it if it exists.
        WriteToLogFile "Checking if drive mapping already exists."
        if ((Get-SmbMapping -LocalPath ($keyName + ':') -ErrorAction SilentlyContinue).Count -gt 0) {
            Remove-SmbMapping -LocalPath ($keyName + ':') -Force -ErrorAction SilentlyContinue
        }
        WriteToLogFile "Drive $(($keyName + ':')) has been found and removed."

        # Create the new Registry Keys
        New-Item -Path $registryPath -Name $keyName -Force
        WriteToLogFile "New mapping being created. Local Name: $($keyName), Remote Path: $($RemotePath)."
        setRegKeys # Runs the function to create the keys.
    }
    WriteToLogFile "All Drives mapped successfully."
    Exit 0 # Returns success code back to Intune for reporting.
}
catch {
    <#Do this if a terminating exception happens#>
    WriteToLogFile "Error mapping the drives."
    WriteToLogFile $_
    Exit 1 # Returns failure code back to Intune for reporting.
}
