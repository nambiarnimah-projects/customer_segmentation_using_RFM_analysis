create database rfm;
use rfm;
create table rfm1(RowID int primary key,
OrderID varchar(50),
OrderDate date,
ShipDate date,
ShipMode varchar(50),
CustomerID varchar(50),
CustomerName varchar(50),
Segment varchar(50),
Country varchar(50),
City varchar(50),
State varchar(50),
PostalCode varchar(50) ,
Region varchar(50),
ProductID varchar(50),
Category varchar(50),
SubCategory varchar(50),
ProductName varchar(100),
Sales decimal(10,2));
select * from rfm1;
show tables;

-- create a RFM table
select customerid,(current_date()-max(orderdate)) as recency,count(orderid) as frequency,sum(sales) as monetary from rfm1 group by customerid order by recency,frequency,monetary;
-- create customer segments
select customerid,recency,frequency,monetary,ntile(5)over(order by recency desc) as rscore,ntile(5) over (order by frequency) as fscore,ntile(5) over(order by monetary) as mscore from 
(select customerid,(current_date()-max(orderdate)) as recency,count(orderid) as frequency,sum(sales) as monetary from rfm1 group by customerid) as rfm1; 


-- generating rfm scores
select customerid,concat(rscore,fscore,mscore) as rfmscore from
(select customerid,recency,frequency,monetary,ntile(5)over(order by recency desc) as rscore,ntile(5) over (order by frequency) as fscore,ntile(5) over(order by monetary) as mscore from 
(select customerid,(current_date()-max(orderdate)) as recency,count(orderid) as frequency,sum(sales) as monetary from rfm1 group by customerid) as rfmbase) as ntile1; 


-- catergorize the customers into groups
select customerid,rfmscore,case
when (rscore>=4 and fscore>=4 and mscore>=4) then 'best customers'
when (fscore>=4 and rscore>=3) then 'loyal customers'
when (mscore>=4 and fscore<=3)then 'big spenders'
when (rscore=5 and fscore<=2) then 'new customers'
when (rscore>=2 and fscore>=2 and mscore>=2) then 'regular customer'
when(rscore<=2 and fscore>=3) then ' at risk'
else'lost customers'
end as segment from
(select customerid,concat(rscore,fscore,mscore) as rfmscore,rscore,fscore,mscore from
(select customerid,recency,frequency,monetary,ntile(5)over(order by recency desc) as rscore,ntile(5) over (order by frequency) as fscore,ntile(5) over(order by monetary) as mscore from 
(select customerid,(current_date()-max(orderdate)) as recency,count(orderid) as frequency,sum(sales) as monetary from rfm1 group by customerid) as rfmbase) as ntile1) as categories;

create view final as
select customerid,rfmscore,recency,frequency,monetary,case
when (rscore>=4 and fscore>=4 and mscore>=4) then 'best customers'
when (fscore>=4 and rscore>=3) then 'loyal customers'
when (mscore>=4 and fscore<=3)then 'big spenders'
when (rscore=5 and fscore<=2) then 'new customers'
when (rscore>=2 and fscore>=2 and mscore>=2) then 'regular customer'
when(rscore<=2 and fscore>=3) then ' at risk'
else'lost customers'
end as segment from
(select customerid,recency,frequency,monetary,concat(rscore,fscore,mscore) as rfmscore,rscore,fscore,mscore from
(select customerid,recency,frequency,monetary,ntile(5)over(order by recency desc) as rscore,ntile(5) over (order by frequency) as fscore,ntile(5) over(order by monetary) as mscore from 
(select customerid,(current_date()-max(orderdate)) as recency,count(orderid) as frequency,sum(sales) as monetary from rfm1 group by customerid) as rfmbase) as ntile1) as categories; 
-- (used view to create a table of the above sub queries) 

-- BUSINESS QUESTIONS
-- 1. number of customers per segment
select segment,count(customerid) from final group by segment; 

-- 2.revenue per segment
select segment,sum(monetary) as totalrevenue from final group by segment;

-- 3.which segment contributes the highest total revenue
select segment ,sum(monetary) as total from final group by segment order by total desc ;

-- 4. how frequently does each segment purchase
select segment ,avg(frequency) as total from final group by segment order by total desc ;

-- 5. how many customers are at risk or lost
select segment,count(*) from final where segment in (' at risk','lost customers') group by segment; 

-- 6.which segmnet purchased most recently
select segment,avg(recency) as rec from final group by segment order by rec;

-- 7.
select segment,round((sum(monetary))/(select sum(monetary) from final)*100,2) as percent from final group by segment order by percent desc ;