$CentralServer = 'PWFLOPDBAS001'
$conn = New-Object System.Data.SqlClient.SqlConnection
$cmd = New-Object System.Data.SqlClient.SqlCommand
$adapter = New-Object System.Data.SqlClient.SqlDataAdapter
$dsServers = New-Object System.Data.DataSet
       $conn.ConnectionString = "Data Source=$CentralServer;Initial Catalog=INFODB;Integrated Security=SSPI;"
       $conn.open()
       $cmd.connection = $conn
       $cmd.CommandText = "select s.ServerName,s.ServerID from test.Servers_Tier3 s"
       $adapter.SelectCommand = $cmd
       $adapter.Fill($dsServers) | Out-Null

       if ($dsServers.Tables[0].rows.Count -gt 0)
        {
            foreach ($dr in $dsServers.tables[0].Rows)
            { 
                    $Server = $dr["ServerName"];
                    $ServerID = $dr["ServerID"];
                    
                    $Server = $Server.Trim();
                    
                    
                    $InsNames = Invoke-Command -ComputerName $Server -ScriptBlock { Get-Item -path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' | Select-Object -ExpandProperty Property }
                    #$InsNames = $InsNames.Trim()
                    #$InsNames
                    
                    foreach($ins in $InsNames)
                    {
                    
                    if($ins -ne "MICROSOFT##SSEE")
                    {
                    $tcpport = invoke-command -computername $Server -ScriptBlock {Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$using:ins\MSSQLServer\SuperSocketNetLib\tcp\IPAll" | select -ExpandProperty TcpPort } 
                    $c1 = Get-WmiObject -Class Win32_SystemServices -ComputerName $server
                    
                    #$clusterstate
                        if ($c1 | select PartComponent | where {$_ -like "*ClusSvc*"})
                        { 
                            $clusterstate = invoke-command -computername $Server -ScriptBlock {Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$using:ins\Cluster" | select -ExpandProperty ClusterName} 
                            if($ins -eq "MSSQLSERVER"){$ins = $null}else{$ins = "\" + $ins}
                            $InstanceName = $clusterstate + $ins 
                            $InstanceName = $InstanceName.Trim();
                            $tcpport = $tcpport.Trim();
                            $InstanceName
                            $tcpport
                                                                    
                        }
                        else
                        {
                            if($ins -eq "MSSQLSERVER")
                            {
                            $InstanceName = $Server  
                            $InstanceName = $InstanceName.Trim();
                            $tcpport = $tcpport.Trim();
                            $InstanceName
                            $tcpport

                            }
                            else
                            {
                            $InstanceName = $Server + "\" + $ins 
                            $InstanceName = $InstanceName.Trim();
                            $tcpport = $tcpport.Trim();
                            $InstanceName
                            $tcpport
                            }
                        }

                        #insert#
                        $cmd.commandtext = "insert into test.SQLServers_Tier3 values ('" + $ServerID + "','" + $Server + "','" + $InstanceName + "','" + $tcpport + "')"
                        $cmd.executenonquery()| Out-Null
              
                    
                      }
                    
                     } 
                    
            }
             
         }
         $conn.close()