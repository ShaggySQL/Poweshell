param([string]$ServerName)
$global:rowtemp = @()
$global:resultfiledata = @()
function Perform-Validation 
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$ServerName  
    )
    $global:resultfilepath = Split-Path -Parent $PSCommandPath
    $date = (Get-Date -Format "MM_dd_yyyy") 
    $global:resultfile = "$resultfilepath\TrueUPDataPull_$date.csv"
   
    $global:tempresult = @()
    # 1024*1024*1024 = 1073741824 
    
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
    
    #Add above line with appropriate control and its command to fetch the result
    #$cmdcollection

    $global:sqlskipFlag = 0;
    $InsNames = Invoke-Command -ComputerName $ServerName -ScriptBlock { Get-Item -path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' | Select-Object -ExpandProperty Property } -ErrorAction SilentlyContinue
    if(!$InsNames){ $global:sqlskipFlag = 1; } #echo "Skipping the Server as No SQL Found on $ServerName"; return;}    
    
                
                        foreach($iName in $InsNames)
                        {
                            #echo "iname :$iName"
                            $instanceskipflag = 0
                            if($iName -eq "MSSQLSERVER") {$servicestatus = get-service -ComputerName $ServerName | Where-Object {$_.Name -like "*$iName*" -and $_.Status -eq "Running"} |select Name,Status}
                            else{$servicestatus = get-service -ComputerName $ServerName | Where-Object {$_.Name -like "MSSQL$*$iName*" -and $_.Status -eq "Running"} |select Name,Status}
                            if(!$servicestatus){$instanceskipflag = 1;echo "Skipping the instance : $iName as SQL Server is stopped on $ServerName"; return; }
                             $sblock = [scriptblock]::Create("& Get-ItemProperty -path ""HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$iName\MSSQLServer\SuperSocketNetLib\tcp\IPALL"" | select -ExpandProperty TcpPort")
                              $global:tcpstaticport = invoke-command -computername $ServerName -ScriptBlock $sblock -ErrorAction SilentlyContinue 
                                
                                    if($iName -notlike '%#SSEE%')
                                    {
                                        $c1 = Get-WmiObject -Class Win32_SystemServices -ComputerName $ServerName
                                        if ($c1 | select PartComponent | where {$_ -like "*ClusSvc*"})
                                        { 
                                            $clusterstate = invoke-command -computername $ServerName -ScriptBlock {Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$using:iName\Cluster" | select -ExpandProperty ClusterName} 
                                            if(!$clusterstate){$clusterstate = $ServerName}
                                            if($iName -eq "MSSQLSERVER"){$iName_part = $null}else{$iName_part = "\" + $iName}
                                            $SQLServerName = $clusterstate + $iName_part 
                                            $SQLServerName = $SQLServerName.Trim();
                                            $global:SQLServerInstance = $SQLServerName + "," + $tcpstaticport      
                                                                    
                                        }
                                        else
                                        {
                                    

                                            if($iName -eq "MSSQLSERVER")
                                            {$SQLServerName = $SName; $global:SQLServerInstance = $SQLServerName + "," + $tcpstaticport }
                                            else
                                            {$SQLServerName = $SName + "\" + $iName; $global:SQLServerInstance = $SQLServerName + "," + $tcpstaticport}

                                        }
                                    }


                            if($instanceskipflag -ne 1 )
                            {
                                foreach($c in $cmdcollection)
                                {    
                                    $ControlName = $c.Control
                                    $cmd = $c.Command
                                    
                                    $CisSQL = $c.isSQL
                                    $CiD = $c.id

                                    if($CisSQL -eq 0) {$cmdName = [scriptblock]::Create($cmd)} else {$cmdName = $cmd}
                               
                                   
                                        try
                                        {
                                             $result = $null
                                            
                                            if($CisSQL -eq 0){$result = invoke-command -computername $ServerName -ScriptBlock $cmdName -ErrorAction SilentlyContinue}
                                            else {if($sqlskipFlag -eq 1) {$result = "No SQL Found"} else {$result = Invoke-Sqlcmd -Query $cmdName -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue | Select -ExpandProperty queryoutput}}
                                                if (!$?)
                                                { 
                                                    $result = "Manual Check"
                                            
                                                }
                                            $global:tempresult += New-Object -TypeName psobject -Property @{Control="$ControlName";Result="$result";}
                                             #$result
                                        }
                                        catch
                                        {
                                            
                                            $result = "Manual Check."
                                            $global:tempresult += New-Object -TypeName psobject -Property @{Control="$ControlName";Result="$result";}
                                        }
                                        <#
                                        if (!$?)
                                        { 
                                           $result = "Manual Check"
                                            
                                        }
                                         #>
                                    
                                
                                    
                                   }
                                   $global:rowtemp = @()
                                   $global:rowtemp = New-Object -TypeName psobject
                                   $global:rowtemp | Add-Member -NotePropertyName Affiliate -NotePropertyValue $null -Force
                                    foreach($t in $tempresult)
                                    {
                                        $tc = $t.Control
                                        $tr = $t.result
                                        $global:rowtemp | Add-Member -NotePropertyName $tc -NotePropertyValue $tr -Force

                                    }
                                    $global:resultfiledata += $rowtemp
                                   # $global:rowtemp
                                   #$global:rowtemp += New-Object -TypeName psobject -Property @{Affiliate="";Is_Physical="$is_physical";Is_Non_Prod="$is_non_prod"; WindowsServerName ="$windowsservername";  Windows_FQDN="$windows_fqdn";  SQL_Instance_Name="$result";OperatingSystemVersion= "$osversion"}
                                   #$tempresult         

                            }

                        }
                    
                    if($sqlskipflag -eq 1 )
                            {
                                foreach($c in $cmdcollection)
                                {    
                                    $ControlName = $c.Control
                                    $cmd = $c.Command
                                    
                                    $CisSQL = $c.isSQL
                                    $CiD = $c.id

                                    if($CisSQL -eq 0) {$cmdName = [scriptblock]::Create($cmd)} else {$cmdName = $cmd}
                               
                                   
                                        try
                                        {
                                             $result = $null
                                            
                                            if($CisSQL -eq 0){$result = invoke-command -computername $ServerName -ScriptBlock $cmdName -ErrorAction SilentlyContinue}
                                            else {$result = "No SQL Found" }
                                                if (!$?)
                                                { 
                                                    $result = "Manual Check"
                                            
                                                }
                                            $global:tempresult += New-Object -TypeName psobject -Property @{Control="$ControlName";Result="$result";}
                                             #$result
                                        }
                                        catch
                                        {
                                            
                                            $result = "Manual Check."
                                            $global:tempresult += New-Object -TypeName psobject -Property @{Control="$ControlName";Result="$result";}
                                        }
                                        <#
                                        if (!$?)
                                        { 
                                           $result = "Manual Check"
                                            
                                        }
                                         #>
                                    
                                
                                    
                                   }
                                   $global:rowtemp = New-Object -TypeName psobject
                                   $global:rowtemp | Add-Member -NotePropertyName Affiliate -NotePropertyValue $null
                                    foreach($t in $tempresult)
                                    {
                                        $tc = $t.Control
                                        $tr = $t.result
                                        $global:rowtemp | Add-Member -NotePropertyName $tc -NotePropertyValue $tr

                                    }
                                    $global:resultfiledata += $rowtemp
                                    #$global:rowtemp
                                   #$global:rowtemp += New-Object -TypeName psobject -Property @{Affiliate="";Is_Physical="$is_physical";Is_Non_Prod="$is_non_prod"; WindowsServerName ="$windowsservername";  Windows_FQDN="$windows_fqdn";  SQL_Instance_Name="$result";OperatingSystemVersion= "$osversion"}
                                   #$tempresult         

                            }
        
        #$resultfiledata | Export-CSV $resultfile -notypeinformation
    
       
}
##Function Ends here###


##Main##
if ($ServerName -eq "" )
{
    echo "`nArgument missing. Usage :: ./TrueUPDataPull.ps1 SERVERNAME"
    echo "                  Usage :: ./TrueUPDataPull.ps1 ""Drive:\Folder\FileName_containing_list_of_servers_separated_by_newline"""
    exit;
}
elseif(Test-Path $ServerName)
{
    $UName = ([Environment]::UserDomainName + "\" + [Environment]::UserName)
    $DateCheckedOn = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    foreach($ServerName in Get-content $ServerName)
    {
            $global:SName = $ServerName.split("\\")[0]
            $global:InsNames = $ServerName.split("\\")[1]
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
    $resultfiledata |Select-Object *| Export-CSV $resultfile -notypeinformation
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
        $resultfiledata |Select-Object *| Export-CSV $resultfile -notypeinformation
}
