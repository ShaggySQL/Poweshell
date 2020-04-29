USE [DBA_Admin]
GO

/****** Object:  StoredProcedure [capacityplanning].[GetCPUStatsPerHour]    Script Date: 11/12/2019 10:24:52 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE    procedure [capacityplanning].[GetCPUStatsPerHour]
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
	CONVERT(VARCHAR(13), UTCCollectionDateTime, 120) as DayAndHour
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
	 CONVERT(VARCHAR(13), UTCCollectionDateTime, 120) as DayAndHour
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
  GROUP BY CONVERT(VARCHAR(13), UTCCollectionDateTime, 120), ms.InstanceName
  ORDER BY CONVERT(VARCHAR(13), UTCCollectionDateTime, 120)


SELECT 
	ttd.DayAndHour
	,ttd.InstanceName
	,CPUThreshold
	,AVG_CPU
	,MAX_CPU
	,MAX (CPUActivityPercentage) as [95Percentile]
FROM #TEMPTestData ttd
INNER JOIN #TEmpMaxAvg TMA ON
ttd.DayAndHour = TMA.DayAndHour
WHERE COLUMNTEST <> 20
	GROUP BY ttd.DayAndHour, ttd.InstanceName,CPUThreshold,AVG_CPU,MAX_CPU
	ORDER BY ttd.DayAndHour, ttd.InstanceName,CPUThreshold,AVG_CPU,MAX_CPU



DROP TABLE #TEMPTestData
DROP TABLE #TEmpMaxAvg




END
GO


