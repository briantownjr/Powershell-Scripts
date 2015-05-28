$NICs = Get-WMIObject Win32_NetworkAdapterConfiguration -computername . | where{$_.IPEnabled -eq $true} 
$user_input = Read-Host "Press 1 to swap main DNS to x, and 2 to swap main DNS to x"
$DNSServers = "x.x.x.x","x.x.x.x"
if ($user_input -eq "1"){
    Foreach($NIC in $NICs) { 
        $ad1 = "x.x.x.x"
        $ad2 = "x.x.x.x"
        $dns = $NIC.DNSServerSearchOrder
        if ($dns -ne $ad1){
            Write-Host "nope"
            $NIC.SetDNSServerSearchOrder($DNSServers)}
    }
}
Elseif ($user_input -eq "2"){
    Foreach($NIC in $NICs) { 
        $ad1 = "x.x.x.x"
        $ad2 = "x.x.x.x"
        $dns = $NIC.DNSServerSearchOrder
        if ($dns -ne $ad1){
            Write-Host "nope"
            $NIC.SetDNSServerSearchOrder($DNSServers)}
    }
}