<# Install PC Client
    Available command parameters:
        /S – Run the installer in unattended mode
        /GATEWAYADDRESS=xxx – chooses HCP gateway address
        /ACCOUNTDOMAIN=yyy – chooses account domain name
        /SYNCPERIOD=nn – automatic synchronization period, in minutes. The default period is 60 minutes
        /IGNORESSLERRORS=true|false – option indicating whether to ignore any errors related to SSL handshake (for example wrong certificate or host name). The default value is false
        /SYNCDRIVER=true|false – enable or disable automatic driver installation. Disabling assumes the user is responsible for the driver install. The default value is true
        /IPPOVERSSL=true|false – enable or disable printing over secure SSL connection. The default value is false
        /AUTHTYPE=0|1|2 – User authentication type: 0=username from session (default), 1=user name from session + domain name, 2=manual login, 3=UserPrincipalName
        /ALLOWCONFIGURATION=true|false – enable or disable the ability for the end-user to configure the PC client after installation. The default value is true
#>

<#  2) Amend below command with values and parameters for your installation:
        GATEWAYADDRESS=
        /ACCOUNTDOMAIN=
        /AUTHTYPE=0
        /SYNCDRIVER=true
        /IPPOVERSSL=true
        /ALLOWCONFIGURATION=false
#>
Start-Process .\hcpclient-3.26.0-release-setup.exe -ArgumentList "/S /GATEWAYADDRESS= /ACCOUNTDOMAIN= /AUTHTYPE=0 /SYNCDRIVER=true /IPPOVERSSL=true /ALLOWCONFIGURATION=false" -Verb RunAs
