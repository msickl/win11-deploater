function Import-RegistryFiles {
    param (
        [string]$mainFolderPath
    )

    # Kombiniere den Hauptordner mit dem Unterordner "Regfiles"
    $regfilesFolder = Join-Path -Path $mainFolderPath -ChildPath "SetLocalMachine"

    # Überprüfe, ob der Unterordner "Regfiles" existiert
    if (-not (Test-Path $regfilesFolder -PathType Container)) {
        Write-Host "Der Ordner 'SetLocalMachine' wurde im Hauptordner nicht gefunden." -ForegroundColor Red
    } else {
        # Erhalte eine Liste aller REG-Dateien im Unterordner "Regfiles"
        $regFiles = Get-ChildItem -Path $regfilesFolder -Filter *.reg

        # Überprüfe, ob mindestens eine REG-Datei gefunden wurde
        if ($regFiles.Count -eq 0) {
            Write-Host "Keine REG-Dateien im Ordner 'SetLocalMachine' gefunden." -ForegroundColor Red
        } else {
            # Durchlaufe jede gefundene REG-Datei und führe sie als Administrator aus
            foreach ($regFile in $regFiles) {
                $regFilePath = $regFile.FullName
                Write-Host "Importiere $regFilePath als Administrator..."
                
                # Verwende den Befehl 'reg import' mit erhöhten Rechten
                Start-Process "reg" -ArgumentList "import $regFilePath" -Verb RunAs

                Write-Host "Erfolgreich importiert." -ForegroundColor Green
            }
        }
    }

    # Überprüfen, ob die Datei existiert
    if (Test-Path $filePath) {
        # Pfade aus der Textdatei lesen und ungültige Zeilen (z. B. Kommentare) entfernen
        $registryKeyPaths = Get-Content $filePath | Where-Object { $_ -match '^[^#]' }

        # Schleife durch jeden Registry-Schlüssel-Pfad und löschen, falls vorhanden
        foreach ($keyPath in $registryKeyPaths) {
            # Überprüfen, ob der Schlüssel existiert, bevor er gelöscht wird
            if (Test-Path $keyPath) {
                Remove-Item -Path $keyPath -Force
                Write-Host "Der Registry-Schlüssel $keyPath wurde erfolgreich gelöscht."
            } else {
                Write-Host "Der Registry-Schlüssel konnte nicht gefunden werden. Pfad: $keyPath"
            }
        }

        # Neustart des Windows Explorers
        Write-Host "Neustart des Windows Explorers..."
        Stop-Process -Name explorer -Force
        Start-Process explorer
        Write-Host "Windows Explorer wurde erfolgreich neu gestartet." -ForegroundColor Green
    }
    else {
        Write-Host "Die Datei $filePath wurde nicht gefunden."
    }
}

# Definiere den Pfad zum Hauptordner, der das Skript enthält
$mainFolder = Split-Path -Parent $MyInvocation.MyCommand.Path

# Pfad zur Textdatei mit den zu löschenden Registry-Schlüsseln
$filePath = Join-Path -Path $PSScriptRoot -ChildPath "ListDelRegfile.txt"

# Funktionsaufrufe
Import-RegistryFiles -mainFolderPath $mainFolder
