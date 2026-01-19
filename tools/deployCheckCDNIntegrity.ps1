#C:\Repos\siunet-gearsnet\tools\deployCheckCDNIntegrity.ps1
#Powershell script per verificare l'integrità dei file caricati sui CDN specificati durante il deploy.
#
# Esecuzione locale (cmd):
# powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Repos\TestDeployWithCDNIntegrity\tools\deployCheckCDNIntegrity.ps1"
#
# Azure DevOps (azure-pipelines.yml):
#
# - task: PowerShell@2
#   displayName: Check CDN integrity
#   inputs:
#     pwsh: true
#     filePath: 'tools/deployCheckCDNIntegrity.ps1'
#     arguments: >
#       -LogLevel 0
#       -FilePatterns "*.aspx" "*.master"
#       -CdnDomains "https://cdnjs.cloudflare.com" "https://cdn.jsdelivr.net"
#
#
# AWS CodeBuild (buildspec.yml):
#
# version: 0.2
# phases:
#   build:
#     commands:
#       - powershell.exe -NoProfile -ExecutionPolicy Bypass `
#           -File ".\tools\deployCheckCDNIntegrity.ps1" `
#           -LogLevel 0 `
#           -FilePatterns "*.aspx" "*.master" `
#           -CdnDomains "https://cdnjs.cloudflare.com" "https://cdn.jsdelivr.net"



param(
  [string[]] $CdnDomains = @(
    "http://maps.google.com",
    "https://cdn.jsdelivr.net",
    "https://cdnjs.cloudflare.com",
    "https://code.jquery.com",
    "https://maps.google.com",
    "https://maps.googleapis.com",
    "https://unpkg.com"
  ),
  [string[]] $FilePatterns = @(
    "*.aspx"
  )
)

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$allFiles = New-Object System.Collections.Generic.List[System.IO.FileInfo]

foreach ($pattern in $FilePatterns) {
  $matching = Get-ChildItem -Path $root -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue
  foreach ($f in $matching) { $allFiles.Add($f) }
}

$files = $allFiles |
  Where-Object { $_.FullName -notmatch "\\(bin|obj|packages|node_modules)\\" } |
  Sort-Object -Property FullName -Unique

# Write-Host "File trovati ($($files.Count)) sotto '$root' con pattern: $($FilePatterns -join ', ')" -ForegroundColor Cyan
# if ($files.Count -eq 0) {
#   Write-Host "Nessun file trovato." -ForegroundColor Yellow
# } else {
#   $files | ForEach-Object { Write-Host " - $($_.FullName)" }
# }

function Test-CdnIntegrityFile {
  param(
    [Parameter(Mandatory)]
    [System.IO.FileInfo] $File,

    [Parameter(Mandatory)]
    [string[]] $CdnDomains
  )

  $successes = New-Object System.Collections.Generic.List[object]
  $failures = New-Object System.Collections.Generic.List[object]

  $content = Get-Content -Path $File.FullName -Raw -ErrorAction Stop

  foreach ($cdn in $CdnDomains) {
    if ($content -match [regex]::Escape($cdn)) {
      $lines = $content -split "`n"
      for ($i = 0; $i -lt $lines.Length; $i++) {
        if ($lines[$i] -match [regex]::Escape($cdn)) {
          $lineNumber = $i + 1
          $charIndex = $lines[$i].IndexOf($cdn) + 1

          $hasIntegrity = ($lines[$i] -match 'integrity\s*=\s*["'']')

          $item = [PSCustomObject]@{
            Cdn       = $cdn
            File      = $File.FullName
            Line      = $lineNumber
            Column    = $charIndex
            LineText  = $lines[$i].TrimEnd("`r")
            Integrity = $hasIntegrity
          }

          if ($hasIntegrity) { $successes.Add($item) | Out-Null }
          else { $failures.Add($item) | Out-Null }
        }
      }
    }
  }

  return [PSCustomObject]@{
    Successes = $successes
    Failures  = $failures
  }
}

$allSuccesses = New-Object System.Collections.Generic.List[object]
$allFailures = New-Object System.Collections.Generic.List[object]

foreach ($file in $files) {
  $result = Test-CdnIntegrityFile -File $file -CdnDomains $CdnDomains
  foreach ($s in $result.Successes) { $allSuccesses.Add($s) | Out-Null }
  foreach ($f in $result.Failures) { $allFailures.Add($f) | Out-Null }
}

# Output “machine-readable” per CI
[PSCustomObject]@{
  Successes = $allSuccesses
  Failures  = $allFailures
  Counts    = [PSCustomObject]@{
    Successes = $allSuccesses.Count
    Failures  = $allFailures.Count
  }
} | ConvertTo-Json -Depth 6
