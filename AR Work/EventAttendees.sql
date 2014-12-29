/*Event Attendees contains most of the information one needs to aggregate for
various event-related questions in a single table. EventSignupID  can facilitate
a join back to eventscontacts, vanid allows one to go  deeper in to the attendee.
The table itself, however, keeps the regional assignment, initial recruitment
date, event date, final status, and whether the person was confirmed in a
1 row/(event*attendee) format.
*/
drop table sroberts.eventattendees;
select *, case
        when shift.wasconfirmed=1 and shift.currentstatus='Completed' then 'Confirmed_completed'
        when shift.wasconfirmed=1 and (shift.currentstatus='No Show' or shift.currentstatus='Declined') then 'Confirmed_uncompleted'
        when shift.wasconfirmed=1 then 'Confirmed_unclosed'
        when shift.currentstatus='Completed' then 'Unconfirmed_completed'
        when (shift.currentstatus='No Show' or shift.currentstatus='Declined') then 'Unconfirmed_uncompleted'
        else 'Unconfirmed_unclosed' end finalsitch
        ,case -- 0 (mod 5)=>[incomplete by Console standards], 1 (mod 5)=>complete, 0 (mod 10)
        when shift.wasconfirmed=1 and shift.currentstatus='Completed' then 11
        when shift.wasconfirmed=1 and (shift.currentstatus='No Show' or shift.currentstatus='Declined') then 10
        when shift.wasconfirmed=1 then 15
        when shift.currentstatus='Completed' then 1
        when (shift.currentstatus='No Show' or shift.currentstatus='Declined') then 0
        else 5 end finalsitchcode into sroberts.eventattendees from (
select status.eventsignupid
, turf.regionname Region
, turf.foname FO
, turf.teamname Team
, min(left(status.datecreated,10)) recruited_date
, econtact.vanid
, events.eventcalendarname eventtype
, left(events.dateoffsetbegin,10) eventdate
, max(
        case when status.rownumber=1 then status.eventstatusname
        else NULL end) currentstatus
,max(
        case when status.eventstatusname='Confirmed' then 1
        else 0 end) wasconfirmed        
--into sroberts.eventattendees
from (
        select *
        , row_number() OVER(
                partition by eventsignupid
                order by left(datecreated,10) desc,
                iscurrentstatus desc
                ) rownumber
        from c2014_ar_coord_vansync.eventscontactsstatuses 
        ) status left join 
        c2014_ar_coord_vansync.eventscontacts econtact using(eventsignupid) left join
        c2014_ar_coord_vansync.events using(eventid) left join
        c2014_ar_coord_vansync.mycampaignperson person on econtact.vanid=person.vanid /*using(vanid)*/ left join
        c2014_ar_coord_vansync.turfexport turf using(precinctid)
--where econtact.vanid is null and left(status.datecreated,4)='2014'
group by 1,2,3,4,6,7,8) shift
;

--Alt Event attendee table construction
drop table sroberts.eventattendeesalt;
select status.eventsignupid
, turf.regionname Region
, turf.foname FO
, turf.teamname Team
, min(left(status.datecreated,10)) recruited_date
, econtact.vanid
, events.eventcalendarname eventtype
, left(events.dateoffsetbegin,10) eventdate
, max(
        case when status.rownumber=1 then status.eventstatusname
        else NULL end) currentstatus
,max(
        case when status.eventstatusname='Confirmed' then 1
        else 0 end) wasconfirmed        
into sroberts.eventattendeesalt
from c2014_ar_coord_vansync.eventscontacts econtact join (
        select *
        , row_number() OVER(
                partition by eventsignupid
                order by left(datecreated,10) desc,
                iscurrentstatus desc
                ) rownumber
        from c2014_ar_coord_vansync.eventscontactsstatuses 
        ) status using(eventsignupid) left join
        c2014_ar_coord_vansync.events using(eventid) left join
        c2014_ar_coord_vansync.mycampaignperson person on econtact.vanid=person.vanid /*using(vanid)*/ left join
        c2014_ar_coord_vansync.turfexport turf using(precinctid)
--where econtact.vanid is null and left(status.datecreated,4)='2014'
where status.eventsignupid is not null
group by 1,2,3,4,6,7,8
;

--Regional breakdown for a particular day
select  coalesce(Region,'Unturfed') Region
--,FO
, sum(case when shifts.currentstatus='Completed' and shifts.wasconfirmed=1 then 1 else 0 end) Confirmed_completed
, sum(case when (shifts.currentstatus='No Show' or shifts.currentstatus='Declined') and shifts.wasconfirmed=1 then 1 else 0 end) Confirmed_uncompleted
, sum(case when shifts.currentstatus='Completed' and shifts.wasconfirmed=0 then 1 else 0 end) unConfirmed_completed
, sum(case when (shifts.currentstatus='No Show' or shifts.currentstatus='Declined') and shifts.wasconfirmed=0 then 1 else 0 end) unConfirmed_uncompleted
from sroberts.eventattendeesalt shifts
where shifts.eventdate='2014-06-04' and (shifts.eventtype='Voter Reg' or shifts.eventtype='Phone Bank' or shifts.eventtype='Canvass')
group by 1
order by 1 asc
;
--Regional breakdown by week
select case
        when shifts.eventdate>='2014-05-30' then '2014-05-30'
        when shifts.eventdate>='2014-05-23' then '2014-05-23'
        when shifts.eventdate>='2014-05-16' then '2014-05-16'
        when shifts.eventdate>='2014-05-09' then '2014-05-09'
        when shifts.eventdate>='2014-05-02' then '2014-05-02'
        else 'April' end Week
, coalesce(Region,'Unturfed') Region
--,FO
, sum(case when shifts.currentstatus='Completed' and shifts.wasconfirmed=1 then 1 else 0 end) Confirmed_completed
, sum(case when (shifts.currentstatus='No Show' or shifts.currentstatus='Declined') and shifts.wasconfirmed=1 then 1 else 0 end) Confirmed_uncompleted
, sum(case when shifts.currentstatus='Completed' and shifts.wasconfirmed=0 then 1 else 0 end) unConfirmed_completed
, sum(case when (shifts.currentstatus='No Show' or shifts.currentstatus='Declined') and shifts.wasconfirmed=0 then 1 else 0 end) unConfirmed_uncompleted
from sroberts.eventattendees shifts
where shifts.eventdate<current_date::varchar(12) and (shifts.eventtype='Voter Reg' or shifts.eventtype='Phone Bank' or shifts.eventtype='Canvass')
group by 1,2--,3
order by 1 desc, 2/*,3*/ asc
;

select case
        when shifts.eventdate>='2014-05-30' then '2014-05-30'
        when shifts.eventdate>='2014-05-23' then '2014-05-23'
        when shifts.eventdate>='2014-05-16' then '2014-05-16'
        when shifts.eventdate>='2014-05-09' then '2014-05-09'
        when shifts.eventdate>='2014-05-02' then '2014-05-02'
        else 'April' end Week
, coalesce(Region,'Unturfed') Region
--,FO
/*, case
        when shifts.wasconfirmed=1 and shifts.currentstatus='Complete' then 'Confirmed_completed'
        when shifts.wasconfirmed=1 and (shifts.currentstatus='No Show' or shifts.currentstatus='Declined') then 'Confirmed_uncompleted'
        when shifts.wasconfirmed=1 then 'Confirmed_unclosed'
        when shifts.currentstatus='Complete' then 'Unconfirmed_completed'
        when (shifts.currentstatus='No Show' or shifts.currentstatus='Declined') then 'Unconfirmed_uncompleted'
        else 'Unconfirmed_unclosed' end finalsitch*/
, shifts.finalsitch
, count(*)
, sum(case when shifts.currentstatus='Completed' and shifts.wasconfirmed=1 then 1 else 0 end) Confirmed_completed
, sum(case when (shifts.currentstatus='No Show' or shifts.currentstatus='Declined') and shifts.wasconfirmed=1 then 1 else 0 end) Confirmed_uncompleted
, sum(case when shifts.currentstatus='Completed' and shifts.wasconfirmed=0 then 1 else 0 end) unConfirmed_completed
, sum(case when (shifts.currentstatus='No Show' or shifts.currentstatus='Declined') and shifts.wasconfirmed=0 then 1 else 0 end) unConfirmed_uncompleted
from (
select case
        when shift.wasconfirmed=1 and shift.currentstatus='Completed' then 'Confirmed_completed'
        when shift.wasconfirmed=1 and (shift.currentstatus='No Show' or shift.currentstatus='Declined') then 'Confirmed_uncompleted'
        when shift.wasconfirmed=1 then 'Confirmed_unclosed'
        when shift.currentstatus='Completed' then 'Unconfirmed_completed'
        when (shift.currentstatus='No Show' or shift.currentstatus='Declined') then 'Unconfirmed_uncompleted'
        else 'Unconfirmed_unclosed' end finalsitch
, * from
sroberts.eventattendees shift) shifts
where shifts.eventdate<current_date::varchar(12) and (shifts.eventtype='Voter Reg' or shifts.eventtype='Phone Bank' or shifts.eventtype='Canvass')
group by 1,2,3--,3
order by 1 desc, 2,3/*,3*/ asc


