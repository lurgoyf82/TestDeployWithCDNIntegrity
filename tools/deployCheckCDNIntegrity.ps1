# ============================================================
# SCOPO DELLO SCRIPT
# ------------------------------------------------------------
# Questo script fa parte di una pipeline CI/CD e verifica che
# tutti i riferimenti a CDN presenti nei file del progetto
# includano l’attributo di sicurezza "integrity".
#
# L’assenza dell’attributo "integrity" su una risorsa CDN è
# considerata un errore bloccante per la pipeline.
# ============================================================

# ============================================================
# RISOLUZIONE DEL CONTESTO DI ESECUZIONE
# ------------------------------------------------------------
# Viene determinata la cartella root del progetto.
# Per convenzione, la root è una cartella sopra quella
# contenente lo script (tipico layout repo/tools).
#
# Tutte le ricerche di file partono esclusivamente da questa
# root, garantendo coerenza tra esecuzione locale e CI.
# ============================================================

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$repoRoot = (Resolve-Path -LiteralPath (Split-Path -Path $scriptDir -Parent)).Path


# ============================================================
# CONFIGURAZIONE
# ------------------------------------------------------------
# La configurazione NON è hardcoded nello script.
# Tutti i parametri operativi (CDN, pattern di file, cartelle
# da escludere) vengono letti da un file JSON esterno,
# posizionato nella stessa cartella di questo script.
#
# Il file JSON è la SINGLE SOURCE OF TRUTH per la pipeline.
# Se il file JSON è mancante o invalido, lo script deve fallire.
# ============================================================

$configPath = Join-Path -Path $scriptDir -ChildPath 'deployCheckCDNIntegrity.json'

if (-not (Test-Path -LiteralPath $configPath)) {
	throw "File di configurazione mancante: '$configPath'."
}

try {
	$config = (Get-Content -LiteralPath $configPath -Raw -Encoding UTF8) | ConvertFrom-Json -ErrorAction Stop
}
catch {
	throw "File di configurazione invalido o non parsabile: '$configPath'. Dettagli: $($_.Exception.Message)"
}

if (-not $config.PSObject.Properties.Match('CdnDomains')) { throw "Configurazione invalida: 'CdnDomains' mancante in '$configPath'." }
if (-not $config.PSObject.Properties.Match('FilePatterns')) { throw "Configurazione invalida: 'FilePatterns' mancante in '$configPath'." }
if (-not $config.PSObject.Properties.Match('ExcludeFolders')) { throw "Configurazione invalida: 'ExcludeFolders' mancante in '$configPath'." }

$CdnDomains = @($config.CdnDomains | ForEach-Object { "$_" })
$FilePatterns = @($config.FilePatterns | ForEach-Object { "$_" })
$ExcludeFolders = @($config.ExcludeFolders | ForEach-Object { "$_" })

if ($CdnDomains.Count -eq 0) { throw "Configurazione invalida: 'CdnDomains' vuoto in '$configPath'." }
if ($FilePatterns.Count -eq 0) { throw "Configurazione invalida: 'FilePatterns' vuoto in '$configPath'." }

# ============================================================
# INIZIALIZZAZIONE DELL’OGGETTO DI RISULTATO
# ------------------------------------------------------------
# Struttura richiesta (contratto):
# - result
#   - successes (map file -> occorrenze)
#     - <FilePath>
#       - [ elenco di occorrenze valide ]
#   - failures  (map file -> occorrenze)
#     - <FilePath>
#       - [ elenco di occorrenze non valide ]
#
# Dove ogni occorrenza contiene informazioni di dettaglio:
# - CDN rilevata
# - riga (1-based)
# - colonna (1-based)
# - testo completo della riga
# - flag che indica la presenza o meno dell’attributo integrity
#
# Un file può:
# - non contenere alcun CDN
# - contenere solo successi
# - contenere solo fallimenti
# - contenere entrambi

# - summary
#   - totalFilesScanned
#       Numero totale di file analizzati dallo script.
#
#   - filesWithSuccesses
#       Numero di file che contengono almeno una occorrenza
#       valida (CDN con attributo integrity).
#
#   - filesWithFailures
#       Numero di file che contengono almeno una occorrenza
#       non valida (CDN senza attributo integrity).
#
#   - totalSuccessOccurrences
#       Numero totale di occorrenze valide rilevate
#       (somma di tutte le occorrenze su tutti i file).
#
#   - totalFailureOccurrences
#       Numero totale di occorrenze non valide rilevate
#       (somma di tutte le occorrenze su tutti i file).
# ============================================================

$resultObject = [pscustomobject]@{
	result  = [pscustomobject]@{
		successes = @{}
		failures  = @{}
	}
	summary = [pscustomobject]@{
		totalFilesScanned        = 0
		filesWithSuccesses       = 0
		filesWithFailures        = 0
		totalSuccessOccurrences  = 0
		totalFailureOccurrences  = 0
	}
}

# ============================================================
# DISCOVERY DEI FILE DA ANALIZZARE
# ============================================================

$allFiles = New-Object System.Collections.Generic.List[System.IO.FileInfo]

foreach ($pattern in $FilePatterns) {
	$matching = Get-ChildItem -LiteralPath $repoRoot -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue
	foreach ($f in $matching) { $allFiles.Add($f) }
}

$filesToScan = $allFiles |
	Where-Object {
		$excludedRegex = '\\(' + (($ExcludeFolders | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')\\'
		$_.FullName -notmatch $excludedRegex
	} |
	Sort-Object -Property FullName -Unique |
	Select-Object -ExpandProperty FullName

$resultObject.summary.totalFilesScanned = @($filesToScan).Count


# ============================================================
# ANALISI DEI FILE
# ------------------------------------------------------------
# Per ogni file individuato:
# - il file viene letto interamente
# - per ogni CDN configurato:
#   - se il CDN non è presente nel file, viene saltato
#   - se presente:
#       - vengono analizzate tutte le righe che lo contengono
#       - per ogni riga:
#           - viene calcolata riga e colonna dell’occorrenza
#           - viene verificata la presenza dell’attributo
#             "integrity" sulla STESSA riga
#
# Ogni occorrenza viene classificata come:
# - SUCCESSO  → CDN con integrity
# - FALLIMENTO → CDN senza integrity
#
# I risultati vengono associati al file corrente.
# ============================================================

$integrityRegex = '(?i)\bintegrity\s*=\s*(["'']).+?\1'

foreach ($filePath in $filesToScan) {
	$content = Get-Content -LiteralPath $filePath -Raw -Encoding UTF8 -ErrorAction Stop
	if ([string]::IsNullOrEmpty($content)) { continue }

	foreach ($cdn in $CdnDomains) {
		if ([string]::IsNullOrWhiteSpace($cdn)) { continue }

		$cdnEscaped = [regex]::Escape($cdn)
		if ($content -notmatch $cdnEscaped) { continue }

		$lines = $content -split "`n"
		for ($i = 0; $i -lt $lines.Length; $i++) {
			$lineText = $lines[$i].TrimEnd("`r")
			if ($lineText -notmatch $cdnEscaped) { continue }

			$startIndex = 0
			while ($true) {
				$idx = $lineText.IndexOf($cdn, $startIndex, [System.StringComparison]::OrdinalIgnoreCase)
				if ($idx -lt 0) { break }

				$hasIntegrity = ($lineText -match $integrityRegex)

				$occ = [pscustomobject]@{
					cdn          = $cdn
					line         = $i + 1
					column       = $idx + 1
					lineText     = $lineText
					hasIntegrity = $hasIntegrity
				}

				if ($hasIntegrity) {
					if (-not $resultObject.result.successes.ContainsKey($filePath)) { $resultObject.result.successes[$filePath] = @() }
					$resultObject.result.successes[$filePath] += $occ
					$resultObject.summary.totalSuccessOccurrences++
				}
				else {
					if (-not $resultObject.result.failures.ContainsKey($filePath)) { $resultObject.result.failures[$filePath] = @() }
					$resultObject.result.failures[$filePath] += $occ
					$resultObject.summary.totalFailureOccurrences++
				}

				$startIndex = $idx + [Math]::Max(1, $cdn.Length)
			}
		}
	}
}

$resultObject.summary.filesWithSuccesses = @($resultObject.result.successes.Keys).Count
$resultObject.summary.filesWithFailures = @($resultObject.result.failures.Keys).Count

# ============================================================
# OUTPUT MACHINE-READABLE (CONTRATTO CI)
# ------------------------------------------------------------
# Lo script emette un output JSON strutturato e deterministico,
# pensato per essere parsato automaticamente dalla pipeline.
#
# Questo JSON rappresenta il CONTRATTO di output dello script.
# La pipeline CI/CD deve basarsi ESCLUSIVAMENTE su questo JSON.
#
# In particolare:
# - se il numero di fallimenti > 0, la pipeline deve fallire
# ============================================================

# ------------------------------------------------------------
# DEBUG: stampa elenco file da analizzare
# ------------------------------------------------------------
#Write-Output "FILES TO SCAN ($(@($filesToScan).Count)):"
#$filesToScan | ForEach-Object { Write-Output " - $_" }


# ============================================================
# OUTPUT (console)
# ============================================================

#Write-Output ($resultObject | ConvertTo-Json -Depth 20)