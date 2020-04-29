set nocount on 
set quoted_identifier off
if object_id('tempdb..##SQLCheck') is not null
	drop table ##SQLCheck
create table ##SQLCheck ( c1Server varchar(40),
	c2type varchar(50),
	c3state varchar(20),
	c3Description varchar(2000))

-- SELECT * FROM #SQLCheck
/******** Checking the database availability ************/
Insert into  ##SQLCheck 
select LEFT(@@SERVERNAME,30),'SQLServer','ONLINE','OK'
--- Add Version
Insert into  ##SQLCheck 
select LEFT(@@SERVERNAME,30),'Version','INFO',SUBSTRING(@@VERSION,0,CHARINDEX(CHAR(9),@@VERSION))

Insert into  ##SQLCheck 
select LEFT(@@SERVERNAME,30),'Database','WARNING/ERROR','Database ['+name+'] is in  '+char(39)+convert(varchar,DATABASEPROPERTYEX( name , 'status' ))++char(39)+' State...Please Check'
from sysdatabases
where DATABASEPROPERTYEX( name , 'status' ) <> 'ONLINE'
if @@rowcount=0
begin
	Insert into  ##SQLCheck 
	select LEFT(@@SERVERNAME,30),'All Databases','ONLINE','OK'
end


/**** Parsing SQL Server Error log *******************/
declare @sql nvarchar(4000)
if object_id('tempdb..##temp01') is not null
	drop table ##temp01

--Satish Kartan -- Modifications for compatibility with SQL 2000/2005/2008
If left(cast(isnull(serverproperty('ProductVersion'),'') as varchar),1) = '8' 
	begin
		set @sql = 'create table ##temp01 ( c0 int identity, [desc] varchar(1000), c2 smallint)'
		exec sp_executesql @sql
		insert into ##temp01 exec master..xp_readerrorlog
		set @sql = 'Insert into  ##SQLCheck select LEFT(@@SERVERNAME,30),''SQL Log'',''WARNING/ERROR'','
		set @sql = @sql + " ltrim(rtrim([desc])) as 'Errors in SQL Startup log' "
	end
else	
	begin
	--print '2005 or above'
		set @sql = 'create table ##temp01 (LogDate datetime, UserID varchar(50), [desc] varchar(2000))'
		exec sp_executesql @sql
		insert into ##temp01 exec master..xp_readerrorlog
		set @sql = 'Insert into  ##SQLCheck select LEFT(@@SERVERNAME,30),''SQL Log'',''WARNING/ERROR'','
		set @sql = @sql + " ltrim(rtrim([desc])) + ' ' + cast(LogDate as varchar) + ' ' + UserID as 'Errors in SQL Startup log' "
	end

set @sql = @sql + ' from ##temp01 '
set @sql = @sql + ' where [desc] like ''%consistency-based I/O error%''  '
set @sql = @sql + ' or [desc] like ''%found [1-65536] errors%'' '
set @sql = @sql + ' or [desc] like ''%corrupt%'' '
set @sql = @sql + ' or [desc] like ''%file control bank%'' '
set @sql = @sql + ' or [desc] like ''%out of memory%'' '
--set @sql = @sql + ' or [desc] like ''%Operating system error%'' '
--set @sql = @sql + ' or [desc] like ''%failed%'' '
set @sql = @sql + ' or [desc] like ''%non-yielding%'' '
set @sql = @sql + ' or [desc] like ''%exception%'' '
set @sql = @sql + ' or [desc] like ''%Contact Technical Support%'' '

--Uncomment the following line if you wish to perform an exhaustive check
--set @sql = @sql + ' or [desc] in (select description from sysmessages with (nolock) where msglangid = 1033 and severity > 17)   '

--print @sql
--exec @sql		
exec sp_executesql @sql

/******** Checking whether SQL Agent is up and running *****/
if ( @@version not like '%Express Edition%')
begin
	if exists ( select * from sys.dm_server_services
		where servicename like '%SQL Server Agent%' and status_desc='Running')
		Insert into  ##SQLCheck select LEFT(@@SERVERNAME,30),'SQL AGENT','ONLINE','OK'
	else
		Insert into  ##SQLCheck select LEFT(@@SERVERNAME,30),'SQL AGENT','ERROR','SQL AGENT ON ['+@@SERVERNAME+'] IS DOWN'
end

if object_id('tempdb..##temp01') is not null
	drop table ##temp01

/************ Checking whether SQL Servers are running on the same node or not ***********/
if exists ( SELECT * FROM ::fn_virtualservernodes())
begin
	declare @cnt smallint
	--PRINT '<<<<<'+@@SERVERNAME+'>>>>> IS A CLUSTERED SQL SERVER'
	declare @Physervers varchar(200)
	SET @Physervers=''
	SELECT @Physervers=@Physervers+Nodename+',' FROM ::fn_virtualservernodes()
	select @Physervers=left(@Physervers,len(@Physervers)-1)
	-- Added by Raj 6/16/2014
	Insert into  ##SQLCheck select LEFT(@@SERVERNAME,30),'SQLServer','INFO','SQL RESIDING ON ['+convert(varchar,SERVERPROPERTY ( 'ComputerNamePhysicalNetBIOS')) +']. Physical Servers:'+@Physervers
	PRINT 'SQL IS RESIDING ON <<<<<'+convert(varchar,SERVERPROPERTY ( 'ComputerNamePhysicalNetBIOS')) +'>>>>>'
	create table #tempnet ( c1 varchar(100))
	-- Uncomment below, if the server is configured to all xp_cmdshell
	--insert into #tempnet  exec master..xp_cmdshell 'net start'
	select @cnt = count(*) from #tempnet where LEFT(ltrim(rtrim(c1)),5) ='MSSQL'
	if @cnt > 1
		PRINT '!!!!!!!!!!!!WARNING !!!!!!!!!! BOTH THE SQL SERVERS ARE RUNNING ON THE SAME NODE'
	drop table #tempnet 
	

end
SELECT * FROM ##SQLCheck 

