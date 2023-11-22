param (
    [Parameter(Mandatory = $false)]
    [String]$category,
    [Parameter(Mandatory = $false)]
    [String]$taskDescription,
    [Parameter(Mandatory = $false)]
    [Switch]$OpenTimeSheet
)

# Set variables
$storageLocation = "C:\Temp\"
$fileName = "Time_Tracker-$(Get-Date -UFormat %Y).xlsx"

if ($taskDescription) {

    # Set the start time and the date.
    $starttime = Get-date -UFormat %R
    $startdate = (Get-Date).ToString("dd\\MM\\yy")
    
    # read host prompt pauses the script whilst the task is worked on.
    Read-Host -Prompt "Press enter to end time entry."
    
    # Upon pressing enter to resume the script - the hash table of entries is created below.
    $tableData = [PSCustomObject]@{
        Date                 = $startdate
        "Start Time"         = $starttime
        "End Time"           = Get-date -UFormat %R
        "Time Worked (Mins)" = ([Math]::Round((NEW-TIMESPAN -Start $starttime -End (Get-date -UFormat %R)).TotalMinutes, 2))
        Category             = $category
        Description          = $taskDescription
    }
    # Data exported to the excel sheet.
    $tableData | Export-Excel -Path $storageLocation\$fileName -WorksheetName "$(Get-Date -UFormat %b)" -TableName "tblTimeTracking$(Get-Date -UFormat %b)" -TableStyle Medium16 -Append -AutoSize
}


if ($OpenTimeSheet) {
    Invoke-Item -Path "$storageLocation\$fileName" -ErrorAction SilentlyContinue
}
