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
}

Remove-OneDrive
