use b2w2;
#################################################################################
drop table if exists m1_tocluster;
create table m1_tocluster
select 
	p1.summary_day as date,
    p1.volume as p1_volume,
    p2.volume as p2_volume,
    p2.volume as p3_volume,
    p2.volume as p4_volume,
    p2.volume as p5_volume,
    p2.volume as p6_volume,
    p2.volume as p7_volume,
    p2.volume as p8_volume,
    p2.volume as p9_volume
from
    daily_summary p1
inner join daily_summary p2
	on p2.product = 'P2'
    and p2.summary_day = p1.summary_day
inner join daily_summary p3
	on p3.product = 'P3'
    and p3.summary_day = p1.summary_day
inner join daily_summary p4
	on p4.product = 'P4'
    and p4.summary_day = p1.summary_day
inner join daily_summary p5
	on p5.product = 'P5'
    and p5.summary_day = p1.summary_day
inner join daily_summary p6
	on p6.product = 'P6'
    and p6.summary_day = p1.summary_day
inner join daily_summary p7
	on p7.product = 'P7'
    and p7.summary_day = p1.summary_day
inner join daily_summary p8
	on p8.product = 'P8'
    and p8.summary_day = p1.summary_day
inner join daily_summary p9
	on p9.product = 'P9'
    and p9.summary_day = p1.summary_day
where
	p1.product = 'P1';
delete from m1_tocluster where date = '2015-09-27';
#################################################################################
drop table if exists m1;
create table m1 as
select
	a.product, 
    a.summary_day, 
    a.volume, 
    a.price, 
    day(a.summary_day) as day, 
    a.day_of_week,    
    
    a.month,
    a.price - y.price as price_diff,
    #a.volume - y.volume as volume_diff, 
    y.volume as volume_lag1,
    y.price as price_lag1,
    y.volume - yy.volume as volume_diff_lag1,
    y.price - yy.price as price_diff_lag1,
    
	yy.volume as volume_lag2,
    yy.price as price_lag2,
    yy.volume - y3.volume as volume_diff_lag2,
    yy.price - y3.price as price_diff_lag2,
    
	y3.volume as volume_lag3,
    y3.price as price_lag3,
	y3.volume - y4.volume as volume_diff_lag3,
    y3.price - y4.price as price_diff_lag3,
    
	y4.volume as volume_lag4,
    y4.price as price_lag4,
    y4.volume - y5.volume as volume_diff_lag4,
    y4.price - y5.price as price_diff_lag4,
    
	y5.volume as volume_lag5,
    y5.price as price_lag5,
    
    ifnull(c5.min_price, cs.avg_price) as comp_min_price,
    ifnull(c5.avg_price, cs.avg_price) as comp_avg_price,
    ifnull(c5.product, 'others') as is_c5,
    is_weekend,
    if(month='August' or month='May', 'mes das maes/pais', 'outros meses') as is_parent_holiday
from daily_summary a
inner join (
		select
			product, 
			date_add(summary_day, interval 1 day) as lag1,
			volume,
			price
		from daily_summary
    ) y
    on a.product = y.product
    and y.lag1 = a.summary_day
inner join (
		select
			product,
            date_add(summary_day, interval 2 day) as lag2,
            volume,
            price
		from daily_summary
	) yy
	on a.product = yy.product
    and yy.lag2 = a.summary_day
inner join (
		select
			product,
            date_add(summary_day, interval 3 day) as lag3,
            volume,
            price
		from daily_summary
	) y3
	on a.product = y3.product
    and y3.lag3 = a.summary_day
inner join (
		select
			product,
            date_add(summary_day, interval 4 day) as lag4,
            volume,
            price
		from daily_summary
	) y4
	on a.product = y4.product
    and y4.lag4 = a.summary_day
inner join (
		select
			product,
            date_add(summary_day, interval 5 day) as lag5,
            volume,
            price
		from daily_summary
	) y5
	on a.product = y5.product
    and y5.lag5 = a.summary_day
left join (
		select
			product,
            extraction_day,
			min(min_price) as min_price,
            avg(avg_price) as avg_price
        from extractions_summary
        where competitor = 'C5'
        group by product, extraction_day

	) c5
    on a.product = c5.product
    and a.summary_day = c5.extraction_day
inner join (
		select
			product,
            extraction_day,
			min(min_price) as min_price,
            avg(avg_price) as avg_price
        from extractions_summary        
        group by product, extraction_day

	) cs
    on a.product = cs.product
    and a.summary_day = cs.extraction_day

