# ==============================================================================
# Active Directory Password Reset Script V2
# ==============================================================================
# Author: Sushanth varma
# Created: 2024
# ==============================================================================
# This script provides functionality to:
# 1. Reset AD user passwords via LDAP
# 2. Generate complex passwords meeting AD requirements
# 3. Test AD connectivity
# 4. Retrieve password change timestamps
# ==============================================================================

# Global AD Configuration
$Global:ADConfig = @{
    Server = "172.16.30.142"
    Domain = "idmtdc"
    AdminUser = "Administrator"
    AdminPassword = "Passw0rd!"
}

# Test AD connectivity
function Test-ADConnection {
    try {
        Write-Host "`nTesting AD Connection:" -ForegroundColor Yellow
        Write-Host "Server: $($ADConfig.Server)"
        Write-Host "Domain: $($ADConfig.Domain)"
        Write-Host "Username: $($ADConfig.AdminUser)"
        
        # Create credential object
        $SecurePassword = ConvertTo-SecureString $ADConfig.AdminPassword -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ("$($ADConfig.Domain)\$($ADConfig.AdminUser)", $SecurePassword)
        
        # Test LDAP connection
        $LdapPath = "LDAP://$($ADConfig.Server)"
        Write-Host "Testing LDAP connection to: $LdapPath" -ForegroundColor Yellow
        
        $DirectoryEntry = New-Object System.DirectoryServices.DirectoryEntry($LdapPath, "$($ADConfig.Domain)\$($ADConfig.AdminUser)", $ADConfig.AdminPassword)
        
        if ($DirectoryEntry.name -ne $null) {
            Write-Host "Successfully connected to AD!" -ForegroundColor Green
            Write-Host "Distinguished Name: $($DirectoryEntry.distinguishedName)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Connection failed - Could not bind to AD" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Connection Error:" -ForegroundColor Red
        Write-Host "Error Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
        Write-Host "Error Message: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Generate a random password
function Generate-RandomPassword {
    param (
        [int]$Length = 7
    )
    
    $CharSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    $Password = -join ((1..$Length) | ForEach-Object { $CharSet[(Get-Random -Maximum $CharSet.Length)] })
    return $Password
}

# Function to reset AD user password
function Reset-UserADPassword {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Username
    )
    
    # First test the connection
    if (-not (Test-ADConnection)) {
        Write-Host "Cannot proceed with password reset - Connection test failed" -ForegroundColor Red
        return
    }
    
    try {
        # Create credential object
        $SecurePassword = ConvertTo-SecureString $ADConfig.AdminPassword -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ("$($ADConfig.Domain)\$($ADConfig.AdminUser)", $SecurePassword)
        
        # Generate new password
        $NewPassword = Generate-RandomPassword -Length 7
        
        # Convert password to secure string
        $SecureNewPassword = ConvertTo-SecureString $NewPassword -AsPlainText -Force
        
        # Search for user with credentials
        $User = Get-ADUser -Server $ADConfig.Server -Credential $Credential -Filter "SamAccountName -eq '$Username'" -ErrorAction Stop
        
        if ($User) {
            Write-Host "Found user: $($User.DistinguishedName)" -ForegroundColor Yellow
            
            # Reset password using credentials
            Set-ADAccountPassword -Server $ADConfig.Server -Credential $Credential -Identity $User -NewPassword $SecureNewPassword -Reset
            
            # Get last password set time
            $UpdatedUser = Get-ADUser -Server $ADConfig.Server -Credential $Credential -Identity $User -Properties PasswordLastSet
            
            # Output results
            Write-Host "`nPassword Reset Summary:" -ForegroundColor Green
            Write-Host "------------------------------"
            Write-Host "Username: $Username"
            Write-Host "Distinguished Name: $($User.DistinguishedName)"
            Write-Host "New Password: $NewPassword"
            Write-Host "Reset Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            Write-Host "Password Last Set: $($UpdatedUser.PasswordLastSet)"
            Write-Host "Status: Success"
            Write-Host "------------------------------"
        }
        else {
            Write-Host "User not found: $Username" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "`nError occurred:" -ForegroundColor Red
        Write-Host "Error Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
        Write-Host "Error Message: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main script execution
if ($args.Count -eq 0) {
    $Username = Read-Host "Enter username to reset password"
}
else {
    $Username = $args[0]
}

# Execute password reset
Reset-UserADPassword -Username $Username