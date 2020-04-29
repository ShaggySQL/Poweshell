
#(Get-Credential).Password | ConvertFrom-SecureString -key $key| Set-Content "D:\scripts\RestoreValidation\LiteSpeedBackupPassword.txt"
$UserName = "dummy"
[Byte[]] $key = (1..16)
#$File = "D:\scripts\RestoreValidation\LiteSpeedBackupPassword.txt"
$password = Get-Content "D:\scripts\RestoreValidation\LiteSpeedBackupPassword.txt" | ConvertTo-securestring -key $key
$MyCredential = New-Object System.Management.Automation.PsCredential($UserName,$password)
$backuppassword = $MyCredential.GetNetworkCredential().password  

$app = "RestoreValidation"
$Removedays = (Get-Date).AddDays(-30)
Get-ChildItem c:\temp -file | ? {$_.Name -like '*pserror*' -and $_.LastWriteTime -lt $Removedays} |  Remove-Item 
function Handle-LynkError
{
[CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        $Error 
    )
    process {
        $ErrObject = New-Object psobject -Property @{
        Date = Get-Date
        ComputerName = $env:COMPUTERNAME;
        UserName = $env:USERNAME;
        DatabaseName = $dbname;
        ServerName = $Server;
        Error = $Error;
        }
        $Filename = "C:\temp\psError$App" +  @(get-date -Format yyyy_MM_dd) + ".txt"
        $ErrObject | fl -force | Out-File -FilePath $Filename -Append -Width 500
    }    
}
$CentralServer = 'PWFLOPDBAS001'
$conn = New-Object System.Data.SqlClient.SqlConnection
$cmd = New-Object System.Data.SqlClient.SqlCommand
$cmd.CommandTimeout = 0
$adapter = New-Object System.Data.SqlClient.SqlDataAdapter
$dsServers = New-Object System.Data.DataSet
Import-Module SQLServer -DisableNameChecking
$logdate = Get-Date -Format g
$ddpath = "\\dsflokydlddom01\SQL"



try
{
       $conn.ConnectionString = "Data Source=$CentralServer;Initial Catalog=INFODB;Integrated Security=SSPI;"
       $conn.open()
       $cmd.connection = $conn
       #$cmd.CommandText = "select s.ServerName,s.ServerID from [RestoreValidation].[SQLServers] s where s.ServerName = 'PWFLOPSQL026C-1,63984'"
       $cmd.CommandText = "select s.ServerName,s.ServerID from [RestoreValidation].[SQLServers] s order by s.ServerID desc"
       $adapter.SelectCommand = $cmd
       $adapter.Fill($dsServers) | Out-Null
       $conn.close()
       
        if ($dsServers.Tables[0].rows.Count -gt 0)
        {
            foreach ($dr in $dsServers.tables[0].Rows)
            { 
                    $Server = $dr["ServerName"];
                    $ServerID = $dr["ServerID"];
                    $Server = $Server.Trim();
                    $s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $Server
                    $conn.close()
                    $conn.ConnectionString = "Data Source=$Server;Integrated Security=SSPI;"
                    try
                    {
                    $conn.open()
                    }
                    catch{}
                    $cmd.connection = $conn
                    $cmd.CommandText = "
                              select a.database_name,a.type,b.physical_device_name from msdb.dbo.backupset a with (nolock)
	                            INNER JOIN msdb.dbo.backupmediafamily b with (nolock)
		                            ON a.media_set_id = b.media_set_id
			                            WHERE a.backup_start_date in (select max(backup_start_date) from msdb.dbo.backupset with (nolock) where type ='D' group by database_name)
			                            AND a.database_name NOT IN ('master','model','msdb','ReportServer','ReportServerTempDB','DBA_Admin','LiteSpeedLocal')
			                            AND databasepropertyex (a.database_name, 'Status') = 'ONLINE'
										AND a.type = 'D' order by a.database_name
                           "

                    $adapter.SelectCommand = $cmd
                    $dsdatabases = New-Object System.Data.DataSet
                    try
                    {
                        $adapter.Fill($dsdatabases) | Out-Null
                    }
                    catch
                    {

                    }
                    if ($dsdatabases.Tables[0].rows.Count -gt 0)
                    {
                        foreach ($db in $dsdatabases.tables[0].Rows)
                        { 
                            
                            $dbname = $db["database_name"];
                            $type = $db["type"];
                            $filename = $db["physical_device_name"];
                            $dbname = $dbname.Trim();
                            $type = $type.Trim();
                            $filename = $filename.Trim();
                            $dbsize = $s.Databases["$dbname"] | select -ExpandProperty Size
                            $dbsize = [int]$dbsize/1024
                            $dbsize = [math]::Round($dbsize,2)
                            $conn.close()
                            $conn.ConnectionString = "Data Source=$Server;Integrated Security=SSPI;"
                            $conn.open()
                            $cmd.connection = $conn
                            $cmd.CommandText = "exec master.dbo.xp_restore_filelistonly @filename = '$filename'"
                            $adapter.SelectCommand = $cmd
                            $dsbakdetails = New-Object System.Data.DataSet
                            $adapter.Fill($dsbakdetails) | Out-Null
                            $restorecmdfname = @()
                            foreach ($dsb in $dsbakdetails.tables[0].Rows)
                            { 
                                $logicalname = $dsb["LogicalName"];
                                if($logicalname.ToLower() -like "*log*")
                                {
                                    $restorecmdfname += "@with = N'MOVE N''$logicalname'' TO N''K:\MSSQLSERVER\Data01\$logicalname.ldf''',"
                                }
                                else
                                {
                                    $restorecmdfname += "@with = N'MOVE N''$logicalname'' TO N''K:\MSSQLSERVER\Data01\$logicalname.mdf''',"
                                }
                                
                            }
                            $conn.close()
                            $conn.ConnectionString = "Data Source=$CentralServer;Initial Catalog=INFODB;Integrated Security=SSPI;"
                            $conn.open()
                            $cmd.connection = $conn
                            $cmd.CommandText = "
                                                exec master.dbo.xp_restore_database @database = N'$dbname' ,
                                                @filename = N'$filename',
                                                @filenumber = 1, 
                                                @encryptionkey = N'$backuppassword',
                                               "
                            
                            $cmd.CommandText = $cmd.CommandText + $restorecmdfname
                            $cmd.CommandText = $cmd.CommandText + "
                                                                    @maxtransfersize = 4194304,
                                                                    @buffercount = 126
                                                                    "
                            
                            $restorestartdate = Get-Date -Format g
                            try{$cmd.executenonquery()| Out-Null
                                $restoreresult ="Restore SUCCESSFUL"
                            }
                            catch {
                                
                                #$_ | Handle-LynkError 
                                #$_.Exception.Message
                                
                                $restoreresult ="Restore FAILED.`n" + $_.Exception.Message
                                $restoreresult = $restoreresult.Replace("'","""")
                            }
                            $restoreenddate = Get-Date -Format g
                            $conn.close()
                            $conn.open()
                            $cmd.CommandText = "SELECT count(*) as count FROM [$dbname].INFORMATION_SCHEMA.TABLES"
                            try
                            {
                                $dbcheck = $cmd.executereader()
                                $isaccesible = "Yes"
                            }
                            catch
                            {
                                $isaccesible = "No"
                            }
                           
                            $cmd.CommandText = "INSERT INTO [RestoreValidation].[Results] VALUES ('$ServerID','$dbname','$dbsize','$filename','$restoreresult','$isaccesible','$restorestartdate','$restoreenddate','$logdate')"
                            $conn.close()
                            $conn.open()
                            $cmd.executenonquery()| Out-Null
                            $cmd.CommandText = "DROP DATABASE [$dbname]"
                            $conn.close()
                            $conn.open()
                            try {$cmd.executenonquery()| Out-Null}
                            catch {}
                            $conn.close()
                            
                        }
                    }
                    else
                    {
                        $Serverwoport = $Server.Split(",")[0]
                        $dddatabasepath = $ddpath + "\" + $Serverwoport + "\" + $Serverwoport
                        if($Serverwoport -eq "PWFLOPSQL001C-1"){ $dddatabasepath = $ddpath + "\" + $Serverwoport + "\DIR002"}
                        $dblist = Get-ChildItem $dddatabasepath -Exclude "master","model","msdb","dba_admin","LiteSpeedLocal" | Select Name
                        foreach ($db in $dblist)
                        { 
                            $skipFlag = 0
                            $dbname = $db.Name;
                            #$dbsize = 'NULL'
                            $filenamepath = $dddatabasepath + "\" + $dbname
                            $filenameonly = Get-ChildItem -Path $filenamepath | Where-Object { $_.Name -like "*.bkp" -and $_.Name -notlike "*.d[0-9]*.bkp"} | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Select -ExpandProperty Name
                            if(!$filenameonly){ $skipFlag = 1}
                            
                            if($skipFlag -eq 0)
                            {
                            $filename = $filenamepath + "\" + $filenameonly
                            $dbname = $dbname.Trim();
                            
                            $filename = $filename.Trim();
                            
                            $conn.close()
                            $conn.ConnectionString = "Data Source=$CentralServer;Integrated Security=SSPI;"
                            $conn.open()
                            $cmd.connection = $conn
                            $cmd.CommandText = "exec master.dbo.xp_restore_filelistonly @filename = '$filename'"
                            $adapter.SelectCommand = $cmd
                            $dsbakdetails = New-Object System.Data.DataSet
                            try{$adapter.Fill($dsbakdetails) | Out-Null
                            }
                            catch{}
                            $restorecmdfname = @()
                            foreach ($dsb in $dsbakdetails.tables[0].Rows)
                            { 
                                $logicalname = $dsb["LogicalName"];
                                if($logicalname.ToLower() -like "*log*")
                                {
                                    $restorecmdfname += "@with = N'MOVE N''$logicalname'' TO N''K:\MSSQLSERVER\Data01\$logicalname.ldf''',"
                                }
                                else
                                {
                                    $restorecmdfname += "@with = N'MOVE N''$logicalname'' TO N''K:\MSSQLSERVER\Data01\$logicalname.mdf''',"
                                }
                                
                            }
                            $conn.close()
                            $conn.ConnectionString = "Data Source=$CentralServer;Initial Catalog=INFODB;Integrated Security=SSPI;"
                            $conn.open()
                            $cmd.connection = $conn
                            $cmd.CommandText = "
                                                exec master.dbo.xp_restore_database @database = N'$dbname' ,
                                                @filename = N'$filename',
                                                @filenumber = 1, 
                                                @encryptionkey = N'$backuppassword',
                                               "
                            
                            $cmd.CommandText = $cmd.CommandText + $restorecmdfname
                            $cmd.CommandText = $cmd.CommandText + "
                                                                    @maxtransfersize = 4194304,
                                                                    @buffercount = 126
                                                                    "
                            
                            $restorestartdate = Get-Date -Format g
                            try{$cmd.executenonquery()| Out-Null
                                $restoreresult ="Restore SUCCESSFUL"
                            }
                            catch {
                                
                                #$_ | Handle-LynkError 
                                #$_.Exception.Message
                                
                                $restoreresult ="Restore FAILED.`n" + $_.Exception.Message
                                $restoreresult = $restoreresult.Replace("'","""")
                            }
                            $restoreenddate = Get-Date -Format g
                            $conn.close()
                            $conn.open()
                            $cmd.CommandText = "SELECT count(*) as count FROM [$dbname].INFORMATION_SCHEMA.TABLES"
                            try
                            {
                                $dbcheck = $cmd.executereader()
                                $isaccesible = "Yes"
                            }
                            catch
                            {
                                $isaccesible = "No.`n" + $_.Exception.Message
                                $isaccesible = $isaccesible.Replace("'","""")
                            }
                           
                            $cmd.CommandText = "INSERT INTO [RestoreValidation].[Results]([ServerID],[DatabaseName],[BackupFile],[RestoreResult],[IsDBAccessible],[RestoreStartDate],[RestoreEndDate],[LogDate]) VALUES ('$ServerID','$dbname','$filename','$restoreresult','$isaccesible','$restorestartdate','$restoreenddate','$logdate')"
                            $conn.close()
                            $conn.open()
                            $cmd.executenonquery()| Out-Null
                            $cmd.CommandText = "DROP DATABASE [$dbname]"
                            $conn.close()
                            $conn.open()
                            try {$cmd.executenonquery()| Out-Null}
                            catch {}
                            $conn.close()
                            }
                        }
                    }
            }
        }
       

       

}
catch
{
   $_
   $_ | Handle-LynkError 
}
finally
{       
    $conn.Close()

   
}