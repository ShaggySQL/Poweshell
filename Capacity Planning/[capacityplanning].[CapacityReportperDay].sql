USE [DBA_Admin]
GO

/****** Object:  StoredProcedure [capacityplanning].[CapacityReportperDay]    Script Date: 11/12/2019 10:03:09 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [capacityplanning].[CapacityReportperDay] @InstanceName as varchar(200), @UTCDate as datetime
	AS
	  select  CONVERT(VARCHAR(13), ss.UTCCollectionDateTime, 120) as DAYandHour,ms.InstanceName,avg(ss.CPUActivityPercentage ) CPUActivityPercentage ,
				avg(oss.OSAvailableMemoryInKilobytes ) OSAvailableMemoryInKilobytes
				,avg(ss.PageLifeExpectancy) PageLifeExpectancy
				,avg(ss.Batches/60 ) as BatchesPerSecond,
				avg(ss.Transactions/60 ) as SQLTransactionsPerSecond,
				avg(AverageDiskQueueLength) as AverageDiskQueueLength,
				avg(dd.DiskReadsPerSecond) as DiskReadsPerSecond,
				avg(dd.DiskWritesPerSecond) as DiskWritesPerSecond 
		  from  [SQLdmRepository].[dbo].[ServerStatistics] ss
		  INNER JOIN [SQLdmRepository].[dbo].MonitoredSQLServers ms ON
		  ss.SQLServerID = ms.SQLServerID
		  INNER JOIN [SQLdmRepository].[dbo].OSStatistics oss ON
		  oss.SQLServerID = ms.SQLServerID AND oss.UTCCollectionDateTime = ss.UTCCollectionDateTime
		  INNER JOIN [SQLdmRepository].[dbo].DiskDrives dd ON
		  dd.SQLServerID = ms.SQLServerID AND dd.UTCCollectionDateTime = ss.UTCCollectionDateTime
		 where ms.InstanceName = @InstanceName AND CAST(ss.[UTCCollectionDateTime] as Date) = @UTCDate 
		  AND ss.CPUActivityPercentage IS NOT NULL
		  AND ss.Transactions IS  NOT NULL
		  AND oss.OSAvailableMemoryInKilobytes IS NOT NULL
		  --AND ss.Transactions/60 < 2000
		  --AND ss.Transactions/60 >1000
		  group by CONVERT(VARCHAR(13), ss.UTCCollectionDateTime, 120) ,ms.InstanceName
		  order by ms.InstanceName,DAYandHour

GO


