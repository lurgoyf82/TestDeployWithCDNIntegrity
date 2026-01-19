# Scansiona la repo e trova i riferimenti in attributi src="...".
#
# Obiettivo primario (oggi):
# - estrarre i domini (origin) delle risorse remote (http/https) usate in src
#
# Obiettivo secondario (per futuro usage):
# - mantenere in variabili separate anche i valori locali/relativi (non http/https)
#   così da poterli analizzare o validare in un secondo momento.
#
# Esempio:
# powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Repos\TestDeployWithCDNIntegrity\tools\getCDNDomains.ps1"

param(
  [string[]] $FilePatterns = @(
    "*.aspx"
    ,"*.ascx"
    ,"*.master"
    ,"*.html"
    ,"*.htm"
    ,"*.cshtml"
    ,"*.vbhtml"
    ,"*.php"
    ,"*.jsp"
  )
)

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

# 1) Raccolta file repository (filtrata per pattern e cartelle da escludere)
$allFiles = New-Object System.Collections.Generic.List[System.IO.FileInfo]
foreach ($pattern in $FilePatterns) {
  $matching = Get-ChildItem -Path $root -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue
  foreach ($f in $matching) { $allFiles.Add($f) }
}

$files = $allFiles |
  Where-Object { $_.FullName -notmatch "\\(bin|obj|packages|node_modules)\\" } |
  Sort-Object -Property FullName -Unique

# 2) Estrazione valori da src= (robusta: case-insensitive, spazi, apici singoli/doppi)
# Nota: è una regex "best effort"; non è un parser HTML.
$srcRegex = [regex]::new('(?is)\bsrc\s*=\s*(["''])(?<value>.*?)\1')

# 3) Collezioni separate:
# - $remoteSrcUrls: solo src che sono URL assoluti http/https (potenzialmente candidate a SRI)
# - $localSrcValues: tutti gli altri (relativi/assoluti locali, URL non http/https, ecc.)
$remoteSrcUrls = New-Object 'System.Collections.Generic.HashSet[string]'
$localSrcValues = New-Object 'System.Collections.Generic.HashSet[string]'

# 4) Domini (origin) unici delle risorse remote trovate
$remoteOrigins = New-Object 'System.Collections.Generic.HashSet[string]'

foreach ($file in $files) {
  $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
  if ([string]::IsNullOrWhiteSpace($content)) { continue }

  $matches = $srcRegex.Matches($content)
  if ($matches.Count -eq 0) { continue }

  foreach ($m in $matches) {
    $value = $m.Groups['value'].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($value)) { continue }

    # Classificazione: remoto (http/https) vs locale/relativo/altro
    if ($value -match '^(?i)https?://') {
      [void]$remoteSrcUrls.Add($value)

      try {
        $u = [Uri]::new($value)
        $origin = $u.GetLeftPart([System.UriPartial]::Authority) # https://domain.tld(:port)
        [void]$remoteOrigins.Add($origin)
      } catch {
        # URL non parseabile: lo teniamo comunque in $remoteSrcUrls ma non contribuisce a $remoteOrigins
        continue
      }
    } else {
      # Qui finiscono tipicamente:
      # - path relativi: ../js/app.js, ./x.js
      # - root-relative: /js/app.js
      # - tilde: ~/scripts/x.js (tipico ASP.NET)
      # - protocol-relative: //cdn... (oggi considerato "locale/altro"; se servirà lo riclassifichiamo)
      # - data:, javascript:, ecc.
      [void]$localSrcValues.Add($value)
    }
  }
}

# OUTPUT (per ora): domini unici delle risorse remote
$remoteOrigins | Sort-Object | ForEach-Object { Write-Output $_ }

# NOTE:
# - $remoteSrcUrls contiene gli URL remoti completi trovati (non solo i domini)
# - $localSrcValues contiene i valori non http/https (locali/relativi/altro)
# - al momento non stampiamo $localSrcValues per non “sporcare” l’output,
#   ma la variabile resta disponibile se in futuro vorrai salvarla su file o stamparla.

