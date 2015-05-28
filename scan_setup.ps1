Write-Host "---------------------------------------------------------"
Write-Host "Please put list of computers on desktop and name it computers.txt if you are planning to remote manage."
Write-Host "This file is required for both scan prep and scan backout"
Write-Host "---------------------------------------------------------"
$user_input = Read-Host "Press 1 for scanning prep and 2 for scanning backout. Press 3 to set up admin accounts on your systems"



if ($user_input -eq "1"){
$system_list = @(Get-Content "C:\Users\$env:username\Desktop\computers.txt")
    Write-Host "Prepping systems for scanning"
    for ($i=0; $i -lt $system_list.length; $i++) {

        Invoke-Command -ComputerName $system_list[$i] -ScriptBlock {

        #OBTAIN OLD SETTINGS 

        #Map a network Drive
        $mapped_drive = "\\l8gssrvfs01\GSI Share\Scan Outputs" #map this to shared drive in production
        New-PSDrive -Name "M" -PsProvider FileSystem -root "$mapped_drive" > $null

        $hostname = hostname
        $timestamp = Get-Date -UFormat "%Y-%m-%d"
        #$directorypath = "C:\Users\$env:username\Desktop\"

        $Old_Lan_Workstation = (Get-ItemProperty -Path 'HKLM:\SYSTEM\ControlSet001\services\LanmanWorkstation\Parameters' -Name 'RequiredSecuritySignature').RequiredSecuritySignature
        $Old_Lan_Server = (Get-ItemProperty -Path 'HKLM:\SYSTEM\ControlSet001\services\LanmanServer\Parameters' -Name 'requiressecuritysignature').requiressecuritysignature
        $Old_LSA = (Get-ItemProperty -ea SilentlyContinue -Path 'HKLM:\SYSTEM\ControlSet001\Control\Lsa' -Name 'LMCompatibilityLevel').LMComptabilityLevel

        $server_service_status = (Get-Service -DisplayName 'Server').Status
        $remote_registry_status = (Get-Service -DisplayName 'Remote Registry').Status
        $lmhosts_status = (Get-Service -DisplayName 'Windows Management Instrumentation').Status
        $wmi_status = (Get-Service -DisplayName "Windows Management Instrumentation").Status

        Write-Output ("Original Lan Workstation settings = " + $Old_Lan_Workstation) + ("Original Lan Server Settings = " + $Old_Lan_Server) + ("Original LSA settings = " + $Old_LSA) + ("Original server status = " + $server_service_status) + ("Original Remote reg status = " + $remote_registry_status) + ("Original Lmhosts status = " + $lmhosts_status) + ("Original WinRM status = " + $wmi_status) >> "M:\$hostname-securitysettings-$timestamp.txt"

        #Remove mapped Drive
        Remove-PSDrive -Name "M"

        #----------------------------------------------------------
        #----------------------------------------------------------
        #MODIFY SETTINGS

        #stop Symantec
        $env:Path += ';C:\Program Files (x86)\Symantec\Symantec Endpoint Protection'
        #traps error if SMC is not found
        trap [Management.Automation.COmmandNotFoundException]
        {
            Write-Host -ForegroundColor Red "ERROR: !!!!!Symantec not installed in assumed directory or at all!!!!!!!!"
            continue
        }
        smc -stop

        #Enable NetBios
        $NIC = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled = true" 
        $NIC.SetTcpipNetbios("1") > $null

        #Enable File and Printer sharing
        Write-Host "**************Enabling File and Printer sharing*************"
        netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=yes

        #Start and stop sevices
        if ($remote_registry_status -ne "Running") {
            Write-Host "Starting RemoteRegistry"
            net start RemoteRegistry #Not automatic it seems
            }
        else {Write-Host "Remote Registry Service already running"}

        if ($server_service_status -ne "Running") {
            Write-Host "Starting Server"
            net start Server #automatic on Win7
            }
        else {Write-Host "Server Service already running"}

        if ($lmhosts_status -ne "Running") {
            Write-Host "Starting lmhosts"
            net start lmhosts #automatic on Win7
            }
        else {Write-Host "NetBIOS Helper Service already running"}

        if ($wmi_status -ne "Running") {
            Write-Host "Starting Winmgmt"
            net start Winmgmt #automatic on Win7
            }
        else {Write-Host "WMI Service already running"}

        #Enable MS Net Client sign communication (always)
        Set-ItemProperty HKLM:\SYSTEM\ControlSet001\services\LanmanWorkstation\Parameters -Name RequiredSecuritySignature -Value 1

        #Enables MS Net Server sign communications (always)
        Set-ItemProperty HKLM:\SYSTEM\ControlSet001\services\LanmanServer\Parameters -Name requiressecuritysignature -Value 1

        #LAN Manager authentication level
        $path_check = Test-RegistryValue -Path 'HKLM:\SYSTEM\ControlSet001\Control\Lsa' -Value 'LMCompatibilityLevel'
        if ($path_check -eq 'False'){
        Write-Host "Adding LMCompatibilityLevel Registry Key"
        New-ItemProperty HKLM:\SYSTEM\ControlSet001\Control\Lsa -Name LMCompatibilityLevel -Value 1 -Type DWord > $null
        }
        else {Write-Host "LSA Key was already in registry"}

        }
    }
}
ElseIf ($user_input -eq "2") {
$system_list = @(Get-Content "C:\Users\$env:username\Desktop\computers.txt")
    Write-Host "Backing out security settings"
    for ($i=0; $i -lt $system_list.length; $i++) {
        Invoke-Command -ComputerName $system_list[$i] -ScriptBlock {
            #Capture settings
            $server_service_status = (Get-Service -DisplayName 'Server').Status
            $remote_registry_status = (Get-Service -DisplayName 'Remote Registry').Status
            $lmhosts_status = (Get-Service -DisplayName 'Windows Management Instrumentation').Status
            $wmi_status = (Get-Service -DisplayName "Windows Management Instrumentation").Status

            trap [Management.Automation.COmmandNotFoundException]
            {
                Write-Host -ForegroundColor Red "ERROR: !!!!!Symantec not installed in assumed directory or at all!!!!!!!!"
                continue
            }

            #start Symantec
            $env:Path += ';C:\Program Files (x86)\Symantec\Symantec Endpoint Protection'
            smc -start

            #Disable NetBios
            $NIC = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled = true" 
            $NIC.SetTcpipNetbios("0") > $null

            #Start and stop sevices
            if ($remote_registry_status -eq "Running") {
                Write-Host "Stopping RemoteRegistry"
                net stop RemoteRegistry #Not automatic it seems
                }
            else {Write-Host "Remote Registry Service was not running"}

            if ($server_service_status -eq "Running") {
                Write-Host "Server will continue to run, this is default on Windows 7"
                }

            if ($lmhosts_status -eq "Running") {
                Write-Host "netBIOS helper will continue to run, this is default on Windows 7"
                }

            if ($wmi_status -eq "Running") {
                Write-Host "WMI service will continue to run, this is default on Windows 7"
                }

            #Enable MS Net Client sign communication (always)
            Set-ItemProperty HKLM:\SYSTEM\ControlSet001\services\LanmanWorkstation\Parameters -Name RequiredSecuritySignature -Value 0

            #Enables MS Net Server sign communications (always)
            Set-ItemProperty HKLM:\SYSTEM\ControlSet001\services\LanmanServer\Parameters -Name requiressecuritysignature -Value 0

            $path_check = Test-RegistryValue -Path 'HKLM:\SYSTEM\ControlSet001\Control\Lsa' -Value 'LMCompatibilityLevel'
            if ($path_check -eq 'True'){
                #LAN Manager authentication level
                Remove-ItemProperty HKLM:\SYSTEM\ControlSet001\Control\Lsa -Name LMCompatibilityLevel
                }

            }
        }
    }
#Added password feature
ElseIf ($user_input -eq "3") {
    $my_secure_password_string1 = " "
    $counter = 0
    #password over 8 characters check
    while ( $my_secure_password_string1.Length -le 8){
        if ($counter -le 0){Write-Host -ForegroundColor Red "Enter a password over 8 characters for admin account"
            $my_secure_password_string1 = Read-Host -AsSecureString "Enter password for" $env:computername
            $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($my_secure_password_string1)
            $my_secure_password_string1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
            $counter += 1
        }
        elseif ($counter -gt 0) {Write-Host -ForegroundColor Red "Password was less then 8 characters, try again"
            $my_secure_password_string1 = Read-Host -AsSecureString "Enter password for" $env:computername
            $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($my_secure_password_string1)
            $my_secure_password_string1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
            $counter += 1
        }

    }
	#change ADMINUSERNAME to the username you use
    #Takes in systemlist 
    $system_list = @(Get-Content "C:\Users\$env:username\Desktop\computers.txt")
    for ($i=0; $i -lt $system_list.length; $i++) { 
        $connect_to = New-PSSession -ComputerName $system_list[$i]
        Invoke-Command -Session $connect_to -ScriptBlock {
            param($secure_password)
            $computerName = $env:COMPUTERNAME
            $computer = [ADSI] "WinNT://$computerName,Computer"
            foreach ( $childObject in $computer.Children ) {
                # Skip objects that are not users.
                if ( $childObject.Class -ne "User" ) {
                continue
                }
             $type = "System.Security.Principal.SecurityIdentifier"
             $childObjectSID = new-object $type($childObject.objectSid[0],0)
                if ( $childObjectSID.Value.EndsWith("-500") ) {
                    $found_account_name = $($childObject.Name[0])
                    if ($found_account_name -ne 'ADMINUSERNAME'){
                        Write-Host -ForegroundColor Red "Found Admin account was named $found_account_name and changed to proper name"
                        $user = [ADSI]"WinNT://./$found_account_name,user"
                        $user.Rename('ADMINUSERNAME')
                        net user 'ADMINUSERNAME' /active:Yes
                        break}
                    Elseif ($found_account_name -eq 'ADMINUSERNAME'){
                        $reset_choice = Read-Host "Admin account seems to be named correctly. Set password anyways? y/n"
                        if ($reset_choice -eq 'y'){
                            $user = [ADSI]"WinNT://./$found_account_name,user"
                            $user.Rename('ADMINUSERNAME')
                            net user 'ADMINUSERNAME' /active:Yes
                            break}
                        Elseif ($reset_choice -ne 'y'){
                            Write-Host -ForegroundColor Red "Your choice was either No or not recognized. Skipping password reset"
                            break}
            }
                }
    }
        Get-WmiObject win32_useraccount -Filter "Name='ADMINUSERNAME'" | ForEach-Object {
            ([adsi](“WinNT://”+$_.caption).replace(“\”,”/”)).SetPassword("$secure_password")}
        } -Args $my_secure_password_string1
    }
}

Else {
    Write-Host "Error you did not select 1 or 2. Restarting"
    .\security_scan_setup.ps1
    }

Exit-PSSession



