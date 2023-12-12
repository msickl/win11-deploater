function Remove-Apps {
    [CmdletBinding()]
    param(
        [System.String]$config
    )

    if (-not (Test-Path $config)) {
        Write-Host "Error: Config file not found."
        return
    }

    $cfg = (Get-Content $config) | ConvertFrom-Json
    $apps = $cfg.appx

    Write-Output "Uninstalling Windows 11 bloatware..."

    # Get a list of apps from the provided file path and remove them one by one
    foreach ($app in $apps) { 
        # Remove any spaces before and after the Appname
        if ($app.remove -eq $true) {
            Write-Output "Attempting to remove $($app.displayname)..."
            
            if ($app.info) {
                Write-Output "INFO: $($app.info)"
            }

            # Remove installed app for all existing users
            try {
                Get-AppxPackage -PackageFullName "$($app)" -AllUsers | Remove-AppxPackage -ErrorAction Stop
                Write-Output "$($app.displayname) uninstalled for existing users."
            } catch {
                Write-Output "Error uninstalling $($app.displayname) for existing users: $_"
            }

            # Remove provisioned app from OS image, so the app won't be installed for any new users
            try {
                Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like "*$($app.displayname)*" } | ForEach-Object { Remove-ProvisionedAppxPackage -Online -PackageName $_.PackageName -ErrorAction Stop }
                Write-Output "$($app.displayname) provisioned app removed from OS image."
            } catch {
                Write-Output "Error removing provisioned app for $($app.displayname): $_"
            }
        }   
    }

    Write-Host "Bloatware has been uninstalled.`n" -ForegroundColor Green
}

Remove-Apps -config .\config.json
