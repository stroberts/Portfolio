drop table if exists Afam_AG_TwoWay_ByMM_20131030_2;
create table Afam_AG_TwoWay_ByMM_20131030_2 as(
SELECT
'06.5 - Media Market' tab_order,
p.Media_market as  tab1,
SUM(case when c.ag_horserace in(1,2,3) then c.weight else 0 end) / SUM(SUM(case when c.ag_horserace in(1,2) then c.weight else 0 end)) OVER() pct
,CAST(SUM(CASE WHEN c.ag_horserace in (1) and q6 = 2 THEN c.weight ELSE 0 END) AS FLOAT) / SUM(CASE WHEN c.ag_horserace in (1,2) and q6 = 2 THEN c.weight ELSE 0 END) pct_Herring_afam
,CAST(SUM(CASE WHEN c.ag_horserace in (2) and q6 = 2 THEN c.weight ELSE 0 END) AS FLOAT) / SUM(CASE WHEN c.ag_horserace in (1,2) and q6 = 2 THEN c.weight ELSE 0 END) pct_Obenshain_Afam
,CAST(SUM(CASE WHEN c.ag_horserace in (3) and q6 = 2 THEN c.weight ELSE 0 END) AS FLOAT) / SUM(CASE WHEN c.ag_horserace in (1,2,3) and q6 = 2 THEN c.weight ELSE 0 END) pct_Afam_undecided
,CAST(SUM(CASE WHEN c.ag_horserace in (1) and q6 <> 2 THEN c.weight ELSE 0 END) AS FLOAT) / SUM(CASE WHEN c.ag_horserace in (1,2,3) and q6 <> 2THEN c.weight ELSE 0 END) pct_nonAfam_Herring
,CAST(SUM(CASE WHEN c.ag_horserace in (2) and q6 <> 2 THEN c.weight ELSE 0 END) AS FLOAT) / SUM(CASE WHEN c.ag_horserace in (1,2,3) and q6 <> 2THEN c.weight ELSE 0 END) pct_nonAfam_Obenshain
,CAST(SUM(CASE WHEN c.ag_horserace in (3) and q6 <> 2 THEN c.weight ELSE 0 END) AS FLOAT) / SUM(CASE WHEN c.ag_horserace in (1,2,3) and q6 <> 2THEN c.weight ELSE 0 END) pct_nonAfam_undecided
,cast(sum(case when c.q6=2 then c.weight else 0 end) as float) AfAm_tot
,cast(sum(case when c.q6<>2 then c.weight else 0 end) as float) non_AfAm_tot
FROM analytics_VA.person p
JOIN c2013_levinj.weighting__VA_trackers c using(personid)
LEFT JOIN c2013_levinj.va_draft_model_gotv_score_20131019 USING(personid)
WHERE p.state_code = 'VA' and c.ag_horserace in(1,2,3) and survey_id = 'va_tracker_20131024'  and is_current_reg IS TRUE AND p.media_market IS NOT NULL
GROUP BY 1,2);

drop table if exists Afam_AG_TwoWay_ByMM_1_20131030_2;
create table Afam_AG_TwoWay_ByMM_1_20131030_2 as(
SELECT
'06 - Media Market' tab_order,
case when Garin_media_markets  = 'DC - Exurbs' then 'Washington, DC - Exurbs' 
when Garin_media_markets  = 'DC - Inner Suburbs' then 'Washington, DC - Inner Suburbs' 
when Garin_media_markets  = 'DC - Rest of Market' then 'Washington, DC - Rest of Market' 
else Garin_media_markets 
end as  tab1,
SUM(case when c.ag_horserace in(1,2,3) then c.weight else 0 end) / SUM(SUM(case when c.ag_horserace in(1,2) then c.weight else 0 end)) OVER() pct
,CAST(SUM(CASE WHEN c.ag_horserace in (1) and q6 = 2 THEN c.weight ELSE 0 END) AS FLOAT) / SUM(CASE WHEN c.ag_horserace in (1,2) and q6 = 2 THEN c.weight ELSE 0 END) pct_Herring_afam
,CAST(SUM(CASE WHEN c.ag_horserace in (2) and q6 = 2 THEN c.weight ELSE 0 END) AS FLOAT) / SUM(CASE WHEN c.ag_horserace in (1,2) and q6 = 2 THEN c.weight ELSE 0 END) pct_Obenshain_Afam
,CAST(SUM(CASE WHEN c.ag_horserace in (3) and q6 = 2 THEN c.weight ELSE 0 END) AS FLOAT) / SUM(CASE WHEN c.ag_horserace in (1,2,3) and q6 = 2 THEN c.weight ELSE 0 END) pct_Afam_undecided
,CAST(SUM(CASE WHEN c.ag_horserace in (1) and q6 <> 2 THEN c.weight ELSE 0 END) AS FLOAT) / SUM(CASE WHEN c.ag_horserace in (1,2,3) and q6 <> 2THEN c.weight ELSE 0 END) pct_nonAfam_Herring
,CAST(SUM(CASE WHEN c.ag_horserace in (2) and q6 <> 2 THEN c.weight ELSE 0 END) AS FLOAT) / SUM(CASE WHEN c.ag_horserace in (1,2,3) and q6 <> 2THEN c.weight ELSE 0 END) pct_nonAfam_Obenshain
,CAST(SUM(CASE WHEN c.ag_horserace in (3) and q6 <> 2 THEN c.weight ELSE 0 END) AS FLOAT) / SUM(CASE WHEN c.ag_horserace in (1,2,3) and q6 <> 2THEN c.weight ELSE 0 END) pct_nonAfam_undecided
,cast(sum(case when c.q6=2 then c.weight else 0 end) as float) AfAm_tot
,cast(sum(case when c.q6<>2 then c.weight else 0 end) as float) non_AfAm_tot
FROM analytics_VA.person p
JOIN c2013_levinj.weighting__VA_trackers c using(personid)
LEFT JOIN c2013_levinj.va_draft_model_gotv_score_20131019 USING(personid)
left join wellerj.VA_Garin_media_markets using(county_fips)
WHERE p.state_code = 'VA' and c.ag_horserace in(1,2,3) and survey_id = 'va_tracker_20131024'  and is_current_reg IS TRUE AND p.media_market IS NOT NULL
GROUP BY 1,2);

--the incredibly beatutiful one!
SELECT
tab_order,
p.tab1-- tab1,
,CASE WHEN p.AfAm_tot>0 THEN ((CASE
	WHEN p.pct_Afam_undecided>0 THEN cast((1-p.pct_nonAfam_undecided) as float) -- defines size of non-undecided portion to be split
	ELSE 1::float --reverts if no undecideds to reallocate
	END)*p.AfAm_tot*p.pct_Herring_afam+p.pct_nonAfam_Herring*non_AfAm_tot)/(p.AfAm_tot+non_AfAm_tot)
	ELSE p.pct_nonAfam_Herring END revised_pct_herring
,CASE WHEN p.AfAm_tot>0 THEN ((CASE
	WHEN p.pct_Afam_undecided>0 THEN cast((1-p.pct_nonAfam_undecided) as float) -- defines size of non-undecided portion to be split
	ELSE 1::float --reverts if no undecideds to reallocate
	END)*p.AfAm_tot*p.pct_Obenshain_Afam+p.pct_nonAfam_Obenshain*non_AfAm_tot)/(p.AfAm_tot+non_AfAm_tot)
	ELSE p.pct_nonAfam_Obenshain END revised_pct_Obenshain
,CASE WHEN p.pct_Afam_undecided>0 THEN p.pct_nonAfam_undecided
ELSE p.pct_nonAfam_undecided*non_AfAm_tot/(p.AfAm_tot+non_AfAm_tot) END revised_pct_Undecided
,p.pct_Afam_undecided
,p.pct_nonAfam_undecided
from Afam_AG_TwoWay_ByMM_1_20131030_2 p
UNION ALL (SELECT
tab_order,
q.tab1-- tab1,
,CASE WHEN q.AfAm_tot>0 THEN ((CASE
	WHEN q.pct_Afam_undecided>0 THEN cast((1-q.pct_nonAfam_undecided) as float) -- defines size of non-undecided portion to be split
	ELSE 1::float --reverts if no undecideds to reallocate
	END)*q.AfAm_tot*q.pct_Herring_afam+q.pct_nonAfam_Herring*non_AfAm_tot)/(q.AfAm_tot+non_AfAm_tot)
	ELSE q.pct_nonAfam_Herring END revised_pct_herring
,CASE WHEN q.AfAm_tot>0 THEN ((CASE
	WHEN q.pct_Afam_undecided>0 THEN cast((1-q.pct_nonAfam_undecided) as float) -- defines size of non-undecided portion to be split
	ELSE 1::float --reverts if no undecideds to reallocate
	END)*q.AfAm_tot*q.pct_Obenshain_Afam+q.pct_nonAfam_Obenshain*non_AfAm_tot)/(q.AfAm_tot+non_AfAm_tot)
	ELSE q.pct_nonAfam_Obenshain END revised_pct_Obenshain
,CASE WHEN q.pct_Afam_undecided>0 THEN q.pct_nonAfam_undecided
ELSE q.pct_nonAfam_undecided*non_AfAm_tot/(q.AfAm_tot+non_AfAm_tot) END revised_pct_Undecided
,q.pct_Afam_undecided
,q.pct_nonAfam_undecided
from Afam_AG_TwoWay_ByMM_20131030_2 q)
order by 1,2
;