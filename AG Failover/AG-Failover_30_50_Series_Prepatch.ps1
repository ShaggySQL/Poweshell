param([string]$ServerName)
$j2 = 0
function Perform-Failover
{ 
[CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$ServerName
    )

try
{
    $AGDetails = @()
    $dbDetails = @()
    Import-Module SQLPS -DisableNameChecking;
    $hostsqlserver = $ServerName;
    
    $sqlserver = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $hostsqlserver;
   
    
    $ags = $sqlserver.AvailabilityGroups;


    foreach ($ag in $ags)
    {
        #$ag.Name ;
        $AGDetails += $sqlserver.AvailabilityGroups[$ag.Name] | where {$_.IsDistributedAvailabilityGroup -ne "True" -and $_.AvailabilityReplicas -ne "{}"} | select   Name,AvailabilityReplicas,LocalReplicaRole
      
    }
    
   
    foreach ($ag in $AGDetails)
    {
        
        $agName = $ag.Name;
        
        #$ag.AvailabilityReplicas #| where { $_.Name -eq $hostsqlserver } # |select *;
        $AGprimaryReplica = $ag.AvailabilityReplicas | where { $_.Role -eq "Primary"}
        $AGprimaryReplicaName = $AGprimaryReplica.Name
        
        $AGsecondaryReplicas = $ag.AvailabilityReplicas | where { $_.Role -eq "Secondary"}
        
        #$AGRemotesecondaryReplica = $AGsecondaryReplicas | Select-Object -last 1 ;
        $AGRemotesecondaryReplica = $AGsecondaryReplicas
       
        $AGRemotesecondaryReplicaName = $AGRemotesecondaryReplica.Name;
        $AGRemotesecondaryReplicaAvailabilityMode = $ag.AvailabilityReplicas[$AGRemotesecondaryReplicaName].AvailabilityMode
        #$AGRemotesecondaryReplicaAvailabilityMode
        $AGRemotesecondaryReplicaConnectionState = $AGRemotesecondaryReplica.ConnectionState
        #$AGRemotesecondaryReplicaConnectionState
        $AGRemotesecondaryReplicaRollupSynchronizationState = $AGRemotesecondaryReplica.RollupSynchronizationState
        #$AGRemotesecondaryReplicaRollupSynchronizationState
        
        
        
        $jobdetails = $sqlserver.JobServer.Jobs | where {$_.Name -eq "test"}|select name,currentrunstatus,IsEnabled
        #$job1 = New-object Microsoft.SqlServer.Management.Smo.Agent.Job($sqlserver.Jobserver,"test")
        #$job1 | Get-Member -MemberType Property
        #$job1.IsEnabled = $FALSE
                    foreach ($jb in $jobdetails)
                    {
                        #$jb.IsEnabled = $False
                        #$jb.Alter()
                        $jobname = $jb.name
                        if($jb.CurrentRunStatus -ne "Idle")
                        {
                            echo "`n`n$jobname is still running. Waiting for the job to complete."
                            for($v1 = 1;$v1 -le 120; $v1++)
            {$sqlserver = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $hostsqlserver;
            $jobdetails = $sqlserver.JobServer.Jobs | where {$_.Name -eq "test"}|select name,currentrunstatus,IsEnabled
            foreach ($jb in $jobdetails)
            {
                $jobname = $jb.Name
                if($jb.CurrentRunStatus -ne "Idle")
                {
                    Start-Sleep -s 10
                    echo "`n`n"
                    echo "Still waiting for the $jobname job to complete."
                    
                    
                }
                else
                {
                    
                   $v1 = 120 
                   echo "`n`n`n$jobname job Completed."
                }

                }
                
                

            }
                        }
                    }


                     $jobdetails = $sqlserver.JobServer.Jobs | where {$_.Name -eq "test2" }|select name,currentrunstatus,IsEnabled
                     #$job1 = New-object Microsoft.SqlServer.Management.Smo.Agent.Job($sqlserver.Jobserver,"test2")
                    #$job1.IsEnabled = $FALSE
                    foreach ($jb in $jobdetails)
                    {
                       # $jb.IsEnabled = $False
                       # $jb.Alter()
                        $jobname = $jb.name
                        if($jb.CurrentRunStatus -ne "Idle")
                        {
                            echo "`n`n$jobname is still running. Waiting for the job to complete."
                            for($v1 = 1;$v1 -le 120; $v1++)
            {$sqlserver = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $hostsqlserver;
            $jobdetails = $sqlserver.JobServer.Jobs | where {$_.Name -eq "test2" }|select name,currentrunstatus,IsEnabled
            foreach ($jb in $jobdetails)
            {
                $jobname = $jb.Name
                if($jb.CurrentRunStatus -ne "Idle")
                {
                    Start-Sleep -s 10
                    echo "`n`n"
                    echo "Still waiting for the $jobname job to complete."
                    
                    
                }
                else
                {
                    
                   $v1 = 120 
                   echo "`n`n`n$jobname job Completed."
                }

                }
                
                

            }
                        }
                    }

        
        
        echo "`n`n`nRemote secondary identified as $AGRemotesecondaryReplicaName . Remote Replica state is $AGRemotesecondaryReplicaConnectionState and the synchronization state is $AGRemotesecondaryReplicaRollupSynchronizationState ."
        echo "`n`n`nRemote secondary replica Availability Mode is : $AGRemotesecondaryReplicaAvailabilityMode "
        if ($AGRemotesecondaryReplicaAvailabilityMode -eq "AsynchronousCommit")
        {
            echo "`n`n`nChanging the Availability Mode to Synchronous Commit to ensure there is no data loss."
            $a = Set-SqlAvailabilityReplica -AvailabilityMode "SynchronousCommit" -FailoverMode "Automatic" -Path "SQLSERVER:\Sql\$AGprimaryReplicaName\DEFAULT\AvailabilityGroups\$agName\AvailabilityReplicas\$AGprimaryReplicaName"
            $a = Set-SqlAvailabilityReplica -AvailabilityMode "SynchronousCommit" -FailoverMode "Automatic" -Path "SQLSERVER:\Sql\$AGprimaryReplicaName\DEFAULT\AvailabilityGroups\$agName\AvailabilityReplicas\$AGRemotesecondaryReplicaName"
            echo "`n`n`nAvailability mode changed to Synchronous Commit. Validating the state and health of AG."
            
            for($var = 1;$var -le 5; $var++)
            {$sqlserver = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $hostsqlserver;
            
                if($sqlserver.AvailabilityGroups[$ag.Name].AvailabilityReplicas[$AGRemotesecondaryReplicaName].ConnectionState -ne "Connected" -or $sqlserver.AvailabilityGroups[$ag.Name].AvailabilityReplicas[$AGRemotesecondaryReplicaName].RollupSynchronizationState -ne "Synchronized" )
                {
                    Start-Sleep -s 5
                    echo "`n`n"
                    echo "Still waiting for the State to change to Connected and Synchronized."
                }
                else
                {
                    $var = 6
                    echo "`n`n`nRemote Secondary Connection State is Connected and Synchronization state is Synchronized"
                }

            }
            
        }
        else
        {
            if($AGRemotesecondaryReplicaConnectionState -ne "Connected" -or $AGRemotesecondaryReplicaRollupSynchronizationState -ne "Synchronized")
            {
            echo "`n`nThe Availability Group is not in a healthy state and a failover should not be performed. `n`nExiting the script"
            exit
            }
        }

           
        
        $response1 = Read-Host -Prompt "`n`n`nPlease type 'YES' to failover to $AGRemotesecondaryReplicaName replica."
        $response2 = "NO"
        if ($response1.ToUpper() -eq "YES")
        {
                    
                    echo "`n`n`nProceeding on performing the failover";
                    Switch-SqlAvailabilityGroup -Path "SQLSERVER:\Sql\$AGRemotesecondaryReplicaName\DEFAULT\AvailabilityGroups\$agName"
                    echo "`n`n`nSuccessfully failed over. Setting the Availability Mode on Replica $AGprimaryReplicaName to Asynchronous Commit";
                    $a = Set-SqlAvailabilityReplica -AvailabilityMode "AsynchronousCommit" -FailoverMode "Manual" -Path "SQLSERVER:\Sql\$AGRemotesecondaryReplicaName\DEFAULT\AvailabilityGroups\$agName\AvailabilityReplicas\$AGprimaryReplicaName"
                    $a = Set-SqlAvailabilityReplica -AvailabilityMode "AsynchronousCommit" -FailoverMode "Manual" -Path "SQLSERVER:\Sql\$AGRemotesecondaryReplicaName\DEFAULT\AvailabilityGroups\$agName\AvailabilityReplicas\$AGRemotesecondaryReplicaName"
                    echo "`n`n`n$AGRemotesecondaryReplicaName has been set to AsynchronousCommit"
                    echo "`n`n`n$AGprimaryReplicaName has been set to AsynchronousCommit. `n`n`n`nPlease proceed to patch $AGprimaryReplicaName"

         }
        else
        {
            echo 'Exiting';
            }
        

    } 

}



catch
{  echo "`n$ServerName is not reachable. Please check the Server Name and the port Number.`nCheck the detailed error posted below`n`n" 
   $_
   
}
finally
{       
    

   
}

}

if ($ServerName -eq "" )
{
    
    echo "`nArgument missing. Usage :: ./AG-Failover_20_30_50_Series.ps1 ListenerName     --> for the default 1433 port"
    echo "                  Usage :: ./AG-Failover_20_30_50_Series.ps1 ListenerName,port     --> for Non-default port"
    exit;
}
else
{
    
        Perform-Failover $ServerName
    
}


##ssisjob_PaymentAccountReportingCT
##ssisjob_ExpressTransactionUpload
