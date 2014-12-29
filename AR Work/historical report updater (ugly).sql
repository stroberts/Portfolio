select (current_date-interval '1 Day') reportdate, * 
into historicalmorningreport7_9
from sroberts.dailymorningreportbasetable
;
--drop table historicalmorningreports
;
--select *
--into historicalmorningreports
-- from  testtable
;
 
--drop table testtable
; 
delete from testtable;
--insert into testtable
select */* into testtable*/ from sroberts.historicalmorningreport7_9
;
--use column list in dbl-click table to create below, inserting new column where needed

insert into testtable
select reportdate
,timeperiod
,turf
,eventtype
,'Vol' cnvrtype
,scheduled
,showed
,newscheduled
,newshowed
,grossflakerate2
,closedflakerate
,percentunclosed
,expected
,expectedconf
,confirmed
,recruited
,mycattempts
,myccontacts
,"1:1s"
,dvcattempts
,dvccontacts
,vr
,uniqueshowers
,weighteduniqueshowers
from historicalmorningreports
;

--use column list in dbl-click table to create above, inserting new column where needed.
select * from testtable
where reportdate<'2014-07-01'
limit 20
;

