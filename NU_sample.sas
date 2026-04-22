libname savepath "/directory";

/********************************************************************************************************************
**NU STUDY TIME FRAME
***Baseline: 7/22/2022-1/19/2023 (weeks -25 to 0)
***Email sent: 1/23/2023
***Washout: 1/20/2023-2/16/2023 (28 days)
***Intervention: 1/20/2023-7/27/2023 (weeks 1 to 27) (intervention period is 2/17/2023-8/24/2023 if including washout)
**46 distinct NU clinicians 
**3 have two decedents
**********************************************************************************************************************/

*ods pdf file = "/directory/NU_consort_cts_12Dec24.pdf";
*import data;
%macro imp(directory, infile, outfile);
proc import datafile = "&directory/&infile..xlsx"
	out = &outfile
	replace
	dbms = xlsx;
run;
%mend imp;
%imp(/directory, rx_temp, rx);
%imp(/directory, clinician_visits, num_vst);
%imp(/directory, mme_cw, cw);
%imp(/directory, clinician_demo, clinicians);
%imp(/directory, weeks, wks);

*check counts in clinician file;
proc sql;
	title "Total no. of clinicians";
	select count(distinct prov_deid) as ct_prov, count(distinct decedentID) as ct_dec, 
	count(distinct nonfatalid) as ct_n
	from clinicians;
quit;

*check counts in clinician file by study arm;	
proc sql;
	title "No. of clinicians and overdose victims
	by study arm (3 clinicians have two decedents and are in both Tx and Control)";
	select count(distinct prov_deid) as ct_prov, count(distinct decedentID) as ct_dec, 
	count(distinct nonfatalid) as ct_nf,
	intervention from clinicians 
	group by intervention;
quit;

*randomized data;
proc sql;
	create table temp as 
	(select distinct prov_deid, decedentid, nonfatalid, intervention from clinicians)
	order by intervention, prov_deid;
quit;

proc print data = temp;
	title "Randomized overdose victims and clinicians";
run;
	
*Merge Rx and clinician data to get counts;
proc sql;
	create table counts as 
	select t.*, l.intervention,
	l.decedentID, l.nonFatalID,
	case 
	when '22JUL2022'd <= ordering_date <= '19JAN2023'd then 'pre'
	when '20JAN2023'd <= ordering_date <= '27JUL2023'd then 'post'
	else ''
  end as post
	from rx t
	left join clinicians l 
	on t.prov_deid = l.prov_deid;
quit;

*clinician and od data;
proc sql;
	create table temp as 
	(select distinct prov_deid, decedentid, nonfatalid, intervention from counts where intervention ne . and post ne '')
	order by intervention, prov_deid;
quit;

proc print data = temp;
	title "Randomized overdose victims and clinicians w/data in Rx file during study period";
run;

*no. Rxs, clinicians, and patients overall;
proc sql;
	title "No. of Rxs, patients, overdose victims,and clinicians (excludes clinicians w/out Rx during study period)";
	select count(distinct prov_deid) as ct_prov, 
	count(distinct nonfatalid) as ct_nf,
	count(distinct decedentid) as ct_dec from counts
	where post ne '' and intervention ne .;
quit;

*by study arm where post ne . and intervention ne .;
proc sql;
	title "No. of Rxs, patients, overdose victims, and
	clinicians by study arm and study period";
	select count(distinct prov_deid) as ct_prov, 
	count(distinct nonfatalid) as ct_nf,
	count(distinct decedentid) as ct_dec,
	intervention from counts
	where post ne '' and intervention ne .
	group by intervention
	order by intervention;
quit;

*add MME variables from CDC crosswalk;
proc sql;
	create table sample_mme as 
	select t.*, l.strength_per_unit, l.OP_Qtotal, l.has_op, l.mme_factor, l.route, l.form,
	case
	when '22JUL2022'd <= t.ordering_date <= '19JAN2023'd then 'pre'
	when '20JAN2023'd <= t.ordering_date <= '27JUL2023'd then 'post'
	end as post
	from rx t 
	left join 
	(select distinct generic_name, medication_id, strength_per_unit, OP_Qtotal, has_op, mme_factor, form, route from cw) l 
	on t.medication_id = l.medication_id;
quit; 

*check study dates;
proc sql;
	title "Study Period Dates";
	select min(ordering_date) format=mmddyy10. as min, max(ordering_date) format=mmddyy10. as max, post from sample_mme 
	group by post;
quit;

*get MME;
data AESOPS2_sample_mme;
	length form_v2 $ 32.;
	set sample_mme;

	/*extract unit for liquids*/
	locunit = prxparse('/\d+?.?\d+ ML ORAL| ?(\d+ ML)/');
	loc2unit = prxmatch(locunit, med_name);
	unit = prxposn(locunit, 0, med_name);
	unitn = input(compress(unit, , 'a'), 8.);
	
	/*extract drugname*/
  locdrug = prxparse('/CODEINE|COD|HYDROCODONE|HYDROMORPHONE|LEVORPHANOL|METHADONE|MORPHINE|NUCYNTA|OXYCODONE|OXYCONTIN|OXYMORPHONE|TAPENTADOL|ULTRACET|TRAMADOL|ULTRAM|FENTANYL|VIRTUSSIN|HYDROMET|GUAIATUSSIN|MEPERIDINE|OPIUM/');
  loc2drug = prxmatch(locdrug, med_name);
  drug = prxposn(locdrug, 0, med_name);
  if drug = 'COD' then drug = 'CODEINE';
  
  locdrug2 = prxparse('/GUAIFENESIN|ACETAMINOPHEN|PSEUDOEPHEDRINE|PROMETHAZINE|HOMATROPINE|CPM|CHLORPHENIRAMINE|COMPOUND/');
  loc2drug2 = prxmatch(locdrug2, med_name);
  drug2 = prxposn(locdrug2, 0, med_name);
  if drug2 = '' then drug2 = "NONE";
	
	/*strength per unit*/
	if medication_id in (4952, 5176, 10655, 5828) then OP_Qtotal = strength_per_unit;
	if unitn ne . then strengthn = OP_Qtotal/unitn;
	else strengthn = OP_Qtotal;
	strengthn = round(strengthn, .01);
	
	/*round mme factor, and remove letters from quantity*/
	mme_factor = round(mme_factor, .01);
	quantityn = input(compress(quantity, , 'a'), 8.);
	
	/*change "1 bottle" to mL*/
	if medication_id =  9335 and quantity = "1 Bottle" then quantityn = 2.5;
	if medication_id in (174087, 9582, 6627, 199002, 36663) and quantity = "1 Bottle" then quantityn = 120;
	if medication_id in (10655) and quantity = "1 Bottle" then quantityn = 30;
	if medication_id = 8947 and quantity = "1 Bottle" then quantityn = 100;

	/*Days' supply*/
  days = end_date - start_date;
  
  /*REMOVING RXS WITH LOW/DAYS' SUPPLY RENDERS glmmTMB effect INSIGNIFICANT-WHY?*/
  /*if days < 5 then days = quantityn;*/
  
  /*MME: version 1 using start and end date. If end date missing, use 30 days' for denominator*/
  if (days > 0 and days ne .) then do;
  daily_MME = round((strengthn*(quantityn/days)*MME_factor),0.01);
	end;
	else do;
	daily_MME = round((strengthn*(quantityn/30)*MME_factor),0.01);
	end;
	/*MME: version 2 using 30 days' for denominator for all Rxs*/
	daily_MME_v2 = round((strengthn*(quantityn/30)*MME_factor), 0.01);
  total_MME = round(strengthn*quantityn*MME_factor,0.01);
  
  *secondary outcome;
  if daily_MME => 50 then GT_50_MME = 1;
  else GT_50_MME = 0;

  /*standardize drug forms*/
  if medication_id in (210364, 3758) then form = 'Solution';
  if form = '' then form_v2 = '';
  else if form in ('Concentrate', 'Syrup', 'Syringe', 'Suspension', 'Solution', 'Liquid', 'suspension,extended rel 12 hr', 'Tincture', 'spray,non-aerosol') then form_v2 = "Solution";
  else if form = "Suppository" then form_v2 = "Suppository";
  else if form = "patch 72 hour" then form_v2 = "Patch";
  else form_v2 = "Tablet";
  if prov_deid ne '' and daily_mme ne . /*N = 7 Rxs missing pill quantity and MME during study period among randomized clinicians*/;
run;

*add study weeks;
*for encounters w/multiple Rxs and ordering dates, use first order date;
proc sql;
	create table savepath.AESOPS2_sample_mme_9Feb26 as 
	select t.*, n.first_order_dt format=mmddyy10., l.week, l.wks from 
	AESOPS2_sample_MME t 
	left join 
	(select visit_id, min(ordering_date) as first_order_dt from AESOPS2_sample_MME 
	group by visit_id) n 
	on t.visit_id = n.visit_id
	left join 
	wks l
	on l.dt_start <= n.first_order_dt <= l.dt_end;
quit;

*remove orders not during study;
data savepath.AESOPS2_NU_sample_9Feb26;
	length prov_deid $ 32.;
	informat prov_deid $7.;
	set savepath.AESOPS2_sample_mme_9Feb26;
	if week ne . then output;
	format prov_deid $7.;
run;

*check order dates by study week;
proc sql;
	title "Study Week Dates";
	select min(first_order_dt) format=mmddyy10. as min_dt, max(first_order_dt) format=mmddyy10. as max_dt, 
	week, wks, post from savepath.AESOPS2_NU_sample_9Feb26
	group by week, wks, post
	order by wks;
quit;
	
*There are N = 9,625 RXS FOR 8,184 DISTINCT VISITS;
proc sql;
	select count(prescription_Id) as ct_rx, count(distinct prescription_id) as ct_distinct_rx, count(distinct visit_id)
	as ct_distinct_visit
	from savepath.AESOPS2_NU_sample_9Feb26;
quit;









	
	
