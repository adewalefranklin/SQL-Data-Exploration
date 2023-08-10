--data inspection
select* from projectportfolio..sales_data_sample

--checking unique values
select distinct status from sales_data_sample -- for subsequent visualisation
select distinct YEAR_ID from sales_data_sample
select distinct productline from sales_data_sample--for subsequent visualisation
select distinct COUNTRY from sales_data_sample -- for subsequent visualisation
select distinct DEALSIZE from sales_data_sample --for subsequent visualisation
select distinct TERRITORY from sales_data_sample -- for subsequent visualisation

-- sales grouping by product line

select productline, SUM(sales) as Revenue
from projectportfolio..sales_data_sample
group by PRODUCTLINE
order by 2 desc

-- sales across the years ( to know which year they made the most revenue)

select YEAR_ID, SUM(sales) as REVENUE
from projectportfolio..sales_data_sample
group by YEAR_ID
order by 2 desc

-- it appears the revenue in 2005 reduced significantly and therefore, we want to know if there is a reason or trend responssible for that

select distinct MONTH_ID 
from projectportfolio..sales_data_sample
where YEAR_ID = '2005' ---- from the result of this query, it shows the firm only operated for 5 months in 2005

--sales grouping by dealsize

select DEALSIZE, SUM(sales) as Revenue
from projectportfolio..sales_data_sample
group by DEALSIZE
order by 2 desc

-- Month with the highest sales and how much was made 

select MONTH_ID, SUM(sales) as Revenue, COUNT(ORDERNUMBER) as Frequency
from projectportfolio..sales_data_sample
where YEAR_ID = '2003'
group by MONTH_ID
order by 2 desc

--from the above result, November looks to be the most that generates more revenue every year and the product was classic car as shown below from the query result 

select MONTH_ID, productline, SUM(sales) as Revenue, COUNT(ORDERNUMBER) as Frequency
from projectportfolio..sales_data_sample
where YEAR_ID = '2003'and month_id = '11'
group by MONTH_ID, productline 
order by 3 desc

--To know who our best customer is using the RFM Analysis Method
drop table if exists #rfm
 with rfm as -- Using CTE Expression
(
select 
    customername, 
    SUM(sales) as monetaryvalue, 
    AVG(sales) as AverageMonetaryValue,
    COUNT(ORDERNUMBER) as Frequency,
    MAX(orderdate)as last_order_date,
    (select max(orderdate) from projectportfolio..sales_data_sample) as Max_order_date,
    DATEDIFF(DD,MAX(orderdate),(select max(orderdate) from projectportfolio..sales_data_sample)) as recency
from projectportfolio..sales_data_sample
group by customername
),
rfm_calc as 
(
select r.*,
 NTILE(4) OVER (order by recency desc) as rfm_recency,
 NTILE(4) OVER (order by  Frequency) as rfm_frequency,
 NTILE(4) OVER (order by MonetaryValue) as rfm_monetary
from rfm r
)
select c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell, 
CAST(rfm_recency as varchar)+ cast (rfm_frequency as varchar)+ cast (rfm_monetary as varchar) as rfm_cell_string
into 
#rfm
from rfm_calc c

select* from #rfm

select customername, rfm_recency, rfm_frequency, rfm_monetary,
case
when  rfm_cell_string in (111, 112, 121, 122, 123, 132, 211, 212,114, 141) then 'lost customers'-- (lost customers)
when  rfm_cell_string in (133, 134, 143, 144, 244, 334, 343, 344) then 'slipping away, cannot lose'-- (big buyers that have not recently make purchase)
when  rfm_cell_string in (311, 411, 331) then 'new customers'
when  rfm_cell_string in (222, 223, 233, 322) then 'potential customers'
when  rfm_cell_string in (323, 333, 321, 422, 332, 432) then 'active' -- customers who buy often and recently but at a low price points)
when  rfm_cell_string in (433, 434, 443, 444) then 'loyal'
end as rfm_segment
from #rfm

-- products that are often most sold together 
--select * from projectportfolio..sales_data_sample where ORDERNUMBER = 10411


select distinct ordernumber, STUFF(

      (select ',' + PRODUCTCODE from projectportfolio..sales_data_sample as p
       where ORDERNUMBER in 
(
select ordernumber 
from
(
   select ordernumber, COUNT(*) as rn
   from projectportfolio..sales_data_sample 
   where status = 'shipped'
   group by ORDERNUMBER
)as m
where rn = 2
and p.ORDERNUMBER = s.ORDERNUMBER
 )
for xml path (''))
,1, 1, '') as productcodes
from projectportfolio..sales_data_sample as s
order by 2 desc
