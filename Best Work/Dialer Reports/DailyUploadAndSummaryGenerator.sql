drop table if exists loginupload;
create table loginupload (
AgentID int,
Phone varchar,
LoginDTS varchar,
LogoutDTS varchar,
DialGroup varchar,
Presented varchar,
Accepted varchar,
RNA varchar,
ManualOutbound varchar,
PreviewDial varchar,
DispXfers varchar,
CallsXfered varchar,
TalkTime varchar,
AvgTalkTime varchar,
LoginTime varchar,
LoginUtilization varchar,
OffHookTime varchar,
RoundedOHTime varchar,
OffHookUtilization varchar,
OffHooktoLogin varchar,
WorkTime varchar,
BreakTime varchar,
AwayTime varchar,
LunchTime varchar,
TrainingTime varchar,
RingTime varchar,
EngagedTime varchar,
RNATime varchar,
PendingDispTime varchar,
AvgPendingDispTime varchar,
CallsPlacedOnHold varchar,
TimeOnHold varchar);

Copy loginupload from local 'C:\Users\Samuel R\Desktop\DialerHoursExports\whatever' delimiter ',' exceptions 'C:\Users\Samuel R\Desktop\DialerHoursExports\whatever';
ALTER TABLE loginupload
add column agent_id varchar;
--select substring(LoginTime,1,1) from logintime1 WHERE LoginTime is not NULL Limit 15;
Update logintupload
set agent_id=AgentID::varchar;

insert into logintimes
select * from loginupload;

drop table if exists CallUploader;
create table CallUploader
(
callID varchar,
ID varchar,
campaign_id varchar,
campaign_name varchar,
country_name varchar,
lead_phone varchar,
lead_state varchar,
timezone varchar,
title varchar,
first_name varchar,
mid_name varchar,
last_name varchar,
suffix varchar,
address1 varchar,
address2 varchar,
city varchar,
state varchar,
zip varchar,
lead_passes varchar,
pass_disposition varchar,
agent_disposition varchar,
call_start varchar,
duration varchar,
agent_notes varchar,
agent_id varchar,
external_agent_id varchar,
username varchar,
agent_first_name varchar,
agent_last_name varchar,
loaded_caller_id varchar,
on_hold varchar,
stupid_dial_type_marker varchar,
McAuliffe_ID varchar,
Issue varchar,
PtV varchar,
Vol_Ask varchar,
LG varchar,
AG varchar,
HoD varchar,
Email varchar
);

copy CallUploader
from local 'C:\Users\Samuel R\Downloads\whatever'
delimiter e'\t' skip 1 exceptions 'C:\Users\Samuel R\Desktop\Exceptions.txt';

Insert into AllCalls
select callID,
ID,
campaign_id,
campaign_name,
country_name,
lead_phone,
lead_state,
timezone,
title,
first_name,
mid_name,
last_name,
suffix,
address1,
address2,
city,
state,
zip,
lead_passes,
pass_disposition,
agent_disposition,
call_start,
duration,
agent_notes,
agent_id,
external_agent_id,
username,
agent_first_name,
agent_last_name,
loaded_caller_id,
on_hold,
McAuliffe_ID,
Issue,
PtV,
Vol_Ask,
LG,
AG,
HoD,
Email from CallUploader;


drop table if exists DialerSummaryReport;
Create table DialerSummaryReport as(
select t.CallDate,
	c.region,
	c.office,
	t.fo,
	t.login,
	t.OffHook,
	t.talk,
	--avr_talk,
	Attempts,
	Contact,
	ids,
	ids_pass_1,
	attempts_pass_1,
	ones,
	twos,
	threes,
	fours,
	fives from (select CallDate,
	agent_id,
	region,
	office,
	fo,
	--login,
	--OffHook,
	--talk,
	--avr_talk,
	sum(Attempts) Attempts,
	sum(Contacts) Contact,
	sum(ids) ids,
	sum(ids_pass_1) ids_pass_1,
	sum(attempts_pass_1) attempts_pass_1,
	sum(ones) ones,
	sum(twos) twos,
	sum(threes) threes,
	sum(fours) fours,
	sum(fives) fives from (
	FOs RIGHT JOIN (
		SELECT left(call_start,10) as CallDate,
		agent_id,
		count(*) as Attempts,
		sum(CASE WHEN agent_disposition='Complete' THEN 1 ELSE 0 END) as Contacts,
		sum(CASE WHEN left(McAuliffe_ID,1) in ('1','2','3','4','5') THEN 1 ELSE 0 END) as ids,
		sum(CASE WHEN lead_passes='1' AND left(McAuliffe_ID,1) in ('1','2','3','4','5') THEN 1 ELSE 0 END) as ids_pass_1,
		sum(CASE WHEN lead_passes='1' THEN 1 ELSE 0 END) as attempts_pass_1,
		sum(CASE WHEN left(McAuliffe_ID,1)='1' THEN 1 ELSE 0 END) as ones,
		sum(CASE WHEN left(McAuliffe_ID,1)='2' THEN 1 ELSE 0 END) as twos,
		sum(CASE WHEN left(McAuliffe_ID,1)='3' THEN 1 ELSE 0 END) as threes,
		sum(CASE WHEN left(McAuliffe_ID,1)='4' THEN 1 ELSE 0 END) as fours,
		sum(CASE WHEN left(McAuliffe_ID,1)='5' THEN 1 ELSE 0 END) as fives FROM AllCalls
		group by 1,2
		) a on FOs.id=a.agent_id --UNION (
	) b WHERE office IS NOT NULL GROUP BY 1,2,3,4,5 UNION SELECT left(call_start,10) as CallDate,
		'Statewide' as agent_id,
		0 as region,
		'Statewide' as office,
		'Statewide' as fo,
		count(*) as Attempts,
		sum(CASE WHEN agent_disposition='Complete' THEN 1 ELSE 0 END) as Contacts,
		sum(CASE WHEN left(McAuliffe_ID,1) in ('1','2','3','4','5') THEN 1 ELSE 0 END) as ids,
		sum(CASE WHEN lead_passes='1' AND left(McAuliffe_ID,1) in ('1','2','3','4','5') THEN 1 ELSE 0 END) as ids_pass_1,
		sum(CASE WHEN lead_passes='1' THEN 1 ELSE 0 END) as attempts_pass_1,
		sum(CASE WHEN left(McAuliffe_ID,1)='1' THEN 1 ELSE 0 END) as ones,
		sum(CASE WHEN left(McAuliffe_ID,1)='2' THEN 1 ELSE 0 END) as twos,
		sum(CASE WHEN left(McAuliffe_ID,1)='3' THEN 1 ELSE 0 END) as threes,
		sum(CASE WHEN left(McAuliffe_ID,1)='4' THEN 1 ELSE 0 END) as fours,
		sum(CASE WHEN left(McAuliffe_ID,1)='5' THEN 1 ELSE 0 END) as fives FROM AllCalls
		group by 1,2
) c FULL OUTER JOIN (select --region,
office,
fo,
CallDate,
login,
OffHook,
talk from 
FOs JOIN (select agent_id,
LoginDTS::date::varchar as CallDate,
sum((substring(LoginTime,1,2+length(LoginTime)-8)::int)*60+(substring(LoginTime,4+length(LoginTime)-8,2)::int)+(substring(LoginTime,length(LoginTime)-1,2)::int)/60)/60 as login,
sum((substring(OffHookTime,1,2+length(OffHookTime)-8)::int)*60+(substring(OffHookTime,4+length(OffHookTime)-8,2)::int)+(substring(OffHookTime,length(OffHookTime)-1,2)::int)/60)/60 as OffHook,
sum((substring(TalkTime,1,2+length(TalkTime)-8)::int)*60+(substring(TalkTime,4+length(TalkTime)-8,2)::int)+(substring(TalkTime,length(TalkTime)-1,2)::int)/60)/60 as Talk--,
from logintimes WHERE AgentID IS NOT NULL group by 1,2) s on s.agent_id=FOs.id UNION (select --0 as region,
'Statewide' as office,
'Statewide' as fo,
--'state' as fo_first,
--'wide' as fo_last,
--'iddy' as id,
--'Statewide' as agent_id,
LoginDTS::date::varchar as CallDate,
sum((substring(LoginTime,1,2+length(LoginTime)-8)::int)*60+(substring(LoginTime,4+length(LoginTime)-8,2)::int)+(substring(LoginTime,length(LoginTime)-1,2)::int)/60)/60 as login,
sum((substring(OffHookTime,1,2+length(OffHookTime)-8)::int)*60+(substring(OffHookTime,4+length(OffHookTime)-8,2)::int)+(substring(OffHookTime,length(OffHookTime)-1,2)::int)/60)/60 as OffHook,
sum((substring(TalkTime,1,2+length(TalkTime)-8)::int)*60+(substring(TalkTime,4+length(TalkTime)-8,2)::int)+(substring(TalkTime,length(TalkTime)-1,2)::int)/60)/60 as talk
from logintimes WHERE AgentID IS NOT NULL group by 1,2,3)) t on t.fo=c.fo and t.office=c.office and t.CallDate=c.CallDate
);