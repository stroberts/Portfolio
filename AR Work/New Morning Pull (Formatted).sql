--insert into historicalmorningreports
--select (current_date-interval '1 Day') reportdate, * from sroberts.dailymorningreportbasetable
;
--insert into conflist
--select *,current_date-interval '1 Days' "confcalldate"
--from todaysconfirmcalls
;
DELETE
FROM
    sroberts.conflist
WHERE
    confcalldate<(CURRENT_DATE-1-extract(dow FROM CURRENT_DATE+1)::int%7) ;
DROP TABLE
    sroberts.eventattendees CASCADE;
SELECT
    *,
    CASE
        WHEN shift.wasconfirmed=1
        AND shift.currentstatus='Completed'
        THEN 'Confirmed_completed'
        WHEN shift.wasconfirmed=1
        AND (shift.currentstatus='No Show'
            OR  shift.currentstatus='Declined')
        THEN 'Confirmed_uncompleted'
        WHEN shift.wasconfirmed=1
        THEN 'Confirmed_unclosed'
        WHEN shift.currentstatus='Completed'
        THEN 'Unconfirmed_completed'
        WHEN (shift.currentstatus='No Show'
            OR  shift.currentstatus='Declined')
        THEN 'Unconfirmed_uncompleted'
        ELSE 'Unconfirmed_unclosed'
    END finalsitchverbose ,
    CASE --completed => 1 (mod 2), closed => 1 (mod 3)
        WHEN shift.currentstatus='Completed'
        THEN 7
        WHEN shift.currentstatus='No Show'
        OR  shift.currentstatus='Declined'
        THEN 4
        ELSE 6
    END finalsitch
INTO
    sroberts.eventattendees
FROM
    (
        SELECT
            status.eventsignupid ,
            events.eventid ,
            COALESCE(turf.region, 'Unturfed')                region ,
            COALESCE(turf.organizer, 'Unturfed')             FO ,
            COALESCE(turf.team, 'Unturfed')                  Team ,
            MIN(status.datecreated-interval '1 Hours')::DATE recruiteddate ,
            econtact.vanid ,
            events.eventcalendarname eventtype ,
            econtact.datetimeoffsetbegin
            /*-interval '1 Hours')*/
            ::DATE eventdate--left(events.dateoffsetbegin,10) eventdate
            ,
            MAX(
                CASE
                    WHEN status.rownumber=1
                    THEN status.eventstatusname
                    ELSE NULL
                END) currentstatus ,
            MAX(
                CASE
                    WHEN status.eventstatusname='Confirmed'
                    THEN 1
                    ELSE 0
                END) wasconfirmed ,
            MAX(
                CASE
                    WHEN status.eventstatusname IN('Scheduled',
                                                   'Confirmed',
                                                   'Completed')
                    THEN 1
                    ELSE NULL
                END)              wasschedconfcomp ,
            MAX(status.rownumber) numtouches
        FROM
            (
                SELECT
                    * ,
                    row_number() OVER( partition BY eventsignupid ORDER BY datecreated DESC ,
                    eventsignupseventstatusid DESC ,iscurrentstatus DESC ) rownumber
                FROM
                    c2014_ar_coord_vansync.eventscontactsstatuses ) status
        INNER JOIN--left join
            c2014_ar_coord_vansync.eventscontacts econtact
        USING
            (eventsignupid)
        LEFT JOIN
            c2014_ar_coord_vansync.events
        USING
            (eventid)
        LEFT JOIN
            c2014_ar_coord_vansync.mycampaignperson person
        ON
            econtact.vanid=person.vanid
        LEFT JOIN
            c2014_ar_coord_vansync.mycampaignmergepersons
        ON
            person.vanid=mycampaignmergepersons.mergevanid
        LEFT JOIN
            sroberts.attributer turf
        ON
            COALESCE(mycampaignmergepersons.mastervanid, person.vanid)=turf.vanid
        WHERE
            econtact.datesuppressed IS NULL
        AND events.datesuppressed IS NULL
        GROUP BY
            1,2,3,4,5,7,8,9) shift ;
CREATE VIEW
    actioneventattendees AS
SELECT
    *
FROM
    eventattendees a
WHERE
    eventtype IN ('Voter Reg',
                  'Canvass',
                  'Phone Bank',
                  'Vol Recruitment') ;
GRANT
SELECT
ON
    eventattendees TO dortiz;
GRANT
SELECT
ON
    actioneventattendees TO dortiz;
--allocate all active or recently dropped off vols into a table, largly split on when they became/
-- will become active/inactive (with those allocated to "today" simply added to keep the total
-- right)
DROP TABLE
    activevols;
SELECT
    vanid ,
    region ,
    fo ,
    CASE
        WHEN MIN(eventdate)=(CURRENT_DATE-interval '1 Day')
        THEN 'Yesterday'
        WHEN MIN(eventdate)=(CURRENT_DATE-1-extract(dow FROM CURRENT_DATE+1)%7)
        THEN 'Week to Date'
        WHEN MAX(eventdate)>=(CURRENT_DATE-interval '23 Days')
        THEN 'Today'
        WHEN MAX(eventdate)>=(CURRENT_DATE-interval '30 Days')
        THEN 'Week to Come'
        WHEN MAX(eventdate)=(CURRENT_DATE-interval '31 Days')
        THEN 'Yesterday'
        ELSE 'Week to Date'
    END            timeperiod ,
    MAX(eventtype) eventtype --needed only to keep from overmatching on join
    ,
    CASE
        WHEN MAX(eventdate)>=(CURRENT_DATE-interval '30 Days')
        THEN 1
    END Active ,
    CASE
        WHEN MAX(eventdate)>=(CURRENT_DATE-interval '30 Days')
        THEN NULL
        ELSE 1
    END Dormant
INTO
    activevols
FROM
    eventattendees
WHERE
    finalsitch=7
AND eventdate>=(CURRENT_DATE-31-extract(dow FROM CURRENT_DATE+1)%7)
AND eventdate<CURRENT_DATE
GROUP BY
    1,2,3 ;
--create a table of attendees categorized by whether they're attendees from the week to day,
-- yesterday, or the weeek to come
--will be duplicates, which is fine - the category will differenciate
DROP TABLE
    timeeventattendees;
CREATE TABLE
    timeeventattendees AS
    (
        SELECT
            'Week to Date' AS timeperiod ,
            *
        FROM
            sroberts.eventattendees
        WHERE
            eventdate<CURRENT_DATE
        AND eventdate>=(CURRENT_DATE-1-extract(dow FROM CURRENT_DATE+1)::int%7)
    )
UNION ALL
    (
        SELECT
            'SchedWeek to Date' AS timeperiod ,
            *
        FROM
            sroberts.eventattendees shifts
        WHERE
            recruiteddate<CURRENT_DATE
        AND recruiteddate>=(CURRENT_DATE-1-extract(dow FROM CURRENT_DATE+1)::int%7) )
UNION ALL
    (
        SELECT
            'Yesterday' AS timeperiod ,
            *
        FROM
            sroberts.eventattendees
        WHERE
            eventdate=(CURRENT_DATE-interval '1 Day') )
UNION ALL
    (
        SELECT
            'SchedYesterday' AS timeperiod ,
            *
        FROM
            sroberts.eventattendees shifts
        WHERE
            recruiteddate=(CURRENT_DATE-interval '1 Day') )
UNION ALL
    (
        SELECT
            'Week to Come' AS timeperiod ,
            *
        FROM
            sroberts.eventattendees
        WHERE
            eventdate>=CURRENT_DATE
        AND eventdate<(CURRENT_DATE+7-extract(dow FROM CURRENT_DATE+2)::int%7)
        AND currentstatus!='Declined')
UNION ALL
    (
        SELECT
            'Today' AS timeperiod ,
            *
        FROM
            sroberts.eventattendees
        WHERE
            eventdate=CURRENT_DATE )
UNION ALL
    (
        SELECT
            'This Weekend' AS timeperiod ,
            *
        FROM
            sroberts.eventattendees
        WHERE
            eventdate IN ((CURRENT_DATE+5-extract(dow FROM CURRENT_DATE+6)%7),
                          (CURRENT_DATE+6-extract(dow FROM CURRENT_DATE+6)%7)) )
UNION ALL
    (
        SELECT
            'Next Week' AS timeperiod ,
            *
        FROM
            sroberts.eventattendees
        WHERE
            eventdate<(CURRENT_DATE+14-extract(dow FROM CURRENT_DATE+2)::int%7)
        AND eventdate>=(CURRENT_DATE+7-extract(dow FROM CURRENT_DATE+2)::int%7) ) ;
DROP TABLE
    actionplustimeeventattendees;
CREATE TABLE
    actionplustimeeventattendees AS
SELECT
    *
FROM
    timeeventattendees a
WHERE
    eventtype IN ('Voter Reg',
                  'Canvass',
                  'Phone Bank',
                  'Vol Recruitment',
                  '1-on-1 Meeting') ;
DROP TABLE
    sroberts.eventsummary;
SELECT
    *
INTO
    sroberts.eventsummary
FROM
    (
        SELECT
            timeperiod ,
            Region
            /*FO 'Statewide'*/
            turf ,
            eventtype ,
            SUM(wasschedconfcomp)         Scheduled ,
            SUM(mod(shifts.finalsitch,2)) Showed ,
            1-SUM(mod(shifts.finalsitch,2))/NULLIF(SUM(shifts.wasschedconfcomp),0)::FLOAT
            grossflakerate2 ,
            1-SUM(mod(shifts.finalsitch,2))/NULLIF(SUM(mod(shifts.finalsitch,3)),0)::FLOAT
                                                                      closedflakerate ,
            1-SUM(mod(shifts.finalsitch,3))/NULLIF(COUNT(*),0)::FLOAT percentunclosed ,
            SUM(
                CASE
                    WHEN shifts.currentstatus IN ('Scheduled',
                                                  'Confirmed',
                                                  'Left Msg')
                    THEN 1
                END) Expected ,
            SUM(
                CASE
                    WHEN shifts.currentstatus='Confirmed'
                    THEN 1
                END)                 ExpectedConf ,
            SUM(shifts.wasconfirmed) confirmed--/nullif(count(*),0)::float percentconfirmed
            ,
            COUNT(DISTINCT weighter.vanid)                       uniqueshowers ,
            SUM(mod(shifts.finalsitch,2)/weighter.weight::FLOAT) weighteduniqueshowers
        FROM
            sroberts.actionplustimeeventattendees shifts
        LEFT JOIN
            (
                SELECT
                    timeperiod ,
                    vanid,
                    COUNT(DISTINCT eventtype) numeventtypes,
                    SUM(mod(finalsitch,2))    weight
                FROM
                    sroberts.actionplustimeeventattendees
                WHERE
                    eventtype!='1-on-1 Meeting'
                AND finalsitch=7
                GROUP BY
                    1,2) weighter
        USING
            (timeperiod,vanid)
        GROUP BY
            1,2,3
        ORDER BY
            1 DESC,
            2 ASC ) c
FULL OUTER JOIN
    (
        SELECT
            RIGHT(timeperiod,LEN(timeperiod)-5) timeperiod ,
            Region
            /*FO 'Statewide'*/
            turf ,
            eventtype ,
            SUM(rec.wasschedconfcomp) recruited
        FROM
            sroberts.actionplustimeeventattendees rec--actioneventattendees is a view
        WHERE
            LEFT(timeperiod,1)='S'
        GROUP BY
            1,2,3
        ORDER BY
            1 DESC,
            2 ) b
USING
    (timeperiod,turf,eventtype)
FULL OUTER JOIN
    (
        SELECT
            timeperiod ,
            region    turf ,
            'Canvass' eventtype --this is only to keep the join from duplicating
            ,
            SUM(active)  newshowed ,
            SUM(dormant) droppedoff
        FROM
            activevols
        GROUP BY
            1,2,3 ) d
USING
    (timeperiod,turf,eventtype)
ORDER BY
    1 DESC,
    2,3 ASC ;
INSERT
INTO
    sroberts.eventsummary
SELECT
    *
FROM
    (
        SELECT
            timeperiod ,
            FO
            /*Region FO 'Statewide'*/
            turf ,
            eventtype ,
            SUM(wasschedconfcomp)         Scheduled ,
            SUM(mod(shifts.finalsitch,2)) Showed ,
            1-SUM(mod(shifts.finalsitch,2))/NULLIF(SUM(shifts.wasschedconfcomp),0)::FLOAT
            grossflakerate2 ,
            1-SUM(mod(shifts.finalsitch,2))/NULLIF(SUM(mod(shifts.finalsitch,3)),0)::FLOAT
                                                                      closedflakerate ,
            1-SUM(mod(shifts.finalsitch,3))/NULLIF(COUNT(*),0)::FLOAT percentunclosed ,
            SUM(
                CASE
                    WHEN shifts.currentstatus IN ('Scheduled',
                                                  'Confirmed',
                                                  'Left Msg')
                    THEN 1
                END) Expected ,
            SUM(
                CASE
                    WHEN shifts.currentstatus='Confirmed'
                    THEN 1
                END)                 ExpectedConf ,
            SUM(shifts.wasconfirmed) confirmed--/nullif(count(*),0)::float percentconfirmed
            ,
            COUNT(DISTINCT weighter.vanid)                       uniqueshowers ,
            SUM(mod(shifts.finalsitch,2)/weighter.weight::FLOAT) weighteduniqueshowers
        FROM
            sroberts.actionplustimeeventattendees shifts
        LEFT JOIN
            (
                SELECT
                    timeperiod ,
                    vanid,
                    COUNT(DISTINCT eventtype) numeventtypes,
                    SUM(mod(finalsitch,2))    weight
                FROM
                    sroberts.actionplustimeeventattendees
                WHERE
                    eventtype!='1-on-1 Meeting'
                AND finalsitch=7
                GROUP BY
                    1,2) weighter
        USING
            (timeperiod,vanid)
        GROUP BY
            1,2,3
        ORDER BY
            1 DESC,
            2 ASC ) c
FULL OUTER JOIN
    (
        SELECT
            RIGHT(timeperiod,LEN(timeperiod)-5) timeperiod ,
            FO
            /*Region FO 'Statewide'*/
            turf ,
            eventtype ,
            SUM(rec.wasschedconfcomp) recruited
        FROM
            sroberts.actionplustimeeventattendees rec--actioneventattendees is a view
        WHERE
            LEFT(timeperiod,1)='S'
        GROUP BY
            1,2,3
        ORDER BY
            1 DESC,
            2 ) b
USING
    (timeperiod,turf,eventtype)
FULL OUTER JOIN
    (
        SELECT
            timeperiod ,
            fo           turf ,
            'Canvass'    eventtype ,
            SUM(active)  newshowed ,
            SUM(dormant) droppedoff
        FROM
            activevols
        GROUP BY
            1,2,3 ) d
USING
    (timeperiod,turf,eventtype)
ORDER BY
    1 DESC,
    2,3 ASC ;
INSERT
INTO
    sroberts.eventsummary
SELECT
    *
FROM
    (
        SELECT
            timeperiod ,
            'Statewide'
            /*Region FO 'Statewide'*/
            turf ,
            eventtype ,
            SUM(wasschedconfcomp) Scheduled
            --                    here I sneak in the number of new vols scheduled today - it doesn
            -- '                  t fit in anywhere else, I only need the statewide number
            --                    and the column would have no use for that "Today" row anyway
            ,
            SUM(
                CASE
                    WHEN timeperiod='Today'
                    AND av.active IS NULL
                    AND shifts.currentstatus IN ('Scheduled',
                                                 'Confirmed',
                                                 'Left Msg')
                    THEN 1
                    ELSE mod(shifts.finalsitch,2)
                END) Showed ,
            1-SUM(mod(shifts.finalsitch,2))/NULLIF(SUM(shifts.wasschedconfcomp),0)::FLOAT
            grossflakerate2 ,
            1-SUM(mod(shifts.finalsitch,2))/NULLIF(SUM(mod(shifts.finalsitch,3)),0)::FLOAT
                                                                      closedflakerate ,
            1-SUM(mod(shifts.finalsitch,3))/NULLIF(COUNT(*),0)::FLOAT percentunclosed ,
            SUM(
                CASE
                    WHEN shifts.currentstatus IN ('Scheduled',
                                                  'Confirmed',
                                                  'Left Msg')
                    THEN 1
                END) Expected ,
            SUM(
                CASE
                    WHEN shifts.currentstatus='Confirmed'
                    THEN 1
                END)                 ExpectedConf ,
            SUM(shifts.wasconfirmed) confirmed--/nullif(count(*),0)::float percentconfirmed
            ,
            COUNT(DISTINCT weighter.vanid)                       uniqueshowers ,
            SUM(mod(shifts.finalsitch,2)/weighter.weight::FLOAT) weighteduniqueshowers
        FROM
            sroberts.actionplustimeeventattendees shifts
        LEFT JOIN
            (
                SELECT
                    timeperiod ,
                    vanid,
                    COUNT(DISTINCT eventtype) numeventtypes,
                    SUM(mod(finalsitch,2))    weight
                FROM
                    sroberts.actionplustimeeventattendees
                WHERE
                    eventtype!='1-on-1 Meeting'
                AND finalsitch=7
                GROUP BY
                    1,2) weighter
        USING
            (timeperiod,vanid)
        LEFT JOIN
            (
                SELECT
                    vanid,
                    active
                FROM
                    activevols) av
        USING
            (vanid)
        GROUP BY
            1,2,3
        ORDER BY
            1 DESC,
            2 ASC ) c
FULL OUTER JOIN
    (
        SELECT
            RIGHT(timeperiod,LEN(timeperiod)-5) timeperiod ,
            'Statewide'
            /*Region FO 'Statewide'*/
            turf ,
            eventtype ,
            SUM(rec.wasschedconfcomp) recruited
        FROM
            sroberts.actionplustimeeventattendees rec--actioneventattendees is a view
        WHERE
            LEFT(timeperiod,1)='S'
        GROUP BY
            1,2,3
        ORDER BY
            1 DESC,
            2 ) b
USING
    (timeperiod,turf,eventtype)
FULL OUTER JOIN
    (
        SELECT
            timeperiod ,
            'Statewide'  turf ,
            'Canvass'    eventtype ,
            SUM(active)  newshowed ,
            SUM(dormant) droppedoff
        FROM
            activevols
        GROUP BY
            1,2,3 ) d
USING
    (timeperiod,turf,eventtype)
ORDER BY
    1 DESC,
    2,3 ASC ;
--select * from eventsummary
--where turf='Statewide'
--order by 2 asc, 1 desc;
DROP TABLE
    quasiactivevols;
--creates list of people who will soon fall off Active Vols
SELECT
    region,
    fo,
    vanid,
    eventdate
INTO
    quasiactivevols
FROM
    (
        SELECT
            * ,
            row_number() OVER( partition BY vanid ORDER BY eventdate DESC ) rn
        FROM
            eventattendees
        WHERE
            eventtype IN ('Voter Reg',
                          'Canvass',
                          'Phone Bank',
                          'Vol Recruitment')
        AND currentstatus='Completed')
WHERE
    rn=1
AND eventdate>(CURRENT_DATE-interval '30 Days')
AND eventdate<(CURRENT_DATE-interval '20 Days')
ORDER BY
    1,2 DESC ;
--creates table of confirmation calls for FOs to call into(via bulk upload for now
--eventually via direct sync to van. also usable to track which calls are confirm calls
--in the week by archiving
/*Block Commented Part creates a call-list-ready table*/
DROP TABLE
    sroberts.todaysconfirmcalls;
SELECT
    eventattendees.vanid,
    region,
    fo
    /*,eventtype
    ,mcp.Name,mcp.phone
    , (ec.datetimeoffsetbegin-interval '1 Hour') ShiftStart
    , (ec.datetimeoffsetend-interval '1 Hour') ShiftEnd*/
INTO
    todaysconfirmcalls
FROM
    sroberts.eventattendees
    /*left join (
    select vanid avanid, phone, concat(firstname,concat(' ',lastname)) "Name"
    from
    c2014_ar_coord_vansync.mycampaignperson
    ) mcp on vanid=avanid
    left join c2014_ar_coord_vansync.eventscontacts ec using(eventsignupid)
    */
WHERE
    eventattendees.currentstatus!='Declined'
AND eventattendees.eventdate>CURRENT_DATE
AND eventattendees.eventdate<(CURRENT_DATE+interval '4 Days') ;
GRANT
SELECT
ON
    todaysconfirmcalls TO dortiz;
DROP TABLE
    MyCPhoneSummary ;
SELECT
    CASE
        WHEN ch.datecanvassed::DATE=(CURRENT_DATE-interval '1 Day')
        THEN 'Yesterday'
        ELSE 'Week to Date'
    END                         timeperiod ,
    COALESCE(Region,'Unturfed') turf ,
    'Vol Recruitment'           eventtype
    --,                         count(*) MyCAttempts
    --,                         sum(case when ch.resultid=14 then 1 end) MyCContacts
    ,
    COUNT(DISTINCT ch.contactscontactid) MyCAttempts ,
    COUNT(DISTINCT
    CASE
        WHEN ch.resultid=14
        THEN ch.contactscontactid
    END) MyCContacts
INTO
    MyCPhoneSummary
FROM
    c2014_ar_coord_vansync.contacthistoryexportmc ch
LEFT JOIN
    c2014_ar_coord_vansync.mycampaignmergepersons mcmp
ON
    ch.vanid=mcmp.mergevanid
LEFT JOIN
    sroberts.attributer attr
ON
    COALESCE(mcmp.mastervanid, ch.vanid)=attr.vanid
WHERE
    ch.datecanvassed::DATE<CURRENT_DATE
AND ch.datecanvassed::DATE>=(CURRENT_DATE-1-extract(dow FROM CURRENT_DATE+1)::int%7)
AND contacttypeid=1--phone
GROUP BY
    1,2
ORDER BY
    1 DESC,
    2 ASC ;
INSERT
INTO
    MyCPhoneSummary
SELECT
    CASE
        WHEN ch.datecanvassed::DATE=CURRENT_DATE-interval '1 Day'
        THEN 'Yesterday'
        ELSE 'Week to Date'
    END                            timeperiod ,
    COALESCE(Organizer,'Unturfed') turf ,
    'Vol Recruitment'              eventtype ,
    COUNT(*)                       MyCAttempts ,
    SUM(
        CASE
            WHEN ch.resultid=14
            THEN 1
        END) MyCContacts
FROM
    c2014_ar_coord_vansync.contacthistoryexportmc ch
LEFT JOIN
    c2014_ar_coord_vansync.mycampaignmergepersons mcmp
ON
    ch.vanid=mcmp.mergevanid
LEFT JOIN
    sroberts.attributer attr
ON
    COALESCE(mcmp.mastervanid, ch.vanid)=attr.vanid
WHERE
    ch.datecanvassed::DATE<CURRENT_DATE
AND ch.datecanvassed::DATE>=(CURRENT_DATE-1-extract(dow FROM CURRENT_DATE+1)::int%7)
AND contacttypeid=1--phone
GROUP BY
    1,2
ORDER BY
    1 DESC,
    2 ASC ;
INSERT
INTO
    MyCPhoneSummary
SELECT
    CASE
        WHEN ch.datecanvassed::DATE=CURRENT_DATE-interval '1 Day'
        THEN 'Yesterday'
        ELSE 'Week to Date'
    END               timeperiod ,
    'Statewide'       turf ,
    'Vol Recruitment' eventtype ,
    COUNT(*)          MyCAttempts ,
    SUM(
        CASE
            WHEN ch.resultid=14
            THEN 1
        END) MyCContacts
FROM
    c2014_ar_coord_vansync.contacthistoryexportmc ch
    --left join c2014_ar_coord_vansync.mycampaignmergepersons mcmp on ch.vanid=mcmp.mergevanid
    --left join sroberts.attributer attr on coalesce(mcmp.mastervanid, ch.vanid)=attr.vanid
WHERE
    ch.datecanvassed::DATE<CURRENT_DATE
AND ch.datecanvassed::DATE>=(CURRENT_DATE-1-extract(dow FROM CURRENT_DATE+1)::int%7)
AND contacttypeid=1--phone
GROUP BY
    1,2
ORDER BY
    1 DESC,
    2 ASC ;
DROP TABLE
    oneonones ;
SELECT
    CASE
        WHEN sq.datecanvassed::DATE=CURRENT_DATE-interval '1 Day'
        THEN 'Yesterday'
        ELSE 'Week to Date'
    END                         timeperiod ,
    COALESCE(Region,'Unturfed') turf ,
    '1-on-1 Meeting'            eventtype ,
    SUM(
        CASE
            WHEN sq.surveyresponseid IN (692860,692861,692862)
            THEN 1
        END) "1:1s"
INTO
    OneonOnes
FROM
    c2014_ar_coord_vansync.surveyresponseexportmc sq
LEFT JOIN
    c2014_ar_coord_vansync.mycampaignmergepersons mcmp
ON
    sq.vanid=mcmp.mergevanid
LEFT JOIN
    sroberts.attributer attr
ON
    COALESCE(mcmp.mastervanid, sq.vanid)=attr.vanid
WHERE
    sq.datecanvassed::DATE<CURRENT_DATE
AND sq.datecanvassed::DATE>=(CURRENT_DATE-1-extract(dow FROM CURRENT_DATE+1)::int%7)
AND sq.surveyquestionid=163085--1:1s
GROUP BY
    1,2
ORDER BY
    1 DESC,
    2 ASC ;
INSERT
INTO
    OneonOnes
SELECT
    CASE
        WHEN sq.datecanvassed::DATE=CURRENT_DATE-interval '1 Day'
        THEN 'Yesterday'
        ELSE 'Week to Date'
    END                            timeperiod ,
    COALESCE(Organizer,'Unturfed') turf ,
    '1-on-1 Meeting'               eventtype ,
    SUM(
        CASE
            WHEN sq.surveyresponseid IN (692860,692861,692862)
            THEN 1
        END) "1:1s"
FROM
    c2014_ar_coord_vansync.surveyresponseexportmc sq
LEFT JOIN
    c2014_ar_coord_vansync.mycampaignmergepersons mcmp
ON
    sq.vanid=mcmp.mergevanid
LEFT JOIN
    sroberts.attributer attr
ON
    COALESCE(mcmp.mastervanid, sq.vanid)=attr.vanid
WHERE
    sq.datecanvassed::DATE<CURRENT_DATE
AND sq.datecanvassed::DATE>=(CURRENT_DATE-1-extract(dow FROM CURRENT_DATE+1)::int%7)
AND sq.surveyquestionid=163085--1:1s
GROUP BY
    1,2
ORDER BY
    1 DESC,
    2 ASC ;
INSERT
INTO
    OneonOnes
SELECT
    CASE
        WHEN sq.datecanvassed::DATE=(CURRENT_DATE-interval '1 Day')
        THEN 'Yesterday'
        ELSE 'Week to Date'
    END              timeperiod ,
    'Statewide'      turf ,
    '1-on-1 Meeting' eventtype ,
    SUM(
        CASE
            WHEN sq.surveyresponseid IN (692860,692861,692862)
            THEN 1
        END) "1:1s"
FROM
    (
        SELECT
            *,
            row_number() over( partition BY vanid, (datecanvassed-interval '1 hour')::DATE ORDER BY
            contactssurveyresponseid DESC ) rn
        FROM
            c2014_ar_coord_vansync.surveyresponseexportmc) sq
    --left join c2014_ar_coord_vansync.mycampaignmergepersons mcmp on sq.vanid=mcmp.mergevanid
    --left join sroberts.attributer attr on coalesce(mcmp.mastervanid, sq.vanid)=attr.vanid
WHERE
    sq.datecanvassed::DATE<CURRENT_DATE
AND sq.datecanvassed::DATE>=(CURRENT_DATE-1-extract(dow FROM CURRENT_DATE+1)::int%7)
AND sq.surveyquestionid=163085--1:1s
AND sq.rn=1
GROUP BY
    1,2,3
ORDER BY
    1 DESC,
    2 ASC ;
DROP TABLE
    sroberts.myvcontacthistory;
SELECT
    CASE
        WHEN ch.datecanvassed::DATE=(CURRENT_DATE-interval '1 Day')
        THEN 'Yesterday'
        ELSE 'Week to Date'
    END                                  timeperiod ,
    COALESCE(attr.regionname,'Unturfed') turf--, coalesce(attr.foname,'Unturfed')
    ,
    CASE
        WHEN contacttypeid=1
        THEN 'Phone Bank'
        ELSE 'Canvass'
    END      eventtype ,
    COUNT(*) DVCAttempts ,
    SUM(
        CASE
            WHEN resultid=14
            THEN 1
        END) DVCContacts
INTO
    myvcontacthistory
FROM
    c2014_ar_coord_vansync.contacthistoryexport ch
LEFT JOIN
    analytics_ar.vanid_to_personid vtp
USING
    (vanid,state)
LEFT JOIN
    (
        SELECT
            personid,
            vanprecinctid AS precinctid
        FROM
            analytics_ar.person) person
USING
    (personid)
LEFT JOIN
    c2014_ar_coord_vansync.turfexport attr
USING
    (precinctid,state)-- on attr.precinctid=person.vanprecinctid and ch.state=attr.state
WHERE
    ch.datecanvassed>=(CURRENT_DATE-1-extract(dow FROM CURRENT_DATE+1)::int%7)
AND contacttypeid IN (1,2)
AND ch.committeeid=45240--Our's
GROUP BY
    1,2,3 ;
INSERT
INTO
    myvcontacthistory
SELECT
    CASE
        WHEN ch.datecanvassed::DATE=(CURRENT_DATE-interval '1 Day')
        THEN 'Yesterday'
        ELSE 'Week to Date'
    END                              timeperiod ,
    COALESCE(attr.foname,'Unturfed') turf--, coalesce(attr.foname,'Unturfed')
    ,
    CASE
        WHEN contacttypeid=1
        THEN 'Phone Bank'
        ELSE 'Canvass'
    END      eventtype ,
    COUNT(*) DVCAttempts ,
    SUM(
        CASE
            WHEN resultid=14
            THEN 1
        END) DVCContacts
FROM
    c2014_ar_coord_vansync.contacthistoryexport ch
LEFT JOIN
    analytics_ar.vanid_to_personid vtp
USING
    (vanid,state)
LEFT JOIN
    (
        SELECT
            personid,
            vanprecinctid AS precinctid
        FROM
            analytics_ar.person) person
USING
    (personid)
LEFT JOIN
    c2014_ar_coord_vansync.turfexport attr
USING
    (precinctid,state)-- on attr.precinctid=person.vanprecinctid and ch.state=attr.state
WHERE
    ch.datecanvassed>=(CURRENT_DATE-1-extract(dow FROM CURRENT_DATE+1)::int%7)
AND contacttypeid IN (1,2)
AND ch.committeeid=45240--Our's
GROUP BY
    1,2,3 ;
INSERT
INTO
    myvcontacthistory
SELECT
    CASE
        WHEN ch.datecanvassed::DATE=(CURRENT_DATE-interval '1 Day')
        THEN 'Yesterday'
        ELSE 'Week to Date'
    END         timeperiod ,
    'Statewide' turf--, coalesce(attr.foname,'Unturfed')
    ,
    CASE
        WHEN contacttypeid=1
        THEN 'Phone Bank'
        ELSE 'Canvass'
    END      eventtype ,
    COUNT(*) DVCAttempts ,
    SUM(
        CASE
            WHEN resultid=14
            THEN 1
        END) DVCContacts
FROM
    c2014_ar_coord_vansync.contacthistoryexport ch
    --left join analytics_ar.vanid_to_personid vtp using(vanid,state)
    --left join (select personid, vanprecinctid as precinctid from analytics_ar.person) person
    -- using(personid)
    --left join c2014_ar_coord_vansync.turfexport attr using(precinctid,state)-- on attr.precinctid
    -- =person.vanprecinctid and ch.state=attr.state
WHERE
    ch.datecanvassed>=(CURRENT_DATE-1-extract(dow FROM CURRENT_DATE+1)::int%7)
AND contacttypeid IN (1,2)
AND ch.committeeid=45240--Our's
GROUP BY
    1,2,3 ;
--VR
DROP TABLE
    sroberts.vr;
SELECT
    CASE
        WHEN vr.datecreated::DATE=(CURRENT_DATE-interval '1 Day')
        THEN 'Yesterday'
        ELSE 'Week to Date'
    END                             timeperiod ,
    COALESCE(vrc.region,'Unturfed') turf ,
    'Voter Reg'                     eventtype ,
    COUNT(*)                        VR
INTO
    sroberts.vr
FROM
    c2014_ar_coord_vansync.voterreg vr
LEFT JOIN
    (
        SELECT DISTINCT
            publicuserid AS createdby,
            publicusername
        FROM
            c2014_ar_coord_vansync.publicusers) pu
USING
    (createdby)
LEFT JOIN
    (
        SELECT DISTINCT
            region,
            fo,
            publicusername
        FROM
            sroberts.vrcanvasserattributer) vrc
USING
    (publicusername)
WHERE
    LEFT(vr.batchname,2)='AR'
AND vr.datecreated>=(CURRENT_DATE-1-extract(dow FROM CURRENT_DATE+1)%7)
GROUP BY
    1,2,3
ORDER BY
    2 ASC ;
INSERT
INTO
    vr
SELECT
    CASE
        WHEN vr.datecreated::DATE=(CURRENT_DATE-interval '1 Day')
        THEN 'Yesterday'
        ELSE 'Week to Date'
    END         timeperiod ,
    'Statewide' turf ,
    'Voter Reg' eventtype ,
    COUNT(*)    VR
FROM
    c2014_ar_coord_vansync.voterreg vr
LEFT JOIN
    (
        SELECT DISTINCT
            publicuserid AS createdby,
            publicusername
        FROM
            c2014_ar_coord_vansync.publicusers) pu
USING
    (createdby)
LEFT JOIN
    (
        SELECT DISTINCT
            region,
            fo,
            publicusername
        FROM
            sroberts.vrcanvasserattributer) vrc
USING
    (publicusername)
WHERE
    LEFT(vr.batchname,2)='AR'
AND vr.datecreated>=(CURRENT_DATE-1-extract(dow FROM CURRENT_DATE+1)%7)
GROUP BY
    1,2,3
ORDER BY
    2 ASC ;
--Cleanup
--insert into table something to match on, to prevent overjoin with full outer join
INSERT
INTO
    eventsummary
SELECT
    'Yesterday'       timeperiod ,
    'Unturfed'        turf ,
    'Vol Recruitment' eventtype
FROM
    eventsummary
GROUP BY
    1,2,3;
INSERT
INTO
    eventsummary
SELECT
    'Week to Date'    timeperiod ,
    'Unturfed'        turf ,
    'Vol Recruitment' eventtype
FROM
    eventsummary
GROUP BY
    1,2,3;
DROP TABLE
    DailyMorningReportBaseTable;
CREATE TABLE
    DailyMorningReportBaseTable AS
    (
        SELECT
            *
        FROM
            eventsummary
        FULL OUTER JOIN
            mycphonesummary
        USING
            (timeperiod,turf,eventtype)
        FULL OUTER JOIN
            oneonones
        USING
            (timeperiod,turf,eventtype)
        FULL OUTER JOIN
            myvcontacthistory
        USING
            (timeperiod,turf,eventtype)
        FULL OUTER JOIN
            vr
        USING
            (timeperiod,turf,eventtype)
        ORDER BY
            2 DESC,
            1
    );
