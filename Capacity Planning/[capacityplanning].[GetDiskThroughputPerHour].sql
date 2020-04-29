USE [DBA_Admin]
GO

/****** Object:  StoredProcedure [capacityplanning].[GetDiskThroughputPerHour]    Script Date: 11/12/2019 10:38:41 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE   procedure [capacityplanning].[GetDiskThroughputPerHour]
	@InstanceName as Varchar(200)
	,@UTCFromDate as datetime
	,@UTCToDate as datetime
	
as
begin

--DECLARE @UTCFromDate as datetime
--DECLARE @UTCToDate as datetime
--DECLARE @InstanceName as VArchar(200)


--set @InstanceName = 'DA-PDBSQL21\PRD,1780'
--SET @UTCFromDate = '9/1/2019'
--SET @UTCToDate = '10/1/2019'


/****** Script for SelectTopNRows command from SSMS  ******/
SELECT CONVERT(VARCHAR(13), UTCCollectionDateTime, 120) as DayAndHour 
	  ,ms.InstanceName
      --,[DriveName]
      ,AVG([DiskReadsPerSecond]) as AVG_DiskReadsPerSecond
	  ,MAX([DiskReadsPerSecond]) as MAX_DiskReadsPerSecond
   --   ,AVG([DiskTransfersPerSecond]) as AVG_DiskTransfersPerSecond
	  --,MAX([DiskTransfersPerSecond]) as MAX_DiskTransfersPerSecond
      ,AVG([DiskWritesPerSecond]) as AVG_DiskWritesPerSecond
	  ,MAX([DiskWritesPerSecond]) as MAX_DiskWritesPerSecond
INTO #TEmpMaxAvg
  FROM [SQLdmRepository].[dbo].[DiskDrives] dd
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  dd.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
  AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate
  GROUP BY CONVERT(VARCHAR(13), UTCCollectionDateTime, 120),ms.InstanceName
  ORDER BY CONVERT(VARCHAR(13), UTCCollectionDateTime, 120)


     SELECT
	CONVERT(VARCHAR(13), UTCCollectionDateTime, 120) as DayAndHour
	,ms.InstanceName
	,[DiskReadsPerSecond] as DiskReadsPerSecond
	,NTile(20) OVER (PARTITION by CAST([UTCCollectionDateTime] as Date) Order BY [DiskReadsPerSecond]) as COLUMNTEST
INTO #TEMPTestData
 FROM [SQLdmRepository].[dbo].[DiskDrives] dd
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  dd.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
  AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate


  SELECT
	CONVERT(VARCHAR(13), UTCCollectionDateTime, 120) as DayAndHour
	,ms.InstanceName
	,[DiskWritesPerSecond] as DiskWritesPerSecond
	,NTile(20) OVER (PARTITION by CAST([UTCCollectionDateTime] as Date) Order BY [DiskWritesPerSecond]) as COLUMNTEST
INTO #TEMPTestData2
 FROM [SQLdmRepository].[dbo].[DiskDrives] dd
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  dd.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
  AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate



  
SELECT 
	ttd.DayAndHour
	,ttd.InstanceName
	,AVG_DiskReadsPerSecond
	,MAX_DiskReadsPerSecond
	,AVG_DiskWritesPerSecond
	,MAX_DiskWritesPerSecond
	,MAX([DiskReadsPerSecond]) as [DiskReadsPerSecond95Percentile]
INTO #TempDisk95
FROM #TEmpMaxAvg TMA
INNER JOIN #TEMPTestData ttd ON
ttd.DayAndHour = TMA.DayAndHour
WHERE ttd.COLUMNTEST <> 20
	GROUP BY ttd.DayAndHour, ttd.InstanceName,AVG_DiskReadsPerSecond,MAX_DiskReadsPerSecond,AVG_DiskWritesPerSecond,MAX_DiskWritesPerSecond
	ORDER BY ttd.DayAndHour, ttd.InstanceName,AVG_DiskReadsPerSecond,MAX_DiskReadsPerSecond,AVG_DiskWritesPerSecond,MAX_DiskWritesPerSecond


SELECT 
td95.DayAndHour
,td95.InstanceName
,td95.AVG_DiskReadsPerSecond
,td95.MAX_DiskReadsPerSecond
,td95.AVG_DiskWritesPerSecond
,td95.MAX_DiskWritesPerSecond
,td95.DiskReadsPerSecond95Percentile
,MAX(DiskWritesPerSecond) as [DiskWritesPerSecond95Percentile]
FROM  #TempDisk95 td95
INNER JOIN #TEMPTestData2 ttd2 ON
td95.DayAndHour = ttd2.DayAndHour
WHERE ttd2.COLUMNTEST <> 20
GROUP BY td95.DayAndHour ,td95.InstanceName ,td95.AVG_DiskReadsPerSecond ,td95.MAX_DiskReadsPerSecond ,td95.AVG_DiskWritesPerSecond ,td95.MAX_DiskWritesPerSecond ,td95.DiskReadsPerSecond95Percentile
ORDER BY td95.DayAndHour ,td95.InstanceName ,td95.AVG_DiskReadsPerSecond ,td95.MAX_DiskReadsPerSecond ,td95.AVG_DiskWritesPerSecond ,td95.MAX_DiskWritesPerSecond ,td95.DiskReadsPerSecond95Percentile






DROP TABLE #TEMPTestData2
DROP TABLE #TEMPTestData
DROP TABLE #TEmpMaxAvg
DROP TABLE #TempDisk95


END
GO


