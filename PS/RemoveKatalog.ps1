$subkey = "SOFTWARE\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"

$rk = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($subkey, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::ChangePermissions)
$rs = [System.Security.AccessControl.RegistrySecurity]::new()

$rar = [System.Security.AccessControl.RegistryAccessRule]::new(
    "Administrator",
    [System.Security.AccessControl.RegistryRights]::FullControl,
    [System.Security.AccessControl.InheritanceFlags]::ContainerInherit,
    [System.Security.AccessControl.PropagationFlags]::InheritOnly,
    [System.Security.AccessControl.AccessControlType]::Allow
)
$rs.AddAccessRule($rar)
$rk.SetAccessControl($rs)


# $subkey = "SOFTWARE\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"


# $rk = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($subkey, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadSubTree, [System.Security.AccessControl.RegistryRights]::ChangePermissions)
# $rs = [System.Security.AccessControl.RegistrySecurity]::new()

# $rar = [System.Security.AccessControl.RegistryAccessRule]::new(
#     "Administrator",
#     [System.Security.AccessControl.RegistryRights]::FullControl,
#     [System.Security.AccessControl.InheritanceFlags]::ContainerInherit,
#     [System.Security.AccessControl.PropagationFlags]::InheritOnly,
#     [System.Security.AccessControl.AccessControlType]::Allow
# )
# $rs.AddAccessRule($rar)
# $rk.SetAccessControl($rs)



#$acl = $registryKey.GetAccessControl()
#$acl.SetOwner([System.Security.Principal.NTAccount]::new($newOwner))
#$registryKey.SetAccessControl($acl)

#$newOwner = $registryKey.GetAccessControl().GetOwner([System.Security.Principal.NTAccount])
#Write-Host "Neuer Besitzer: $newOwner"
