--criar view de modo a reunir todos os campos/informações necessárias
create view vw_SalesProfit as
	select
		SH.SalesOrderID,
		year(SH.OrderDate) 'Year',
		month(SH.OrderDate) 'Month',
		SD.ProductID,
		PP.Name,
		SD.OrderQty,
		SD.UnitPrice,
		SD.UnitPriceDiscount,
		SD.LineTotal,
		PP.StandardCost * SD.OrderQty as Cost --cálculo do custo
	from Sales.SalesOrderHeader SH
		join Sales.SalesOrderDetail SD
		on SH.SalesOrderID = SD.SalesOrderID
		join Production.Product PP
		on SD.ProductID = PP.ProductID

select * --teste
from vw_SalesProfit

--adicionar campos 
alter view vw_SalesProfit as
	select
		SH.SalesOrderID,
		year(SH.OrderDate) 'Year',
		month(SH.OrderDate) 'Month',
		SD.ProductID,
		PP.[Name],
		PS.[Name] SubCategory, --adicionar subcategoria dos produtos
		PC.[Name] Category, --adicionar categoria dos produtos
		SD.OrderQty,
		SD.UnitPrice,
		SD.UnitPriceDiscount,
		UnitPrice - UnitPriceDiscount as UnitPriceWithDiscount,
		SD.LineTotal,
		PP.StandardCost * SD.OrderQty as Cost,
		PP.StandardCost as UnitCost
	from Sales.SalesOrderHeader SH
		join Sales.SalesOrderDetail SD
		on SH.SalesOrderID = SD.SalesOrderID
		join Production.Product PP
		on SD.ProductID = PP.ProductID
		join Production.ProductSubcategory PS
		on PP.ProductSubcategoryID = PS.ProductSubcategoryID
		join Production.ProductCategory PC
		on PS.ProductCategoryID = PC.ProductCategoryID

select * --teste
from vw_SalesProfit


-- teste para verificar nulos

SELECT
    COUNT(*) AS TotalRegistos,
    COUNT(SD.UnitPriceDiscount) AS ComDesconto,
    COUNT(PP.StandardCost) AS ComCusto
FROM Sales.SalesOrderDetail SD
JOIN Production.Product PP
    ON SD.ProductID = PP.ProductID


-- teste valores negativos 

SELECT *
FROM Sales.SalesOrderDetail
WHERE
    OrderQty <= 0
    OR UnitPrice < 0
    OR UnitPriceDiscount < 0
    OR UnitPriceDiscount > 1;

--vendas/custos
select
	sum(LineTotal) Sales, --soma das vendas totais
	sum(Cost) Cost --soma do custo total
from vw_SalesProfit

select
	Year,
	sum(LineTotal) Sales, --soma das vendas totais por ano
	sum(Cost) Cost --soma do custo total por ano
from vw_SalesProfit
group by Year

select
	Year,
	Month,
	sum(LineTotal) Sales, --soma das vendas totais por mês
	sum(Cost) Cost, --soma do custo total por mês
	sum(LineTotal - Cost) Profit --cálculo do lucro
from vw_SalesProfit
group by Year, Month
order by Year, Month 

--total de produtos vendidos
select 
	sum(OrderQty) TotalQty
from vw_SalesProfit 

select --produtos distintos
	count(distinct ProductID) TotalProd
from vw_SalesProfit

--quantidades vendidas por ano
select
	Year,
	sum(OrderQty) TotalQty
from vw_SalesProfit
group by Year
order by Year

--quantidades vendidas por categoria e subcategoria
select 
	Year,
	Category, 
	SubCategory,
	sum(OrderQty) TotalQty
from vw_SalesProfit
group by Year, Category, SubCategory
order by Year, TotalQty desc

--quantidades vendidas por categoria
select 
	Year,
	Category,
	sum(OrderQty) TotalQty
from vw_SalesProfit
group by Year, Category
order by Year, TotalQty desc

--quantidades vendidas por e subcategoria
select 
	Year,
	SubCategory,
	sum(OrderQty) TotalQty
from vw_SalesProfit
group by Year, SubCategory
order by Year, TotalQty desc

--margem
select
	Year,
	Month,
	sum(LineTotal - Cost)/sum(LineTotal)*100 Margin
from vw_SalesProfit
group by Year, Month
order by Year, Month

--ranking margem mensal
select
	Year,
	Month,
	sum(LineTotal - Cost)/sum(LineTotal)*100 Margin,
	rank() over (
		partition by Year
		order by sum(LineTotal - Cost)/sum(LineTotal)*100 desc
		) as RankMensal
from vw_SalesProfit
group by Year, Month

--calculo da diferença entre o preço de custo e o preço de venda (rentabilidade)
select distinct
	ProductID,
	Name,
	avg(UnitPrice) as UnitPrice,
	avg(UnitPriceWithDiscount) as UnitPriceWithDiscount,
	avg(UnitCost) as UnitCost,
	avg(UnitPriceWithDiscount - UnitCost) as Dif
from vw_SalesProfit
group by ProductID, Name
having avg(UnitPriceWithDiscount - UnitCost) < 0 
order by ProductID

-- calculo dos descontos medios 

SELECT
    YEAR(SH.OrderDate)  AS [Year],
    MONTH(SH.OrderDate) AS [Month],
    
    MAX(SD.UnitPriceDiscount) AS MaxDiscount,
    AVG(SD.UnitPriceDiscount) AS AvgDiscount
FROM Sales.SalesOrderHeader SH
JOIN Sales.SalesOrderDetail SD
    ON SH.SalesOrderID = SD.SalesOrderID
JOIN Production.Product PP
    ON SD.ProductID = PP.ProductID
GROUP BY
    YEAR(SH.OrderDate),
    MONTH(SH.OrderDate)
ORDER BY
    [Year],
    [Month]