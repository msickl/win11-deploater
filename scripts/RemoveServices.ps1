function Remove-ServicesFromList {
    $PathToList = ".\DelServicesList.txt"

    # Check if the file exists
    if (-not (Test-Path -Path $PathToList -PathType Leaf)) {
        Write-Host "The specified list ($PathToList) does not exist. Make sure the path is correct."
        return
    }

    # Read service names from the list
    $serviceNames = Get-Content -Path $PathToList

    # Loop through the service names, stop and then delete the services
    foreach ($serviceName in $serviceNames) {
        # Check if the service exists
        if ($service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
            # Stop the service
            if ($service.Status -eq 'Running') {
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
}

# Example call without the need for a path parameter
Remove-ServicesFromList
