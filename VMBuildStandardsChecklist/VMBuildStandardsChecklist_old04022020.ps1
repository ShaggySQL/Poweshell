param([string]$ServerName)
$global:rowtemp = @()
$global:resultfiledata = @()
function Perform-Validation 
{
    [CmdletBinding()]
    Param
    (
        [string]$ServerName  
    )
    $global:resultfilepath = Split-Path -Parent $PSCommandPath
    $date = (Get-Date -Format "MM_dd_yyyy") 
    $global:resultfile = "$resultfilepath\VMBuildStandardsChecklist_$date.csv"
    $global:rowtemp = @()
    $global:tempresult = @()
    # 1024*1024*1024 = 1073741824 
    
    <#
    $global:cmdcollection = @()
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=1; isSQL=0; Control='Is_Physical';  Command='$model = Get-WmiObject -Class Win32_ComputerSystem | Select -ExpandProperty Model;if($model -like "*Virtual*"){echo "N"} else {echo "Yes"}'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=2; isSQL=0; Control='Is_Non_Prod';  Command='$hostname = [System.Net.Dns]::GetHostName() ;if($hostname -like "N*"){echo "Y"} else {echo "N"}'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=3; isSQL=0; Control='WindowsServerName';  Command='[System.Net.Dns]::GetHostName()'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=4; isSQL=0; Control='Windows_FQDN';  Command='(Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=5; isSQL=1; Control='SQL_Instance_Name';  Command='select SERVERPROPERTY(''SERVERNAME'') as queryoutput'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=6; isSQL=0; Control='OperatingSystemVersion';  Command='$osversion = Get-WmiObject Win32_OperatingSystem | select -ExpandProperty Name;if ($osversion -like "*|*") {$osversion = $osversion.split("|")[0];$osversion} else {$osversion}  '}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=7; isSQL=0; Control='Processors';  Command='$processors = (Get-WmiObject Win32_Processor | select-object Name | Measure-Object).Count; echo $processors'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=8; isSQL=0; Control='TotalCores';  Command='$processors = (Get-WmiObject Win32_Processor | select-object Name | Measure-Object).Count;$num_of_cores = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty NumberOfCores -first 1; $cores = $num_of_cores * $processors; echo $cores'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=9; isSQL=0; Control='TotalLogicalCores';  Command='$processors = (Get-WmiObject Win32_Processor | select-object Name | Measure-Object).Count;$num_logicalcores = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty  NumberOfLogicalProcessors -first 1;$num_logicalcores = $num_logicalcores * $processors; $num_logicalcores'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=10; isSQL=0; Control='ProcessorType';  Command='Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name -first 1'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=11; isSQL=0; Control='HyperthreadingEnabled';  Command='$processors = (Get-WmiObject Win32_Processor | select-object Name | Measure-Object).Count;$num_of_cores = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty NumberOfCores -first 1; $cores = $num_of_cores * $processors;$num_logicalcores = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty  NumberOfLogicalProcessors -first 1;$num_logicalcores = $num_logicalcores * $processors;if ($num_logicalcores -gt $cores) {echo "Y, Logical Cores : $num_logicalcores"} else {echo ''N''}'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=12; isSQL=1; Control='SQL_Version_No';  Command='select SERVERPROPERTY(''ProductVersion'') AS queryoutput'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=13; isSQL=1; Control='SQL_Version_Name';  Command='select substring(@@version,0,charindex(convert(varchar,SERVERPROPERTY(''productversion'')) ,@@version)+len(convert(varchar,SERVERPROPERTY(''productversion'')))) as queryoutput'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=14; isSQL=1; Control='SQL_Edition';  Command='select SERVERPROPERTY(''Edition'') AS queryoutput'}
    #>
    #Add above line with appropriate control and its command to fetch the result
    #$cmdcollection

    if($ServerName.Length -eq 0)
    {
        $a = Connect-VIServer pagr2vc001.prodroot.local
        #$a = Connect-VIServer paflovc001.prodroot.local
        $list_of_vms = Get-VM -Name "*SQL*" | Where-Object {$_.PowerState -eq "PoweredOn"}
        #$list_of_vms = Get-VM -Name PWGR2PEXPSQL901 | Where-Object {$_.PowerState -eq "PoweredOn"}
        #$list_of_vms = Get-VM | Where-Object {$_.PowerState -eq "PoweredOn"}
        

        foreach ($v in $list_of_vms)
        {
            #$drsrulevms = @()
            $vmdrsrulesAA = $null
            $vmdrsrulesHA = $null
            $vmName = $v.Name
            $vmName
            $vmmemoryprovisioned = Get-VM -Name $vmName | select -ExpandProperty MemoryGB
            $vmmemoryreserved = Get-VM -Name $vmName | Get-VMResourceConfiguration | Select -ExpandProperty MemReservationGB
            $vmcpu = Get-VM -Name $vmName | select -ExpandProperty NumCpu
            $vmcpuhotaddenabled = Get-VM -Name $vmName | Get-View  | select -ExpandProperty Config | select -ExpandProperty CpuHotAddEnabled
            $vmcpuaffinity = Get-VM -Name $vmName | Get-View  | select -ExpandProperty Config | select -ExpandProperty CpuAffinity
            if($vmcpuaffinity.Length -eq 0){$vmcpuaffinity="Not Set"}
            $vmscsicontrollers = $null
            $vmscsilist = Get-VM -Name $vmName | Get-ScsiController | select -ExpandProperty Name
            foreach($vmscsi in $vmscsilist)
            {
                $vmscsicontrollers += $vmscsi + ";"
                #$vmscsicontrollers += ";"
            }
            $vmHostName = Get-VM -Name $vmName | select -ExpandProperty VMHost | Select -ExpandProperty Name
            $htenabled = Get-VMHost -Name $vmHostName | select -ExpandProperty HyperthreadingActive
            $hostpowerpolicy = Get-VMHost -Name $vmHostName | Select @{N='Current_Policy';E={$_.ExtensionData.Hardware.CpuPowerManagementInfo.CurrentPolicy}}
            $hostpowerplan = $hostpowerpolicy | select -ExpandProperty 'Current_Policy'
            #$vmHostName
            $clusterName = Get-VMHost -Name $vmHostName | select -ExpandProperty Parent | Select -ExpandProperty Name
            $clusterevcmode = Get-Cluster -Name $clusterName | select -ExpandProperty EVCMode
            $numanodestmp = Get-VMHost -Name $vmHostName | Get-View | % { $_ | Select  @{L="NumaNodes";E={$_.Hardware.NumaInfo.NumNodes}}}
            $vmhostnumanodes = $numanodestmp | select -ExpandProperty NumaNodes
            $processorCStates = Get-VMHost -Name $vmHostName| Get-View |select -ExpandProperty Hardware | select -ExpandProperty CpuPowerManagementInfo | select -ExpandProperty HardwareSupport
            #$clusterName
            $drsrulevmsAA = $null
            $drsruletypeAA = $null
            $drsrulename = $null
            $drsrulehostsHA = $null
            $drsruletypeHA = $null
            
            try
            {
                $vmdrsrulesAA = Get-DrsRule -Cluster $clusterName -VM $vmName | Where-Object {$_.Enabled -eq "True"} | select VMIds, Type, Name
            }
            catch
            {
                $_.Exception.Message
            }
            if($vmdrsrulesAA)
            {
                $drsrulevmsAA = $null
                $drsruletypeAA = $null
                $drsrulename = $null
                #echo "drsruletype : $drsruletype"
                foreach($v in $vmdrsrulesAA)
                {
                    $vmIDsAA = $v.VMIds
                    $drsruletypeAA = $v.Type
                    $drsrulename = $v.Name
                        foreach($vid in $vmIDsAA)
                        {
                            $drsvmnameAA =  Get-VM -ID $vid | select -ExpandProperty Name
                            $drsrulevmsAA = $drsrulevmsAA + ";" + $drsvmnameAA
                        }
                }
            }
            else
            {
                $vmdrsrulesAA = "None"
            }
            

            try
            {
                $vmdrsrulesHA = Get-DrsRule -Cluster $clusterName -VM $vmName -Type VMHostAffinity | Where-Object {$_.Enabled -eq "True"} | select AffineHostIds, Type, Name
            }
            catch
            {
                $_.Exception.Message
            }
            if($vmdrsrulesHA)
            {
                $drsrulehostsHA = $null
                $drsruletypeHA = $null
                $drsrulename = $null
                #echo "drsruletype : $drsruletype"
                foreach($v in $vmdrsrulesHA)
                {
                    $vmhostIDsHA = $v.AffineHostIds
                    $drsruletypeHA = $v.Type
                    $drsrulename = $v.Name
                        foreach($vid in $vmhostIDsHA)
                        {
                            $drshostnameHA =  Get-VMHost -ID $vid | select -ExpandProperty Name
                            $drsrulehostsHA = $drsrulehostsHA + ";" + $drshostnameHA
                        }
                }
            }
            else
            {
                $vmdrsrulesHA = "None"
            }

            $global:rowtemp += New-Object -TypeName psobject -Property @{VM_Name="$vmName";VM_HostName="$vmHostName";NumaEnabled_NumaNodes="$vmhostnumanodes";ProcessorCStates="$processorCStates";VM_Memory_GB_Provisioned="$vmmemoryprovisioned";VM_Memory_GB_Reserved="$vmmemoryreserved";VM_CPU="$vmcpu";HyperThreadingEnabled="$htenabled";ClusterName="$clusterName";EVCMode="$clusterevcmode";HostPowerPlan="$hostpowerplan";VM_CPUHotAddEnabled="$vmcpuhotaddenabled";VM_CPUAffinity="$vmcpuaffinity";VM_SCSI_Controllers="$vmscsicontrollers";DRSRuleName="$drsrulename";DRSRuleTypeAntiAffinity="$drsruletypeAA";DRSRuleAntiAffinityVMs="$drsrulevmsAA";DRSRuleTypeHostAffinity="$drsruletypeHA";DRSRulePinnedHosts="$drsrulehostsHA"}
                                    
                                    #$global:rowtemp
                                   #$global:rowtemp += New-Object -TypeName psobject -Property @{Affiliate="";Is_Physical="$is_physical";Is_Non_Prod="$is_non_prod"; WindowsServerName ="$windowsservername";  Windows_FQDN="$windows_fqdn";  SQL_Instance_Name="$result";OperatingSystemVersion= "$osversion"}
                                   #$tempresult   


        }
        $global:resultfiledata += $rowtemp
        #echo "No variable passed"
    }
    else
    {
        $global:resultfile = "$resultfilepath\$ServerName-VMBuildStandardsChecklist_$date.csv"
        $a = Connect-VIServer pagr2vc001.prodroot.local
        #$a = Connect-VIServer paflovc001.prodroot.local
        $list_of_vms = Get-VM -Name "*$ServerName*" | Where-Object {$_.PowerState -eq "PoweredOn"}
        #$list_of_vms = Get-VM -Name PWGR2PRROOT*** | Where-Object {$_.PowerState -eq "PoweredOn"}
        #$list_of_vms = Get-VM | Where-Object {$_.PowerState -eq "PoweredOn"}
        

        foreach ($v in $list_of_vms)
        {
            #$drsrulevms = @()
            $vmdrsrulesAA = $null
            $vmdrsrulesHA = $null
            $vmName = $v.Name
            $vmName
            $vmmemoryprovisioned = Get-VM -Name $vmName | select -ExpandProperty MemoryGB
            $vmmemoryreserved = Get-VM -Name $vmName | Get-VMResourceConfiguration | Select -ExpandProperty MemReservationGB
            $vmcpu = Get-VM -Name $vmName | select -ExpandProperty NumCpu
            $vmcpuhotaddenabled = Get-VM -Name $vmName | Get-View  | select -ExpandProperty Config | select -ExpandProperty CpuHotAddEnabled
            $vmcpuaffinity = Get-VM -Name $vmName | Get-View  | select -ExpandProperty Config | select -ExpandProperty CpuAffinity
            if($vmcpuaffinity.Length -eq 0){$vmcpuaffinity="Not Set"}
            $vmscsicontrollers = $null
            $vmscsilist = Get-VM -Name $vmName | Get-ScsiController | select -ExpandProperty Name
            foreach($vmscsi in $vmscsilist)
            {
                $vmscsicontrollers += $vmscsi + ";"
                #$vmscsicontrollers += ";"
            }
            $vmHostName = Get-VM -Name $vmName | select -ExpandProperty VMHost | Select -ExpandProperty Name
            $htenabled = Get-VMHost -Name $vmHostName | select -ExpandProperty HyperthreadingActive
            $hostpowerpolicy = Get-VMHost -Name $vmHostName | Select @{N='Current_Policy';E={$_.ExtensionData.Hardware.CpuPowerManagementInfo.CurrentPolicy}}
            $hostpowerplan = $hostpowerpolicy | select -ExpandProperty 'Current_Policy'
            #$vmHostName
            $clusterName = Get-VMHost -Name $vmHostName | select -ExpandProperty Parent | Select -ExpandProperty Name
             $clusterevcmode = Get-Cluster -Name $clusterName | select -ExpandProperty EVCMode
             $numanodestmp = Get-VMHost -Name $vmHostName | Get-View | % { $_ | Select  @{L="NumaNodes";E={$_.Hardware.NumaInfo.NumNodes}}}
            $vmhostnumanodes = $numanodestmp | select -ExpandProperty NumaNodes
            #$clusterName
            $drsrulevmsAA = $null
            $drsruletypeAA = $null
            $drsrulename = $null
            $drsrulehostsHA = $null
            $drsruletypeHA = $null
            
            try
            {
                $vmdrsrulesAA = Get-DrsRule -Cluster $clusterName -VM $vmName | Where-Object {$_.Enabled -eq "True"} | select VMIds, Type, Name
            }
            catch
            {
                $_.Exception.Message
            }
            if($vmdrsrulesAA)
            {
                $drsrulevmsAA = $null
                $drsruletypeAA = $null
                $drsrulename = $null
                #echo "drsruletype : $drsruletype"
                foreach($v in $vmdrsrulesAA)
                {
                    $vmIDsAA = $v.VMIds
                    $drsruletypeAA = $v.Type
                    $drsrulename = $v.Name
                        foreach($vid in $vmIDsAA)
                        {
                            $drsvmnameAA =  Get-VM -ID $vid | select -ExpandProperty Name
                            $drsrulevmsAA = $drsrulevmsAA + ";" + $drsvmnameAA
                        }
                }
            }
            else
            {
                $vmdrsrulesAA = "None"
            }
            

            try
            {
                $vmdrsrulesHA = Get-DrsRule -Cluster $clusterName -VM $vmName -Type VMHostAffinity | Where-Object {$_.Enabled -eq "True"} | select AffineHostIds, Type, Name
            }
            catch
            {
                $_.Exception.Message
            }
            if($vmdrsrulesHA)
            {
                $drsrulehostsHA = $null
                $drsruletypeHA = $null
                $drsrulename = $null
                #echo "drsruletype : $drsruletype"
                foreach($v in $vmdrsrulesHA)
                {
                    $vmhostIDsHA = $v.AffineHostIds
                    $drsruletypeHA = $v.Type
                    $drsrulename = $v.Name
                        foreach($vid in $vmhostIDsHA)
                        {
                            $drshostnameHA =  Get-VMHost -ID $vid | select -ExpandProperty Name
                            $drsrulehostsHA = $drsrulehostsHA + ";" + $drshostnameHA
                        }
                }
            }
            else
            {
                $vmdrsrulesHA = "None"
            }

            $global:rowtemp += New-Object -TypeName psobject -Property @{VM_Name="$vmName";VM_HostName="$vmHostName";NumaEnabled_NumaNodes="$vmhostnumanodes";ProcessorCStates="$processorCStates";VM_Memory_GB_Provisioned="$vmmemoryprovisioned";VM_Memory_GB_Reserved="$vmmemoryreserved";VM_CPU="$vmcpu";HyperThreadingEnabled="$htenabled";ClusterName="$clusterName";EVCMode="$clusterevcmode";HostPowerPlan="$hostpowerplan";VM_CPUHotAddEnabled="$vmcpuhotaddenabled";VM_CPUAffinity="$vmcpuaffinity";VM_SCSI_Controllers="$vmscsicontrollers";DRSRuleName="$drsrulename";DRSRuleTypeAntiAffinity="$drsruletypeAA";DRSRuleAntiAffinityVMs="$drsrulevmsAA";DRSRuleTypeHostAffinity="$drsruletypeHA";DRSRulePinnedHosts="$drsrulehostsHA"}
                                    
                                    #$global:rowtemp
                                   #$global:rowtemp += New-Object -TypeName psobject -Property @{Affiliate="";Is_Physical="$is_physical";Is_Non_Prod="$is_non_prod"; WindowsServerName ="$windowsservername";  Windows_FQDN="$windows_fqdn";  SQL_Instance_Name="$result";OperatingSystemVersion= "$osversion"}
                                   #$tempresult   


        }
        $global:resultfiledata += $rowtemp
        #echo "No variable passed"
    
    }
    
  
          
    
       
}
##Function Ends here###

    try
    {
        Import-Module VMware.VimAutomation.Core -ErrorAction Stop
        $xyz = Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
    }

    catch
    {
        $error1 = $_.Exception.Message
        echo "`n`nError : $error1"
        return;
    }
##Main##
if ($ServerName -eq "" )
{
    echo "`n`t`t`t`t`t`t`t`t`t`t Usage :: ./TrueUPDataPull.ps1 ""Drive:\Folder\FileName_containing_list_of_servers_separated_by_newline"""
    echo "`n`t`t`t`t`t`t`t`t`t`t No argument provided. Proceeding with the VM/ESXi checks on all SQL Servers in the current environment."
    
    Perform-Validation
    $resultfiledata |Select-Object VM_Name,VM_HostName,ClusterName,EVCMode,NumaEnabled_NumaNodes,ProcessorCStates,VM_Memory_GB_Provisioned,VM_Memory_GB_Reserved,VM_CPU,HyperThreadingEnabled,HostPowerPlan,VM_CPUHotAddEnabled,VM_CPUAffinity,VM_SCSI_Controllers,DRSRuleName,DRSRuleTypeAntiAffinity,DRSRuleAntiAffinityVMs,DRSRuleTypeHostAffinity,DRSRulePinnedHosts| Export-CSV $resultfile -notypeinformation
}
elseif(Test-Path $ServerName)
{
    
    foreach($ServerName in Get-content $ServerName)
    {
            $global:SName = $ServerName.split("\\")[0]
            
            try {$a = Invoke-Command -computername $SName -scriptblock {$env:computername} -ErrorAction SilentlyContinue
                    if (!$?)
                    {
                            if($SName.Trim() -eq $env:computername)
                            {
                                echo "`nPlease run PowerShell ""as an administrator"" to pull the data."
                                exit
                            }
                        throw $error[0].Exception
                    }
                    $global:errorFlag1 = 0
                 }
            catch { 
                    echo "`n$ServerName not reachable. Copy the script to the target server in order to pull the data.`n"
                    echo $_.Exception.Message
		            #$env:username
                    #echo $_.Exception.ItemName
                    $filepath = Split-Path -Parent $PSCommandPath 
                    $filedate = (Get-Date -Format "yyyy-MM-dd")
                    $ServerName >> "$filepath\Unable_to_reach_servers_list.$filedate.txt"
                    $global:errorFlag1 = 1
                   }  
                
                $global:skipFlag = 0
       
                if($errorFlag1 -eq 0)
                {echo "Proceeding with Checks on $SName"
                
                Perform-Validation $SName
                }
                #$rowtemp |Select-Object "Affiliate", "Is_Physical", "Is_Non_Prod", "WindowsServerName", "Windows_FQDN","SQL_Instance_Name","OperatingSystemVersion"| Export-CSV $resultfile -notypeinformation
                
                
    }
    $resultfiledata |Select-Object VM_Name,VM_HostName,ClusterName,EVCMode,NumaEnabled_NumaNodes,ProcessorCStates,VM_Memory_GB_Provisioned,VM_Memory_GB_Reserved,VM_CPU,HyperThreadingEnabled,HostPowerPlan,VM_CPUHotAddEnabled,VM_CPUAffinity,VM_SCSI_Controllers,DRSRuleName,DRSRuleTypeAntiAffinity,DRSRuleAntiAffinityVMs,DRSRuleTypeHostAffinity,DRSRulePinnedHosts| Export-CSV $resultfile -notypeinformation
}
else
{
    $global:SName = $ServerName
    
    try {$a = Invoke-Command -computername $SName -scriptblock {$env:computername} -ErrorAction SilentlyContinue
            if (!$?)
            {
                    if($SName.Trim() -eq $env:computername)
                    {
                        echo "`nPlease run PowerShell ""as an administrator"" to perform the validation."
                        exit
                    }
                throw $error[0].Exception
            }
         }
    catch { 
            echo "`n$ServerName not reachable. Copy the script to the target server in order to pull the data.`n"
            echo $_.Exception.Message
		    #$env:username
            #echo $_.Exception.ItemName
            exit
           }  
        $UName = ([Environment]::UserDomainName + "\" + [Environment]::UserName)
        $DateCheckedOn = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        $global:skipFlag = 0
       
        echo "Proceeding with Checks on $SName"
        Perform-Validation $SName
        #$rowtemp |Select-Object "Affiliate", "Is_Physical", "Is_Non_Prod", "WindowsServerName", "Windows_FQDN","SQL_Instance_Name","OperatingSystemVersion"| Export-CSV $resultfile -notypeinformation
        $resultfiledata |Select-Object VM_Name,VM_HostName,ClusterName,EVCMode,NumaEnabled_NumaNodes,ProcessorCStates,VM_Memory_GB_Provisioned,VM_Memory_GB_Reserved,VM_CPU,HyperThreadingEnabled,HostPowerPlan,VM_CPUHotAddEnabled,VM_CPUAffinity,VM_SCSI_Controllers,DRSRuleName,DRSRuleTypeAntiAffinity,DRSRuleAntiAffinityVMs,DRSRuleTypeHostAffinity,DRSRulePinnedHosts| Export-CSV $resultfile -notypeinformation
}
