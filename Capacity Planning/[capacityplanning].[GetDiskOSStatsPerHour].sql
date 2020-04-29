USE [DBA_Admin]
GO

/****** Object:  StoredProcedure [capacityplanning].[GetDiskOSStatsPerHour]    Script Date: 11/12/2019 10:36:46 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






CREATE  procedure [capacityplanning].[GetDiskOSStatsPerHour]
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
	  CONVERT(VARCHAR(13), UTCCollectionDateTime, 120) as DayAndHour
	  ,ms.InstanceName
	  ,AVG([DiskTimePercent]) as AVG_DiskTimePercent
      ,MAX([DiskTimePercent]) as Max_DiskTimePercent
      ,AVG([DiskQueueLength]) as AVG_DiskQueueLength
	  ,MAX([DiskQueueLength]) as Max_DiskQueueLength
INTO #TEMPDiskStats
  FROM [SQLdmRepository].[dbo].[OSStatistics] os
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  os.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
  AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate
  GROUP BY CONVERT(VARCHAR(13), UTCCollectionDateTime, 120), ms.InstanceName
  ORDER BY CONVERT(VARCHAR(13), UTCCollectionDateTime, 120)




   SELECT
	CONVERT(VARCHAR(13), UTCCollectionDateTime, 120) as DayAndHour
	,ms.InstanceName
	,[DiskTimePercent]
	,NTile(20) OVER (PARTITION by CAST([UTCCollectionDateTime] as Date) Order BY [DiskTimePercent]) as Tile
INTO #TEMPDiskTimePercent
  FROM [SQLdmRepository].[dbo].[OSStatistics] os
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  os.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
  AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate




SELECT
	CONVERT(VARCHAR(13), UTCCollectionDateTime, 120) as DayAndHour
	,ms.InstanceName
	,[DiskQueueLength]
	,NTile(20) OVER (PARTITION by CAST([UTCCollectionDateTime] as Date) Order BY [DiskQueueLength]) as Tile
INTO #TEMPDiskQueueLength
  FROM [SQLdmRepository].[dbo].[OSStatistics] os
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  os.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
  AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate




SELECT 
	TDS.DayAndHour
	,TDS.InstanceName
	,AVG_DiskTimePercent
	,Max_DiskTimePercent
	,AVG_DiskQueueLength
	,Max_DiskQueueLength
	,MAX (DiskTimePercent) as [95Percentile_DiskTimePercent]
INTO #Temp95DiskTimePercent
FROM #TEMPDiskStats TDS
INNER JOIN #TEMPDiskTimePercent TDTP ON
TDS.DayAndHour = TDTP.DayAndHour
WHERE TDTP.Tile <> 20
	GROUP BY TDS.DayAndHour, TDS.InstanceName	,AVG_DiskTimePercent,Max_DiskTimePercent,AVG_DiskQueueLength,Max_DiskQueueLength
	ORDER BY TDS.DayAndHour, TDS.InstanceName	,AVG_DiskTimePercent,Max_DiskTimePercent,AVG_DiskQueueLength,Max_DiskQueueLength



SELECT 
	T95DTP.DayAndHour
	,T95DTP.InstanceName
	,AVG_DiskTimePercent
	,Max_DiskTimePercent
	,AVG_DiskQueueLength
	,Max_DiskQueueLength
	,[95Percentile_DiskTimePercent]
	,MAX ([DiskQueueLength]) as [95Percentile_DiskQueueLength]
FROM #Temp95DiskTimePercent T95DTP
inner join #TEMPDiskQueueLength TDQL ON
T95DTP.DayAndHour = TDQL.DayAndHour
WHERE TDQL.Tile <>20
	GROUP BY T95DTP.DayAndHour,T95DTP.InstanceName,AVG_DiskTimePercent,Max_DiskTimePercent,AVG_DiskQueueLength,Max_DiskQueueLength,[95Percentile_DiskTimePercent]
	ORDER BY T95DTP.DayAndHour,T95DTP.InstanceName,AVG_DiskTimePercent,Max_DiskTimePercent,AVG_DiskQueueLength,Max_DiskQueueLength,[95Percentile_DiskTimePercent]





DROP TABLE #TEMPDiskStats
DROP TABLE #TEMPDiskTimePercent
DROP TABLE #TEMPDiskQueueLength
DROP TABLE #Temp95DiskTimePercent

END
GO


