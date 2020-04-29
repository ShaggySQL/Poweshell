USE [DBA_Admin]
GO

/****** Object:  StoredProcedure [capacityplanning].[GetProcessorQueueLengthPerDay]    Script Date: 11/12/2019 10:44:06 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   procedure [capacityplanning].[GetProcessorQueueLengthPerDay]
	@InstanceName as Varchar(200)
	,@UTCFromDate as datetime
	,@UTCToDate as datetime
	
as
begin

--DECLARE @InstanceName as VArchar(200)
--DECLARE @UTCFromDate as datetime
--DECLARE @UTCToDate as datetime



--set @InstanceName = 'DA-PDBSQL21\PRD,1780'
--SET @UTCFromDate = '9/1/2019'
--SET @UTCToDate = '10/1/2019'



SELECT
	  CAST([UTCCollectionDateTime] as Date) as DAY
	  ,ms.InstanceName
	  ,AVG([ProcessorQueueLength]) as AVG_ProcessorQueueLength
      ,MAX([ProcessorQueueLength]) as Max_ProcessorQueueLength
INTO #TEMPProcessorQueueLength
FROM [SQLdmRepository].[dbo].[OSStatistics] os
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  os.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
  AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate
  GROUP BY CAST([UTCCollectionDateTime] as Date), ms.InstanceName
  ORDER BY CAST([UTCCollectionDateTime] as Date)



 SELECT
	CAST([UTCCollectionDateTime] as Date) as DAY
	,ms.InstanceName
	,[ProcessorQueueLength] as ProcessorQueueLength
	,NTile(20) OVER (PARTITION by CAST([UTCCollectionDateTime] as Date) Order BY [ProcessorQueueLength]) as Tile
INTO #TEMP95ProcessorQueueLength
FROM [SQLdmRepository].[dbo].[OSStatistics] os
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  os.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
  AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate
    AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate




SELECT 
	tpql.DAY
	,tpql.InstanceName
	,AVG_ProcessorQueueLength
	,Max_ProcessorQueueLength
	,MAX ([ProcessorQueueLength]) as [95Percentile_ProcessorQueueLength]
FROM #TEMPProcessorQueueLength tpql
INNER JOIN #TEMP95ProcessorQueueLength t95pql ON
tpql.DAY = t95pql.DAY
WHERE t95pql.Tile <> 20
	GROUP BY tpql.DAY, tpql.InstanceName,AVG_ProcessorQueueLength,Max_ProcessorQueueLength
	ORDER BY tpql.DAY, tpql.InstanceName,AVG_ProcessorQueueLength,Max_ProcessorQueueLength




DROP TABLE #TEMPProcessorQueueLength
DROP TABLE #TEMP95ProcessorQueueLength


END
GO


