param([string]$ServerName)

function Perform-Validation 
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$ServerName  
    )
    $resultfilepath = Split-Path -Parent $PSCommandPath 
    $date = (Get-Date -Format "MM_dd_yyyy") 
    $resultfile = "$resultfilepath\Output\ServerChecklist_$ServerName-$date.csv"
    $resultfiledata = @()
    # 1024*1024*1024 = 1073741824 
    
    $global:cmdcollection = @()
    #$global:cmdcollection += New-Object -TypeName psobject -Property @{id=1; isSQL=0; Control='Drive Details';  Command='Get-WmiObject -Class Win32_logicaldisk -Filter "DriveType=3" | Select-Object -Property DeviceID, VolumeName,FileSystem,FreeSpace,Size'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=1; isSQL=0; Control='Drive Details';  Command='Get-WmiObject -Class Win32_Volume -Filter "DriveType=3" | Where-Object {$_.Label -ne "System Reserved"}|Sort-Object -Property DriveLetter | Select-Object -Property Name, DriveLetter, Label,FileSystem,FreeSpace,Capacity,BlockSize'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=2; isSQL=0; Control='PageFile Configuration';  Command='get-wmiobject Win32_pagefileusage | select name ,AllocatedBaseSize'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=3; isSQL=0; Control='Windows Activation';  Command='Get-WmiObject SoftwareLicensingProduct | where {$_.PartialProductKey} | select -ExpandProperty licensestatus'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=4; isSQL=0; Control='Available RAM in GB'; Command='get-wmiobject Win32_ComputerSystem | % {[math]::Round($_.TotalPhysicalMemory/1073741824,2)}'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=5; isSQL=0; Control='Available CPU'; Command='get-wmiobject Win32_ComputerSystem | % {$_.NumberOfLogicalProcessors}'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=6; isSQL=0; Control='Power Plan'; Command='gwmi -NS root\cimv2\power -Class win32_PowerPlan| Where-Object { $_.IsActive -eq "True" } |select -ExpandProperty ElementName'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=7; isSQL=0; Control='SQL Server Network Protocol - TCP/IP'; Command='& Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$Using:iName\MSSQLServer\SuperSocketNetLib\tcp" | select -ExpandProperty Enabled'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=8; isSQL=0; Control='SQL Server Network Protocol - Named Pipes'; Command='& Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$Using:iName\MSSQLServer\SuperSocketNetLib\Np" | select -ExpandProperty Enabled'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=9; isSQL=0; Control='SQL Server Network Protocol - Shared Memory'; Command='& Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$Using:iName\MSSQLServer\SuperSocketNetLib\Sm" | select -ExpandProperty Enabled'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=10; isSQL=0; Control='SQL Server Network Protocol - TCP/IP Port Number'; Command='& Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$Using:iName\MSSQLServer\SuperSocketNetLib\tcp\IPALL" | select -ExpandProperty TcpPort'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=11; isSQL=0; Control='TCP/IP Port Number - STATIC'; Command='echo $using:staticFlag'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=12; isSQL=1; Control='SQL Version'; Command="SELECT SERVERPROPERTY('productversion') as queryoutput"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=13; isSQL=1; Control='SQL server Service Account'; Command="select service_account as queryoutput FROM sys.dm_server_services where servicename like 'SQL Server (%'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=14; isSQL=1; Control='SQL server Agent Service Account'; Command="select service_account as queryoutput FROM sys.dm_server_services where servicename like 'SQL Server Agent (%'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=15; isSQL=1; Control='Instant File Initialization Enabled'; Command="select case When instant_file_initialization_enabled = 'Y' THEN 'Yes' ELSE 'No' END as queryoutput FROM sys.dm_server_services where servicename like 'SQL Server (%'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=16; isSQL=1; Control='All Database data Files in K drive'; Command="select CASE WHEN count(*) > 0 THEN 'No' ELSE 'Yes' END as queryoutput from sys.sysaltfiles where dbid not in (32767,2) and filename not like 'K:%.mdf' and name not like '%log%'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=17; isSQL=1; Control='All Database T-log Files in L drive'; Command="select CASE WHEN count(*) > 0 THEN 'No' ELSE 'Yes'  END as queryoutput  from sys.sysaltfiles where dbid not in (32767,2) and filename not like 'L:%.ldf' and filename not like '%.mdf'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=18; isSQL=1; Control='All Tempdb Files in P drive'; Command="select CASE WHEN count(*) > 0 THEN 'No' ELSE 'Yes'  END as queryoutput from sys.sysaltfiles where dbid=2 and filename not like 'P:%'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=19; isSQL=1; Control='Max Memory Setting'; Command="SELECT CASE WHEN value_in_use=maximum THEN 'No' ELSE 'Yes. ' + cast(cast(value_in_use as int)/1024 as varchar) + ' GB' END as queryoutput FROM sys.configurations WHERE name = 'Max Server Memory (MB)'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=20; isSQL=1; Control='OLE Automation Procedures - (Expected Result : Enabled)'; Command="SELECT value_in_use as queryoutput FROM sys.configurations WHERE name = 'Ole Automation Procedures'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=21; isSQL=1; Control='DAC(Remote Admin Connections) - (Expected Result : Disabled)'; Command="SELECT value_in_use as queryoutput FROM sys.configurations WHERE name = 'remote admin connections'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=22; isSQL=1; Control='Ad Hoc Distributed Queries - (Expected Result : Disabled)'; Command="SELECT value_in_use as queryoutput FROM sys.configurations WHERE name = 'Ad Hoc Distributed Queries'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=23; isSQL=1; Control='CLR - (Expected Result : Disabled)'; Command="SELECT value_in_use as queryoutput FROM sys.configurations WHERE name = 'clr enabled'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=24; isSQL=1; Control='Cross DB Ownership Chaining - (Expected Result : Disabled)'; Command="SELECT value_in_use as queryoutput FROM sys.configurations WHERE name = 'cross db ownership chaining'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=25; isSQL=1; Control='Remote Access - (Expected Result : Disabled)'; Command="SELECT value_in_use as queryoutput FROM sys.configurations WHERE name = 'remote access'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=26; isSQL=1; Control='Database Mail XPs - (Expected Result : Enabled)'; Command="SELECT value_in_use as queryoutput FROM sys.configurations WHERE name = 'Database Mail XPs'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=27; isSQL=1; Control='Scan for startup Procs - (Expected Result : Disabled)'; Command="SELECT value_in_use as queryoutput FROM sys.configurations WHERE name = 'scan for startup procs'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=28; isSQL=1; Control='xp_cmdshell - (Expected Result : Disabled)'; Command="SELECT value_in_use as queryoutput FROM sys.configurations WHERE name = 'xp_cmdshell'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=29; isSQL=0; Control='Hide Instance - (Expected Result : Enabled)'; Command='& Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$Using:iName\MSSQLServer\SuperSocketNetLib" | select -ExpandProperty HideInstance'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=30; isSQL=0; Control='Number of Error Logs - (Expected Result : 12)'; Command='& Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$Using:iName\MSSQLServer" | select -ExpandProperty NumErrorLogs'}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=31; isSQL=1; Control='SA login renamed to WP_sa'; Command="SELECT CASE WHEN name='WP_sa' THEN 'Yes' ELSE 'No' END as queryoutput from sys.server_principals where principal_id=1"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=32; isSQL=1; Control='SA login disabled'; Command="SELECT CASE WHEN is_disabled=1 THEN 'Yes' ELSE 'No' END as queryoutput from sys.server_principals where principal_id=1"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=33; isSQL=1; Control='DBA_Admin Database Exists'; Command="SELECT CASE WHEN name like '%DBA_Admin%' THEN 'Yes' ELSE 'No' END as queryoutput from sys.sysdatabases where name like '%DBA_Admin%'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=34; isSQL=1; Control='MaxDop Settings(8 or less cores, MaxDOP = half the number of cores. More than 8 cores, MaxDOP = 8)'; Command="SELECT value_in_use as queryoutput FROM sys.configurations WHERE name = 'max degree of parallelism'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=35; isSQL=1; Control='Cost Threshold For Parallelism - (Expected Result : 50)'; Command="SELECT value_in_use as queryoutput FROM sys.configurations WHERE name = 'cost threshold for parallelism'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=36; isSQL=1; Control='TempDB Files - (8 cores or less, no. of tempdb files = no. of cores. More than 8 cores, no. of tempdb files = 8)'; Command="select count(*) as queryoutput from sys.sysaltfiles where db_name(dbid) = 'TempDB' and groupid = 1"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=37; isSQL=1; Control='SQL Agent Operator - (Expected Result: Enabled)'; Command="select ENABLED as queryoutput from msdb..sysoperators"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=38; isSQL=1; Control='SQLServer Maintenance Jobs Deployed (Script checks for keywords ''Index'' & ''Integrity'' in job-step commands)'; Command="select CASE WHEN count(*) > 0 THEN 'Yes' ELSE 'No' END  as queryoutput from msdb.dbo.sysjobsteps where command like '%Index%' or command like '%Integrity%'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=39; isSQL=1; Control='Database Backups Scheduled'; Command="select CASE WHEN count(*) > 0 THEN 'Yes' ELSE 'No' END  as queryoutput  from msdb.dbo.sysjobsteps where command like '%backup%database%'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=40; isSQL=1; Control='Audit Action Groups Created'; Command="SELECT CASE WHEN count(*) > 0 THEN 'Yes' ELSE 'No' END  as queryoutput   FROM sys.server_audit_specification_details AS SAD JOIN sys.server_audit_specifications AS SA ON SAD.server_specification_id = SA.server_specification_id JOIN sys.server_audits AS S ON SA.audit_guid = S.audit_guid WHERE SAD.audit_action_id IN ('CNAU', 'LGFL', 'LGSD')"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=41; isSQL=1; Control='Guest User Status (Expected Result: Disabled)'; Command="CREATE TABLE #tuser (DBName sysname NULL ,hasdbaccess sysname NULL);INSERT #tuser EXEC sp_MSforeachdb ' SELECT ''[?]'' AS DBName, hasdbaccess FROM ?.sys.sysusers where name= ''guest''  ;';select case hasdbaccess when '1' then DbName + 'Enabled' else DbName + ':Disabled' end as queryoutput  from #tuser where #tuser.DBName not in ('[master]','[msdb]','[tempdb]') and hasdbaccess=1;DROP TABLE #tuser"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=42; isSQL=1; Control='TRUSTWORTHY Option (Expected Result: Disabled)'; Command="select case WHEN is_trustworthy_on = 1 THEN name + ':Enabled' ELSE name + ':DISABLED' END as queryoutput from sys.databases where is_trustworthy_on =1 and name not in ('msdb')"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=43; isSQL=1; Control='Windows built-in account/group Exist;'; Command="select case WHEN count(*) >0 THEN 'Yes' ELSE 'No' END as queryoutput from sys.server_principals where name like 'BUILTIN\%'"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=44; isSQL=1; Control='CHECK_EXPIRATION Option set for SQL Logins with sysadmin role (Expected Result : Yes)'; Command="select case WHEN a.is_expiration_checked = 1 THEN 'Yes' ELSE a.name + ':No' END as queryoutput from sys.sql_logins a,sys.server_role_members b where a.principal_id=b.member_principal_id  and a.is_disabled = 0  and a.is_expiration_checked = 0 and b.role_principal_id = SUSER_ID('Sysadmin')"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=45; isSQL=1; Control='CHECK POLICY Option set for SQL Logins (Expected Result : Yes)'; Command="select case WHEN is_policy_checked = 1 THEN 'Yes' ELSE name + ':No' END as queryoutput from sys.sql_logins where is_disabled = 0  and is_policy_checked = 0 "}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=46; isSQL=1; Control='Server Configured in Monitoring Tool'; Command="Check"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=47; isSQL=0; Control='Server Added to appropriate patching Group'; Command="Check"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=48; isSQL=0; Control='Receive Side Scaling (Expected Result : Enabled)'; Command="Get-NetAdapterRss -InterfaceDescription vmxnet3* | select -ExpandProperty Enabled"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=49; isSQL=0; Control='VM Standards: Enhanced vMotion Compatibility (EVC Mode) - (Expected Result : Disabled)'; Command="Check"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=50; isSQL=0; Control='VM Standards: BIOS/UEFI Settings - Turbo Boost (Expected Result : Enabled)'; Command="Check"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=51; isSQL=0; Control='VM Standards: BIOS/UEFI Settings - Hyper Threading (Expected Result : Enabled)'; Command="Check"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=52; isSQL=0; Control='VM Standards: BIOS/UEFI Settings - NUMA (Expected Result : Enabled)'; Command="Check"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=53; isSQL=0; Control='VM Standards: BIOS/UEFI Settings - CPU Advanced Features (VT-x,EPT,RVI) (Expected Result : Enabled)'; Command="Check"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=54; isSQL=0; Control='VM Standards: BIOS/UEFI Settings - Select appropriate Snoop Mode (not a configurable setting on Dell PowerEdge servers)'; Command="Check"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=55; isSQL=0; Control='VM Standards: BIOS/UEFI Settings - Select Power Management to "OS Controlled"'; Command="Check"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=56; isSQL=0; Control='VM Standards: BIOS/UEFI Settings - Processor C-states (including the C1E Halt State) (Expected Result : Disabled)'; Command="Check"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=57; isSQL=0; Control='VM Standards: BIOS/UEFI Settings - QPI Power Management (Expected Result : Disabled)'; Command="Check"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=58; isSQL=0; Control='VM Standards: vCPU Configuration - CPU Hot Plug (Expected Result : Disabled)'; Command="Check"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=59; isSQL=0; Control='VM Standards: vCPU Configuration - CPU Affinity - Do NOT Use'; Command="Check"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=60; isSQL=0; Control='VM Standards: Memory Configuration - Reserve 100% Memory provisioned to VM'; Command="Check"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=61; isSQL=0; Control='VM Standards: Memory Configuration - If Memory Provisioned to VM >= 50% of ESXi Host Memory (aka Unbalanced vNUMA) Add VM Advanced setting (numa.vcpu.maxPerMachineNode = (Number of vCPU assigned to VM) / 2)'; Command="Check"}
    $global:cmdcollection += New-Object -TypeName psobject -Property @{id=62; isSQL=0; Control='VM Standards: Memory Configuration - If Memory Provisioned to VM >= 50% of ESXi Host Memory (aka Unbalanced vNUMA) Configure CoresPerSocket (coresPerSocket = numa.vcpu.maxPerMachineNode)'; Command="Check"}

    #Add above line with appropriate control and its command to fetch the result
    #$cmdcollection

    if(!$InsNames)
                {
                    $InsNames = Invoke-Command -ComputerName $ServerName -ScriptBlock { Get-Item -path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' | Select-Object -ExpandProperty Property } -ErrorAction SilentlyContinue
                }

     if(!$InsNames){ $global:skipFlag = 1}
        
    $rowtemp = @()
    foreach($c in $cmdcollection)
        {
            $ControlName = $c.Control
            $cmd = $c.Command
            
            $CisSQL = $c.isSQL
            $CiD = $c.id
            try
            {
                
                if($CiD -le 6)
                    {
                        $cmdName = [scriptblock]::Create($cmd)
                        $result = invoke-command -computername $ServerName -ScriptBlock $cmdName -ErrorAction SilentlyContinue
                        if (!$?)
                        { 
                        $result = "Manual Check"
                        }
                        else
                        {
                            if($ControlName -like '*Drive*')
                            {
                                #$temp1 = get-disk -CimSession $ServerName|Where-Object {$_.Number -ne $null} | %{ $PartitionStyle1 = $_.PartitionStyle; Get-Partition $_.Disknumber | ?{$_.driveletter} | select driveletter,@{N="PartitionStyle";E={$PartitionStyle1}} } -ErrorAction SilentlyContinue
                                $temp1 = get-disk -CimSession $ServerName|Where-Object {$_.Number -ne $null}|%{ $PartitionStyle1 = $_.PartitionStyle;$DiskLocation = $_.Location; Get-Partition -CimSession $ServerName $_.number | ?{$_.driveletter} | select driveletter,@{N="DiskLocation";E={$DiskLocation}},@{N="PartitionStyle";E={$PartitionStyle1}} } -ErrorAction SilentlyContinue
                                foreach ($dr in $result)
                                {
                                    $DriveLetter = $dr.DriveLetter
                                    if ($DriveLetter -eq '' -or $DriveLetter -eq $null)
                                    { $DriveLetter = $dr.Name
                                    }
                                    else {
                                    $DriveLetter = $dr.DriveLetter
                                    }
                                    $DriveFreeSpace = [math]::round($dr.FreeSpace/1Gb,2)
                                    $DriveAllocatedSize = [math]::round($dr.Capacity/1Gb,2)
                                    $DriveVolumeName = $dr.Label
                                    $DriveFileSystem = $dr.FileSystem
                                    $DriveAllocUnitsize = [math]::round($dr.BlockSize/1kb,2)
                                    $DriveLettermatch = $DriveLetter.ToString()
                                    $DriveLettermatch = $DriveLettermatch.split(":")[0]
                                    
                                    $PartitionStyle = $temp1 | Where-Object {$_.driveletter -like "$DriveLettermatch*"} | select -ExpandProperty PartitionStyle
                                    $DiskLocation = $temp1 | Where-Object {$_.driveletter -like "$DriveLettermatch*"} | select -ExpandProperty DiskLocation
                                    
                                    $rowtemp += New-Object -TypeName psobject -Property @{ServerName="$ServerName";Control="$ControlName"; Result =""; DriveLetter="$DriveLetter";  VolumeName="$DriveVolumeName"; DriveFileSystem ="$DriveFileSystem" ;PartitionStyle = "$PartitionStyle";DiskLocation ="$DiskLocation"; DriveAllocationUnitSize = "$DriveAllocUnitsize"; FreeSpaceinGB="$DriveFreeSpace";  AllocatedSpaceinGB="$DriveAllocatedSize";  UserName="$UName";  DateCheckedOn="$DateCheckedOn"}
                                    $result = ""
                                 }
                            }
                            elseif($ControlName -like '*PageFile*')
                            {
                        
                                foreach ($pg in $result)
                                {
                                    $pgAllocatedSize = [math]::round($pg.AllocatedBaseSize/1024,2)
                                    $pgfilename = $pg.Name
                        
                                    $rowtemp += New-Object -TypeName psobject -Property @{ServerName="$ServerName";Control="$ControlName"; Result =""; DriveLetter="$pgfilename";  VolumeName="";DriveFileSystem= "";PartitionStyle ="";DiskLocation=""; DriveAllocationUnitSize = ""; FreeSpaceinGB="";  AllocatedSpaceinGB="$pgAllocatedSize";  UserName="$UName";  DateCheckedOn="$DateCheckedOn"}
                                    $result = ""
                                 }
                            }
                            else
                            {
                                $rowtemp += New-Object -TypeName psobject -Property @{ServerName="$ServerName";Control="$ControlName"; Result ="$Result";  DriveLetter="";  VolumeName="";DriveFileSystem= "";PartitionStyle ="";DiskLocation=""; DriveAllocationUnitSize = ""; FreeSpaceinGB="";  AllocatedSpaceinGB="";  UserName="$UName";  DateCheckedOn="$DateCheckedOn"}
                                $result = ""
                            }

                         }
                    }
                else
                {
                    
                }
            }
            catch
            {
                echo $error[0].Exception
            }
        
        }
            
                    if($skipFlag -eq 0)
                    {
                        foreach($iName in $InsNames)
                        {
                            $instanceskipflag = 0
                            if($iName -eq "MSSQLSERVER") {$servicestatus = get-service -ComputerName $ServerName | Where-Object {$_.Name -like "*$iName*" -and $_.Status -eq "Running"} |select Name,Status}
                            else{$servicestatus = get-service -ComputerName $ServerName | Where-Object {$_.Name -like "MSSQL$*$iName*" -and $_.Status -eq "Running"} |select Name,Status}
                            if(!$servicestatus){$instanceskipflag = 1}
                            if($instanceskipflag -ne 1)
                            {
                            foreach($c in $cmdcollection)
                            {    
                                $ControlName = $c.Control
                                
                                $cmd = $c.Command
                                $cmdName = [scriptblock]::Create($cmd)
                                $CisSQL = $c.isSQL
                                $CiD = $c.id
                               if($CiD -gt 6)
                               { 
                                
                                if($iName -notlike '%#SSEE%')
                                {
                                    $c1 = Get-WmiObject -Class Win32_SystemServices -ComputerName $ServerName
                                    if ($c1 | select PartComponent | where {$_ -like "*ClusSvc*"})
                                    { 
                                    if($iName -eq "MSSQLSERVER")
                                    {$SQLServerName = $SName }
                                    else
                                    {$SQLServerName = $SName + "\" + $iName}
                                      
                                                                    
                                    }
                                    else
                                    {
                                    

                                    if($iName -eq "MSSQLSERVER")
                                    {$SQLServerName = $SName }
                                    else
                                    {$SQLServerName = $SName + "\" + $iName}

                                    }
                                
                                try
                                {
                                if($CisSQL -eq 0){$result = invoke-command -computername $ServerName -ScriptBlock $cmdName -ErrorAction SilentlyContinue}
                                else {$result = Invoke-Sqlcmd -Query $cmdName -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue | Select -ExpandProperty queryoutput}
                                
                                }
                                catch
                                {
                                echo $error[0].Exception
                                }
                                    if (!$?)
                                    { 
                                        $result = "Manual Check"
                                        if($CiD -eq 30){$result = 6}
                                        
                                        $rowtemp += New-Object -TypeName psobject -Property @{ServerName="$SQLServerName";Control="$ControlName"; Result ="$Result";  DriveLetter="";  VolumeName="";DriveFileSystem= "";PartitionStyle ="";DiskLocation="";DriveAllocationUnitSize = "";  FreeSpaceinGB="";  AllocatedSpaceinGB="";  UserName="$UName";  DateCheckedOn="$DateCheckedOn"}
                                        $result = ""
                                    }
                                    else
                                    {
                                        
                                        if($CiD -eq 10)
                                        { 
                                            if($result)
                                            { 
                                                $global:tcpstaticport = $result
                                                $global:SQLServerInstance = $SQLServerName + "," + $tcpstaticport
                                                $global:staticFlag = 1
                                            } 
                                            else 
                                            { 
                                                $result = invoke-command -computername $ServerName -ScriptBlock {& Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$Using:iName\MSSQLServer\SuperSocketNetLib\tcp\IPALL" | select -ExpandProperty TcpDynamicPorts} -ErrorAction SilentlyContinue
                                                $global:tcpdynamicport = $result
                                                $global:SQLServerInstance = $SQLServerName + "," + $tcpdynamicport
                                                $global:staticFlag = 0
                                             }
                                
                                        }
                                        if($CiD -eq 48)
                                        { 
                                            if($result.length -eq 0){$result = "Physical Server"}
                                            else{
                                                if($result -like "False"){ $result = "Disabled"} else { $result = "Enabled"}
                                            }
                                        }

                                        if($CiD -eq 41 -or $CiD -eq 42 -or $CiD -eq 44 -or $CiD -eq 45)
                                        {
                                            if($result)
                                            {
                                                foreach($result in $result)
                                                {
                                                    $rowtemp += New-Object -TypeName psobject -Property @{ServerName="$SQLServerName";Control="$ControlName"; Result ="$Result";  DriveLetter="";  VolumeName="";DriveFileSystem= "";PartitionStyle ="";DiskLocation="";DriveAllocationUnitSize = "";  FreeSpaceinGB="";  AllocatedSpaceinGB="";  UserName="$UName";  DateCheckedOn="$DateCheckedOn"}
                                                    $result = ""
                                                }
                                            }
                                            else
                                            {
                                                if($CiD -eq 44 -or $CiD -eq 45)
                                                {$result = "Yes"}
                                                else
                                                {$result = "Disabled"}
                                                
                                                $rowtemp += New-Object -TypeName psobject -Property @{ServerName="$SQLServerName";Control="$ControlName"; Result ="$Result";  DriveLetter="";  VolumeName="";DriveFileSystem= "";PartitionStyle ="";DiskLocation="";DriveAllocationUnitSize = "";  FreeSpaceinGB="";  AllocatedSpaceinGB="";  UserName="$UName";  DateCheckedOn="$DateCheckedOn"}
                                                $result = ""
                                            }
                                            

                                        }
                                        else
                                        {
                                        $rowtemp += New-Object -TypeName psobject -Property @{ServerName="$SQLServerName";Control="$ControlName"; Result ="$Result";  DriveLetter="";  VolumeName="";DriveFileSystem= "";PartitionStyle ="";DiskLocation="";DriveAllocationUnitSize = "";  FreeSpaceinGB="";  AllocatedSpaceinGB="";  UserName="$UName";  DateCheckedOn="$DateCheckedOn"}
                                        $result = ""
                                        }
                                    }
                                    }
                                }
                            }
                            }
                        }

                    }
        
        $rowtemp |Select-Object "ServerName", "Control", "Result", "DriveLetter", "VolumeName","DriveFileSystem","PartitionStyle","DiskLocation","DriveAllocationUnitSize", "FreeSpaceinGB", "AllocatedSpaceinGB", "UserName", "DateCheckedOn"| Export-CSV $resultfile -notypeinformation
        #$resultfiledata | Export-CSV $resultfile -notypeinformation
    
       
}
##Function Ends here###


##Main##
if ($ServerName -eq "" )
{
    echo "`nArgument missing. Usage :: ./SQLBuildStandardsChecklist.ps1 SERVERNAME"
    echo "                  Usage :: ./SQLBuildStandardsChecklist.ps1 SQLSERVERNAME"
    echo "                  Usage :: ./SQLBuildStandardsChecklist.ps1 SQLSERVERNAME,PORT"
    echo "                  Usage :: ./SQLBuildStandardsChecklist.ps1 ""Drive:\Folder\FileName_containing_list_of_servers_separated_by_newline"""
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
                                echo "`nPlease run PowerShell ""as an administrator"" to perform the validation."
                                exit
                            }
                        throw $error[0].Exception
                    }
                    $global:errorFlag1 = 0
                 }
            catch { 
                    echo "`n$ServerName not reachable. Copy the script to the target server in order to perform the validation.`n"
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
    }
}
else
{
    $global:SName = $ServerName.split("\\")[0]
    $global:InsNames = $ServerName.split("\\")[1]
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
            echo "`n$ServerName not reachable. Copy the script to the target server in order to perform the validation.`n"
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
   
}
