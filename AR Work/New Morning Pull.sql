--insert into historicalmorningreports
--select (current_date-interval '1 Day') reportdate, * from sroberts.dailymorningreportbasetable
;
--insert into conflist
--select *,current_date-interval '1 Days' "confcalldate"
--from todaysconfirmcalls
;
delete from sroberts.conflist
where confcalldate<(current_date-1-extract(dow from current_date+1)::int%7)
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
,case when isstaginglocation then locationname end SL
,eventrolename rolename
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
        --sroberts.attributer turf on coalesce(mycampaignmergepersons.mastervanid, person.vanid)=turf.vanid left join
        (select vanid,regionname aregion, foname afo, teamname ateam from c2014_ar_coord_vansync.activityturfexport
        where committeeid=45240) ate on coalesce(mycampaignmergepersons.mastervanid, econtact.vanid)=ate.vanid
        left join (select acvanid, case when activistcodeid=4266777 then 'Fellow' else 'Vol'end cnvrtype, acdate from FellowACs where acrn=1) fac
        on acvanid=econtact.vanid and acdate<=econtact.datetimeoffsetbegin::date
        left join (select locationid,locationname,isstaginglocation,latitude,longitude from c2014_ar_coord_vansync.locations where isactive) using(locationid)
where econtact.datesuppressed is null and events.datesuppressed is null
group by 1,2,3,4,5,6,7,9,10,11,12,13) shift
;

create view actioneventattendees as
select * from eventattendees a
where eventtype in ('Voter Reg', 'Canvass', 'Phone Bank', 'Vol Recruitment','Signature Gathering','Phone Banker (Dialer)')
;


--allocate all active or recently dropped off vols into a table, largly split on when they became/will become active/inactive (with those allocated to "today" simply added to keep the total right) 
drop table activevols;
select vanid
,region
,fo
, CASE
        WHEN min(eventdate)=(current_date-interval '1 Day') then 'Yesterday'
        when min(eventdate)>=(current_date-1-extract(dow from current_date+1)%7) then 'Week to Date'
        when max(eventdate)>=(current_date-interval '24 Days') then 'Today'
        when max(eventdate)>=(current_date-interval '31 Days') then 'Week to Come'
        when max(eventdate)=(current_date-interval '32 Days') then 'Yesterday'
        else 'Week to Date' end timeperiod
,max(eventtype) eventtype --needed only to keep from overmatching on join
,case when max(eventdate)>=(current_Date-interval '31 Days') then 1 end Active
,case when max(eventdate)>=(current_Date-interval '31 Days') then null else 1 end Dormant
into activevols
from eventattendees
where eventtype in ('Voter Reg', 'Canvass', 'Phone Bank', 'Vol Recruitment','Data Entry','Signature Gathering','Phone Banker (Dialer)')
and finalsitch=7
and eventdate>=(current_date-32-extract(dow from current_date+1)%7)
and eventdate<current_date
group by 1,2,3
;

--create a table of attendees categorized by whether they're attendees from the week to day, yesterday, or the weeek to come
--will be duplicates, which is fine - the category will differenciate
drop table timeeventattendees;
create table timeeventattendees as(
select 'Week to Date' as timeperiod
,* from sroberts.eventattendees
where eventdate<current_date and eventdate>=(current_date-1-extract(dow from current_date+1)::int%7)
) union all (
select 'SchedWeek to Date' as timeperiod
,* from sroberts.eventattendees shifts
where recruiteddate<current_date and recruiteddate>=(current_date-1-extract(dow from current_date+1)::int%7)
) Union all (
select 'Yesterday' as timeperiod
,* from sroberts.eventattendees
where eventdate=(current_date-interval '1 Day')
) union all (
select 'SchedYesterday' as timeperiod
,* from sroberts.eventattendees shifts
where recruiteddate=(current_date-interval '1 Day')
) union all (
select 'Week to Come' as timeperiod
,* from sroberts.eventattendees
where eventdate>=current_date and eventdate<(current_date+7-extract(dow from current_date+2)::int%7)
and currentstatus!='Declined'
) Union all (
select 'Today' as timeperiod
,* from sroberts.eventattendees
where eventdate=current_date
) Union all (
select 'This Weekend' as timeperiod
,* from sroberts.eventattendees
where eventdate in ((current_date+5-extract(dow from current_date+6)%7),(current_date+6-extract(dow from current_date+6)%7))
) union all (
select 'Next Week' as timeperiod
,* from sroberts.eventattendees
where eventdate<(current_date+14-extract(dow from current_date+2)::int%7) and eventdate>=(current_date+7-extract(dow from current_date+2)::int%7)
)
;

drop table actionplustimeeventattendees;
create table actionplustimeeventattendees as
select * from timeeventattendees a
where eventtype in ('Voter Reg', 'Canvass', 'Phone Bank', 'Vol Recruitment','Signature Gathering','1-on-1 Meeting')
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
,cnvrtype
,sum(rec.wasschedconfcomp) recruited
from sroberts.actionplustimeeventattendees rec--actioneventattendees is a view
where left(timeperiod,1)='S'
group by 1,2,3,4
order by 1 desc, 2
) b using(timeperiod,turf,eventtype,cnvrtype) full outer join (
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
,cnvrtype
,sum(rec.wasschedconfcomp) recruited
from sroberts.actionplustimeeventattendees rec--actioneventattendees is a view
where left(timeperiod,1)='S'
group by 1,2,3,4
order by 1 desc, 2
) b using(timeperiod,turf,eventtype,cnvrtype) full outer join (
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
,cnvrtype
,sum(rec.wasschedconfcomp) recruited
from sroberts.actionplustimeeventattendees rec--actioneventattendees is a view
where left(timeperiod,1)='S'
group by 1,2,3,4
order by 1 desc, 2
) b using(timeperiod,turf,eventtype,cnvrtype) full outer join (
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
--select * from eventsummary
--where turf='Statewide'
--order by 2 asc, 1 desc;
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

--creates analogouse table for Phase 1-4 of GOTV
drop table timesleventattendees;
create table timesleventattendees as(
select 'Phase 1' as timeperiod
,* from sroberts.eventattendees
where eventdate  between '2014-10-10' and '2014-10-20'
) union all (
select 'Phase 2' as timeperiod
,* from sroberts.eventattendees
where eventdate between '2014-10-21' and '2014-10-30'
) union all (
select 'Phase 3' as timeperiod
,* from sroberts.eventattendees
where eventdate between '2014-11-01' and '2014-11-02'
) union all (
select 'Phase 4' as timeperiod
,* from sroberts.eventattendees
where eventdate between '2014-11-03' and '2014-11-04'
)
;
--creates analogous table for GOTV events, clarifies roles
drop table slactiontimeeventattendees;
create table slactiontimeeventattendees as
select * from timesleventattendees a
where --eventtype in ('Voter Reg', 'Canvass', 'Phone Bank', 'Vol Recruitment','Signature Gathering','1-on-1 Meeting')
rolename in ('Canvasser','Canvass Lead','Phone banker','Phone Bank Lead', 'Phone Banker (Dialer)','Phone Bank Lead (Dialer)')
and eventtype='GOTV Event'
and SL is not null
;

--creates analogous table for gotv events
drop table sroberts.sleventsummary;
select * into sroberts.sleventsummary from (
select phase        
, coalesce(SL,'Un-SLed') turf
,coalesce(rolename,'Unroled') "role" --drop completely once where-ing on Type=gotv?
,sum(wasschedconfcomp) Scheduled
,count(distinct case when wasschedconfcomp=1 then vanid end) uniquescheduled
,sum(mod(shifts.finalsitch,2)) Showed
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(shifts.wasschedconfcomp),0)::float grossflakerate2
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(mod(shifts.finalsitch,3)),0)::float closedflakerate
,1-sum(mod(shifts.finalsitch,3))/nullif(count(*),0)::float percentunclosed
,sum(case when shifts.currentstatus in ('Scheduled','Confirmed','Left Msg') then 1 end) Expected
,sum(case when shifts.currentstatus='Confirmed' then 1 end) ExpectedConf
,sum(shifts.wasconfirmed) confirmed--/nullif(count(*),0)::float percentconfirmed
, count(distinct weighter.vanid) uniqueshowers
, sum(mod(shifts.finalsitch,2)/weighter.weight::float) weighteduniqueshowers
,SL orderer
from (select case when eventdate='2014-11-04' then 'Phase 4' when eventdate>='2014-11-01' then 'Phase 3' when eventdate>='2014-10-20' then 'Phase 2' else 'Phase 1' end phase 
, * from sroberts.eventattendees) shifts left join (
select case when eventdate='2014-11-04' then 'Phase 4' when eventdate>='2014-11-01' then 'Phase 3' when eventdate>='2014-10-20' then 'Phase 2' else 'Phase 1' end phase  
,vanid, count(distinct eventtype) numeventtypes, sum(mod(finalsitch,2)) weight from sroberts.eventattendees
where eventtype='GOTV Event' and SL is not null and eventdate between '2014-10-10' and '2014-11-04' and finalsitch=7 --and eventtype='GOTV Event'
group by 1,2) weighter using(phase,vanid)
where rolename in ('Canvasser','Canvass Lead','Phone banker','Phone Bank Lead', 'Phone Banker (Dialer)','Phone Bank Lead (Dialer)')
and eventtype='GOTV Event'
and SL is not null
and eventdate between '2014-10-10' and '2014-11-04'
group by 1,2,3,15) UNION ALL (
select phase        
, 'Total' turf
,coalesce(rolename,'Unroled') "role" --drop completely once where-ing on Type=gotv?
,sum(wasschedconfcomp) Scheduled
,count(distinct case when wasschedconfcomp=1 then vanid end) uniquescheduled
,sum(mod(shifts.finalsitch,2)) Showed
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(shifts.wasschedconfcomp),0)::float grossflakerate2
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(mod(shifts.finalsitch,3)),0)::float closedflakerate
,1-sum(mod(shifts.finalsitch,3))/nullif(count(*),0)::float percentunclosed
,sum(case when shifts.currentstatus in ('Scheduled','Confirmed','Left Msg') then 1 end) Expected
,sum(case when shifts.currentstatus='Confirmed' then 1 end) ExpectedConf
,sum(shifts.wasconfirmed) confirmed--/nullif(count(*),0)::float percentconfirmed
, count(distinct weighter.vanid) uniqueshowers
, sum(mod(shifts.finalsitch,2)/weighter.weight::float) weighteduniqueshowers
,'ZZZ' orderer
from (select case when eventdate='2014-11-04' then 'Phase 4' when eventdate>='2014-11-01' then 'Phase 3' when eventdate>='2014-10-20' then 'Phase 2' else 'Phase 1' end phase 
, * from sroberts.eventattendees where eventtype='GOTV Event' and SL is not null and eventdate between '2014-10-10' and '2014-11-04') shifts left join (
select case when eventdate='2014-11-04' then 'Phase 4' when eventdate>='2014-11-01' then 'Phase 3' when eventdate>='2014-10-20' then 'Phase 2' else 'Phase 1' end phase  
,vanid, count(distinct eventtype) numeventtypes, sum(mod(finalsitch,2)) weight from sroberts.eventattendees
where eventtype='GOTV Event' and SL is not null and eventdate between '2014-10-10' and '2014-11-04' and finalsitch=7 --and eventtype='GOTV Event'
group by 1,2) weighter using(phase,vanid)
where rolename in ('Canvasser','Canvass Lead','Phone banker','Phone Bank Lead', 'Phone Banker (Dialer)','Phone Bank Lead (Dialer)')
group by 1,2,3,15
) UNION ALL (
select phase        
, case when FO is not null and FO!='Unturfed' then FO end turf
,coalesce(rolename,'Unroled') "role" --drop completely once where-ing on Type=gotv?
,sum(wasschedconfcomp) Scheduled
,count(distinct case when wasschedconfcomp=1 then vanid end) uniquescheduled
,sum(mod(shifts.finalsitch,2)) Showed
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(shifts.wasschedconfcomp),0)::float grossflakerate2
,1-sum(mod(shifts.finalsitch,2))/nullif(sum(mod(shifts.finalsitch,3)),0)::float closedflakerate
,1-sum(mod(shifts.finalsitch,3))/nullif(count(*),0)::float percentunclosed
,sum(case when shifts.currentstatus in ('Scheduled','Confirmed','Left Msg') then 1 end) Expected
,sum(case when shifts.currentstatus='Confirmed' then 1 end) ExpectedConf
,sum(shifts.wasconfirmed) confirmed--/nullif(count(*),0)::float percentconfirmed
, count(distinct weighter.vanid) uniqueshowers
, sum(mod(shifts.finalsitch,2)/weighter.weight::float) weighteduniqueshowers
,' '||substring(FO,3,1)||right(FO,1)
from (select case when eventdate='2014-11-04' then 'Phase 4' when eventdate>='2014-11-01' then 'Phase 3' when eventdate>='2014-10-20' then 'Phase 2' else 'Phase 1' end phase 
, * from sroberts.eventattendees where eventtype='GOTV Event' and SL is not null and eventdate between '2014-10-10' and '2014-11-04') shifts left join (
select case when eventdate='2014-11-04' then 'Phase 4' when eventdate>='2014-11-01' then 'Phase 3' when eventdate>='2014-10-20' then 'Phase 2' else 'Phase 1' end phase  
,vanid, count(distinct eventtype) numeventtypes, sum(mod(finalsitch,2)) weight from sroberts.eventattendees
where eventtype='GOTV Event' and SL is not null and eventdate between '2014-10-10' and '2014-11-04' and finalsitch=7 --and eventtype='GOTV Event'
group by 1,2) weighter using(phase,vanid)
where rolename in ('Canvasser','Canvass Lead','Phone banker','Phone Bank Lead', 'Phone Banker (Dialer)','Phone Bank Lead (Dialer)')
group by 1,2,3,15
)
order by 15,1,3--case when turf='Total' then 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ' when left(turf,2)='R0' then 'ZZZZZZZZZZZZZZZZZZZZZ' else turf end  /*ERROR: ORDER BY on a UNION/INTERSECT/EXCEPT result must be on one of the result columns*/
;

--creates table of confirmation calls for FOs to call into(via bulk upload for now
--eventually via direct sync to van. also usable to track which calls are confirm calls
--in the week by archiving
/*Block Commented Part creates a call-list-ready table*/
drop table sroberts.todaysconfirmcalls;
select eventattendees.vanid,region,fo/*,eventtype
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
*/ where eventattendees.currentstatus!='Declined'
and eventattendees.eventdate>current_date
and eventattendees.eventdate<(current_date+interval '4 Days')
;
grant select on todaysconfirmcalls to dortiz;

drop table MyCPhoneSummary
;

select CASE 
        WHEN ch.datecanvassed::date=(current_date-interval '1 Day') then 'Yesterday'
        else 'Week to Date' end timeperiod
, coalesce(regionname,'Unturfed') turf
, 'Vol Recruitment' eventtype
,'Staff' cnvrtype
,count(distinct ch.contactscontactid) MyCAttempts
,count(distinct case when ch.resultid=14 then ch.contactscontactid end) MyCContacts
into MyCPhoneSummary
from c2014_ar_coord_vansync.contacthistoryexportmc ch
left join c2014_ar_coord_vansync.activityturfexport ate using(vanid)
where ch.datecanvassed::date<current_date
and (case ch.datecanvassed --corrects for central time if not manual(hence 'midnight') entry
        when ch.datecanvassed::date then ch.datecanvassed
        else ch.datecanvassed-interval '1 Hour' end)>=(current_date-1-extract(dow from current_date+1)::int%7)
and contacttypeid=1--phone
group by 1,2,3
order by 1 desc, 2 asc
;
insert into MyCPhoneSummary
select CASE 
        WHEN ch.datecanvassed::date=(current_date-interval '1 Day') then 'Yesterday'
        else 'Week to Date' end timeperiod
, coalesce(foname,'Unturfed') turf
, 'Vol Recruitment' eventtype
,'Staff' cnvrtype
,count(distinct ch.contactscontactid) MyCAttempts
,count(distinct case when ch.resultid=14 then ch.contactscontactid end) MyCContacts
from c2014_ar_coord_vansync.contacthistoryexportmc ch
left join c2014_ar_coord_vansync.activityturfexport ate using(vanid)
where ch.datecanvassed::date<current_date
and (case ch.datecanvassed --corrects for central time if not manual(hence 'midnight') entry
        when ch.datecanvassed::date then ch.datecanvassed
        else ch.datecanvassed-interval '1 Hour' end)>=(current_date-1-extract(dow from current_date+1)::int%7)
and contacttypeid=1--phone
group by 1,2,3
order by 1 desc, 2 asc
;
insert into MyCPhoneSummary
select CASE 
        WHEN ch.datecanvassed::date=current_date-interval '1 Day' then 'Yesterday'
        else 'Week to Date' end timeperiod
, 'Statewide' turf
, 'Vol Recruitment' eventtype
,'Staff' cnvrtype
,count(*) MyCAttempts
,sum(case when ch.resultid=14 then 1 end) MyCContacts
from c2014_ar_coord_vansync.contacthistoryexportmc ch
--left join (select vanid,regionname aregion, foname afo, teamname ateam from c2014_ar_coord_vansync.activityturfexport 
--        where committeeid=45240) ate using(vanid)
where ch.datecanvassed::date<current_date
and (case ch.datecanvassed --corrects for central time if not manual(hence 'midnight') entry
        when ch.datecanvassed::date then ch.datecanvassed
        else ch.datecanvassed-interval '1 Hour' end)>=(current_date-1-extract(dow from current_date+1)::int%7)
and contacttypeid=1--phone
group by 1,2
order by 1 desc, 2 asc
;

--create table of all (including non-phone) MyC Contacts - allows more accurate contacts/shift #s
drop table MyCContactSummary
;
select CASE 
        WHEN ch.datecanvassed::date=(current_date-interval '1 Day') then 'Yesterday'
        else 'Week to Date' end timeperiod
, coalesce(regionname,'Unturfed') turf
, 'Vol Recruitment' eventtype
,'Staff' cnvrtype
,count(distinct case when ch.resultid=14 then ch.contactscontactid end) MyCAllContacts
into MyCContactSummary
from c2014_ar_coord_vansync.contacthistoryexportmc ch
left join c2014_ar_coord_vansync.activityturfexport ate using(vanid)
where ch.datecanvassed::date<current_date
and (case ch.datecanvassed --corrects for central time if not manual(hence 'midnight') entry
        when ch.datecanvassed::date then ch.datecanvassed
        else ch.datecanvassed-interval '1 Hour' end)>=(current_date-1-extract(dow from current_date+1)::int%7)
group by 1,2--,3
order by 1 desc, 2 asc
;
insert into MyCContactSummary
select CASE 
        WHEN ch.datecanvassed::date=(current_date-interval '1 Day') then 'Yesterday'
        else 'Week to Date' end timeperiod
, coalesce(foname,'Unturfed') turf
, 'Vol Recruitment' eventtype
,'Staff' cnvrtype
,count(distinct case when ch.resultid=14 then ch.contactscontactid end) MyCAllContacts
from c2014_ar_coord_vansync.contacthistoryexportmc ch
left join c2014_ar_coord_vansync.activityturfexport ate using(vanid)
where ch.datecanvassed::date<current_date
and (case ch.datecanvassed --corrects for central time if not manual(hence 'midnight') entry
        when ch.datecanvassed::date then ch.datecanvassed
        else ch.datecanvassed-interval '1 Hour' end)>=(current_date-1-extract(dow from current_date+1)::int%7)
group by 1,2--,3
order by 1 desc, 2 asc
;
insert into MyCContactSummary
select CASE 
        WHEN ch.datecanvassed::date=(current_date-interval '1 Day') then 'Yesterday'
        else 'Week to Date' end timeperiod
, 'Statewide' turf
, 'Vol Recruitment' eventtype
,'Staff' cnvrtype
,count(distinct case when ch.resultid=14 then ch.contactscontactid end) MyCAllContacts
from c2014_ar_coord_vansync.contacthistoryexportmc ch
left join c2014_ar_coord_vansync.mycampaignmergepersons mcmp on ch.vanid=mcmp.mergevanid
left join sroberts.attributer attr on coalesce(mcmp.mastervanid, ch.vanid)=attr.vanid
where ch.datecanvassed::date<current_date
and ch.datecanvassed::date>=(current_date-1-extract(dow from current_date+1)::int%7)
group by 1,2--,3
order by 1 desc, 2 asc
;

drop table usrtype;
create table usrtype as(
select canvasserid
,case min(typechar)
        when '!' then 'Fellow'
        when '#' then 'Vol'
        when '~' then 'Staff'
        when null then 'Null'
        else 'incorrect' end cnvrtype --order asc: '!','#',number,alpha,'~'
from (select userid canvasserid, left(lastname,1) typechar from c2014_ar_coord_vansync.vanusers union select publicuserid canvasserid, left(publicusername,1) typechar from c2014_ar_coord_vansync.publicusers)
group by 1
order by 1 asc
)
;

drop table myvcontacthistory;
select case when ch.datecanvassed::date=(current_date-interval '1 Day') then 'Yesterday' else 'Week to Date' end timeperiod
, coalesce(attr.regionname,'Unturfed') turf--, coalesce(attr.foname,'Unturfed') 
,case contacttypeid when 1 then 'Phone Bank' when 19 then 'Dialer' else 'Canvass' end eventtype
,ut.cnvrtype
,count(distinct case when contacttypeid in (1,19) then ch.contactscontactid else addressid end) DVCAttempts
,sum(case when resultid=14 then 1 end) DVCContacts
into myvcontacthistory
from c2014_ar_coord_vansync.contacthistoryexport ch
left join analytics_ar.vanid_to_personid vtp using(vanid,state) 
left join (select personid, vanprecinctid as precinctid, primary_voting_address_id addressid from analytics_ar.person) person using(personid) 
left join c2014_ar_coord_vansync.turfexport attr using(precinctid,state)-- on attr.precinctid=person.vanprecinctid and ch.state=attr.state
left join sroberts.usrtype ut using(canvasserid)
where ch.datecanvassed>=(current_date-1-extract(dow from current_date+1)::int%7)
and contacttypeid in (1,2,19)
and ch.committeeid=45240--Our's
group by 1,2,3,4
;
insert into myvcontacthistory
select case when ch.datecanvassed::date=(current_date-interval '1 Day') then 'Yesterday' else 'Week to Date' end timeperiod
, coalesce(attr.foname,'Unturfed') turf--, coalesce(attr.foname,'Unturfed') 
,case contacttypeid when 1 then 'Phone Bank' when 19 then 'Dialer' else 'Canvass' end eventtype
,ut.cnvrtype
,count(distinct case when contacttypeid in (1,19) then ch.contactscontactid else addressid end) DVCAttempts
,sum(case when resultid=14 then 1 end) DVCContacts
from c2014_ar_coord_vansync.contacthistoryexport ch
left join analytics_ar.vanid_to_personid vtp using(vanid,state) 
left join (select personid, vanprecinctid as precinctid, primary_voting_address_id addressid from analytics_ar.person) person using(personid) 
left join c2014_ar_coord_vansync.turfexport attr using(precinctid,state)-- on attr.precinctid=person.vanprecinctid and ch.state=attr.state
left join sroberts.usrtype ut using(canvasserid)
where ch.datecanvassed>=(current_date-1-extract(dow from current_date+1)::int%7)
and contacttypeid in (1,2,19)
and ch.committeeid=45240--Our's
group by 1,2,3,4
;
insert into myvcontacthistory
select case when ch.datecanvassed::date=(current_date-interval '1 Day') then 'Yesterday' else 'Week to Date' end timeperiod
, 'Statewide' turf--, coalesce(attr.foname,'Unturfed') 
,case contacttypeid when 1 then 'Phone Bank' when 19 then 'Dialer' else 'Canvass' end eventtype
,ut.cnvrtype
,count(distinct case when contacttypeid in (1,19) then ch.contactscontactid else addressid end) DVCAttempts
,sum(case when resultid=14 then 1 end) DVCContacts
from c2014_ar_coord_vansync.contacthistoryexport ch
left join analytics_ar.vanid_to_personid vtp using(vanid,state) 
left join (select personid, vanprecinctid as precinctid, primary_voting_address_id addressid from analytics_ar.person) person using(personid) 
--left join c2014_ar_coord_vansync.turfexport attr using(precinctid,state)-- on attr.precinctid=person.vanprecinctid and ch.state=attr.state
left join sroberts.usrtype ut using(canvasserid)
where ch.datecanvassed>=(current_date-1-extract(dow from current_date+1)::int%7)
and contacttypeid in (1,2,19)
and ch.committeeid=45240--Our's
group by 1,2,3,4
;

--VR
/*drop table sroberts.vr*/;
/*select case when vr.datecreated::date=(current_date-interval '1 Day') then 'Yesterday'
else 'Week to Date' end timeperiod
, coalesce(vrc.region,'Unturfed') turf
,'Voter Reg' eventtype
,ut.cnvrtype
,count(*) VR
into sroberts.vr
from c2014_ar_coord_vansync.voterreg vr
left join (select distinct publicuserid as createdby, publicusername from c2014_ar_coord_vansync.publicusers) pu using(createdby)
left join (select distinct region,fo,publicusername  from sroberts.vrcanvasserattributer) vrc using(publicusername)
left join sroberts.usrtype ut on vr.createdby=canvasserid
where left(vr.batchname,2)='AR'
and vr.datecreated>=(current_date-1-extract(dow from current_date+1)%7)
group by 1,2,3,4
order by 2 asc
*/;
/*insert into vr
select case when vr.datecreated::date=(current_date-interval '1 Day') then 'Yesterday'
else 'Week to Date' end timeperiod
, coalesce(vrc.fo,'Unturfed') turf
,'Voter Reg' eventtype
,ut.cnvrtype
,count(*) VR
from c2014_ar_coord_vansync.voterreg vr
left join (select distinct publicuserid as createdby, publicusername from c2014_ar_coord_vansync.publicusers) pu using(createdby)
left join (select distinct region,fo,publicusername  from sroberts.vrcanvasserattributer) vrc using(publicusername)
left join sroberts.usrtype ut on vr.createdby=canvasserid
where left(vr.batchname,2)='AR'
and vr.datecreated>=(current_date-1-extract(dow from current_date+1)%7)
group by 1,2,3,4
order by 2 asc
*/;
/*insert into vr
select case when vr.datecreated::date=(current_date-interval '1 Day') then 'Yesterday'
else 'Week to Date' end timeperiod
, 'Statewide' turf
,'Voter Reg' eventtype
,ut.cnvrtype
,count(*) VR
from c2014_ar_coord_vansync.voterreg vr
left join sroberts.usrtype ut on vr.createdby=canvasserid
where left(vr.batchname,2)='AR'
and vr.datecreated>=(current_date-1-extract(dow from current_date+1)%7)
group by 1,2,3,4
order by 2 asc
*/;
--attributes dialer hours by a form, then against MyC, so the form overrides
drop table sroberts.dialer;
select case when agentreports.logged_out::date=(current_date-interval '1 Day') then 'Yesterday'
else 'Week to Date' end timeperiod
, coalesce(Region,regionname,'Unturfed') turf
,'Phone Banker (Dialer)' eventtype
,'Vol' cnvrtype
,sum(datediff(hour,logged_in,logged_out)+datediff(minute,logged_in,logged_out)::float/60+datediff(minute,logged_in,logged_out)::float/3600) hrs
into sroberts.dialer
from sroberts.agentreports left join sroberts.dialerattributer using(phone_number)
left join (select phone::bigint phone_number, max(regionname) regionname, max(foname) foname from c2014_ar_coord_vansync.mycampaignperson_turf where phone is not null group by 1) using(phone_number)
where agentreports.logged_out>=(current_date-1-extract(dow from current_date+1)%7)
group by 1,2,3,4 union all (
select case when agentreports.logged_out::date=(current_date-interval '1 Day') then 'Yesterday'
else 'Week to Date' end timeperiod
, coalesce(FO,foname,'Unturfed') turf
,'Phone Banker (Dialer)' eventtype
,'Vol' cnvrtype
,sum(datediff(hour,logged_in,logged_out)+datediff(minute,logged_in,logged_out)::float/60+datediff(minute,logged_in,logged_out)::float/3600) hrs
from sroberts.agentreports left join sroberts.dialerattributer using(phone_number)
left join (select phone::bigint phone_number, max(regionname) regionname, max(foname) foname from c2014_ar_coord_vansync.mycampaignperson_turf where phone is not null group by 1) using(phone_number)
where agentreports.logged_out>=(current_date-1-extract(dow from current_date+1)%7)
group by 1,2,3,4
) union all (
select case when agentreports.logged_out::date=(current_date-interval '1 Day') then 'Yesterday'
else 'Week to Date' end timeperiod
, 'Statewide' turf
,'Phone Banker (Dialer)' eventtype
,'Vol' cnvrtype
,sum(datediff(hour,logged_in,logged_out)+datediff(minute,logged_in,logged_out)::float/60+datediff(minute,logged_in,logged_out)::float/3600) hrs
from sroberts.agentreports
where agentreports.logged_out>=(current_date-1-extract(dow from current_date+1)%7)
group by 1,2,3,4
)
order by 2 asc
;





--July Gross Contact Rate in MyC is 20.373 /\ 4 Passes => OOV dial weighted by (weighting against # confcalls) x+x^2+x^3, x being 1-GCR
--=> OOV Dials = [conf calls]*
drop table confcallload;
select case when FO!='Unturfed' then substring(FO,7,len(FO)-10) end namefo
--, max(FO) foturf
, sum(neededconfcallyesterday)*1.985 OOVconfcalls
into confcallload
from eventattendees
where eventdate=current_date
group by 1;
--takes number of first-pass NH and CBs from Tier 1 - those that would get a second call
drop table tierload;
select substring(foname,7,len(foname)-10) namefo
,count(distinct ch.vanid2) tierload 
into tierload
from (select * from epbartlett.hist_tier where tier_class='Tier1' and tier_date=current_date-1)
left join (select vanid vanid2 from c2014_ar_coord_vansync.contacthistoryexportmc
where (case datecanvassed
        when datecanvassed::date then datecanvassed
        else datecanvassed-interval '1 Hour' end)::date=current_date-1
and contacttypeid=1 and resultid in (1,17)) ch on vanid=vanid2
group by 1;

--Calculates whether FOs made their minimul calls the previous night
drop table duty;
select 'Yesterday' timeperiod
,foturf turf
, 'Vol Recruitment' eventtype
,'Staff' cnvrtype
, count(distinct ch.contactscontactid) MyCCalls
, max(ccload.OOVconfcalls) calculatedconfcalls
,max(tierload) tierload
, case 
        when (count(distinct ch.contactscontactid)+max(coalesce(ccload.OOVconfcalls,0))+max(coalesce(tierload,0)))>=175 then 1
        when (count(distinct ch.contactscontactid)+max(coalesce(ccload.OOVconfcalls,0))+max(coalesce(tierload,0)))>=82 and extract(dow from current_date) in (6,0) then 1
        else 0 end didthurduty
into duty
from (select /*distinct*/ substring(foname,7,len(foname)-10) namefo, max(foname) foturf
from c2014_ar_coord_vansync.activityturfexport
group by 1) namemaker left join (select userid, firstname, lastname 
from c2014_ar_coord_vansync.vanusers) turfer
on lower(namefo)=lower(firstname)||' '||(case when left(lastname,1)='~' then substring(lower(lastname),2) else lower(lastname) end)
left join (select canvasserid userid, contactscontactid from c2014_ar_coord_vansync.contacthistoryexportmc
where (case datecanvassed
        when datecanvassed::date then datecanvassed
        else datecanvassed-interval '1 Hour' end)::date=current_date-1
and contacttypeid=1) ch using(userid)
left join confcallload ccload using(namefo)
left join tierload using(namefo)
group by 2 order by 5 desc
;


drop table DailyMorningReportBaseTable;
create table DailyMorningReportBaseTable as (
select * from eventsummary 
full outer join mycphonesummary using(timeperiod,turf,eventtype,cnvrtype) 
full outer join MyCContactSummary using(timeperiod,turf,eventtype,cnvrtype) 
full outer join myvcontacthistory using(timeperiod,turf,eventtype,cnvrtype) 
full outer join dialer using(timeperiod,turf,eventtype,cnvrtype) 
full outer join (select timeperiod,turf,eventtype,cnvrtype,didthurduty from duty) using(timeperiod,turf,eventtype,cnvrtype)
order by 2 desc,1)
;