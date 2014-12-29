--this is a straight upload of the agent reports hubdialer spits out
select * from sroberts.agentreports;

--dialerattributer is fed by a google doc/form that collects 
--the mrr for a particular phone number and which FO/Region it belongs to
--MyCPersons is used as a backup plan

/* THIS IS WHERE THE MAGIC HAPPENS! 40% attrbution from MyC alone! (with no real answers in form)*/
select coalesce(Region,regionname) Region, coalesce(FO,foname) FO,sum(datediff(hour,logged_in,logged_out)+datediff(minute,logged_in,logged_out)::float/60+datediff(minute,logged_in,logged_out)::float/3600) hrs from sroberts.agentreports left join sroberts.dialerattributer using(phone_number)
left join (select phone::bigint phone_number, max(regionname) regionname, max(foname) foname from c2014_ar_coord_vansync.mycampaignperson_turf where phone is not null group by 1) using(phone_number)
group by 1,2
order by 1,2;

--thanks, Matthew, for saving me at least one join and coalesce here
select * from c2014_ar_coord_vansync.mycampaignperson_turf
limit 20;

--adapted for use in my main query
drop table sroberts.dialer;
select case when agentreports.logged_out::date=(current_date-interval '1 Day') then 'Yesterday'
else 'Week to Date' end timeperiod
, coalesce(Region,regionname,'Unturfed') turf
,'Dialer' eventtype
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
,'Dialer' eventtype
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
,'Dialer' eventtype
,'Vol' cnvrtype
,sum(datediff(hour,logged_in,logged_out)+datediff(minute,logged_in,logged_out)::float/60+datediff(minute,logged_in,logged_out)::float/3600) hrs
from sroberts.agentreports
where agentreports.logged_out>=(current_date-1-extract(dow from current_date+1)%7)
group by 1,2,3,4
)
order by 2 asc
;

drop table sroberts.dialerattributer ;

--adding dialer contacts to the vc tables
drop table myvcontacthistory;
select case when ch.datecanvassed::date=(current_date-interval '1 Day') then 'Yesterday' else 'Week to Date' end timeperiod
, coalesce(attr.regionname,'Unturfed') turf--, coalesce(attr.foname,'Unturfed')
,case contacttypeid when 1 then 'Phone Bank' when 19 then 'Dialer' else 'Canvass' end eventtype
,ut.cnvrtype
,count(distinct case when contacttypeid=1 then ch.contactscontactid else addressid end) DVCAttempts
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
,count(distinct case when contacttypeid=1 then ch.contactscontactid else addressid end) DVCAttempts
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
,count(*) DVCAttempts
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

select * from vansync.contacttypecodes;



--,case eventrolename when '' then 'Dialer' else eventrolename end rolename
drop table agentreports;
create table agentreports(
campaign_id int
,agent_id int
,name varchar(1024)
,phone_number bigint
,email varchar(1024)
,logged_in datetime
,logged_out datetime
,total_call_duration_sec int
,_calls_taken int
,avg_call_duration_sec int
,avg_talk_time_sec int
,avg_response_time_sec int
,avg_wait_time_sec int
);,count(distinct addressid) DVCKnocks
,count(*) DVCAttempts


select coalesce(vrc.fo,'Unturfed') turf
, publicusername
,ut.cnvrtype
,count(distinct coalesce(vanid,0)||batchid) VR
,Case when vrc.fo is null then 'Unturfed' else 'Out of Date Turf Name' end 
from c2014_ar_coord_vansync.voterreg vr
left join (select distinct publicuserid as createdby, publicusername from c2014_ar_coord_vansync.publicusers) pu using(createdby)
left join (select distinct region,fo,publicusername  from sroberts.vrcanvasserattributer) vrc using(publicusername)
left join sroberts.usrtype ut on vr.createdby=canvasserid
left join (select distinct coalesce(foname,'Unturfed') fo, 'current' c from c2014_ar_coord_vansync.activityturfexport) ate using(fo)
where left(vr.batchname,2)='AR'
and vr.datecreated>=(current_date-1-extract(dow from current_date+1)%7)
and (vrc.fo is null or ate.c is null)
group by 1,2,3,5
order by 1,3,2 desc
;


select phone_number,sum(datediff(hour,logged_in,logged_out)+datediff(minute,logged_in,logged_out)::float/60+datediff(minute,logged_in,logged_out)::float/3600) hrs
from sroberts.agentreports left join sroberts.dialerattributer using(phone_number)
left join (select phone::bigint phone_number, max(regionname) regionname, max(foname) foname from c2014_ar_coord_vansync.mycampaignperson_turf where phone is not null group by 1) using(phone_number)
where agentreports.logged_out>=(current_date-1-extract(dow from current_date+1)%7)
and coalesce(Region,regionname) is null
group by 1
order by 1 asc
;



