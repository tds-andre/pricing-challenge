use b2w2;
#################################################################################
drop table if exists daily_summary;
create table daily_summary as
select
	product,
	bought_at as summary_day,
	sum(quantity) as volume,
	sum(revenue) as revenue,
	max(price) as price,
	max(price) as max_price,
	cast(avg(price) as decimal(10,2)) as avg_price,
	min(price) as min_price,
	std(price) as dev_price,
    concat("Dia ",cast(day(bought_at) as char(2))) as day,
	day_of_week,
    is_weekend,
	month
from sales 
group by bought_at, product;
#################################################################################
drop table if exists extractions_summary;
create table extractions_summary
select 
	count(*) as extractions, 
    product, 
    competitor, 
    date(price_at) as extraction_day,
    max(price) - min(price) as delta,
    max(price) as max_price,
    min(price) as min_price,
    cast(avg(price) as decimal(10,2)) as avg_price,
    cast(std(price) as decimal(10,2)) as std_price,
    pay_type, 
    day_of_week, 
    month,
    if(max(price) - min(price) = 0, 'unchanged', 'changed') had_change
from prices 
group by date(price_at), competitor, product;
#################################################################################
drop table if exists change_summary;
create table  change_summary as
select
	count(*) as count,
    had_change,
    product, 
    competitor,
    cast(avg(delta) as decimal(10,2)) as avg_delta,
    max(delta) as max_delta,
    min(delta) as min_delta
from extractions_summary
group by had_change, product, competitor
order by  product, competitor, had_change;
#################################################################################
drop table if exists price_stability;
create table price_stability as 
select 
	a.product,
    a.competitor,
	a.count as changed_count,
    b.count as unchanged_count,
    cast(100*a.count/b.count as decimal(10,2)) as ratio,
    cast(100*b.count / (b.count + a.count) as decimal(10,2)) as stability,
    a.avg_delta,
    a.max_delta,
    a.min_delta
from change_summary a 
left join (select * from change_summary where had_change = 'unchanged') b
on a.product = b.product and a.competitor = b.competitor
where a.had_change = 'changed';
#################################################################################
drop table if exists sales_and_prices;
create table sales_and_prices as
select 
	extractions,
    b.product,
    competitor,
    extraction_day as price_at,
    delta,
    a.max_price,
    a.min_price,
    a.avg_price,
    a.std_price,
    pay_type,
    a.day_of_week,
    a.month,
    had_change,
    volume,
    revenue,
    b.price as my_base_price,
    b.price - a.avg_price as diff,
    if(b.price > a.min_price, 'higher', 'lower') as comparision
from extractions_summary a
inner join daily_summary b on
	a.product = b.product and
	a.extraction_day = b.summary_day;
#################################################################################
drop table if exists comparision_summary;
create table comparision_summary as 
select
	product,
    competitor,
    comparision,
    count(*) as count,
	avg(volume) as avg_volume,
    max(volume) as max_volume,
    avg(revenue) as avg_revenue,
    sum(volume) as volume
from sales_and_prices
group by comparision, product, competitor;
#################################################################################
drop table if exists pricing_analysis;
create table pricing_analysis
select
	l.product,
    l.competitor,
    cast(100*h.count / (h.count + l.count) as decimal(10,2)) as pricing_efficiency,
    cast(l.avg_volume/h.avg_volume as decimal(10,2)) as pricing_impact,
    cast(l.avg_revenue * l.avg_volume/h.avg_volume as decimal(10,2)) as pricing_relevancy,
    l.count as lower_count,
    l.avg_volume as lower_avg_volume,
    l.volume as lower_volume,
    l.avg_revenue as lower_avg_revenue,
	h.count as higher_count,
    h.avg_volume as higher_avg_volume,
    h.volume as higher_volume,
    h.avg_revenue as higher_avg_revenue    
from comparision_summary l
inner join (select * from comparision_summary where comparision = 'higher') h
	on h.product = l.product
	and h.competitor = l.competitor
where l.comparision = 'lower';
#################################################################################

