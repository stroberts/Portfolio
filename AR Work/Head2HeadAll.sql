--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
-------------------------------------------new senate forecast------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

select * from (
select /*'Statewide'*/ county, coalesce(ev,'nvy') voted
,100*sum(case 
        when ev in ('ev','ab') then civis.senate_support_2014/100
        else civis.senate_support_2014*civis.turnout_2014/10000 end)/sum(case when ev in ('ev','ab') then 1 else civis.turnout_2014/100 end) h2hprimary 
,100*sum(case 
        when ev in ('ev','ab') then civis.senate_support_2014/100
        else civis.senate_support_2014*(civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end)/
        sum(case when ev in ('ev','ab') then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end) h2hsecondary
,sum(case when ev in ('ev','ab') then 1 else civis.turnout_2014/100 end)::dec(38,2) primary_turnout
,sum(case when ev in ('ev','ab') then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end)::dec(38,2) secondary_turnout
,sum(case 
        when ev is null then civis.senate_support_2014*(civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end) h2himpact
from (select personid, votebuilder_identifier,precinctid,vanprecinctid,county_name pcounty from analytics_ar.person where is_current_reg) person
full outer join (select vanid votebuilder_identifier, list_name ev from c2014_team_ar.vanevbatch) evoters using(votebuilder_identifier)
left join analytics_ar.all_civis_scores civis using(personid)
left join (select votebuilder_identifier, sum(contacts) contacts from (select * from (select vanid votebuilder_identifier,count(distinct contacthistoryexport.contactscontactid) contacts from c2014_ar_coord_vansync.contacthistoryexport 
        where contacthistoryexport.datecanvassed::date>='2014-10-20'::date and contacttypeid in (1,2) and contacthistoryexport.resultid=14 group by 1) union all (
        select vanid votebuilder_identifier, count(/*case lower(ans) when 'no' then null else */ans/* end*/) contacts from  edayhdv group by 1)) group by 1) contacts using(votebuilder_identifier)
        --this lets me take into account dialer contacts made today
left join (select county,precinctname,precinctid from precinct_basetable) using(precinctid)
group by 1,2 order by 1,2) union all (
select 'All State' county, coalesce(ev,'nvy') voted
,100*sum(case 
        when ev in ('ev','ab') then civis.senate_support_2014/100
        else civis.senate_support_2014*civis.turnout_2014/10000 end)/sum(case when ev in ('ev','ab') then 1 else civis.turnout_2014/100 end) h2hprimary 
,100*sum(case 
        when ev in ('ev','ab') then civis.senate_support_2014/100
        else civis.senate_support_2014*(civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end)/
        sum(case when ev in ('ev','ab') then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end) h2hsecondary
,sum(case when ev in ('ev','ab') then 1 else civis.turnout_2014/100 end)::dec(38,2) primary_turnout
,sum(case when ev in ('ev','ab') then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end)::dec(38,2) secondary_turnout
,sum(case 
        when ev is null then civis.senate_support_2014*(civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end) h2himpact
/*,sum(case 
        when ev='ev' then civis.senate_support_2014/100
        else civis.senate_support_2014*civis.turnout_2014/10000 end) pvotersev*/
from (select personid, votebuilder_identifier,precinctid,vanprecinctid,county_name pcounty from analytics_ar.person where is_current_reg) person
full outer join (select vanid votebuilder_identifier, list_name ev from c2014_team_ar.vanevbatch) evoters using(votebuilder_identifier)
left join analytics_ar.all_civis_scores civis using(personid)
left join (select votebuilder_identifier, sum(contacts) contacts from (select * from (select vanid votebuilder_identifier,count(distinct contacthistoryexport.contactscontactid) contacts from c2014_ar_coord_vansync.contacthistoryexport 
        where contacthistoryexport.datecanvassed::date>='2014-10-20'::date and contacttypeid in (1,2) and contacthistoryexport.resultid=14 group by 1) union all (
        select vanid votebuilder_identifier, count(/*case lower(ans) when 'no' then null else */ans/* end*/) contacts from  edayhdv group by 1)) group by 1) contacts using(votebuilder_identifier)
left join (select county,precinctname,precinctid from precinct_basetable) using(precinctid)
group by 1,2) union all (
select /*'Statewide'*/ county, 'all' voted
,100*sum(case 
        when ev in ('ev','ab') then civis.senate_support_2014/100
        else civis.senate_support_2014*civis.turnout_2014/10000 end)/sum(case when ev in ('ev','ab') then 1 else civis.turnout_2014/100 end) h2hprimary 
,100*sum(case 
        when ev in ('ev','ab') then civis.senate_support_2014/100
        else civis.senate_support_2014*(civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end)/
        sum(case when ev in ('ev','ab') then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end) h2hsecondary
,sum(case when ev in ('ev','ab') then 1 else civis.turnout_2014/100 end)::dec(38,2) primary_turnout
,sum(case when ev in ('ev','ab') then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end)::dec(38,2) secondary_turnout
,sum(case 
        when ev is null then civis.senate_support_2014*(civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end) h2himpact
from (select personid, votebuilder_identifier,precinctid,vanprecinctid,county_name pcounty from analytics_ar.person where is_current_reg) person
full outer join (select vanid votebuilder_identifier, list_name ev from c2014_team_ar.vanevbatch) evoters using(votebuilder_identifier)
left join analytics_ar.all_civis_scores civis using(personid)
left join (select votebuilder_identifier, sum(contacts) contacts from (select * from (select vanid votebuilder_identifier,count(distinct contacthistoryexport.contactscontactid) contacts from c2014_ar_coord_vansync.contacthistoryexport 
        where contacthistoryexport.datecanvassed::date>='2014-10-20'::date and contacttypeid in (1,2) and contacthistoryexport.resultid=14 group by 1) union all (
        select vanid votebuilder_identifier, count(/*case lower(ans) when 'no' then null else */ans/* end*/) contacts from  edayhdv group by 1)) group by 1) contacts using(votebuilder_identifier)
left join (select county,precinctname,precinctid from precinct_basetable) using(precinctid)
group by 1,2 order by 1,2) union all (
select 'All State' county, ' all' voted
,100*sum(case 
        when ev in ('ev','ab') then civis.senate_support_2014/100
        else civis.senate_support_2014*civis.turnout_2014/10000 end)/sum(case when ev in ('ev','ab') then 1 else civis.turnout_2014/100 end) h2hprimary 
,100*sum(case 
        when ev in ('ev','ab') then civis.senate_support_2014/100
        else civis.senate_support_2014*(civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end)/
        sum(case when ev in ('ev','ab') then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end) h2hsecondary
,sum(case when ev in ('ev','ab') then 1 else civis.turnout_2014/100 end)::dec(38,2) primary_turnout
,sum(case when ev in ('ev','ab') then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end)::dec(38,2) secondary_turnout
,sum(case 
        when ev is null then civis.senate_support_2014*(civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end) h2himpact
from (select personid, votebuilder_identifier,precinctid,vanprecinctid,county_name pcounty from analytics_ar.person where is_current_reg) person
full outer join (select vanid votebuilder_identifier, list_name ev from c2014_team_ar.vanevbatch) evoters using(votebuilder_identifier)
left join analytics_ar.all_civis_scores civis using(personid)
left join (select votebuilder_identifier, sum(contacts) contacts from (select * from (select vanid votebuilder_identifier,count(distinct contacthistoryexport.contactscontactid) contacts from c2014_ar_coord_vansync.contacthistoryexport 
        where contacthistoryexport.datecanvassed::date>='2014-10-20'::date and contacttypeid in (1,2) and contacthistoryexport.resultid=14 group by 1) union all (
        select vanid votebuilder_identifier, count(/*case lower(ans) when 'no' then null else */ans/* end*/) contacts from  edayhdv group by 1)) group by 1) contacts using(votebuilder_identifier)
left join (select county,precinctname,precinctid from precinct_basetable) using(precinctid)
group by 1,2 order by 1,2) union all (
select 'All State' county, ' bearish all' voted
,100*sum(case 
        when ev in ('ev','ab') then civis.senate_support_2014/100
        else civis.senate_support_2014*civis.turnout_2014/10000 end)/sum(case when ev in ('ev','ab') then 1 else civis.turnout_2014/100 end) h2hprimary 
,100*sum(case 
        when ev in ('ev','ab') then civis.senate_support_2014/100
        else civis.senate_support_2014*(civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end)/
        sum(case when ev in ('ev','ab') then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end) h2hsecondary
,sum(case when ev in ('ev','ab') then 1 else civis.turnout_2014/100 end)::dec(38,2) primary_turnout
,sum(case when ev in ('ev','ab') then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end)::dec(38,2) secondary_turnout
,sum(case 
        when ev is null then civis.senate_support_2014*(civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end) h2himpact
from (select personid, votebuilder_identifier,precinctid,vanprecinctid,county_name pcounty from analytics_ar.person where is_current_reg) person
full outer join (select vanid votebuilder_identifier, list_name ev from c2014_team_ar.vanevbatch) evoters using(votebuilder_identifier)
left join analytics_ar.all_civis_scores civis using(personid)
left join (select votebuilder_identifier, sum(contacts) contacts from (select * from (select vanid votebuilder_identifier,count(distinct contacthistoryexport.contactscontactid) contacts from c2014_ar_coord_vansync.contacthistoryexport 
        where contacthistoryexport.datecanvassed::date>='2014-10-20'::date and contacttypeid in (1,2) and contacthistoryexport.resultid=14 group by 1) union all (
        select vanid votebuilder_identifier, count(case lower(ans) when 'no' then null else ans end) contacts from  edayhdv group by 1)) group by 1) contacts using(votebuilder_identifier)
left join (select county,precinctname,precinctid from precinct_basetable) using(precinctid)
group by 1,2)
order by 1,2;











































-----------------------------------------------------------------------------------------------------
--------------------------------------------previous work--------------------------------------------
-----------------------------------------------------------------------------------------------------

--Senate
select /*'Statewide'*/ county, coalesce(ev,'nvy') voted
,100*sum(case 
        when ev='ev' then civis.senate_support_2014/100
        else civis.senate_support_2014*civis.turnout_2014/10000 end)/sum(case when ev='ev' then 1 else civis.turnout_2014/100 end) h2hprimary--this is the simple sum(dot-product) of support*turnout (hence a person with a support score of 60 and a turnout score of 70 is .42 votes) 
,100*sum(case 
        when ev='ev' then civis.senate_support_2014/100
        else civis.senate_support_2014*(civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end)/
        sum(case when ev='ev' then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end) h2hsecondary--here we add in the gotv score for those contacted w/i EDay-14d; it decays by half with each additional contact, so asymptotically approaches 2*gotv 
,sum(case when ev='ev' then 1 else civis.turnout_2014/100 end)::dec(38,2) primary_turnout
,sum(case when ev='ev' then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end)::dec(38,2) secondary_turnout
from (select personid, votebuilder_identifier,precinctid,vanprecinctid,county_name pcounty from analytics_ar.person where is_current_reg) person
full outer join (select vanid votebuilder_identifier, 'ev' ev from c2014_team_ar.vanevbatch) evoters using(votebuilder_identifier)
left join analytics_ar.all_civis_scores civis using(personid)
left join (select vanid votebuilder_identifier,count(distinct contacthistoryexport.contactscontactid) contacts from c2014_ar_coord_vansync.contacthistoryexport where contacthistoryexport.datecanvassed::date>='2014-10-20'::date and contacttypeid in (1,2) and contacthistoryexport.resultid=14 group by 1) using(votebuilder_identifier)
left join (select county,precinctname,precinctid from precinct_basetable) using(precinctid)
group by 1,2 order by 1,2;
select * from c2014_team_ar.vanevbatch limit 20;

--initial cd2 pull
select * from (
select countyname county,count(*) early_voters,100*sum(dccc2014cdsup/100)/count(dccc2014cdsup) dtrip_2way_cd_supportHays--, 100*sum(1-dccc2014cdsup/100)/count(dccc2014cdsup) dtrip_2way_cd_supportHill
,100*sum(c2dcccdemsup/100)/count(c2dcccdemsup) dtrip_cd2_supportHays--,100*sum(1-c2dcccdemsup/100)/count(c2dcccdemsup) dtrip_cd2_supportHill 
from cdscores left join c2014_team_ar.vanevbatch using(vanid) where list_name is not null group by 1) union all (
select 'cd 2' county,count(*) early_voters,100*sum(dccc2014cdsup/100)/count(dccc2014cdsup) dtrip_2way_cd_supportHays--,100*sum(1-dccc2014cdsup/100)/count(dccc2014cdsup) dtrip_2way_cd_supportHill
,100*sum(c2dcccdemsup/100)/count(c2dcccdemsup) dtrip_cd2_supportHays--,100*sum(1-c2dcccdemsup/100)/count(c2dcccdemsup) dtrip_cd2_supportHill 
from cdscores left join c2014_team_ar.vanevbatch using(vanid) where list_name is not null group by 1)
order by 1;
left join analytics_ar.all_civis_scores civis using(personid)
left join (select vanid votebuilder_identifier,count(distinct contacthistoryexport.contactscontactid) contacts from c2014_ar_coord_vansync.contacthistoryexport where contacthistoryexport.datecanvassed::date>='2014-10-20'::date and contacttypeid in (1,2) and contacthistoryexport.resultid=14 group by 1) using(votebuilder_identifier)
left join (select county,precinctname,precinctid from precinct_basetable) using(precinctid)
group by 1,2;


--cd 2
select /*'Statewide'*/ bl.countyname county, coalesce(ev,'nvy') voted
,100*sum(case 
        when ev='ev' then bl.dccc2014cdsup/100
        else bl.dccc2014cdsup*bl.dcccto/10000 end)/sum(case when ev='ev' then 1 else bl.dcccto/100 end) h2hprimary 
,100*sum(case 
        when ev='ev' then bl.dccc2014cdsup/100
        else bl.dccc2014cdsup*(bl.dcccto+bl.c2dcccgotv*(2-.5^(coalesce(contacts,0)-1)))/10000 end)/
        sum(case when ev='ev' then 1 else (bl.dcccto+bl.c2dcccgotv*(2-.5^(coalesce(contacts,0)-1)))/100 end) h2hsecondary
,sum(case when ev='ev' then 1 else bl.dcccto/100 end)::dec(38,2) primary_turnout
,sum(case when ev='ev' then 1 else (bl.dcccto+bl.c2dcccgotv*(2-.5^(coalesce(contacts,0)-1)))/100 end)::dec(38,2) secondary_turnout
from (select personid, votebuilder_identifier,precinctid,vanprecinctid,county_name pcounty from analytics_ar.person where is_current_reg) person
full outer join (select vanid votebuilder_identifier, 'ev' ev from c2014_team_ar.vanevbatch) evoters using(votebuilder_identifier)
left join (select *, vanid votebuilder_identifier, 2 cd from cdscores) bl using(votebuilder_identifier)
left join (select vanid votebuilder_identifier,count(distinct contacthistoryexport.contactscontactid) contacts from c2014_ar_coord_vansync.contacthistoryexport where contacthistoryexport.datecanvassed::date>='2014-10-20'::date and contacttypeid in (1,2) and contacthistoryexport.resultid=14 group by 1) using(votebuilder_identifier)
left join (select county,precinctname,precinctid from precinct_basetable) using(precinctid)
where bl.cd=2
group by 1,2
order by 1,2;


-----------------------------------More presentable export versions--------------
--Senate
select * from (
select /*'Statewide'*/ county, coalesce(ev,'nvy') voted
,100*sum(case 
        when ev='ev' then civis.senate_support_2014/100
        else civis.senate_support_2014*civis.turnout_2014/10000 end)/sum(case when ev='ev' then 1 else civis.turnout_2014/100 end) h2hprimary 
,100*sum(case 
        when ev='ev' then civis.senate_support_2014/100
        else civis.senate_support_2014*(civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end)/
        sum(case when ev='ev' then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end) h2hsecondary
,sum(case when ev='ev' then 1 else civis.turnout_2014/100 end)::dec(38,2) primary_turnout
,sum(case when ev='ev' then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end)::dec(38,2) secondary_turnout
,sum(case 
        when ev is null then civis.senate_support_2014*(civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end) h2himpact
from (select personid, votebuilder_identifier,precinctid,vanprecinctid,county_name pcounty from analytics_ar.person where is_current_reg) person
full outer join (select vanid votebuilder_identifier, 'ev' ev from c2014_team_ar.vanevbatch) evoters using(votebuilder_identifier)
left join analytics_ar.all_civis_scores civis using(personid)
left join (select vanid votebuilder_identifier,count(distinct contacthistoryexport.contactscontactid) contacts from c2014_ar_coord_vansync.contacthistoryexport where contacthistoryexport.datecanvassed::date>='2014-10-20'::date and contacttypeid in (1,2) and contacthistoryexport.resultid=14 group by 1) using(votebuilder_identifier)
left join (select county,precinctname,precinctid from precinct_basetable) using(precinctid)
group by 1,2 order by 1,2) union all (
select 'All State' county, coalesce(ev,'nvy') voted
,100*sum(case 
        when ev='ev' then civis.senate_support_2014/100
        else civis.senate_support_2014*civis.turnout_2014/10000 end)/sum(case when ev='ev' then 1 else civis.turnout_2014/100 end) h2hprimary 
,100*sum(case 
        when ev='ev' then civis.senate_support_2014/100
        else civis.senate_support_2014*(civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end)/
        sum(case when ev='ev' then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end) h2hsecondary
,sum(case when ev='ev' then 1 else civis.turnout_2014/100 end)::dec(38,2) primary_turnout
,sum(case when ev='ev' then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end)::dec(38,2) secondary_turnout
,sum(case 
        when ev is null then civis.senate_support_2014*(civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end) h2himpact
/*,sum(case 
        when ev='ev' then civis.senate_support_2014/100
        else civis.senate_support_2014*civis.turnout_2014/10000 end) pvotersev*/
from (select personid, votebuilder_identifier,precinctid,vanprecinctid,county_name pcounty from analytics_ar.person where is_current_reg) person
full outer join (select vanid votebuilder_identifier, 'ev' ev from c2014_team_ar.vanevbatch) evoters using(votebuilder_identifier)
left join analytics_ar.all_civis_scores civis using(personid)
left join (select vanid votebuilder_identifier,count(distinct contacthistoryexport.contactscontactid) contacts from c2014_ar_coord_vansync.contacthistoryexport where contacthistoryexport.datecanvassed::date>='2014-10-20'::date and contacttypeid in (1,2) and contacthistoryexport.resultid=14 group by 1) using(votebuilder_identifier)
left join (select county,precinctname,precinctid from precinct_basetable) using(precinctid)
group by 1,2) union all (
select /*'Statewide'*/ county, 'all' voted
,100*sum(case 
        when ev='ev' then civis.senate_support_2014/100
        else civis.senate_support_2014*civis.turnout_2014/10000 end)/sum(case when ev='ev' then 1 else civis.turnout_2014/100 end) h2hprimary 
,100*sum(case 
        when ev='ev' then civis.senate_support_2014/100
        else civis.senate_support_2014*(civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end)/
        sum(case when ev='ev' then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end) h2hsecondary
,sum(case when ev='ev' then 1 else civis.turnout_2014/100 end)::dec(38,2) primary_turnout
,sum(case when ev='ev' then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end)::dec(38,2) secondary_turnout
,sum(case 
        when ev is null then civis.senate_support_2014*(civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end) h2himpact
from (select personid, votebuilder_identifier,precinctid,vanprecinctid,county_name pcounty from analytics_ar.person where is_current_reg) person
full outer join (select vanid votebuilder_identifier, 'ev' ev from c2014_team_ar.vanevbatch) evoters using(votebuilder_identifier)
left join analytics_ar.all_civis_scores civis using(personid)
left join (select vanid votebuilder_identifier,count(distinct contacthistoryexport.contactscontactid) contacts from c2014_ar_coord_vansync.contacthistoryexport where contacthistoryexport.datecanvassed::date>='2014-10-20'::date and contacttypeid in (1,2) and contacthistoryexport.resultid=14 group by 1) using(votebuilder_identifier)
left join (select county,precinctname,precinctid from precinct_basetable) using(precinctid)
group by 1,2 order by 1,2) union all (
select 'All State' county, 'all' voted
,100*sum(case 
        when ev='ev' then civis.senate_support_2014/100
        else civis.senate_support_2014*civis.turnout_2014/10000 end)/sum(case when ev='ev' then 1 else civis.turnout_2014/100 end) h2hprimary 
,100*sum(case 
        when ev='ev' then civis.senate_support_2014/100
        else civis.senate_support_2014*(civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end)/
        sum(case when ev='ev' then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end) h2hsecondary
,sum(case when ev='ev' then 1 else civis.turnout_2014/100 end)::dec(38,2) primary_turnout
,sum(case when ev='ev' then 1 else (civis.turnout_2014+civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/100 end)::dec(38,2) secondary_turnout
,sum(case 
        when ev is null then civis.senate_support_2014*(civis.gotv_2014*(2-.5^(coalesce(contacts,0)-1)))/10000 end) h2himpact
from (select personid, votebuilder_identifier,precinctid,vanprecinctid,county_name pcounty from analytics_ar.person where is_current_reg) person
full outer join (select vanid votebuilder_identifier, 'ev' ev from c2014_team_ar.vanevbatch) evoters using(votebuilder_identifier)
left join analytics_ar.all_civis_scores civis using(personid)
left join (select vanid votebuilder_identifier,count(distinct contacthistoryexport.contactscontactid) contacts from c2014_ar_coord_vansync.contacthistoryexport where contacthistoryexport.datecanvassed::date>='2014-10-20'::date and contacttypeid in (1,2) and contacthistoryexport.resultid=14 group by 1) using(votebuilder_identifier)
left join (select county,precinctname,precinctid from precinct_basetable) using(precinctid)
group by 1,2)
order by 1,2;

--cd2 
select * from (
select /*'Statewide'*/ bl.countyname county, coalesce(ev,'nvy') voted
,100*sum(case 
        when ev='ev' then bl.dccc2014cdsup/100
        else bl.dccc2014cdsup*bl.dcccto/10000 end)/sum(case when ev='ev' then 1 else bl.dcccto/100 end) h2hprimary 
,100*sum(case 
        when ev='ev' then bl.dccc2014cdsup/100
        else bl.dccc2014cdsup*(bl.dcccto+bl.c2dcccgotv*(2-.5^(coalesce(contacts,0)-1)))/10000 end)/
        sum(case when ev='ev' then 1 else (bl.dcccto+bl.c2dcccgotv*(2-.5^(coalesce(contacts,0)-1)))/100 end) h2hsecondary
,sum(case when ev='ev' then 1 else bl.dcccto/100 end)::dec(38,2) primary_turnout
,sum(case when ev='ev' then 1 else (bl.dcccto+bl.c2dcccgotv*(2-.5^(coalesce(contacts,0)-1)))/100 end)::dec(38,2) secondary_turnout
from (select personid, votebuilder_identifier,precinctid,vanprecinctid,county_name pcounty from analytics_ar.person where is_current_reg) person
full outer join (select vanid votebuilder_identifier, 'ev' ev from c2014_team_ar.vanevbatch) evoters using(votebuilder_identifier)
left join (select *, vanid votebuilder_identifier, 2 cd from cdscores) bl using(votebuilder_identifier)
left join (select vanid votebuilder_identifier,count(distinct contacthistoryexport.contactscontactid) contacts from c2014_ar_coord_vansync.contacthistoryexport where contacthistoryexport.datecanvassed::date>='2014-10-20'::date and contacttypeid in (1,2) and contacthistoryexport.resultid=14 group by 1) using(votebuilder_identifier)
left join (select county,precinctname,precinctid from precinct_basetable) using(precinctid)
where bl.cd=2
group by 1,2) union all (
select 'CD 2' /*bl.countyname*/ county, coalesce(ev,'nvy') voted
,100*sum(case 
        when ev='ev' then bl.dccc2014cdsup/100
        else bl.dccc2014cdsup*bl.dcccto/10000 end)/sum(case when ev='ev' then 1 else bl.dcccto/100 end) h2hprimary 
,100*sum(case 
        when ev='ev' then bl.dccc2014cdsup/100
        else bl.dccc2014cdsup*(bl.dcccto+bl.c2dcccgotv*(2-.5^(coalesce(contacts,0)-1)))/10000 end)/
        sum(case when ev='ev' then 1 else (bl.dcccto+bl.c2dcccgotv*(2-.5^(coalesce(contacts,0)-1)))/100 end) h2hsecondary
,sum(case when ev='ev' then 1 else bl.dcccto/100 end)::dec(38,2) primary_turnout
,sum(case when ev='ev' then 1 else (bl.dcccto+bl.c2dcccgotv*(2-.5^(coalesce(contacts,0)-1)))/100 end)::dec(38,2) secondary_turnout
from (select personid, votebuilder_identifier,precinctid,vanprecinctid,county_name pcounty from analytics_ar.person where is_current_reg) person
full outer join (select vanid votebuilder_identifier, 'ev' ev from c2014_team_ar.vanevbatch) evoters using(votebuilder_identifier)
left join (select *, vanid votebuilder_identifier, 2 cd from cdscores) bl using(votebuilder_identifier)
left join (select vanid votebuilder_identifier,count(distinct contacthistoryexport.contactscontactid) contacts from c2014_ar_coord_vansync.contacthistoryexport where contacthistoryexport.datecanvassed::date>='2014-10-20'::date and contacttypeid in (1,2) and contacthistoryexport.resultid=14 group by 1) using(votebuilder_identifier)
left join (select county,precinctname,precinctid from precinct_basetable) using(precinctid)
where bl.cd=2
group by 1,2) union all (
select /*'Statewide'*/ bl.countyname county, 'all' voted
,100*sum(case 
        when ev='ev' then bl.dccc2014cdsup/100
        else bl.dccc2014cdsup*bl.dcccto/10000 end)/sum(case when ev='ev' then 1 else bl.dcccto/100 end) h2hprimary 
,100*sum(case 
        when ev='ev' then bl.dccc2014cdsup/100
        else bl.dccc2014cdsup*(bl.dcccto+bl.c2dcccgotv*(2-.5^(coalesce(contacts,0)-1)))/10000 end)/
        sum(case when ev='ev' then 1 else (bl.dcccto+bl.c2dcccgotv*(2-.5^(coalesce(contacts,0)-1)))/100 end) h2hsecondary
,sum(case when ev='ev' then 1 else bl.dcccto/100 end)::dec(38,2) primary_turnout
,sum(case when ev='ev' then 1 else (bl.dcccto+bl.c2dcccgotv*(2-.5^(coalesce(contacts,0)-1)))/100 end)::dec(38,2) secondary_turnout
from (select personid, votebuilder_identifier,precinctid,vanprecinctid,county_name pcounty from analytics_ar.person where is_current_reg) person
full outer join (select vanid votebuilder_identifier, 'ev' ev from c2014_team_ar.vanevbatch) evoters using(votebuilder_identifier)
left join (select *, vanid votebuilder_identifier, 2 cd from cdscores) bl using(votebuilder_identifier)
left join (select vanid votebuilder_identifier,count(distinct contacthistoryexport.contactscontactid) contacts from c2014_ar_coord_vansync.contacthistoryexport where contacthistoryexport.datecanvassed::date>='2014-10-20'::date and contacttypeid in (1,2) and contacthistoryexport.resultid=14 group by 1) using(votebuilder_identifier)
left join (select county,precinctname,precinctid from precinct_basetable) using(precinctid)
where bl.cd=2
group by 1,2) union all (
select 'CD 2' /*bl.countyname*/ county, 'all' voted
,100*sum(case 
        when ev='ev' then bl.dccc2014cdsup/100
        else bl.dccc2014cdsup*bl.dcccto/10000 end)/sum(case when ev='ev' then 1 else bl.dcccto/100 end) h2hprimary 
,100*sum(case 
        when ev='ev' then bl.dccc2014cdsup/100
        else bl.dccc2014cdsup*(bl.dcccto+bl.c2dcccgotv*(2-.5^(coalesce(contacts,0)-1)))/10000 end)/
        sum(case when ev='ev' then 1 else (bl.dcccto+bl.c2dcccgotv*(2-.5^(coalesce(contacts,0)-1)))/100 end) h2hsecondary
,sum(case when ev='ev' then 1 else bl.dcccto/100 end)::dec(38,2) primary_turnout
,sum(case when ev='ev' then 1 else (bl.dcccto+bl.c2dcccgotv*(2-.5^(coalesce(contacts,0)-1)))/100 end)::dec(38,2) secondary_turnout
from (select personid, votebuilder_identifier,precinctid,vanprecinctid,county_name pcounty from analytics_ar.person where is_current_reg) person
full outer join (select vanid votebuilder_identifier, 'ev' ev from c2014_team_ar.vanevbatch) evoters using(votebuilder_identifier)
left join (select *, vanid votebuilder_identifier, 2 cd from cdscores) bl using(votebuilder_identifier)
left join (select vanid votebuilder_identifier,count(distinct contacthistoryexport.contactscontactid) contacts from c2014_ar_coord_vansync.contacthistoryexport where contacthistoryexport.datecanvassed::date>='2014-10-20'::date and contacttypeid in (1,2) and contacthistoryexport.resultid=14 group by 1) using(votebuilder_identifier)
left join (select county,precinctname,precinctid from precinct_basetable) using(precinctid)
where bl.cd=2
group by 1,2)
order by 1,2
;












-----------Scratch work---------------------------

limit 20;
select (2-.5^(contacts-1)),contacts  from one2five order by 2;

insert into one2five
select 5 contacts from one2five limit 1;
select * from one2five;


select * from analytics_ar.person limit 20;
select * from analytics_ar.all_civis_scores  limit 20;

select * from precinctscutprocessed where walkable<.5
and county in ('Faulkner', 'Perry', 'White', 'Van Buren', 'Conway')
;

select * from cdscores limit 20;
select * from c2014_team_ar.vanevbatch limit 20;

select * from (
select countyname county,count(*) early_voters,100*sum(dccc2014cdsup/100)/count(dccc2014cdsup) dtrip_2way_cd_supportHays--, 100*sum(1-dccc2014cdsup/100)/count(dccc2014cdsup) dtrip_2way_cd_supportHill
,100*sum(c2dcccdemsup/100)/count(c2dcccdemsup) dtrip_cd2_supportHays--,100*sum(1-c2dcccdemsup/100)/count(c2dcccdemsup) dtrip_cd2_supportHill 
from cdscores left join c2014_team_ar.vanevbatch using(vanid) where list_name is not null group by 1) union all (
select 'cd 2' county,count(*) early_voters,100*sum(dccc2014cdsup/100)/count(dccc2014cdsup) dtrip_2way_cd_supportHays--,100*sum(1-dccc2014cdsup/100)/count(dccc2014cdsup) dtrip_2way_cd_supportHill
,100*sum(c2dcccdemsup/100)/count(c2dcccdemsup) dtrip_cd2_supportHays--,100*sum(1-c2dcccdemsup/100)/count(c2dcccdemsup) dtrip_cd2_supportHill 
from cdscores left join c2014_team_ar.vanevbatch using(vanid) where list_name is not null group by 1)
order by 1;
