libname savepath "/directory";

*2330 unique patients in NU sample, 2409 in Table 1 (saw Tx and control clinician);
*287 unique patients in AltaMed sample, 288 in Table 1 (1 patient saw Tx and control clinician);
*import NU patient data;
proc import datafile = "/directory/Alta_table1_patients_9Feb26.xlsx"
	out = alta
	replace
	dbms = xlsx;
run;

*edit variable lengths in Alta file;
data alta; 
	length ethnicity $ 48. race $ 71.;
	informat ethnicity $ 48. race $ 71.;
	set alta;
	format ethnicity $ 48. race $ 71.;
run;

*append NU and AltaMed patient data;
data pat_temp;
	length age_cat $ 32.;
	set savepath.pat_demos alta;
	if inst = "ALTA" then inst_pat = 0;
	else inst_pat = 1;
	*ethnicity;
	ethnicity = lowcase(ethnicity);
	*convert variables to lowercase;
	race = lowcase(race);
	/*age categorical*/
	if 18 <= age_cont <= 30 then age_cat = 0;
	else if 31 <= age_cont <= 45 then age_cat = 1;
	else if 46 <= age_cont <= 60 then age_cat = 2;
	else if 61 <= age_cont <= 75 then age_cat = 3;
	else age_cat = 4;
run;

*check age;
proc sql;
	select count(distinct patient_id) as ct, min(age_cont) as min_age, max(age_cont) as max_age, age_cat from pat_temp
	group by age_cat;
quit;
	
*confirm patient counts by institution;
proc sql;
	title "Table 1 patient counts by institution";
	select inst, count(*) as ct_pat, count(distinct patient_id) as ct_distinct_pat
	from pat_temp
	group by inst
	order by inst;
quit;

*confirm patient counts by institution and study arm;
proc sql;
	title "Table 1 patient counts by institution";
	select inst_pat, letter, count(*) as ct_pat, count(distinct patient_id) as ct_distinct_pat
	from pat_temp
	group by inst_pat, letter
	order by inst_pat, letter;
quit;

*recode;
proc sql;
	create table savepath.pat_v2 as 
	select *, 
	
	/*ethnicity*/
	case 
	when ethnicity like ('%cuban%') or ethnicity like ('%hispanic or latino%') or ethnicity like ('%mexican%')
	or ethnicity like ('%puerto%') or ethnicity like ('%other%') or ethnicity like ('%yes%') then 'h'
	when ethnicity like ('%decline%') or ethnicity like ('%null%') or ethnicity like ('%to respond%') or ethnicity 
	like ('%unknown%') then 'uk'
	else 'nh'
  end as ethnicity_rc, 
  
  /*race*/
  case 
  
  /*mixed*/
  when race like ('%2%') or race like ('%native/b%') or race like ('%asian/w%') or race like ('%asian/am%') or race like ('%native/w%')
  or race like ('%can/a%') or race like ('%can/na%') or race like ('%can/w%') or race like ('%ese/wh%') 
  or race like ('%ite/a%') or race like ('%ite/na%') or race like ('%ite/b%') or race like ('%ite/o%') 
  or race like ('%white/patient declined to respond/american%')
  then 5
  
  /*asian*/
  when race like ('%asian%') or race like ('%ese%') or race like ('%fil%') or race like ('%kor%') then 2
  
  /*white*/
  when race like ('%white%') then 0
  
  /*pacific islander*/
  when race like ('%sam%') or race like ('%pac%') or race like ('%guam%') or race like ('%haw%') then 4
  
  /*american indian*/
   when race like ('%alaska%') then 3
  
  /*black*/
   when race like ('%black%') then 1
  
  /*unknown*/
  when race like ('%decline %') or race like ('%above%') or race like ('%other%') or race like ('%patient%') or race 
  like ('%un%') or race like ('%his%')
  or race = '' then 6
 
	end as race_rc,
	
	/*gender*/
	case
	when gender in ('O', 'U', 'X') then 'uk'
	when gender in ('Male', 'M') then 'M'
	else 'F'
	end as gender_rc
  
  from pat_temp;
quit;

/*stats for 2nd paragraph of results*/
proc sql;
	select count(*) as ct, count(distinct patient_id) as ct_distinct_pat, gender, gender_rc from savepath.pat_v2
	group by gender, gender_rc;
quit;

proc sql;
	select count(*) as ct, count(distinct patient_id) as ct_distinct_pat, ethnicity, ethnicity_rc from savepath.pat_v2
	group by ethnicity, ethnicity_rc;
quit;

proc sql;
	select count(*) as ct, count(distinct patient_id) as ct_distinct_pat, race, race_rc from savepath.pat_v2
	group by race, race_rc;
quit;

*age;
*continous;
proc sql;
	select count(*) as ct, age, age_cont from savepath.pat_v2
	where inst = 'NU'
	group by age, age_cont;
quit;

*categorical;
*overall;
proc sql;
	select count(distinct patient_id) as ct_distinct_patient, min(age_cont) as min_age, max(age_cont) as max_age, age_cat from pat_temp
	group by age_cat;
quit;

*by arm;
proc sql;
	select letter, count(distinct patient_id) as ct, min(age_cont) as min_age, max(age_cont) as max_age, age_cat from pat_temp
	group by letter, age_cat;
quit;

*distinct patient counts for 'sample' paragraph in paper;
proc sql;
	create table distinct as 
	select distinct patient_id, age_cat, gender_rc, ethnicity_rc, race_rc from savepath.pat_v2;
quit;

proc freq data = distinct;
	table age_cat gender_rc ethnicity_rc race_rc;
quit;

proc sort data = savepath.pat_v2;
	by letter;
run;

proc sql;
	select count(*) as ct, age_cat, letter from savepath.pat_v2
	group by letter, age_cat order by letter, age_cat;
quit;































