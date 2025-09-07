#### This script was crafted with the help of GPT 4.0
## This script is provided "as-is" with no gurenteee of its operation. Use at your own risk!

<#
.SYNOPSIS
  Clean old items from all users' Downloads folders, with WhatIf and logging.

.DESCRIPTION
  Deletes files and folders in C:\Users\<user>\Downloads that were last accessed
  before a cutoff date (default: 2025-06-30). Includes deep recursion, totals
  bytes freed, supports -WhatIf (dry-run), and logs to C:\it\DownloadsCleanup-<timestamp>.log.

.EXAMPLE
  .\Clean-Downloads.ps1

.EXAMPLE
  .\Clean-Downloads.ps1 -Cutoff '2025-06-30' -Verbose

.EXAMPLE
  .\Clean-Downloads.ps1 -WhatIf
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [Parameter()]
  [datetime]$Cutoff = (Get-Date '2025-06-30'),

  [Parameter()]
  [string[]]$SkipProfiles = @('Default', 'Default User', 'Public', 'All Users')
)

# --- Setup logging ---
$LogDir = 'C:\it'
if (-not (Test-Path -LiteralPath $LogDir)) {
  New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$TimeStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$LogFile = Join-Path $LogDir "DownloadsCleanup-$TimeStamp.log"

function Write-Log {
  param(
    [Parameter(Mandatory)]
    [string]$Message,
    [ValidateSet('INFO','WARN','ERROR','DRYRUN','SUMMARY')]
    [string]$Level = 'INFO'
  )
  $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
  Add-Content -LiteralPath $LogFile -Value $line
  if ($Level -eq 'ERROR' -or $Level -eq 'WARN') {
    Write-Warning $Message
  } elseif ($Level -eq 'DRYRUN') {
    Write-Verbose $Message
    Write-Host $Message
  } else {
    Write-Host $Message
  }
}

Write-Log "Starting Downloads cleanup. Cutoff: $($Cutoff.ToString('yyyy-MM-dd HH:mm:ss'))  WhatIf: $($PSCmdlet.WhatIfPreference)" 'INFO'

# --- Core ---
$TotalBytesFreed = [int64]0
$TotalBytesWouldFree = [int64]0

# Get user profiles
$UserProfiles = Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -notin $SkipProfiles }

foreach ($Profile in $UserProfiles) {
  $DownloadsPath = Join-Path $Profile.FullName 'Downloads'
  if (-not (Test-Path -LiteralPath $DownloadsPath)) {
    Write-Log "No Downloads folder for profile '$($Profile.Name)'; skipping." 'INFO'
    continue
  }

  Write-Log "Scanning: $DownloadsPath" 'INFO'

  # --- Delete old files first ---
  $OldFiles = Get-ChildItem -LiteralPath $DownloadsPath -File -Recurse -ErrorAction SilentlyContinue |
              Where-Object { $_.LastAccessTime -lt $Cutoff }

  foreach ($File in $OldFiles) {
    $size = [int64]$File.Length
    $target = $File.FullName

    try {
      if ($PSCmdlet.ShouldProcess($target, 'Delete file')) {
        Remove-Item -LiteralPath $target -Force -ErrorAction Stop
        $TotalBytesFreed += $size
        Write-Log "Deleted file: $target  (${size} bytes)" 'INFO'
      } else {
        # Dry-run
        $TotalBytesWouldFree += $size
        Write-Log "DRY-RUN would delete file: $target  (${size} bytes)" 'DRYRUN'
      }
    }
    catch {
      Write-Log "Failed to delete file: $target  Error: $($_.Exception.Message)" 'ERROR'
    }
  }

  # --- Delete old folders next (deepest first) ---
  # Only delete folders whose LastAccessTime is before cutoff
  $OldFolders = Get-ChildItem -LiteralPath $DownloadsPath -Directory -Recurse -ErrorAction SilentlyContinue |
                Sort-Object FullName -Descending |
                Where-Object { $_.LastAccessTime -lt $Cutoff }

  foreach ($Folder in $OldFolders) {
    $target = $Folder.FullName

    # Compute remaining size of files inside (in case some children survived)
    $folderSize = 0
    try {
      $filesInFolder = Get-ChildItem -LiteralPath $target -File -Recurse -ErrorAction SilentlyContinue
      if ($filesInFolder) {
        $folderSize = [int64](@($filesInFolder | Measure-Object -Property Length -Sum).Sum)
      }
    } catch {
      Write-Log "Failed to compute size for folder: $target  Error: $($_.Exception.Message)" 'WARN'
    }

    try {
      if ($PSCmdlet.ShouldProcess($target, 'Delete folder')) {
        Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop
        $TotalBytesFreed += $folderSize
        Write-Log "Deleted folder: $target  (~${folderSize} bytes)" 'INFO'
      } else {
        # Dry-run
        $TotalBytesWouldFree += $folderSize
        Write-Log "DRY-RUN would delete folder: $target  (~${folderSize} bytes)" 'DRYRUN'
      }
    }
    catch {
      Write-Log "Failed to delete folder: $target  Error: $($_.Exception.Message)" 'ERROR'
    }
  }
}

# --- Summary ---
$FreedGB        = [math]::Round(($TotalBytesFreed / 1GB), 2)
$WouldFreeGB    = [math]::Round(($TotalBytesWouldFree / 1GB), 2)

Write-Log "-------------------------------------------" 'SUMMARY'
Write-Log "Total storage freed: $FreedGB GB ($TotalBytesFreed bytes)" 'SUMMARY'
if ($PSCmdlet.WhatIfPreference) {
  Write-Log "Dry-run estimated reclaimable space: $WouldFreeGB GB ($TotalBytesWouldFree bytes)" 'SUMMARY'
}
Write-Log "Log written to: $LogFile" 'SUMMARY'

Write-Host "Total storage freed: $FreedGB GB ($TotalBytesFreed bytes)"
if ($PSCmdlet.WhatIfPreference) {
  Write-Host "Dry-run estimated reclaimable space: $WouldFreeGB GB ($TotalBytesWouldFree bytes)"
}
Write-Host "Log: $LogFile"
