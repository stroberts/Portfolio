
drop view fellowacs;
create view FellowACs as(
select vanid acvanid
,activistcodeid
,datecreated::date acdate
,row_number() over(
partition by vanid
order by datecreated desc, case when activistcodeid=4277122 then 0 else 2000 end asc
) acrn
from c2014_ar_coord_vansync.activistcodeexportmc
where activistcodeid in (4266777,4277122)
)
;

select * from c2014_ar_coord_vansync.activistcodeexportmc
limit 1;


select * from FellowACs
--where activistcodeid=4266777-- acrn=1
;
drop table eventattendees cascade;
select *, case
        when shift.wasconfirmed=1 and shift.currentstatus='Completed' then 'Confirmed_completed'
        when shift.wasconfirmed=1 and (shift.currentstatus='No Show' or shift.currentstatus='Declined') then 'Confirmed_uncompleted'
        when shift.wasconfirmed=1 then 'Confirmed_unclosed'
        when shift.currentstatus='Completed' then 'Unconfirmed_completed'
        when (shift.currentstatus='No Show' or shift.currentstatus='Declined') then 'Unconfirmed_uncompleted'
        else 'Unconfirmed_unclosed' end finalsitchverbose
        ,case --completed => 1 (mod 2), closed => 1 (mod 3)
        when shift.currentstatus='Completed' then 7
        when shift.currentstatus='No Show' or shift.currentstatus='Declined' then 4
        else 6 end finalsitch into sroberts.eventattendees from (
select status.eventsignupid
, events.eventid
, coalesce(ate.aregion,/* turf.region,*/ 'Unturfed') region
, coalesce(ate.afo,/* turf.organizer,*/ 'Unturfed') FO
, coalesce(ate.ateam,/* turf.team,*/ 'Unturfed') Team
, coalesce(person.cdname, 'Unturfed') CD
, coalesce(fac.cnvrtype, 'Vol') cnvrtype
, min(status.datecreated-interval '1 Hours')::date recruiteddate
, econtact.vanid
, events.eventcalendarname eventtype
, econtact.datetimeoffsetbegin/*-interval '1 Hours')*/::date eventdate--left(events.dateoffsetbegin,10) eventdate
, max(
        case when status.rownumber=1 then status.eventstatusname
        else NULL end) currentstatus
,max(
        case when status.eventstatusname='Confirmed' then 1
        else 0 end) wasconfirmed 
,max( case when status.eventstatusname in('Scheduled','Confirmed','Completed') then 1 else NULL end) wasschedconfcomp
,max(status.rownumber) numtouches
,max(case when status.confrn=1 and status.eventstatusname!='Declined' then 1 end) neededconfcallyesterday
from (
        select *
        , row_number() OVER(
                partition by eventsignupid
                order by datecreated desc
                ,eventsignupseventstatusid desc
                ,iscurrentstatus desc
                ) rownumber
        , row_number() OVER(
                partition by eventsignupid
                order by case when datecreated::date<(current_date-1) then datecreated end desc
                ,eventsignupseventstatusid desc
                ,iscurrentstatus desc
                ) confrn
        from c2014_ar_coord_vansync.eventscontactsstatuses 
        ) status inner join--left join 
        c2014_ar_coord_vansync.eventscontacts econtact using(eventsignupid) left join
        c2014_ar_coord_vansync.events using(eventid) left join
        c2014_ar_coord_vansync.mycampaignperson person on econtact.vanid=person.vanid left join
        c2014_ar_coord_vansync.mycampaignmergepersons on person.vanid=mycampaignmergepersons.mergevanid left join
        sroberts.attributer turf on coalesce(mycampaignmergepersons.mastervanid, person.vanid)=turf.vanid left join
        (select vanid,regionname aregion, foname afo, teamname ateam from c2014_ar_coord_vansync.activityturfexport
        where committeeid=45240) ate on coalesce(mycampaignmergepersons.mastervanid, person.vanid)=ate.vanid
        left join (select acvanid, case when activistcodeid=4266777 then 'Fellow' else 'Vol'end cnvrtype, acdate from FellowACs where acrn=1) fac
        on acvanid=econtact.vanid and acdate<=econtact.datetimeoffsetbegin::date
where econtact.datesuppressed is null and events.datesuppressed is null
group by 1,2,3,4,5,6,7,9,10,11) shift
;

drop table sroberts.eventsummary;
select * into sroberts.eventsummary from (
select timeperiod
, Region /*FO 'Statewide'*/ turf
,eventtype
, coalesce(cnvrtype,'Vol') cnvrtype
,sum(wasschedconfcomp) Scheduled
,sum(mod(shifts.finalsitch,2)) Showed
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(shifts.wasschedconfcomp),0)::float grossflakerate2
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(mod(shifts.finalsitch,3)),0)::float closedflakerate
,1-sum(mod(shifts.finalsitch,3))/nullif(count(*),0)::float percentunclosed
,sum(case when shifts.currentstatus in ('Scheduled','Confirmed','Left Msg') then 1 end) Expected
,sum(case when shifts.currentstatus='Confirmed' then 1 end) ExpectedConf
,sum(shifts.wasconfirmed) confirmed--/nullif(count(*),0)::float percentconfirmed
, count(distinct weighter.vanid) uniqueshowers
, sum(mod(shifts.finalsitch,2)/weighter.weight::float) weighteduniqueshowers
from sroberts.actionplustimeeventattendees shifts left join (
select timeperiod ,vanid, count(distinct eventtype) numeventtypes, sum(mod(finalsitch,2)) weight from sroberts.actionplustimeeventattendees
where eventtype!='1-on-1 Meeting'
and finalsitch=7
group by 1,2) weighter using(timeperiod,vanid)
group by 1,2,3,4
order by 1 desc, 2 asc
) c full OUTER join (select right(timeperiod,len(timeperiod)-5) timeperiod
, Region /*FO 'Statewide'*/ turf
, eventtype
,sum(rec.wasschedconfcomp) recruited
from sroberts.actionplustimeeventattendees rec--actioneventattendees is a view
where left(timeperiod,1)='S'
group by 1,2,3
order by 1 desc, 2
) b using(timeperiod,turf,eventtype) full outer join (
select timeperiod
, region turf
, 'Canvass' eventtype --this is only to keep the join from duplicating
, 'Vol' cnvrtype
, sum(active) newshowed
, sum(dormant) droppedoff
from activevols
group by 1,2,3
) d using(timeperiod,turf,eventtype,cnvrtype)
order by 1 desc, 2,3 asc
;
insert into sroberts.eventsummary
select * from (select timeperiod
, FO/*Region FO 'Statewide'*/ turf
,eventtype
, coalesce(cnvrtype,'Vol') cnvrtype
,sum(wasschedconfcomp) Scheduled
,sum(mod(shifts.finalsitch,2)) Showed
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(shifts.wasschedconfcomp),0)::float grossflakerate2
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(mod(shifts.finalsitch,3)),0)::float closedflakerate
,1-sum(mod(shifts.finalsitch,3))/nullif(count(*),0)::float percentunclosed
,sum(case when shifts.currentstatus in ('Scheduled','Confirmed','Left Msg') then 1 end) Expected
,sum(case when shifts.currentstatus='Confirmed' then 1 end) ExpectedConf
,sum(shifts.wasconfirmed) confirmed--/nullif(count(*),0)::float percentconfirmed
, count(distinct weighter.vanid) uniqueshowers
, sum(mod(shifts.finalsitch,2)/weighter.weight::float) weighteduniqueshowers
from sroberts.actionplustimeeventattendees shifts left join (
select timeperiod ,vanid, count(distinct eventtype) numeventtypes, sum(mod(finalsitch,2)) weight from sroberts.actionplustimeeventattendees
where eventtype!='1-on-1 Meeting'
and finalsitch=7
group by 1,2) weighter using(timeperiod,vanid)
group by 1,2,3,4
order by 1 desc, 2 asc
) c full OUTER join (select right(timeperiod,len(timeperiod)-5) timeperiod
, FO/*Region FO 'Statewide'*/ turf
, eventtype
,sum(rec.wasschedconfcomp) recruited
from sroberts.actionplustimeeventattendees rec--actioneventattendees is a view
where left(timeperiod,1)='S'
group by 1,2,3
order by 1 desc, 2
) b using(timeperiod,turf,eventtype) full outer join (
select timeperiod
, fo turf
, 'Canvass' eventtype
, 'Vol' cnvrtype
, sum(active) newshowed
, sum(dormant) droppedoff
from activevols
group by 1,2,3
) d using(timeperiod,turf,eventtype,cnvrtype)
order by 1 desc, 2,3 asc
;
insert into sroberts.eventsummary
select * from (select timeperiod
, 'Statewide'/*Region FO 'Statewide'*/ turf
,eventtype
, coalesce(cnvrtype,'Vol') cnvrtype
,sum(wasschedconfcomp) Scheduled
--here I sneak in the number of new vols scheduled today - it doesn't fit in anywhere else, I only need the statewide number
--and the column would have no use for that "Today" row anyway
, sum(case when timeperiod='Today' and av.active is null and shifts.currentstatus in ('Scheduled','Confirmed','Left Msg') then 1 else mod(shifts.finalsitch,2) end) Showed
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(shifts.wasschedconfcomp),0)::float grossflakerate2
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(mod(shifts.finalsitch,3)),0)::float closedflakerate
,1-sum(mod(shifts.finalsitch,3))/nullif(count(*),0)::float percentunclosed
,sum(case when shifts.currentstatus in ('Scheduled','Confirmed','Left Msg') then 1 end) Expected
,sum(case when shifts.currentstatus='Confirmed' then 1 end) ExpectedConf
,sum(shifts.wasconfirmed) confirmed--/nullif(count(*),0)::float percentconfirmed
, count(distinct weighter.vanid) uniqueshowers
, sum(mod(shifts.finalsitch,2)/weighter.weight::float) weighteduniqueshowers
from sroberts.actionplustimeeventattendees shifts left join (
select timeperiod ,vanid, count(distinct eventtype) numeventtypes, sum(mod(finalsitch,2)) weight from sroberts.actionplustimeeventattendees
where eventtype!='1-on-1 Meeting'
and finalsitch=7
group by 1,2) weighter using(timeperiod,vanid) left join
(select vanid, active from activevols) av using(vanid)
group by 1,2,3,4
order by 1 desc, 2 asc
) c full OUTER join (select right(timeperiod,len(timeperiod)-5) timeperiod
, 'Statewide'/*Region FO 'Statewide'*/ turf
, eventtype
,sum(rec.wasschedconfcomp) recruited
from sroberts.actionplustimeeventattendees rec--actioneventattendees is a view
where left(timeperiod,1)='S'
group by 1,2,3
order by 1 desc, 2
) b using(timeperiod,turf,eventtype) full outer join (
select timeperiod
, 'Statewide' turf
, 'Canvass' eventtype
, 'Vol' cnvrtype
, sum(active) newshowed
, sum(dormant) droppedoff
from activevols
group by 1,2,3
) d using(timeperiod,turf,eventtype,cnvrtype)
order by 1 desc, 2,3 asc
;



drop view fellowacs;
create view FellowACs as(
select vanid acvanid
,activistcodeid
,datecreated::date acdate
,row_number() over(
partition by vanid
order by datecreated desc, case when activistcodeid=4280168 then 0 else 2000 end asc
) acrn
from c2014_ar_coord_vansync.activistcodeexportmc
where activistcodeid in (4266777,4280168)
)
;
select * from fellowacs;

--4266777=Confirmed Intern
--4277122=Dropped Off (check)



jacob hobkins
ashley williams


select * from c2014_ar_coord_vansync.activistcodeexportmc
limit 10;



--4266777=Confirmed Intern


select * from vansync.dncactivistcodes
where activistcodeid=4263880
and stateid='AR';

create view actable as (
select activistcodeid,activistcodename from vansync.dncactivistcodes where stateid='AR');


select cnvrtype, eventdate-extract(dow from eventdate+2)%7, count(*) from eventattendees
group by 1,2
order by 2 desc;

