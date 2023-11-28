function Kopiere-Ordner {
    param(
        [string]$ordnerUrsprung,
        [string]$ordnerZiel
    )

    try {
        Copy-Item -Path $ordnerUrsprung -Destination $ordnerZiel -Recurse -ErrorAction Stop
        Write-Host "Ordner von $ordnerUrsprung nach $ordnerZiel kopiert."
    } catch {
        Write-Host "Fehler beim Kopieren des Ordners: $_"
    }
}

function Verschiebe-Datei {
    param(
        [string]$dateiUrsprung,
        [string]$zielVerzeichnis
    )

    try {
        Copy-Item -Path $dateiUrsprung -Destination $zielVerzeichnis -ErrorAction Stop
        Write-Host "Datei von $dateiUrsprung nach $zielVerzeichnis verschoben."
    } catch {
        Write-Host "Fehler beim Verschieben der Datei: $_"
    }
}

# Verwendung der Funktionen
$ordnerUrsprung = ".\OEM"
$ordnerZiel = "$env:SystemRoot\"
$dateiUrsprung = ".\Theme\zimmer.theme"
$zielVerzeichnis = "$env:SystemRoot\Resources\Themes\"

Kopiere-Ordner -ordnerUrsprung $ordnerUrsprung -ordnerZiel $ordnerZiel
Verschiebe-Datei -dateiUrsprung $dateiUrsprung -zielVerzeichnis $zielVerzeichnis
