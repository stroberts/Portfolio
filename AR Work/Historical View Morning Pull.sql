
drop table actionpluseventattendees;
create table actionpluseventattendees as
select (eventdate-extract(dow from eventdate+2)::int%7) week, * from eventattendees a
where eventtype in ('Voter Reg', 'Canvass', 'Phone Bank', 'Vol Recruitment','1-on-1 Meeting')
;

drop table sroberts.historicaleventsummary;
select * into sroberts.historicaleventsummary from (
select week
, Region /*FO 'Statewide'*/ turf
,eventtype
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
from sroberts.actionpluseventattendees shifts left join (
select week ,vanid, count(distinct eventtype) numeventtypes, sum(mod(finalsitch,2)) weight from sroberts.actionpluseventattendees
where eventtype!='1-on-1 Meeting'
and finalsitch=7
group by 1,2) weighter using(week,vanid)
group by 1,2,3
order by 1 desc, 2 asc
) c full OUTER join (select (rec.recruiteddate-1-extract(dow from rec.recruiteddate+1)::int%7) week
, Region /*FO 'Statewide'*/ turf
, eventtype
,sum(rec.wasschedconfcomp) recruited
from sroberts.actionplustimeeventattendees rec--actioneventattendees is a view
where left(timeperiod,1)='S'
group by 1,2,3
order by 1 desc, 2
) b using(week,turf,eventtype)/* full outer join (
select timeperiod
, region turf
, 'Canvass' eventtype --this is only to keep the join from duplicating
, sum(active) newshowed
, sum(dormant) droppedoff
from activevols
group by 1,2,3
) d using(timeperiod,turf,eventtype)*/
order by 1 desc, 2,3 asc
;
insert into sroberts.historicaleventsummary
select * from (select week
, FO /*FO 'Statewide'*/ turf
,eventtype
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
from sroberts.actionpluseventattendees shifts left join (
select week ,vanid, count(distinct eventtype) numeventtypes, sum(mod(finalsitch,2)) weight from sroberts.actionpluseventattendees
where eventtype!='1-on-1 Meeting'
and finalsitch=7
group by 1,2) weighter using(week,vanid)
group by 1,2,3
order by 1 desc, 2 asc
) c full OUTER join (select (rec.recruiteddate-1-extract(dow from rec.recruiteddate+1)::int%7) week
, FO /*FO 'Statewide'*/ turf
, eventtype
,sum(rec.wasschedconfcomp) recruited
from sroberts.actionplustimeeventattendees rec--actioneventattendees is a view
where left(timeperiod,1)='S'
group by 1,2,3
order by 1 desc, 2
) b using(week,turf,eventtype)
order by 1 desc, 2,3 asc
;
insert into sroberts.historicaleventsummary
select * from (select week
, 'Statewide' turf
,eventtype
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
from sroberts.actionpluseventattendees shifts left join (
select week ,vanid, count(distinct eventtype) numeventtypes, sum(mod(finalsitch,2)) weight from sroberts.actionpluseventattendees
where eventtype!='1-on-1 Meeting'
and finalsitch=7
group by 1,2) weighter using(week,vanid)
group by 1,2,3
order by 1 desc, 2 asc
) c full OUTER join (select (rec.recruiteddate-1-extract(dow from rec.recruiteddate+1)::int%7) week
, 'Statewide' turf
, eventtype
,sum(rec.wasschedconfcomp) recruited
from sroberts.actionplustimeeventattendees rec--actioneventattendees is a view
where left(timeperiod,1)='S'
group by 1,2,3
order by 1 desc, 2
) b using(week,turf,eventtype)
order by 1 desc, 2,3 asc
;

drop table HistoricalMyCPhoneSummary
;

select (ch.datecanvassed::date-extract(dow from ch.datecanvassed::date+2)::int%7) week
, coalesce(Region,'Unturfed') turf
, 'Vol Recruitment' eventtype
--,count(*) MyCAttempts
--,sum(case when ch.resultid=14 then 1 end) MyCContacts
,count(distinct ch.contactscontactid) MyCAttempts
,count(distinct case when ch.resultid=14 then ch.contactscontactid end) MyCContacts
into HistoricalMyCPhoneSummary
from c2014_ar_coord_vansync.contacthistoryexportmc ch
left join c2014_ar_coord_vansync.mycampaignmergepersons mcmp on ch.vanid=mcmp.mergevanid
left join sroberts.attributer attr on coalesce(mcmp.mastervanid, ch.vanid)=attr.vanid
where ch.datecanvassed::date<current_date
--and ch.datecanvassed::date>=(current_date-1-extract(dow from current_date+1)::int%7)
and contacttypeid=1--phone
group by 1,2
order by 1 desc, 2 asc
;
insert into HistoricalMyCPhoneSummary
select (ch.datecanvassed::date-extract(dow from ch.datecanvassed::date+2)::int%7) week
, coalesce(Organizer,'Unturfed') turf
, 'Vol Recruitment' eventtype
,count(*) MyCAttempts
,sum(case when ch.resultid=14 then 1 end) MyCContacts
from c2014_ar_coord_vansync.contacthistoryexportmc ch
left join c2014_ar_coord_vansync.mycampaignmergepersons mcmp on ch.vanid=mcmp.mergevanid
left join sroberts.attributer attr on coalesce(mcmp.mastervanid, ch.vanid)=attr.vanid
where ch.datecanvassed::date<current_date
--and ch.datecanvassed::date>=(current_date-1-extract(dow from current_date+1)::int%7)
and contacttypeid=1--phone
group by 1,2
order by 1 desc, 2 asc
;
insert into HistoricalMyCPhoneSummary
select (ch.datecanvassed::date-extract(dow from ch.datecanvassed::date+2)::int%7) week
, 'Statewide' turf
, 'Vol Recruitment' eventtype
,count(*) MyCAttempts
,sum(case when ch.resultid=14 then 1 end) MyCContacts
from c2014_ar_coord_vansync.contacthistoryexportmc ch
--left join c2014_ar_coord_vansync.mycampaignmergepersons mcmp on ch.vanid=mcmp.mergevanid
--left join sroberts.attributer attr on coalesce(mcmp.mastervanid, ch.vanid)=attr.vanid
where ch.datecanvassed::date<current_date
--and ch.datecanvassed::date>=(current_date-1-extract(dow from current_date+1)::int%7)
and contacttypeid=1--phone
group by 1,2
order by 1 desc, 2 asc
;

drop table historicaloneonones
;
select (sq.datecanvassed::date-extract(dow from sq.datecanvassed::date+2)::int%7) week
, coalesce(Region,'Unturfed') turf
, '1-on-1 Meeting' eventtype
,sum(case when sq.surveyresponseid in (692860,692861,692862) then 1 end) "1:1s"
into historicalOneonOnes
from c2014_ar_coord_vansync.surveyresponseexportmc sq
left join c2014_ar_coord_vansync.mycampaignmergepersons mcmp on sq.vanid=mcmp.mergevanid
left join sroberts.attributer attr on coalesce(mcmp.mastervanid, sq.vanid)=attr.vanid
where sq.datecanvassed::date<current_date
--and sq.datecanvassed::date>=(current_date-1-extract(dow from current_date+1)::int%7)
and sq.surveyquestionid=163085--1:1s
group by 1,2
order by 1 desc, 2 asc
;
insert into historicalOneonOnes
select (sq.datecanvassed::date-extract(dow from sq.datecanvassed::date+2)::int%7) week
, coalesce(Organizer,'Unturfed') turf
, '1-on-1 Meeting' eventtype
,sum(case when sq.surveyresponseid in (692860,692861,692862) then 1 end) "1:1s"
from c2014_ar_coord_vansync.surveyresponseexportmc sq
left join c2014_ar_coord_vansync.mycampaignmergepersons mcmp on sq.vanid=mcmp.mergevanid
left join sroberts.attributer attr on coalesce(mcmp.mastervanid, sq.vanid)=attr.vanid
where sq.datecanvassed::date<current_date
--and sq.datecanvassed::date>=(current_date-1-extract(dow from current_date+1)::int%7)
and sq.surveyquestionid=163085--1:1s
group by 1,2
order by 1 desc, 2 asc
;
insert into historicalOneonOnes
select (sq.datecanvassed::date-extract(dow from sq.datecanvassed::date+2)::int%7) week
, 'Statewide' turf
, '1-on-1 Meeting' eventtype
,sum(case when sq.surveyresponseid in (692860,692861,692862) then 1 end) "1:1s"
from (
select *, row_number() over(
partition by vanid,
(datecanvassed-interval '1 hour')::date
order by contactssurveyresponseid desc
) rn from
c2014_ar_coord_vansync.surveyresponseexportmc) sq
--left join c2014_ar_coord_vansync.mycampaignmergepersons mcmp on sq.vanid=mcmp.mergevanid
--left join sroberts.attributer attr on coalesce(mcmp.mastervanid, sq.vanid)=attr.vanid
where sq.datecanvassed::date<current_date
--and sq.datecanvassed::date>=(current_date-1-extract(dow from current_date+1)::int%7)
and sq.surveyquestionid=163085--1:1s
and sq.rn=1
group by 1,2,3
order by 1 desc, 2 asc
;

drop table sroberts.historicalmyvcontacthistory;
select (ch.datecanvassed::date-extract(dow from ch.datecanvassed::date+2)::int%7) week
, coalesce(attr.regionname,'Unturfed') turf--, coalesce(attr.foname,'Unturfed') 
,case when contacttypeid=1 then 'Phone Bank' else 'Canvass' end eventtype
,count(*) DVCAttempts
,sum(case when resultid=14 then 1 end) DVCContacts
into historicalmyvcontacthistory
from c2014_ar_coord_vansync.contacthistoryexport ch
left join analytics_ar.vanid_to_personid vtp using(vanid,state) 
left join (select personid, vanprecinctid as precinctid from analytics_ar.person) person using(personid) 
left join c2014_ar_coord_vansync.turfexport attr using(precinctid,state)-- on attr.precinctid=person.vanprecinctid and ch.state=attr.state
where contacttypeid in (1,2)
and ch.committeeid=45240--Our's
group by 1,2,3
;
insert into historicalmyvcontacthistory
select (ch.datecanvassed::date-extract(dow from ch.datecanvassed::date+2)::int%7) week
, coalesce(attr.foname,'Unturfed') turf--, coalesce(attr.foname,'Unturfed') 
,case when contacttypeid=1 then 'Phone Bank' else 'Canvass' end eventtype
,count(*) DVCAttempts
,sum(case when resultid=14 then 1 end) DVCContacts
from c2014_ar_coord_vansync.contacthistoryexport ch
left join analytics_ar.vanid_to_personid vtp using(vanid,state) 
left join (select personid, vanprecinctid as precinctid from analytics_ar.person) person using(personid) 
left join c2014_ar_coord_vansync.turfexport attr using(precinctid,state)-- on attr.precinctid=person.vanprecinctid and ch.state=attr.state
where contacttypeid in (1,2)
and ch.committeeid=45240--Our's
group by 1,2,3
;
insert into historicalmyvcontacthistory
select (ch.datecanvassed::date-extract(dow from ch.datecanvassed::date+2)::int%7) week
, 'Statewide' turf--, coalesce(attr.foname,'Unturfed') 
,case when contacttypeid=1 then 'Phone Bank' else 'Canvass' end eventtype
,count(*) DVCAttempts
,sum(case when resultid=14 then 1 end) DVCContacts
from c2014_ar_coord_vansync.contacthistoryexport ch
--left join analytics_ar.vanid_to_personid vtp using(vanid,state) 
--left join (select personid, vanprecinctid as precinctid from analytics_ar.person) person using(personid) 
--left join c2014_ar_coord_vansync.turfexport attr using(precinctid,state)-- on attr.precinctid=person.vanprecinctid and ch.state=attr.state
where contacttypeid in (1,2)
and ch.committeeid=45240--Our's
group by 1,2,3
;

--VR
drop table sroberts.historicalvr;
select (vr.datecreated::date-extract(dow from vr.datecreated::date+2)::int%7) week
, coalesce(vrc.region,'Unturfed') turf
,'Voter Reg' eventtype
,count(*) VR
into sroberts.historicalvr
from c2014_ar_coord_vansync.voterreg vr
left join (select distinct publicuserid as createdby, publicusername from c2014_ar_coord_vansync.publicusers) pu using(createdby)
left join (select distinct region,fo,publicusername  from sroberts.vrcanvasserattributer) vrc using(publicusername)
where left(vr.batchname,2)='AR'
--and vr.datecreated>=(current_date-1-extract(dow from current_date+1)%7)
group by 1,2,3
order by 2 asc
;
insert into historicalvr
select (vr.datecreated::date-extract(dow from vr.datecreated::date+2)::int%7) week
, 'Statewide' turf
,'Voter Reg' eventtype
,count(*) VR
from c2014_ar_coord_vansync.voterreg vr
left join (select distinct publicuserid as createdby, publicusername from c2014_ar_coord_vansync.publicusers) pu using(createdby)
left join (select distinct region,fo,publicusername  from sroberts.vrcanvasserattributer) vrc using(publicusername)
where left(vr.batchname,2)='AR'
--and vr.datecreated>=(current_date-1-extract(dow from current_date+1)%7)
group by 1,2,3
order by 2 asc
;


drop table WeeklyMorningReportBaseTable;
create table WeeklyMorningReportBaseTable as (
select * from historicaleventsummary full outer join historicalmycphonesummary using(week,turf,eventtype) full outer join historicaloneonones using(week,turf,eventtype) full outer join historicalmyvcontacthistory using(week,turf,eventtype) full outer join historicalvr using(week,turf,eventtype)
order by 2 desc,1);
