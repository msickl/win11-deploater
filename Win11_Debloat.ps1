function main()
{
	# Display a message and wait for input
	Write-Host "This script will perform various actions to customize your system."
	Write-Host "Press Enter to continue..."
	
	Read-Host | Out-Null 
	
	RemoveApps -config .\config.json
	
	UninstallEdgeBrowser
	
	RemoveOneDrive
	
	RemoveMediaPlayer
	
	RemoveServices -config .\config.json
	
	CopyFiles
	
	ModifyRegistryFiles
	
	ModifyDefaultUser
	
	RemoveStartExplorer
	
	ClearStartMenu

	# Success message and restart prompt
	Write-Host "The script was executed successfully.`n" -ForegroundColor Green

	# Ask for a restart
	$restartChoice = Read-Host "Do you want to restart the system now? (Yes/No)"
	if ($restartChoice -eq "Yes" -or $restartChoice -eq "yes" -or $restartChoice -eq "Y" -or $restartChoice -eq "y") {
		Write-Host "Restarting the system..."
		Restart-Computer -Force
	} else {
		Write-Host "The system will not be restarted."
	}
}

#############################################
#### FUNCTIONS
#############################################

function RemoveApps {
    [CmdletBinding()]
    param (
        [System.String]$config
    )

    if (-not (Test-Path $config)) {
        Write-Host "Error: Config file not found."
        return
    }

    $cfg = (Get-Content $config) | ConvertFrom-Json
    $apps = $cfg.appx

    Write-Output "Uninstalling Windows 11 bloatware..."

    foreach ($app in $apps) {
        if ($app.remove -eq $true) {
            Write-Output "Attempting to remove $($app.id)..."

            if ($app.info) {
                Write-Output "INFO: $($app.info)"
            }

            # Remove installed app for all existing users
            $existingUsersPackages = Get-AppxPackage -AllUsers | Where-Object { $_.PackageFamilyName -like "*$($app.id)*" }
            if ($existingUsersPackages) {
                foreach ($package in $existingUsersPackages) {
                    Remove-AppxPackage -Package $package.PackageFullName
                    Write-Output "$($app.id) uninstalled for existing users."
                }
            } else {
                Write-Output "$($app.id) not found for existing users."
            }

            # Remove provisioned app from OS image
            $provisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like "*$($app.id)*" }
            if ($provisionedPackages) {
                foreach ($package in $provisionedPackages) {
                    Remove-ProvisionedAppxPackage -Online -AllUsers -PackageName $package.PackageName
                    Write-Output "$($app.id) provisioned app removed from OS image."
                }
            } else {
                Write-Output "Provisioned app for $($app.id) not found."
            }
        }
    }

    Write-Host "Bloatware has been uninstalled.`n" -ForegroundColor Green
}

function UninstallEdgeBrowser {
    $originalPath = Get-Location

    Write-Host "Uninstall EdgeBrowser"

    # Determine the Edge version using Get-AppxPackage
    $EdgeVersion = Get-AppxPackage -Name "Microsoft.MicrosoftEdge.*" | Select-Object -ExpandProperty Version

    # Check if the Edge version is found
    if ($EdgeVersion -ne $null) {
        # Add the installation path
        $EdgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\$EdgeVersion\Installer"

        # Check if the installation folder exists
        if (Test-Path $EdgePath) {
            # Change to the installation directory
            Set-Location -Path $EdgePath

            # Start the uninstallation process
            Start-Process -FilePath "setup.exe" -ArgumentList "--uninstall", "--force-uninstall", "--system-level" -Wait
        }
        Write-Host ""
    }

    # Restore the original directory
    Set-Location -Path $originalPath

    # Check if the MicrosoftEdgeUpdate service exists and is running
    $edgeUpdateService = Get-Service -Name MicrosoftEdgeUpdate -ErrorAction SilentlyContinue
    if ($edgeUpdateService -ne $null -and $edgeUpdateService.Status -eq 'Running') {
        # Stop the MicrosoftEdgeUpdate service
        Stop-Service -Name MicrosoftEdgeUpdate -Force
    }

    # Check if the MicrosoftEdgeUpdate.exe process exists and is running
    $edgeUpdateProcess = Get-Process -Name MicrosoftEdgeUpdate -ErrorAction SilentlyContinue
    if ($edgeUpdateProcess -ne $null) {
        # Terminate the MicrosoftEdgeUpdate.exe process
        Stop-Process -Name MicrosoftEdgeUpdate -Force
    }

    # Check if the EdgeUpdate folder exists
    $edgeUpdateFolder = "C:\Program Files (x86)\Microsoft\EdgeUpdate"
    if (Test-Path $edgeUpdateFolder) {
        # Delete the EdgeUpdate folder
        Remove-Item -Path $edgeUpdateFolder -Recurse -Force
    }
    Write-Host "EdgeBrowser has been uninstalled`n" -ForegroundColor Green
}

function RemoveOneDrive {

    Write-Host "Stop OneDrive"

    Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5

    Write-Host "Uninstall OneDrive"

    $x86 = "$env:SystemRoot\System32\OneDriveSetup.exe"
    $x64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"

    if (Test-Path $x64) {
        Start-Process -FilePath $x64 -ArgumentList "/uninstall" -Wait
    } else {
        Start-Process -FilePath $x86 -ArgumentList "/uninstall" -Wait
    }

    Write-Host "Remove remaining OneDrive artifacts"

    Remove-Item -Path "$env:USERPROFILE\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:PROGRAMDATA\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "Remove OneDrive from File Explorer"

    $regPath = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    Remove-Item -Path $regPath -Force -ErrorAction SilentlyContinue
    $regPathWow6432Node = "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    Remove-Item -Path $regPathWow6432Node -Force -ErrorAction SilentlyContinue
    $regCurrentUser = "HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\ShellFolder"
    Remove-Item -Path $regCurrentUser -Force -ErrorAction SilentlyContinue
    $regCurrentUserWow6432Node = "HKCU:\Software\Classes\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\ShellFolder"
    Remove-Item -Path $regCurrentUserWow6432Node -Force -ErrorAction SilentlyContinue
    
    Write-Host "Onedrive has been successfully uninstalled`n" -ForegroundColor Green
}

function RemoveMediaPlayer {
    $mediaPlayerInstalled = Get-WindowsOptionalFeature -Online | Where-Object FeatureName -eq "WindowsMediaPlayer"

    Write-Host "Uninstalling Windows Media Player."

    # Check if the script is running as an administrator
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "This function requires administrator rights. Run PowerShell as an administrator."
        return
    }

    if ($mediaPlayerInstalled -eq $null) {
        Write-Host "Windows Media Player is not installed."
        return
    }

    # Uninstall Windows Media Player
    Disable-WindowsOptionalFeature -Online -FeatureName "WindowsMediaPlayer" -NoRestart

    Write-Host "Windows Media Player has been uninstalled.`n" -ForegroundColor Green
}

function RemoveServices {
    [CmdletBinding()]
    param (
        [System.String]$config
    )

    if (-not (Test-Path $config)) {
        Write-Host "Error: Config file not found."
        return
    }

    $cfg = (Get-Content $config -Raw) | ConvertFrom-Json
    $services = $cfg.services

    Write-Host "Services are being deleted"

    # Check if the service list is defined in the configuration
    if (-not $services) {
        Write-Host "Error: Service list not found in the config file."
        return
    }

    # Loop through the services, stop and then delete each service
    foreach ($service in $services.PSObject.Properties) {
        $serviceName = $service.Name
        $serviceProperties = $service.Value

        # Check if the service exists
        if ($existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
            # Stop the service if it's running
            if ($existingService.Status -eq 'Running') {
                Write-Host "Stopping service: $serviceName"
                Stop-Service -Name $serviceName -Force
            }

            # Delete the service
            Write-Host "Deleting service: $serviceName"
            sc.exe delete $serviceName
        } else {
            Write-Host "Service not found: $serviceName"
        }
    }

    # Display success message in green
    Write-Host "Services have been successfully deleted.`n" -ForegroundColor Green
}

function CopyFiles {
    $sourceFolder = Join-Path $PSScriptRoot "Theme\OEM"
    $destinationFolder = "$env:SystemRoot"
    $sourceFile = Join-Path $PSScriptRoot "Theme\zimmer.theme"
    $destinationFile = "$env:SystemRoot\Resources\Themes\zimmer.theme"

    Write-Host "Copy Theme and OEM Files."

    try {
        # Copy OEM Folder
        if (-not (Test-Path -Path (Join-Path $destinationFolder $sourceFolder))) {
            Copy-Item -Path $sourceFolder -Destination $destinationFolder -Recurse -ErrorAction Stop
            Write-Host "Folder copied from $sourceFolder to $destinationFolder.`n" -ForegroundColor Green
        } else {
            Write-Host "Destination folder $sourceFolder already exists in $destinationFolder. Skipping copy.`n" -ForegroundColor Yellow
        }

        # Copy BGInfo folder
        $bgInfoSourceFolder = Join-Path $PSScriptRoot "Theme\BGInfo"
        $bgInfoDestinationFolder = "C:\Program Files"

        if (-not (Test-Path -Path (Join-Path $bgInfoDestinationFolder (Split-Path $bgInfoSourceFolder -Leaf)))) {
            Copy-Item -Path $bgInfoSourceFolder -Destination $bgInfoDestinationFolder -Recurse -ErrorAction Stop
            Write-Host "Folder copied from $bgInfoSourceFolder to $bgInfoDestinationFolder.`n" -ForegroundColor Green
        } else {
            Write-Host "Destination folder $bgInfoSourceFolder already exists in $bgInfoDestinationFolder. Skipping copy.`n" -ForegroundColor Yellow
        }

        # Copy Theme
        if (-not (Test-Path -Path $destinationFile)) {
            Copy-Item -Path $sourceFile -Destination $destinationFile -ErrorAction Stop
            Write-Host "File copied from $sourceFile to $destinationFile." -ForegroundColor Green
        } else {
            Write-Host "Destination file $destinationFile already exists. Skipping copy.`n" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error while copying`n" -ForegroundColor Red
    }
}

function ModifyRegistryFiles {
    param (
        [string]$mainFolderPath = (Join-Path $PSScriptRoot "RegFiles")
    )

    try {
        # List of registry keys to process
        $registryKeys = @("HKEY_LOCAL_MACHINE", "HKEY_CLASSES_ROOT", "HKEY_USERS.DEFAULT", "HKEY_CURRENT_USER", "HKEY_PolicyManager")

        foreach ($rootKey in $registryKeys) {
            $regfilesFolder = Join-Path -Path $mainFolderPath -ChildPath $rootKey

            # Check if the folder for the current registry key exists
            if (-not (Test-Path $regfilesFolder -PathType Container)) {
                Write-Error "The folder '$rootKey' was not found in the main directory."
                continue
            }

            # Get a list of all REG files in the current subfolder
            $regFiles = Get-ChildItem -Path $regfilesFolder -Filter *.reg

            # Check if at least one REG file is found
            if ($regFiles.Count -eq 0) {
                Write-Error "No REG files found in the '$rootKey' folder."
                continue
            }

            # Iterate through each found REG file and execute it
            foreach ($regFile in $regFiles) {
                Write-Host "Importing $rootKey\$($regFile.Name) as administrator..."

                # Use Invoke-Expression or reg.exe directly
                Invoke-Expression "reg import `"$($regFile.FullName)`"" -ErrorAction Stop

                Write-Host "Successfully imported.`n" -ForegroundColor Green
            }
        }
    } catch {
        Write-Error "Error executing the script: $_"
    }
}

function ModifyDefaultUser() {
    [CmdletBinding()]
    param()

    function LoadHive() {
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
                Write-Warning "Registry could not be loaded: $Path"
                return $false
            }
        }
    }

    function UnloadHive() {
        [gc]::Collect()
        [gc]::WaitForPendingFinalizers()
        try {
            reg unload "HKU\<DefaultUser>"
        } catch {
            Write-Warning "Registry-Hive could not be unloaded!"
        }
    }

    $scriptPath = $PSScriptRoot
    $regFolderPath = Join-Path $scriptPath "RegFiles\HKEY_DEFAULT_USER"
    $reg = "C:\Users\Default\NTUSER.DAT"

    Write-Host "Load <DefaultUser> Hive" -ForegroundColor Green
    if (LoadHive -Path $reg) {
        Write-Host "Import Modifications" -ForegroundColor Green
        $regFiles = Get-ChildItem -Path $regFolderPath -Filter *.reg

        if ($regFiles.Count -eq 0) {
            Write-Warning "No .reg files found in the folder: $regFolderPath"
            return
        }

        foreach ($regFile in $regFiles) {
            reg import $regFile.FullName
        }

        Write-Host "Unload <DefaultUser> Hive`n" -ForegroundColor Green
        UnloadHive
    }
}

function RemoveStartExplorer {
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace_36354489"
    $guid = "{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"
    $entryPath = Join-Path -Path $registryPath -ChildPath $guid

    if (Test-Path $entryPath) {
        Remove-Item -Path $entryPath -Force
        Write-Host "Registry entry removed successfully."
        Write-Host ""
    } else {
        Write-Host "Registry entry not found."
    }
    Start-Sleep -Seconds 2
}

function ClearStartMenu {
    $startMenuTemplatePath = "$PSScriptRoot\Theme\start2.bin"
    
    Write-Output "Replace Start menu for all users and restart Windows Explorer."

    # Path to the default user folder
    $defaultUserStartMenuPath = "C:\Users\Default\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"
    $defaultUserStartMenuFile = Join-Path $defaultUserStartMenuPath 'start2.bin'

    # Path to the admin start menu folder
    $adminStartMenuPath = "C:\Users\Administrator\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"
    $adminStartMenuFile = Join-Path $adminStartMenuPath 'start2.bin'

    # Check and create the destination folder for the default user
    if (-not (Test-Path $defaultUserStartMenuPath)) {
        New-Item -Path $defaultUserStartMenuPath -ItemType Directory -Force
    }

    # Check and create the destination folder for the admin user
    if (-not (Test-Path $adminStartMenuPath)) {
        New-Item -Path $adminStartMenuPath -ItemType Directory -Force
    }

    # Check if the bin file exists
    if (Test-Path $startMenuTemplatePath) {
        # Copy the start menu template to the default user folder
        Copy-Item -Path $startMenuTemplatePath -Destination $defaultUserStartMenuFile -Force
        Write-Output "Start menu replaced for the default user."

        # Copy the start menu template to the admin user folder
        Copy-Item -Path $startMenuTemplatePath -Destination $adminStartMenuFile -Force
        Write-Output "Start menu replaced for the Administrator."
    } else {
        Write-Output "Error: Start menu template not found. Make sure the file 'start2.bin' is present at the specified path."
        return
    }

    # Path to the destination folder for all users
    $commonFolderPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Accessibility"

    # Path to the destination folder for the admin user
    $adminFolderPath = "C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Accessibility"

    # Check and delete the folder for all users
    if (Test-Path $commonFolderPath -PathType Container) {
        Remove-Item -Path $commonFolderPath -Force -Recurse
        Write-Host "The folder for all users was successfully removed."
    } else {
        Write-Host "The folder for all users does not exist and therefore does not need to be removed."
    }

    # Check and delete the folder for the admin user
    if (Test-Path $adminFolderPath -PathType Container) {
        Remove-Item -Path $adminFolderPath -Force -Recurse
        Write-Host "The folder for the Administrator was successfully removed."
    } else {
        Write-Host "The folder for the Administrator does not exist and therefore does not need to be removed."
    }

    # Restart Windows Explorer
    Write-Host "Restarting Windows Explorer..."
    Stop-Process -Name explorer -Force
    Start-Process explorer
    Write-Host "Windows Explorer was successfully restarted.`n" -ForegroundColor Green
}

main