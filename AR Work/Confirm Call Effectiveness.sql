drop table eventstatusbasetable;
select st.eventsignupid
, max(case when st.iscurrentstatus=1 and st.eventstatusname='Completed' then 1 else 0 end) completed
, max(case when st.iscurrentstatus=1 and st.eventstatusname='Declined' then 1 else 0 end) declined
, max(case when st.iscurrentstatus=1 and st.eventstatusname='No Show' then 1 else 0 end) NoShow
, max(case when st.eventstatusname='Confirmed' then 1 else 0 end) confirmed
, max(case when st.eventstatusname='Left Msg' then 1 else 0 end) messageleft
into eventstatusbasetable
from /*dortiz*/c2014_ar_coord_vansync.eventscontactsstatuses st left join (
select eventsignupid, eventid from /*dortiz*/c2014_ar_coord_vansync.eventscontacts) ec using(eventsignupid) left join (
select eventid, eventcalendarname, dateoffsetbegin from /*dortiz*/c2014_ar_coord_vansync.events) e using(eventid)
where left(e.dateoffsetbegin,4)='2014' AND left(e.dateoffsetbegin,10)<'2014-05-28' AND (e.eventcalendarname='Voter Reg' OR e.eventcalendarname='Vol Recruitment' OR e.eventcalendarname='Canvass' OR e.eventcalendarname='Phone Bank')
group by 1;

grant select on table eventstatusbasetable to dortiz;
grant usage on schema sroberts to dortiz;

--linear format
select/* left(a.datecreated,4)
,*/ count(*) total
, sum(a.completed) complete
, sum(a.declined) declined
, sum(a.noshow) NoShow
, sum(case when a.completed=1 and a.confirmed=1 then 1 else 0 end) confirmed_then_completed
, sum(case when a.declined+a.noshow=1 and a.confirmed=1 then 1 else 0 end) confirmed_then_incomplete
, sum(case when a.completed=1 and a.confirmed=0 then 1 else 0 end) unconfirmed_then_completed
, sum(case when a.declined+a.noshow=1 and a.confirmed=0 then 1 else 0 end) unconfirmed_then_incomplete
, sum(case when a.completed=1 and a.messageleft=1 then 1 else 0 end) lm_then_completed
, sum(case when a.declined+a.noshow=1 and a.messageleft=1 then 1 else 0 end) lm_then_incomplete
, sum(case when a.completed=1 and a.messageleft=0 then 1 else 0 end) no_lm_then_completed
, sum(case when a.declined+a.noshow=1 and a.messageleft=0 then 1 else 0 end) no_lm_then_incomplete from sroberts.eventstatusbasetable a;
--tablular format, suitable to Excel manipulation
select case
        when a.completed=1 then 'Completed'
        when a.declined=1 then 'Declined'
        when a.noshow=1 then 'No Show'
        else 'Unclosed'
        end as FinalStatus
, sum(a.confirmed) Confirmed
, sum(a.messageleft) LeftMessage
, count(*) AllStatuses from sroberts.eventstatusbasetable a
group by 1; 
