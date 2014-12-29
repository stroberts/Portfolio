insert into conflist
select *,current_date-interval '1 Days' "confcalldate"
from todaysconfirmcalls
;
delete from sroberts.conflist
where confcalldate<(current_date-extract(dow from current_date+2)::int%7)
;

drop table sroberts.eventattendees cascade;

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
, coalesce(turf.region, 'Unturfed') region
, coalesce(turf.organizer, 'Unturfed') FO
, coalesce(turf.team, 'Unturfed') Team
, min(status.datecreated-interval '1 Hours')::date recruiteddate
, econtact.vanid
, events.eventcalendarname eventtype
, (econtact.datetimeoffsetbegin-interval '1 Hours')::date eventdate--left(events.dateoffsetbegin,10) eventdate
, max(
        case when status.rownumber=1 then status.eventstatusname
        else NULL end) currentstatus
,max(
        case when status.eventstatusname='Confirmed' then 1
        else 0 end) wasconfirmed 
,max( case when status.eventstatusname in('Scheduled','Confirmed','Completed') then 1 else NULL end) wasschedconfcomp
,max(status.rownumber) numtouches       
from (
        select *
        , row_number() OVER(
                partition by eventsignupid
                order by datecreated desc
                ,eventsignupseventstatusid desc
                ,iscurrentstatus desc
                ) rownumber
        from c2014_ar_coord_vansync.eventscontactsstatuses 
        ) status inner join--left join 
        c2014_ar_coord_vansync.eventscontacts econtact using(eventsignupid) left join
        c2014_ar_coord_vansync.events using(eventid) left join
        c2014_ar_coord_vansync.mycampaignperson person on econtact.vanid=person.vanid left join
        c2014_ar_coord_vansync.mycampaignmergepersons on person.vanid=mycampaignmergepersons.mergevanid left join
        sroberts.attributer turf on coalesce(mycampaignmergepersons.mastervanid, person.vanid)=turf.vanid
where econtact.datesuppressed is null and events.datesuppressed is null
group by 1,2,3,4,5,7,8,9) shift
;
create view actioneventattendees as
select * from eventattendees a
where eventtype in ('Voter Reg', 'Canvass', 'Phone Bank', 'Vol Recruitment')
;

grant select on eventattendees to dortiz;
grant select on actioneventattendees to dortiz;
drop table sroberts.eventsummary;

select * into sroberts.eventsummary from (
select (shifts.eventdate-extract(dow from shifts.eventdate+2)::int%7) Week
, Region
, FO--Turf--FO FOTurf
--, finalsitch
,1-sum(mod(shifts.finalsitch,2))/nullif(count(*),0)::float grossflakerate
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(shifts.wasschedconfcomp),0)::float grossflakerate2
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(mod(shifts.finalsitch,3)),0)::float closedflakerate
,1-sum(mod(shifts.finalsitch,2)*shifts.wasconfirmed)/nullif(sum(shifts.wasconfirmed),0)::float confirmedflakerate
,1-sum(mod(shifts.finalsitch,3))/nullif(count(*),0)::float percentunclosed
,sum(shifts.wasconfirmed)/nullif(count(*),0)::float percentconfirmed
from sroberts.actioneventattendees shifts--actioneventattendees is a view
where shifts.eventdate<current_date --and (shifts.eventtype='Voter Reg' or shifts.eventtype='Phone Bank' or shifts.eventtype='Canvass')
group by 1,2,3
order by 1 desc, 2,3 asc
) c
left join (select (shifts.eventdate-extract(dow from shifts.eventdate+2)::int%7) Week
, Region
, FO--Turf--FO FOTurf
--, finalsitch
,sum(case when shifts.eventdate<current_date then wasschedconfcomp end) ScheduledWeekToDate
,sum(mod(shifts.finalsitch,2)) Showed
,sum(case when shifts.eventdate>=current_date and currentstatus!='Declined' then wasschedconfcomp end) RemainingShiftsinWeek
from sroberts.actioneventattendees shifts--actioneventattendees is a view
--where shifts.eventdate<current_date --and (shifts.eventtype='Voter Reg' or shifts.eventtype='Phone Bank' or shifts.eventtype='Canvass')
group by 1,2,3
order by 1 desc, 2,3 asc) a using(Week,Region,FO)
left join (select (rec.recruiteddate-extract(dow from rec.recruiteddate+2)::int%7) Week
 , Region
, FO
,sum(rec.wasschedconfcomp) ShiftsRecruitedThisWeek
from sroberts.actioneventattendees rec--actioneventattendees is a view
group by 1,2,3
order by 1 desc, 2,3 asc
) b using(Week,Region,FO)
order by 1 desc, 2,3 asc
;
insert into sroberts.eventsummary
select * from (
select (shifts.eventdate-extract(dow from shifts.eventdate+2)::int%7) Week
, Region
,'Total' as FO--Turf--FO FOTurf
--, finalsitch
,1-sum(mod(shifts.finalsitch,2))/nullif(count(*),0)::float grossflakerate
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(shifts.wasschedconfcomp),0)::float grossflakerate2
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(mod(shifts.finalsitch,3)),0)::float closedflakerate
,1-sum(mod(shifts.finalsitch,2)*shifts.wasconfirmed)/nullif(sum(shifts.wasconfirmed),0)::float confirmedflakerate
,1-sum(mod(shifts.finalsitch,3))/nullif(count(*),0)::float percentunclosed
,sum(shifts.wasconfirmed)/nullif(count(*),0)::float percentconfirmed
from sroberts.actioneventattendees shifts--actioneventattendees is a view
where shifts.eventdate<current_date --and (shifts.eventtype='Voter Reg' or shifts.eventtype='Phone Bank' or shifts.eventtype='Canvass')
group by 1,2,3
order by 1 desc, 2,3 asc
) c
left join (select (shifts.eventdate-extract(dow from shifts.eventdate+2)::int%7) Week
, Region
,'Total' as FO--Turf--FO FOTurf
--, finalsitch
,sum(case when shifts.eventdate<current_date then wasschedconfcomp end) ScheduledWeekToDate
,sum(mod(shifts.finalsitch,2)) Showed
,sum(case when shifts.eventdate>=current_date and currentstatus!='Declined' then wasschedconfcomp end) RemainingShiftsinWeek
from sroberts.actioneventattendees shifts--actioneventattendees is a view
--where shifts.eventdate<current_date --and (shifts.eventtype='Voter Reg' or shifts.eventtype='Phone Bank' or shifts.eventtype='Canvass')
group by 1,2,3
order by 1 desc, 2,3 asc) a using(Week,Region,FO)
left join (select (rec.recruiteddate-extract(dow from rec.recruiteddate+2)::int%7) Week
, Region
,'Total' as FO--Turf--FO FOTurf
,sum(rec.wasschedconfcomp) ShiftsRecruitedThisWeek
from sroberts.actioneventattendees rec--actioneventattendees is a view
group by 1,2,3
order by 1 desc, 2,3 asc
) b using(Week,Region,FO)
order by 1 desc, 2,3 asc
;
insert into sroberts.eventsummary
select * from (
select (shifts.eventdate-extract(dow from shifts.eventdate+2)::int%7) Week
, 'Statewide' Region
,'Total' as FO--Turf--FO FOTurf
--, finalsitch
,1-sum(mod(shifts.finalsitch,2))/nullif(count(*),0)::float grossflakerate
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(shifts.wasschedconfcomp),0)::float grossflakerate2
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(mod(shifts.finalsitch,3)),0)::float closedflakerate
,1-sum(mod(shifts.finalsitch,2)*shifts.wasconfirmed)/nullif(sum(shifts.wasconfirmed),0)::float confirmedflakerate
,1-sum(mod(shifts.finalsitch,3))/nullif(count(*),0)::float percentunclosed
,sum(shifts.wasconfirmed)/nullif(count(*),0)::float percentconfirmed
from sroberts.actioneventattendees shifts--actioneventattendees is a view
where shifts.eventdate<current_date --and (shifts.eventtype='Voter Reg' or shifts.eventtype='Phone Bank' or shifts.eventtype='Canvass')
group by 1,2,3
order by 1 desc, 2,3 asc
) c
left join (select (shifts.eventdate-extract(dow from shifts.eventdate+2)::int%7) Week
, 'Statewide' Region
,'Total' as FO--Turf--FO FOTurf
--, finalsitch
,sum(case when shifts.eventdate<current_date then wasschedconfcomp end) ScheduledWeekToDate
,sum(mod(shifts.finalsitch,2)) Showed
,sum(case when shifts.eventdate>=current_date and currentstatus!='Declined' then wasschedconfcomp end) RemainingShiftsinWeek
from sroberts.actioneventattendees shifts--actioneventattendees is a view
--where shifts.eventdate<current_date --and (shifts.eventtype='Voter Reg' or shifts.eventtype='Phone Bank' or shifts.eventtype='Canvass')
group by 1,2,3
order by 1 desc, 2,3 asc) a using(Week,Region,FO)
left join (select (rec.recruiteddate-extract(dow from rec.recruiteddate+2)::int%7) Week
, 'Statewide' Region
,'Total' as FO--Turf--FO FOTurf
,sum(rec.wasschedconfcomp) ShiftsRecruitedThisWeek
from sroberts.actioneventattendees rec--actioneventattendees is a view
group by 1,2,3
order by 1 desc, 2,3 asc
) b using(Week,Region,FO)
order by 1 desc, 2,3 asc
;


/*select * from sroberts.eventsummary
order by 1 desc,2 asc*/;
/*select (shifts.eventdate-extract(dow from shifts.eventdate+2)::int%7) Week
,shifts.eventtype
,count(*)
,sum(shifts.wasschedconfcomp)
,sum(mod(shifts.finalsitch,2))
from sroberts.eventattendees shifts
where shifts.eventdate<current_date --and (shifts.eventtype='Voter Reg' or shifts.eventtype='Phone Bank' or shifts.eventtype='Canvass')
group by 1,2 
order by 1 desc
*/;

drop table quasiactivevols;
--creates list of people who will soon fall off Active Vols
select region,fo,vanid, eventdate
into quasiactivevols
from (
select *
,row_number() OVER(
partition by vanid
order by eventdate desc
) rn
from eventattendees
where eventtype in ('Voter Reg', 'Canvass', 'Phone Bank', 'Vol Recruitment')
and currentstatus='Completed'
)
where rn=1 and eventdate>(current_date-interval '30 Days') and eventdate<(current_date-interval '20 Days')
order by 1,2 desc
;
 

--creates table of confirmation calls for FOs to call into(via bulk upload for now
--eventually via direct sync to van. also usable to track which calls are confirm calls
--in the week by archiving
/*Block Commented Part creates a call-list-ready table*/
drop table sroberts.todaysconfirmcalls;
select region,fo,eventattendees.vanid/*,eventtype
,mcp.Name,mcp.phone
, (ec.datetimeoffsetbegin-interval '1 Hour') ShiftStart
, (ec.datetimeoffsetend-interval '1 Hour') ShiftEnd*/
into todaysconfirmcalls
from sroberts.eventattendees
/*left join (
select vanid avanid, phone, concat(firstname,concat(' ',lastname)) "Name"
from
c2014_ar_coord_vansync.mycampaignperson
) mcp on vanid=avanid
left join c2014_ar_coord_vansync.eventscontacts ec using(eventsignupid)
*/where eventattendees.currentstatus!='Declined'
and eventattendees.eventdate>current_date
and eventattendees.eventdate<(current_date+interval '4 Days')
;
grant select on todaysconfirmcalls to dortiz;

