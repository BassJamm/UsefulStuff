<# 
  Wrap this script up with the Intune Wrapper tool with the icon folder in the same folder as this script.
#>

#########################################
#           Create log file.            #
#########################################
$logFileLocation = "C:\ProgramData\Remediations\StartMenuShortcuts"
$logFileName = "Create-StartMenu-Shortcuts.log"
# Remove log file if found.
if (Test-Path -path $logFileLocation\$logfileName) { Remove-Item -Path $logFileLocation\$logfileName }
New-Item -Path $logFileLocation -Name $logFileName -ItemType File -Force
function WriteToLogFile($message) { Add-Content "$logFileLocation\$logFileName" -Value "$(Get-Date) - $($message)" }
WriteToLogFile "Log Created\Updated."
WriteToLogFile "Script begins now."

#########################################
#       Shortcuts in csv format.        #
#########################################
WriteToLogFile "Ingesting the CSV data for the shortcuts."
$csv = @"
shortcutTarget,fileName, iconname
URL or App path, ShortcutName.lnk, iconfilename.ico
"@
# Convert from CSV to objects.
$shortcuts = $csv | ConvertFrom-Csv

#########################################
#  Icon and target location variables.  #
#########################################
$targetFolderLocation = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\FolderName"
$iconFolderlocation = "C:\ProgramData\Remediations\StartMenuShortcuts\icons"

# Create the directories.
try {
    Copy-Item -Path .\Icons -Recurse -Destination $iconFolderlocation -Force
    WriteToLogFile "Created icon folder at $($iconFolderlocation) and copied all icons."
    New-Item -Path $targetFolderLocation -ItemType Directory -Force
    WriteToLogFile "Created start menu folder $($targetFolderLocation)"
}
catch {
    WriteToLogFile "Someething happened when creating the icon or start menu folder."
    Exit 1
}

#########################################
#     Loop to create the new icons.     #
#########################################
WriteToLogFile "Beginning the creation of the links."
try {

    foreach ($item in $shortcuts) {
    
        # Create the shortcut.
        $WScriptShell = New-Object -ComObject WScript.Shell                                 # Creates the new object.
        $Shortcut = $WScriptShell.CreateShortcut("$targetFolderLocation\$($item.fileName)") # Location of the new shortcut.
        $Shortcut.TargetPath = $item.shortcutTarget                                         # Shortcut target or URL.
        $Shortcut.IconLocation = "$iconFolderlocation\$($item.iconname), 0"                 # Icon file location.
        $Shortcut.Save()
        WriteToLogFile "Creating the $($item.fileName) shortcut."
    }
}
catch {
    WriteToLogFile "There's been an error creating the shortcuts."
    Exit 1
}
WriteToLogFile "Shortcuts all created fine."
Exit 0
