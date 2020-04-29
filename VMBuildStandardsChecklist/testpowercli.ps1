Import-Module VMware.PowerCLI
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Connect-VIServer pagr2vc001.prodroot.local


$VMHostName = Get-VM -Name PWGR2RSQL034C-1 | select -ExpandProperty VMHost | select -ExpandProperty Name
#VirtualMachine-vm-13856


Get-VMHost -Name $VMHostName | Select Name,MaxEVCMode
#HostSystem-host-283
Get-VMHost | Select Name,MaxEVCMode
Get-VMHost -Name $VMHostName | Get-View 

Get-VMHost -Name $VMHostName| Select-Object Name,HyperthreadingActive


$model = Get-WmiObject -Class Win32_ComputerSystem -ComputerName pwgr2rsqldb1c-2.prod.pb01.local | Select -ExpandProperty Model;if($model -like "*Virtual*"){echo "N"} else {echo "Y"}




Get-VM | Select-Object -Property Name,

@{Name='MinRequiredEVCModeKey';Expression={$_.ExtensionData.Runtime.MinRequiredEVCModeKey}},

@{Name='Cluster';Expression={$_.VMHost.Parent}},

@{Name='ClusterEVCMode';Expression={$_.VMHost.Parent.EVCMode}}






(Get-VM | select ExtensionData).ExtensionData.config | Select Name, MemoryHotAddEnabled 

(Get-VM -Name NWGR2DEXPEMV006 | select ExtensionData).ExtensionData.config | Select *


 Get-VM -Name NWGR2DEXPEMV006 | Get-View  | foreach {Write-output * $_.Config.CpuAffinity.AffinitySet}
 Get-VM -Name NWGR2DEXPEMV006 | Get-View  | foreach {Write-output $_.Name $_.Config.CpuAffinity.AffinitySet}

Get-VM -Name NWGR2DEXPEMV006 | Get-View | select Config.CpuAffinity.AffinitySet

 Get-VM -Name NWGR2DEXPEMV006 | Get-View  | select $_.Config.CpuAffinity.AffinitySet
 Get-VM -Name NWGR2DEXPEMV006 | Get-View  | select -ExpandProperty Config | select Name,CpuAffinity 
 Get-VM -Name NWGR2DEXPEMV006 | Get-View  | select -ExpandProperty Config | select Name,CpuHotAddEnabled
 Get-VM -Name NWGR2DEXPEMV006 | Get-View  | select -ExpandProperty Config | select -ExpandProperty CpuAllocation | select *


 Get-VM -Name NWGR2QEXPSQL501 | Get-View  | select -ExpandProperty Config | select Name, CpuHotAddEnabled,CpuAffinity
 

 Get-VM -Name NWGR2QEXPSQL501 | Get-VMResourceConfiguration | select VM,
 
 Get-VM -Name NWGR2QEXPSQL501 | Get-VMResourceConfiguration | Select VM,CpuReservationMhz, MemReservationGB

 try
    {
        $a = Import-Module VMware.VimAutomation.Core -ErrorAction SilentlyContinue
        $a = Connect-VIServer nagr2vc001.nproot.local
        
    }
catch
    {
        
        $_.Exception.Message
    }


    $VMHostName = Get-VM -Name NWGR2SEXPSQL701 | select -ExpandProperty VMHost | select -ExpandProperty Name
    Get-VMHost -Name $VMHostName | Select *
    



Get-VMHost -Name $VMHostName | Get-View | select -ExpandProperty Config | select -ExpandProperty Option | Where-Object { $_.key -like "*cpu*"}

$VMHostName = Get-VM -Name NWGR2SEXPSQL701 | select -ExpandProperty VMHost | select -ExpandProperty Name
Get-VMHost -Name $VMHostName | Select-Object Name,MaxEVCMode
Get-VMHost | Select-Object Name,MaxEVCMode

