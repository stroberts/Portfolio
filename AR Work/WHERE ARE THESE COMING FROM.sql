select eventscontactsstatuses.datecreated::date, count(*)
from c2014_ar_coord_vansync.eventscontactsstatuses
where datecreated>='2014-10-6'
group by 1
;

select *
from c2014_ar_coord_vansync.eventscontactsstatuses ecs
full outer join c2014_ar_coord_vansync.eventscontacts ec using(eventsignupid,state)
--where datecreated>='2014-10-6'
--and vanid=100011327
--and 
where eventsignupid in (70229,70228,70230)
;
select ea.region, ea.fo, ea.eventtype, ea.eventdate, en./*eventcalendarname */eventname, ea.currentstatus, ea.vanid, p.firstname||' '||p.lastname name, ea.eventsignupid
from eventattendees ea
left join (select eventid, /*eventcalendarname */eventname from c2014_ar_coord_vansync.events) en using(eventid)
left join (Select vanid, firstname, lastname from c2014_ar_coord_vansync.mycampaignperson) p using(vanid)
where ea.eventdate='2014-10-10'
and finalsitch=6
order by 1,2,4,3 asc
;

drop table checkeventattendees cascade;
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
        else 6 end finalsitch into sroberts.checkeventattendees from (
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
,case when isstaginglocation then locationname||'SL' else locationname end SL
,eventrolename rolename
,locationid
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
group by 1,2,3,4,5,6,7,9,10,11,12,13,14) shift
;
grant select on eventattendees to epbartlett;

select * from eventattendees
where vanid=100011327
;
select * from c2014_ar_coord_vansync.eventscontactsstatuses ecs
full outer join c2014_ar_coord_vansync.eventscontacts ec using(eventsignupid,state)
where ec.datesuppressed is not null
and ec.datetimeoffsetbegin>='2014-10-01'
;

select eventtype,rolename, count(*) from eventattendees where eventdate between '2014-10-10' and '2014-11-04'
and eventattendees.currentstatus in ('Left Msg','Scheduled','Confirmed')
and SL is not null
group by 1,2
order by 1,2;

select rolename, count(*) from eventattendees where eventattendees.eventtype='GOTV Event'
and eventattendees.currentstatus in ('Left Msg','Scheduled','Confirmed')
and SL is not null
group by 1 order by 2 desc
;

select eventtype,/*rolename,*/SL,locationid, count(*) from checkeventattendees where eventdate between '2014-10-10' and '2014-11-04'
and currentstatus in ('Left Msg','Scheduled','Confirmed')
--and SL is not null
group by 1,2,3
order by 1,2;

select * from c2014_ar_coord_vansync.locations where locations.locationid between 630 and 660 --648 is R3 OL - Jonesboro w/700 gotv shifts
order by locationid asc;
select * from c2014_ar_coord_vansync.locations where upper(left(locationname,2))='R3' --R3 OL - Jonesboro w/700 gotv shifts
order by locationid asc;


select * from c2014_team_ar.clintoneventmatch full outer join c2014_team_ar.clintonevent
left join sroberts."clinton wholw" using(first_name,last_name,phone_number)
on source_id=clintonevent.id
where matched_id is null
;

