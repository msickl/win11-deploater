function ClearStartMenu {
    param (
        [string]$startMenuTemplatePath = "$PSScriptRoot\Start\start2.bin"
    )

    $message = "Startmenü für alle Benutzer ersetzen und Windows Explorer neu starten."
    Write-Output $message

    # Pfad zum Standardbenutzerordner
    $defaultUserStartMenuPath = "C:\Users\Default\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"
    $defaultUserStartMenuFile = Join-Path $defaultUserStartMenuPath 'start2.bin'

    # Pfad zum Admin-Startmenüordner
    $adminStartMenuPath = "C:\Users\Administrator\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"
    $adminStartMenuFile = Join-Path $adminStartMenuPath 'start2.bin'

    # Überprüfen und ggf. den Zielordner für den Standardbenutzer erstellen
    if (-not (Test-Path $defaultUserStartMenuPath)) {
        New-Item -Path $defaultUserStartMenuPath -ItemType Directory -Force
    }

    # Überprüfen und ggf. den Zielordner für den Admin-Benutzer erstellen
    if (-not (Test-Path $adminStartMenuPath)) {
        New-Item -Path $adminStartMenuPath -ItemType Directory -Force
    }

    # Überprüfen, ob die Bin-Datei vorhanden ist
    if (Test-Path $startMenuTemplatePath) {
        # Kopiere die Startmenüvorlage in den Ordner des Standardbenutzers
        Copy-Item -Path $startMenuTemplatePath -Destination $defaultUserStartMenuFile -Force
        Write-Output "Startmenü für Standardbenutzer ersetzt"

        # Kopiere die Startmenüvorlage in den Ordner des Admin-Benutzers
        Copy-Item -Path $startMenuTemplatePath -Destination $adminStartMenuFile -Force
        Write-Output "Startmenü für Administrator ersetzt"
    } else {
        Write-Output "Fehler: Startmenüvorlage nicht gefunden. Stellen Sie sicher, dass die Datei `start2.bin` im angegebenen Pfad vorhanden ist."
        return
    }

    # Neustart des Windows Explorers
    Write-Host "Neustart des Windows Explorers..."
    Stop-Process -Name explorer -Force
    Start-Process explorer
    Write-Host "Windows Explorer wurde erfolgreich neu gestartet." -ForegroundColor Green
}

# Funktion aufrufen mit der angegebenen Nachricht
ClearStartMenu