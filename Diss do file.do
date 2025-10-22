***Load Data using import 

import delimited "C:\Users\jemia\OneDrive\Desktop\Diss\data\underlying_data_2021_ees.csv"

**Data Cleaning**
* Filter for level 7 taught, level 7, and level 7 research programs
keep if qualification_level == "Level 7 (taught)" | qualification_level == "Level 7 (research)" | qualification_level == "Level 7" 

**Remove observations with 'c' in any variable**
tabulate domicile if missing( earnings_median )
* Count occurrences of 'c' and 'z' by domicile
tabulate domicile if earnings_median == "c"
tabulate domicile if earnings_median == "z"

*Drop Missing Values
drop if missing(earnings_median)
summarize earnings_median
drop if trim( sex ) == "Female + male"
drop if trim(subject) == "Total"

**catogorical variables 
encode subject , gen( subject )
encode sex , gen( sexvar )
encode domicile , gen( domicilevar )
encode yag, gen (cohort)
 

*Recoding domicile 
gen domicile_new = .
replace domicile_new = 0 if domicile == "UK"
replace domicile_new = 1 if domicile == "EU"
replace domicile_new = 2 if domicile == "Non-EU"

 
gen treatment = ( domicile_new != 0)

gen lne=ln(earnings_median)


*Removing variables
drop country_code country_name region_code academic_year ethnicity ethnicity_with_chinese ethnicity_detailed inst_type study_mode polar4 polar4 prior_attainment fsm home_region residence grads grads_uk unmatched_percent matched activity_not_captured no_sust_dest sust_emp_only sust_emp_with_or_without_fs sust_emp_fs_or_both fs_with_or_without_sust_emp earnings_include geographic_level region_name time_identifier overseas_percent age_band

 graph bar (mean) earnings_median, over(sex) over(domicilevar) blabel(bar)
 
**IPW 
teffects ipw (lne) ( domicile_new ib2.sexvar ib2.YAG), vce(cluster subject YAG) nolog
estimates store ipw, title(IPW)

teffects overlap, ptlevel(1)
tebalance summarize
estimates store covariate_balance, title(CB)
estout ipw covariate_balance using "ipw results", cells(b(star fmt(3)) se(par fmt(2))) legend label varlabels(_cons constant)   stats(r2 df_r bic, fmt(3 0 1) label(R-sqr dfres BIC))

outreg2 using "results.doc", append title("Results") ctitle("Model ") label bdec(3) tdec(3)

**entropy
ssc install ebalance

* Perform entropy balancing for  students and generate weights
ebalance treatment i.sexvar i.subject i.YAG, gen(eweights) targets ( 1 )


*****FE model
***Model Refinement:
xtset subject

label list subject
regress lne ib3.domicilevar ib2.sexvar ib2.YAG ib20.subject, vce(cluster YAG)
estimates store m1, title(Model 1)  


**Clustered Standard errors
regress lne ib3.domicilevar ib2.sexvar ib2.YAG ib20.subject, vce(cluster YAG)
estimates store m2, title(Model 2) 

** applying entropy weignts 
regress lne ib3.domicilevar ib2.sexvar ib2.YAG ib20.subject [aweight= eweights], vce(cluster YAG)
estimates store m3, title(Model 3) 

**interaction domicile and sex
regress lne ib3.domicilevar ib2.sexvar ib3.domicilevar#ib2.sexvar  ib2.YAG ib20.subject [aweight= eweights], vce(cluster YAG)
estimates store m4, title(Model 4) 


**Domicile and sex , and domicile and chorts
regress lne ib3.domicilevar ib2.sexvar ib3.domicilevar#ib2.sexvar  ib2.YAG  ib3.domicilevar#ib2.YAG ib20.subject [aweight= eweights], vce(cluster YAG)
estimates store m5, title(Model 5) 

estout m1 m2 m3 m4 m5, cells(b(star fmt(3)) se(par fmt(2))) legend label varlabels(_cons constant)   stats(r2 df_r bic, fmt(3 0 1) label(R-sqr dfres BIC))

esttab m1 m2 m3 m4 m5 using "results.rtf", cells(b(star fmt(3)) se(par fmt(2))) legend label varlabels(_cons constant) stats(r2 df_r bic, fmt(3 0 1) label(R-sqr dfres BIC)) replace

outreg2 using "entropy.doc", replace title("Results") ctitle("Model 1") label bdec(3) tdec(3)
outreg2 using "entropy.doc", append title("Results") ctitle("Model 2") label bdec(3) tdec(3)
outreg2 using "entropy.doc", append title("Results") ctitle("Model 3") label bdec(3) tdec(3)
outreg2 using "entropy.doc", append title("Results") ctitle("Model 4") label bdec(3) tdec(3)
outreg2 using "entropy.doc", append title("Results") ctitle("Model 5") label bdec(3) tdec(3)

***PSM IPW
label list domicilevar
recode domicilevar (2=3)
recode domicilevar (1=2)
recode domicilevar (3=1)


