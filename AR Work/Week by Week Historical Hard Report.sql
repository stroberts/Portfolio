drop table weeks;

select distinct (recruiteddate-extract(dow from recruiteddate+2)::int%7) week
into weeks
from eventattendees
order by 1 asc;

insert into weeks
select max(week)+7 from weeks
;

--allocate all active or recently dropped off vols into a table, largly split on when they became/will become active/inactive (with those allocated to "today" simply added to keep the total right) 
drop table weekactivevols;
select week
,vanid
,region
,fo
, CASE
        --WHEN min(eventdate)=(low.week-interval '1 Day') then 'Yesterday'
        when min(eventdate)>=(low.week-1-extract(dow from low.week+1)%7) then 'Week to Date'
        when max(eventdate)>=(low.week-interval '24 Days') then 'Today'
        when max(eventdate)>=(low.week-interval '31 Days') then 'Week to Come'
        --when max(eventdate)=(low.week-interval '32 Days') then 'Yesterday'
        else 'Week to Date' end timeperiod
,max(eventtype) eventtype --needed only to keep from overmatching on join
,case when max(eventdate)>=(low.week-interval '31 Days') then 1 end Active
,case when max(eventdate)>=(low.week-interval '31 Days') then null else 1 end Dormant
into weekactivevols
from weeks low left join
eventattendees on eventdate<low.week
where eventtype in ('Voter Reg', 'Canvass', 'Phone Bank', 'Vol Recruitment','Data Entry','Signature Gathering')
and finalsitch=7
and eventdate>=(low.week-32-extract(dow from low.week+1)%7)
and eventdate<low.week
group by 1,2,3,4
;

--create a table of attendees categorized by whether they're attendees from the week to day, yesterday, or the weeek to come
--will be duplicates, which is fine - the category will differenciate

;

drop table weektimeeventattendees;
create table weektimeeventattendees as(
select week, 'Week to Date' as timeperiod
,* from weeks left join sroberts.eventattendees
on eventdate<weeks.week where eventdate>=(weeks.week-1-extract(dow from weeks.week+1)::int%7)
) union all (
select week, 'SchedWeek to Date' as timeperiod
,* from weeks left join sroberts.eventattendees
on recruiteddate<weeks.week and recruiteddate>=(weeks.week-1-extract(dow from weeks.week+1)::int%7)
) /*Union all (
select week, 'Yesterday' as timeperiod
,* from weeks left join sroberts.eventattendees
on eventdate=(weeks.week-interval '1 Day')
) union all (
select week, 'SchedYesterday' as timeperiod
,* from weeks left join sroberts.eventattendees
on recruiteddate=(weeks.week-interval '1 Day')
) union all (
select week, 'Week to Come' as timeperiod
,* from weeks left join sroberts.eventattendees
on eventdate>=weeks.week and eventdate<(weeks.week+7-extract(dow from weeks.week+2)::int%7)
and currentstatus!='Declined'
) Union all (
select week, 'Today' as timeperiod
,* from weeks left join sroberts.eventattendees
on eventdate=Weeks.week
) Union all (
select week, 'This Weekend' as timeperiod
,* from weeks left join sroberts.eventattendees
on eventdate in ((weeks.week+5-extract(dow from weeks.week+6)%7),(weeks.week+6-extract(dow from weeks.week+6)%7))
) union all (
select week, 'Next Week' as timeperiod
,* from weeks left join sroberts.eventattendees
on eventdate<(weeks.week+14-extract(dow from weeks.week+2)::int%7) and eventdate>=(weeks.week+7-extract(dow from weeks.week+2)::int%7)
)*/
;

update weektimeeventattendees
set week=(week-interval '7 days')
;
update weekactivevols
set week=(week-interval '7 days')
;

drop table weekactionplustimeeventattendees;
create table weekactionplustimeeventattendees as
select * from weektimeeventattendees a
where eventtype in ('Voter Reg', 'Canvass', 'Phone Bank', 'Vol Recruitment','1-on-1 Meeting','Signature Gathering')
;

drop table sroberts.weekeventsummary;
select * into sroberts.weekeventsummary from (
select week
, timeperiod
, Region turf
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
from sroberts.weekactionplustimeeventattendees shifts left join (
select week, timeperiod ,vanid, count(distinct eventtype) numeventtypes, sum(mod(finalsitch,2)) weight from sroberts.weekactionplustimeeventattendees
where eventtype!='1-on-1 Meeting'
and finalsitch=7
group by 1,2,3) weighter using(week,timeperiod,vanid)
group by 1,2,3,4,5
order by 1 desc, 2 asc
) c full OUTER join (select week
, right(timeperiod,len(timeperiod)-5) timeperiod
, Region  turf
, eventtype
, cnvrtype
,sum(rec.wasschedconfcomp) recruited
from sroberts.weekactionplustimeeventattendees rec--actioneventattendees is a view
where left(timeperiod,1)='S'
group by 1,2,3,4,5
order by 1 desc, 2
) b using(week,timeperiod,turf,eventtype,cnvrtype) full outer join (
select week
, timeperiod
, region turf
, 'Canvass' eventtype --this is only to keep the join from duplicating
, 'Vol' cnvrtype
, sum(active) newshowed
, sum(dormant) droppedoff
from weekactivevols
group by 1,2,3,4,5
) d using(week,timeperiod,turf,eventtype,cnvrtype)
order by 1 desc, 2,3 asc
;

insert into sroberts.weekeventsummary
select * from (
select week
, timeperiod
, 'Statewide' turf
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
from sroberts.weekactionplustimeeventattendees shifts left join (
select week, timeperiod ,vanid, count(distinct eventtype) numeventtypes, sum(mod(finalsitch,2)) weight from sroberts.weekactionplustimeeventattendees
where eventtype!='1-on-1 Meeting'
and finalsitch=7
group by 1,2,3) weighter using(week,timeperiod,vanid)
group by 1,2,3,4,5
order by 1 desc, 2 asc
) c full OUTER join (select week
, right(timeperiod,len(timeperiod)-5) timeperiod
, 'Statewide' turf
, eventtype
, cnvrtype
,sum(rec.wasschedconfcomp) recruited
from sroberts.weekactionplustimeeventattendees rec--actioneventattendees is a view
where left(timeperiod,1)='S'
group by 1,2,3,4,5
order by 1 desc, 2
) b using(week,timeperiod,turf,eventtype,cnvrtype) full outer join (
select week
, timeperiod
, 'Statewide' turf
, 'Canvass' eventtype --this is only to keep the join from duplicating
, 'Vol' cnvrtype
, sum(active) newshowed
, sum(dormant) droppedoff
from weekactivevols
group by 1,2,3,4
) d using(week,timeperiod,turf,eventtype,cnvrtype)
order by 1 desc, 2,3 asc
;


 


drop table weekMyCPhoneSummary
;

select (ch.datecanvassed::date-extract(dow from ch.datecanvassed::date+2)::int%7) week
,'Week to Date' timeperiod
, coalesce(Region,'Unturfed') turf
, 'Vol Recruitment' eventtype
,'Staff' cnvrtype
--,count(*) MyCAttempts
--,sum(case when ch.resultid=14 then 1 end) MyCContacts
,count(distinct ch.contactscontactid) MyCAttempts
,count(distinct case when ch.resultid=14 then ch.contactscontactid end) MyCContacts
into weekMyCPhoneSummary
from c2014_ar_coord_vansync.contacthistoryexportmc ch
left join c2014_ar_coord_vansync.mycampaignmergepersons mcmp on ch.vanid=mcmp.mergevanid
left join sroberts.attributer attr on coalesce(mcmp.mastervanid, ch.vanid)=attr.vanid
where ch.datecanvassed::date<current_date
and datecreated>='2014-02-01'
--and ch.datecanvassed::date>=(current_date-1-extract(dow from current_date+1)::int%7)
and contacttypeid=1--phone
group by 1,2,3
order by 1 desc, 2 asc
;
insert into weekMyCPhoneSummary
select (ch.datecanvassed::date-extract(dow from ch.datecanvassed::date+2)::int%7) week
,'Week to Date' timeperiod
, 'Statewide' turf
, 'Vol Recruitment' eventtype
,'Staff' cnvrtype
,count(distinct contactscontactid) MyCAttempts
,sum(case when ch.resultid=14 then 1 end) MyCContacts
from c2014_ar_coord_vansync.contacthistoryexportmc ch
--left join c2014_ar_coord_vansync.mycampaignmergepersons mcmp on ch.vanid=mcmp.mergevanid
--left join sroberts.attributer attr on coalesce(mcmp.mastervanid, ch.vanid)=attr.vanid
where ch.datecanvassed::date<current_date
--and ch.datecanvassed::date>=(current_date-1-extract(dow from current_date+1)::int%7)
and datecreated>='2014-02-01'
and contacttypeid=1--phone
group by 1,2
order by 1 desc, 2 asc
;

--create table of all (including non-phone) MyC Contacts - allows more accurate contacts/shift #s
drop table weekMyCContactSummary
;
select (ch.datecanvassed::date-extract(dow from ch.datecanvassed::date+2)::int%7) week
,'Week to Date' timeperiod
, coalesce(Region,'Unturfed') turf
, 'Vol Recruitment' eventtype
,'Staff' cnvrtype
,count(distinct case when ch.resultid=14 then ch.contactscontactid end) MyCAllContacts
into weekMyCContactSummary
from c2014_ar_coord_vansync.contacthistoryexportmc ch
left join c2014_ar_coord_vansync.mycampaignmergepersons mcmp on ch.vanid=mcmp.mergevanid
left join sroberts.attributer attr on coalesce(mcmp.mastervanid, ch.vanid)=attr.vanid
where ch.datecanvassed::date<current_date
--and ch.datecanvassed::date>=(current_date-1-extract(dow from current_date+1)::int%7)
and datecreated>='2014-02-01'
group by 1,2,3
order by 1 desc, 2 asc
;

insert into weekMyCContactSummary
select (ch.datecanvassed::date-extract(dow from ch.datecanvassed::date+2)::int%7) week
,'Week to Date' timeperiod
, 'Statewide' turf
, 'Vol Recruitment' eventtype
,'Staff' cnvrtype
,count(distinct case when ch.resultid=14 then ch.contactscontactid end) MyCAllContacts
from c2014_ar_coord_vansync.contacthistoryexportmc ch
where ch.datecanvassed::date<current_date
and datecreated>='2014-02-01'
--and ch.datecanvassed::date>=(current_date-1-extract(dow from current_date+1)::int%7)
group by 1,2,3
order by 1 desc, 2 asc
;

--different - more forgiving
drop table histusrtype
;
create table histusrtype as(
select canvasserid
,case min(typechar)
        when '!' then 'Fellow'
        when '#' then 'Vol'
        when '~' then 'Staff'
        when null then 'Null'
        else 'Vol' end cnvrtype --order asc: '!','#',number,alpha,'~'
from (select userid canvasserid, left(lastname,1) typechar from c2014_ar_coord_vansync.vanusers union select publicuserid canvasserid, left(publicusername,1) typechar from c2014_ar_coord_vansync.publicusers)
group by 1
order by 1 asc
)
;

drop table sroberts.weekmyvcontacthistory;
select (ch.datecanvassed::date-extract(dow from ch.datecanvassed::date+2)::int%7) week
,'Week to Date' timeperiod
, coalesce(attr.regionname,'Unturfed') turf--, coalesce(attr.foname,'Unturfed') 
,case when contacttypeid=1 then 'Phone Bank' else 'Canvass' end eventtype
,ut.cnvrtype
,count(*) DVCAttempts
,sum(case when resultid=14 then 1 end) DVCContacts
into weekmyvcontacthistory
from c2014_ar_coord_vansync.contacthistoryexport ch
left join analytics_ar.vanid_to_personid vtp using(vanid,state) 
left join (select personid, vanprecinctid as precinctid from analytics_ar.person) person using(personid) 
left join c2014_ar_coord_vansync.turfexport attr using(precinctid,state)-- on attr.precinctid=person.vanprecinctid and ch.state=attr.state
left join sroberts.histusrtype ut using(canvasserid)
where  contacttypeid in (1,2)
and datecreated>='2014-02-01'
and ch.committeeid=45240--Our's
group by 1,2,3,4,5
;
insert into weekmyvcontacthistory
select (ch.datecanvassed::date-extract(dow from ch.datecanvassed::date+2)::int%7) week
,'Week to Date' timeperiod
, 'Statewide' turf--, coalesce(attr.foname,'Unturfed') 
,case when contacttypeid=1 then 'Phone Bank' else 'Canvass' end eventtype
,ut.cnvrtype
,count(*) DVCAttempts
,sum(case when resultid=14 then 1 end) DVCContacts
from c2014_ar_coord_vansync.contacthistoryexport ch
--left join analytics_ar.vanid_to_personid vtp using(vanid,state) 
--left join (select personid, vanprecinctid as precinctid from analytics_ar.person) person using(personid) 
--left join c2014_ar_coord_vansync.turfexport attr using(precinctid,state)-- on attr.precinctid=person.vanprecinctid and ch.state=attr.state
left join sroberts.histusrtype ut using(canvasserid)
where contacttypeid in (1,2)
and datecreated>='2014-02-01'
and ch.committeeid=45240--Our's
group by 1,2,3,4,5
;

--VR
drop table sroberts.weekvr;
select (vr.datecreated::date-extract(dow from vr.datecreated::date+2)::int%7) week
,'Week to Date' timeperiod
, coalesce(vrc.region,'Unturfed') turf
,'Voter Reg' eventtype
,ut.cnvrtype
,count(*) VR
into sroberts.weekvr
from c2014_ar_coord_vansync.voterreg vr
left join (select distinct publicuserid as createdby, publicusername from c2014_ar_coord_vansync.publicusers) pu using(createdby)
left join (select distinct region,fo,publicusername  from sroberts.vrcanvasserattributer) vrc using(publicusername)
left join sroberts.histusrtype ut on vr.createdby=canvasserid
where left(vr.batchname,2)='AR'
and datecreated>='2014-02-01'
--and vr.datecreated>=(current_date-1-extract(dow from current_date+1)%7)
group by 1,2,3,4,5
order by 2 asc
;
insert into weekvr
select (vr.datecreated::date-extract(dow from vr.datecreated::date+2)::int%7) week
,'Week to Date' timeperiod
, 'Statewide' turf
,'Voter Reg' eventtype
,ut.cnvrtype
,count(*) VR
from c2014_ar_coord_vansync.voterreg vr
left join sroberts.histusrtype ut on vr.createdby=canvasserid
where left(vr.batchname,2)='AR'
and datecreated>='2014-02-01'
--and vr.datecreated>=(current_date-1-extract(dow from current_date+1)%7)
group by 1,2,3,4,5
order by 2 asc
;


drop table WeeklyHistReport;
create table WeeklyHistReport as (
select * from sroberts.weekeventsummary full outer join weekmycphonesummary using(week,timeperiod,turf,eventtype,cnvrtype) full outer join weekMyCContactSummary using(week,timeperiod,turf,eventtype,cnvrtype) full outer join weekmyvcontacthistory using(week,timeperiod,turf,eventtype,cnvrtype) full outer join weekvr using(week,timeperiod,turf,eventtype,cnvrtype)
order by 2 desc,1);
