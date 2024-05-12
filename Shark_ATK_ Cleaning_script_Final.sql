--  Needed to import the file using the impor wizard
-- The currently the table name is Shark_table_Original 

--Only select 10 years old Data
-- Insert original Data to temp table
drop table #shark_table_1

--Creating a Working table (Temp table) using
Select * 
into #shark_table_1 
from Shark_table_Original ------------> Original table name


--Step 1 Delete the data where year and Date are null
Select Count(*) from [dbo].[#Shark_table_1] where year is null and date is null -- Record Count 58591 to be deleted
Delete  [dbo].[#Shark_table_1] where year is null and date is null -- Record Count deleted 58591


--Step 2 Fill the year field where the value is null --> needed to delete uneeded data
--Identify null year values
--Select * from [dbo].[#Shark_table_1] where  year is null order by year desc
update [dbo].[#Shark_table_1]-->881 records updated
Set year = right(date,4)
where year is null

-->Review the data again
--Select distinct year from  [dbo].[#Shark_table_1]  order by year asc

-- Look for values that dont start with 1 or 2 from the year field --> Incorrect year format  since previous I use a right function
Select distinct year from  [dbo].[#Shark_table_1] 
where left (year,1) not in ('1','2')--> to further identify errors after update
order by year asc

--> This are the Records under the year with errors --->    results 135
Select * from [dbo].[#Shark_table_1] 
where year in 
(
 '0000'
,'0005'
,'0077'
,'018.'
,'021`'
,'-202'
,'6.05'
)
order by year


--Review the data under this errors and since there are few records , they were manually updated the value was taken from the source field in the records
update [dbo].[#Shark_table_1]--> 4 records updated
Set year = 
Case when
year = '018.'	 then '2018'
when year='021`' then '2021'
when year='-202' then '2020'
when year='6.05' then '2017'
end
where year
in
(
 '018.'
,'021`'
,'-202'
,'6.05'
)

-- Review the others records with the year in error and we find that they are to old for what we needed 

Delete  [dbo].[#Shark_table_1] where --> 131 records deleted Old Data with errors
 year in (
 '0000'
,'0005'
,'0077'
)

---------> By this step all the year field issues were fixed <---------

--Select * from [dbo].[#Shark_table_1] where convert(int,year) >= 2000
-- Based on our project need, we wont needed the data that older than 2000
-- Deleting 4120 records
Delete  [dbo].[#Shark_table_1] where
 convert(int,year) < 2000

 
 -------> Now working with the Date field <---------

 --Eliminate space with nothing in the date field 263 records updated
 --update #Shark_table_1
 --set date = replace(date,' ','')
 ----------------------------------------------------------------------
 --Identify Error in the Date field--
 drop table #Date_format_Errors --> droping temp table in case of a re-run
 Select
 a.Date
 ,Convert(nvarchar(255),TRY_CONVERT(DATE, a.Date)) as 'New_Date'
 ,Cast('' as varchar(50)) as Validation
 into #Date_format_Errors
 from #shark_table_1 a

 Update #Date_format_Errors
 Set Validation= Case
 When New_Date is null then 'Invalid_Format'
 Else 'Valid_Format'
 End
 -- Finding 239 discrepancies in the field
 Select * from #Date_format_Errors where New_Date is null

--Pending Update
-- Standar Date Format
Update #Date_format_Errors
set New_Date = Convert(nvarchar,New_Date,101)
where New_Date is not null


--------------> Cleaning Process<-------------------
 Select * from #Date_format_Errors where New_Date is null order by date

-- identify missing hyphen in the 3 position 74 records
Select * from #Date_format_Errors where substring(date,3,1)=' ' and New_Date is null

Update #Date_format_Errors
set New_date = convert(varchar(255),replace (date,' ','-'))
where substring(date,3,1)=' '
and New_Date is null

--Reviewing results
Select * from #Date_format_Errors where Validation = 'Invalid_Format' and New_Date is not null

-- Double hyphe issue
Update #Date_format_Errors 
Set New_Date=replace(New_Date,'--','-')
where Validation = 'Invalid_Format'


Update #Date_format_Errors 
Set Validation='Valid_Format'
where Validation = 'Invalid_Format' and New_Date is not null

--Reviewing results
Select * from #Date_format_Errors 
where Validation = 'Invalid_Format' and New_Date is null
order by date

-- Fixing String in the field (Reported)
-----> Need to work on some other records that are affected by this update

Update #Date_format_Errors
Set New_Date = right(Date,11)
Where Date like ('%Reported%')and Validation = 'Invalid_Format'

--> Double hyphen records
update #Date_format_Errors 
Set New_Date= replace(Date,'--','-')
where Validation = 'Invalid_Format' and New_Date is null
and Date like ('%--%')

--> Missing first 3 characters
update #Date_format_Errors 
set New_Date= '01-'+Date
where Validation = 'Invalid_Format' and New_Date is null
and len(date)=8

-- String Early in the Date
Update #Date_format_Errors 
Set New_date = Replace(Date,'Early ','01-')
where Validation = 'Invalid_Format' and New_Date is null
and Date like ('%Early %')


-- String Late in the Date
Update #Date_format_Errors 
Set New_date = Replace(Date,'Late ','29-')
where Validation = 'Invalid_Format' and New_Date is null
and Date like ('%Late %')

-- Replacing space for hyphen 
-- > this affect other record need to work on those
update #Date_format_Errors 
set New_Date= replace(date,' ','-')
where Validation = 'Invalid_Format' and New_Date is null
and Date like ('% %')


--Reviewing results
Select * from #Date_format_Errors 
where Validation = 'Invalid_Format' and New_Date is null
order by date

	-- updated manually 
	Update #Date_format_Errors
	Set New_Date=
	Case 
	--when Date ='Fall-2008' then '12-Dec-2008'
	when Date ='29-Nov2013' then '29-Nov-2013'--
	when Date ='09-Jul-2006.' then '09-Jul-2006'--
	when Date ='13-May2014' then '13-May-2014'--	
	when Date ='02-Ap-2001' then '02-Apr-2001'--
	when Date ='20-May2015' then '20-May-2015'--
	when Date ='19-Jul-2007.b' then '19-Jul-2007'--
	when Date ='19-Jul-2007.a' then '19-Jul-2007'--
	when Date ='24-Nov-2005-3' then '24-Nov-2005'
	when Date ='11-Dec-2021`' then '11-Dec-2021'--
	when Date ='15-Nox-2021'  then '15-Nov-2021'--
	when Date ='190Feb-2010'  then '19-Feb-2010'--
	when Date ='24-Nov-2005-'  then '24-Nov-2005'--
	when Date ='Summer-2008'  then '01-Jul-2008'--
	End
	where New_date is null

-- Update Manually
	Update #Date_format_Errors
	Set New_Date= '12-Dec-2008'
	where date ='Fall 2008' 

drop table #Date_format_V2 --> droping temp table in case of a re-run
 Select
 a.Date as Original_Date
 ,a.New_Date
 ,Convert(nvarchar(255),TRY_CONVERT(DATE, a.New_Date)) as Date_Format_test
 ,Cast('' as varchar(50)) as Validation
 into #Date_format_V2
 from #Date_format_Errors a

 Update #Date_format_V2
 Set Validation= Case
 When Date_Format_test is null then 'Invalid_Format'
 Else 'Valid_Format'
 End

 Select * from #Date_format_V2 where Validation !='Valid_Format'

 -- Manual Updates
 Update #Date_format_V2
 Set New_Date=
 Case when Original_Date = 'Reported 14-June 2023' then '14-Jun-2023'
	  when Original_Date = 'Reported 14 Jul-2023' then '14-Jul-2023'
	  when Original_Date = 'Reported 09-Jul-2018.' then '09-Jul-2018'
	  when Original_Date = ' 19-Jul-2004 Reported to have happened  "on the weekend"' then '19-Jul-2004'
	  when Original_Date = 'Reported 12-Jan 2011' then '12-Jan-2011'
	  when Original_Date = 'Reported 02 Nov-2023' then '02-Nov-2023'
 end
 Where Date_Format_test is null

 --Final Review
 Select
 a.Original_Date
 ,a.New_Date
 ,Convert(nvarchar(255),TRY_CONVERT(DATE, a.New_Date)) as Date_Format_test
 into #temp
 from #Date_format_V2 a

 Select * from #temp where Date_Format_test is null

Delete from #Shark_table_1 where date = '2007.'
Delete from #Date_format_V2 where Original_Date = '2007.'


update #Shark_table_1 
set Date= b.New_Date
from #Date_format_V2 b
inner join #Shark_table_1 a
on a.Date=b.Original_Date

--Data Period per Project
Select * from #Shark_table_1 
where month(Date) in (5,6,7,8)


