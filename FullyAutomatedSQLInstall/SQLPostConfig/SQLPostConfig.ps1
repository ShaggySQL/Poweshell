param([string]$Server, [string]$InsNames)
     #$Server ="PWGR2RSQLDB1C-2.PROD.PB01.LOCAL"

                Import-Module SQLServer -ErrorAction SilentlyContinue
                if ($?)
                {}
                else
                {
                    echo "`nInstalling the PowerShell 'SQLServer' module.`r`n"
                    
                    $temp = Install-PackageProvider NuGet -Force -ErrorAction SilentlyContinue
                    $a1 = Copy-Item "\\PWGR2PSQLATMN01.prod.pb01.local\Software\PowerShell\nuget" -Destination "C:\Program Files\PackageManagement\ProviderAssemblies\nuget" -Recurse
                    $a1 = Copy-Item "\\PWGR2PSQLATMN01.prod.pb01.local\Software\PowerShell\SqlServer" -Destination "C:\Program Files\WindowsPowerShell\Modules\SqlServer" -Recurse
                    Import-Module SQLServer -ErrorAction SilentlyContinue
                    if ($?) {}
                    else
                    {
                        Import-Module SQLPS -ErrorAction SilentlyContinue
                        if ($?) {}
                        else
                        {echo "`nUnable to Install the PowerShell 'SQLServer' module. The post Configuration steps will not be performed.`r`n"
                        
                        }
                    }                       
                }

             
             try
             {
                if($InsNames.Length -eq 0)
                {$InsNames = Invoke-Command -ComputerName $Server -ScriptBlock { Get-Item -path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' | Select-Object -ExpandProperty Property }}
     
  
                $portnumbersdiscovery = $null
                $portnumbersdiscovery = @()
                $FixedPort = $null
                $FixedPort = 62754
                $tport = $null
                $dport = $null
                $InsNamesdiscovery = $null
                $InsNamesdiscovery = Invoke-Command -ComputerName $Server -ScriptBlock { Get-Item -path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' | Select-Object -ExpandProperty Property }
                
                foreach($ins in $InsNamesdiscovery)
                {
                    if($ins -ne "MICROSOFT##SSEE")
                    {
                        $sblock = [scriptblock]::Create("Get-ItemProperty -path ""HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$ins\MSSQLServer\SuperSocketNetLib\tcp\IPAll"" | select -ExpandProperty TcpPort ")
                        $tport = invoke-command -computername $Server -ScriptBlock $sblock
                        $sblock = [scriptblock]::Create("Get-ItemProperty -path ""HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$ins\MSSQLServer\SuperSocketNetLib\tcp\IPAll"" | select -ExpandProperty TcpDynamicPorts")
                        $dport = invoke-command -computername $Server -ScriptBlock $sblock 
                    
                        if($tport.Length -gt 0){ $portnumbersdiscovery += $tport}else{$portnumbersdiscovery += $dport}
                    
                    }
                }
                $pFlag = $null
                $pres = $null
                for($pFlag = 1;$pFlag -le $portnumbersdiscovery.Count;$pFlag++)
                {
                $pres=$portnumbersdiscovery | Where-Object {$_ -contains $FixedPort}
                if($pres.Count -eq 0){ $pnum = $FixedPort; $breakFlag = 1;} else {$FixedPort = $FixedPort + 1}
                if($breakFlag -eq 1){$pFlag = $portnumbersdiscovery.Count + 1}
                }
                if($pnum.Count -eq 0){$pnum =$FixedPort + 1}
     
                
    

                            foreach($ins in $InsNames)
                            {
                 
                                        if($ins -ne "MICROSOFT##SSEE")
                                        {
                                        $sblock = [scriptblock]::Create("Get-ItemProperty -path ""HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$ins\MSSQLServer\SuperSocketNetLib\tcp\IPAll"" | select -ExpandProperty TcpPort ")
                                        $tcpport = invoke-command -computername $Server -ScriptBlock $sblock 
                                        $sblock = [scriptblock]::Create("Get-ItemProperty -path ""HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$ins\MSSQLServer\SuperSocketNetLib\tcp\IPAll"" | select -ExpandProperty TcpDynamicPorts")
                                        $tcpdynamicport = invoke-command -computername $Server -ScriptBlock $sblock 
                                        $tcpport = $tcpport.Trim();
                                        $tcpdynamicport = $tcpdynamicport.Trim();
                                        #echo "tcpport : $tcpport"
                                        #echo "tcpdynamicport : $tcpdynamicport"

                                        $c1 = Get-WmiObject -Class Win32_SystemServices -ComputerName $server
                                            if ($c1 | select PartComponent | where {$_ -like "*ClusSvc*"})
                                            { 
                                                $sblock = [scriptblock]::Create("Get-ItemProperty -path ""HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$ins\Cluster"" | select -ExpandProperty ClusterName")
                                                $clusterstate = invoke-command -computername $Server -ScriptBlock $sblock
                                                if($ins -eq "MSSQLSERVER"){$ins1 = $null}else{$ins1 = "\" + $ins}
                                                if($clusterstate.Count -eq 0) { $clusterstate = $Server}
                                                $InstanceName = $clusterstate + $ins1 
                                                $InstanceName = $InstanceName.Trim();
                                                
                                            }
                                            else
                                            {
                                                if($ins -eq "MSSQLSERVER")
                                                {
                                                $InstanceName = $Server  
                                                $InstanceName = $InstanceName.Trim();
                                                }
                                                else
                                                {
                                                $InstanceName = $Server + "\" + $ins 
                                                $InstanceName = $InstanceName.Trim();
                                                }
                                            }
                    
                                  
                                if($ins -ne "MSSQLSERVER") { $ins2 = "MSSQL$" + $ins; $agt1 = "SQLAgent$" + $ins; $browserFlag = 1} else { $ins2 = "MSSQLSERVER"; $agt1 = "SQLSERVERAGENT" ; $browserFlag = 0}
                                
                        
                        
                        
                                $iName = $InstanceName + "," + $pnum
                                
                                $response1 = "Yes"
                                #$response1 = Read-Host -Prompt "`nPlease type 'YES' to proceed on performing Post Install Configuration on $InstanceName"
                                if ($response1.ToUpper() -eq "YES")
                                {
                                    $sblock = [scriptblock]::Create("Set-ItemProperty -path ""HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$ins\MSSQLServer\SuperSocketNetLib\tcp\IPAll"" -Name TcpPort -Value ""$pnum"" ")
                                    invoke-command -computername $Server -ScriptBlock $sblock
                                    $sblock = [scriptblock]::Create("Set-ItemProperty -path ""HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$ins\MSSQLServer\SuperSocketNetLib\tcp\IPAll"" -Name TcpDynamicPorts -Value """" ")
                                    invoke-command -computername $Server -ScriptBlock $sblock
                        
                                    if($vFlag -eq 2016)
                                    {
                                    $wmi = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $Server
                                    $wmiinstance = $wmi.ServerInstances | Where-Object { $_.Name -eq $ins }
                                    $tcp = $wmiinstance.ServerProtocols | Where-Object { $_.DisplayName -eq 'TCP/IP' }
                                
                                            echo "`nEnabling TCP/IP Protocol"
                                            
                                            $Tcp.IsEnabled = $true 
                                            $Tcp.Alter() 
                                    }
                                
                                            echo "`r`nTCP/IP Protocol Enabled and port set to $pnum. Restarting the SQL service."
                                            
                                            Get-Service -Name $ins2 -ComputerName $Server | Restart-Service -Force
                               
                                
                                        echo "`r`nSetting the agent service to Automatic and restarting the agent service."
                                        
                                        Set-Service -Name $agt1 -ComputerName $Server -StartupType Automatic
                                        Get-Service -Name $agt1 -ComputerName $Server | Restart-Service -Force
                                        if ( $browserFlag -eq 1 )
                                        {
                                            echo "`r`nSetting the Browser service to Automatic and restarting the browser service as its a named instance."
                                            
                                            Set-Service -Name SQLBrowser -ComputerName $Server -StartupType Automatic
                                            Get-Service -Name SQLBrowser -ComputerName $Server | Restart-Service -Force
                                        }
                                        else
                                        {
                                            echo "`r`nSetting the Browser service to Disabled and stopping the browser service, if running, as its a default instance."
                                            
                                            Set-Service -Name SQLBrowser -ComputerName $Server -StartupType Disabled
                                            Get-Service -Name SQLBrowser -ComputerName $Server | Stop-Service -Force
                                        }

                                
                                        # $s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $iName
                                        #$sourcelogpath = $s.Databases["Master"].LogFiles.FileName.TrimEnd("\mastlog.ldf")
                                        #$targetlogpath = $s | Select -ExpandProperty DefaultLog
                                        #$targetlogpath = $targetlogpath.TrimEnd("\")
                                        #$sourcedatapath = $s.Databases["Master"].Filegroups.Files.FileName.TrimEnd("\master.mdf")
                                        #$targetdatapath = $s | Select -ExpandProperty DefaultFile
                                        #$targetdatapath = $targetdatapath.TrimEnd("\")
                                        #$masterTlog = $s.Databases["Master"].LogFiles.FileName
                                        #$masterData = $s.Databases["Master"].Filegroups.Files.FileName
                                        #if ($sourcelogpath -ne $targetlogpath -or $sourcedatapath -ne $targetdatapath)
                                        #{
                                        #echo "`r`nMoving the Database Files and Transaction Log files for Master, Model and MSDB databases to the default user db directories : `r`n$targetdatapath`r`n$targetlogpath "
                                        
                                        #$masterData = $masterData.Replace("$sourcedatapath","$targetdatapath")
                                        #$masterTlog = $masterTlog.Replace("$sourcelogpath","$targetlogpath")
                                        #$('model','MSDB')|
                                        #ForEach-Object {$Db = $s.databases[$PSItem]
                                        #        foreach ($fl in $Db.Filegroups.Files) {$fl.FileName = $fl.FileName.Replace("$sourcedatapath","$targetdatapath")}
                                        #        $s.databases[$PSItem].Alter()
                                        #                }
                                        #$('model','MSDB')|
                                        #ForEach-Object {$Db = $s.databases[$PSItem]
                                        #        foreach ($fl in $Db.LogFiles) {$fl.FileName = $fl.FileName.Replace("$sourcelogpath","$targetlogpath")}
                                        #        $s.databases[$PSItem].Alter()
                                        #                }



                                        #$sblock = [scriptblock]::Create("Set-ItemProperty -path ""HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$ins\MSSQLServer\Parameters"" -Name SQLArg0 -Value (""-d" + $masterData + """)")
                                        #invoke-command -computername $Server -ScriptBlock $sblock
                                        #$sblock = [scriptblock]::Create("Set-ItemProperty -path ""HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$ins\MSSQLServer\Parameters"" -Name SQLArg2 -Value (""-l" + $masterTlog + """)")
                                        #invoke-command -computername $Server -ScriptBlock $sblock
                                        echo "`r`nStopping and starting SQL services."
                                        Get-Service -Name $ins2 -ComputerName $Server | Stop-Service -Force
                                        
                                        #$sblock = [scriptblock]::Create("Move-Item -Path ""$sourcelogpath" + "\*.ldf"" -Destination ""$targetlogpath" + "\""")
                                        #$xyz1 = invoke-command -computername $Server -ScriptBlock $sblock
                                        #$sblock = [scriptblock]::Create("Move-Item -Path ""$sourcedatapath" + "\*.mdf"" -Destination ""$targetdatapath" + "\""")
                                        #$xyz1 = invoke-command -computername $Server -ScriptBlock $sblock
                                        <#
                                        $sblock = [scriptblock]::Create("Move-Item -Path $("'" + ""$sourcelogpath"" + ""\"" + $PSItem+'*.ldf' + "'") -Destination (""$targetlogpath" + "\"")")
                                        $('model','MSDB','mast')|ForEach-Object {invoke-command -computername $Server -ScriptBlock $sblock}
                                        $sblock = [scriptblock]::Create("Move-Item -Path $("'" + ""$sourcedatapath"" + ""\"" + $PSItem+'*.mdf' + "'") -Destination (""$targetdatapath" + "\"")")
                                        $('model','MSDB','mast')|ForEach-Object {invoke-command -computername $Server -ScriptBlock $sblock}
                                        #>
                                        
                                        Get-Service -Name $ins2 -ComputerName $Server | Start-Service
                                        Get-Service -Name $agt1 -ComputerName $Server | Start-Service
                                
                                        #}

                                
                                        $RAM = invoke-command -computername $Server -ScriptBlock {get-wmiobject Win32_ComputerSystem | % {$_.TotalPhysicalMemory}}
                                        $RAM  = [math]::round($RAM/1Gb)
                                        if($RAM -le 4) { $min_os_memory = 1 }
                                        elseif($RAM -gt 4 -and $RAM -le 8) { $min_os_memory = 2 }
                                        elseif($RAM -gt 8 -and $RAM -le 32) { $min_os_memory = 4 }
                                        else{ $min_os_memory = [math]::round($RAM*.1) }
                                        $no_of_instances = (Get-Service -Name *MSSQL* -ComputerName $Server).Count
                                        $max_SQL_memory_in_MB = (($RAM - $min_os_memory)/$no_of_instances)*1024
                                        $max_SQL_memory_in_GB = $max_SQL_memory_in_MB/1024
                                        $s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $iName
                                        echo "`r`nSetting Max memory settings."
                                        
                                        echo "Available RAM : $RAM GB. Reserved for OS : $min_os_memory GB. Number of Instances : $no_of_instances. Allocated to SQL : $max_SQL_memory_in_GB GB "
                                        
                                        $s.Configuration.MaxServerMemory.ConfigValue = $max_SQL_memory_in_MB
                                        $s.Configuration.Alter()
                                        $num_of_cpu = invoke-command -computername $Server -ScriptBlock {Get-CimInstance -ClassName 'Win32_Processor' | Measure-Object -Property 'NumberOfCores' -Sum | select -ExpandProperty Sum;}
                                        if ($num_of_cpu -le 8) { $maxdopvalue = $num_of_cpu/2}else{$maxdopvalue = 8}
                                        echo "`r`nConfiguring the MaxDop Setting to : $maxdopvalue as the number of CPU's is : $num_of_cpu"
                                        
                                        $s.Configuration.MaxDegreeOfParallelism.ConfigValue = $maxdopvalue
                                        $s.Configuration.Alter()
                                        echo "`r`nConfiguring the Cost Threshold For Parallelism to 50"
                                        
                                        $s.Configuration.CostThresholdForParallelism.ConfigValue = 50
                                        $s.Configuration.Alter()
                                                    
                                        echo "`r`nConfiguring the Initial Size to 256MB and Growth to 128MB for Model database DATA File."
                                        
                                        if($s.Databases['Model'].FileGroups.Files.Size -lt 262144)
                                        {
                                        $s.Databases['Model'].FileGroups.Files.Size = 262144
                                        $s.Databases['Model'].Alter()
                                        }
                                        if($s.Databases['Model'].FileGroups.Files.Growth -lt 131072)
                                        {$s.Databases['Model'].FileGroups.Files.Growth = 131072
                                        $s.Databases['Model'].Alter()
                                        }

                                        echo "`r`nConfiguring the Initial Size to 256MB and Growth to 128MB for Model database LOG File."
                                        
                                        foreach ($l in $s.Databases['Model'].LogFiles)
                                        {
                                            if($l.Size -lt 262144)
                                            {$l.Size = 262144
                                            $s.Databases['Model'].Alter()}
                                            if($l.Growth -lt 131072)
                                            {$l.Growth = 131072
                                            $s.Databases['Model'].Alter()}
                                        }
                                
                                        echo "`r`nMaking sure 'Ole Automation Procedures' is Enabled."
                                        
                                        $s.Configuration.OleAutomationProceduresEnabled.ConfigValue = 1
                                        $s.Configuration.Alter()
                                        echo "`r`nMaking sure 'Ole Automation Procedures' is Enabled."
                                        
                                        $s.Configuration.OleAutomationProceduresEnabled.ConfigValue = 1
                                        $s.Configuration.Alter()
                                        echo "`r`nMaking sure 'DAC(remote admin connections)' is Disabled."
                                        
                                        $s.Configuration.RemoteDacConnectionsEnabled.ConfigValue = 0
                                        $s.Configuration.Alter()
                                        echo "`r`nMaking sure 'AdHoc Distributed Queries' is Disabled."
                                        
                                        $s.Configuration.AdHocDistributedQueriesEnabled.ConfigValue = 0
                                        $s.Configuration.Alter()
                                        echo "`r`nMaking sure 'IsSqlClrEnabled' is Disabled."
                                        
                                        $s.Configuration.IsSqlClrEnabled.ConfigValue = 0
                                        $s.Configuration.Alter()
                                        echo "`r`nMaking sure 'CrossDBOwnershipChaining' is Disabled."
                                        
                                        $s.Configuration.CrossDBOwnershipChaining.ConfigValue = 0
                                        $s.Configuration.Alter()
                                        echo "`r`nMaking sure 'Remote Access' is Disabled."
                                        
                                        $s.Configuration.RemoteAccess.ConfigValue = 0
                                        $s.Configuration.Alter()
                                        echo "`r`nMaking sure 'ScanForStartupProcedures' is Disabled."
                                        
                                        $s.Configuration.ScanForStartupProcedures.ConfigValue = 0
                                        $s.Configuration.Alter()
                                        echo "`r`nMaking sure 'XPCmdShell' is Disabled."
                                        
                                        $s.Configuration.XPCmdShellEnabled.ConfigValue = 0
                                        $s.Configuration.Alter()
                                        echo "`r`nRenaming 'sa' account to 'WP_sa' and disabling it."
                                        
                                        $sacheck = ($s.Logins | Where-Object { $_.Name -eq "sa"}).Count
                                        if($sacheck -gt 0) {($s.Logins | Where-Object { $_.Name -eq "sa"}).rename('WP_sa') } 
                                        $s.Logins.Alter()
                                        $s.Logins["WP_sa"].Disable()
                                        $s.Logins.Alter()
                                        echo "`r`nEnabling 'HideInstance' Property"
                                        
                                        $sblock = [scriptblock]::Create("Set-ItemProperty -path ""HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$ins\MSSQLServer\SuperSocketNetLib"" -Name HideInstance -Value 1")
                                        invoke-command -computername $Server -ScriptBlock $sblock
                                        echo "`r`nSetting number of Error logs to 12."
                                        
                                        #Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$Using:iName\MSSQLServer" | select NumErrorLogs
                                        $sblock = [scriptblock]::Create("(Get-ItemProperty -path ""HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$ins\MSSQLServer"" | select -ExpandProperty NumErrorLogs -ErrorAction silentlycontinue )")
                                        $a = invoke-command -computername $Server -ScriptBlock $sblock
                                        if($a -gt 0)
                                        {
                                            $sblock = [scriptblock]::Create("Set-ItemProperty -path ""HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$ins\MSSQLServer"" -Name NumErrorLogs -Value 12")
                                            $b = invoke-command -computername $Server -ScriptBlock $sblock
                                        }
                                        else
                                        {
                                            $sblock = [scriptblock]::Create("New-ItemProperty -path ""HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$ins\MSSQLServer"" -Name NumErrorLogs -Value 12")
                                            $b = invoke-command -computername $Server -ScriptBlock $sblock
                                        }
                                        $dbExists = $FALSE
                                        foreach ($db in $s.databases) {
                                            if ($db.name -eq "DBA_Admin") {
                                            $dbExists = $TRUE
                                            }
                                        }

                                        if ($dbExists -eq $FALSE) {
                                        echo "`r`nCreating 'DBA_Admin' database."
                                        
                                        $db = New-Object Microsoft.SqlServer.Management.Smo.Database -argumentlist $s, "DBA_Admin"
                                        $db.Create();
                                        }
                                        else
                                        {
                                            echo "`r`nDatabase 'DBA_Admin' already exists."
                                            
                                        }
                                        echo "`r`nSetting up Database Mail"
                                        
                                        $s.Configuration.DatabaseMailEnabled.ConfigValue = 1
                                        $s.Configuration.Alter()

                                        $mail = $s.Mail
                                        $acctcheck = $mail.Accounts | select -ExpandProperty Name
                                        if ($acctcheck -ne "SQL Server DBAs")
                                        {
                                        $acct = new-object ('Microsoft.SqlServer.Management.Smo.Mail.MailAccount') ($mail, 'SQL Server DBAs')
                                        $acct.DisplayName = "$InstanceName DB Mail"
                                        $acct.EmailAddress = 'DLITDataPlatformMSSQLDBAUSCore@worldpay.com'
                                        $acct.ReplyToAddress = 'DLITDataPlatformMSSQLDBAUSCore@worldpay.com'
                                        $acct.Create()
                                
                                        $mlsrv = $acct.MailServers
                                        $mls = $mlsrv.Item(0)
                                        $mls.Rename('mail-gateway.infoftps.com')
                                        $mls.EnableSsl = $FALSE
                                        $mls.UserName = ''
                                        $mls.Alter()
                                        $acct.Alter()
                                        }
                                        $profilecheck = $mail.Profiles | select -ExpandProperty Name
                                        if ($profilecheck -ne "SQL Server DBAs")
                                        {
                                        $mlp = new-object ('Microsoft.SqlServer.Management.Smo.Mail.MailProfile') ($mail, 'SQL Server DBAs', 'Database Administrator Mail Profile')
                                        $mlp.Create()
                                        $mlp.AddAccount('SQL Server DBAs', 1)
                                        $mlp.AddPrincipal('public', 1)
                                        $mlp.Alter()
                                        }

                                        echo "`r`nCreating operator in SQL Server Agent."
                                        
                                        $oper = "SQL Server DBAs"
                                        $op = $s.JobServer.Operators[$oper]
                                        if ($op.Count -gt 0) {
                                            echo "Operator already exists."
                                            
                                        }
                                        else
                                        {
                                        $op = New-Object ('Microsoft.SqlServer.Management.Smo.Agent.Operator') ($s.JobServer,$oper)
                                        $op.EmailAddress = "DLITDataPlatformMSSQLDBAUSCore@worldpay.com"
                                        $op.Create()
                                        }

                                        echo "`r`nEnabling DB Mail in SQL Server Agent Alert and restarting the Agent service."
                                        
                                        $s.JobServer.AgentMailType='DatabaseMail'
                                        $s.JobServer.DatabaseMailProfile='SQL Server DBAs'
                                        $s.JobServer.Alter()
                                
                                                    
                                        Get-Service -Name $agt1 -ComputerName $Server | Restart-Service -Force
                                        $agentstatusFlag = 1
                                        $agentstatus = Get-Service -Name $agt1 -ComputerName $Server | Select -ExpandProperty Status
                                        while($agentstatus -ne "Running"){Start-Sleep 1; $agentstatusFlag++;if($agentstatusFlag -eq 30) {$agentstatus = "Running"}}

                                        $auditcheck = ($s.Audits | Where-Object { $_.Name -like '*TrackLoginActivity*'}).Count
                                        $auditquery = @"
                                        CREATE SERVER AUDIT TrackLoginActivity 
                                            TO APPLICATION_LOG

                                        CREATE SERVER AUDIT SPECIFICATION TrackLoginActivity_spec
                                        FOR SERVER AUDIT TrackLoginActivity  
                                            ADD (FAILED_LOGIN_GROUP);
                                        GO  
                                        ALTER SERVER AUDIT SPECIFICATION TrackLoginActivity_spec
                                        FOR SERVER AUDIT TrackLoginActivity  
                                            ADD (SUCCESSFUL_LOGIN_GROUP);
                                        GO  
                                        ALTER SERVER AUDIT SPECIFICATION TrackLoginActivity_spec
                                        FOR SERVER AUDIT TrackLoginActivity  
                                            ADD (AUDIT_CHANGE_GROUP);
                                        GO  
                                        ALTER SERVER AUDIT TrackLoginActivity  
                                        WITH (STATE = ON);  
                                        GO  
                                        ALTER SERVER AUDIT SPECIFICATION TrackLoginActivity_spec
                                        WITH (STATE = ON);  
                                        GO
"@
                                        if($auditcheck -eq 0)
                                        {
                                            echo "`r`nCreating the Server Audit Specification : 'TrackLoginActivity'"
                                            
                                            $a = Invoke-SqlCmd -ServerInstance $iName -Query $auditquery
                                        }

                                        try
                                        {
                                        echo "`r`nSetting SQL Agent MaximumHistoryRows and MaximumJobHistoryRows'."
                                        
                                            $TargetMaximumHistoryRows = 50000;
                                            $TargetMaximumJobHistoryRows = 5000 ;
                                            $s.jobserver.MaximumHistoryRows = $TargetMaximumHistoryRows ;
                                            $s.jobserver.MaximumJobHistoryRows  = $TargetMaximumJobHistoryRows ;
                                            $s.jobserver.Alter();
                                        }
                                        catch
                                        {
                                        echo "`r`nUnable to set the SQL Agent MaximumHistoryRows and MaximumJobHistoryRows'."
                                        
                                        }


                                        <#echo "`r`nCreating the OLA Maintenance Jobs and configuring the default schedule."
                                        
                                       
                                        $jobscheck = ($s.JobServer.Jobs | Where-Object { $_.Name -like '*Admin-*'}).Count
                                        if($jobscheck -eq 0)
                                        {
                                            $a = Invoke-SqlCmd -ServerInstance $iName -Query $createMaintenanceJobs
                                        }
                                        #>

                                        try
                                        {
                                        echo "`r`nCreating OLA maintenance scripts, jobs, and adding sp_whoisactive to DBA_Admin'."

                                            $sqlfilelocation = 'D:\scripts\FullyAutomatedSQLInstall\SQL Scripts'
                                            $SQLFileList = get-childitem -Path $sqlfilelocation -File Step*.sql | select -ExpandProperty fullname | Sort-Object -Property fullname
                                            FOREACH ($file in $SQLFileList)
                                            {
                                                $a = Invoke-SqlCmd -ServerInstance $iName -inputfile $file
                                            }
                                        }
                                        Catch
                                        {
                                        echo "`r`nUnable to create OLA maintenance scripts, jobs, and adding sp_whoisactive to DBA_Admin'."

                                        }

                                        echo "`r`nRestarting the SQL service."
                                            
                                            Get-Service -Name $ins2 -ComputerName $Server | Restart-Service -Force

                                        $sqlstatusFlag = 1
                                        $sqlstatus = Get-Service -Name $ins2 -ComputerName $Server | Select -ExpandProperty Status
                                        while($sqlstatus -ne "Running"){Start-Sleep 1; $sqlstatusFlag++;if($sqlstatusFlag -eq 10) {$sqlstatus = "Running"}}

                                        try
                                        {
                                        echo "`r`nSetting the Power Plan on the server to 'High Performance'."
                                        
                                        $P = gwmi -NS root\cimv2\power -Class win32_PowerPlan -ComputerName $Server -Filter "ElementName = 'High performance'"
                                        $P = $P.activate()
                                        }
                                        catch
                                        {
                                        echo "`r`nUnable to set the Power Plan on the server to 'High Performance'."
                                        
                                        }
                                        
                                        


                                }

                            }
                            }

echo "`r`nSuccessfully configured"
                         
                         }
                         catch
                         {
                         echo "`r`n"
                         $_.Exception.Message
                         echo "`r`nConfiguration Failed"
                         }
                         