#C:\Repos\siunet-gearsnet\tools\deployCheckCDNIntegrity.ps1
#Powershell script per verificare l'integrità dei file caricati sui CDN specificati durante il deploy.
#
# Esecuzione locale (cmd):
# powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Repos\siunet-gearsnet\tools\deployCheckCDNIntegrity.ps1"
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
    ,"http://213.215.162.189:8886"
    ,"http://maps.google.com"
    ,"http://www.siunet.net"
    ,"https://110.siunet.it:8887"
    ,"https://110.siunet.it:8888"
    ,"https://ajax.aspnetcdn.com"
    ,"https://ams.servizi.mquadro.net"
    ,"https://cdn.jsdelivr.net"
    ,"https://cdnjs.cloudflare.com"
    ,"https://code.jquery.com"
    ,"https://maps.google.com"
    ,"https://npmcdn.com"
    ,"https://unpkg.com"
    ,"https://www.openlayers.org"
    ,"https://www.runtrackers.net"
    #Inserire qui altri CDN se necessario
  ),
  [string[]] $FilePatterns = @(
      "*.aspx"
      #Aggiungere qui altri pattern di file se necessario, ricordarsi la virgola iniziale
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
    [string[]] $CdnDomains,

    [Parameter(Mandatory)]
    [string[]] $FilePatterns,

    #0 - 00 -> No output (default)
    #1 - 01 -> Successes
    #2 - 10 -> Failures
    #3 - 11 -> All
    [Parameter()]
    [int] $LogLevel = 0
  )

  #If $LogLevel as binary has bit 1 set, print Successes must be printed
  $printSuccesses = ($LogLevel -band 1) -eq 1
  #If $LogLevel as binary has bit 2 set, print Failures must be printed
  $printFailures = ($LogLevel -band 2) -eq 2

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

          if ($lines[$i] -match 'integrity\s*=\s*["'']') {
            if ($printSuccesses) {
              #Write-Host " - Trovato riferimento CDN: $cdn (Rigo: $lineNumber, Carattere: $charIndex)" -ForegroundColor Green
              #Write-Host "   $($lines[$i])" -ForegroundColor DarkGray
              $successes.Add([PSCustomObject]@{
                Cdn        = $cdn
                File       = $File.FullName
                Line       = $lineNumber
                Column     = $charIndex
                LineText   = $lines[$i].TrimEnd("`r")
                Integrity  = $true
              }) | Out-Null
            }
          } else {
            if ($printFailures) {
              #Write-Host " - Trovato riferimento CDN: $cdn (Rigo: $lineNumber, Carattere: $charIndex)" -ForegroundColor Yellow
              #Write-Host "   $($lines[$i])" -ForegroundColor DarkGray
              #Write-Host "   Attenzione: Attributo 'integrity' NON trovato in questo rigo." -ForegroundColor Red
              $failures.Add([PSCustomObject]@{
                Cdn        = $cdn
                File       = $File.FullName
                Line       = $lineNumber
                Column     = $charIndex
                LineText   = $lines[$i].TrimEnd("`r")
                Integrity  = $false
              }) | Out-Null
            }
          }
        }
      }
    }
  }

  $failures = New-Object System.Collections.Generic.List[object]
  return $failures
}

$failures = New-Object System.Collections.Generic.List[object]
foreach ($file in $files) {
  $fileFailures = Test-CdnIntegrityFile -File $file -CdnDomains $CdnDomains -FilePatterns $FilePatterns -LogLevel 3
  foreach ($failure in $fileFailures) {
    $failures.Add($failure)
  }
}
