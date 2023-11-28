# Setzen Sie den Pfad zum Registrierungsschlüssel
$registryPath = "HKLM:\SOFTWARE\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"

# Setzen Sie den neuen Eigentümer
$newOwner = "Jeder"

# Holen Sie den aktuellen Besitzer des Registrierungsschlüssels
$currentOwner = (Get-Item -LiteralPath $registryPath).GetAccessControl().Owner

# Erstellen Sie einen neuen Besitzer für die ACL
$owner = New-Object System.Security.Principal.NTAccount($newOwner)

# Setzen Sie den neuen Besitzer für den Registrierungsschlüssel
$regKey = Get-Item -LiteralPath $registryPath
$regKey.SetAccessControl((New-Object System.Security.AccessControl.RegistrySecurity))
$acl = $regKey.GetAccessControl()
$acl.SetOwner($owner)
$regKey.SetAccessControl($acl)

Write-Host "Der Besitzer des Registrierungsschlüssels wurde auf '$newOwner' geändert."
