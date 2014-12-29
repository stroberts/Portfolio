select person.state_senate_district_latest StateSenate,person.state_house_district_latest StateHouse
--,(datecanvassed-1-extract(dow from datecanvassed+1)%7) week
,count(distinct targets.vanid) targetpeople,count(distinct case when targets.vanid is not null then person.primary_voting_address_id end) targethouseholds --get outside group
,count(distinct case when targets.vanid is not null then myvcontacts.vanid end) targetsattempted
,count(distinct case when targets.vanid and myvcontacts.contacttypeid=2 then myvcontacts.vanid end) targetsknocked
,count(distinct case when targets.vanid and myvcontacts.contacttypeid=2 and resultid=14 then myvcontacts.vanid end) targetsknockedspoken
,count(distinct case when targets.vanid and myvcontacts.contacttypeid=1 then myvcontacts.vanid end) targetsphoned
,count(distinct case when targets.vanid and myvcontacts.contacttypeid=1 and resultid=14 then myvcontacts.vanid end) targetsphonedspoken
,count(distinct case when targets.vanid is null then myvcontacts.vanid end) nontargetsattempted
,count(distinct case when targets.vanid is null and resultid=14 then myvcontacts.vanid end) nontargetsspoken
from sroberts.t1_persuasion_doors targets full outer join
(select vanid, datecanvassed, contacttypeid, resultid from c2014_ar_coord_vansync.contacthistoryexport
where datecanvassed>='2014-09-02' and contacttypeid in (1,2)) myvcontacts using(vanid)
left join analytics_ar.person on vanid=votebuilder_identifier
group by 1,2--,3
;

select (eventdate-1-extract(dow from eventdate+1)%7) week, person.hdname statehouse, person.sdname statesenate
,sum(mod(case when eventtype='Phone Bank' then finalsitch end,2)) phonebankers
,sum(mod(case when eventtype='Canvass' then finalsitch end,2)) canvassers
,sum(mod(case when eventtype='Voter Reg' then finalsitch end,2)) voterregers
--,*
from sroberts.eventattendees
left join c2014_ar_coord_vansync.mycampaignperson person using(vanid)

where eventattendees.eventdate>='2014-09-02'
group by 1,2,3
limit 20;


select * from c2014_ar_coord_vansync.surveyresponseexport
limit 20;



--more general approach
select (datecanvassed-1-extract(dow from datecanvassed+1)%7) week
,person.state_senate_district_latest StateSenate,person.state_house_district_latest StateHouse
--,(datecanvassed-1-extract(dow from datecanvassed+1)%7) week
,count(distinct myvcontacts.vanid) targetsattempted
,count(distinct case when myvcontacts.contacttypeid=2 then myvcontacts.vanid end) targetsknocked
,count(distinct case when  myvcontacts.contacttypeid=2 and resultid=14 then myvcontacts.vanid end) targetsknockedspoken
,count(distinct case when  myvcontacts.contacttypeid=1 then myvcontacts.vanid end) targetsphoned
,count(distinct case when  myvcontacts.contacttypeid=1 and resultid=14 then myvcontacts.vanid end) targetsphonedspoken
,count(PryorId) PryorIDs
,count(RossId) RossIDs
,count(HaysId) HaysIDs
,count(WittId) WittIDs
,count(coalesce(SDId/*,DemsId*/)) SDIDs
,count(coalesce(HDId/*,DemsId*/)) HDIDs
from --sroberts.t1_persuasion_doors targets full outer join
(select vanid, case when datecanvassed::date=datecanvassed then datecanvassed else (datecanvassed-interval '1 Hour')::date end datecanvassed
, contacttypeid, resultid from c2014_ar_coord_vansync.contacthistoryexport
where datecanvassed>='2014-09-02' and contacttypeid in (1,2) and extract(dow from datecanvassed) in (6,7)) myvcontacts --using(vanid)
left join analytics_ar.person on vanid=votebuilder_identifier
left join (select vanid, case SURVEYRESPONSEID%10 when 7 then 1 when 0 then 2 else surveyresponseid%10 end PryorId,case when datecanvassed::date=datecanvassed then datecanvassed else (datecanvassed-interval '1 Hour')::date end datecanvassed 
from c2014_ar_coord_vansync.surveyresponseexport where surveyquestionid=166174) using(vanid,datecanvassed)
left join (select vanid, SURVEYRESPONSEID-714519 RossId,case when datecanvassed::date=datecanvassed then datecanvassed else (datecanvassed-interval '1 Hour')::date end datecanvassed 
from c2014_ar_coord_vansync.surveyresponseexport where surveyquestionid=168395) using(vanid,datecanvassed)
left join (select vanid, case SURVEYRESPONSEID-741700 when 19 then 6 when 20 then 7 else SURVEYRESPONSEID-741706 end HDId,case when datecanvassed::date=datecanvassed then datecanvassed else (datecanvassed-interval '1 Hour')::date end datecanvassed 
from c2014_ar_coord_vansync.surveyresponseexport where surveyquestionid=174873) using(vanid,datecanvassed)
left join (select vanid, SURVEYRESPONSEID-741728 SDId,case when datecanvassed::date=datecanvassed then datecanvassed else (datecanvassed-interval '1 Hour')::date end datecanvassed 
from c2014_ar_coord_vansync.surveyresponseexport where surveyquestionid=174877) using(vanid,datecanvassed)
left join (select vanid, SURVEYRESPONSEID-741393 DemsId,case when datecanvassed::date=datecanvassed then datecanvassed else (datecanvassed-interval '1 Hour')::date end datecanvassed 
from c2014_ar_coord_vansync.surveyresponseexport where surveyquestionid=174802) using(vanid,datecanvassed)
left join (select vanid, case SURVEYRESPONSEID-741416 when 8 then 5 when 9 then 6 else SURVEYRESPONSEID-741416 end HaysId,case when datecanvassed::date=datecanvassed then datecanvassed else (datecanvassed-interval '1 Hour')::date end datecanvassed 
from c2014_ar_coord_vansync.surveyresponseexport where surveyquestionid=174807) using(vanid,datecanvassed)
left join (select vanid, case SURVEYRESPONSEID-741429 when 6 then 4 when 8 then 5 when 9 then 6 else SURVEYRESPONSEID-741429 end WittId,case when datecanvassed::date=datecanvassed then datecanvassed else (datecanvassed-interval '1 Hour')::date end datecanvassed 
from c2014_ar_coord_vansync.surveyresponseexport where surveyquestionid=174810) using(vanid,datecanvassed)
group by 1,2,3
;


select * from vansync.dncsurveyresponses
where dncsurveyresponses.surveyquestionid=166174
/*
166174	705177	1 - Strong Pryor
166174	705180	2 - Lean Pryor
166174	705183	3 - Undecided
166174	705184	4 - Lean Cotton
166174	705185	5 - Strong Cotton
166174	705186	6 - Other*/
;
select * from vansync.dncsurveyresponses
where dncsurveyresponses.surveyquestionid=168395
/*
168395	714519	1-Strong Ross
168395	714520	2-Lean Ross
168395	714521	3-Undecided
168395	714522	4-Lean Hutchinson
168395	714523	5-Strong Hutchinson
168395	714524	6-Other*/
;
select * from vansync.dncsurveyresponses
where dncsurveyresponses.surveyquestionid=174873--HD Generic
/*
174873	741707	1 - Support Dem
174873	741708	2 - Lean Dem
174873	741709	3 - Undecided
174873	741710	4 - Lean GOP
174873	741711	5 - Support GOP
174873	741719	6 - Lean Other
174873	741720	7 - Support Other*/
;
select * from vansync.dncsurveyresponses
where dncsurveyresponses.surveyquestionid=174877--SD Generic
/*
174877	741729	1 - Support Dem
174877	741730	2 - Lean Dem
174877	741731	3 - Undecided
174877	741732	4 - Lean GOP
174877	741733	5 - Support GOP*/
;
select * from vansync.dncsurveyresponses
where dncsurveyresponses.surveyquestionid=174802--Dems Up& Down
/*
174802	741394	1 - Strong Dem
174802	741395	2 - Lean Dem
174802	741396	3 - Undecided
174802	741397	4 - Lean GOP
174802	741398	5 - Strong GOP
174802	741399	6 - Other*/
;
select * from vansync.dncsurveyresponses
where dncsurveyresponses.surveyquestionid=174807--Hays
/*
174807	741417	1 - Strong Hays
174807	741418	2 - Lean Hays
174807	741419	3 - Undecided
174807	741420	4 - Lean FrenchHill
174807	741424	5 - Strong FrencHill
174807	741425	6 - Other*/
;
select * from vansync.dncsurveyresponses
where dncsurveyresponses.surveyquestionid=174810--Witt
/*
174810	741429	1 - Strong Witt
174810	741430	2 - Lean Witt
174810	741431	3 - Undecided
174810	741434	4 - Lean Westerman
174810	741436	5 - Strong Westerman
174810	741437	6 - Other*/
;

select extract(dow from '2014-09-29'::date)
from vansync.dncsurveyresponses
limit 1;









