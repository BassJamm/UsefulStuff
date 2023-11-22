# Set variables for file sesssions, date and time.
$filesessions = Get-SmbOpenFile
$getDate = Get-Date -Format "dd-MM-yyyy"
$getTime = Get-Date -Format "HH-mm-ss"

# Get basic information about the open files\folders.
$ouput = $filesessions | Select-Object @{ l='Date';e={ $getDate }}, @{ l='Time';e={ $getTime } }, ClientComputerName, clientusername,path
# Write the output to the terminal session.
Write-Output $ouput
# Export the data to file.
$ouput | Export-Csv "C:\temp\SMB Share Reports\Open-File-Report_$((get-date).tostring("dd-MM-yyyy")).csv" -NoTypeInformation -Append 
