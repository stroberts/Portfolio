/* This query was meant to address a large discrepancy in undecided voters between African American voters and all other voters in the AG race. African American voters were undecided by a good 10 or so more points.
We wanted to examine the hypothetical, by media market, of what the overall AG race would look like if those African American voters were only undecided at the rate all other voters were.

To separate out the undecided block, and be able to maintain propotionality, I used two properties.

1) The sum of weights apportioned to a candidate in a group is equal to the percentage of that group apportioned to that candidate multiplied by the total weight of that group.
So letting w_a_h be the combined weight of AfAm Herring respondents, w_a be the combined weight of AfAm respondents, and h_a be the percentage (by weight) of AfAm respondents who support Herring:
w_a_h=h_a * w_a
as h_a = w_a_h / (w_a_h + w_a_o + w_a_u) = w_a_h / w_a

2) The percentage of Herring or Obenshain support in a three way contest is equal to the support in a two way contest, multiplied by one minus the percentage of respondents undecided
Letting h_i be the percentage Herring respondents, o_i be percentage Obenshain respondents, and u_a be percentage undecided respondents, in demographic group i,
h_i = sum(w_i_h)/sum(w_i_[h,o,u])
h_i + o_i + u_i = 1

h_i = [h_i/(h_i+o_i)]*(1-u_i)  <= h_i / (1- u_i) = h_i / (h_i + o_i)
where one can note that the quantity in square brackets [] is the two way split for Herring.

This makes is possible, having the two way and three way splits, to very simply change the undecided percentage in any particular group, and examine the effect on the entire population.
Since that number is typically calculated by summing the weights of x supporters, divided by the weights of all respondents, we simply split the weights as in line 8, represent the percentages for African Americans
as on line 16, then replace the undecided % u_a with the undecided % in the rest of the population, u_~a. This keeps all the relevant constraints in place.
*/


drop table if exists basetable_ag2way_MM; --So named because it's divided by media_market
create table basetable_ag2way_MM as(
SELECT
'06.5 - Media Market' tab_order,
p.Media_market as  tab1,
SUM(case when c.ag_horserace in(1,2,3) then c.weight else 0 end) / SUM(SUM(case when c.ag_horserace in(1,2) then c.weight else 0 end)) OVER() pct
,CAST(SUM(CASE WHEN c.ag_horserace in (1) and q6 = 2 THEN c.weight ELSE 0 END) AS FLOAT) / SUM(CASE WHEN c.ag_horserace in (1,2) and q6 = 2 THEN c.weight ELSE 0 END) pct_Herring_afam_2way
,CAST(SUM(CASE WHEN c.ag_horserace in (2) and q6 = 2 THEN c.weight ELSE 0 END) AS FLOAT) / SUM(CASE WHEN c.ag_horserace in (1,2) and q6 = 2 THEN c.weight ELSE 0 END) pct_Obenshain_afam_2way
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

drop table if exists basetable_ag2way_GarinMM; --So named because it's divided by Garin_media_markets
create table basetable_ag2way_GarinMM as(
SELECT
'06 - Media Market' tab_order,
case when Garin_media_markets  = 'DC - Exurbs' then 'Washington, DC - Exurbs' 
when Garin_media_markets  = 'DC - Inner Suburbs' then 'Washington, DC - Inner Suburbs' 
when Garin_media_markets  = 'DC - Rest of Market' then 'Washington, DC - Rest of Market' 
else Garin_media_markets 
end as  tab1,
SUM(case when c.ag_horserace in(1,2,3) then c.weight else 0 end) / SUM(SUM(case when c.ag_horserace in(1,2) then c.weight else 0 end)) OVER() pct
,CAST(SUM(CASE WHEN c.ag_horserace in (1) and q6 = 2 THEN c.weight ELSE 0 END) AS FLOAT) / SUM(CASE WHEN c.ag_horserace in (1,2) and q6 = 2 THEN c.weight ELSE 0 END) pct_Herring_afam_2way
,CAST(SUM(CASE WHEN c.ag_horserace in (2) and q6 = 2 THEN c.weight ELSE 0 END) AS FLOAT) / SUM(CASE WHEN c.ag_horserace in (1,2) and q6 = 2 THEN c.weight ELSE 0 END) pct_Obenshain_afam_2way
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

--the incredibly beautiful one!
SELECT
tab_order,
p.tab1-- tab1,
,CASE WHEN p.AfAm_tot>0 
	THEN ((CASE
		WHEN p.pct_Afam_undecided>0 THEN cast((1-p.pct_nonAfam_undecided) as float) -- defines size of non-undecided portion to be split
		ELSE 1::float --in some media markets, we had no Undecided AfAm respondents
		END)*p.AfAm_tot*p.pct_Herring_afam_2way+p.pct_nonAfam_Herring*non_AfAm_tot)/(p.AfAm_tot+non_AfAm_tot)
	ELSE p.pct_nonAfam_Herring --in some media markets, we had no AfAm respondents
	END revised_pct_herring
,CASE WHEN p.AfAm_tot>0 THEN ((CASE
		WHEN p.pct_Afam_undecided>0 THEN cast((1-p.pct_nonAfam_undecided) as float) 
		ELSE 1::float 
		END)*p.AfAm_tot*p.pct_Obenshain_afam_2way+p.pct_nonAfam_Obenshain*non_AfAm_tot)/(p.AfAm_tot+non_AfAm_tot)
	ELSE p.pct_nonAfam_Obenshain
	END revised_pct_Obenshain
,CASE WHEN p.pct_Afam_undecided>0 THEN p.pct_nonAfam_undecided --if there were undecided AfAm respondents to allocate, then the overall undecided % definitionally goes to the non_AfAm undecided
ELSE p.pct_nonAfam_undecided*non_AfAm_tot/(p.AfAm_tot+non_AfAm_tot) END revised_pct_Undecided 
,p.pct_Afam_undecided
,p.pct_nonAfam_undecided
from basetable_ag2way_GarinMM p
UNION ALL (SELECT
tab_order,
q.tab1-- tab1,
,CASE WHEN q.AfAm_tot>0 THEN ((CASE
		WHEN q.pct_Afam_undecided>0 THEN cast((1-q.pct_nonAfam_undecided) as float) 
		ELSE 1::float 
		END)*q.AfAm_tot*q.pct_Herring_afam_2way+q.pct_nonAfam_Herring*non_AfAm_tot)/(q.AfAm_tot+non_AfAm_tot)
	ELSE q.pct_nonAfam_Herring 
	END revised_pct_herring
,CASE WHEN q.AfAm_tot>0 
	THEN ((CASE
		WHEN q.pct_Afam_undecided>0 THEN cast((1-q.pct_nonAfam_undecided) as float) 
		ELSE 1::float 
		END)*q.AfAm_tot*q.pct_Obenshain_afam_2way+q.pct_nonAfam_Obenshain*non_AfAm_tot)/(q.AfAm_tot+non_AfAm_tot)
	ELSE q.pct_nonAfam_Obenshain 
	END revised_pct_Obenshain
,CASE WHEN q.pct_Afam_undecided>0 THEN q.pct_nonAfam_undecided
ELSE q.pct_nonAfam_undecided*non_AfAm_tot/(q.AfAm_tot+non_AfAm_tot) END revised_pct_Undecided
,q.pct_Afam_undecided
,q.pct_nonAfam_undecided
from basetable_ag2way_MM q)
order by 1,2
;