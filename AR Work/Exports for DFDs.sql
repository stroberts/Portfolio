--Unclosed Shifts
select ea.region, ea.fo, ea.eventtype, ea.eventdate, en./*eventcalendarname */eventname, ea.currentstatus, ea.vanid, p.firstname||' '||p.lastname name
from actionplustimeeventattendees ea
left join (select eventid, /*eventcalendarname */eventname from c2014_ar_coord_vansync.events) en using(eventid)
left join (Select vanid, firstname, lastname from c2014_ar_coord_vansync.mycampaignperson) p using(vanid)
where timeperiod='Week to Date'
and finalsitch=6
order by 1,2,4,3 asc
;

--Unturfed Vols
Select case
        when timeperiod='Yesterday' and active=1 then 'New'
        when timeperiod='Yesterday' then 'Dropped off'
        when timeperiod='Week to Date' and active=1 then 'New'
        when timeperiod='Week to Date' then 'Dropped off'
        When timeperiod='Today' then 'Active'
        when timeperiod='Week to Come' then 'Danger!' end "voltype"
,vanid
,p.firstname||' '||p.lastname name
from activevols left join (Select vanid, firstname, lastname from c2014_ar_coord_vansync.mycampaignperson) p using(vanid)
where region='Unturfed' or fo='Unturfed'
;
--All Vols
Select case
        when timeperiod='Yesterday' and active=1 then 'New'
        when timeperiod='Yesterday' then 'Dropped off'
        when timeperiod='Week to Date' and active=1 then 'New'
        when timeperiod='Week to Date' then 'Dropped off'
        When timeperiod='Today' then 'Active'
        when timeperiod='Week to Come' then 'Danger!' end "voltype"
,vanid
,region
,p.lastname||', '||p.firstname name
from activevols left join (Select vanid, firstname, lastname from c2014_ar_coord_vansync.mycampaignperson) p using(vanid)
;