/*************************************************
191211bbgbdata
this code downloads the data of campbell and
vuolteenaho (2004) from aea
*************************************************/

/*filename a "%sysfunc(getoption(work))\a";*/

/*proc http out=a url="http://www.aeaweb.org/aer/data/dec04_data_campbell.zip";*/
/*run;*/

/*filename a zip "%sysfunc(getoption(work))\a";*/
filename b "%sysfunc(getoption(work))\b";
proc http url="https://raw.githubusercontent.com/junyongkim/misc/master/sas/191211bbgbdata/191226BBGBdata.xls" out=b;run;
/*data _null_;*/
/*	infile a(BBGBdata.xls) eof=e recfm=f;*/
/*	file b recfm=n;*/
/*	input;*/
/*	put _infile_;*/
/*	return;*/
/*	e:stop;*/
/*run;*/

proc import file=b dbms=xls out=bbgbdata replace;
	sheet="monthly";
run;

proc transpose out=bbgbdata;
	by date;
	var _all_;
run;

data bbgbdata;
	set bbgbdata;
	_name_=lowcase(_name_);
	if _name_="r_me" then _name_="rm";
	if _name_="et_r_me_" then _name_="erm";
	if _name_="_n_dr" then _name_="ndr";
	if _name_="n_cf" then _name_="ncf";
	if _name_="rrf" then _name_="rf";
	if substr(_name_,1,2)="ff" then _name_="f"||substr(_name_,4,1)||substr(_name_,7,1);
	if substr(_name_,1,4)="risk" then _name_="k"||put(input(substr(_name_,5,2),2.),z2.);
	if col1^="NaN" then col2=input(col1,16.);
run;

proc transpose data=bbgbdata(drop=_label_ rename=(date=d)) out=bbgbdata(drop=d _name_);
	by d;
	var col2;
run;

quit;
