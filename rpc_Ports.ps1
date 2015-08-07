#Sets RPC port range

$port_range = '5000-5300'
$ports_available = 'Y'
$use_ports = 'Y'

if (Test-Path HKLM:\SOFTWARE\Microsoft\Rpc\Internet){
    if (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Rpc\Internet -Name Ports -ErrorAction SilentlyContinue){
        Set-ItemProperty HKLM:\Software\Microsoft\Rpc\Internet -Name Ports -Value $port_range -Type MultiString > $null
    }
    else {New-ItemProperty HKLM:\Software\Microsoft\Rpc\Internet -Name Ports -Value $port_range -Type MultiString > $null
    }


    if (Get-ItemProperty HKLM:\Software\Microsoft\Rpc\Internet -Name PortsInternetAvailable -ErrorAction SilentlyContinue){
        Set-ItemProperty HKLM:\Software\Microsoft\Rpc\Internet -Name PortsInternetAvailable -Value $ports_available -Type String > $null
    }
    else {New-ItemProperty HKLM:\Software\Microsoft\Rpc\Internet -Name PortsInternetAvailable -Value 'Y' -Type String > $null
    }

    if (Get-ItemProperty HKLM:\Software\Microsoft\Rpc\Internet -Name UseInternetPorts -ErrorAction SilentlyContinue){
        Set-ItemProperty HKLM:\Software\Microsoft\Rpc\Internet -Name UseInternetPorts -Value $use_ports -Type String > $null
    }
    else {New-ItemProperty HKLM:\Software\Microsoft\Rpc\Internet -Name UseInternetPorts -Value 'Y' -Type String > $null
    }
}

else { New-Item -Path HKLM:\Software\Microsoft\Rpc -Name Internet 
    New-ItemProperty HKLM:\Software\Microsoft\Rpc\Internet -Name Ports -Value $port_range -Type MultiString > $null
    New-ItemProperty HKLM:\Software\Microsoft\Rpc\Internet -Name PortsInternetAvailable -Value 'Y' -Type String > $null
    New-ItemProperty HKLM:\Software\Microsoft\Rpc\Internet -Name UseInternetPorts -Value 'Y' -Type String > $null
    break
}

