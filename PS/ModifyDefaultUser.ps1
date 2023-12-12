function main()
{
    $scriptPath = $PSScriptRoot
    $regFolderPath = Join-Path $scriptPath "DefaultUser"  # Der Ordner mit den .reg-Dateien befindet sich im gleichen Verzeichnis wie das Skript

    $reg = "C:\Users\Default\NTUSER.DAT"

    Write-Host "Load <DefaultUser> Hive" -ForegroundColor Green
    LoadHive -path $reg

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

function LoadHive()
{
    [CMDLetBinding()]
    param(
        [System.String]$path
    )
    $ErrorActionPreference = "Stop"

    if (!(Get-PSDrive HKU -EA SilentlyContinue)) { New-PSDrive -PSProvider "Registry" -Name "HKU" -Root "HKEY_USERS" }

    if (Test-Path $path -PathType Leaf) {
        try {
            reg load "HKU\<DefaultUser>" $path
            return $true
        } catch {
            Write-Warning "Registry konnte nicht geladen werden: $path"
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

main
