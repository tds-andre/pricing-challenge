#################################################################################
set @dir = 'C:\\Users\\andre.santos\\Desktop\\b2w-pricing-challenge\\data\\in\\';
create schema b2w2;
use b2w2;
#################################################################################
CREATE TABLE `stg_sales` (
  `prod_id` varchar(2) NOT NULL,
  `date_order` date NOT NULL,
  `qty_order` decimal(10,2) NOT NULL,
  `revenue` decimal(10,2) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
#################################################################################
CREATE TABLE `stg_comp_prices` (
  `prod_id` varchar(2) DEFAULT NULL,
  `date_extraction` datetime DEFAULT NULL,
  `competitor` varchar(2) DEFAULT NULL,
  `competitor_price` decimal(10,2) DEFAULT NULL,
  `pay_type` varchar(1) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
#################################################################################
load data local infile  'C:\\Users\\andre.santos\\Desktop\\b2w-pricing-challenge\\data\\in\\sales.csv'
into table stg_sales
fields terminated by ','
ignore 1 lines;
#################################################################################
load data local infile  'C:\\Users\\andre.santos\\Desktop\\b2w-pricing-challenge\\data\\in\\comp_prices.csv'
into table stg_comp_prices
fields terminated by ','
ignore 1 lines;
#################################################################################
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `fill_date_dimension`(IN startdate DATE,IN stopdate DATE)
BEGIN
DECLARE currentdate DATE;
SET currentdate = startdate;
WHILE currentdate < stopdate DO
INSERT INTO time_dimension VALUES (
YEAR(currentdate)*10000+MONTH(currentdate)*100 + DAY(currentdate),
currentdate,
YEAR(currentdate),
MONTH(currentdate),
DAY(currentdate),
QUARTER(currentdate),
WEEKOFYEAR(currentdate),
DATE_FORMAT(currentdate,'%W'),
DATE_FORMAT(currentdate,'%M'),
'f',
CASE DAYOFWEEK(currentdate) WHEN 1 THEN 't' WHEN 7 then 't' ELSE 'f' END,
NULL);
SET currentdate = ADDDATE(currentdate,INTERVAL 1 DAY);
END WHILE;
END$$
DELIMITER ;
#################################################################################
CREATE TABLE `time_dimension` (
  `id` int(11) NOT NULL,
  `db_date` date NOT NULL,
  `year` int(11) NOT NULL,
  `month` int(11) NOT NULL,
  `day` int(11) NOT NULL,
  `quarter` int(11) NOT NULL,
  `week` int(11) NOT NULL,
  `day_name` varchar(9) NOT NULL,
  `month_name` varchar(9) NOT NULL,
  `holiday_flag` char(1) DEFAULT 'f',
  `weekend_flag` char(1) DEFAULT 'f',
  `event` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `td_ymd_idx` (`year`,`month`,`day`),
  UNIQUE KEY `td_dbdate_idx` (`db_date`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
call fill_date_dimension('2015-01-01', '2015-10-15');
#################################################################################
create table prices as
select
	a.prod_id as product,
    a.competitor as competitor,
    pay_type,
    date_extraction as price_at,    
    cast(if(a.competitor_price > 4 * a2.avg_price, a.competitor_price/10, a.competitor_price) as decimal(10,2)) as price,    
    day_name as day_of_week,
    month_name as month
from stg_comp_prices a 
left join 
	(
		select 
			prod_id, 
			competitor, 
			avg(competitor_price) as avg_price 
		from b2w2.stg_comp_prices 
		group by prod_id, competitor
	) a2
	on a2.prod_id = a.prod_id
	and a2.competitor = a.competitor
left join time_dimension t 
	on t.db_date = date(a.date_extraction);
#################################################################################
drop table if exists sales;
create table sales as
select 
	prod_id as product,
    date_order as bought_at,
    qty_order as quantity,
    revenue as revenue,
    cast(revenue/qty_order as decimal(10,2)) as price,
    day_name as day_of_week,
    month_name as month,
    if(weekend_flag='t', 'weekend', 'workday') as is_weekend
from stg_sales a
left join time_dimension t
	on a.date_order = t.db_date;
#################################################################################
drop table if exists daily_summary;
create table daily_summary as
select
	product,
	bought_at,
	sum(quantity) as volume,
	sum(revenue) as revenue,
	max(price) as price,
	max(price) as max_price,
	cast(avg(price) as decimal(10,2)) as avg_price,
	min(price) as min_price,
	std(price) as dev_price,
	day_of_week,
	month
from sales 
group by bought_at, product;
#################################################################################
#################################################################################
#################################################################################
#################################################################################
#################################################################################