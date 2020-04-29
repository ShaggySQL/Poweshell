$app = "SQLDiscovery"
$Removedays = (Get-Date).AddDays(-15)
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
        Error = $Error;
        }
        $Filename = "C:\temp\psError$App" +  @(get-date -Format yyyy_MM_dd) + ".txt"
        $ErrObject | fl -force | Out-File -FilePath $Filename -Append -Width 500
    }    
}
$CentralServer = 'PWFLOPDBAS001'
$conn = New-Object System.Data.SqlClient.SqlConnection
$cmd = New-Object System.Data.SqlClient.SqlCommand
$adapter = New-Object System.Data.SqlClient.SqlDataAdapter
$dsServers = New-Object System.Data.DataSet
$dsInstances = New-Object System.Data.DataSet
$logdate = Get-Date -Format g
try
{
       $StatusID  = [int]::Empty
       $conn.ConnectionString = "Data Source=$CentralServer;Initial Catalog=INFODB;Integrated Security=SSPI;"
       $conn.open()
       $cmd.connection = $conn
       $cmd.CommandText = "select s.ServerName,s.ServerID from info.Servers s where s.IsServer = 1"
       $adapter.SelectCommand = $cmd
       $adapter.Fill($dsServers) | Out-Null
       $cmd.CommandText = "select s.ServerName,s.ServerID,s.PortNumber from info.Servers s where s.IsInstance = 1"
       $adapter.SelectCommand = $cmd
       $adapter.Fill($dsInstances) | Out-Null
       $TableDetail = @()
       $DatabaseDetail = @()
       $filedetails = @()
       
       Import-Module SQLServer -DisableNameChecking
         #####################################################################   Server Loop  ########################################################################
        if ($dsServers.Tables[0].rows.Count -gt 0)
        {
            foreach ($dr in $dsServers.tables[0].Rows)
            { 
                    $Server = $dr["ServerName"];
                    $ServerID = $dr["ServerID"];
                    
                    $Server = $Server.Trim();
                    
                    $DriveDetail += Get-WmiObject -Class win32_Volume -ComputerName $Server -Filter "DriveType = '3'"|  where {$_.caption -notlike "\\*"} |
                                                                                                                        select @{name="ServerID";expression= {$ServerID}},@{name="ServerName";expression= {$Server}},`
                                                                                                                        @{name="Drive";expression= {$_.caption}},`
                                                                                                                        @{name="CapacityinGB";expression = {[math]::truncate($_.Capacity/1gb)}},`
                                                                                                                        @{name="UsedSpaceinGB";expression = {([math]::truncate($_.Capacity/1gb)) - ([math]::truncate($_.freespace/1gb))}},`
                                                                                                                        @{name="FreeSpaceinGB";expression = {[math]::truncate($_.freespace/1gb)}} `
            }
             foreach ($d in $DriveDetail)
            {         $d.CapacityinGB = [int]$d.CapacityinGB
                      $d.UsedSpaceinGB = [int]$d.UsedSpaceinGB
                      $d.FreeSpaceinGB = [int]$d.FreeSpaceinGB
                      $cmd.commandtext = "insert into info.Drives values ('" + $d.ServerID + "','" + $d.ServerName + "','" + $d.Drive + "','" + $d.CapacityinGB + "','" + $d.UsedSpaceinGB + "','" + $d.FreeSpaceinGB + "','" + $logdate + "')"
                      $cmd.executenonquery()| Out-Null
            }
         }
        if ($dsInstances.Tables[0].rows.Count -gt 0)
        {
            foreach ($dr in $dsInstances.tables[0].Rows)
            { 
                    $Server = $dr["ServerName"];
                    $ServerID = $dr["ServerID"];
                    $Server = $Server.Trim();
                    $PortNumber = $dr["PortNumber"];
                    $PortNumber = $PortNumber.Trim();
                    $SQLInstance = $Server + "," + $PortNumber
                    try{
                    $s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $SQLInstance
                        }
                    catch
                    {
                    $s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $Server
                    }
                    $DatabaseDetail += $s.Databases | where {$_.IsAccessible -eq "True"} | select ID,@{name="SQLInstance";expression= {$SQLInstance}},@{name="Server";expression= {$Server}},@{name="ServerID";expression= {$ServerID}},`
                                                     @{name="DatabaseName";expression={$_.name}},`
                                                     @{name="Drive";expression={$_.PrimaryFilePath}},`
                                                     @{name="UsedSpace";expression={(($_.DataSpaceUsage/1024/1024) + ($_.IndexSpaceUsage/1024/1024)).ToString('N2')}},`
                                                     @{name="FreeSpace";expression={($_.SpaceAvailable/1024/1024).toString('N2')}},`
                                                     @{name="DataSpace";expression={($_.DataSpaceUsage/1024/1024).toString('N2')}},`
                                                     @{name="IndexSpace";expression={($_.IndexSpaceUsage/1024/1024).toString('N2')}},`
                                                     LastBackupDate,LastDifferentialBackupDate `
              }  
              

                    foreach ($d in $DatabaseDetail)
                    {
                        
                        $Server = $d.Server;
                        $SQLInstance = $d.SQLInstance;
                        try
                        {
                        $s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $SQLInstance
                        }
                        catch
                        {
                        $s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $Server
                        }
                        
                      $dbid = [int]$d.ID  
                     if($dbid -gt 4)
                     {   
                        try
                        {
                        $TableDetail += $s.Databases[$d.DatabaseName].tables| where {$_.DataSpaceUsed -gt 1048576 -or $_.IndexSpaceUsed -gt 1048576} | select @{name="ServerID";expression= {$d.ServerID}},@{name="ServerName";expression= {$d.Server}},name,Urn,`
                                                                                                                        @{name="RowCT";expression={$_.RowCountAsDouble.toString('N0')}},`
                                                                                                                        @{name="DataSpaceUsed";expression={($_.DataSpaceUsed/1024/1024).toString('N2')}},`
                                                                                                                       @{name="IndexSpaceUsed";expression={($_.IndexSpaceUsed/1024/1024).toString('N2')}} `
                        }
                        catch
                        {
                        }
                        $Filegroups = $s.Databases[$d.DatabaseName].FileGroups
                        foreach($f in $Filegroups)
                        {
                            $filedetails += $s.Databases[$d.DatabaseName].FileGroups[$f.Name].Files | select @{name="ServerID";expression= {$d.ServerID}},@{name="ServerName";expression= {$d.Server}},`
                                                                                                      @{name="dbname";expression= {$d.DatabaseName}},`
                                                                                                      @{name="fgname";expression= {$f.Name}},`
                                                                                                      @{name="FileName";expression= {$_.FileName}},`
                                                                                                      @{name="Size";expression={($_.Size/1024/1024).toString('N2')}},`
                                                                                                      @{name="UsedSpace";expression={($_.UsedSpace/1024/1024).toString('N2')}},`
                                                                                                      @{name="AvailableSpace";expression={($_.AvailableSpace/1024/1024).toString('N2')}},`
                                                                                                      @{name="VolumeFreeSpace";expression={($_.VolumeFreeSpace/1024/1024).toString('N2')}}`

                        }

                     }                                                                                
                    }     

                

                    foreach ($d in $DatabaseDetail)
                    {  
                    $d.UsedSpace = [int]$d.UsedSpace
                    $d.FreeSpace = [int]$d.FreeSpace
                    $d.DataSpace = [int]$d.DataSpace
                    $d.IndexSpace = [int]$d.IndexSpace
                    $d.Drive = $d.Drive.SubString(0,3);
                    if($d.LastBackupDate -eq "1/1/0001 12:00 AM"){ $d.LastBackupDate = "NULL"};
                    if($d.LastDifferentialBackupDate -eq "1/1/0001 12:00 AM"){ $d.LastDifferentialBackupDate = "NULL"};
                    $cmd.commandtext = "insert into info.Databases values ('" + $d.ServerID + "','" + $d.Server + "','" + $d.DatabaseName + "','" + $d.Drive + "','" + $d.UsedSpace + "','" + $d.FreeSpace + "','" + $d.DataSpace + "','" + $d.IndexSpace + "','" + $d.LastBackupDate + "','" + $d.LastDifferentialBackupDate + "','" + $logdate + "')"
                    $cmd.commandtext = $cmd.commandtext -replace "'NULL'", "NULL"
                    $cmd.executenonquery()| Out-Null
                    }
                    foreach ($t in $TableDetail)
                            {   $t.DataSpaceUsed = [int]$t.DataSpaceUsed
                                $t.IndexSpaceUsed = [int]$t.IndexSpaceUsed
                                $tdname = $t.Urn.Value.Split("'")[3]
                                $IntRowCT = [int]$t.RowCT
                                $cmd.commandtext = "insert into info.Tables values ('" + $t.ServerID + "','" + $t.ServerName + "','" + $tdname + "','" + $t.name + "','" + $IntRowCT + "','" + $t.DataSpaceUsed + "','" + $t.IndexSpaceUsed + "','" + $logdate + "')"
                                $cmd.executenonquery()| Out-Null
                            }

                    foreach($f in $filedetails)
                            {
                                $f.Size = [int]$f.Size
                                $f.UsedSpace = [int]$f.UsedSpace
                                $f.AvailableSpace = [int]$f.AvailableSpace
                                $f.VolumeFreeSpace = [int]$f.VolumeFreeSpace
                                $cmd.commandtext = "insert into info.DatabaseFileInfo values ('" + $f.ServerID + "','" + $f.ServerName + "','" + $f.dbname + "','" + $f.fgname + "','" + $f.FileName + "','" + $f.Size + "','" + $f.UsedSpace + "','" + $f.AvailableSpace + "','" + $f.VolumeFreeSpace + "','" +$logdate + "')"
                                $cmd.executenonquery()| Out-Null
                            }
                    
        }             
            
        
}catch
{
   $_
   $_ | Handle-LynkError 
}
finally
{       
    $conn.Close()

   
}

