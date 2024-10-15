$computerNames = @(
 #Array of server names, seperated by a coma
)

$eventIDs = 4740, 4719, 4099, 4688, 4670, 4672, 1125, 1006

# Date ranges to check. Must be filled

$startDate = [DateTime]::ParseExact("28/07/2023", "dd/MM/yyyy", $null)
$formattedDate = $startDate.ToString("dd/MM/yyyy")
$endDate = [DateTime]::ParseExact("28/07/2023", "dd/MM/yyyy", $null)
$formattedDate = $endDate.ToString("dd/MM/yyyy")


foreach ($computer in $computerNames) {
    # Check if the computer is reachable
    if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
        try {
            # Check if the event log exists on the remote computer
            if (Get-EventLog -ComputerName $computer -List | Where-Object { $_.Log -eq 'System' }) {
                Get-EventLog -ComputerName $computer -LogName System -After $startDate -Before $endDate |
                Where-Object { $_.EventID -in $eventIDs } |
                Select-Object -Property Source, EventID, TimeGenerated, Message |
                Sort-Object Source |
                ForEach-Object {
                    "{0} {1} {2}" -f $_.Source, $_.EventID, $_.TimeGenerated
                }
            } else {
                Write-Host "System log not found on $computer"
            }
        } catch {
            Write-Host "Error retrieving logs from $computer $_"
        }
    } else {
        Write-Host "$computer is unreachable"
    }
}
