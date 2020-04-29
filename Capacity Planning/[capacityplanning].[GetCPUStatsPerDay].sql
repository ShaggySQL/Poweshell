USE [DBA_Admin]
GO

/****** Object:  StoredProcedure [capacityplanning].[GetCPUStatsPerDay]    Script Date: 11/12/2019 10:21:37 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE    procedure [capacityplanning].[GetCPUStatsPerDay]
	@InstanceName as Varchar(200)
	,@UTCFromDate as datetime
	,@UTCToDate as datetime
	
as
begin


/*----------------------------------------------------------------------------------
------------------------------------------------------------------------------------
Usage:  exec [capacityplanning].[GetCPUStatsPerDay] 
				@InstanceName = 'DA-PDBSQL21\PRD,1780'
				,@UTCFromDate = '9/1/2019'
				,@UTCToDate = '10/1/2019'

Purpose:  This stored proc will pull CPU stats per day.  Per day it will get the AVG, MAX, and 
95th percentile for CPU activity Percentage.

Who                  When       What
--------------------------------------------------------------------------------------
JSM					10/22/19    Created CPU Stats proc
-------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------*/

SELECT
	CAST([UTCCollectionDateTime] as Date) as DAY
	,ms.InstanceName
	,[CPUActivityPercentage] as CPUActivityPercentage
	,NTile(20) OVER (PARTITION by CAST([UTCCollectionDateTime] as Date) Order BY [CPUActivityPercentage]) as COLUMNTEST
INTO #TEMPTestData
FROM [SQLdmRepository].[dbo].[ServerStatistics] ss
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  ss.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
    AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate


SELECT
	 CAST([UTCCollectionDateTime] as Date) as DAY
	  ,ms.InstanceName
	  ,80 as CPUThreshold
	  ,AVG([CPUActivityPercentage]) as AVG_CPU
      ,MAX([CPUActivityPercentage]) as MAX_CPU
INTO #TEmpMaxAvg
  FROM [SQLdmRepository].[dbo].[ServerStatistics] ss
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  ss.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
  AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate
  GROUP BY CAST([UTCCollectionDateTime] as Date), ms.InstanceName
  ORDER BY CAST([UTCCollectionDateTime] as Date)


SELECT 
	ttd.DAY
	,ttd.InstanceName
	,CPUThreshold
	,AVG_CPU
	,MAX_CPU
	,MAX (CPUActivityPercentage) as [95Percentile]
FROM #TEMPTestData ttd
INNER JOIN #TEmpMaxAvg TMA ON
ttd.DAY = TMA.DAY
WHERE COLUMNTEST <> 20
	GROUP BY ttd.DAY, ttd.InstanceName,CPUThreshold,AVG_CPU,MAX_CPU
	ORDER BY ttd.DAY, ttd.InstanceName,CPUThreshold,AVG_CPU,MAX_CPU



DROP TABLE #TEMPTestData
DROP TABLE #TEmpMaxAvg




END
GO


