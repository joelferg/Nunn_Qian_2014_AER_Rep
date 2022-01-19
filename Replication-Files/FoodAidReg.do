version 13.0
clear all
capture log close
set more off

set matsize 7000

set scheme s1mono

cd "\\Client\H$\Downloads\112825-V1\Replication-Files"

log using "FoodAidReg.log", replace

************************************
*** Some basic coding & cleaning ***
************************************
use "FAid_Final.dta", clear
tsset obs year

/* Converting wheat aid measure & production to thousands of tonnes - coefficients are easier to read */
*replace wheat_aid=wheat_aid_USA/1000
replace wheat_aid=wheat_aid/1000
replace US_wheat_production=US_wheat_production/1000
replace recipient_wheat_prod=recipient_wheat_prod/1000
replace recipient_cereals_prod=recipient_cereals_prod/1000
replace real_usmilaid=real_usmilaid/1000
replace real_us_nonfoodaid_ecaid=real_us_nonfoodaid_ecaid/1000
replace non_us_oda_net=non_us_oda_net/1000
replace non_us_oda_net2=non_us_oda_net2/1000

replace world_wheat_aid=world_wheat_aid/1000
replace world_cereals_aid=world_cereals_aid/1000
replace non_US_wheat_aid=non_US_wheat_aid/1000
replace non_US_cereals_aid=non_US_cereals_aid/1000

* LDVs
gen l_any_war=l.any_war
gen l_inter_state=l.inter_state
gen l_intra_state=l.intra_state
gen l_US_wheat_production=l.US_wheat_production

* Lag and lead of wheat aid
gen l_wheat_aid=l.wheat_aid
gen l2_wheat_aid=l2.wheat_aid
gen l3_wheat_aid=l3.wheat_aid
gen l4_wheat_aid=l4.wheat_aid
gen l5_wheat_aid=l5.wheat_aid

gen f_wheat_aid=f.wheat_aid
gen f2_wheat_aid=f2.wheat_aid
gen f3_wheat_aid=f3.wheat_aid
gen f4_wheat_aid=f4.wheat_aid
gen f5_wheat_aid=f5.wheat_aid

foreach x of varlist all_Precip_jan-all_Precip_dec all_Temp_jan-all_Temp_dec{
	drop `x'_faavg
	gen `x'_faavg=`x'*fadum_avg
}


/* Creating all instruments */
gen instrument=l.US_wheat_production*fadum_avg
la var instrument "Baseline interaction instrument: US wheat prod (t-1) x avg food aid prob (1971-2006)"

gen instrument2=l.US_wheat_production
la var instrument2 "Alternative unteracted instrument: US wheat production (t-1)"

gen l_instrument=l2.US_wheat_production*fadum_avg
la var l_instrument "One-year lag of baseline interaction instrument"
gen l2_instrument=l3.US_wheat_production*fadum_avg
la var l2_instrument "Two-year lag of baseline interaction instrument"
gen l3_instrument=l4.US_wheat_production*fadum_avg
la var l3_instrument "Three-year lag of baseline interaction instrument"
gen l4_instrument=l5.US_wheat_production*fadum_avg
la var l4_instrument "Four-year lag of baseline interaction instrument"
gen l5_instrument=l6.US_wheat_production*fadum_avg
la var l5_instrument "Five-year lag of baseline interaction instrument"

gen f_instrument=US_wheat_production*fadum_avg
la var f_instrument "One-year forward of baseline interaction instrument"
gen f2_instrument=f.US_wheat_production*fadum_avg
la var f2_instrument "Two-year forward of baseline interaction instrument"
gen f3_instrument=f2.US_wheat_production*fadum_avg
la var f3_instrument "Two-year forward of baseline interaction instrument"
gen f4_instrument=f3.US_wheat_production*fadum_avg
la var f4_instrument "Two-year forward of baseline interaction instrument"
gen f5_instrument=f4.US_wheat_production*fadum_avg
la var f5_instrument "Two-year forward of baseline interaction instrument"

gen instrument3=ln(l.US_wheat_production)*fadum_avg
la var instrument3 "Instrument using the log of lagged US wheat production"

/* Creating lagged US production variables */
foreach x in Oranges Grapes Lettuce Cotton_lint Onions_dry Grapefruit Cabbages Watermelons Carrots_turnips Peaches_nectarines{
	gen l_USprod_`x'=l.USprod_`x'
	la var l_USprod_`x' "US production in year t-1 (tonnes, MT) - from FAOStat"
}

/* Dropping years outside of the sample period */
drop if year<1971
drop if year>2006

/* Generating continent indicators, year indicators, and their interactions so that we don't have to use time-series operators -- they take longer for stata to compute */
gen cont=.
replace cont=1 if wb_region=="East Asia & Pacific"
replace cont=2 if wb_region=="Europe & Central Asia"
replace cont=3 if wb_region=="Latin America & Caribbean"
replace cont=4 if wb_region=="Middle East & North Africa"
replace cont=5 if wb_region=="South Asia"
replace cont=6 if wb_region=="Sub-Saharan Africa"

tab cont, gen(contdum)
tab year, gen(ydum)
tab risocode, gen(cdum)

forval x=1/36{
	gen cont1_y`x'=contdum1*ydum`x'
}
forval x=1/36{
	gen cont2_y`x'=contdum2*ydum`x'
}
forval x=1/36{
	gen cont3_y`x'=contdum3*ydum`x'
}
forval x=1/36{
	gen cont4_y`x'=contdum4*ydum`x'
}
forval x=1/36{
	gen cont5_y`x'=contdum5*ydum`x'
}
forval x=1/36{
	gen cont6_y`x'=contdum6*ydum`x'
}
forval x=1/36{
	gen rcereal_y`x'=recipient_pc_cereals_prod_avg*ydum`x'
}
forval x=1/36{
	gen rimport_y`x'=cereal_pc_import_quantity_avg*ydum`x'
}
forval x=1/36{
	gen usec_y`x'=real_us_nonfoodaid_ecaid_avg*ydum`x'
}
forval x=1/36{
	gen usmil_y`x'=real_usmilaid_avg*ydum`x'
}

gen USA_ln_income = ln(USA_rgdpch)

bysort risocode: egen ln_rgdpch_avg=mean(ln_rgdpch) if year>=1971 & year<=2006

forval x=1/36{
	gen gdp_y`x'=ln_rgdpch_avg*ydum`x'
}
gen oil_fadum_avg=oil_price_2011_USD*fadum_avg
gen US_income_fadum_avg=USA_ln_income*fadum_avg
gen US_democ_pres_fadum_avg=US_president_democ*fadum_avg

local US_controls "oil_fadum_avg US_income_fadum_avg US_democ_pres_fadum_avg"
local weather_controls "all_Precip_jan-all_Precip_dec all_Temp_jan-all_Temp_dec all_Precip_jan_faavg-all_Precip_dec_faavg all_Temp_jan_faavg-all_Temp_dec_faavg"
local country_chars_controls "gdp_y2-gdp_y36 usmil_y2-usmil_y36 usec_y2-usec_y36"
local cereals_controls "rcereal_y2-rcereal_y36 rimport_y2-rimport_y36"
local baseline_controls "oil_fadum_avg US_income_fadum_avg US_democ_pres_fadum_avg gdp_y2-gdp_y36 usmil_y2-usmil_y36 usec_y2-usec_y36 rcereal_y2-rcereal_y36 rimport_y2-rimport_y36 all_Precip_jan-all_Precip_dec all_Temp_jan-all_Temp_dec all_Precip_jan_faavg-all_Precip_dec_faavg all_Temp_jan_faavg-all_Temp_dec_faavg"

sor risocode year
save "in_sample.dta", replace


***********************************
*** TABLE 1: Summary Statistics ***
***********************************

use "in_sample.dta", clear

/* Generating in-sample indicator so that all specifications have the same number of observations */
qui: xi: ivreg2 intra_state (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode)
gen in_sample=1 if e(sample)==1

sum any_war intra_state inter_state wheat_aid fadum_avg instrument2 recipient_cereals_prod recipient_wheat_prod if in_sample==1

* Summary statistics for the variables from the onset & offset specifications are reported below (Table 7)


**********************************
*** TABLE 2: Baseline OLS & IV ***
**********************************

use "in_sample.dta", clear

/* Generating in-sample indicator so that all specifications have the same number of observations */
qui: xi: ivreg2 intra_state (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode)
gen in_sample=1 if e(sample)==1

*** Panel A: OLS Estimates ***
* Col 1
xi: reg any_war wheat_aid i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 wheat_aid using "T2_PanelA_ols.xls", replace se noast nocons lab dec(5)
* Col 2
xi: reg any_war wheat_aid `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 wheat_aid using "T2_PanelA_ols.xls", append se noast nocons lab dec(5)
* Col 3
xi: reg any_war wheat_aid `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 wheat_aid using "T2_PanelA_ols.xls", append se noast nocons lab dec(5)
* Col 4
xi: reg any_war wheat_aid `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 wheat_aid  using "T2_PanelA_ols.xls", append se noast nocons lab dec(5)
* Col 5
xi: reg any_war wheat_aid `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 wheat_aid  using "T2_PanelA_ols.xls", append se noast nocons lab dec(5)
* Col 6
xi: reg intra_state wheat_aid `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 wheat_aid  using "T2_PanelA_ols.xls", append se noast nocons lab dec(5)
* Col 7
xi: reg inter_state wheat_aid `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 wheat_aid  using "T2_PanelA_ols.xls", append se noast nocons lab dec(5)

*** Panel B: Reduced Form ***
preserve
foreach x of varlist any_war intra_state inter_state{
	replace `x'=`x'*1000
}
* Col 1
xi: reg any_war instrument i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument using "T2_PanelB_rf.xls", replace se noast nocons lab dec(5)
* Col 2
xi: reg any_war instrument `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument using "T2_PanelB_rf.xls", append se noast nocons lab dec(5)
* Col 3
xi: reg any_war instrument `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument using "T2_PanelB_rf.xls", append se noast nocons lab dec(5)
* Col 4
xi: reg any_war instrument `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument using "T2_PanelB_rf.xls", append se noast nocons lab dec(5)
* Col 5
xi: reg any_war instrument `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument using "T2_PanelB_rf.xls", append se noast nocons lab dec(5)
* Col 6
xi: reg intra_state instrument `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument using "T2_PanelB_rf.xls", append se noast nocons lab dec(5)
* Col 7
xi: reg inter_state instrument `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument using "T2_PanelB_rf.xls", append se noast nocons lab dec(5)
restore

*** Panel C: Second Stage of IV ***
* Col 1 - no controls
xi: ivreg2 any_war (wheat_aid=instrument) i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid using "T2_PanelC_iv_second.xls", replace se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
* Col 2 - add oil price x FAdum, US GDP x FAdum & president x FAdum
xi: ivreg2 any_war (wheat_aid=instrument) `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid using "T2_PanelC_iv_second.xls", se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
* Col 3 - add weather x FAdum
xi: ivreg2 any_war (wheat_aid=instrument) `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid using "T2_PanelC_iv_second.xls", se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
* Col 4 - add other aid x yearFE & Income avg x yearFE
xi: ivreg2 any_war (wheat_aid=instrument) `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid using "T2_PanelC_iv_second.xls", se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
* Col 5 - add cereal prod x year FE & imports x yearFE (=all controls)
xi: ivreg2 any_war (wheat_aid=instrument) `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid using "T2_PanelC_iv_second.xls", se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
* Col 6 - all controls: intra-state conflicts
xi: ivreg2 intra_state (wheat_aid=instrument) `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid using "T2_PanelC_iv_second.xls", se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
*Col 7 - all controls: inter-state conflicts
xi: ivreg2 inter_state (wheat_aid=instrument) `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid using "T2_PanelC_iv_second.xls", se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))

*** Panel D: First stage of IV *****
* Col 1
xi: reg wheat_aid instrument i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument using "T2_PanelD_iv_first.xls", replace se noast nocons lab dec(5)
* Col 2
xi: reg wheat_aid instrument `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument using "T2_PanelD_iv_first.xls", append se noast nocons lab dec(5)
* Col 3
xi: reg wheat_aid instrument `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument using "T2_PanelD_iv_first.xls", append se noast nocons lab dec(5)
* Col 4
xi: reg wheat_aid instrument `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument using "T2_PanelD_iv_first.xls", append se noast nocons lab dec(5)
* Col 5
xi: reg wheat_aid instrument `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument using "T2_PanelD_iv_first.xls", append se noast nocons lab dec(5)
* Col 6
xi: reg wheat_aid instrument `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument using "T2_PanelD_iv_first.xls", append se noast nocons lab dec(5)
* Col 7
xi: reg wheat_aid instrument `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument using "T2_PanelD_iv_first.xls", append se noast nocons lab dec(5)


********************************
*** TABLE 3: Uninteracted IV ***
********************************
use "in_sample.dta", clear

/* Generating analogous control variables variables */
gen x1=year*real_usmilaid_avg
gen x2=year*real_us_nonfoodaid_ecaid_avg
gen x3=year*ln_rgdpch_avg
gen x4=year*recipient_pc_cereals_prod_avg
gen x5=year*cereal_pc_import_quantity_avg

local US_controls2 "oil_price_2011_USD USA_ln_income US_president_democ"
local weather_controls2 "all_Precip_jan-all_Precip_dec all_Temp_jan-all_Temp_dec"
local country_chars_controls2 "x1 x2 x3"
local cereals_controls2 "x4 x5"

/* Generating in-sample indicator so that all specifications have the same number of observations */
qui: xi: ivreg2 any_war (wheat_aid=instrument2) `cereals_controls2' `country_chars_controls2' `weather_controls2' `US_controls2' i.risocode i.wb_region*year if year>=1971 & year<=2006, cluster(risocode)
gen in_sample=1 if e(sample)==1


*** Panel A: OLS Estimates ***
* Col 1
xi: reg any_war wheat_aid i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 wheat_aid using "T3_uninteracted_PanelA_ols.xls", replace se noast nocons lab dec(5) slow(500)
* Col 2
xi: reg any_war wheat_aid `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 wheat_aid using "T3_uninteracted_PanelA_ols.xls", append se noast nocons lab dec(5) slow(500)
* Col 3
xi: reg any_war wheat_aid `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 wheat_aid using "T3_uninteracted_PanelA_ols.xls", append se noast nocons lab dec(5) slow(500)
* Col 4
xi: reg any_war wheat_aid `country_chars_controls2' `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 wheat_aid  using "T3_uninteracted_PanelA_ols.xls", append se noast nocons lab dec(5) slow(500)
* Col 5
xi: reg any_war wheat_aid `cereals_controls2' `country_chars_controls2' `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 wheat_aid  using "T3_uninteracted_PanelA_ols.xls", append se noast nocons lab dec(5) slow(500)
* Col 6
xi: reg intra_state wheat_aid `cereals_controls2' `country_chars_controls2' `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 wheat_aid  using "T3_uninteracted_PanelA_ols.xls", append se noast nocons lab dec(5) slow(500)
* Col 7
xi: reg inter_state wheat_aid `cereals_controls2' `country_chars_controls2' `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 wheat_aid  using "T3_uninteracted_PanelA_ols.xls", append se noast nocons lab dec(5) slow(500)

*** Panel B: Reduced Form ***
preserve
foreach x of varlist any_war intra_state inter_state{
	replace `x'=`x'*1000
}
* Col 1
xi: reg any_war instrument2 i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 instrument2 using "T3_uninteracted_PanelB_rf.xls", replace se noast nocons lab dec(5) slow(100)
* Col 2
xi: reg any_war instrument2 `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 instrument2 using "T3_uninteracted_PanelB_rf.xls", append se noast nocons lab dec(5) slow(100)
* Col 3
xi: reg any_war instrument2 `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 instrument2 using "T3_uninteracted_PanelB_rf.xls", append se noast nocons lab dec(5) slow(100)
* Col 4
xi: reg any_war instrument2 `country_chars_controls2' `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 instrument2 using "T3_uninteracted_PanelB_rf.xls", append se noast nocons lab dec(5) slow(100)
* Col 5
xi: reg any_war instrument2 `cereals_controls2' `country_chars_controls2' `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 instrument2 using "T3_uninteracted_PanelB_rf.xls", append se noast nocons lab dec(5) slow(100)
* Col 6
xi: reg intra_state instrument2 `cereals_controls2' `country_chars_controls2' `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 instrument2 using "T3_uninteracted_PanelB_rf.xls", append se noast nocons lab dec(5) slow(100)
* Col 7
xi: reg inter_state instrument2 `cereals_controls2' `country_chars_controls2' `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 instrument2 using "T3_uninteracted_PanelB_rf.xls", append se noast nocons lab dec(5) slow(100)
restore

*** Panel C: Second Stage of IV ***
* Col 1
xi: ivreg2 any_war (wheat_aid=instrument2) i.risocode i.wb_region*year if in_sample==1, cluster(risocode) first
rivtest, ci level(90)
outreg2 wheat_aid using "T3_uninteracted_PanelC_iv_second.xls", replace se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
* Col 2
xi: ivreg2 any_war (wheat_aid=instrument2) `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode) ffirst
rivtest, ci level(90)
outreg2 wheat_aid using "T3_uninteracted_PanelC_iv_second.xls", append se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
* Col 3
xi: ivreg2 any_war (wheat_aid=instrument2) `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode) ffirst
rivtest, ci level(90)
outreg2 wheat_aid using "T3_uninteracted_PanelC_iv_second.xls", append se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
* Col 4
xi: ivreg2 any_war (wheat_aid=instrument2) `country_chars_controls2' `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode) ffirst
rivtest, ci level(90)
outreg2 wheat_aid using "T3_uninteracted_PanelC_iv_second.xls", append se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
* Col 5
xi: ivreg2 any_war (wheat_aid=instrument2) `cereals_controls2' `country_chars_controls2' `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode) ffirst
rivtest, ci level(90)
outreg2 wheat_aid using "T3_uninteracted_PanelC_iv_second.xls", append se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
* Col 6
xi: ivreg2 intra_state (wheat_aid=instrument2) `cereals_controls2' `country_chars_controls2' `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode) ffirst
rivtest, ci level(90)
outreg2 wheat_aid using "T3_uninteracted_PanelC_iv_second.xls", append se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
* Col 7
xi: ivreg2 inter_state (wheat_aid=instrument2) `cereals_controls2' `country_chars_controls2' `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode) ffirst
rivtest, ci level(90)
outreg2 wheat_aid using "T3_uninteracted_PanelC_iv_second.xls", append se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))

*** Panel D: First stage of IV *****
* Col 1
xi: reg wheat_aid instrument2 i.risocode i.wb_region*year if missing(any_war)!=1 & in_sample==1, cluster(risocode)
outreg2 instrument2 using "T3_uninteracted_PanelD_iv_first.xls", replace se noast nocons lab dec(6)
* Col 2
xi: reg wheat_aid instrument2 `US_controls2' i.risocode i.wb_region*year if missing(any_war)!=1 & in_sample==1, cluster(risocode)
outreg2 instrument2 using "T3_uninteracted_PanelD_iv_first.xls", append se noast nocons lab dec(6)
* Col 3
xi: reg wheat_aid instrument2 `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 instrument2 using "T3_uninteracted_PanelD_iv_first.xls", append se noast nocons lab dec(6)
* Col 4
xi: reg wheat_aid instrument2 `country_chars_controls2' `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 instrument2 using "T3_uninteracted_PanelD_iv_first.xls", append se noast nocons lab dec(6)
* Col 5
xi: reg wheat_aid instrument2 `cereals_controls2' `country_chars_controls2' `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 instrument2 using "T3_uninteracted_PanelD_iv_first.xls", append se noast nocons lab dec(6)
* Col 6
xi: reg wheat_aid instrument2 `cereals_controls2' `country_chars_controls2' `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 instrument2 using "T3_uninteracted_PanelD_iv_first.xls", append se noast nocons lab dec(6)
* Col 7
xi: reg wheat_aid instrument2 `cereals_controls2' `country_chars_controls2' `weather_controls2' `US_controls2' i.risocode i.wb_region*year if in_sample==1, cluster(risocode)
outreg2 instrument2 using "T3_uninteracted_PanelD_iv_first.xls", append se noast nocons lab dec(6)


************************************
*** TABLE 4: Baseline with a LDV ***
************************************

use "in_sample.dta", clear

/* Generating in-sample indicator so that all specifications have the same number of observations */
qui: xi: ivreg2 intra_state l_intra_state (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode)
gen in_sample=1 if e(sample)==1

*** Panel A: OLS Estimates ***
* Col 1
xi: reg any_war l_any_war wheat_aid i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 wheat_aid l_any_war using "T4_ldv_PanelA_ols.xls", replace se noast nocons lab dec(5)
* Col 2
xi: reg any_war l_any_war wheat_aid `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 wheat_aid l_any_war using "T4_ldv_PanelA_ols.xls", append se noast nocons lab dec(5)
* Col 3
xi: reg any_war l_any_war wheat_aid `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 wheat_aid l_any_war using "T4_ldv_PanelA_ols.xls", append se noast nocons lab dec(5)
* Col 4
xi: reg any_war l_any_war wheat_aid `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 wheat_aid l_any_war using "T4_ldv_PanelA_ols.xls", append se noast nocons lab dec(5)
* Col 5
xi: reg any_war l_any_war wheat_aid `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 wheat_aid l_any_war using "T4_ldv_PanelA_ols.xls", append se noast nocons lab dec(5)
* Col 6
xi: reg intra_state l_intra_state wheat_aid `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 wheat_aid l_intra_state using "T4_ldv_PanelA_ols.xls", append se noast nocons lab dec(5)
* Col 7
xi: reg inter_state l_inter_state wheat_aid `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 wheat_aid l_inter_state using "T4_ldv_PanelA_ols.xls", append se noast nocons lab dec(5)

*** Panel B: Reduced Form ***
preserve
foreach x of varlist any_war intra_state inter_state{
	replace `x'=`x'*1000
}
* Col 1
xi: reg any_war l_any_war instrument i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument l_any_war using "T4_ldv_PanelB_rf.xls", replace se noast nocons lab dec(5)
* Col 2
xi: reg any_war l_any_war instrument `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument l_any_war using "T4_ldv_PanelB_rf.xls", append se noast nocons lab dec(5)
* Col 3
xi: reg any_war l_any_war instrument `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument l_any_war using "T4_ldv_PanelB_rf.xls", append se noast nocons lab dec(5)
* Col 4
xi: reg any_war l_any_war instrument `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument l_any_war using "T4_ldv_PanelB_rf.xls", append se noast nocons lab dec(5)
* Col 5
xi: reg any_war l_any_war instrument `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument l_any_war using "T4_ldv_PanelB_rf.xls", append se noast nocons lab dec(5)
* Col 6
xi: reg intra_state l_intra_state instrument `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument l_intra_state using "T4_ldv_PanelB_rf.xls", append se noast nocons lab dec(5)
* Col 7
xi: reg inter_state l_inter_state instrument `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument l_inter_state using "T4_ldv_PanelB_rf.xls", append se noast nocons lab dec(5)
restore

*** Panel C: Second Stage of IV ***
* Col 1
xi: ivreg2 any_war l_any_war (wheat_aid=instrument) i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid l_any_war using "T4_ldv_PanelC_iv_second.xls", replace se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
* Col 2
xi: ivreg2 any_war l_any_war (wheat_aid=instrument) `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid l_any_war using "T4_ldv_PanelC_iv_second.xls", append se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
* Col 3
xi: ivreg2 any_war l_any_war (wheat_aid=instrument) `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid l_any_war using "T4_ldv_PanelC_iv_second.xls", append se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
* Col 4
xi: ivreg2 any_war l_any_war (wheat_aid=instrument) `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid l_any_war using "T4_ldv_PanelC_iv_second.xls", append se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
* Col 5
xi: ivreg2 any_war l_any_war (wheat_aid=instrument) `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid l_any_war using "T4_ldv_PanelC_iv_second.xls", append se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
* Col 6
xi: ivreg2 intra_state l_intra_state (wheat_aid=instrument) `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid l_intra_state using "T4_ldv_PanelC_iv_second.xls", append se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))
*Col 7
xi: ivreg2 inter_state l_inter_state (wheat_aid=instrument) `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid l_inter_state using "T4_ldv_PanelC_iv_second.xls", append se noast nocons lab dec(5) adds(KP F-Stat, e(rkf))

*** Panel D: First stage of IV *****
* Col 1
xi: reg wheat_aid l_any_war instrument i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument l_any_war using "T4_ldv_PanelD_iv_first.xls", replace se noast nocons lab dec(5)
* Col 2
xi: reg wheat_aid l_any_war instrument `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument l_any_war using "T4_ldv_PanelD_iv_first.xls", append se noast nocons lab dec(5)
* Col 3
xi: reg wheat_aid l_any_war instrument `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument l_any_war using "T4_ldv_PanelD_iv_first.xls", append se noast nocons lab dec(5)
* Col 4
xi: reg wheat_aid l_any_war instrument `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument l_any_war using "T4_ldv_PanelD_iv_first.xls", append se noast nocons lab dec(5)
* Col 5
xi: reg wheat_aid l_any_war instrument `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument l_any_war using "T4_ldv_PanelD_iv_first.xls", append se noast nocons lab dec(5)
* Col 6
xi: reg wheat_aid l_inter_state instrument `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument l_inter_state using "T4_ldv_PanelD_iv_first.xls", append se noast nocons lab dec(5)
* Col 7
xi: reg wheat_aid l_intra_state instrument `cereals_controls' `country_chars_controls' `weather_controls' `US_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode)
outreg2 instrument l_intra_state using "T4_ldv_PanelD_iv_first.xls", append se noast nocons lab dec(5)


*******************************************
*** TABLE 5: Reduced Form Placebo Tests ***
*******************************************

use "in_sample.dta", clear

/* Changing units so coefficients are easier read */
foreach x of varlist /*any_war*/ intra_state /*inter_state*/{
	replace `x'=`x'*1000
}

* Col 1: wheat
xi: reg intra_state instrument `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006 & missing(wheat_aid)!=1, cluster(risocode)
outreg2 instrument using "T5_Falsification_rf.xls", replace se noast nocons lab dec(5) ctitle("Wheat/Baseline")

* Cols 2-11: other crops
gen instrument_orig=instrument
foreach x in Oranges Grapes Lettuce Cotton_lint Onions_dry Grapefruit Cabbages Watermelons Carrots_turnips Peaches_nectarines{
	preserve
	drop instrument
	gen instrument=(l_USprod_`x'/1000)*fadum_avg	/* Placebo instruments are measured in thousands of MT just like the original wheat instrument */
	xi: reg intra_state instrument_orig instrument `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006 & missing(wheat_aid)!=1, cluster(risocode)
	outreg2 using "T5_Falsification_rf.xls", append se noast nocons lab dec(5) ctitle("`x'") keep(instrument_orig instrument)
	restore
}

*** Beta coefficients ***
* Col 1: wheat
xi: reg intra_state instrument `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006 & missing(wheat_aid)!=1, beta
outreg2 instrument using "T5_Falsification_rf_betas.xls", replace se noast nocons lab dec(5) ctitle("Wheat/Baseline") stats(beta)

* Cols 2-11: Other crops
foreach x in Oranges Grapes Lettuce Cotton_lint Onions_dry Grapefruit Cabbages Watermelons Carrots_turnips Peaches_nectarines{
	preserve
	drop instrument
	gen instrument=(l_USprod_`x'/1000)*fadum_avg	/* Placebo instruments are measured in thousands of MT just like the original wheat instrument */
	xi: reg intra_state instrument_orig instrument `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006 & missing(wheat_aid)!=1, beta
	outreg2 using "T5_Falsification_rf_betas.xls", append se noast nocons lab dec(5) ctitle("`x'") keep(instrument_orig instrument) stats(beta)
	restore
}


*** Summary Statistics ****
qui: xi: ivreg2 intra_state (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode)
gen in_sample=1 if e(sample)==1

foreach x in Oranges Grapes Lettuce Cotton_lint Onions_dry Grapefruit Cabbages Watermelons Carrots_turnips Peaches_nectarines{
sum USprod_`x' if year>=1971 & year<=2006 & in_sample==1
}


*******************************************
*** TABLE 6: Alternative specifications ***
*******************************************
use "in_sample.dta", clear
tsset obs year

/*Col 1: Baseline*/
xi: ivreg2 intra_state (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
outreg2 wheat_aid using "T6_alt_specs.xls", replace se noast nocons ctitle(baseline) dec(5) adds(KP F-Stat, e(rkf))
gen in_sample=1 if e(sample)==1
xi: ivreg intra_state (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode)
outreg2 wheat_aid using "T6_alt_specs_beta.xls", replace se noast nocons ctitle(baseline) stat(beta) dec(3)

/* Col 2: Using lagged FAdum */
preserve
tsset obs year
gen l_fadum=(l.fadum)
drop instrument
gen instrument=l_US_wheat_production*l_fadum
xi: ivreg2 intra_state (wheat_aid=instrument) l_fadum `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid using "T6_alt_specs.xls", append se noast nocons ctitle(using lagged FAdum) dec(5) adds(KP F-Stat, e(rkf))
xi: ivreg intra_state (wheat_aid=instrument) l_fadum `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, beta
outreg2 wheat_aid using "T6_alt_specs_beta.xls", append se noast nocons ctitle(using lagged FAdum) stat(beta) dec(3)
restore

/* Col 3: Using 2-year lagged FAdum */
preserve
tsset obs year
gen xx=(l.fadum+l2.fadum)/2
drop instrument
gen instrument=l_US_wheat_production*xx
gen xx2=xx*xx
xi: ivreg2 intra_state (wheat_aid=instrument) xx* `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid using "T6_alt_specs.xls", append se noast nocons ctitle(using 2-year lagged FAdum) dec(5) adds(KP F-Stat, e(rkf))
xi: ivreg intra_state (wheat_aid=instrument) xx* `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, beta
outreg2 wheat_aid using "T6_alt_specs_beta.xls", append se noast nocons ctitle(using 2-year lagged FAdum) stat(beta) dec(3)
drop xx
restore

/* Col 4: Using 4-year lagged FAdum */
preserve
tsset obs year
gen xx=(l.fadum+l2.fadum+l3.fadum+l4.fadum)/4
drop instrument
gen instrument=l_US_wheat_production*xx
gen xx2=xx*xx
xi: ivreg2 intra_state (wheat_aid=instrument) xx* `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
rivtest, ci level(90)	/* First stage in this specification is weak */
outreg2 wheat_aid using "T6_alt_specs.xls", append se noast nocons ctitle(using 4-year lagged FAdum) dec(5) adds(KP F-Stat, e(rkf))
xi: ivreg intra_state (wheat_aid=instrument) xx* `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, beta
outreg2 wheat_aid using "T6_alt_specs_beta.xls", append se noast nocons ctitle(using 4-year lagged FAdum) stat(beta) dec(3)
drop xx
restore

/* Col 5: Normalizing wheat aid by per capita population (kg/person)*/
preserve
replace wheat_aid=wheat_aid*1000*1000/total_population
xi: ivreg2 intra_state (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid using "T6_alt_specs.xls", append se noast nocons ctitle(normalize by pop) adds(KP F-Stat, e(rkf))
xi: ivreg intra_state (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, beta
outreg2 wheat_aid using "T6_alt_specs_beta.xls", append se noast nocons ctitle(normalize by pop) stat(beta) dec(3)
restore

/* Col 6: Taking natural log of wheat aid and production */
preserve
replace wheat_aid=ln(1+wheat_aid)
xi: ivreg2 intra_state (wheat_aid=instrument3) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid using "T6_alt_specs.xls", append se noast nocons ctitle (logs) adds(KP F-Stat, e(rkf))
xi: ivreg intra_state (wheat_aid =instrument3) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, beta
outreg2 wheat_aid using "T6_alt_specs_beta.xls", append se noast nocons ctitle(logs) stat(beta) dec(3)
restore

/* Col 7: Dropping former Soviet countries */
preserve
for @ in any RUS ARM AZE BLR EST GEO KAZ KGZ LVA LTU MDA TJK TKM UKR UZB: drop if risocode=="@"
xi: ivreg2 intra_state (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid using "T6_alt_specs.xls", append se noast nocons ctitle(No Soviet) dec(5) adds(KP F-Stat, e(rkf))
xi: ivreg intra_state (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, beta
outreg2 wheat_aid using "T6_alt_specs_beta.xls", append se noast nocons ctitle(No Soviet) stat(beta) dec(3)
restore

/* Col 8: Dropping 1971, 1972 & 1973 -- Years for which the data seem noisiest */
preserve
xi: ivreg2 intra_state (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1 & year>=1974 & year<=2006, cluster(risocode) ffirst
outreg2 wheat_aid using "T6_alt_specs.xls", append se noast nocons ctitle(Dropping early yrs) dec(5) adds(KP F-Stat, e(rkf))
xi: ivreg intra_state (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1 & year>=1974 & year<=2006, beta
outreg2 wheat_aid using "T6_alt_specs_beta.xls", append se noast nocons ctitle(Dropping early yrs) stat(beta) dec(3)
restore

/* Col 9: Adding lagged wheat aid */
xi: ivreg2 intra_state (wheat_aid l_wheat_aid = instrument l_instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 l_wheat_aid wheat_aid using "T6_alt_specs.xls", append se noast nocons ctitle(Add lag) dec(5)
xi: ivreg intra_state (wheat_aid l_wheat_aid = instrument l_instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, beta
outreg2 l_wheat_aid wheat_aid using "T6_alt_specs_beta.xls", append se noast nocons ctitle(Add lag) stat(beta) dec(3)

/* Col 10: Adding lead wheat aid */
xi: ivreg2 intra_state (wheat_aid f_wheat_aid = instrument f_instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 f_wheat_aid wheat_aid using "T6_alt_specs.xls", append se noast nocons ctitle(Add lead) dec(5)
xi: ivreg intra_state (wheat_aid f_wheat_aid = instrument f_instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, beta
outreg2 f_wheat_aid wheat_aid using "T6_alt_specs_beta.xls", append se noast nocons ctitle(Add lead) stat(beta) dec(3)


*********************************
*** TABLE 7: Onset & Duration ***
*********************************

use "FAid_Final.dta", clear
tsset obs year

gen l_intra_state=l.intra_state
gen l_any_war=l.any_war

/* Converting wheat aid measure & production to thousands of tonnes - coefficients are easier to read */
replace wheat_aid=wheat_aid/1000
replace US_wheat_production=US_wheat_production/1000

gen instrument=l.US_wheat_production*fadum_avg
la var instrument "Baseline interaction instrument: US wheat prod (t-1) x avg food aid prob (1971-2006)"

/* Dropping years outside of the sample period */
drop if year<1971
drop if year>2006

/* Generating continent indicators, year indicators, and their interactions so that we don't have to use time-series operators -- they take longer for stata to compute */
gen cont=.
replace cont=1 if wb_region=="East Asia & Pacific"
replace cont=2 if wb_region=="Europe & Central Asia"
replace cont=3 if wb_region=="Latin America & Caribbean"
replace cont=4 if wb_region=="Middle East & North Africa"
replace cont=5 if wb_region=="South Asia"
replace cont=6 if wb_region=="Sub-Saharan Africa"

tab cont, gen(contdum)
tab year, gen(ydum)
tab risocode, gen(cdum)

forval x=1/36{
	gen cont1_y`x'=contdum1*ydum`x'
}
forval x=1/36{
	gen cont2_y`x'=contdum2*ydum`x'
}
forval x=1/36{
	gen cont3_y`x'=contdum3*ydum`x'
}
forval x=1/36{
	gen cont4_y`x'=contdum4*ydum`x'
}
forval x=1/36{
	gen cont5_y`x'=contdum5*ydum`x'
}
forval x=1/36{
	gen cont6_y`x'=contdum6*ydum`x'
}
forval x=1/36{
	gen rcereal_y`x'=recipient_pc_cereals_prod_avg*ydum`x'
}
forval x=1/36{
	gen rimport_y`x'=cereal_pc_import_quantity_avg*ydum`x'
}
forval x=1/36{
	gen usec_y`x'=real_us_nonfoodaid_ecaid_avg*ydum`x'
}
forval x=1/36{
	gen usmil_y`x'=real_usmilaid_avg*ydum`x'
}

gen USA_ln_income = ln(USA_rgdpch)

bysort risocode: egen ln_rgdpch_avg=mean(ln_rgdpch) if year>=1971 & year<=2006

forval x=1/36{
	gen gdp_y`x'=ln_rgdpch_avg*ydum`x'
}
gen oil_fadum_avg=oil_price_2011_USD*fadum_avg
gen US_income_fadum_avg=USA_ln_income*fadum_avg
gen US_democ_pres_fadum_avg=US_president_democ*fadum_avg

local baseline_controls "oil_fadum_avg US_income_fadum_avg US_democ_pres_fadum_avg gdp_y2-gdp_y36 usmil_y2-usmil_y36 usec_y2-usec_y36 rcereal_y2-rcereal_y36 rimport_y2-rimport_y36 all_Precip_jan-all_Precip_dec all_Temp_jan-all_Temp_dec all_Precip_jan_faavg-all_Precip_dec_faavg all_Temp_jan_faavg-all_Temp_dec_faavg"

/* Generating in-sample indicator so that all specifications have the same number of observations */
qui: xi: ivreg2 intra_state (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode)
gen in_sample=1 if e(sample)==1

/* Col 1: Intra: Collier and Hoefler (onset), drop all conflict that is not the first year */
preserve
drop if l_intra_state==1
xi: ivreg2 intra_state_onset (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid using "T7_onset_dur.xls", replace se noast nocons dec(5) adds(KP F-Stat, e(rkf))
** For sum stats **
sum intra_state_onset if e(sample)==1
restore

/* Col 2: Intra: Fearon and Laitin (onset) */
xi: ivreg2 intra_state_onset (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid using "T7_onset_dur.xls", append se noast nocons dec(5) adds(KP F-Stat, e(rkf))
** For sum stats **
sum intra_state_onset if e(sample)==1

*** Duration models: for conflict -> peace (offset) - using control function approach for IV ***
* Marginal effects are reported. These are not exported using outreg. To see these please look at the log file
local dur_controls "real_usmilaid_avg real_us_nonfoodaid_ecaid_avg recipient_pc_cereals_prod_avg cereal_pc_import_quantity_avg ln_rgdpch_avg"

/* Col 3: Duration: Only controlling for duration */
preserve
drop if l_intra_state==1	/* Only at risk of onset if last year were not at war */
gen peace_dur2=peace_dur*peace_dur
gen peace_dur3=peace_dur2*peace_dur
for @ in any `dur_controls': drop if missing(@)==1
xi: reg wheat_aid instrument peace_dur peace_dur2 peace_dur3 if missing(intra_state_onset)!=1, cluster(risocode)
test instrument
predict aid_hat if e(sample)==1, resid
xi: logit intra_state_onset wheat_aid aid_hat peace_dur peace_dur2 peace_dur3, cluster(risocode)
margins, dydx(wheat_aid) atmeans
restore

/* Col 4: Duration: Control for time invariant country characteristics */
preserve
drop if l_intra_state==1	/* Only at risk of onset if last year were not at war */
gen peace_dur2=peace_dur*peace_dur
gen peace_dur3=peace_dur2*peace_dur
xi: reg wheat_aid instrument peace_dur peace_dur2 peace_dur3 `dur_controls' if missing(intra_state_onset)!=1, cluster(risocode)
test instrument
predict aid_hat if e(sample)==1, resid
xi: logit intra_state_onset wheat_aid aid_hat peace_dur peace_dur2 peace_dur3 `dur_controls', cluster(risocode)
margins, dydx(wheat_aid) atmeans
restore

/* Col 5: Duration: Also add region FEs */
preserve
drop if l_intra_state==1	/* Only at risk of onset if last year were not at war */
gen peace_dur2=peace_dur*peace_dur
gen peace_dur3=peace_dur2*peace_dur
xi: reg wheat_aid instrument peace_dur peace_dur2 peace_dur3 `dur_controls' i.wb_region if missing(intra_state_onset)!=1, cluster(risocode)
test instrument
predict aid_hat if e(sample)==1, resid
xi: logit intra_state_onset wheat_aid aid_hat peace_dur peace_dur2 peace_dur3 `dur_controls' i.wb_region, cluster(risocode)
margins, dydx(wheat_aid) atmeans

** For sum stats **
sum intra_state_onset if e(sample)==1
restore

/* Col 6: Duration: Only controlling for duration */
preserve
drop if l_intra_state==0	/* Only at risk of offset if last year were at war */
gen intra_state_dur2=intra_state_dur*intra_state_dur
gen intra_state_dur3=intra_state_dur2*intra_state_dur
for @ in any `dur_controls': drop if missing(@)==1
xi: reg wheat_aid instrument intra_state_dur intra_state_dur2 intra_state_dur3 if missing(intra_state_offset)!=1, cluster(risocode)
test instrument
predict aid_hat if e(sample)==1, resid
xi: logit intra_state_offset wheat_aid aid_hat intra_state_dur intra_state_dur2 intra_state_dur3, cluster(risocode)
margins, dydx(wheat_aid) atmeans
restore

/* Col 7: Duration: Control for time invariant country characteristics */
preserve
drop if l_intra_state==0	/* Only at risk of offset if last year were at war */
gen intra_state_dur2=intra_state_dur*intra_state_dur
gen intra_state_dur3=intra_state_dur2*intra_state_dur
xi: reg wheat_aid instrument intra_state_dur intra_state_dur2 intra_state_dur3 `dur_controls' if missing(intra_state_offset)!=1, cluster(risocode)
test instrument
predict aid_hat if e(sample)==1, resid
xi: logit intra_state_offset wheat_aid aid_hat intra_state_dur intra_state_dur2 intra_state_dur3 `dur_controls', cluster(risocode)
margins, dydx(wheat_aid) atmeans
outreg2 wheat_aid using "T7_onset_dur.xls", append se noast nocons dec(5) margin
restore

/* Col 8: Duration: Also add region FEs */
preserve
drop if l_intra_state==0	/* Only at risk of offset if last year were at war */
gen intra_state_dur2=intra_state_dur*intra_state_dur
gen intra_state_dur3=intra_state_dur2*intra_state_dur
xi: reg wheat_aid instrument intra_state_dur intra_state_dur2 intra_state_dur3 `controls' i.wb_region if missing(intra_state_offset)!=1, cluster(risocode)
test instrument
predict aid_hat if e(sample)==1, resid
xi: logit intra_state_offset wheat_aid aid_hat intra_state_dur intra_state_dur2 intra_state_dur3 `dur_controls' i.wb_region, cluster(risocode)
margins, dydx(wheat_aid) atmeans
outreg2 wheat_aid using "T7_onset_dur.xls", append se noast nocons dec(5) margin

** For sum stats **
sum intra_state_offset if e(sample)==1
restore


*******************************
*** TABLE 8: Size Estimates ***
*******************************
use "in_sample.dta", clear

qui: xi: ivreg any_war (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode)
gen in_sample=1 if e(sample)==1

/* Column 1. Small any war */
gen small_any_war=.
replace small_any_war=0 if any_war==0
replace small_any_war=1 if any_war==1 & intensity==1
replace small_any_war=0 if any_war==1 & intensity==2
xi: ivreg2 small_any_war (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid  using "T8_Size_estimates.xls", replace se noast nocons lab dec(5) ctitle("Small any war") adds(KP F-Stat, e(rkf))

/* Column 2. Small civil war */
gen small_civil_war=.
replace small_civil_war=0 if intra_state==0
replace small_civil_war=1 if intra_state==1 & intensity==1
replace small_civil_war=0 if intra_state==1 & intensity==2
xi: ivreg2 small_civil_war (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
outreg2 wheat_aid  using "T8_Size_estimates.xls", append se noast nocons lab dec(5) ctitle("Small intra state") adds(KP F-Stat, e(rkf))

/* Column 3. Small inter-state war */
gen small_inter_state_war=.
replace small_inter_state_war=0 if inter_state==0
replace small_inter_state_war=1 if inter_state==1 & intensity==1
replace small_inter_state_war=0 if inter_state==1 & intensity==2
xi: ivreg2 small_inter_state_war (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid  using "T8_Size_estimates.xls", append se noast nocons lab dec(5) ctitle("Small inter state") adds(KP F-Stat, e(rkf))

/* Column 4. Big any war */
gen big_any_war=.
replace big_any_war=0 if any_war==0
replace big_any_war=0 if any_war==1 & intensity==1
replace big_any_war=1 if any_war==1 & intensity==2
xi: ivreg2 big_any_war (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
outreg2 wheat_aid  using "T8_Size_estimates.xls", append se noast nocons lab dec(5) ctitle("Big any war") adds(KP F-Stat, e(rkf))

/* Column 5. Big civil war */
gen big_civil_war=.
replace big_civil_war=0 if intra_state==0
replace big_civil_war=0 if intra_state==1 & intensity==1
replace big_civil_war=1 if intra_state==1 & intensity==2
xi: ivreg2 big_civil_war (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid  using "T8_Size_estimates.xls", append se noast nocons lab dec(5) ctitle("Big intra state") adds(KP F-Stat, e(rkf))

/* Column 6. Big inter-state war */
gen big_inter_state_war=.
replace big_inter_state_war=0 if inter_state==0
replace big_inter_state_war=0 if inter_state==1 & intensity==1
replace big_inter_state_war=1 if inter_state==1 & intensity==2
xi: ivreg2 big_inter_state_war (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid  using "T8_Size_estimates.xls", append se noast nocons lab dec(5) ctitle("Big inter state") adds(KP F-Stat, e(rkf))

/* Summary statistics - for means reported in the table */
sum small_any_war small_civil_war small_inter_state_war big_any_war big_civil_war big_inter_state_war if in_sample==1


******************************
*** TABLE 9: AID CROWD OUT ***
******************************

use "in_sample.dta", clear

xi: ivreg2 intra_state (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode)
gen in_sample=1 if e(sample)==1

/* Filling in missing just in case */
for @ in any world_wheat_aid world_cereals_aid non_US_wheat_aid non_US_cereals_aid real_usmilaid real_us_nonfoodaid_ecaid non_us_oda_net non_us_oda_net2: replace @=0 if missing(@)==1 & in_sample==1

* Column 1
xi: ivreg2 world_wheat_aid (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid using "T9_aid_crowdout.xls", replace se noast nocons lab ctitle("tot_wheat_aid") adds(KP F-Stat, e(rkf))
* Column 2-8
foreach x of varlist /*world_wheat_aid*/ world_cereals_aid non_US_wheat_aid non_US_cereals_aid real_usmilaid real_us_nonfoodaid_ecaid non_us_oda_net non_us_oda_net2{
	xi: ivreg2 `x' (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if in_sample==1, cluster(risocode) ffirst
	outreg2 wheat_aid using "T9_aid_crowdout.xls", append se noast nocons lab  ctitle("`x'") adds(KP F-Stat, e(rkf))
}

/* Getting means of variables */
sum wheat_aid world_wheat_aid world_cereals_aid non_US_wheat_aid non_US_cereals_aid real_usmilaid real_us_nonfoodaid_ecaid non_us_oda_net non_us_oda_net2 if in_sample==1


*********************************************************
*** TABLE 10: IMPACTS ON DOMESTIC PRODUCTION & PRICES ***
*********************************************************
use "in_sample.dta", clear

*** Wheat production as the dependent variable ****
xi: ivreg2 recipient_wheat_prod (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
outreg2 wheat_aid  using "T10_Prices_and_production.xls", replace se noast nocons lab dec(5) ctitle(wheat production) adds(KP F-Stat, e(rkf))
sum recipient_wheat_prod if e(sample)==1

*** Cereal production as the dependent variable ****
xi: ivreg2 recipient_cereals_prod (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
outreg2 wheat_aid  using "T10_Prices_and_production.xls", append se noast nocons lab dec(5) ctitle(cereal production) adds(KP F-Stat, e(rkf))
sum recipient_cereals_prod if e(sample)==1

*** Price as the dependent variable ****
/* Windsorizing the price data */
preserve
sum wheat_price_xrat_US_curr, detail
replace wheat_price_xrat_US_curr=1000 if wheat_price_xrat_US_curr>1000 & missing(wheat_price_xrat_US_curr)!=1
xi: ivreg2 wheat_price_xrat_US_curr (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
outreg2 wheat_aid  using "T10_Prices_and_production.xls", append se noast nocons lab dec(5) ctitle(wheat price) adds(KP F-Stat, e(rkf))
sum wheat_price_xrat_US_curr if e(sample)==1
restore

/* Log wheat price */
preserve
for @ in any wheat_price_xrat_US_curr: gen ln_@=ln(@)
xi: ivreg2 ln_wheat_price_xrat_US_curr (wheat_aid=instrument) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
outreg2 wheat_aid  using "T10_Prices_and_production.xls", append se noast nocons lab dec(5) ctitle(ln wheat price) adds(KP F-Stat, e(rkf))
sum ln_wheat_price_xrat_US_curr if e(sample)==1
restore


**********************************************************
*** TABLE 11: Heterogeneity Regressions: Past Conflict ***
**********************************************************
/* Cannot use the "in_sample" dataset because we needs observations from earlier time periods to construct lagged conflict */
use "FAid_Final.dta", clear
tsset obs year

/* Converting wheat aid measure & production to thousands of tonnes - coefficients are easier to read */
replace wheat_aid=wheat_aid/1000
replace US_wheat_production=US_wheat_production/1000
replace recipient_wheat_prod=recipient_wheat_prod/1000
replace recipient_cereals_prod=recipient_cereals_prod/1000
replace real_usmilaid=real_usmilaid/1000
replace real_us_nonfoodaid_ecaid=real_us_nonfoodaid_ecaid/1000

/* Creating all instruments */
gen instrument=l.US_wheat_production*fadum_avg
la var instrument "Baseline interaction instrument: US wheat prod (t-1) x avg food aid prob (1971-2006)"

gen instrument2=l.US_wheat_production
la var instrument2 "Alternative unteracted instrument: US wheat production (t-1)"

/* Creating controls */
foreach x of varlist all_Precip_jan-all_Precip_dec all_Temp_jan-all_Temp_dec{
	drop `x'_faavg
	gen `x'_faavg=`x'*fadum_avg
}

gen USA_ln_income = ln(USA_rgdpch)
bysort risocode: egen ln_rgdpch_avg=mean(ln_rgdpch) if year>=1971 & year<=2006

gen oil_fadum_avg=oil_price_2011_USD*fadum_avg
gen US_income_fadum_avg=USA_ln_income*fadum_avg
gen US_democ_pres_fadum_avg=US_president_democ*fadum_avg

/* Creating new set of baseline controls - just the coding is a little different: using Stata to create fixed effects on the fly */
local baseline_controls3 "oil_fadum_avg US_income_fadum_avg US_democ_pres_fadum_avg i.year*ln_rgdpch_avg i.year*real_usmilaid_avg i.year*real_us_nonfoodaid_ecaid_avg i.year*recipient_pc_cereals_prod_avg i.year*cereal_pc_import_quantity_avg all_Precip_jan-all_Precip_dec all_Temp_jan-all_Temp_dec all_Precip_jan_faavg-all_Precip_dec_faavg all_Temp_jan_faavg-all_Temp_dec_faavg"

/* Baseline regression with smaller sample */
preserve
tsset obs year
for # in numlist 1/20: gen l#_intra_state=l#.intra_state
egen xx=rowmax(l1_intra_state l2_intra_state l3_intra_state l4_intra_state l5_intra_state l6_intra_state l7_intra_state l8_intra_state l9_intra_state l10_intra_state l11_intra_state l12_intra_state l13_intra_state l14_intra_state l15_intra_state l16_intra_state l17_intra_state l18_intra_state l19_intra_state l20_intra_state) if year>=1971 & year<=2006
gen Pastconflict=1-xx
for # in numlist 1/20: drop l#_intra_state
gen wheat_aid_x_Pastconflict=wheat_aid*Pastconflict
tsset obs year
gen l_US_wheat_production_faavg_int1=instrument*Pastconflict
gen x1=fadum_avg*Pastconflict
gen x2=instrument2*Pastconflict
xi: ivreg intra_state (wheat_aid wheat_aid_x_Pastconflict = instrument l_US_wheat_production_faavg_int1 x2) x1 Pastconflict `baseline_controls3' i.risocode i.wb_region*i.year if year>=1971 & year<=2006, cluster(risocode)
gen in_sample=1 if e(sample)==1
xi: ivreg2 intra_state (wheat_aid=instrument) `baseline_controls3' i.risocode i.wb_region*i.year if in_sample==1, cluster(risocode) ffirst
outreg2 wheat_aid using "T11_hetero_past_conflict.xls", replace se noast nocons dec(5)
rivtest, ci level(90)
restore

/* No Conflict (past 20 years)*/
preserve
tsset obs year
for # in numlist 1/20: gen l#_intra_state=l#.intra_state
egen xx=rowmax(l1_intra_state l2_intra_state l3_intra_state l4_intra_state l5_intra_state l6_intra_state l7_intra_state l8_intra_state l9_intra_state l10_intra_state l11_intra_state l12_intra_state l13_intra_state l14_intra_state l15_intra_state l16_intra_state l17_intra_state l18_intra_state l19_intra_state l20_intra_state) if year>=1971 & year<=2006
gen Pastconflict=1-xx
for # in numlist 1/20: drop l#_intra_state
gen wheat_aid_x_Pastconflict=wheat_aid*Pastconflict
tsset obs year
gen l_US_wheat_production_faavg_int1=instrument*Pastconflict
gen x1=fadum_avg*Pastconflict
gen x2=instrument2*Pastconflict
xi: ivreg2 intra_state (wheat_aid wheat_aid_x_Pastconflict = instrument l_US_wheat_production_faavg_int1 x2) x1 Pastconflict `baseline_controls3' i.risocode i.wb_region*i.year if year>=1971 & year<=2006, cluster(risocode) ffirst
lincom wheat_aid + wheat_aid_x_Pastconflict
outreg2 wheat_aid wheat_aid_x_Pastconflict using "T11_hetero_past_conflict.xls", se noast nocons dec(5) adds(Joint_coeff, r(estimate), Joint_se, r(se)) ctitle(20yr conflict)
restore

/* No Conflict (past 15 years)*/
preserve
tsset obs year
for # in numlist 1/15: gen l#_intra_state=l#.intra_state
egen xx=rowmax(l1_intra_state l2_intra_state l3_intra_state l4_intra_state l5_intra_state l6_intra_state l7_intra_state l8_intra_state l9_intra_state l10_intra_state l11_intra_state l12_intra_state l13_intra_state l14_intra_state l15_intra_state) if year>=1971 & year<=2006
gen Pastconflict=1-xx
for # in numlist 1/15: drop l#_intra_state
gen wheat_aid_x_Pastconflict=wheat_aid*Pastconflict
tsset obs year
gen l_US_wheat_production_faavg_int1=instrument*Pastconflict
gen x1=fadum_avg*Pastconflict
gen x2=instrument2*Pastconflict
xi: ivreg2 intra_state (wheat_aid wheat_aid_x_Pastconflict = instrument l_US_wheat_production_faavg_int1 x2) x1 Pastconflict `baseline_controls3' i.risocode i.wb_region*i.year if year>=1971 & year<=2006, cluster(risocode) ffirst
lincom wheat_aid + wheat_aid_x_Pastconflict
outreg2 wheat_aid wheat_aid_x_Pastconflict using "T11_hetero_past_conflict.xls", se noast nocons dec(5) adds(Joint_coeff, r(estimate), Joint_se, r(se)) ctitle(15yr conflict)
restore

/* No Conflict (past 10 years)*/
preserve
tsset obs year
for # in numlist 1/10: gen l#_intra_state=l#.intra_state
egen xx=rowmax(l1_intra_state l2_intra_state l3_intra_state l4_intra_state l5_intra_state l6_intra_state l7_intra_state l8_intra_state l9_intra_state l10_intra_state) if year>=1971 & year<=2006
gen Pastconflict=1-xx
for # in numlist 1/10: drop l#_intra_state
gen wheat_aid_x_Pastconflict=wheat_aid*Pastconflict
tsset obs year
gen l_US_wheat_production_faavg_int1=instrument*Pastconflict
gen x1=fadum_avg*Pastconflict
gen x2=instrument2*Pastconflict
xi: ivreg2 intra_state (wheat_aid wheat_aid_x_Pastconflict = instrument l_US_wheat_production_faavg_int1 x2) x1 Pastconflict `baseline_controls3' i.risocode i.wb_region*i.year if year>=1971 & year<=2006, cluster(risocode) ffirst
lincom wheat_aid + wheat_aid_x_Pastconflict
outreg2 wheat_aid wheat_aid_x_Pastconflict using "T11_hetero_past_conflict.xls", se noast nocons dec(5) adds(Joint_coeff, r(estimate), Joint_se, r(se)) ctitle(10yr conflict)
restore

/* No Conflict (past 5 years)*/
preserve
tsset obs year
for # in numlist 1/5: gen l#_intra_state=l#.intra_state
egen xx=rowmax(l1_intra_state l2_intra_state l3_intra_state l4_intra_state l5_intra_state) if year>=1971 & year<=2006
gen Pastconflict=1-xx
for # in numlist 1/5: drop l#_intra_state
gen wheat_aid_x_Pastconflict=wheat_aid*Pastconflict
tsset obs year
gen l_US_wheat_production_faavg_int1=instrument*Pastconflict
gen x1=fadum_avg*Pastconflict
gen x2=instrument2*Pastconflict
xi: ivreg2 intra_state (wheat_aid wheat_aid_x_Pastconflict = instrument l_US_wheat_production_faavg_int1 x2) x1 Pastconflict `baseline_controls3' i.risocode i.wb_region*i.year if year>=1971 & year<=2006, cluster(risocode) ffirst
lincom wheat_aid + wheat_aid_x_Pastconflict
outreg2 wheat_aid wheat_aid_x_Pastconflict using "T11_hetero_past_conflict.xls", se noast nocons dec(5) adds(Joint_coeff, r(estimate), Joint_se, r(se)) ctitle(5yr conflict)
restore

********************************************************************
*** TABLE 12: Heterogeneity Regressions: Country Characteristics ***
********************************************************************
use "in_sample.dta", clear

/* Baseline */
xi: ivreg2 intra_state (wheat_aid=instrument) `baseline_controls' i.risocode i.wb_region*i.year if year>=1971 & year<=2006, cluster(risocode) ffirst
outreg2 wheat_aid using "T12_hetero.xls", replace se noast nocons dec(5)

/* High Average Income */
bysort risocode: egen rgdpch_avg=mean(rgdpch) if year>=1971 & year<=2006
sum rgdpch_avg if year==2000, detail
gen HighIncome=.
replace HighIncome=0 if rgdpch_avg<3801.282
replace HighIncome=1 if rgdpch_avg>=3801.282 & missing(rgdpch_avg)!=1
gen wheat_aid_x_HighIncome=wheat_aid*HighIncome
tsset obs year
gen l_US_wheat_production_faavg_int1=instrument*HighIncome
gen x1=instrument2*HighIncome

xi: ivreg2 intra_state (wheat_aid wheat_aid_x_HighIncome = instrument l_US_wheat_production_faavg_int1 x1) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
lincom wheat_aid + wheat_aid_x_HighIncome
outreg2 wheat_aid wheat_aid_x_HighIncome using "T12_hetero.xls", append se noast nocons dec(5) adds(Joint_coeff, r(estimate), Joint_se, r(se))

/* High Resource Dependence */
bysort risocode: egen resource_share_GDP_avg=mean(resource_share_GDP) if year>=1971 & year<=2006
sum resource_share_GDP_avg if year==2000, detail
gen HighResource=.
replace HighResource=0 if resource_share_GDP_avg<4.953968
replace HighResource=1 if resource_share_GDP_avg>=4.953968 & missing(resource_share_GDP_avg)!=1
gen wheat_aid_x_HighResource=wheat_aid*HighResource
tsset obs year
gen l_US_wheat_production_faavg_int2=instrument*HighResource
gen x2=instrument2*HighResource

xi: ivreg2 intra_state (wheat_aid wheat_aid_x_HighResource = instrument l_US_wheat_production_faavg_int2 x2) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
lincom wheat_aid + wheat_aid_x_HighResource
outreg2 wheat_aid wheat_aid_x_HighResource using "T12_hetero.xls", append se noast nocons dec(5) adds(Joint_coeff, r(estimate), Joint_se, r(se))

/* High Polity2 */
bysort risocode: egen polity2_avg=mean(polity2_from_P4) if year>=1971 & year<=2006
sum polity2_avg if year==2000, detail
gen HighPolity=.
replace HighPolity=0 if polity2_avg<=-1.833333
replace HighPolity=1 if polity2_avg>-1.833333 & missing(polity2_avg)!=1
sum HighPolity, detail
gen wheat_aid_x_HighPolity=wheat_aid*HighPolity
tsset obs year
gen l_US_wheat_production_faavg_int3=instrument*HighPolity
gen x3=instrument2*HighPolity

xi: ivreg2 intra_state (wheat_aid wheat_aid_x_HighPolity = instrument l_US_wheat_production_faavg_int3 x3) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
lincom wheat_aid + wheat_aid_x_HighPolity
outreg2 wheat_aid wheat_aid_x_HighPolity using "T12_hetero.xls", append se noast nocons dec(5) adds(Joint_coeff, r(estimate), Joint_se, r(se))

/* EPR: Ethnic polarization #1 */
bysort risocode: egen polrqnew_avg=mean(polrqnew) if year>=1971 & year<=2006
sum polrqnew_avg if year==2000, detail
gen LowEPOL=.
replace LowEPOL=0 if polrqnew_avg>.7364611 & missing(polrqnew_avg)!=1
replace LowEPOL=1 if polrqnew_avg<=.7364611
gen wheat_aid_x_LowEPOL=wheat_aid*LowEPOL
tsset obs year
gen l_US_wheat_production_faavg_int4=instrument*LowEPOL
*gen x1=fadum_avg*LowEPOL
gen x4=instrument2*LowEPOL

xi: ivreg2 intra_state (wheat_aid wheat_aid_x_LowEPOL = instrument l_US_wheat_production_faavg_int4 x4) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
lincom wheat_aid + wheat_aid_x_LowEPOL
outreg2 wheat_aid wheat_aid_x_LowEPOL using "T12_hetero.xls", append se noast nocons dec(5) adds(Joint_coeff, r(estimate), Joint_se, r(se))

/* Low ethnic diversity (Alesina's measure)*/
sum alesina_ethnic if year==2000, detail
gen LowEthnic=.
replace LowEthnic=1 if alesina_ethnic<.5416
replace LowEthnic=0 if alesina_ethnic>=.5416 & missing(alesina_ethnic)!=1
sum LowEthnic, detail
gen wheat_aid_x_LowEthnic=wheat_aid*LowEthnic
tsset obs year
gen l_US_wheat_production_faavg_int5=instrument*LowEthnic
*gen x1=fadum_avg*LowEthnic
gen x5=instrument2*LowEthnic

xi: ivreg2 intra_state (wheat_aid wheat_aid_x_LowEthnic = instrument l_US_wheat_production_faavg_int5 x5) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
lincom wheat_aid + wheat_aid_x_LowEthnic
outreg2 wheat_aid wheat_aid_x_LowEthnic using "T12_hetero.xls", append se noast nocons dec(5) adds(Joint_coeff, r(estimate), Joint_se, r(se))

/* Ethnic controls only */
xi: ivreg2 intra_state (wheat_aid wheat_aid_x_LowEPOL wheat_aid_x_LowEthnic = instrument l_US_wheat_production_faavg_int4-l_US_wheat_production_faavg_int5 x4-x5) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
lincom wheat_aid + wheat_aid_x_LowEthnic + wheat_aid_x_LowEPOL
outreg2 wheat_aid wheat_aid_x_LowEPOL wheat_aid_x_LowEthnic using "T12_hetero.xls", append se noast nocons dec(5) adds(Joint_coeff, r(estimate), Joint_se, r(se))


*******************************************************************
*** TABLE 13: Heterogeneity Regressions: Understanding Channels ***
*******************************************************************

use "in_sample.dta", clear

/* Baseline */
xi: ivreg2 intra_state (wheat_aid=instrument) `baseline_controls' i.risocode i.wb_region*i.year if year>=1971 & year<=2006, cluster(risocode) ffirst
outreg2 wheat_aid using "T13_hetero_channels.xls", replace se noast nocons dec(5)

/* Low (per capita) cereal-production countries */
sum recipient_pc_cereals_prod_avg if year==2000, detail
gen LowCereals=.
replace LowCereals=0 if recipient_pc_cereals_prod_avg>.1371454
replace LowCereals=1 if recipient_pc_cereals_prod_avg<=.1371454 & missing(recipient_pc_cereals_prod_avg)!=1
gen wheat_aid_x_LowCereals=wheat_aid*LowCereals
tsset obs year
gen l_US_wheat_production_faavg_int1=instrument*LowCereals
gen x1=instrument2*LowCereals

xi: ivreg2 intra_state (wheat_aid wheat_aid_x_LowCereals = instrument l_US_wheat_production_faavg_int1 x1) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
lincom wheat_aid + wheat_aid_x_LowCereals
outreg2 wheat_aid wheat_aid_x_LowCereals using "T13_hetero_channels.xls", se noast nocons dec(5) adds(Joint_coeff, r(estimate), Joint_se, r(se))

/* Years of low (per-capita) cereal production */
gen pc_cereal_prod=recipient_cereals_prod/total_population
bysort risocode: egen pc_cereal_prod_avg=mean(pc_cereal_prod) if year>=1971 & year<=2006
sum pc_cereal_prod_avg if year==2000, detail
gen Below_mean_prod=.
replace Below_mean_prod=0 if pc_cereal_prod>=pc_cereal_prod_avg & missing(pc_cereal_prod)!=1 & missing(pc_cereal_prod_avg)!=1
replace Below_mean_prod=1 if pc_cereal_prod<pc_cereal_prod_avg & missing(pc_cereal_prod)!=1 & missing(pc_cereal_prod_avg)!=1
gen wheat_aid_x_Below_mean_prod=wheat_aid*Below_mean_prod
tsset obs year
gen l_US_wheat_production_faavg_int2=instrument*Below_mean_prod
gen x2=instrument2*Below_mean_prod

xi: ivreg2 intra_state (wheat_aid wheat_aid_x_Below_mean_prod = instrument l_US_wheat_production_faavg_int2 x2) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
lincom wheat_aid + wheat_aid_x_Below_mean_prod
outreg2 wheat_aid wheat_aid_x_Below_mean_prod using "T13_hetero_channels.xls", append se noast nocons dec(5) adds(Joint_coeff, r(estimate), Joint_se, r(se))

/* High density of roads (normalized by per capita) */
bysort risocode: egen roads_per_capita_avg=mean(roads_per_capita) if year>=1971 & year<=2006
sum roads_per_capita_avg if year==2000, detail
gen Road=.
replace Road=1 if roads_per_capita_avg>.003408 & missing(roads_per_capita_avg)!=1
replace Road=0 if roads_per_capita_avg<=.003408
gen wheat_aid_x_Road=wheat_aid*Road
tsset obs year
gen l_US_wheat_production_faavg_int3=instrument*Road
gen x3=instrument2*Road

xi: ivreg2 intra_state (wheat_aid wheat_aid_x_Road = instrument l_US_wheat_production_faavg_int3 x3) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
lincom wheat_aid + wheat_aid_x_Road
outreg2 wheat_aid wheat_aid_x_Road using "T13_hetero_channels.xls", se noast nocons dec(5) adds(Joint_coeff, r(estimate), Joint_se, r(se))

/* Heterogeneity: Cold War */
gen CW=.
replace CW=0 if year<=1947 | year>=1991 & missing(year)!=1
replace CW=1 if year>1947 & year<1991
gen wheat_aid_x_CW=wheat_aid*CW
tsset obs year
gen l_US_wheat_production_faavg_int4=instrument*CW
gen x4=fadum_avg*CW

xi: ivreg2 intra_state (wheat_aid wheat_aid_x_CW = instrument l_US_wheat_production_faavg_int4 x4) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
lincom wheat_aid + wheat_aid_x_CW
outreg2 wheat_aid wheat_aid_x_CW using "T13_hetero_channels.xls", se noast nocons dec(5) adds(Joint_coeff, r(estimate), Joint_se, r(se))

/* Aligned with the USA */
bysort risocode: egen s2unUSA_avg=mean(s2unUSA) if year>=1971 & year<=2006
sum s2unUSA_avg if year==2000, detail
gen Align=.
replace Align=1 if s2unUSA_avg>.5672459 & missing(s2unUSA_avg)!=1
replace Align=0 if s2unUSA_avg<=.5672459
sum Align, detail
gen wheat_aid_x_Align=wheat_aid*Align
tsset obs year
gen l_US_wheat_production_faavg_int5=instrument*Align
gen x5=instrument2*Align

xi: ivreg2 intra_state (wheat_aid wheat_aid_x_Align = instrument l_US_wheat_production_faavg_int5 x5) `baseline_controls' i.risocode i.year*i.wb_region if year>=1971 & year<=2006, cluster(risocode) ffirst
lincom wheat_aid + wheat_aid_x_Align
outreg2 wheat_aid wheat_aid_x_Align using "T13_hetero_channels.xls", append se noast nocons dec(5) adds(Joint_coeff, r(estimate), Joint_se, r(se))

log close
