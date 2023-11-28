function Remove-Apps {

    $appsFile = Join-Path -Path $PSScriptRoot -ChildPath "GetAppxPackage/AppsList.txt"

    Write-Output $message

    # Get list of apps from file at the path provided, and remove them one by one
    Foreach ($app in (Get-Content -Path $appsFile | Where-Object { $_ -notmatch '^#.*' -and $_ -notmatch '^\s*$' } )) 
    { 
        # Remove any spaces before and after the Appname
        $app = $app.Trim()

        # Remove any comments from the Appname
        if (-not ($app.IndexOf('#') -eq -1)) {
            $app = $app.Substring(0, $app.IndexOf('#'))
        }
        # Remove any remaining spaces from the Appname
        if (-not ($app.IndexOf(' ') -eq -1)) {
            $app = $app.Substring(0, $app.IndexOf(' '))
        }
        
        $appString = $app.Trim('*')
        Write-Output "Attempting to remove $appString..."

        # Remove installed app for all existing users
        Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage

        # Remove provisioned app from OS image, so the app won't be installed for any new users
        Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like $app } | ForEach-Object { Remove-ProvisionedAppxPackage -Online -AllUsers -PackageName $_.PackageName }
    }

    Write-Output "Apps wurden deinstalliert"
}

function Uninstall-EdgeBrowser {
    Write-Host "Uninstall EdgeBrowser"
    # Speichere das aktuelle Verzeichnis
    $originalPath = Get-Location

    # Ermittle die Edge-Version mit Get-AppxPackage
    $EdgeVersion = Get-AppxPackage -Name "Microsoft.MicrosoftEdge.*" | Select-Object -ExpandProperty Version

    # Überprüfe, ob die Edge-Version gefunden wurde
    if ($EdgeVersion -ne $null) {
        # Füge den Installationspfad hinzu
        $EdgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\$EdgeVersion\Installer"

        # Überprüfe, ob der Installationsordner existiert
        if (Test-Path $EdgePath) {
            # Wechsle zum Installationsverzeichnis
            Set-Location -Path $EdgePath

            # Starte den Deinstallationsprozess
            Start-Process -FilePath "setup.exe" -ArgumentList "--uninstall", "--force-uninstall", "--system-level" -Wait
        }
    }

    # Wiederherstelle das ursprüngliche Verzeichnis
    Set-Location -Path $originalPath

    # Überprüfe, ob der Dienst MicrosoftEdgeUpdate existiert und läuft
    $edgeUpdateService = Get-Service -Name MicrosoftEdgeUpdate -ErrorAction SilentlyContinue
    if ($edgeUpdateService -ne $null -and $edgeUpdateService.Status -eq 'Running') {
        # Stoppe den Dienst MicrosoftEdgeUpdate
        Stop-Service -Name MicrosoftEdgeUpdate -Force
    }

    # Überprüfe, ob der Prozess MicrosoftEdgeUpdate.exe existiert und läuft
    $edgeUpdateProcess = Get-Process -Name MicrosoftEdgeUpdate -ErrorAction SilentlyContinue
    if ($edgeUpdateProcess -ne $null) {
        # Beende den Prozess MicrosoftEdgeUpdate.exe
        Stop-Process -Name MicrosoftEdgeUpdate -Force
    }

    # Überprüfe, ob der Ordner EdgeUpdate existiert
    $edgeUpdateFolder = "C:\Program Files (x86)\Microsoft\EdgeUpdate"
    if (Test-Path $edgeUpdateFolder) {
        # Lösche den Ordner EdgeUpdate
        Remove-Item -Path $edgeUpdateFolder -Recurse -Force
    }
    Write-Host "EdgeBrowser wurden deinstalliert" -ForegroundColor Green
    Start-Sleep -Seconds 2
}

function Remove-OneDrive {
    Write-Host "OneDrive beenden"
    Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5

    Write-Host "OneDrive deinstallieren"
    $x86 = "$env:SystemRoot\System32\OneDriveSetup.exe"
    $x64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"

    if (Test-Path $x64) {
        Start-Process -FilePath $x64 -ArgumentList "/uninstall" -Wait
    } else {
        Start-Process -FilePath $x86 -ArgumentList "/uninstall" -Wait
    }
    Start-Sleep -Seconds 5

    Write-Host "OneDrive letzte Reste entfernen"
    Remove-Item -Path "$env:USERPROFILE\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:PROGRAMDATA\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "OneDrive aus Datei Explorer entfernen"
    $regPath = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    Remove-Item -Path $regPath -Force -ErrorAction SilentlyContinue
    $regPathWow6432Node = "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    Remove-Item -Path $regPathWow6432Node -Force -ErrorAction SilentlyContinue
    $regCurrentUser = "HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\ShellFolder"
    Remove-Item -Path $regCurrentUser -Force -ErrorAction SilentlyContinue
    $regCurrentUserWow6432Node = "HKCU:\Software\Classes\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\ShellFolder"
    Remove-Item -Path $regCurrentUserWow6432Node -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

function Deinstalliere-MediaPlayer {

    Write-Host "Der Windows Media Player wird deinstalliert."

    # Überprüfe, ob die Funktion als Administrator ausgeführt wird
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Die Funktion erfordert Administratorrechte. Führen Sie die PowerShell als Administrator aus."
        return
    }

    # Überprüfe, ob das Windows Media Player-Feature installiert ist
    $mediaPlayerInstalled = Get-WindowsOptionalFeature -Online | Where-Object FeatureName -eq "WindowsMediaPlayer"

    if ($mediaPlayerInstalled -eq $null) {
        Write-Host "Der Windows Media Player ist nicht installiert."
        return
    }

    # Deinstalliere den Windows Media Player
    Disable-WindowsOptionalFeature -Online -FeatureName "WindowsMediaPlayer" -NoRestart

    Write-Host "Der Windows Media Player wurde deinstalliert."
}

function Kopiere-Ordner {
    $ordnerUrsprung = ".\OEM"
    $ordnerZiel = "$env:SystemRoot"

    try {
        # Überprüfe, ob der Zielordner bereits existiert
        if (-not (Test-Path -Path (Join-Path $ordnerZiel $ordnerUrsprung))) {
            Copy-Item -Path $ordnerUrsprung -Destination $ordnerZiel -Recurse -ErrorAction Stop
            Write-Host "Ordner von $ordnerUrsprung nach $ordnerZiel kopiert." -ForegroundColor Green
        } else {
            Write-Host "Zielordner $ordnerUrsprung existiert bereits in $ordnerZiel. Überspringe das Kopieren." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Fehler beim Kopieren des Ordners: $_"
    }
}

function Kopiere-Datei {
    $dateiUrsprung = ".\Theme\zimmer.theme"
    $zielVerzeichnis = Join-Path $env:SystemRoot "Resources\Themes"
    $zielDatei = Join-Path $zielVerzeichnis "zimmer.theme"

    try {
        # Überprüfe, ob die Zieldatei bereits existiert
        if (-not (Test-Path -Path $zielDatei)) {
            Copy-Item -Path $dateiUrsprung -Destination $zielVerzeichnis -ErrorAction Stop
            Write-Host "Datei von $dateiUrsprung nach $zielVerzeichnis kopiert." -ForegroundColor Green
        } else {
            Write-Host "Zieldatei $zielDatei existiert bereits. Überspringe das Kopieren." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Fehler beim Kopieren der Datei: $_" -ForegroundColor Red
    }
    Start-Sleep -Seconds 2
}

function Import-RegistryFiles {
    param (
        [string]$mainFolderPath = $PSScriptRoot
    )

    try {
        # Kombiniere den Hauptordner mit dem Unterordner "SetRegistryHKLM/SetLocalMachine"
        $regfilesFolder = Join-Path -Path $mainFolderPath -ChildPath "SetRegistryHKLM/SetLocalMachine"

        # Überprüfe, ob der Unterordner "Regfiles" existiert
        if (-not (Test-Path $regfilesFolder -PathType Container)) {
            Write-Host "Der Ordner 'SetLocalMachine' wurde im Hauptordner nicht gefunden." -ForegroundColor Red
            return
        }

        # Erhalte eine Liste aller REG-Dateien im Unterordner "Regfiles"
        $regFiles = Get-ChildItem -Path $regfilesFolder -Filter *.reg

        # Überprüfe, ob mindestens eine REG-Datei gefunden wurde
        if ($regFiles.Count -eq 0) {
            Write-Host "Keine REG-Dateien im Ordner 'SetLocalMachine' gefunden." -ForegroundColor Red
            return
        }

        # Durchlaufe jede gefundene REG-Datei und führe sie als Administrator aus
        foreach ($regFile in $regFiles) {
            $regFilePath = $regFile.FullName
            Write-Host "Importiere $regFilePath als Administrator..."
            
            # Verwende den Befehl 'reg import' mit erhöhten Rechten
            Start-Process "reg" -ArgumentList "import $regFilePath" -Verb RunAs

            Write-Host "Erfolgreich importiert." -ForegroundColor Green
        }

        # Überprüfen, ob die Datei existiert
        $filePath = Join-Path -Path $mainFolderPath -ChildPath "ListDelRegfile.txt"
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
            #Write-Host "Neustart des Windows Explorers..."
            #Stop-Process -Name explorer -Force
            #Start-Process explorer
            #Write-Host "Windows Explorer wurde erfolgreich neu gestartet." -ForegroundColor Green
        } else {
            Write-Host "Die Datei $filePath wurde nicht gefunden."
        }
    } catch {
        Write-Host "Fehler beim Ausführen des Skripts: $_" -ForegroundColor Red
    }
    Start-Sleep -Seconds 2
}

function ModifyDefaultUser()
{
    [CmdletBinding()]
    param()

    $scriptPath = $PSScriptRoot
    $regFolderPath = Join-Path $scriptPath "SetRegistryHKLM\DefaultUser"
    $reg = "C:\Users\Default\NTUSER.DAT"

    Write-Host "Load <DefaultUser> Hive" -ForegroundColor Green
    if (LoadHive -Path $reg) {
        Write-Host "Import Modifications" -ForegroundColor Green
        $regFiles = Get-ChildItem -Path $regFolderPath -Filter *.reg

        if ($regFiles.Count -eq 0) {
            Write-Warning "Keine .reg-Dateien im Ordner gefunden: $regFolderPath"
            return
        }

        foreach ($regFile in $regFiles) {
            reg import $regFile.FullName
        }

        Write-Host "Unload <DefaultUser> Hive" -ForegroundColor Green
        UnloadHive
    }
}

function LoadHive()
{
    [CmdletBinding()]
    param(
        [System.String]$Path
    )
    $ErrorActionPreference = "Stop"

    if (!(Get-PSDrive HKU -EA SilentlyContinue)) { New-PSDrive -PSProvider "Registry" -Name "HKU" -Root "HKEY_USERS" }

    if (Test-Path $Path -PathType Leaf) {
        try {
            reg load "HKU\<DefaultUser>" $Path
            return $true
        } catch {
            Write-Warning "Registry konnte nicht geladen werden: $Path"
            return $false
        }
    }
}

function UnloadHive()
{
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()
    try {
        reg unload "HKU\<DefaultUser>"
    } catch {
        Write-Warning "Registry-Hive konnte nicht entladen werden!"
    }
}

function Remove-StratExplorer {
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace_36354489"
    $guid = "{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"
    $entryPath = Join-Path -Path $registryPath -ChildPath $guid

    if (Test-Path $entryPath) {
        Remove-Item -Path $entryPath -Force
        Write-Host "Registry entry removed successfully."
    } else {
        Write-Host "Registry entry not found."
    }
    Start-Sleep -Seconds 2
}

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

    # Pfad zum Zielordner für alle Benutzer
    $commonFolderPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Accessibility"

    # Pfad zum Zielordner für den Administrator-Benutzer
    $adminFolderPath = "C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Accessibility"

    # Überprüfen und löschen des Ordners für alle Benutzer
    if (Test-Path $commonFolderPath -PathType Container) {
        Remove-Item -Path $commonFolderPath -Force -Recurse
        Write-Host "Der Ordner für alle Benutzer wurde erfolgreich entfernt."
    } else {
        Write-Host "Der Ordner für alle Benutzer existiert nicht und muss daher nicht entfernt werden."
    }

    # Überprüfen und löschen des Ordners für den Administrator-Benutzer
    if (Test-Path $adminFolderPath -PathType Container) {
        Remove-Item -Path $adminFolderPath -Force -Recurse
        Write-Host "Der Ordner für den Administrator-Benutzer wurde erfolgreich entfernt."
    } else {
        Write-Host "Der Ordner für den Administrator-Benutzer existiert nicht und muss daher nicht entfernt werden."
    }

    # Neustart des Windows Explorers
    Write-Host "Neustart des Windows Explorers..."
    Stop-Process -Name explorer -Force
    Start-Process explorer
    Write-Host "Windows Explorer wurde erfolgreich neu gestartet." -ForegroundColor Green
    Start-Sleep -Seconds 2
}

Remove-Apps
Uninstall-EdgeBrowser
Remove-OneDrive
Deinstalliere-MediaPlayer
Kopiere-Ordner
Kopiere-Datei
Import-RegistryFiles
ModifyDefaultUser
Remove-StratExplorer
ClearStartMenu