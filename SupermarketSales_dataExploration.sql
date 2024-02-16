/*
SalesMarket Data Exploration 

Skills used: Faster data load ,Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

Please note that for items which are returned are present with negative [Unit Selling Price (RMB kg)] , also [Unit Selling Price (RMB kg)] is {price per kg} is given
*/
/*Data to be used*/
select distinct [Item Code],[Item Name],[Category Name] from dbo.itemdetails(nolock)

select distinct CAST([date]+' '+[Time] as datetime) as [CreatedDatetime],[Item Code],[Quantity Sold (kilo)],[Unit Selling Price (RMB kg)],[Sale or Return],[Discount (Yes No)] 
from dbo.Sales(nolock)

select [Item Code],[Wholesale Price (RMB kg)] from dbo.ItemsWithwhosesaleprice(nolock)

/* Datset with large volume of data (8M+) hence for faster data load index created*/
alter table dbo.Sales add SalesID bigint identity(1,1)
create index sales_idx on dbo.Sales([item code],[Date])

/*Details of item for which discount is given*/
select distinct id.[Item Name],s.[Item Code],id.[Category Name]
from dbo.Sales s(nolock)
inner join dbo.itemdetails id(nolock) on id.[Item Code]=s.[Item Code]
where 1=1
and LTRIM(RTRIM([Discount (Yes No)]))='Yes'
order by 1

/*Number of orders that are either returned or sold*/
select Count(SalesID) As [Count of Orders],[Sale or Return]
from dbo.Sales(nolock)
group by [Sale or Return]

/* List of items that are returned */

select distinct i.[Item Code],i.[Item Name]
from dbo.Sales s(nolock)
inner join dbo.ItemDetails i(nolock) on i.[Item Code]=s.[Item Code]
where LTRIM(RTRIM([Sale or Return]))='Return'

/* List of items that have never been returned */

select distinct i.[Item Code],i.[Item Name]
from dbo.Sales s(nolock)
inner join dbo.ItemDetails i(nolock) on i.[Item Code]=s.[Item Code]
where LTRIM(RTRIM([Sale or Return]))='Sale'
and not exists(
	select top 1 1 from dbo.Sales s1(nolock) 
	where s1.[Sale or Return]='Return' 
	and s.[Item Code]=s1.[Item Code]
)

/* List of items that are returned along with number of times it has been returned (frequency of return)*/

select  i.[Item Code],i.[Item Name], COUNT(i.[Item Code]) [Count of how may times item has been returned]
from dbo.Sales s(nolock)
inner join dbo.ItemDetails i(nolock) on i.[Item Code]=s.[Item Code]
where [Sale or Return]='Return'
group by i.[Item Code],i.[Item Name]
order by 3 desc

/* List of items that are returned along with number of times which has been returned (frequency of return) more than or equal to 10 times*/

select  i.[Item Code],i.[Item Name], COUNT(i.[Item Code]) [Count of how may times item has been returned]
from dbo.Sales s(nolock)
inner join dbo.ItemDetails i(nolock) on i.[Item Code]=s.[Item Code]
where [Sale or Return]='Return'
group by i.[Item Code],i.[Item Name]
having  COUNT(i.[Item Code]) >=10
order by 3 desc

/*3rd highest top selling product in terms of revenue*/
select *
from (
	select distinct s.[Item Code], i.[Item Name],
	DENSE_RANK () over (ORDER BY SUM(CAST([Quantity Sold (kilo)] as decimal(16,2))*cast([Unit Selling Price (RMB kg)] as decimal(16,2))) ) as [Rank]
	from Sales s(nolock)
	inner join itemdetails i(nolock) on i.[Item Code]=s.[Item Code]
	group by s.[Item Code],i.[Item Name]
) as subquery
where [Rank]=3

/*Revenue generated per year*/
select distinct YEAR(cast(s.Date as date)) as [Year],
(
	SUM(CAST([Quantity Sold (kilo)] as decimal(16,2))*cast([Unit Selling Price (RMB kg)] as decimal(16,2))) 
) as [Revenue generated per year]
from dbo.Sales s(nolock)
group by YEAR(cast(s.Date as date))


/*detail of Item that are generating most revenue  */
select [Item Code],SUM(CAST([Quantity Sold (kilo)] as decimal(16,2))*cast([Unit Selling Price (RMB kg)] as decimal(16,2))) as [Price]
from dbo.Sales s(nolock)
--where [Sale or Return]='Sale'
group by [Item Code]
order by 2

/*faster result through CTE*/
;with cte as(
	select i.[Item Code],i.[Item Name],CAST([Quantity Sold (kilo)] as decimal(16,2))*cast([Unit Selling Price (RMB kg)] as decimal(16,2)) as [Price]
	from dbo.Sales s(nolock)
	inner join dbo.ItemDetails i(nolock) on i.[Item Code]=s.[Item Code]
	--where [Sale or Return]='Sale'
)
select [Item Name],[Item Code], SUM([Price]) as [Revenue created by Particular item]
from cte c
group by [Item Code],[Item Name]
order by [Revenue created by Particular item] desc

/*faster result through Temp table */
drop table if exists #HighestRevenue

/*
CREATE TABLE #HighestRevenue
(
[Item Code] varchar(50)
,Price decimal(16,2)
)
*/

select i.[Item Code],i.[Item Name],CAST([Quantity Sold (kilo)] as decimal(16,2))*cast([Unit Selling Price (RMB kg)] as decimal(16,2)) as [Price]
INTO #HighestRevenue
from dbo.Sales s(nolock)
inner join dbo.ItemDetails i(nolock) on i.[Item Code]=s.[Item Code]
--where [Sale or Return]='Sale'

select [Item Name],[Item Code], SUM([Price]) as [Revenue created by Particular item]
from #HighestRevenue
group by [Item Code],[Item Name]
order by [Revenue created by Particular item] desc

/* revenue per category per year*/

	CREATE VIEW RevenuePerCategoryPerYear As 
	select distinct YEAR(cast(s.Date as date)) as [Year],
		i.[Category Name],
		SUM(CAST([Quantity Sold (kilo)] as decimal(16,2))*cast([Unit Selling Price (RMB kg)] as decimal(16,2))) as [TotalRevenue]
		from dbo.Sales s(nolock)
		inner join dbo.itemdetails i(nolock) on i.[Item Code]=s.[Item Code]
		group by YEAR(cast(s.Date as date)),i.[Category Name]

		select * from RevenuePerCategoryPerYear