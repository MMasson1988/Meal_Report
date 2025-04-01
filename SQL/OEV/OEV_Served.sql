USE caris_db;
SET @start_date = '2024-07-01';
SET @end_date = '2024-09-30';
SET @start_date_last = '2024-04-01';
SET @end_date_last = '2024-08-30';

SELECT
patient.id as id_patient,
patient_code,
coalesce(ti.dob,tme.infant_dob,spy.date_of_birth) as dob,
coalesce(ti.gender,tme.infant_gender) as gender,
IF(arv.id_patient IS NOT NULL,
   'yes',
   'no') AS on_arv,
IF(statut.id_patient IS NOT NULL,
   'pos',
   'neg') AS statut,
IF(followup_q1 IS NOT NULL
   OR odk_q1 IS NOT NULL
   OR arv_q1 IS NOT NULL
   OR ques_q1 IS NOT NULL
   OR club_q1 IS NOT NULL
   OR mereenfant_q1 is not null
   OR specimen_q1 is not null
   OR rapid.rapid_q1 is not null
   OR opf_q1.id_patient is not null,
   'yes',
   'no') AS q1,
IF(followup_q1 IS NOT NULL, 'yes', 'no') AS followup_q1,
IF(odk_q1 IS NOT NULL, 'yes', 'no') AS odk_q1,
IF(arv_q1 IS NOT NULL, 'yes', 'no') AS arv_q1,
IF(ques_q1 IS NOT NULL, 'yes', 'no') AS ques_q1,
IF(club_q1 IS NOT NULL, 'yes', 'no') AS club_q1,
if(mereenfant_q1 is not null, 'yes','no') as mereenfant_q1,
if(specimen_q1 is not null, 'yes','no') as specimen_q1,
if(rapid.rapid_q1 is not null, 'yes','no') as rapid_q1,
IF(followup_q2 IS NOT NULL
   OR odk_q2 IS NOT NULL
   OR arv_q2 IS NOT NULL
   OR ques_q2 IS NOT NULL
   OR club_q2 IS NOT NULL
   or mereenfant_q2 is not null
   or specimen_q2 is not null
   OR rapid2.rapid_q2 is not null
   OR opf_q2.id_patient is not null,
   'yes',
   'no') AS q2,
IF(followup_q2 IS NOT NULL, 'yes', 'no') AS followup_q2,
IF(odk_q2 IS NOT NULL, 'yes', 'no') AS odk_q2,
IF(arv_q2 IS NOT NULL, 'yes', 'no') AS arv_q2,
IF(ques_q2 IS NOT NULL, 'yes', 'no') AS ques_q2,
IF(club_q2 IS NOT NULL, 'yes', 'no') AS club_q2,
if(mereenfant_q2 is not null, 'yes','no') as mereenfant_q2,
if(specimen_q2 is not null, 'yes','no') as specimen_q2,
if(rapid2.rapid_q2 is not null, 'yes','no') as rapid_q2,
if(opf_q1.id_patient is not null,'yes','no') as odk_phone_followup_q1,
if(opf_q2.id_patient is not null,'yes','no') as odk_phone_followup_q2,
patient.created_at,
lookup_hospital.name as hospital_name,
office,
IF(hn.id,'yes','no') as is_ugp,
if(ti.is_abandoned=1, 'yes', 'No') as Abandoned,
if(ti.is_dead=1, 'yes', 'No') as Dead

FROM
(SELECT
  *
    FROM
  (SELECT
    id_patient
    FROM
    tracking_followup
    WHERE
    date BETWEEN @start_date_last AND @end_date UNION
    
    ##### ADDING positive_pcr_1 or positive_pcr_2 START
    SELECT
    id_patient
    FROM
    tracking_infant
    WHERE
    (positive_pcr_1 BETWEEN @start_date_last AND @end_date
      OR positive_pcr_2 BETWEEN @start_date_last AND @end_date)
    
    ##### ADDING positive_pcr_1 or positive_pcr_2 END
    
    ### ADDING ODK PHONE FOLLOWUP START
    UNION (
      select pt.id as id_patient from tracking_odk_phone_followup topf 
      left join patient pt on topf.patient_code = pt.patient_code
      where (topf.eccm_date between @start_date_last AND @end_date)  and topf.name='Enquette Corona Enfant' and topf.eccm_joignable_par_tel!=0
    )
    UNION
    ### ADDING ODK PHONE FOLLOWUP END
    
    (SELECT DISTINCT
      patient.id AS id_patient
      FROM
      caris_db.odk_child_visit
      LEFT JOIN patient ON patient.patient_code = odk_child_visit.patient_code
      WHERE
      date_of_visit BETWEEN @start_date_last AND @end_date
      AND patient.id IS NOT NULL
      AND is_available_at_time_visit = 1
      AND linked_to_id_patient = 0) UNION SELECT
    id_patient
    FROM
    tracking_regime
    WHERE
    (start_date BETWEEN @start_date_last AND @end_date or end_date BETWEEN @start_date_last AND @end_date)
    AND category = 'regime_infant_treatment' UNION SELECT
    id_patient
    FROM
    questionnaire_child
    WHERE
    date BETWEEN @start_date_last AND @end_date UNION SELECT
    id_patient
    FROM
    testing_mereenfant
    WHERE
    date BETWEEN @start_date_last AND @end_date UNION SELECT
    id_patient
    FROM
    testing_specimen
    WHERE
    date_blood_taken BETWEEN @start_date_last AND @end_date  UNION SELECT
    id_patient
    FROM
    questionnaire_proftraining18
    WHERE
    date BETWEEN @start_date_last AND @end_date UNION ((SELECT
                                                        id_patient
                                                        FROM
                                                        session
                                                        LEFT JOIN club_session ON club_session.id = id_club_session
                                                        LEFT JOIN club ON club_session.id_club = club.id
                                                        WHERE
                                                        is_present = 1
                                                        AND (date BETWEEN @start_date AND @end_date
                                                             OR date BETWEEN @start_date_last AND @end_date_last)
                                                        AND club_type != 1))) o) bot
LEFT JOIN
(SELECT DISTINCT
  id_patient AS followup_q1
  FROM
  tracking_followup
  WHERE
  date BETWEEN @start_date_last AND @end_date_last) x ON followup_q1 = bot.id_patient
left join
(select distinct id_patient as specimen_q1 from testing_specimen WHERE
  date_blood_taken BETWEEN @start_date_last AND @end_date_last) x2 ON specimen_q1 = bot.id_patient
left join
(select distinct id_patient as specimen_q2 from testing_specimen WHERE
  date_blood_taken BETWEEN @start_date AND @end_date) x3 ON specimen_q2 = bot.id_patient
LEFT JOIN
(SELECT DISTINCT
  id_patient AS followup_q2
  FROM
  tracking_followup
  WHERE
  date BETWEEN @start_date AND @end_date) y ON followup_q2 = bot.id_patient
LEFT JOIN
patient ON patient.id = bot.id_patient
LEFT JOIN
(SELECT DISTINCT
  id_patient AS mereenfant_q1
  FROM
  testing_mereenfant
  WHERE
  date BETWEEN @start_date_last AND @end_date_last) me ON mereenfant_q1 = bot.id_patient
LEFT JOIN
(SELECT DISTINCT
  id_patient AS mereenfant_q2
  FROM
  testing_mereenfant
  WHERE
  date BETWEEN @start_date AND @end_date) me2 ON mereenfant_q2 = bot.id_patient
LEFT JOIN
(SELECT DISTINCT
  patient.id AS odk_q1
  FROM
  caris_db.odk_child_visit
  LEFT JOIN patient ON patient.patient_code = odk_child_visit.patient_code
  WHERE
  date_of_visit BETWEEN @start_date_last AND @end_date_last
  AND patient.id IS NOT NULL
  AND is_available_at_time_visit = 1
  AND linked_to_id_patient = 0) z ON odk_q1 = bot.id_patient
LEFT JOIN
(SELECT DISTINCT
  patient.id AS odk_q2
  FROM
  caris_db.odk_child_visit
  LEFT JOIN patient ON patient.patient_code = odk_child_visit.patient_code
  WHERE
  date_of_visit BETWEEN @start_date AND @end_date
  AND patient.id IS NOT NULL
  AND is_available_at_time_visit = 1
  AND linked_to_id_patient = 0) zz ON odk_q2 = bot.id_patient
LEFT JOIN
(SELECT DISTINCT
  id_patient AS arv_q2
  FROM
  tracking_regime
  WHERE
  start_date BETWEEN @start_date AND @end_date or end_date BETWEEN @start_date AND @end_date) a2 ON arv_q2 = bot.id_patient
LEFT JOIN
(SELECT DISTINCT
  id_patient AS arv_q1
  FROM
  tracking_regime
  WHERE
  start_date BETWEEN @start_date_last AND @end_date_last or end_date BETWEEN @start_date_last AND @end_date_last) a1 ON arv_q1 = bot.id_patient
LEFT JOIN
(SELECT
  id_patient AS ques_q1
  FROM
  questionnaire_child
  WHERE
  date BETWEEN @start_date_last AND @end_date_last UNION SELECT
  id_patient AS ques_q1
  FROM
  questionnaire_proftraining18
  WHERE
  date BETWEEN @start_date_last AND @end_date_last) q1 ON ques_q1 = bot.id_patient
LEFT JOIN
(SELECT
  id_patient AS ques_q2
  FROM
  questionnaire_child
  WHERE
  date BETWEEN @start_date AND @end_date UNION SELECT
  id_patient AS ques_q2
  FROM
  questionnaire_proftraining18
  WHERE
  date BETWEEN @start_date AND @end_date) q2 ON ques_q2 = bot.id_patient
LEFT JOIN
(SELECT DISTINCT
  id_patient AS club_q1
  FROM
  session
  LEFT JOIN club_session ON club_session.id = id_club_session
  LEFT JOIN club ON club_session.id_club = club.id
  WHERE
  is_present = 1
  AND date BETWEEN @start_date_last AND @end_date_last
  AND club_type != 1) c1 ON club_q1 = bot.id_patient
LEFT JOIN
(SELECT DISTINCT
  id_patient AS club_q2
  FROM
  session
  LEFT JOIN club_session ON club_session.id = id_club_session
  LEFT JOIN club ON club_session.id_club = club.id
  WHERE
  is_present = 1
  AND date BETWEEN @start_date AND @end_date
  AND club_type != 1) c2 ON club_q2 = bot.id_patient
LEFT JOIN
lookup_hospital ON CONCAT(lookup_hospital.city_code,
                          '/',
                          lookup_hospital.hospital_code) = LEFT(patient_code, 8)
LEFT JOIN
(SELECT DISTINCT
  id_patient
  FROM
  tracking_regime
  WHERE
  category = 'regime_infant_treatment') arv ON arv.id_patient = bot.id_patient
##### ADDING positive_pcr_1 or positive_pcr_2 START
LEFT JOIN (SELECT
           id_patient as rapid_q1
           FROM
           tracking_infant
           WHERE
           (positive_pcr_1 BETWEEN @start_date_last AND @end_date_last
             OR positive_pcr_2 BETWEEN @start_date_last AND @end_date_last)) rapid on rapid.rapid_q1=bot.id_patient

##### ADDING positive_pcr_1 or positive_pcr_2 END

##### ADDING positive_pcr_1 or positive_pcr_2 START
LEFT JOIN (SELECT
           id_patient as rapid_q2
           FROM
           tracking_infant
           WHERE
           (positive_pcr_1 BETWEEN @start_date AND @end_date
             OR positive_pcr_2 BETWEEN @start_date AND @end_date)) rapid2 on rapid2.rapid_q2=bot.id_patient

##### ADDING positive_pcr_1 or positive_pcr_2 END

### ODK PHONE FOLLOWUP START

LEFT JOIN (
  select case_id,eccm_date, pt3.id as id_patient from tracking_odk_phone_followup topf
  left join patient pt3 on  pt3.patient_code = topf.patient_code
  where topf.eccm_joignable_par_tel!=0 and topf.eccm_date BETWEEN @start_date_last AND @end_date_last group by topf.case_id
) opf_q1 on opf_q1.id_patient= bot.id_patient
LEFT JOIN (
  select case_id,eccm_date, pt4.id as id_patient from tracking_odk_phone_followup topf
  left join caris_db.odk_hivhaiti_backward_compatibility obc on obc.odk_case_id=topf.case_id
  left join patient pt4 on pt4.patient_code = topf.patient_code
  where topf.eccm_joignable_par_tel!=0 and topf.eccm_date BETWEEN @start_date AND @end_date group by topf.case_id
) opf_q2 on opf_q2.id_patient= bot.id_patient
### ODK PHONE FOLLOWUP END
LEFT JOIN
(SELECT
  id_patient
  FROM
  tracking_followup UNION SELECT
  id_patient
  FROM
  tracking_regime
  WHERE
  category = 'regime_infant_treatment' UNION SELECT
  id_patient
  FROM
  club_patient UNION SELECT
  id_patient
  FROM
  questionnaire_child UNION SELECT
  id_patient
  FROM
  questionnaire_proftraining18 UNION SELECT
  id_patient
  FROM
  testing_specimen
  WHERE
  pcr_result = 1 UNION SELECT
  id_patient
  FROM
  testing_result
  WHERE
  result = 1 UNION SELECT
  id_patient
  FROM
  tracking_infant
  WHERE
  positive_pcr_1 != '0000-00-00'
  OR positive_pcr_2 != '0000-00-00') statut ON statut.id_patient = bot.id_patient

left join tracking_infant ti on ti.id_patient=bot.id_patient
left join testing_mereenfant tme on tme.id_patient=bot.id_patient
left join (select max(spx.date_of_birth) as date_of_birth, spx.id_patient from testing_specimen spx group by spx.id_patient) spy on spy.id_patient=bot.id_patient
left join hospital_network hn on (hn.id_hospital=lookup_hospital.id and id_network=7)

WHERE
linked_to_id_patient = 0"
     ))

  
  #Fetching the data
  serv_oev = fetch(service_oev,n=-1)


```

```{r}
#View(serv_oev)
```

```{r ptme serv}

#Importing the ovc_serv dataset

start_date <- as.character(prev)
end_date <- as.character(after)
start_date_last <- as.character(prev)
end_date_last <- as.character(after)

serv_ptme = dbSendQuery(
    dbConnect(MySQL(), user='caris_readonly', password='longlivecaris!!', dbname='caris_db', host='caris.cwyvkxmtzny2.us-east-1.rds.amazonaws.com'),
          
          gsubfn::fn$identity("SELECT bot.patient_code,
    IF(p.id is null,'no','yes') as is_patient_on_hivhaiti,
    IF(club_q1 IS NOT NULL,
        'yes',
        IF(quest_q1 IS NOT NULL,
            'yes',
            IF(arv_1 IS NOT NULL,
                'yes',
                IF(odk_1 IS NOT NULL,
                    'yes',
                    IF(ptme_1 IS NOT NULL,
                        'yes',
                        IF(ptme1_1 IS NOT NULL,
                            'yes',
                            IF(mereenfant_1 IS NOT NULL,
                                'yes',
                                IF(opf_q1.case_id IS NOT NULL ,'yes',
                                IF(tmf_q1.patient_code IS NOT NULL,'yes',
                                IF(tpv_q1.patient_code IS NOT NULL,'yes',
                                IF(oto1.patient_code IS NOT NULL,'yes',
                                'no'))))))))))) AS q1,
    IF(club_q2 IS NOT NULL,
        'yes',
        IF(quest_q2 IS NOT NULL,
            'yes',
            IF(arv_2 IS NOT NULL,
                'yes',
                IF(odk_2 IS NOT NULL,
                    'yes',
                    IF(ptme_2 IS NOT NULL,
                        'yes',
                        IF(ptme1_2 IS NOT NULL,
                            'yes',
                            IF(mereenfant_2 IS NOT NULL,
                                'yes',
                                IF(opf_q2.case_id IS NOT NULL ,
                                'yes',
                                IF(tmf_q2.patient_code IS NOT NULL, 'yes',
                                IF(oto2.patient_code IS NOT NULL, 'yes',
                                IF(tpv_q2.patient_code IS NOT NULL,'yes','no'))))))))))) AS q2,
    IF(club_q1 IS NOT NULL, 'yes', 'no') AS club_q1,
    IF(club_q2 IS NOT NULL, 'yes', 'no') AS club_q2,
    IF(quest_q1 IS NOT NULL, 'yes', 'no') AS quest_q1,
    IF(quest_q2 IS NOT NULL, 'yes', 'no') AS quest_q2,
    IF(arv_1 IS NOT NULL, 'yes', 'no') AS on_arv_q1,
    IF(arv_2 IS NOT NULL, 'yes', 'no') AS on_arv_q2,
    IF(odk_1 IS NOT NULL, 'yes', 'no') AS odk_q1,
    IF(odk_2 IS NOT NULL, 'yes', 'no') AS odk_q2,
    IF(tmf_q1.patient_code IS NOT NULL, 'yes','no')  as followup_q1,
    IF(tmf_q2.patient_code IS NOT NULL, 'yes','no')  as followup_q2,
    IF(tpv_q1.patient_code IS NOT NULL,'yes','no') as visit_ptme_q1,
    IF(tpv_q2.patient_code IS NOT NULL,'yes','no') as visit_ptme_q2,
    IF(oto1.patient_code IS NOT NULL,'yes','no') as visit_ptme_ratio_q1,
    IF(oto2.patient_code IS NOT NULL,'yes','no') as visit_ptme_ratio_q2,

    IF(opf_q1.case_id IS NOT NULL ,'yes','no') AS odk_phone_followup_q1,
    IF(opf_q2.case_id IS NOT NULL ,'yes','no') AS odk_phone_followup_q2,
    if(tmf_q1.patient_code IS NOT NULL,'yes','no') as mother_followup_q1,
    if(tmf_q2.patient_code IS NOT NULL,'yes','no') as mother_followup_q2,
    IF(COALESCE(ptme_1, ptme1_1) IS NOT NULL,
        'yes',
        'no') AS ptme_q1,
    IF(COALESCE(ptme_2, ptme1_2) IS NOT NULL,
        'yes',
        'no') AS ptme_q2,
    IF(mereenfant_1 IS NOT NULL,
        'yes',
        'no') AS mereenfant_q1,
    IF(mereenfant_2 IS NOT NULL,
        'yes',
        'no') AS mereenfant_2,
    office,
    p.created_at as patient_created_date,
    IF(p.created_at BETWEEN @start_date AND @end_date , 'yes','no') as is_patient_created_on_q2,
    IF(tr.id_patient is not null , 'yes','no') as on_arv,
    tmi.dob,
    tmi.is_dead
FROM
    (SELECT
        *
    FROM
        (SELECT
        patient_code
    FROM
        tracking_motherbasicinfo
    LEFT JOIN patient ON patient.id = tracking_motherbasicinfo.id_patient) o UNION (SELECT
        health_id AS patient_code
    FROM
        openfn.odk_pregnancy_visit
    WHERE
        date_of_visit BETWEEN @start_date_last AND @end_date) 
        ## ODK PHONE FOLLOWUP START
        UNION (
        select topf.patient_code as patient_code from tracking_odk_phone_followup topf 
			where topf.eccm_joignable_par_tel!=0 and (topf.eccm_date between @start_date_last AND @end_date) and topf.name='Enquette Corona club meres'
        )
        ## ODK PHONE FOLLOWUP END

        UNION (

          select tpv.patient_code from tracking_ptme_visit tpv where tpv.date_of_visit between @start_date_last AND @end_date
        
        )
        ## ODK Ratio Visits
        UNION (
           select opt.patient_code from odk_tracking_other_visit_ptme opt where opt.date_of_visit between @start_date_last AND @end_date 
        )
        ) bot
        LEFT JOIN
    (SELECT DISTINCT
        patient_code AS club_q2
    FROM
        session
    LEFT JOIN club_session ON club_session.id = session.id_club_session
    LEFT JOIN patient ON patient.id = session.id_patient
    WHERE
        is_present = 1
            AND club_session.date BETWEEN @start_date AND @end_date) c2 ON club_q2 = bot.patient_code
        LEFT JOIN
    patient ON patient.patient_code = bot.patient_code
        LEFT JOIN
    (SELECT DISTINCT
        patient_code AS club_q1
    FROM
        session
    LEFT JOIN club_session ON club_session.id = session.id_club_session
    LEFT JOIN patient ON patient.id = session.id_patient
    WHERE
        is_present = 1
            AND club_session.date BETWEEN @start_date_last AND @end_date_last) c1 ON club_q1 = bot.patient_code
        LEFT JOIN
    (SELECT
        patient_code AS quest_q1, date
    FROM
        (SELECT
        id_patient, date
    FROM
        questionnaire_motherhivknowledge UNION SELECT
        id_patient, date
    FROM
        questionnaire_mothersurvey UNION SELECT
        id_patient, date
    FROM
        questionnaire_newmotherhivknowledge) x
    LEFT JOIN patient ON patient.id = x.id_patient
    WHERE
        date BETWEEN @start_date_last AND @end_date_last) quest ON quest_q1 = bot.patient_code
        LEFT JOIN
    (SELECT
        patient_code AS quest_q2
    FROM
        (SELECT
        id_patient
    FROM
        questionnaire_motherhivknowledge
    WHERE
        date BETWEEN @start_date AND @end_date UNION SELECT
        id_patient
    FROM
        questionnaire_mothersurvey
    WHERE
        date BETWEEN @start_date AND @end_date UNION SELECT
        id_patient
    FROM
        questionnaire_newmotherhivknowledge
    WHERE
        date BETWEEN @start_date AND @end_date) y
    LEFT JOIN patient ON patient.id = y.id_patient) ques ON quest_q2 = bot.patient_code
        LEFT JOIN
    lookup_hospital ON CONCAT(lookup_hospital.city_code,
            '/',
            lookup_hospital.hospital_code) = LEFT(patient.patient_code, 8)
        LEFT JOIN
    (SELECT DISTINCT
        patient_code AS arv_1
    FROM
        tracking_regime
    LEFT JOIN patient ON patient.id = id_patient
    WHERE
        (start_date BETWEEN @start_date_last AND @end_date_last
            OR end_date BETWEEN @start_date_last AND @end_date_last)
            AND category = 'regime_mother_treatment') ar ON arv_1 = bot.patient_code
        LEFT JOIN
    (SELECT DISTINCT
        patient_code AS arv_2
    FROM
        tracking_regime
    LEFT JOIN patient ON patient.id = id_patient
    WHERE
        (start_date BETWEEN @start_date AND @end_date
            OR end_date BETWEEN @start_date AND @end_date)
            AND category = 'regime_mother_treatment') arv ON arv_2 = bot.patient_code
        LEFT JOIN
    (SELECT DISTINCT
        health_id AS odk_1
    FROM
        openfn.odk_pregnancy_visit
    WHERE
        date_of_visit BETWEEN @start_date_last AND @end_date_last) odk1 ON odk_1 = bot.patient_code
        LEFT JOIN
    (SELECT DISTINCT
        health_id AS odk_2
    FROM
        openfn.odk_pregnancy_visit
    WHERE
        date_of_visit BETWEEN @start_date AND @end_date) odk2 ON odk_2 = bot.patient_code
        LEFT JOIN
    (SELECT DISTINCT
        patient_code AS ptme_1
    FROM
        tracking_pregnancy
    LEFT JOIN patient ON patient.id = id_patient_mother
    WHERE
        (ptme_enrollment_date BETWEEN @start_date_last AND @end_date_last)
            OR (actual_delivery_date BETWEEN @start_date_last AND @end_date_last)) ptme1 ON ptme_1 = bot.patient_code
        LEFT JOIN
    (SELECT DISTINCT
        patient_code AS ptme_2
    FROM
        tracking_pregnancy
    LEFT JOIN patient ON patient.id = id_patient_mother
    WHERE
        (ptme_enrollment_date BETWEEN @start_date AND @end_date)
            OR (actual_delivery_date BETWEEN @start_date AND @end_date)) ptme2 ON ptme_2 = bot.patient_code
        LEFT JOIN
    (SELECT DISTINCT
        patient_code AS ptme1_1
    FROM
        tracking_motherbasicinfo
    LEFT JOIN patient ON patient.id = id_patient
    WHERE
        PTME_date BETWEEN @start_date_last AND @end_date_last) pt1 ON ptme1_1 = bot.patient_code
        LEFT JOIN
    (SELECT DISTINCT
        patient_code AS ptme1_2
    FROM
        tracking_motherbasicinfo
    LEFT JOIN patient ON patient.id = id_patient
    WHERE
        PTME_date BETWEEN @start_date AND @end_date) pt2 ON ptme1_2 = bot.patient_code
        LEFT JOIN
    (SELECT
        patient.patient_code AS mereenfant_1
    FROM
        tracking_motherbasicinfo
    LEFT JOIN patient ON patient.id = tracking_motherbasicinfo.id_patient
    LEFT JOIN testing_mereenfant ON CONCAT(testing_mereenfant.mother_city_code, '/', testing_mereenfant.mother_hospital_code, '/', testing_mereenfant.mother_code) = patient_code
    WHERE
        date BETWEEN @start_date_last AND @end_date_last
            AND patient_code IS NOT NULL
    GROUP BY patient_code) me1 ON mereenfant_1 = bot.patient_code
        LEFT JOIN
    (SELECT
        patient.patient_code AS mereenfant_2
    FROM
        tracking_motherbasicinfo
    LEFT JOIN patient ON patient.id = tracking_motherbasicinfo.id_patient
    LEFT JOIN testing_mereenfant ON CONCAT(testing_mereenfant.mother_city_code, '/', testing_mereenfant.mother_hospital_code, '/', testing_mereenfant.mother_code) = patient_code
    WHERE
        date BETWEEN @start_date AND @end_date
            AND patient_code IS NOT NULL
    GROUP BY patient_code) me2 ON mereenfant_2 = bot.patient_code
    left join patient p on p.patient_code=bot.patient_code
    ## ODK FOLLOWUP PHONE END
	LEFT JOIN (
    select case_id,eccm_date, topf.patient_code from tracking_odk_phone_followup topf
    where topf.eccm_joignable_par_tel!=0 and topf.eccm_date BETWEEN @start_date_last AND @end_date_last group by topf.case_id
    ) opf_q1 on opf_q1.patient_code= bot.patient_code
	LEFT JOIN (
    select case_id,eccm_date, topf.patient_code from tracking_odk_phone_followup topf
    where topf.eccm_joignable_par_tel!=0 and topf.eccm_date BETWEEN @start_date AND @end_date group by topf.case_id
    ) opf_q2 on opf_q2.patient_code= bot.patient_code
    
	## MOTHER FOLLOWUP  START
	LEFT JOIN (
    select tmf.date, p.patient_code from tracking_motherfollowup tmf
    left join patient p on p.id=tmf.id_patient
    where  tmf.date BETWEEN @start_date_last AND @end_date_last group by tmf.id_patient
    ) tmf_q1 on tmf_q1.patient_code= bot.patient_code
	LEFT JOIN (
    select tmf.date, p.patient_code from tracking_motherfollowup tmf
    left join patient p on p.id=tmf.id_patient
    where  tmf.date BETWEEN @start_date AND @end_date group by tmf.id_patient
    ) tmf_q2 on tmf_q2.patient_code= bot.patient_code
    
    ##  MOTHER FOLLOWUP END

	## MOTHER Agent visit ptme  START
	LEFT JOIN (
    select tpv.date_of_visit, tpv.patient_code from tracking_ptme_visit tpv
    where  tpv.date_of_visit BETWEEN @start_date_last AND @end_date_last group by tpv.patient_code
    ) tpv_q1 on tpv_q1.patient_code= bot.patient_code
	LEFT JOIN (
    select tpv.date_of_visit, tpv.patient_code from tracking_ptme_visit tpv
    where  tpv.date_of_visit BETWEEN @start_date AND @end_date group by tpv.patient_code
    ) tpv_q2 on tpv_q2.patient_code= bot.patient_code
    
    ##  MOTHER Agent visit ptme END
    
    ## MOTHER ratio start
    
    LEFT JOIN (
    select oto11.date_of_visit, oto11.patient_code from odk_tracking_other_visit_ptme oto11 
    where oto11.date_of_visit BETWEEN @start_date_last AND @end_date_last group by oto11.patient_code
    ) oto1 on oto1.patient_code= bot.patient_code
	LEFT JOIN (
    select oto21.date_of_visit, oto21.patient_code from odk_tracking_other_visit_ptme oto21 
    where oto21.date_of_visit BETWEEN @start_date AND @end_date group by oto21.patient_code
    ) oto2 on oto2.patient_code= bot.patient_code
    
    ## MOTHER ratio end
    left join tracking_motherbasicinfo tmi on tmi.id_patient=p.id
    left join (select distinct id_patient from tracking_regime where category='regime_mother_treatment' and (id_arv is not null) and id_arv!=0  ) tr  on tr.id_patient=p.id
WHERE
    (p.linked_to_id_patient = 0 or p.linked_to_id_patient is null)
        AND (club_q1 IS NOT NULL
        OR club_q2 IS NOT NULL
        OR quest_q1 IS NOT NULL
        OR quest_q2 IS NOT NULL
        OR arv_1 IS NOT NULL
        OR arv_2 IS NOT NULL
        OR odk_1 IS NOT NULL
        OR odk_2 IS NOT NULL
        OR ptme_1 IS NOT NULL
        OR ptme_2 IS NOT NULL
        OR ptme1_1 IS NOT NULL
        OR ptme1_2 IS NOT NULL
        OR mereenfant_1 IS NOT NULL
        OR mereenfant_2 IS NOT NULL
        OR opf_q1.case_id IS NOT NULL
        OR opf_q2.case_id IS NOT NUlL
        OR tmf_q1.patient_code IS NOT NULL
        OR tmf_q2.patient_code IS NOT NULL
        OR tpv_q1.patient_code IS NOT NULL 
        OR tpv_q2.patient_code IS NOT NULL
        OR oto1.patient_code IS NOT NULL
        OR oto2.patient_code IS NOT NULL
        
        )
GROUP BY bot.patient_code"))
    
ptme_serv = fetch(serv_ptme,n=-1)  