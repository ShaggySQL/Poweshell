USE [DBA_Admin]
GO

/****** Object:  StoredProcedure [capacityplanning].[GetSqlCompilationsReCompilationsPerDay]    Script Date: 11/12/2019 10:46:06 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






CREATE   procedure [capacityplanning].[GetSqlCompilationsReCompilationsPerDay]
	@InstanceName as Varchar(200)
	,@UTCFromDate as datetime
	,@UTCToDate as datetime
	
as
begin


--DECLARE @Percentile as decimal(5,4)
--DECLARE @UTCFromDate as datetime
--DECLARE @UTCToDate as datetime
--DECLARE @InstanceName as VArchar(200)
--DECLARE @Count95Percentile as int

--set @InstanceName = 'DA-PDBSQL21\PRD,1780'
--SET @UTCFromDate = '10/1/2019'
--SET @UTCToDate = '11/1/2019'


/****** Script for SelectTopNRows command from SSMS  ******/
SELECT
	 CAST([UTCCollectionDateTime] as Date) as DAY
	 --ss.UTCCollectionDateTime
	  ,ms.InstanceName
	  ,AVG([UserProcesses]) as AVG_UserProcesses
	  ,MAX([UserProcesses]) as MAX_UserProcesses
	  ,AVG([SqlCompilations]) as AVG_SqlCompilations
	  ,MAX([SqlCompilations]) as MAX_SqlCompilations
      ,AVG([SqlRecompilations]) as AVG_SqlRecompilations
	  ,MAX([SqlRecompilations]) as MAX_SqlRecompilations
	  --,AVG(([Batches]/60)) as AVG_BatchesPerSecond
	  --,MAX(([Batches]/60)) as MAX_BatchesPerSecond
INTO #TEmpSQLServerStats
  FROM [SQLdmRepository].[dbo].[ServerStatistics] ss
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  ss.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
  AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate
  GROUP BY CAST([UTCCollectionDateTime] as Date), ms.InstanceName
  ORDER BY CAST([UTCCollectionDateTime] as Date)






  
  SELECT
	CAST([UTCCollectionDateTime] as Date) as DAY
	,ms.InstanceName
	,[UserProcesses] as UserProcesses
	,NTile(20) OVER (PARTITION by CAST([UTCCollectionDateTime] as Date) Order BY [UserProcesses]) as Tile
INTO #TEMPUserProcesses
FROM [SQLdmRepository].[dbo].[ServerStatistics] ss
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  ss.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
    AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate


  SELECT
	CAST([UTCCollectionDateTime] as Date) as DAY
	,ms.InstanceName
	,[SqlCompilations] as SqlCompilations
	,NTile(20) OVER (PARTITION by CAST([UTCCollectionDateTime] as Date) Order BY [SqlCompilations]) as Tile
INTO #TEMPSqlCompilations
FROM [SQLdmRepository].[dbo].[ServerStatistics] ss
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  ss.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
    AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate


  SELECT
	CAST([UTCCollectionDateTime] as Date) as DAY
	,ms.InstanceName
	,[SqlRecompilations] as SqlRecompilations
	,NTile(20) OVER (PARTITION by CAST([UTCCollectionDateTime] as Date) Order BY [SqlRecompilations]) as Tile
INTO #TEMPSqlRecompilations
FROM [SQLdmRepository].[dbo].[ServerStatistics] ss
  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
  ss.SQLServerID = ms.SQLServerID
  WHERE ms.InstanceName = @InstanceName
    AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate


--  SELECT
--	CAST([UTCCollectionDateTime] as Date) as DAY
--	,ms.InstanceName
--	,[Batches] as Batches
--	,NTile(20) OVER (PARTITION by CAST([UTCCollectionDateTime] as Date) Order BY [Batches]) as Tile
--INTO #TEMPBatches
--FROM [SQLdmRepository].[dbo].[ServerStatistics] ss
--  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
--  ss.SQLServerID = ms.SQLServerID
--  WHERE ms.InstanceName = @InstanceName
--    AND UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate



SELECT 
	TSSS.DAY
	,TSSS.InstanceName
	,AVG_UserProcesses
	,MAX_UserProcesses
	,AVG_SqlCompilations
	,MAX_SqlCompilations
	,AVG_SqlRecompilations
	,MAX_SqlRecompilations
	--,AVG_BatchesPerSecond
	--,MAX_BatchesPerSecond
	,MAX(UserProcesses) as [UserProcesses_95Percentile]
INTO #Temp95UserProcesses
FROM #TEmpSQLServerStats TSSS
	INNER JOIN #TEMPUserProcesses TUP ON
	TSSS.DAY = TUP.DAY
WHERE TUP.Tile <> 20
GROUP BY TSSS.DAY
	,TSSS.InstanceName
	,AVG_UserProcesses
	,MAX_UserProcesses
	,AVG_SqlCompilations
	,MAX_SqlCompilations
	,AVG_SqlRecompilations
	,MAX_SqlRecompilations
	--,AVG_BatchesPerSecond
	--,MAX_BatchesPerSecond
ORDER BY TSSS.DAY
	,TSSS.InstanceName
	,AVG_UserProcesses
	,MAX_UserProcesses
	,AVG_SqlCompilations
	,MAX_SqlCompilations
	,AVG_SqlRecompilations
	,MAX_SqlRecompilations
	--,AVG_BatchesPerSecond
	--,MAX_BatchesPerSecond






SELECT 
	T95UP.DAY
	,T95UP.InstanceName
	,AVG_UserProcesses
	,MAX_UserProcesses
	,AVG_SqlCompilations
	,MAX_SqlCompilations
	,AVG_SqlRecompilations
	,MAX_SqlRecompilations
	--,AVG_BatchesPerSecond
	--,MAX_BatchesPerSecond
	,UserProcesses_95Percentile
	,MAX(SqlCompilations) as [SqlCompilations_95Percentile]
INTO #Temp95SqlCompilations
FROM #Temp95UserProcesses T95UP
	INNER JOIN #TEMPSqlCompilations TSC ON
	T95UP.DAY = TSC.DAY
WHERE TSC.Tile <> 20
GROUP BY T95UP.DAY
	,T95UP.InstanceName
	,AVG_UserProcesses
	,MAX_UserProcesses
	,AVG_SqlCompilations
	,MAX_SqlCompilations
	,AVG_SqlRecompilations
	,MAX_SqlRecompilations
	--,AVG_BatchesPerSecond
	--,MAX_BatchesPerSecond
	,UserProcesses_95Percentile
ORDER BY T95UP.DAY
	,T95UP.InstanceName
	,AVG_UserProcesses
	,MAX_UserProcesses
	,AVG_SqlCompilations
	,MAX_SqlCompilations
	,AVG_SqlRecompilations
	,MAX_SqlRecompilations
	--,AVG_BatchesPerSecond
	--,MAX_BatchesPerSecond
	,UserProcesses_95Percentile






SELECT 
	T95SC.DAY
	,T95SC.InstanceName
	,AVG_UserProcesses
	,MAX_UserProcesses
	,AVG_SqlCompilations
	,MAX_SqlCompilations
	,AVG_SqlRecompilations
	,MAX_SqlRecompilations
	--,AVG_BatchesPerSecond
	--,MAX_BatchesPerSecond
	,UserProcesses_95Percentile
	,SqlCompilations_95Percentile
	,MAX(SqlRecompilations) as [SqlRecompilations_95Percentile]
--INTO #Temp95SqlRecompilations
FROM #Temp95SqlCompilations T95SC
	INNER JOIN #TEMPSqlRecompilations TSRC ON
	T95SC.DAY = TSRC.DAY
WHERE TSRC.Tile <> 20
GROUP BY T95SC.DAY
	,T95SC.InstanceName
	,AVG_UserProcesses
	,MAX_UserProcesses
	,AVG_SqlCompilations
	,MAX_SqlCompilations
	,AVG_SqlRecompilations
	,MAX_SqlRecompilations
	--,AVG_BatchesPerSecond
	--,MAX_BatchesPerSecond
	,UserProcesses_95Percentile
	,SqlCompilations_95Percentile
ORDER BY T95SC.DAY
	,T95SC.InstanceName
	,AVG_UserProcesses
	,MAX_UserProcesses
	,AVG_SqlCompilations
	,MAX_SqlCompilations
	,AVG_SqlRecompilations
	,MAX_SqlRecompilations
	--,AVG_BatchesPerSecond
	--,MAX_BatchesPerSecond
	,UserProcesses_95Percentile
	,SqlCompilations_95Percentile




	
--SELECT 
--	T95RSC.DAY
--	,T95RSC.InstanceName
--	,AVG_UserProcesses
--	,MAX_UserProcesses
--	,AVG_SqlCompilations
--	,MAX_SqlCompilations
--	,AVG_SqlRecompilations
--	,MAX_SqlRecompilations
--	,AVG_BatchesPerSecond
--	,MAX_BatchesPerSecond
--	,UserProcesses_95Percentile
--	,SqlCompilations_95Percentile
--	,SqlRecompilations_95Percentile
--	,MAX(Batches/60) as [BatchesPerSecond_95Percentile]
--FROM #Temp95SqlRecompilations T95RSC
--	INNER JOIN #TEMPBatches TB ON
--	T95RSC.DAY = TB.DAY
--WHERE TB.Tile <> 20
--GROUP BY T95RSC.DAY
--	,T95RSC.InstanceName
--	,AVG_UserProcesses
--	,MAX_UserProcesses
--	,AVG_SqlCompilations
--	,MAX_SqlCompilations
--	,AVG_SqlRecompilations
--	,MAX_SqlRecompilations
--	,AVG_BatchesPerSecond
--	,MAX_BatchesPerSecond
--	,UserProcesses_95Percentile
--	,SqlCompilations_95Percentile
--	,SqlRecompilations_95Percentile
--ORDER BY T95RSC.DAY
--	,T95RSC.InstanceName
--	,AVG_UserProcesses
--	,MAX_UserProcesses
--	,AVG_SqlCompilations
--	,MAX_SqlCompilations
--	,AVG_SqlRecompilations
--	,MAX_SqlRecompilations
--	,AVG_BatchesPerSecond
--	,MAX_BatchesPerSecond
--	,UserProcesses_95Percentile
--	,SqlCompilations_95Percentile
--	,SqlRecompilations_95Percentile




DROP TABLE #TEmpSQLServerStats
DROP TABLE #TEMPUserProcesses
DROP TABLE #TEMPSqlCompilations
DROP TABLE #TEMPSqlRecompilations
--DROP TABLE #TEMPBatches
DROP TABLE #Temp95UserProcesses
DROP TABLE #Temp95SqlCompilations
--DROP TABLE #Temp95SqlRecompilations

END
GO


