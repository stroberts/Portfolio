



select staginglocation,regionname region,foname fo,county,vanprecinctid,precinctname,max(case when coalesce(walkable,1)>=.5 then packetscut end) packetscut
,count(currentuni) currentunitargets,count(distinct case when currentuni is not null and person.address_type='S' then addressid end) currentunidoors
,count(gotvuni) gotvunitargets,count(distinct case when gotvuni is not null and person.address_type='S' then addressid end) gotvunidoors
,count(expgotvuni) gotvunitargets,count(distinct case when expgotvuni is not null and person.address_type='S' then addressid end) expgotvunidoors
from (
select vanid, list_name currentuni from universes1025 where list_id=647765) currentuni full outer join (
select vanid, list_name gotvuni from universes1025 where list_id=647786) gotvuni using(vanid) full outer join (
select vanid, list_name expgotvuni from universes1025 where list_id=647746) expgotvuni using(vanid) left join (
select votebuilder_identifier vanid, precinctid,vanprecinctid, primary_voting_address_id addressid,address_type from analytics_ar.person) person using(vanid) 
left join precinct_basetable using(precinctid) left join (select regionname,foname,precinctid vanprecinctid from c2014_ar_coord_vansync.turfexport) turf using(vanprecinctid) 
left join sl2fo24oct using(foname) full outer join (select county,lprecinctname,packetscut,walkable from precinctscutprocessed) pcp using(county,lprecinctname)
group by 1,2,3,4,5,6
order by 4,6;




--GOTV Universe	647786
--Current Combo GOTV Universe	647765
--GOTV Expanded Universe	647746



