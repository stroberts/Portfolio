/*
        In cases where you have an R process that won't die in R (won't terminate w/o killing the whole R process,
        this can work to kill it from DbVis or dbeaver, etc.
*/
select pid, user_name, starttime, query
from stv_recents
where status='Running'
order by starttime desc;
--where returned value is [pid], and ideally recognizably your's:
CANCEL [pid];

select * 
from STL_QUERY
-- You can specify dates as cutoff 
--where starttime < '2016-04-26 17:45:00'::datetime
order by endtime desc

limit 1000
;

--find and troubleshoot your recent load issues
select *
from stl_load_errors
order by starttime desc
;

--evaluate status of multi-query jobs
select *--starttime::date,count(*),min(starttime),max(starttime)--2016-05-13 18:16:20
from STL_QUERY

where left(querytxt,len('INSERT INTO someschema.profiling_counts_new'))='INSERT INTO someschema.profiling_counts_new'
--group by 1
order by starttime desc
;
select starttime::date,starttime>'2016-05-13 19:33:01'::datetime secondrun,count(*) 
from STL_QUERY

where left(querytxt,len('INSERT INTO univision.profiling_counts_new'))='INSERT INTO univision.profiling_counts_new'
group by 1,2
order by starttime desc
;



--find work on a table
select *
from STL_QUERY
where querytxt LIKE '%hispanic_viewership_ntl_combined%'
order by starttime desc;
