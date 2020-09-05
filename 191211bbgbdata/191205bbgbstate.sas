/*************************************************
191205bbgbstate
downloads the four var state variables used in
campbell and vuolteenaho (2004)
*************************************************/

/*campbell and vuolteenaho (2004) data*/

/*filename a "%sysfunc(getoption(work))\a";*/

/*proc http method="get" out=a*/
/*	url="http://www.aeaweb.org/aer/data/dec04_data_campbell.zip";*/
/*run;*/

/*filename a zip "%sysfunc(getoption(work))\a";*/
filename b "%sysfunc(getoption(work))\b";proc http url="http://mindhunter.dothome.co.kr/BBGBdata.xls" out=b;run;

/*data _null_;*/
/*	infile a(BBGBdata.xls) eof=_ recfm=f;*/
/*	file b recfm=n;*/
/*	input;*/
/*	put _infile_;*/
/*	return;*/
/*	_:stop;*/
/*run;*/

proc import file=b dbms=xls out=_01 replace;
	sheet="Monthly";
run;

proc transpose out=_01;
	by date;
	var _all_;
run;

data _01;
	set _01;
	rename date=_;
	_name_=lowcase(_name_);
	if col1 ne "NaN" then col2=input(col1,16.);
run;

proc transpose out=_01(drop=_ _name_);
	by _;
	var col2;
run;

/*rme from french*/

filename a "%sysfunc(getoption(work))\a";

proc http method="get" out=a
	url="http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_CSV.zip";
run;

filename a zip "%sysfunc(getoption(work))\a";

data _02;
	infile a(F-F_Research_Data_Factors.CSV) dsd truncover;
	input time mktrf smb hml rf;
	if time<lag(time) then _+1;
	if time>0;
run;

/*ty from fred*/

filename a "%sysfunc(getoption(work))\a";

%macro http(url,data);

proc http method="get" out=a
	url="http://fred.stlouisfed.org/graph/fredgraph.csv?id=&url.";
run;

data &data.;
	infile a dsd truncover;
	input time yymmdd10. +1 &url.;
	time=input(put(time,yymmn6.),6.);
	if time>0;
run;

%mend;

%http(gs10,_03);
%http(gs3,_04);
%http(gs1,_05);

/*pe from shiller*/

proc http method="get" out=a
	url="http://www.econ.yale.edu/~shiller/data/ie_data.xls";
run;

proc import file=a dbms=xls out=_06 replace;
	sheet="Data";
run;

proc transpose out=_06;
	where substr(a,1,1) in ("1","2");
	by a;
	var _all_;
run;

data _06;
	set _06;
	time=input(a,16.)*100;
	if col1 not in ("",".","NA") then col2=input(col1,16.);
run;

proc transpose out=_06(drop=a _name_);
	by time;
	var col2;
run;

/*vs from french*/

filename a "%sysfunc(getoption(work))\a";

proc http method="get" out=a
	url="http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/6_Portfolios_2x3_CSV.zip";
run;

filename a zip "%sysfunc(getoption(work))\a";

data _07;
	infile a(6_Portfolios_2x3.CSV) dsd truncover;
	input time sl sm sh bl bm bh;
	if time<lag(time) then _+1;
	if time>0;
run;

/*collect*/

data _08;
	merge _01(rename=(date=time r_me=rme0 ty=ty0 pe=pe0 vs=vs0))
		_02(where=(_=0))
		_03
		_04
		_05
		_06
		_07(keep=time _ sl sh rename=(sl=sl_ sh=sh_) where=(_=7))
		_07(where=(_=0));
	by time;
	rme=log(1+mktrf/100);
	ty=gs10-mean(gs3,gs1);
	pe=log(m);
	retain vs;
	if mod(time,100)=7 then vs=log(sh_/sl_);
	vs=vs+log(1+sl/100)-log(1+sh/100);
	time2=input(put(time,6.),yymmn6.);
run;

data bbgbstate;
	set _08;
	where rme+ty+pe+vs>.;
	keep time rme ty pe vs;
run;

/*delete*/

proc delete data=_01-_08;
run;

quit;
