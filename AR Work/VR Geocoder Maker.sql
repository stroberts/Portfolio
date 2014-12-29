

drop table VRGeocodeTester;
select *,vaddress||', '||city||', '||state||', '||(case when zip4 is null then zip5 else zip5||'-'||zip4 end) full_address
into vrgeocodetester
from c2014_ar_coord_vansync.voterreg
where datecreated>='2014-04-01'
;

select * from c2014_ar_coord_vansync.voterreg
where latitude!=0 or longitude!=0
and datecreated>='2014-04-01'
;

select sum(case when mycampaignperson.actregion=3 then 1 else 0 end) 
from c2014_ar_coord_vansync.mycampaignperson
where mycampaignperson.actregion is null
;
