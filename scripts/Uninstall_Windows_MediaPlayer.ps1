function Deinstalliere-MediaPlayer {
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

    Write-Host "Der Windows Media Player wurde deinstalliert. Ein Neustart des Systems ist erforderlich."
}

# Funktion aufrufen
Deinstalliere-MediaPlayer
