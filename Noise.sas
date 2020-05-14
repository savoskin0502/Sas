DATA nois;
    SET noise;
    id+1;
RUN;
/* Build the graph */
proc plot data=nois;
	plot soundLevel*id='*';
run;
ods graphics off;
title 'Scaled Sound Pressure Level';
proc univariate data=noise noprint;
   histogram soundLevel;
run;
/* Now we see that we work with normal distribution, so it's not need to rebuild our model */
/* Additionally let's see on the scatter(dispersion), min, max and mean, for better
	representing the model*/
proc means data = nois n mean var min max; 
	var frequency angle chord velocity suction soundLevel;
run;

/* We know that there are some assumption in LRM, which we must stick to,
	one of the assumption is that there is no collinearity/multicollinearity 
	in the model, if we have col. in the model our t and F tests can't describe
	our model fully->there will be errors in assumption->can be statistically significant
	->our model can be better for the reason of higher r and adjusted r square;
	other assumption is variables is independent, so let's test col in the model*/
	
proc reg data=nois plots=all;
    model soundLevel=frequency angle chord velocity suction/vif;
run;
/* We see that there can be collinearity in the model based on the results, 
	Variance inflation factor of the angle is about ~3.5, which is not so good,
	but can be better, so let's delete and check again without angle*/

proc reg data=nois plots=all;
    model soundLevel=frequency chord velocity suction/vif;
run;
/* Based on the result i can surely said that there was multicollinearity in the model,
	now there no such varianca inflation with number more than 1.12, and now we can continue*/

/* Let's build our model */
proc genmod data=nois;
	model soundLevel=frequency chord velocity suction/dist=normal;
run;

/* It's amazing, all variables(excepting collinearity variables), are
	statistically significant, but let's check that our model is described fully by that model*/
/* We know that within deviance parameter and chi_square statistics we can identify,
	is our parameters described our model good */
data test; 
  pval = 1 - probchi(1503.0000,1497);
run;
	
proc print data = test;
run;
/* From the test we see that there is not statistically significant value,
	assumption in our test was that model is good, alternate bad, value is nonstat. signif.->
	model is good*/

/* Final model is that: soundLevel = 130.3502 - 0.0012*frequency - 25.9729*chord +
	+ 0.0869*velocity - 269.155*suction; */
	
/* We don't have categorical values in the model, so we can run proc reg except genmod,
	 */
proc reg data=nois;
	model soundLevel=frequency chord velocity suction;
run;
/* And we see that Results the same*/
/* Build our model for forecasting, assume that we predict soundLevel, see results on graphs  */
proc arima data=nois;
   identify var=soundLevel scan;
run;

/* We can't work with our data without time, so let's add time for day parameter */

data withTime;
	id+1;
	set nois;
run;

proc sql;
	create table byDay as
	Select soundLevel,id  id From withTime;
RUN;

/* Build table with week interval */
proc sql;
	create table byWeek as
	Select soundLevel From withTime 
	Where MOD(id,7)=0;
RUN;
data byWeekTime;
	id+1;
	set byWeek;
run;

/* Build table with month parameter */
proc sql;
	create table byMonth as
	Select soundLevel From withTime 
	Where MOD(id,30)=0;
RUN;
data byMonthTime;
	id+1;
	set byMonth;
run;

/* Build table with quart paramter */
proc sql;
	create table byQuart as
	Select soundLevel From withTime 
	Where MOD(id,90)=0;
RUN;
data byQuartTime;
	id+1;
	set byQuart;
run;
/* All datasets is ready to be used, so let's see on our forecasting, in that forecasting 
	we will used maximum likelihood method to evaluate our model */
ods graphics;
PROC VARMAX data=byDay plot=forecasts(all); 
	id id interval=day;
	model soundLevel/method=ml;
	output out=out lead=1200;
run;
ods graphics off;
/* Based on the result i can said the next: some values of autocorrelation and
 moving average coefficients is ~ to 1, so it can be better to use model with the difference
 in most of datasets it can be enough if we use dif(1), let's start with that
	 */

ods graphics;
PROC VARMAX data=byDay plot=forecasts(all); 
	id id interval=day;
	model soundLevel/method=ml dif=(soundLevel(1));
	output out=out lead=1200;
run;
ods graphics off;
/* dif 1 is'nt enough, add 1 more */
ods graphics;
PROC VARMAX data=byDay plot=forecasts(all); 
	id id interval=day;
	model soundLevel/method=ml  dif=(soundLevel(2));
	output out=out lead=1200;
run;
ods graphics off;
/* Now all is ok with our ar and ma parameters, and std error variate small, and in our
	case we see that now don't need any additional p and q parameters */

/* Down is for forecasting by week */

ods graphics;
PROC VARMAX data=byWeekTime plot=forecasts(all); 
	id id interval=week;
	model soundLevel/method=ml ;
	output out=out lead=200;
run;
ods graphics off;
/* Model are not sensitive->bad->ar is strange->let's fix */
ods graphics;
PROC VARMAX data=byWeekTime plot=forecasts(all); 
	id id interval=day;
	model soundLevel/method=ml dif=(soundLevel(2));
	output out=out lead=200;
run;
ods graphics off;
/* Again take dif which will enough and make our model sensitive*/
/* Model said us to take p=3 and q=3(based on statistically significance level) */
ods graphics;
PROC VARMAX data=byWeekTime plot=forecasts(all); 
	id id interval=day;
	model soundLevel/method=ml dif=(soundLevel(2)) minic=(type=sbc p=3 q=3);
	output out=out lead=200;
run;
ods graphics off;
/* All is good :), results in the table, forecasting for 4 year */
/* Again see */
ods graphics;
PROC VARMAX data=byMonthTime plot=forecasts(all); 
	id id interval=day;
	model soundLevel/method=ml;
	output out=out lead=48;
run;
ods graphics off;
/* Again make sens */
ods graphics;
PROC VARMAX data=byMonthTime plot=forecasts(all); 
	id id interval=day;
	model soundLevel/method=ml dif=(soundLevel(2));
	output out=out lead=48;
run;
ods graphics off;
/* And again choose the best */

ods graphics;
PROC VARMAX data=byMonthTime plot=forecasts(all); 
	id id interval=day;
	model soundLevel/method=ml dif=(soundLevel(2)) minic=(type=sbc p=2 q=0);
	output out=out lead=48;
run;
ods graphics off;