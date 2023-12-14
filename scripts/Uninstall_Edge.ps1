function Uninstall-EdgeBrowser {
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
}

# Funktionsaufruf
Uninstall-EdgeBrowser


# # Speichere das aktuelle Verzeichnis
# $originalPath = Get-Location

# # Ermittle die Edge-Version mit Get-AppxPackage
# $EdgeVersion = Get-AppxPackage -Name "Microsoft.MicrosoftEdge.*" | Select-Object -ExpandProperty Version

# # Überprüfe, ob die Edge-Version gefunden wurde
# if ($EdgeVersion -ne $null) {
#     # Füge den Installationspfad hinzu
#     $EdgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\$EdgeVersion\Installer"

#     # Überprüfe, ob der Installationsordner existiert
#     if (Test-Path $EdgePath) {
#         # Wechsle zum Installationsverzeichnis
#         Set-Location -Path $EdgePath

#         # Starte den Deinstallationsprozess
#         Start-Process -FilePath "setup.exe" -ArgumentList "--uninstall", "--force-uninstall", "--system-level" -Wait
#     }
# }

# # Wiederherstelle das ursprüngliche Verzeichnis
# Set-Location -Path $originalPath

# # Überprüfe, ob der Dienst MicrosoftEdgeUpdate existiert und läuft
# $edgeUpdateService = Get-Service -Name MicrosoftEdgeUpdate -ErrorAction SilentlyContinue
# if ($edgeUpdateService -ne $null -and $edgeUpdateService.Status -eq 'Running') {
#     # Stoppe den Dienst MicrosoftEdgeUpdate
#     Stop-Service -Name MicrosoftEdgeUpdate -Force
# }

# # Überprüfe, ob der Prozess MicrosoftEdgeUpdate.exe existiert und läuft
# $edgeUpdateProcess = Get-Process -Name MicrosoftEdgeUpdate -ErrorAction SilentlyContinue
# if ($edgeUpdateProcess -ne $null) {
#     # Beende den Prozess MicrosoftEdgeUpdate.exe
#     Stop-Process -Name MicrosoftEdgeUpdate -Force
# }

# # Überprüfe, ob der Ordner EdgeUpdate existiert
# $edgeUpdateFolder = "C:\Program Files (x86)\Microsoft\EdgeUpdate"
# if (Test-Path $edgeUpdateFolder) {
#     # Lösche den Ordner EdgeUpdate
#     Remove-Item -Path $edgeUpdateFolder -Recurse -Force
# }
