--Turf tracker sequence


/*Drop Precincts cut (SQL Runner)
https://console.civisanalytics.com/jobs/1324289#/tab-job-config*/
drop table sroberts.precinctscut;
drop table sroberts.precinctshit;


/*Upload Precincts Cut (Import a Google Doc)
https://console.civisanalytics.com/jobs/1324232#/tab-job-config*/

/*Upload Precincts Hit (Import a Google Doc)
https://console.civisanalytics.com/jobs/1324386#/tab-job-config*/

/*process cut precincts (SQL Runner)
https://console.civisanalytics.com/jobs/1324291*/

/*This takes the output of a google form with 1 page for each county
,uploaded by console, and coalesces the 75 counties' precinct columns together
*/

drop table sroberts.precinctscutprocessed;
select county,precinctname,list_number, packetscut-(case when packetshit is null then 0 else packetshit end) packets
into precinctscutprocessed 
from (
select select_county county, max(list_number) list_number
,coalesce(which_precinct::varchar
,which_precinct1::varchar
,which_precinct2::varchar
,which_precinct3::varchar
,which_precinct4::varchar
,which_precinct5::varchar
,which_precinct6::varchar
,which_precinct7::varchar
,which_precinct8::varchar
,which_precinct9::varchar
,which_precinct10::varchar
,which_precinct11::varchar
,which_precinct12::varchar
,which_precinct13::varchar
,which_precinct14::varchar
,which_precinct15::varchar
,which_precinct16::varchar
,which_precinct17::varchar
,which_precinct18::varchar
,which_precinct19::varchar
,which_precinct20::varchar
,which_precinct21::varchar
,which_precinct22::varchar
,which_precinct23::varchar
,which_precinct24::varchar
,which_precinct25::varchar
,which_precinct26::varchar
,which_precinct27::varchar
,which_precinct28::varchar
,which_precinct29::varchar
,which_precinct30::varchar
,which_precinct31::varchar
,which_precinct32::varchar
,which_precinct33::varchar
,concat(case when log(which_precinct34::int)>3 then null when log(which_precinct34::int)>2 then '0' when log(which_precinct34::int)>1 then '00' when log(which_precinct34::int)>0 then '000' end,which_precinct34::varchar)
--this deals with a set of precincts names '0030' etc, whihc google casts as ints, and which need to be recast as varchar anyway
,which_precinct35::varchar
,which_precinct36::varchar
,which_precinct37::varchar
,which_precinct38::varchar
,which_precinct39::varchar
,which_precinct40::varchar
,which_precinct41::varchar
,which_precinct42::varchar
,which_precinct43::varchar
,which_precinct44::varchar
,which_precinct45::varchar
,which_precinct46::varchar
,which_precinct47::varchar
,which_precinct48::varchar
,which_precinct49::varchar
,which_precinct50::varchar
,which_precinct51::varchar
,which_precinct52::varchar
,which_precinct53::varchar
,which_precinct54::varchar
,which_precinct55::varchar
,which_precinct56::varchar
,which_precinct57::varchar
,which_precinct58::varchar
,which_precinct59::varchar
,which_precinct60::varchar
,which_precinct61::varchar
,which_precinct62::varchar
,which_precinct63::varchar
,which_precinct64::varchar
,which_precinct65::varchar
,which_precinct66::varchar
,which_precinct67::varchar
,which_precinct68::varchar
,which_precinct69::varchar
,which_precinct70::varchar
,which_precinct71::varchar
,which_precinct72::varchar
,which_precinct73::varchar
,which_precinct74::varchar) precinctname
,max(how_many_walk_packets_were_made_in_this_thing) packetscut
from sroberts.precinctscut group by 1,3) cut
left join (select select_county county--, list_number
,coalesce(which_precinct::varchar
,which_precinct1::varchar
,which_precinct2::varchar
,which_precinct3::varchar
,which_precinct4::varchar
,which_precinct5::varchar
,which_precinct6::varchar
,which_precinct7::varchar
,which_precinct8::varchar
,which_precinct9::varchar
,which_precinct10::varchar
,which_precinct11::varchar
,which_precinct12::varchar
,which_precinct13::varchar
,which_precinct14::varchar
,which_precinct15::varchar
,which_precinct16::varchar
,which_precinct17::varchar
,which_precinct18::varchar
,which_precinct19::varchar
,which_precinct20::varchar
,which_precinct21::varchar
,which_precinct22::varchar
,which_precinct23::varchar
,which_precinct24::varchar
,which_precinct25::varchar
,which_precinct26::varchar
,which_precinct27::varchar
,which_precinct28::varchar
,which_precinct29::varchar
,which_precinct30::varchar
,which_precinct31::varchar
,which_precinct32::varchar
,which_precinct33::varchar
,concat(case when log(which_precinct34::int)>3 then null when log(which_precinct34::int)>2 then '0' when log(which_precinct34::int)>1 then '00' when log(which_precinct34::int)>0 then '000' end,which_precinct34::varchar)
--this deals with a set of precincts names '0030' etc, whihc google casts as ints, and which need to be recast as varchar anyway
,which_precinct35::varchar
,which_precinct36::varchar
,which_precinct37::varchar
,which_precinct38::varchar
,which_precinct39::varchar
,which_precinct40::varchar
,which_precinct41::varchar
,which_precinct42::varchar
,which_precinct43::varchar
,which_precinct44::varchar
,which_precinct45::varchar
,which_precinct46::varchar
,which_precinct47::varchar
,which_precinct48::varchar
,which_precinct49::varchar
,which_precinct50::varchar
,which_precinct51::varchar
,which_precinct52::varchar
,which_precinct53::varchar
,which_precinct54::varchar
,which_precinct55::varchar
,which_precinct56::varchar
,which_precinct57::varchar
,which_precinct58::varchar
,which_precinct59::varchar
,which_precinct60::varchar
,which_precinct61::varchar
,which_precinct62::varchar
,which_precinct63::varchar
,which_precinct64::varchar
,which_precinct65::varchar
,which_precinct66::varchar
,which_precinct67::varchar
,which_precinct68::varchar
,which_precinct69::varchar
,which_precinct70::varchar
,which_precinct71::varchar
,which_precinct72::varchar
,which_precinct73::varchar
,which_precinct74::varchar) precinctname
,sum(how_many_walk_packets_were_knocked) packetshit
--into precinctscutprocessed
from sroberts.precinctshit
group by 1,2) hit using(precinctname,county);

/*R1 Cut Priorities (Export to Google Doc)
https://console.civisanalytics.com/jobs/1320415
Representative - there are 9 of these
the first 9 are "Cut" ones, that all launch as children of "process cut precincts"
then each has a child "Hit" job*/

--(From original writeup)
/* Turf Priorities Export
This spits out turfs that haven't yet been cut,
ranked by the number of persuasion and gotv targets they have.
The function acts on their product, instead of the two in some order
to account for cases when one is significantly larger (for example,
ordering by persuasion, gotv isn't well suited to precincts with 4,3,2 respective
persuasion targets and 250,500,375 respective gotv targets.
*/

select * from (
select 
vanprecinctid, turfexport.regionname,turfexport.foname--,substring(turfexport.teamname,6,1)
,precinct.county, precinct.precinctname
,sum(case when civis.persuasion_score>=4.9 and civis.senate_support_2014>=30 then 1 end) persuasiontier
,sum(case when civis.gotv_2014>1.5 then 1 end) gotvtier
,sum(case when person.address_type='S' and civis.persuasion_score>=4.32 then civis.persuasion_score when person.address_type='S' and civis.persuasion_score>=3.6 and civis.senate_support_2014>=30 then civis.persuasion_score else 0 end) walkpersuasiontier
,sum(case when person.address_type='S' and civis.gotv_2014>1.5 then civis.gotv_2014 else 0 end) walkgotvtier
,sum(case when person.address_type='S' and (civis.persuasion_score>=4.32 or (civis.persuasion_score>=3.6 and civis.senate_support_2014>=30) or civis.gotv_2014>1.5) then 1 else 0 end) allwalkabletargets
,sum(case when person.primary_phone_number is not null and civis.persuasion_score>=4.75 /*and civis.senate_support_2014>=30*/ then 1 end) phonepersuasiontier
,sum(case when person.primary_phone_number is not null and civis.gotv_2014>1.5 then 1 end) phonegotvtier
from analytics_ar.person
left join analytics_ar.all_civis_scores civis using(personid)
left join analytics_ar.all_dnc_scores dnc using(personid)
left join sroberts.precinct_basetable precinct using(precinctid,vanprecinctid)
left join c2014_ar_coord_vansync.turfexport on vanprecinctid=turfexport.precinctid
left join sroberts.precinctscutprocessed using(county,precinctname)
--left join (select precinctid, precinctname from analytics_ar.arbor_precinct) using(precinctid)
where civis.current_reg is true
and packets is null--defining the precincts that haven't been cut
group by 1,2,3,4,5)
where regionname='Region 01 - Northwest Arkansas' --This varies accross the 9 regions, should be only difference in queries
and allwalkabletargets>=100
order by regionname asc, right(foname,1) asc
/*this divides the export by FO turf (so the gdoc can divide the list into FOs with a begining and ending line) 
and region(which is trivial, but could be useful if at some point we moved to a single document, which was consideed)*/
,(walkpersuasiontier*walkgotvtier) desc--then within each FO turf, it orders based on descending score-product
;

/*R1 hit Priorities (Export to Google Doc)
https://console.civisanalytics.com/jobs/1324394*/
select * from (
select 
vanprecinctid, turfexport.regionname,turfexport.foname--,substring(turfexport.teamname,6,1)
,precinct.county, precinct.precinctname
,sum(case when civis.persuasion_score>=4.9 and civis.senate_support_2014>=30 then 1 end) persuasiontier
,sum(case when civis.gotv_2014>1.5 then 1 end) gotvtier
,sum(case when person.address_type='S' and civis.persuasion_score>=4.32 then civis.persuasion_score when person.address_type='S' and civis.persuasion_score>=3.6 and civis.senate_support_2014>=30 then civis.persuasion_score else 0 end) walkpersuasiontier
,sum(case when person.address_type='S' and civis.gotv_2014>1.5 then civis.gotv_2014 else 0 end) walkgotvtier
,sum(case when person.address_type='S' and (civis.persuasion_score>=4.32 or (civis.persuasion_score>=3.6 and civis.senate_support_2014>=30) or civis.gotv_2014>1.5) then 1 else 0 end) allwalkabletargets
,sum(case when person.primary_phone_number is not null and civis.persuasion_score>=4.75 /*and civis.senate_support_2014>=30*/ then 1 end) phonepersuasiontier
,sum(case when person.primary_phone_number is not null and civis.gotv_2014>1.5 then 1 end) phonegotvtier
from analytics_ar.person
left join analytics_ar.all_civis_scores civis using(personid)
left join analytics_ar.all_dnc_scores dnc using(personid)
left join sroberts.precinct_basetable precinct using(precinctid,vanprecinctid)
left join c2014_ar_coord_vansync.turfexport on vanprecinctid=turfexport.precinctid
left join sroberts.precinctscutprocessed using(county,precinctname)
--left join (select precinctid, precinctname from analytics_ar.arbor_precinct) using(precinctid)
where civis.current_reg is true
and packets>0--this is the primary difference between the two exports - this excludes turfs completely walked, and turfs uncut (which will be null, since they don't join)
group by 1,2,3,4,5)
where regionname='Region 01 - Northwest Arkansas'
and allwalkabletargets>=100
order by regionname asc, right(foname,1) asc
,(walkpersuasiontier*walkgotvtier) desc
;

--fin

