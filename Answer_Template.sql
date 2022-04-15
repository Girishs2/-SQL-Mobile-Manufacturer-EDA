--SQL Advance Case Study

create database mbl_manufacturer

select * from DIM_CUSTOMER
select * from DIM_DATE
select * from DIM_LOCATION
select * from DIM_MANUFACTURER
select * from DIM_MODEL
select * from FACT_TRANSACTIONS


--Q1--BEGIN 

select distinct l.State from FACT_TRANSACTIONS t left join DIM_LOCATION l
on t.IDLocation = l.IDLocation
where year(t.Date) > 2005

--Q1--END

--Q2--BEGIN
	
select top 1 l.State, sum(t.Quantity) [qty_sold] from FACT_TRANSACTIONS t left join DIM_LOCATION l
on t.IDLocation = l.IDLocation left join DIM_MODEL m on t.IDModel = m.IDModel 
left join DIM_MANUFACTURER mn on m.IDManufacturer = mn.IDManufacturer
where Manufacturer_Name = 'Samsung' and l.Country = 'US'
group by l.State
order by sum(t.Quantity) desc

--Q2--END

--Q3--BEGIN      

select t.IDModel, l.ZipCode, l.State, count(*) as number_of_transactions
from FACT_TRANSACTIONS t left join DIM_LOCATION l on t.IDLocation = l.IDLocation
group by t.IDModel, l.ZipCode, l.State

--Q3--END

--Q4--BEGIN

select top 1 mn.Manufacturer_Name, m.Model_Name, min(m.Unit_price) Price
from  DIM_MODEL m left join DIM_MANUFACTURER mn on m.IDManufacturer = mn.IDManufacturer
group by mn.Manufacturer_Name, m.Model_Name

--Q4--END

--Q5--BEGIN

select IDManufacturer, IDModel, avg(Unit_price) [avg_price] from DIM_MODEL
where IDManufacturer in
	(
	select top 5 IDManufacturer from FACT_TRANSACTIONS t left join DIM_MODEL m on t.IDModel = m.IDModel
	group by IDManufacturer
	order by sum(Quantity) desc
	)
group by IDManufacturer,  IDModel
order by avg(Unit_price) desc

--Q5--END

--Q6--BEGIN

select Customer_Name,avg(TotalPrice) [Avg_amt_spent]
from FACT_TRANSACTIONS t left join DIM_CUSTOMER c on t.IDCustomer = c.IDCustomer
where year(Date) = 2009
group by Customer_Name
having avg(TotalPrice) > 500

--Q6--END
	
--Q7--BEGIN  

select m.IDModel, Model_Name, Manufacturer_Name from DIM_MODEL m left join DIM_MANUFACTURER mn
on m.IDManufacturer = mn.IDManufacturer
where m.IDModel in
				(
				select idmodel from
					(select top 5 IDModel, sum(Quantity) [qty_sold] from FACT_TRANSACTIONS
					where year(Date)=2008
					group by IDModel
					order by sum(Quantity) desc) as t1
				intersect
				select idmodel from
					(select top 5 IDModel, sum(Quantity) [qty_sold] from FACT_TRANSACTIONS
					where year(Date)=2009
					group by IDModel
					order by sum(Quantity) desc) as t2
				intersect
				select idmodel from
					(select top 5 IDModel, sum(Quantity) [qty_sold] from FACT_TRANSACTIONS
					where year(Date)=2010
					group by IDModel
					order by sum(Quantity) desc) as t3
					)

--Q7--END	

--Q8--BEGIN

select Manufacturer_Name, [year], [Qty_sold]
from 
	(
		select Manufacturer_Name,year(date) [year], sum(Quantity) [Qty_sold] from FACT_TRANSACTIONS t left join DIM_MODEL m 
		on t.IDModel = m.IDModel left join DIM_MANUFACTURER mn on m.IDManufacturer = mn.IDManufacturer
		where year(Date) = '2009'
		group by Manufacturer_Name, year(date)
		order by sum(Quantity) desc
		offset 1 row
		fetch next 1 row only
	union all
		select Manufacturer_Name,  year(date) [year], sum(Quantity) [Qty_sold] from FACT_TRANSACTIONS t left join DIM_MODEL m 
		on t.IDModel = m.IDModel left join DIM_MANUFACTURER mn on m.IDManufacturer = mn.IDManufacturer
		where year(Date) = '2010'
		group by Manufacturer_Name, year(date)
		order by sum(Quantity) desc
		offset 1 row
		fetch next 1 row only
	) as t1

--Q8--END

--Q9--BEGIN

select Manufacturer_Name from DIM_MANUFACTURER 
where IDManufacturer in
					(
					select distinct IDManufacturer from FACT_TRANSACTIONS t left join DIM_MODEL m on t.IDModel = m.IDModel
					where (year(date) = '2010') 
					group by IDManufacturer
			except
					select distinct IDManufacturer from FACT_TRANSACTIONS t left join DIM_MODEL m on t.IDModel = m.IDModel
					where (year(date) = '2009') 
					group by IDManufacturer
					)

--Q9--END

--Q10--BEGIN

select top 100 *, concat(cast(coalesce((((a.avg_price - (lag(a.avg_price,1) over(partition by IDCustomer order by [year])))
/a.avg_price)*100),0) as float),'%') as percent_of_change
from
	(
	select ROW_NUMBER() over (partition by t.idcustomer order by year(date)) as row_num, 
	t.IDCustomer, c.Customer_Name, avg(TotalPrice) as avg_price, avg(Quantity) as avg_qty, year(date) [year]
	from FACT_TRANSACTIONS t left join DIM_CUSTOMER c on t.IDCustomer = c.IDCustomer
	group by t.IDCustomer, c.Customer_Name, year(date)
	) as a

--Q10--END
	