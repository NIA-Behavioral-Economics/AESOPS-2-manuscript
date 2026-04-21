	PURPOSE
	The AESOPS-2 repository provides code for manuscript "###" published in xyz journal on mm yyyy

	DOI: ##########

	DATA (acquired from July 22, 2022 to February 19, 2024)
	1. Clinician, patient, and prescription data acquired from Northwestern Medicine and AltaMed Medical Group 
	2. MME Conversion factors, drug names and strengths, and drug NDCs obtained from Centers for Disease Control and Prevention 
     a. Opioid National Drug Code and Oral MME Conversion File Update. https://www.cdc.gov/opioids/data-resources/index.html (2023). 

	ANALYSES 
	PRIMARY
	1. Piecewise hierarchical Poisson regression with a knot at study week zero testing pre- to post-intervention change in 5 MME 
	pill equivalents between study arms for AESOPS-2 clinicians (n = 60) 
	2. Exponentiated coefficients result in weekly percentage decrease in 5-mg morphine equivalents

	SECONDARY
	1. Log odds (i.e., probability) of clinician-visit including high dose opioid Rx (=> 50 MME) for visits where an opioid was prescribed
     
	CONTENTS 
	1. File code descriptions in order which they should be executed 
	2. Analytic sample data dictionary 
	3. Contact information 
 
	SOFTWARE
	SAS version 9.4, STATA software version 16, and R version 4.3.2

	LICENSE
	Schaeffer Center for Health Policy and Economics, University Southern California
	
	CODE 
	Table1.sas
	Goal: Create Table 1 clinician and patient demographics/characteristics
	  1. Proc import imports data and proc format creates format for Table 1 [1-103]
	  2. Proc sql edits AltaMed and NU demos. Datastep appends AltaMed and NU demos. [105-231]
	  3. Proc sql calculates counts (%) for categorical variables and mean (SD) [233-334]
	  4. Proc sql calculates mean (SD) visits overall and by institution [336-364]
	  5. Proc sql creates table title rows [366-392]
	  6. Proc sql and proc transpose to get sample totals [394-415]
	  7. Datastep appends characteristic statistics and proc report outputs formatted Table 1 [417-465]
	Table1_pat.sas
	Goal: Clean AltaMed and NU patient characteristics to use in Table1.sas
	  1. Proc import imports AltaMed data, datastep increases variable lengths and adds format [3-18]
	  2. Datastep edits variables and bins age [20-36]
	  3. Proc sql adds patient counts by assignment and letter [38-60]
	  4. Proc sql recodes ethnicity, race, and gender [62-116]
	  5. Proc sql and proc freq calculates counts [118-173]
	NU_sample.sas
	Goal: Edit NU sample and calculate morphine milligram equivalents (MME)
	  1. Proc import imports data [13-26]
	  2. Proc sql calculates clinician counts [28-124]
	  3. Datastep extracts and calcualtes MME [126-193]
	  4. Proc sql adds study weeks, checks study dates, and check Rx counts [195-233]  
	disaggregate.sas 
	Goal: Get number of visits w/out an opioid prescription and elongate data so visits without MME are 0 
	 	1. Proc import imports data and datastep standardizes variable format and length for prov_deid [1-26]
		2. Proc sql calculates clinician and decedent counts [28-43]
		3. Datastep creates variables (e.g., fatal, decedent ID) [45-74]
		4. Proc sql calculates clinician and OD victim counts for consort diagram [76-96]
		5. Proc sql joins number of visits per clinician week to sample [98-116]
		6. Datastep cleans bad data (e.g., clinician weeks missing number of visits) [118-128]
		7. Datastep and proc sql disaggregates number of nonopioid visits, proc sql sums MME by visit [130-165]
		8. Proc sql joins opioid and patient data to get Table 1 patient sample [167-186]
		9. Datastep makes age variable continuous and applies formats [187-197]
		10..Proc sql combines NU clinician visits with and without opioid and AltaMed sample [199-227]
		11. Proc sql gets consort diagaram counts and proc export exports analytic data [229-241]
		12. Datastep creates, and proc export exports secondary data [243-262]
		
	   
