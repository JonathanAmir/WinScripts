#Created by Jonathan Amir for Impact Netowrks ldt.

function disableProtectView {

$applications = 'word','excel'
$registeryNames = 'DisableAttachmentsInPV','DisableInternetFilesInPV','DisableUnsafeLocationsInPV'

$regPath = "HKCU:\SOFTWARE\Microsoft\Office\16.0\$application\Security\ProtectedView"
foreach ($application in $applications) {
    if  (Test-Path -Path $regPath) {
        Write-output "Information" "No need for further action"
                    exit
        
}
    else {
        foreach ($regName in $registeryNames) {
        New-Item -Path HKCU:\SOFTWARE\Microsoft\Office\16.0\$application\Security\ProtectedView 
        New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Office\16.0\$application\Security\ProtectedView -name $regName -Value 1 -PropertyType DWORD -Force 
        Write-Output "Information: Disabling Protected View...."
        }
}
}
}
disableProtectView
