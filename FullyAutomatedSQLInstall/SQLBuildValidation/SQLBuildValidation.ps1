param([string]$ServerName, [string]$Option)
function Perform-Validation 
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$ServerName,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$Option
    )
    #$ComputerName = "-computername $ServerName"
    #$ComputerName = [computername]::Create($ComputerName)
    
    $global:ValidationRepositoryServer = "PWGR2RSQLDB1C-2.PROD.PB01.LOCAL,62754"
    $iFlag = 0
    $SName = $ServerName.split("\\")[0]
    $InsNames = $ServerName.split("\\")[1]
    try {$a = Invoke-Command -computername $SName -scriptblock {$env:computername} -ErrorAction SilentlyContinue
            if ($?)
            {   
                                            
            }
            else
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
            $iFlag = 1
            echo "`n$ServerName not reachable. Copy the script to the target server in order to perform the validation.`n"
            echo $_.Exception.Message
		$env:username
            #echo $_.Exception.ItemName
            exit
           }  
  

    if ($Option -eq "PRE")
    {
        $UName = ([Environment]::UserDomainName + "\" + [Environment]::UserName)
        $DateCheckedOn = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        $CentralServer = $ValidationRepositoryServer
        $conn = New-Object System.Data.SqlClient.SqlConnection
        $cmd = New-Object System.Data.SqlClient.SqlCommand
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $dsControls = New-Object System.Data.DataSet
        
        echo "Performing PRE - Validation `n"
            try
            {
               
               $conn.ConnectionString = "Data Source=$CentralServer;Initial Catalog=INFODB;Integrated Security=SSPI;"
               
               $conn.open()
               
               $cmd.connection = $conn
               $cmd.CommandText = "select s.ControlID,s.Control,s.Script from build.ValidationScripts s where s.IsPRE = 1 order by s.ControlID"
               $adapter.SelectCommand = $cmd
               $adapter.Fill($dsControls) | Out-Null
               
               if ($dsControls.Tables[0].rows.Count -gt 0)
                {
                    foreach ($dr in $dsControls.tables[0].Rows)
                    { 
                            $ControlID = $dr["ControlID"];
                            $Control = $dr["Control"];
                            $Script = $dr["Script"];
                            $ScriptBlock = [scriptblock]::Create($Script)
                            if ($ControlID -eq 1)
                            {
                                try { $net = invoke-command -computername $ServerName -ScriptBlock $Scriptblock -ErrorAction SilentlyContinue
                                      if ($?)
                                        {   $net = ".Net 3.5 PRESENT"
                                            
                                        }
                                        else
                                        {
                                           throw $error[0].Exception
                                        }
                                    }
                                catch { $net = ".Net 3.5 MISSING"  } 
                                finally    {
                                                    $cmd.commandtext = "insert into [build].[PreInstallMiscResults] values ('" + $ServerName + "','" + $Control + "','" + $net + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                    $cmd.executenonquery()| Out-Null
                                            }
                            }
                            if ($ControlID -eq 2)
                            {
                                try { $drive = invoke-command -computername $ServerName -ScriptBlock $Scriptblock -ErrorAction SilentlyContinue
                                      if ($?)
                                        { 
                                            foreach ($dr in $drive)
                                            {
                                                
                                                $dr.FreeSpace = [math]::round($dr.FreeSpace/1Gb,2)
                                                
                                                $dr.Size = [math]::round($dr.Size/1Gb,2)
                                                
                                                $cmd.commandtext = "insert into [build].[PreInstallDriveResults] values ('" + $ServerName + "','" + $Control + "','" + $dr.DeviceID + "','" + $dr.VolumeName + "','" + $dr.FreeSpace + "','" + $dr.Size + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                $cmd.executenonquery()| Out-Null
                                                
                                            }
                                        
                                        
                                        }
                                        else
                                        {
                                           throw $error[0].Exception
                                        }
                                    }
                                catch { } 
                                
                            }
                            
                            if ($ControlID -eq 3)
                            {
                                try { $page = invoke-command -computername $ServerName -ScriptBlock $Scriptblock -ErrorAction SilentlyContinue
                                      if ($?)
                                        { 
                                            foreach ($pg in $page)
                                            {
                                                
                                                $pg.AllocatedBaseSize = [math]::round($pg.AllocatedBaseSize/1024,2)
                                                
                                                $cmd.commandtext = "insert into [build].[PreInstallPageFileResults] values ('" + $ServerName + "','" + $Control + "','" + $pg.name + "','" + $pg.AllocatedBaseSize + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                $cmd.executenonquery()| Out-Null
                                             }
                                        
                                        
                                        }
                                        else
                                        {
                                           throw $error[0].Exception
                                        }
                                    }
                                catch { }
                                
                            }
                            if ($ControlID -eq 4)
                            {
                                try { $license = invoke-command -computername $ServerName -ScriptBlock $Scriptblock -ErrorAction SilentlyContinue
                                      if ($?)
                                        { 
                                            foreach ($lic in $license)
                                            {
                                                if($lic.licensestatus -eq "1")
                                                {
                                                    $license = "Activated"
                                                    
                                                }
                                                else
                                                {
                                                    $license = "NOT Activated"
                                                }

                                             }
                                        
                                        }
                                        else
                                        {
                                           throw $error[0].Exception
                                        }
                                    }
                                catch { $license = "NOT Activated" }
                                

                                finally    { 
                                                    $cmd.commandtext = "insert into [build].[PreInstallMiscResults] values ('" + $ServerName + "','" + $Control + "','" + $license + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                    $cmd.executenonquery()| Out-Null
                                            }
                                
                            }
                            if ($ControlID -eq 5)
                            {
                                try { $RAM = invoke-command -computername $ServerName -ScriptBlock $Scriptblock -ErrorAction SilentlyContinue
                                      if ($?)
                                        { 
                                           $RAM  = [math]::round($RAM/1Gb)
                                                                           
                                        }
                                        else
                                        {
                                           throw $error[0].Exception
                                        }
                                    }
                                catch { $RAM = "ERROR" ; }
                                finally    {
                                                    $cmd.commandtext = "insert into [build].[PreInstallMiscResults] values ('" + $ServerName + "','" + $Control + "','" + $RAM + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                    $cmd.executenonquery()| Out-Null
                                            }
                                
                            }
                            if ($ControlID -eq 6)
                            {
                                try { $CPU = invoke-command -computername $ServerName -ScriptBlock $Scriptblock -ErrorAction SilentlyContinue
                                      if ($?)
                                        { 
                                                                             
                                        }
                                        else
                                        {
                                           throw $error[0].Exception
                                        }
                                    }
                                catch { $CPU = "ERROR" ; } 
                                finally    {
                                                    $cmd.commandtext = "insert into [build].[PreInstallMiscResults] values ('" + $ServerName + "','" + $Control + "','" + $CPU + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                    $cmd.executenonquery()| Out-Null
                                            }
                                
                            }

                            

                    }
                }
             }

             catch
             {
                $iFlag = 2
                echo "Unable to reach the repository stored in $CentralServer from this host. `n"
                #echo $_.Exception.Message
                #echo $_.Exception.ItemName
                

                exit
             }
             finally
             {       
                if ($iFlag -ne 2)
                {
                echo "Script Execution Complete. Execute a query on the INFODB Database tables on MWGR2RSQLDB1C-2 to see the results, until SSRS is setup.`n"
                #echo "http://PWGR2RSQLDB1C-2.PROD.PB01.LOCAL,62754/Reports"
                
                }
                
                $conn.Close()
                
             }
    }
    

    if ($Option -eq "POST")
    {
        
        $UName = ([Environment]::UserDomainName + "\" + [Environment]::UserName)
        $DateCheckedOn = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        $CentralServer = $ValidationRepositoryServer
        $conn = New-Object System.Data.SqlClient.SqlConnection
        $cmd = New-Object System.Data.SqlClient.SqlCommand
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $dsControls = New-Object System.Data.DataSet
        echo "Performing POST - Validation`n"

        try
        {
               $conn.ConnectionString = "Data Source=$CentralServer;Initial Catalog=INFODB;Integrated Security=SSPI;"
               $conn.open()
               $cmd.connection = $conn
               $cmd.CommandText = "select s.ControlID,s.Control,s.Script from build.ValidationScripts s where s.IsPOST = 1 order by s.ControlID"
               $adapter.SelectCommand = $cmd
               $adapter.Fill($dsControls) | Out-Null
               
               if ($dsControls.Tables[0].rows.Count -gt 0)
                {
                    
                    try{ 
                        if(!$InsNames)
                        {$InsNames = Invoke-Command -ComputerName $SName -ScriptBlock { Get-Item -path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' | Select-Object -ExpandProperty Property }
                        }
                        else
                        {}
                        foreach($iName in $InsNames)
                        {
                            if($iName -like '%#SSEE%')
                            {}
                            else
                            {
                                         foreach ($dr in $dsControls.tables[0].Rows)
                                         { 
                                            $ControlID = $dr["ControlID"];
                                            $Control = $dr["Control"];
                                            $Script = $dr["Script"];
                                            $ScriptBlock = [scriptblock]::Create($Script)
                                            if($iName -eq "MSSQLSERVER")
                                            {$SQLServerName = $SName }
                                            else
                                            {$SQLServerName = $SName + "\" + $iName}

                    

                                                    if ($ControlID -eq 7)
                                                    {
                                                        try { $tcpnet = invoke-command -computername $SName -ScriptBlock $Scriptblock -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($tp in $tcpnet)
                                                                    {
                                                                        if($tp.Enabled -eq 1)
                                                                        { $tpstatus = "Enabled"}
                                                                        else
                                                                        { $tpstatus ="Disabled"}
                                                                        
                                                
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $tpstatus + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { }
                                                    }

                                                    if ($ControlID -eq 8)
                                                    {
                                                        try { $Npnet = invoke-command -computername $SName -ScriptBlock $Scriptblock -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($Np in $Npnet)
                                                                    {
                                                                        if($Np.Enabled -eq 1)
                                                                        { $Npstatus = "Enabled"}
                                                                        else
                                                                        { $Npstatus ="Disabled"}
                                                                        
                                                
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $Npstatus + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { }
                                                    }

                                                    if ($ControlID -eq 9)
                                                    {
                                                        try { $Smnet = invoke-command -computername $SName -ScriptBlock $Scriptblock -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($Sm in $Smnet)
                                                                    {
                                                                        if($Sm.Enabled -eq 1)
                                                                        { $Smstatus = "Enabled"}
                                                                        else
                                                                        { $Smstatus ="Disabled"}
                                                                        
                                                
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $Smstatus + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { }
                                                    }

                                                    if ($ControlID -eq 10)
                                                    {
                                                        try { $tcpport = invoke-command -computername $SName -ScriptBlock $Scriptblock -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($tcpp in $tcpport)
                                                                    {
                                                                        $portnumber = $tcpp.TcpPort
                                                                        $portnumberdynamic = $tcpp.TcpDynamicPorts
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $tcpp.TcpPort + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                                                     $SQLServerInstance = $SQLServerName + "," + $portnumber
                                                                     
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { }
                                                    }

                                                    if ($ControlID -eq 11)
                                                    {
                                                        try { $Count = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($Dcount in $Count)
                                                                    {
                                                                        if($Dcount.Count -eq 0)
                                                                        { $Dstatus = "Yes"}
                                                                        else
                                                                        { $Dstatus ="No"}
                                                                        
                                                
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $Dstatus + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    break
                                                              }
                                                    }

                                                    if ($ControlID -eq 12)
                                                    {
                                                        try { $Count = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($Dcount in $Count)
                                                                    {
                                                                        if($Dcount.Count -eq 0)
                                                                        { $Dstatus = "Yes"}
                                                                        else
                                                                        { $Dstatus ="No"}
                                                                        
                                                
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $Dstatus + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    break
                                                              }
                                                    }

                                                    if ($ControlID -eq 13)
                                                    {
                                                        try { $Count = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($Dcount in $Count)
                                                                    {
                                                                        if($Dcount.Count -eq 0)
                                                                        { $Dstatus = "Yes"}
                                                                        else
                                                                        { $Dstatus ="No"}
                                                                        
                                                
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $Dstatus + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    break
                                                              }
                                                    }

                                                    if ($ControlID -eq 14)
                                                    {
                                                        try { $maxmemory = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($maxm in $maxmemory)
                                                                    {
                                                                        $maxm.value_in_use = $maxm.value_in_use/1024 
                                                                        $result = $maxm.MaxMemory + ". " + $maxm.value_in_use + " GB"
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $result + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }

                                                     if ($ControlID -eq 15)
                                                    {
                                                        try { $ole = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($ol in $ole)
                                                                    {
                                                                        
                                                                        $result = $ol.OLE
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $result + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                       
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }

                                                     if ($ControlID -eq 16)
                                                    {
                                                        try { $dac = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($dc in $dac)
                                                                    {
                                                                        
                                                                        $result = $dc.DAC
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $result + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                       
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }

                                                     if ($ControlID -eq 17)
                                                    {
                                                        try { $adhoc = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($ac in $adhoc)
                                                                    {
                                                                        
                                                                        $result = $ac.adhoc
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $result + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                       
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }

                                                     if ($ControlID -eq 18)
                                                    {
                                                        try { $clr = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($cr in $clr)
                                                                    {
                                                                        
                                                                        $result = $cr.clr
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $result + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                       
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }
                                                     if ($ControlID -eq 19)
                                                    {
                                                        try { $crossdb = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($cs in $crossdb)
                                                                    {
                                                                        
                                                                        $result = $cs.crossdb
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $result + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                       
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }

                                                      if ($ControlID -eq 20)
                                                    {
                                                        try { $raccess = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($ra in $raccess)
                                                                    {
                                                                        
                                                                        $result = $ra.remoteaccess
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $result + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                       
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }

                                                      if ($ControlID -eq 21)
                                                    {
                                                        try { $dxp = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($dx in $dxp)
                                                                    {
                                                                        
                                                                        $result = $dx.dbmailxps
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $result + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                       
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }

                                                      if ($ControlID -eq 22)
                                                    {
                                                        try { $sprocs = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($sp in $sprocs)
                                                                    {
                                                                        
                                                                        $result = $sp.startupprocs
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $result + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                       
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }

                                                      if ($ControlID -eq 23)
                                                    {
                                                        try { $xpcmd = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($xpc in $xpcmd)
                                                                    {
                                                                        
                                                                        $result = $xpc.xpcmdshell
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $result + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                       
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }

                                                    if ($ControlID -eq 24)
                                                    {
                                                        try { $hidei = invoke-command -computername $SName -ScriptBlock $Scriptblock -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($hi in $hidei)
                                                                    {
                                                                        if($hi.HideInstance -eq 1)
                                                                        { $histatus = "Yes"}
                                                                        else
                                                                        { $histatus ="No"}
                                                                        
                                                
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $histatus + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { }
                                                    }

                                                     if ($ControlID -eq 25)
                                                    {
                                                        try { $enum = invoke-command -computername $SName -ScriptBlock $Scriptblock -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($en in $enum)
                                                                    {
                                                                        
                                                                        if($en.NumErrorLogs -eq 12)
                                                                        { $enstatus = "Yes"}
                                                                        else
                                                                        { $enstatus ="No"}
                                                                        
                                                
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $enstatus + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { }
                                                    }

                                                      if ($ControlID -eq 26)
                                                    {
                                                        try { $sarename = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($sa in $sarename)
                                                                    {
                                                                        
                                                                        $result = $sa.sa
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $result + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                       
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }

                                                      if ($ControlID -eq 27)
                                                    {
                                                        try { $sadisable = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($sad in $sadisable)
                                                                    {
                                                                        
                                                                        $result = $sad.sa
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $result + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                       
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }

                                                       if ($ControlID -eq 28)
                                                    {
                                                        try { $dbadmin = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($dba in $dbadmin)
                                                                    {
                                                                        
                                                                        $result = $dba.name
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $result + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                       
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }

                                                       if ($ControlID -eq 29)
                                                    {
                                                        try { $tmail = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($tm in $tmail)
                                                                    {
                                                                        
                                                                        if($tm.sent_status -eq 1)
                                                                        { $tmstatus = "Yes"}
                                                                        else
                                                                        { $tmstatus ="No"}
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $tmstatus + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                       
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }


                                                       if ($ControlID -eq 30)
                                                    {
                                                        try { $operator = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($op in $operator)
                                                                    {
                                                                        
                                                                        if($op.ENABLED -eq 1)
                                                                        { $opstatus = "Yes"}
                                                                        else
                                                                        { $opstatus ="No"}
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $opstatus + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                       
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }

                                                        if ($ControlID -eq 31)
                                                    {
                                                        try { $ola = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($ol in $ola)
                                                                    {
                                                                        
                                                                        if($ol.count -ge 5)
                                                                        { $olstatus = "Yes"}
                                                                        else
                                                                        { $olstatus ="No"}
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $olstatus + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                       
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }

                                                        if ($ControlID -eq 32)
                                                    {
                                                        try { $lp = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($l in $lp)
                                                                    {
                                                                        
                                                                        if($l.count -ge 2)
                                                                        { $lstatus = "Yes"}
                                                                        else
                                                                        { $lstatus ="No"}
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $lstatus + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                       
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }

                                                         if ($ControlID -eq 33)
                                                    {
                                                        try { $audit = Invoke-Sqlcmd -Query $Scriptblock -ServerInstance $SQLServerInstance -ErrorAction SilentlyContinue
                                                              if ($?)
                                                                { 
                                                                    foreach ($aud in $audit)
                                                                    {
                                                                        
                                                                        if($aud.count -eq 3)
                                                                        { $astatus = "Yes"}
                                                                        else
                                                                        { $astatus ="No"}
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $astatus + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                       
                                                                        $cmd.executenonquery()| Out-Null
                                                                     }
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   throw $error[0].Exception
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    echo $_.Exception.Message
                                                                    echo $_.Exception.ItemName
                                                                    break
                                                              }
                                                    }

                                                         if ($ControlID -eq 34)
                                                    {
                                                        try { 
                                                                if(!$portnumberdynamic)   
                                                                {$portnumberdynamicresponse = "Yes"
                                                                        $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $portnumberdynamicresponse + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                        $cmd.executenonquery()| Out-Null
                                                              
                                        
                                        
                                                                }
                                                                else
                                                                {
                                                                   $portnumberdynamicresponse = "No"
                                                                   $cmd.commandtext = "insert into [build].[PostInstallMiscResults] values ('" + $SQLServerName + "','" + $Control + "','" + $portnumberdynamicresponse + "','" + $UName + "','" + $DateCheckedOn + "')"
                                                                   $cmd.executenonquery()| Out-Null
                                                                }
                                                            }
                                                        catch { 
                                                                    echo "Exiting. Please make sure that the instance is up and running."
                                                                    
                                                                    break
                                                              }
                                                    }

                                          }
                                
                               }

                        }

                        }
                    catch
                        {
                        echo "catch"

                        }
                    
                    
                }


        }

        catch
        {
            $iFlag = 2
            echo "Unable to reach the repository stored in $CentralServer from this host. `n"
            
        }

        finally
        {
            if ($iFlag -ne 2)
                {
                echo "Script Execution Complete. Execute a query on the INFODB Database tables on MWGR2RSQLDB1C-2 to see the results, until SSRS is setup.`n"
                #echo "http://PWGR2RSQLDB1C-2.PROD.PB01.LOCAL,62754/Reports"
                
                
                }
                $conn.Close()
                
        }
    }
    


}

if ($ServerName -eq "" -or $Option -eq "" )
{
    
    echo "`nArgument missing. Usage :: ./SQLBuildValidation.ps1 SERVERNAME PRE      --> for Pre install validation."
    echo "                  Usage :: ./SQLBuildValidation.ps1 SERVERNAME POST     --> for Post install validation."
    exit;
}
else
{
    if ($Option -ne "PRE" -and $Option -ne "POST")
    {
        echo "`nArgument missing. Usage :: ./SQLBuildValidation.ps1 SERVERNAME PRE      --> for Pre install validation."
        echo "                  Usage :: ./SQLBuildValidation.ps1 SERVERNAME POST     --> for Post install validation."
        exit;

    }
    else
    {
    #echo "Proceeding"
    Perform-Validation $ServerName $Option
    }
}
