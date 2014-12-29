select * from passschedule;

/*Changes to the pass schedule table*/
--alter table passschedule
--rename  column passstart to pass1;
--alter table passschedule
--add column pass2 datetime;
--alter table passschedule
--add column pass3 datetime;
--alter table passschedule
--add column pass4 datetime;

update passschedule
set pass2='2014-10-26'::datetime
where select_county in ('Craighead','Pope','Sebastian','Washington','Pulaski','Saline','Clark','Polk')
;
update passschedule
set pass2='2014-10-25'::datetime
where select_county='Pulaski'
;

('Craighead','Pope','Sebastian','Washington','Pulaski','Saline','Clark','Polk')




select /*staginglocation,*/regionname region,foname fo,county,/*vanprecinctid,*/precinctname,case when coalesce(walkable,1)>=.5 then packetscut else 0 end packetscut
,case when coalesce(walkable,1)>=.5 then p1packets else 0 end p1packets--,max(case when coalesce(walkable,1)>=.5 then packetscut end) packetscut,max(packets) packets
,case when coalesce(walkable,1)>=.5 then p2packets else 0 end p2packets
,case when coalesce(walkable,1)>=.5 then p3packets else 0 end p3packets
,case when coalesce(walkable,1)>=.5 then p4packets else 0 end p4packets
,walkable
from (select county,precinctname,lower(precinctname) lprecinctname
,coalesce(packetscut,0)-(case when p1packetshit is null then 0 when p1packetshit>packetscut then packetscut else p1packetshit end) p1packets
,coalesce(packetscut,0)-(case when p2packetshit is null then 0 when p2packetshit>packetscut then packetscut else p2packetshit end) p2packets
,coalesce(packetscut,0)-(case when p3packetshit is null then 0 when p3packetshit>packetscut then packetscut else p3packetshit end) p3packets
,coalesce(packetscut,0)-(case when p4packetshit is null then 0 when p4packetshit>packetscut then packetscut else p4packetshit end) p4packets
, packetscut, coalesce(walkable,1) walkable
from (
select select_county county--, max(list_number) list_number
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
,concat(case when substring(which_precinct34,4,1)='-' then null when log(which_precinct34::int)>3 then null when log(which_precinct34::int)>2 then '0' when log(which_precinct34::int)>1 then '00' when log(which_precinct34::int)>0 then '000' end,which_precinct34::varchar)
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
from sroberts.precinctscut where timestamp::datetime>'10/12/2014 15:00:00'::datetime group by 1,2) cut
full outer join (select select_county county--, list_number
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
,concat(case when substring(which_precinct34,4,1)='-' then null when log(which_precinct34::int)>3 then null when log(which_precinct34::int)>2 then '0' when log(which_precinct34::int)>1 then '00' when log(which_precinct34::int)>0 then '000' end,which_precinct34::varchar)
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
,sum(case when timestamp::datetime>coalesce(passschedule.pass1,'2014-11-04'::datetime) then how_many_walk_packets_were_knocked end) p1packetshit
,sum(case when timestamp::datetime>coalesce(passschedule.pass2,'2014-11-04'::datetime) then how_many_walk_packets_were_knocked end) p2packetshit
,sum(case when timestamp::datetime>coalesce(passschedule.pass3,'2014-11-04'::datetime) then how_many_walk_packets_were_knocked end) p3packetshit
,sum(case when timestamp::datetime>coalesce(passschedule.pass4,'2014-11-04'::datetime) then how_many_walk_packets_were_knocked end) p4packetshit
,avg(coalesce(precinctshit.was_this_turf_walkable,1)::dec(3,2)) walkable
--into precinctscutprocessed
from sroberts.precinctshit left join passschedule using(select_county) --where timestamp::datetime>passschedule.passstart
group by 1,2) hit using(precinctname,county)) pcp /*using(county,lprecinctname) */ left join (select vanprecinctid,county,lprecinctname from pb2) using(county,lprecinctname) left join (select regionname,foname,precinctid vanprecinctid from c2014_ar_coord_vansync.turfexport) turf using(vanprecinctid)
--group by 1,2,3,4,5,6
order by 1,right(foname,1) asc,3,4;





