#Created by Jonathan Amir.
#Free for use
#Use at your own risk!

function disableProtectView {

$applications = 'word','excel'
$registeryNames = 'DisableAttachmentsInPV','DisableInternetFilesInPV','DisableUnsafeLocationsInPV'

foreach ($application in $applications) {
$regPath = "HKCU:\SOFTWARE\Microsoft\Office\16.0\$application\Security\ProtectedView"

    if  (Test-Path -Path $regPath) {
        Write-output "Information" "No need for further action"
                    exit
        
}
    else {
        New-Item -Path $regPath -Force
        foreach ($regName in $registeryNames) {
            New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Office\16.0\$application\Security\ProtectedView -name $regName -Value 1 -PropertyType DWORD -Force 
        Write-Output "Information: Disabling Protected View for $application...."
        }
}
}
}
disableProtectView
