USE [DBA_Admin]
GO

/****** Object:  StoredProcedure [capacityplanning].[GetDiskLatencyPerDay]    Script Date: 11/12/2019 10:26:52 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE   procedure [capacityplanning].[GetDiskLatencyPerDay]
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
SELECT CAST([UTCCollectionDateTime] as Date) as DAY 
	  ,ms.InstanceName
      --,[DriveName]
	  ,AVG([AverageDiskQueueLength]) as AVG_AverageDiskQueueLength
	  ,MAX([AverageDiskQueueLength]) as MAX_AverageDiskQueueLength
      ,AVG([AverageDiskMillisecondsPerRead]) as AVG_AverageDiskMillisecondsPerRead
	  ,MAX([AverageDiskMillisecondsPerRead]) as MAX_AverageDiskMillisecondsPerRead
      ,AVG([AverageDiskMillisecondsPerWrite]) as AVG_AverageDiskMillisecondsPerWrite
	  ,MAX([AverageDiskMillisecondsPerWrite]) as MAX_AverageDiskMillisecondsPerWrite
INTO #TempDiskLatency
  FROM [SQLdmRepository].[dbo].[DiskDrives] dd
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  dd.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
  AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate
  GROUP BY CAST([UTCCollectionDateTime] as Date),ms.InstanceName
  ORDER BY CAST([UTCCollectionDateTime] as Date)


SELECT
	CAST([UTCCollectionDateTime] as Date) as DAY
	,ms.InstanceName
	,[AverageDiskQueueLength] as AverageDiskQueueLength
	,NTile(20) OVER (PARTITION by CAST([UTCCollectionDateTime] as Date) Order BY [AverageDiskQueueLength]) as Tile
INTO #TempAverageDiskQueueLength
 FROM [SQLdmRepository].[dbo].[DiskDrives] dd
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  dd.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
  AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate

 SELECT
	CAST([UTCCollectionDateTime] as Date) as DAY
	,ms.InstanceName
	,[AverageDiskMillisecondsPerRead] as AverageDiskMillisecondsPerRead
	,NTile(20) OVER (PARTITION by CAST([UTCCollectionDateTime] as Date) Order BY [AverageDiskMillisecondsPerRead]) as Tile
INTO #TEMPAverageDiskMillisecondsPerRead
 FROM [SQLdmRepository].[dbo].[DiskDrives] dd
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  dd.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
  AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate


  SELECT
	CAST([UTCCollectionDateTime] as Date) as DAY
	,ms.InstanceName
	,[AverageDiskMillisecondsPerWrite] as AverageDiskMillisecondsPerWrite
	,NTile(20) OVER (PARTITION by CAST([UTCCollectionDateTime] as Date) Order BY [AverageDiskMillisecondsPerWrite]) as Tile
INTO #TEMPAverageDiskMillisecondsPerWrite
 FROM [SQLdmRepository].[dbo].[DiskDrives] dd
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  dd.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
  AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate




  
SELECT 
	TDL.DAY
	,TDL.InstanceName
	,AVG_AverageDiskQueueLength
	,MAX_AverageDiskQueueLength
	,AVG_AverageDiskMillisecondsPerRead
	,MAX_AverageDiskMillisecondsPerRead
	,AVG_AverageDiskMillisecondsPerWrite
	,MAX_AverageDiskMillisecondsPerWrite
	,MAX(AverageDiskQueueLength) as [AverageDiskQueueLength_95Percentile]
INTO #Temp95AverageDiskQueueLength
FROM #TempDiskLatency TDL
	INNER JOIN #TempAverageDiskQueueLength TADQL ON
	TDL.DAY = TADQL.DAY
WHERE TADQL.Tile <> 20
GROUP BY TDL.DAY
	,TDL.InstanceName
	,AVG_AverageDiskQueueLength
	,MAX_AverageDiskQueueLength
	,AVG_AverageDiskMillisecondsPerRead
	,MAX_AverageDiskMillisecondsPerRead
	,AVG_AverageDiskMillisecondsPerWrite
	,MAX_AverageDiskMillisecondsPerWrite
ORDER BY TDL.DAY
	,TDL.InstanceName
	,AVG_AverageDiskQueueLength
	,MAX_AverageDiskQueueLength
	,AVG_AverageDiskMillisecondsPerRead
	,MAX_AverageDiskMillisecondsPerRead
	,AVG_AverageDiskMillisecondsPerWrite
	,MAX_AverageDiskMillisecondsPerWrite


SELECT 
T95ADQL.DAY
	,T95ADQL.InstanceName
	,AVG_AverageDiskQueueLength
	,MAX_AverageDiskQueueLength
	,AVG_AverageDiskMillisecondsPerRead
	,MAX_AverageDiskMillisecondsPerRead
	,AVG_AverageDiskMillisecondsPerWrite
	,MAX_AverageDiskMillisecondsPerWrite
	,[AverageDiskQueueLength_95Percentile]
	,MAX(AverageDiskMillisecondsPerRead) as [AverageDiskMillisecondsPerRead95Percentile]
INTO #Temp95AverageDiskMillisecondsPerRead
FROM  #Temp95AverageDiskQueueLength T95ADQL
	INNER JOIN #TEMPAverageDiskMillisecondsPerRead TADMPR ON
	T95ADQL.DAY = TADMPR.DAY
WHERE TADMPR.Tile <> 20
GROUP BY T95ADQL.DAY
	,T95ADQL.InstanceName
	,AVG_AverageDiskQueueLength
	,MAX_AverageDiskQueueLength
	,AVG_AverageDiskMillisecondsPerRead
	,MAX_AverageDiskMillisecondsPerRead
	,AVG_AverageDiskMillisecondsPerWrite
	,MAX_AverageDiskMillisecondsPerWrite
	,[AverageDiskQueueLength_95Percentile]
ORDER BY T95ADQL.DAY
	,T95ADQL.InstanceName
	,AVG_AverageDiskQueueLength
	,MAX_AverageDiskQueueLength
	,AVG_AverageDiskMillisecondsPerRead
	,MAX_AverageDiskMillisecondsPerRead
	,AVG_AverageDiskMillisecondsPerWrite
	,MAX_AverageDiskMillisecondsPerWrite
	,[AverageDiskQueueLength_95Percentile]



SELECT 
	T95DMPR.DAY
	,T95DMPR.InstanceName
	,AVG_AverageDiskQueueLength
	,MAX_AverageDiskQueueLength
	,AVG_AverageDiskMillisecondsPerRead
	,MAX_AverageDiskMillisecondsPerRead
	,AVG_AverageDiskMillisecondsPerWrite
	,MAX_AverageDiskMillisecondsPerWrite
	,[AverageDiskQueueLength_95Percentile]
	,[AverageDiskMillisecondsPerRead95Percentile]
	,MAX(AverageDiskMillisecondsPerWrite) as [AverageDiskMillisecondsPerWrite95Percentile]
FROM  #Temp95AverageDiskMillisecondsPerRead T95DMPR
	INNER JOIN #TEMPAverageDiskMillisecondsPerWrite TADMPW ON
	T95DMPR.DAY = TADMPW.DAY
WHERE TADMPW.Tile <> 20
GROUP BY T95DMPR.DAY
	,T95DMPR.InstanceName
	,AVG_AverageDiskQueueLength
	,MAX_AverageDiskQueueLength
	,AVG_AverageDiskMillisecondsPerRead
	,MAX_AverageDiskMillisecondsPerRead
	,AVG_AverageDiskMillisecondsPerWrite
	,MAX_AverageDiskMillisecondsPerWrite
	,[AverageDiskQueueLength_95Percentile]
	,[AverageDiskMillisecondsPerRead95Percentile]
ORDER BY T95DMPR.DAY
	,T95DMPR.InstanceName
	,AVG_AverageDiskQueueLength
	,MAX_AverageDiskQueueLength
	,AVG_AverageDiskMillisecondsPerRead
	,MAX_AverageDiskMillisecondsPerRead
	,AVG_AverageDiskMillisecondsPerWrite
	,MAX_AverageDiskMillisecondsPerWrite
	,[AverageDiskQueueLength_95Percentile]
	,[AverageDiskMillisecondsPerRead95Percentile]


DROP TABLE #TempDiskLatency
DROP TABLE #TempAverageDiskQueueLength
DROP TABLE #TEMPAverageDiskMillisecondsPerRead
DROP TABLE #TEMPAverageDiskMillisecondsPerWrite
DROP TABLE #Temp95AverageDiskQueueLength
DROP TABLE #Temp95AverageDiskMillisecondsPerRead


END
GO


