param (
[string]$system = $(throw "Requires specification of system via: '-system Linux/Windows'"),
[string]$user_input2 = $(Read-Host "If searching for a specific user, type the name here, otherwise press Enter")
)
#designate view connection Server
$viewserver = VIEW_CONNECTION_SERVER
If ($system -eq 'Linux'){
	Invoke-Command -ComputerName $viewserver -ScriptBlock{
	param ($user_input2)
	Add-PSSnapin vmware.view.broker
	Write-Host "----Linux CONNECTIONS----"
	If ([string]::IsNullOrWhiteSpace($user_input2)){
		Get-RemoteSession -protocol Blast | select Username,pool_id,state,duration
	}
	Else {
		$username = 'DOMAIN\' + $user_input2
		Get-RemoteSession -protocol Blast | where {$_.Username -Like $username} | select username,pool_id,state,duration
	}
	Write-Host "----Linux CONNECTIONS----"
	} -argumentlist $user_input2
}
ElseIf ($system -eq 'Windows'){
	Invoke-Command -ComputerName $viewserver -ScriptBlock {
	Add-PSSnapin vmware.view.broker
	Write-Host "----Windows CONNECTIONS----"
	Get-RemoteSession -protocol PCOIP | select Username,pool_id,state
	Write-Host "----Windows CONNECTIONS----"
	}
}

