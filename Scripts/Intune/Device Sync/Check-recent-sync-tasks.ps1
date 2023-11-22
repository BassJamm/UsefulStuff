# Function used to re-run the value through the switch.
function InTuneAction ($Source) {
    switch ($source) {
        'UserAgentOrigin: (0x1)' { "Account Settings Initiated" }
        'UserAgentOrigin: (0x5)' { "Account Settings Initiated" }
        'UserAgentOrigin: (0x2)' { "Device Initiated" }
        'UserAgentOrigin: (0x4)' { "Device Initated, at user logon" }
        'UserAgentOrigin: (0x8)' { "Company Portal Initiated" }
        'UserAgentOrigin: (0x7)' { "Intune Initiated" }
        'UserAgentOrigin: (0x8)' { "Company Portal Initiated" }
        Default {}
    }
} 
# Splatting for the properties otherwise it'd be mega long. 
$properties = @(
    'TimeCreated',
    @{l = 'Source'; e = { InTuneAction -Source ( $_.message | Select-String 'UserAgentOrigin:\s\(0x.\)' ).Matches.Value } }
)
# Command grabs the events and the sources.
Get-WinEvent -FilterHashTable @{ LogName = 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin' ; id = 208; ; StartTime = (get-date).AddDays(-1) } | Select-Object $properties
