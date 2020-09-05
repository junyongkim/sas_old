/*************************************************
191229worldbank
enables to download worldbank's data
*************************************************/

%macro worldbank(name,code);

%let name=%upcase(&name.);

filename a "%sysfunc(getoption(work))\a";

proc http out=a url="http://api.worldbank.org/v2/en/indicator/&name.?downloadformat=csv";
run;

filename a zip "%sysfunc(getoption(work))\a";
filename b "%sysfunc(getoption(work))\b";
filename c "%sysfunc(getoption(work))\c";

data _null_;
	infile a(API_&name._DS2_en_csv_v2_&code..csv) eof=e recfm=f;
	file b recfm=n;
	input;
	put _infile_;
	return;
	e:stop;
run;

%let name=%sysfunc(tranwrd(&name.,.,_));

data _null_;
	infile b firstobs=5;
	file c;
	input;
	put _infile_;
run;

proc import file=c dbms=csv out=&name. replace;
run;

proc transpose out=&name.;
	by Country_Code Country_Name Indicator_Name;
	id Indicator_Code;
	var _:;
run;

data &name.;
	set &name.;
	Year=input(substr(_NAME_,2),4.);
	_=input(&name.,16.);
	drop _NAME_ &name.;
	rename _=&name.;
	if &name.>.;
run;

%mend;

quit;
