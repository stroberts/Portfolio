--returns empty set, because no case where datecreated_max(eventsignupstatusid)<some other datecreated
select * from (
select a.eventsignupid
, max(case when rownum=1 then eventsignupseventstatusid end) latesteventsignupseventstatusid
,max(eventsignupseventstatusid) maxeventsignupseventstatusid
from (
select *, row_number() OVER(
 partition by eventsignupid
                order by datecreated desc                
) rownum
from c2014_ar_coord_vansync.eventscontactsstatuses
where datecreated>='2014-01-01') a
group by 1
) left join (
select datecreated latesttime
,eventsignupseventstatusid
from c2014_ar_coord_vansync.eventscontactsstatuses) b on latesteventsignupseventstatusid=b.eventsignupseventstatusid left join (
select datecreated maxstatidtime
,eventsignupseventstatusid
from c2014_ar_coord_vansync.eventscontactsstatuses) c on maxeventsignupseventstatusid=c.eventsignupseventstatusid
where latesteventsignupseventstatusid!=maxeventsignupseventstatusid and latesttime!=maxstatidtime;
