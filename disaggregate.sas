libname savepath "/directory";

*import data;
%macro imp(directory, infile, outfile);
proc import datafile = "&directory/&infile..xlsx"
	out = &outfile
	replace
	dbms = xlsx;
run;

*set prov_deid to same length/format for appending;
%if &outfile ne wks OR &outfile ne pat %then %do;
data &outfile;
	length prov_deid $ 32;
	informat prov_deid $7.;
	set &outfile;
	format prov_deid $7.;
run;
%end;

%mend imp;
%imp(/directory, num_vst);
%imp(/directory, clinicians);
%imp(/directory, weeks, wks);
%imp(/directory, Alta_analytic_9Feb26, Alta);
%imp(/directory, AESOPS_R33_Trial2_Pt_Demo, pat);
	
/**************************************NU CONSORT*************************************************************/	
*number of distinct fatal and nonfatal patients NU (CONSORT level 1);
proc sql;
	title "Number of fatal and nonfatal victims for NU (CONSORT level 1)";
	select count(distinct decedentID) as ct_decedent, count(distinct nonfatalID) as ct_nonfatal from clinicians;
quit;

*number of clinicians and OD IDs in each arm NU (CONSORT level 2);
proc sql;
	title "Clinician and OD ID count by arm for NU, CONSORT level 2";
	select intervention, count(distinct prov_deid) as ct_clinician, count(distinct decedentID) as ct_decedent, 
	count(distinct nonfatalID) as ct_nonfatal from clinicians
	group by intervention
	order by intervention;
quit;
/***************************************************************************************************************/

*add letter and fatal variables;
*get one decedent per prescriber;
*3 clinicians (prov11, prov25, prov28)  have two OD victims (only one clinician has both fatal and nonfatal);
*these 3 clinicians are assigned 'letter' and given corresponding OD_ID (prov11 = pt11, prov25 = pt23, prov28 = pt29);
proc sort data = clinicians;
	by prov_deid descending intervention;
run;

data savepath.clinicians_v2;
	length prov_deid $ 32.;
	set clinicians (rename=(intervention=letter));
	by prov_deid;
	
	/*od type (0 = nonfatal, 1 = fatal)*/
	if decedentID = '' then fatal = 0;
	else fatal = 1;
	
	/*decedent ID for random effect*/
	if nonfatalid = '' then od_i = decedentID;
	else if decedentID = '' then od_i = nonfatalid;
	
	/*remove hyphens and quotes*/
	od_id = compress(od_i, '''-');
	
	/*remove subsequent decedents*/
	if first.prov_deid then rn = 1;
	else rn+1;
	if rn = 1 then output;
	keep prov_deid prov_type od_id letter fatal sex specialty_nm grad_year hospital_community clinic_location;
run;

*number of clinicians and OD IDs in each arm NU (CONSORT level 3);
proc sql;
	title "Clinician and OD ID count by arm after removing duplicate OD IDs for NU, CONSORT level 2 (clinicians) & 3 (od id)";
	select count(distinct prov_deid) as ct_clinician, count(distinct od_id) as ct_od, letter, fatal from savepath.clinicians_v2
	group by letter, fatal
	order by letter, fatal;
quit;
	
/*****************************************AltaMed CONSORT*********************************************/
*number of od ids (nonfatal only);
proc sql;
	title "OD ID count (nonfatal only) for AltaMed, CONSORT level 1";
	select count(distinct od_id) as ct_nonfatal from alta;
quit;

proc sql;
	title "OD ID and clinician count (nonfatal only) by arm for AltaMed, CONSORT level 2 & 3";
	select count(distinct prov_deid) as ct_clinician, count(distinct od_id) as ct_nonfatal, letter from alta
	group by letter;
quit;
/*******************************************************************************************************/

*disaggregate sample;
*get total visits, total visits with opioid Rx, and total visits w/out opioid per clinician-week;
proc sql;
create table vsts as 
select t.prov_deid, n.od_id, l.week, n.fatal, n.letter, m.opioid_vsts, t.num_vsts
from num_vst t 
left join 
wks l 
on t.wks = l.wks 
left join 
savepath.clinicians_v2 n 
on t.prov_deid = n.prov_deid 
left join 
(select prov_deid, week, wks, count(distinct visit_id) as opioid_vsts from savepath.AESOPS2_NU_sample_9Feb26
group by prov_deid, week, wks) m 
on t.prov_deid = m.prov_deid 
and t.wks = m.wks
where l.week ne .;
quit;

*remove clinician-weeks with no clincian visits or opioid visits;
*set clinician-weeks with missing opioid visits to 0;
*set clinician-weeks with missing num_vsts or where num_vsts < opioid visits to number of opioid visits [bad data?];
data vsts;
	set vsts;
	if num_vsts = . and opioid_vsts = . then delete;
	if opioid_vsts = . then opioid_vsts = 0;
	if (num_vsts = .) or (num_vsts < opioid_vsts) then num_vsts = opioid_vsts;
	nonopioid_vsts = num_vsts - opioid_vsts;
	drop num_vsts opioid_vsts;
run; 

*generate number of visits (max number of nonopioid Rxs is 84);
data number;
	do _n_ = 1 to 100;
	n = _n_;
	output;
	end;
run;

*extend non-opioid visits;
*total NU non-opioid visits = 50,093;
proc sql;
	create table nonopioids as 
	select t.prov_deid, t.od_id, t.week, t.fatal, t.letter, 0 as gt_50_mme, 0 as daily_mme, 0 as total_mme 
	from vsts t
	join 
	number l
	on t.nonopioid_vsts GE l.n
	order by t.prov_deid, t.week;
quit;

*add opioid visits;
*N = 9,625 RXS FOR 8,184 DISTINCT VISITS;
*1 VISIT ID HAS TWO PRESCRIBERS, SO OPIOID SAMPLE HAS 8,185 ROWS, NOT 8,184;
proc sql;
	create table opioids as 
	select t.prov_deid, t.patient_id,
	l.od_id, t.visit_id, t.week, l.fatal, l.letter, 
	sum(t.daily_mme) as vst_daily_mme, sum(t.total_mme) as vst_total_mme,
	sum(t.GT_50_MME) as vst_gt_50_mme
	from
	savepath.AESOPS2_NU_sample_9Feb26 t
	left join 
	savepath.clinicians_v2 l 
	on t.prov_deid = l.prov_deid
	group by t.prov_deid, t.patient_id, l.od_id, t.visit_id, l.letter, l.fatal, t.week;
quit;

*Table 1 patient demos;
*N = 2,330 distinct patients, and 2,309 total (997 in control and 1412 in letter);
proc sql;
	create table savepath.pat_demos as 
	select distinct t.patient_id, t.letter, l.age,
	l.gender, l.ethnicity, l.race, "NU" as inst from opioids t 
	left join 
	pat l 
	on t.patient_id = l.patient_id;
quit;

*cannot convert age to continuous using 'when' statement in proc sql;
data savepath.pat_demos;
	length patient_id $ 36. inst $ 4. gender $ 6.;
	informat patient_id $ 36. inst $ 4. gender $ 6.;
	set savepath.pat_demos;
	/*age continuous*/
	if age = '' then age_cont = .;
	else if age = '89+' then age_cont = 89;
	else age_cont = age;
	format patient_id $ 36. inst $ 4. gender $ 6.;
run;

*combine opioids, nonopioids and altamed sample;
proc sql;
	create table savepath.analytic_9Feb26 as 
	select *, round(daily_MME/5,1) as pills, 
	case
	when gt_50_mme GE 1 then 1
	else 0
	end as gt_50,
	case 
	when week < 0 then 0
	else week 
	end as kweek, 
	case 
	when week LE 0 then 0
	else 1
	end as post,
	case 
	when daily_mme ne 0 then 1 
	else 0 
	end as opioids 
	from
	(
	(select prov_deid, od_id, letter, fatal, vst_daily_mme as daily_mme, vst_total_mme as total_mme, vst_gt_50_mme as gt_50_mme, week, "NU" as inst from opioids)
	union all
	(select prov_deid, od_id, letter, fatal, daily_mme as daily_mme, total_mme, gt_50_mme, week, "NU" as inst from nonopioids)
	union all
	(select prov_deid, od_id, letter, fatal, daily_mme, . as total_mme, gt_50_mme, week, inst from alta)
	);
quit;

*check sample counts;
proc sql;
	title "OD ID and clinician count by arm for analytic sample, CONSORT level 3";
	select count(distinct prov_deid) as ct_prov, count(distinct od_id) as ct_od, fatal, letter, inst from savepath.analytic 
	group by letter, fatal, inst
	order by letter, fatal, inst;
quit;

*export analytic data;
proc export data = savepath.analytic_9Feb26 
	outfile = "/directory/analytic.dta"
	dbms = dta
	replace;
run;

*secondary data;
data savepath.secondary_analytic;
	set savepath.analytic_9Feb26 (rename = (gt_50_mme = gt_temp));
	if gt_temp GE 1 then gt_50_mme = 1;
	else gt_50_mme = 0;
	if daily_mme ne 0 then output;
	drop gt_temp pills daily_mme;
run; 

*export secondary analytic data;
proc export data = savepath.secondary_analytic 
	outfile = "/directory/secondary_analytic.dta"
	dbms = dta
	replace;
run;
