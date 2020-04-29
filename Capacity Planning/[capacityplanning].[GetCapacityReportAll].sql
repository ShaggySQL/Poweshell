USE [DBA_Admin]
GO

/****** Object:  StoredProcedure [capacityplanning].[GetCapacityReportAll]    Script Date: 11/12/2019 10:17:11 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [capacityplanning].[GetCapacityReportAll] @InstanceName as varchar(200), @UTCFromDate as datetime, @UTCToDate as datetime
	AS
	  --		DECLARE @InstanceName as varchar(200)
			--DECLARE @UTCFromDate as datetime
			--DECLARE @UTCToDate as datetime
			--SET @InstanceName = 'NWFLOTSQL031,49879'
			--SET @UTCFromDate = '2019-10-16'
			--SET @UTCToDate = '2019-10-17'
			select ss.UTCCollectionDateTime,ms.InstanceName, ss.CPUActivityPercentage ,oss.OSAvailableMemoryInKilobytes/1024 AS OSAvailableMemoryInMegabytes,
				sum(AverageDiskQueueLength) AverageDiskQueueLength,
				sum(dd.DiskReadsPerSecond) DiskReadsPerSecond,
				sum(dd.DiskWritesPerSecond) DiskWritesPerSecond ,
				sq.TotalWaitTimeInMinutes
				,ss.Transactions/60 as SQLTransactionsPerSecond, ss.BlockedProcesses
		  from  [SQLdmRepository].[dbo].[ServerStatistics] ss
		  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
		  ss.SQLServerID = ms.SQLServerID
		  INNER JOIN [SQLdmRepository].[dbo].OSStatistics oss ON
		  oss.SQLServerID = ms.SQLServerID AND oss.UTCCollectionDateTime = ss.UTCCollectionDateTime
		  INNER JOIN [SQLdmRepository].[dbo].DiskDrives dd ON
		  dd.SQLServerID = ms.SQLServerID AND dd.UTCCollectionDateTime = ss.UTCCollectionDateTime
		  INNER JOIN 
		  (
					  SELECT
					ws.UTCCollectionDateTime
					,ms.InstanceName
					,sum(wsd.WaitTimeInMilliseconds)/1000/60 AS TotalWaitTimeInMinutes
					  FROM [SQLdmRepository].[dbo].[WaitStatistics] ws
					  INNER JOIN [SQLdmRepository].[dbo].WaitStatisticsDetails wsd ON
					  ws.WaitStatisticsID = wsd.WaitStatisticsID
					  Inner JOin [SQLdmRepository].[dbo].WaitTypes wt ON
					  wsd.WaitTypeID = wt.WaitTypeID
					  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
					  ws.SQLServerID = ms.SQLServerID
					 WHERE ms.InstanceName = @InstanceName
					 AND ws.UTCCollectionDateTime BETWEEN @UTCFromDate AND @UTCToDate
					 group by ws.UTCCollectionDateTime,ms.InstanceName
		  ) as sq ON sq.UTCCollectionDateTime = ss.UTCCollectionDateTime AND sq.InstanceName = ms.InstanceName
		  where ms.InstanceName = @InstanceName AND ss.UTCCollectionDateTime Between @UTCFromDate AND @UTCToDate 
		  group by ss.UTCCollectionDateTime,ms.InstanceName,ss.CPUActivityPercentage ,oss.OSAvailableMemoryInKilobytes,sq.TotalWaitTimeInMinutes,ss.Transactions, ss.BlockedProcesses
		  order by ms.InstanceName,ss.UTCCollectionDateTime,sq.TotalWaitTimeInMinutes desc

GO


