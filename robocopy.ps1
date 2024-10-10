### Created by Jonathan Amir
# Required info: $source and $destination
# Can be changed: $logfile
# 
# Free for use


# Define variables
$source = "<remote computer>"   
$destination = "<local destination folder>"           
$logFile = "C:\RobocopyLog.txt"          
# Ensure the local destination folder exists
if (-not (Test-Path -Path $destination)) {
    New-Item -ItemType Directory -Path $destination
}


$robocopyCommand = "Robocopy $source $destination /MIR /Z /R:3 /W:5 /LOG:$logFile /V /NP"

# Execute the Robocopy command
Invoke-Expression $robocopyCommand

# Check if the copy was successful
if ($LASTEXITCODE -le 3) {
    Write-Output "Folder copied successfully!"
} else {
    Write-Error "Error during copy. Check the log file for details: $logFile"
}
