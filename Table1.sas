libname savepath "/directory";
	
*table output;	
ods rtf file="/directory/Table1.rtf";
	
*needed for superscript formats;
ods escapechar="^"; 
%LET PLUSMIN=%SYSFUNC(BYTE(177));
	
*Table 1 format;
proc format;
	value Characteristicf 
	1 = "Clinicians^{super 1}"
	2 = "Total Clinicians, No. (%)"
	3 = '^{style ^{NBSPACE 5}}Northwestern Medicine'
	4 = '^{style ^{NBSPACE 5}}AltaMed Medical Group'
	5 = "Clinician Type, No. (%)"
	6 = '^{style ^{NBSPACE 5}}Community'
	7 = '^{style ^{NBSPACE 5}}Hospital'
	8 = 'Clinician Location, No. (%)'
	9 = '^{style ^{NBSPACE 5}}Rural'
	10 = "^{style ^{NBSPACE 5}}Urban"
	11 = "License Years, ^{unicode '00B1'x}^{unicode 03C3}^{super 2}"
	12 = "Biological Sex, No. (%)"
	13 = "^{style ^{NBSPACE 5}}Male"
	14 = "^{style ^{NBSPACE 5}}Female"
	15 = "^{style ^{NBSPACE 5}}Unknown or not reported"
	16 = "Clinician Specialty, No. (%)"
  17 = '^{style ^{NBSPACE 5}}Family Medicine'
	18 = '^{style ^{NBSPACE 5}}Internal Medicine'
	19 = '^{style ^{NBSPACE 5}}Geriatric Medicine'
	20 = '^{style ^{NBSPACE 5}}Other'
  21 = "Clinician Type, No. (%)"
	22 = '^{style ^{NBSPACE 5}}Physician'
	23 = '^{style ^{NBSPACE 5}}APRN'
	24 = '^{style ^{NBSPACE 5}}Physician Assistant'
	25 = '^{style ^{NBSPACE 5}}Anesthesiologist'
	26 = '^{style ^{NBSPACE 5}}Nurse Practitioner'
  27 = "^{style ^{NBSPACE 5}}Unknown or not reported" 
  28 = "Overdose Victim Type, No. (%)"
  29 = '^{style ^{NBSPACE 5}}Nonfatal'
  30 = '^{style ^{NBSPACE 5}}Fatal'
  31 = "Number of Overdose Victims, No. (%)"
  32 = '^{style ^{NBSPACE 5}}One'
  33 = '^{style ^{NBSPACE 5}}Two'
	34 = "Patients^{super 3}"
	35 = "Total Patients, No. (%)"
	36 = '^{style ^{NBSPACE 5}}Northwestern Medicine'
	37 = '^{style ^{NBSPACE 5}}AltaMed Medical Group'
	38 = 'Race, No. (%)'
	39 = "^{style ^{NBSPACE 5}}White"
	40 = "^{style ^{NBSPACE 5}}Black"
	41 = "^{style ^{NBSPACE 5}}Asian"
	42 = "^{style ^{NBSPACE 5}}American Indian/Alaska Native"
	43 = "^{style ^{NBSPACE 5}}Native Hawaiian or Other Pacific Islander"
	44  = "^{style ^{NBSPACE 5}}More than one race"
	45 = "^{style ^{NBSPACE 5}}Unknown or not reported"
	46 = 'Ethnicity, No. (%)'
	47 = "^{style ^{NBSPACE 5}}Not Hispanic or Latino"
	48 = "^{style ^{NBSPACE 5}}Hispanic or Latino"
	49 = "^{style ^{NBSPACE 5}}Unknown or not reported"
	50 = "Biological Sex, No. (%)"
	51 = "^{style ^{NBSPACE 5}}Female"
	52 = "^{style ^{NBSPACE 5}}Male"
	53 = "Age, No. (%)"
	54 = "^{style ^{NBSPACE 5}}18-30"
	55 = "^{style ^{NBSPACE 5}}31-45"
	56 = "^{style ^{NBSPACE 5}}46-60"
	57 = "^{style ^{NBSPACE 5}}61-75"
	58 = "^{style ^{NBSPACE 5}}Above 75"
	59 = "Age^{super 4}, ^{unicode '00B1'x}^{unicode 03C3}"
	60 = "Clinician Visits^{super 5}"
	61 = "Total Visits, No. (%)"
	62 = '^{style ^{NBSPACE 5}}Northwestern Medicine'
	63 = '^{style ^{NBSPACE 5}}AltaMed Medical Group'
	64 = "Overdose Type, No. (%)"
	65 = "^{style ^{NBSPACE 5}}Nonfatal"
	66 = "^{style ^{NBSPACE 5}}Fatal"
	67 = "Opioid Prescriptions"
	68 = 'Total Visits with an Opioid Prescription, No. (%)'
	69 = "^{style ^{NBSPACE 5}}Northwestern Medicine"
	70 = "^{style ^{NBSPACE 5}}AltaMed Medical Group"
	71 = "Clinician-Weekly Opioid Prescriptions, ^{unicode '00B1'x}^{unicode 03C3}"
	72 = "^{style ^{NBSPACE 5}}Northwestern Medicine"
	73 = "^{style ^{NBSPACE 5}}AltaMed Medical Group";
run;
 
*import altamed data;
proc import datafile = "/directory/AESOPS2_ALTA_gender.xlsx"
	out = gender
	dbms = xlsx;
run;

proc import datafile = "/directory/AESOPS2_ALTA_demos.xlsx"
	out = alta_demos
	dbms = xlsx;
run;

*import NU clinician demo file;
proc import datafile = "/directory/clinician_demo.xlsx"
	out = nu_demos
	dbms = xlsx;
run;

*add gender to altamed demo file;
proc sql;
	create table alta as 
	select put(t.prov_deid,6.) as prov_id, 
	l.gendern, 
	case 
	when t.prov_type like 'Ref%' then ''
	else t.prov_type 
	end as prov_type_v2, 
	t.specialty, 
	t.hospital_community, 
	t.clinic_location, 
	t.letter, 
	0 as fatal, 
	. as years_md,
  1 as ct_od,
	'Alta' as inst 
	from alta_demos t 
	left join 
	gender l 
	on t.first_name = l.first_name;
quit;

*NU clinician characteristics;
proc sql;
	create table nu as
	select distinct t.prov_deid as prov_id,
	case 
	when sex = 'F' then 1 
	else 0 
	end as gendern,
	t.prov_type as prov_type_v2 length=32,
	t.specialty_nm as specialty, 
	t.hospital_community,
	t.clinic_location, 
	t.intervention as letter,
	case 
	when t.decedentid = '' then 0 
	else 1 
	end as 
	fatal,
	ct_od,
	2025-t.grad_year as years_md,
	'NU' as inst 
	from nu_demos t
	where t.prov_deid ne '';
quit;

*combine NU and AltaMed data;
data clinicians;
	length prov_type_v2 $ 32.;
	set alta nu;
run;

*number of clinicians (mean (SD)) per-overdose victim for 'Sample' section of results;
proc sql;
	create table od_clinicians as 
	(select distinct od_id, ct_clinician as ct_prov from nu_demos) 
	union all
	(select od_id, count(distinct prov_deid) as ct_prov 
	from savepath.analytic_9Feb26 where inst = "ALTA" group by od_id);
quit;

proc freq data = od_clinicians;
	title "Number of clinicians per overdose victim";
	table ct_prov;
run;

proc sql;
	title "Mean (SD) clinicians per overdose victim";
	select avg(ct_prov) as mean_prov, std(ct_prov) as sd_prov from od_clinicians;
quit;

%macro chck(var);
proc sql;
	select count(*) as ct, &var, letter from clinicians
	group by &var, letter order by &var, letter;
quit;
%mend chck;
%chck(gendern);
%chck(prov_type_v2);
%chck(specialty);
%chck(clinic_location);
%chck(inst);
%chck(hospital_community);

%macro chck(var);
proc sql;
	select count(*) as ct, &var, letter from savepath.pat_v2
	group by &var, letter order by &var, letter;
quit;
%mend chck;
%chck(gender_rc);
%chck(race_rc);
%chck(ethnicity_rc);
%chck(age_cat);
%chck(inst_pat);

*distinct clinician info. (3 clinicians co-occur in tx and control);
data clinician_temp;
	set clinicians;
	drop letter ct_od fatal;
run;

/*proc sql;
	create table clinician_distinct as 
	select distinct * from clinician_temp;
quit;

proc freq data = clinician_distinct;
	title "Counts % for clinician characteristics in 'Sample' section of results";
	table gendern prov_type_v2 inst specialty inst;
run;

proc sql;
	title "Mean (SD) license years in 'Sample' section of results";
	select avg(years_md) as avg_license_yrs, std(years_md) as sd_licennse_yrs from clinician_distinct;
quit;*/
	
*rename institution in analytic data and output opioid Rxs to separate file;
data opioids (rename = (inst_analytic = inst_opioids)) temp_analytic (rename=(fatal=fatalvst));
	set savepath.analytic_9Feb26;
	if inst = "ALTA" then inst_analytic = 0;
	else inst_analytic = 1;
	if opioids in (0,1) then output temp_analytic;
	if opioids = 1 then output opioids;
run;

*counts by study arm for each characteristic;
%macro counts(char, dat);
%do i = 0 %to 1;
proc sql;
	create table counts&i as
	select * from
	(select count(*) as ct, &char from &dat
	where letter = &i
	group by &char)
	%if &char = age_cat | &char = specialty | &char = race_rc %then %do;
	order by &char;
	%end;
	%else %do;
	order by ct desc;
	%end;
quit;

data counts&i;
	set counts&i;
	rn = _n_;
run;
%end;

proc sql;
	create table &char as
	select Control, Letter from
	(select 
	case 
	when lrn = . then crn
	when crn = . then lrn
	else crn 
  end as rn,
  case 
  when c = '' then '0' 
  else c 
  end as Control,
  case 
  when i = '' then '0'
  else i 
  end as Letter 
  from 
	(select t.c, l.i, l.rn as lrn, t.rn as crn from 
	(select &char, catx(' ', ct, cat('(', round(ct/sum(ct),.001)*100, ')')) as c, rn from counts0) t
	full join 
	(select &char, catx(' ', ct, cat('(', round(ct/sum(ct),.001)*100, ')')) as i, rn from counts1) l
	on t.&char = l.&char))
	%if &char = inst_analytic %then %do;
	order by rn desc;
	%end;
	%else %if &char = age_cat %then %do;
	;
	%end;
	%else %do;
	order by rn;
	%end;
quit;

%mend counts;
%counts(gendern, clinicians);
%counts(prov_type_v2, clinicians);
%counts(specialty, clinicians);
%counts(hospital_community, clinicians);
%counts(clinic_location, clinicians);
%counts(fatal, clinicians);
%counts(ct_od, clinicians);
%counts(inst, clinicians);
%counts(gender_rc, savepath.pat_v2);
%counts(race_rc, savepath.pat_v2);
%counts(ethnicity_rc, savepath.pat_v2);
%counts(age_cat, savepath.pat_v2);
%counts(inst_pat, savepath.pat_v2);
%counts(inst_analytic, temp_analytic);
%counts(inst_opioids, opioids);
%counts(fatalvst, temp_analytic);

*mean (SD) clinician-weekly opioid visits;
proc sql;
	create table opioid_vsts as 
	select prov_deid, week, letter, inst, sum(opioids) as mean_opioid_vsts from temp_analytic
	group by prov_deid, week, letter, inst
	order by prov_deid, week;
quit;

%macro meanyrs(var, dat);
	%do i = 0 %to 1;
	*mean years;
 	proc sql;
  create table years&i as
  select catx(' ', mean_years, cat( '(', sd_years, ')')) as v&i from
	(select round(avg(&var),.1) as mean_years, round(std(&var),.1) as sd_years from &dat
	where letter = &i);
	quit;
	%end;

	proc sql;
	create table &var as 
	select t.v0 as Control, l.v1 as Letter from years0 t, years1 l;
	quit;
%mend meanyrs;
%meanyrs(years_md, clinicians);
%meanyrs(age_cont, savepath.pat_v2);
%meanyrs(mean_opioid_vsts, opioid_vsts);

*mean clinician-weekly opioid Rxs by institution;
%macro meanvsts;
	%do i = 0 %to 1;
proc sql;
	create table meanvsts&i as
	select * from
	(select round(avg(mean_opioid_vsts),.01) as mean, round(std(mean_opioid_vsts),.01) as sd, inst from opioid_vsts
	where letter = &i
	group by inst)
	order by mean desc;
quit;

data meanvsts&i;
	set meanvsts&i;
	rn = _n_;
run;
%end;
%mend meanvsts;
%meanvsts;

proc sql;
	create table meanvstsinst as
	select catx(' ', t.mean, cat('(', t.sd, ')')) as Control, catx(' ', l.mean, cat('(', l.sd, ')')) as Letter from
	meanvsts0 t
	join 
  meanvsts1 l
	on t.rn = l.rn
	order by t.rn;
quit;

*title rows;
%macro title(char, val);
proc sql;
		create table &char.title 
		(Control char(32),
		Letter char(32));
		
		insert into &char.title
		values(' ', ' ');
quit;
%mend title;
%title(clinician);
%title(clinic_type);
%title(hospital_community);
%title(location);
%title(gender);
%title(specialty);
%title(type);
%title(fatal);
%title(ct_od);
%title(pat);
%title(race);
%title(ethnicity);
%title(age);
%title(encounters);
%title(fatalvst)
%title(opioid);

%macro totals(dat, datout);
*sample totals by study arm;
proc sql;
	create table total_no as 
	select count(*) as ct, letter from &dat
	group by letter;
quit;

*transpose data;
proc transpose data = total_no out = total_not (where = (_NAME_ ne 'letter'));
run;

proc sql;
	create table &datout as 
	select catx(' ', COL1, cat('(', round(COL1/(COL1+COL2),.01)*100, ')')) as Control, 
	catx(' ', COL2, cat('(', round(COL2/(COL1+COL2),.01)*100, ')')) as Letter from total_not;
quit;
%mend totals;
%totals(clinicians, clinician_ct);
%totals(savepath.pat_v2, pat_ct);
%totals(temp_analytic, vst_ct);
%totals(opioids, opioid_ct);

*append and add format;
data total;
	retain Characteristic Control Letter;
	set 
	cliniciantitle
	clinician_ct
	inst 
	hospital_communitytitle hospital_community
	locationtitle clinic_location
	years_md
	gendertitle gendern 
	specialtytitle specialty 
	typetitle prov_type_v2
	fataltitle fatal
	ct_odtitle ct_od
	pattitle
	pat_ct
	inst_pat
	racetitle race_rc
	ethnicitytitle ethnicity_rc
	gendertitle gender_rc
  agetitle age_cat age_cont
  encounterstitle vst_ct
  inst_analytic
  fatalvsttitle fatalvst
  opioidtitle
  opioid_ct
  inst_opioids
  mean_opioid_vsts meanvstsinst;
	Characteristic = _n_;
	format Characteristic Characteristicf.;
run;

proc report data = total nowd
	 style(report)=[rules=none frame=hsides cellspacing=1 cellpadding=1 borderbottomcolor=white] 
	 style(header) = [background=white borderbottomwidth=2.25pt borderbottomcolor = black bordertopcolor = white];
	 define characteristic / left;
	 define control / center style(column)={cellwidth=1.25in};
	 define letter / center style(column)={cellwidth=1.25in};
	 compute after / style={just=l};
 	 line "Abbreviations: APRN, Advanced Practice Registered Nurse.";
	 line "^{super 1}Three clinicians with two overdose victims co-occur in control and letter group.";
	 line "^{super 2}Data missing for 31 clinicians.";
	 line "^{super 3}Patients who received at least one opioid prescription from a participating clinician during the study period.";
	 line "^{super 4}Northwestern Medicine patient age 89 plus was capped at 89.";
   line "^{super 5}Visits and opioid prescriptions during the study period among clinicians in analytic sample (n = 60).";
   endcomp;
run;
ods rtf close;








