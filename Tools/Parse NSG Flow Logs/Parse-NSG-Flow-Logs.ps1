param(
    [string]$NsgFlowLogFileName = "C:\flowlog.json"
)

# Import the logs from the file convert it from json into a powershell object
$logs = Get-Content $NsgFlowLogFileName  -ErrorAction SilentlyContinue | ConvertFrom-Json | Select-Object -ExpandProperty records

# Loop through each entry in the json file
foreach ($Log in $Logs) {
    #Get a list of flows
    $Flows = $log.properties.flows

    # Loop through each flow of each json entry and output the details
    foreach ($Flow in $Flows) {
        # Split the flow information to a variable for easier and quicker referencing
        $FlowInfo = $Flow.flows.flowtuples[0] -split (',')

        # Output details as a powershell object
        [pscustomobject]@{
            DateTime      = (Get-Date 01.01.1970) + ([System.TimeSpan]::fromseconds($FlowInfo[0]))
            NSGName       = $Log.resourceId.split('/')[-1]
            RuleName      = $Flow.rule
            Decision      = switch ($FlowInfo[7]) { 'a' { "Allowed" } ; "d" { "Denied" } }
            FlowState     = switch ($FlowInfo[8]) { 'B' { "Begin" } ; "C" { "Continue" } ; "e" { "End" } }
            SourceIP      = $FlowInfo[1]
            SourcePort    = $FlowInfo[3]
            DestIP        = $FlowInfo[2]
            DestPort      = $FlowInfo[4]
            Protocol      = switch ($FlowInfo[5]) { 't' { "TCP" } ; "u" { "UDP" } }
            Direction     = switch ($FlowInfo[6]) { 'i' { "InBound" } ; "o" { "OutBound" } }
            SourcePackets = $FlowInfo[9]
            SourceBytes   = $FlowInfo[10]
            DestPackets   = $FlowInfo[11]
            DestBytes     = $FlowInfo[12]

            # Below line ends the flow loop, then filters out the empty entries (as each flow entry has all rules listed, even if they are not 'hit' by some traffic.
        } | Where-Object SourceIP -ne $null

    }
}
