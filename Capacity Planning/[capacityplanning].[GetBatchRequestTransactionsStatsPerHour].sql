USE [DBA_Admin]
GO

/****** Object:  StoredProcedure [capacityplanning].[GetBatchRequestTransactionsStatsPerHour]    Script Date: 11/12/2019 10:07:22 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   procedure [capacityplanning].[GetBatchRequestTransactionsStatsPerHour]
	@InstanceName as Varchar(200)
	,@UTCFromDate as datetime
	,@UTCToDate as datetime
	
as
begin


/*----------------------------------------------------------------------------------
------------------------------------------------------------------------------------
Usage:  exec [capacityplanning].[GetBatchRequestTransactionsStatsPerDay]
				@InstanceName = 'DA-PDBSQL21\PRD,1780'
				,@UTCFromDate = '9/1/2019'
				,@UTCToDate = '10/1/2019'

Purpose:  This stored proc will pull Batch Requests Per Second and transaction per second stats per day.  
Per day it will get the AVG, MAX, and 95th percentile for Batch Requests Per Second and transaction per second stats.

Who                  When       What
--------------------------------------------------------------------------------------
JSM					10/22/19    Created Batch Requests Per Second and transaction per second stats proc
-------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------*/



/****** Script for SelectTopNRows command from SSMS  ******/
SELECT
	 CONVERT(VARCHAR(13), UTCCollectionDateTime, 120) as DayAndHour
	  ,ms.InstanceName
      --,Batches as Batch
	  --,Transactions as Transactions
	  ,AVG((Batches/60)) as AVG_BatchesPerSecond
	  ,MAX((Batches/60)) as MAX_BatchesPerSecond
	  ,AVG((Transactions/60)) as AVG_TransactionPerSecond
	  ,MAX((Transactions/60)) as MAX_TransactionPerSecond
INTO #TEmpMaxAvg
  FROM [SQLdmRepository].[dbo].[ServerStatistics] ss
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  ss.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
  AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate
  GROUP BY CONVERT(VARCHAR(13), UTCCollectionDateTime, 120), ms.InstanceName
  ORDER BY CONVERT(VARCHAR(13), UTCCollectionDateTime, 120)



  SELECT
	CONVERT(VARCHAR(13), UTCCollectionDateTime, 120) as DayAndHour
	,ms.InstanceName
	,[Batches] as Batches
	,NTile(20) OVER (PARTITION by CAST([UTCCollectionDateTime] as Date) Order BY [Batches]) as COLUMNTEST
INTO #TEMPTestData
FROM [SQLdmRepository].[dbo].[ServerStatistics] ss
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  ss.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
    AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate




SELECT
	CONVERT(VARCHAR(13), UTCCollectionDateTime, 120) as DayAndHour
	,ms.InstanceName
	,[Transactions] as Transactions
	,NTile(20) OVER (PARTITION by CAST([UTCCollectionDateTime] as Date) Order BY [Transactions]) as COLUMNTEST
INTO #TEMPTestData2
FROM [SQLdmRepository].[dbo].[ServerStatistics] ss
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  ss.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
    AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate




SELECT 
	ttd.DayAndHour
	,ttd.InstanceName
	,AVG_BatchesPerSecond
	,MAX_BatchesPerSecond
	,AVG_TransactionPerSecond
	,MAX_TransactionPerSecond
	,MAX (([Batches]/60)) as [95Percentile_BatchesPerSecond]
INTO #TempBatchData
FROM #TEMPTestData ttd
INNER JOIN #TEmpMaxAvg TMA ON
ttd.DayAndHour = TMA.DayAndHour
WHERE ttd.COLUMNTEST <> 20
	GROUP BY ttd.DayAndHour, ttd.InstanceName,AVG_BatchesPerSecond,MAX_BatchesPerSecond,AVG_TransactionPerSecond,MAX_TransactionPerSecond
	ORDER BY ttd.DayAndHour, ttd.InstanceName,AVG_BatchesPerSecond,MAX_BatchesPerSecond,AVG_TransactionPerSecond,MAX_TransactionPerSecond



SELECT 
	tbd.DayAndHour
	,tbd.InstanceName
	,AVG_BatchesPerSecond
	,MAX_BatchesPerSecond
	,AVG_TransactionPerSecond
	,MAX_TransactionPerSecond
	,[95Percentile_BatchesPerSecond]
	,MAX (([Transactions]/60)) as [95Percentile_TransactionsPerSecond]
FROM #TempBatchData tbd
inner join #TEMPTestData2 ttd2 ON
ttd2.DayAndHour = tbd.DayAndHour
WHERE ttd2.COLUMNTEST <>20
	GROUP BY tbd.DayAndHour, tbd.InstanceName,AVG_BatchesPerSecond,MAX_BatchesPerSecond,AVG_TransactionPerSecond,MAX_TransactionPerSecond,tbd.[95Percentile_BatchesPerSecond]
	ORDER BY tbd.DayAndHour, tbd.InstanceName,AVG_BatchesPerSecond,MAX_BatchesPerSecond,AVG_TransactionPerSecond,MAX_TransactionPerSecond,tbd.[95Percentile_BatchesPerSecond]


DROP TABLE #TEMPTestData2
DROP TABLE #TEMPTestData
DROP TABLE #TEmpMaxAvg
DROP TABLE #TempBatchData

END
GO


