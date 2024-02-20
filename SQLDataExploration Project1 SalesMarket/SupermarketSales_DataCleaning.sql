/* Data cleaning checks*/

/*


*/
--no entry in sales table present where quantity sold or unit selling price or item code or date on which it was bought  is null or empty 
-- 
select *
from dbo.sales(nolock)
where ISNULL([Quantity Sold (kilo)],'')=''
or ISNULL([Unit Selling Price (RMB kg)],'')=''
or isnull([Item Code],'')=''
or isnull([date],'')=''

--only distinct values are present in [sale or return] & [discount yes or no]
-- 
select distinct [Sale or Return]
from dbo.Sales(nolock)

select distinct [Discount (Yes No)]
from dbo.Sales(nolock)

--no entry in ItemsWithWhoseSalePrice table present where Wholesale Price or item code or date on which it was bought  is null or empty 
-- 
select *
from dbo.ItemsWithWhoseSalePrice(nolock)
where isnull([Wholesale Price (RMB kg)],'')=''
or isnull([Item Code],'')=''
or isnull([date],'')=''

--no entry in ItemsWithWhoseSalePrice table present where item name or item code or category name is null or empty 
-- 
select *
from dbo.itemdetails(nolock)
where isnull([Item Name],'')=''
or isnull([Item Code],'')=''
or isnull([Category Name],'')=''

/* finding duplicates - none found */
;with cte as (
select *, ROW_NUMBER() over (
partition by 
[Date]
,[Item Code]
,[Quantity Sold (kilo)]
,[Unit Selling Price (RMB kg)]
,[Sale or Return]
,[Discount (Yes No)]
order by salesid
) as RowNo
from dbo.Sales(nolock)
)
select *
from cte c
where [RowNo]>1

