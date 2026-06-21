USE road_safety;
/*SELECT * FROM collision limit 10 ;
SELECT * FROM casualty limit 10 ;
SELECT * FROM vehicle limit 10 ;*/

/*How many collisions were there in total in 2022? Break down by accident_severity (Slight / Serious / Fatal).*/
with tb as (select 
case when collision_severity=1 then "Fatal" when collision_severity=2 then "Serious" else "Slight"  end as severity 
from collision where collision_year=2025 )
select severity,count(*) as cnt from tb group by severity;

/*Whats the % of fatal collisions out of all collisions? Use a CASE expression inside an AVG or COUNT.*/
select (avg(case when collision_severity=1 then 1 else 0 end))*100 as cnt  from collision;

/*Which hour of the day has the most collisions? (Extract hour from the time column, GROUP BY, ORDER BY.)*/
select hour(time) as hr,count(*) as cnt from collision group by hr order by cnt desc;

/*Top 10 local authorities by collision count — and which of those has the highest fatal-collision rate?*/
with tb as (select local_authority_ons_district,count(*) as cnt from collision
 WHERE local_authority_ons_district IS NOT NULL AND local_authority_ons_district <> '' group by local_authority_ons_district order by cnt desc limit 10)
 select c.local_authority_ons_district,count(*) as total,
sum(case when c.collision_severity=1 then 1 else 0 end) as fatalcollisions,
round((sum(case when c.collision_severity=1 then 1 else 0 end)*100)/count(*),2) as fatal_rate_pct
 from collision c join tb t on c.local_authority_ons_district = t.local_authority_ons_district group by c.local_authority_ons_district order by fatal_rate_pct desc;
 
 
 /*Do collisions on wet road surfaces have a higher serious-or-fatal rate than dry ones?*/
 select case when road_surface_conditions=1 then "dry" else "wet" end as road_condition,
 sum(case when collision_severity in (1,2) then 1 else 0 end) as severity,
 round((sum(case when collision_severity in (1,2) then 1 else 0 end)*100)/count(*),2) as pct,
 count(*) as cnt
from collision where road_surface_conditions in (1,2)
 group by road_surface_conditions 
 order by pct desc;
 

/*Do weekends have proportionally more serious-or-fatal collisions at night than weekdays?*/
SELECT
  CASE WHEN day_of_week = 7                              -- All of Saturday
      OR (day_of_week = 6 AND HOUR(time) >= 22)       -- Friday 10pm+
      OR (day_of_week = 1 AND HOUR(time) <= 4)        -- Sunday up to 4am
    THEN 'Weekend night' ELSE 'Weekday night' END AS day_type,
  COUNT(*) AS total,
  SUM(CASE WHEN collision_severity IN (1,2) THEN 1 ELSE 0 END) AS serious_or_fatal,
  ROUND(SUM(CASE WHEN collision_severity IN (1,2) THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct
FROM collision
WHERE HOUR(time) BETWEEN 22 AND 23 OR HOUR(time) BETWEEN 0 AND 4 and  day_of_week IS NOT NULL AND day_of_week <> '' -- 10pm to 4am
GROUP BY day_type;



/*which vehicle type is most over-represented in fatal collisions vs all collisions?*/
select v.vehicle_type, case v.vehicle_type when 1	then "Pedal cycle"
when 2	then "Motorcycle 50cc and under"
when 3	then "Motorcycle 125cc and under"
when 4	then "Motorcycle over 125cc and up to 500cc"
when 5	then "Motorcycle over 500cc"
when 8	then "Taxi/Private hire car"
when 9	then "Car"
when 11	then "Bus or coach (17 or more pass seats)"
when 19	then "Van / Goods 3.5 tonnes mgw or under"
when 20 then "Goods over 3.5t. and under 7.5t"
when 21	then "Goods 7.5 tonnes mgw and over"
when 23	then "Electric motorcycle"
when 90	then "Other vehicle"
when 97	then "Motorcycle - unknown cc"
when 98	then "Goods vehicle - unknown weight"
end as vehicle_label,
count(*) as allcollisions, sum(case when c.collision_severity=1 then 1 else 0 end) as fatalcollision,
round(sum(case when c.collision_severity=1 then 1 else 0 end)*100.0/count(*),2) as pct
 from collision c 
inner join vehicle v on c.collision_index=v.collision_index and c.collision_ref_no=v.collision_ref_no 
where v.vehicle_type!=-1 
group by v.vehicle_type having count(*)>=50 order by pct desc;



/*in fatal collisions, what's the age and sex breakdown of casualties?*/
select 
case v.sex_of_casualty when 1 then "Male" when 2 then "Female" when 9 then "unknown" end as sex,
case v.age_band_of_casualty when 1 then "0 - 5"
when 2	then "6 - 10"
when 3	then "11 - 15"
when 4	then "16 - 20"
when 5	then "21 - 25"
when 6	then "26 - 35"
when 7	then "36 - 45"
when 8	then "46 - 55"
when 9	then "56 - 65"
when 10	then "66 - 75"
when 11	then "Over 75" end as age_band,
count(*) as fatal_casualties
from collision c 
inner join casualty v on c.collision_index=v.collision_index and c.collision_ref_no=v.collision_ref_no 
where c.collision_severity = 1 and v.sex_of_casualty!=-1 and v.age_of_casualty!=-1 and v.age_band_of_casualty!=-1 
group by v.age_band_of_casualty,v.sex_of_casualty order by fatal_casualties desc;
