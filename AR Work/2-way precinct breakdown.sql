select distinct person.combined_ethnicity_full race
from analytics_ar.person;


select
vanprecinctid--, turfexport.regionname,turfexport.foname
,precinct.county, precinct.precinctname
,case person.combined_ethnicity_full
        when 'H' then 'Hispanic'
        when 'B' then 'Black'
        when 'W' then 'White'
        when 'A' then 'Asian'
        when 'N' then 'Native American'
        when 'U' then 'Unknown'
        end race
,round(sum(civis.senate_support_2014::real/100)) pryor_2way
,round(sum((100-civis.senate_support_2014)::real/100)) cotton_2way
,round(sum((civis.turnout_2014*civis.senate_support_2014)::real/10000)) pryor_2way_turnedout
,round(sum((civis.turnout_2014*(100-civis.senate_support_2014))::real/10000)) cotton_2way_turnedout
from analytics_ar.person
left join analytics_ar.all_civis_scores civis using(personid)
left join analytics_ar.all_dnc_scores dnc using(personid)
left join sroberts.precinct_basetable precinct using(precinctid)--,vanprecinctid)
where civis.current_reg
group by 1,2,3,4--,5
--limit 20
union all (select
vanprecinctid--, turfexport.regionname,turfexport.foname
,precinct.county, precinct.precinctname
,'all' race
,round(sum(civis.senate_support_2014::real/100)) pryor_2way
,round(sum((100-civis.senate_support_2014)::real/100)) cotton_2way
,round(sum((civis.turnout_2014*civis.senate_support_2014)::real/10000)) pryor_2way_turnedout
,round(sum((civis.turnout_2014*(100-civis.senate_support_2014))::real/10000)) cotton_2way_turnedout
from analytics_ar.person
left join analytics_ar.all_civis_scores civis using(personid)
left join analytics_ar.all_dnc_scores dnc using(personid)
left join sroberts.precinct_basetable precinct using(precinctid)--,vanprecinctid)
where civis.current_reg
group by 1,2,3,4--,5
)
order by 2,3,4 asc
;






