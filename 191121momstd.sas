/*************************************************
191121momstd
computes 12-month moving average of monthly daily
return standard deviation and plots it with some
shading methods - nber, daniel and moskowitz, and
drawdowns and recoveries from john
*************************************************/

resetline;
dm"log;clear;output;clear;";
option nodate nonumber nolabel ls=128 ps=max;

proc datasets kill nolist;
run;

/*download from ken*/

filename _ "%sysfunc(getoption(work))\_.zip";

proc http method="get" out=_
	url="https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/10_portfolios_prior_12_2_daily_csv.zip";
run;

filename _ zip "%sysfunc(getoption(work))\_.zip";

data mom(drop=i);
	infile _(10_Portfolios_Prior_12_2_Daily.CSV) dsd;
	input day p01-p10;
	if day<lag(day) then i+1;
	if i=0 and day>0;
run;

proc transpose out=mom;
	by day;
	var p:;
run;

proc sql;
	create table mom as
		select day as month,_name_ as name_,std(col1)*sqrt(252) as sigma
		from mom
		group by int(month/100),name_
		having month=max(month)
		order by name_,month;
quit;

/*compute moving averages*/

%macro mom(lag);

data mom(drop=sigma1-sigma&lag.);
	set mom;
	%do i=1 %to &lag.;
	sigma&i.=ifn(name_=lag&i.(name_),lag&i.(sigma),.);
	%end;
	if name_=lag&lag.(name_) then sigma_=mean(of sigma1-sigma&lag.);
	if sigma_>.;
	month_=intnx("month",input(put(month,8.),yymmdd8.),0,"e");
run;

%mend;

%mom(11);

data _1(drop=_:);
	merge mom(where=(name_="p01") rename=(sigma_=_1))
		mom(where=(name_="p10") rename=(sigma_=_2));
	by month;
	name_="p10-p01";
	sigma_=_2-_1;
run;

proc append base=mom;
run;

proc sql noprint;
	select min(month_),max(month_)
		into :min trimmed,:max trimmed
		from mom;
quit;

/*download from fred website*/

filename _ "%sysfunc(getoption(work))\_.csv";

proc http method="get" out=_
	url="https://fred.stlouisfed.org/graph/fredgraph.csv?id=usrec";
run;

data nber;
	infile _ firstobs=2;
	input month yymmdd10. +1 rec;
	if rec=1;
run;

data nber;
	set nber;
	where &min.<=month<=&max. and rec=1;
	layer="front";
	x1space="datavalue";
	y1space="wallpercent";
	display="fill";
	fillcolor="black";
	filltransparency=0.9;
	function="polygon ";
	x1=month;
	y1=0;
	output;
	function="polycont";
	y1=100;
	output;
	function="polycont";
	x1=intnx("month",month,0,"e");
	output;
	function="polycont";
	y1=0;
	output;
run;

/*another shading from the daniel moskowitz paper*/

filename _ "%sysfunc(getoption(work))\_.zip";

proc http method="get" out=_
	url="http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_CSV.zip";
run;

filename _ zip "%sysfunc(getoption(work))\_.zip";

data ff3(drop=i);
	infile _(F-F_Research_Data_Factors.CSV) dsd;
	input month rmrf smb hml rf;
	if month<lag(month) then i+1;
	if i=0 and month>0;
	month_=input(put(month,6.),yymmn6.);
	rm=rmrf+rf;
	rm_+log(1+rm/100);
	if lag(rm_)<lag25(rm_) then rec=1;
run;

data ff3;
	set ff3;
	where &min.<=month_<=&max. and rec=1;
	layer="front";
	x1space="datavalue";
	y1space="wallpercent";
	display="fill";
	fillcolor="black";
	filltransparency=0.9;
	function="polygon ";
	x1=month_;
	y1=0;
	output;
	function="polycont";
	y1=100;
	output;
	function="polycont";
	x1=intnx("month",month_,0,"e");
	output;
	function="polycont";
	y1=0;
	output;
run;

/*another shading by jeff - cancelled as poor*/

/*filename _ "%sysfunc(getoption(work))\_.xlsx";*/
/**/
/*proc http method="get" out=_*/
/*	url="http://people.stern.nyu.edu/jwurgler/data/Investor_Sentiment_Data_20190327_POST.xlsx";*/
/*run;*/
/**/
/*proc import file=_ dbms=xlsx out=jeff replace;*/
/*	sheet="DATA";*/
/*run;*/
/**/
/*proc transpose out=jeff;*/
/*	where yearmo>.;*/
/*	by yearmo;*/
/*	var _all_;*/
/*run;*/
/**/
/*data jeff;*/
/*	set jeff;*/
/*	if _name_="yearmo" then _name_="month";*/
/*	else _name_=lowcase(_name_);*/
/*	col2=col1+0;*/
/*run;*/
/**/
/*proc transpose out=jeff(drop=yearmo _:);*/
/*	by yearmo;*/
/*run;*/
/**/
/*proc means noprint;*/
/*	where &min.<=input(put(month,6.),yymmn6.)<=&max.;*/
/*	var sent_;*/
/*	output out=_1 q1=_1;*/
/*run;*/
/**/
/*proc sql noprint;*/
/*	select _1 into :_1 trimmed from _1;*/
/*quit;*/
/**/
/*data jeff;*/
/*	set jeff;*/
/*	month_=input(put(month,6.),yymmn6.);*/
/*	if .<sent_<&_1. then rec=1;*/
/*run;*/
/**/
/*data jeff;*/
/*	set jeff;*/
/*	where &min.<=month_<=&max. and rec=1;*/
/*	layer="front";*/
/*	x1space="datavalue";*/
/*	y1space="wallpercent";*/
/*	display="fill";*/
/*	fillcolor="black";*/
/*	filltransparency=0.9;*/
/*	function="polygon ";*/
/*	x1=month_;*/
/*	y1=0;*/
/*	output;*/
/*	function="polycont";*/
/*	y1=100;*/
/*	output;*/
/*	function="polycont";*/
/*	x1=intnx("month",month_,0,"e");*/
/*	output;*/
/*	function="polycont";*/
/*	y1=0;*/
/*	output;*/
/*run;*/

/*another shading by michigan - cancelled as poor*/

/*filename _ "%sysfunc(getoption(work))\_.csv";*/
/**/
/*proc http method="get" out=_*/
/*	url="https://fred.stlouisfed.org/graph/fredgraph.csv?id=UMCSENT";*/
/*run;*/
/**/
/*data mich;*/
/*	infile _ firstobs=2 dsd;*/
/*	input month yymmdd10. +1 mich;*/
/*	if year(month)>=1978;*/
/*run;*/
/**/
/*proc means noprint;*/
/*	where &min.<=month<=&max.;*/
/*	var mich;*/
/*	output out=_1 q1=_1;*/
/*run;*/
/**/
/*proc sql noprint;*/
/*	select _1 into :_1 trimmed from _1;*/
/*quit;*/
/**/
/*data mich;*/
/*	set mich;*/
/*	where &min.<=month<=&max. and mich<&_1.;*/
/*	layer="front";*/
/*	x1space="datavalue";*/
/*	y1space="wallpercent";*/
/*	display="fill";*/
/*	fillcolor="black";*/
/*	filltransparency=0.9;*/
/*	function="polygon ";*/
/*	x1=month;*/
/*	y1=0;*/
/*	output;*/
/*	function="polycont";*/
/*	y1=100;*/
/*	output;*/
/*	function="polycont";*/
/*	x1=intnx("month",month,0,"e");*/
/*	output;*/
/*	function="polycont";*/
/*	y1=0;*/
/*	output;*/
/*run;*/

/*another shading by john*/

proc import file="!userprofile\OneDrive - UWM\UWM\2019_02_Fall\191121drawdown_ret.xls" out=john replace;
	sheet="Sheet1";
run;

data john;
	set john;
	month_=input(put(date_yyyymm,6.),yymmn6.);
	if drawdown_max<-0.10 and drawdown_startend_idx>0 then justdrawdown=1;
	if drawdown_max<-0.10 and drawdown_endrecovery_idx>0 then justrecovery=1;
run;

data john;
	set john;
	where &min.<=month_<=&max. and (justdrawdown=1 or justrecovery=1);
	layer="front";
	x1space="datavalue";
	y1space="wallpercent";
	display="fill";
	if justdrawdown=1 then fillcolor="red ";
	else fillcolor="lime";
	filltransparency=0.9;
	function="polygon ";
	x1=month_;
	y1=0;
	output;
	function="polycont";
	y1=100;
	output;
	function="polycont";
	x1=intnx("month",month_,0,"e");
	output;
	function="polycont";
	y1=0;
	output;
run;

/*plot ken and fred*/

ods listing gpath="!userprofile\desktop\";
ods graphics/reset imagename="191121momstd" width=1280 height=720 noborder;
ods results=off;

proc sgplot data=mom sganno=nber;
	where name_ in ("p01","p10","p10-p01");
	series x=month_ y=sigma_/group=name_;
	xaxis values=(&min. to &max. by year10) valueshint valuesformat=yymmn6.;
	styleattrs datacontrastcolors=(red blue magenta) datalinepatterns=(solid);
	inset "nber recessions";
run;

proc sgplot data=mom sganno=ff3;
	where name_ in ("p01","p10","p10-p01");
	series x=month_ y=sigma_/group=name_;
	xaxis values=(&min. to &max. by year10) valueshint valuesformat=yymmn6.;
	styleattrs datacontrastcolors=(red blue magenta) datalinepatterns=(solid);
	inset "negative two-year market returns";
run;

/*cancelled as poor*/

/*proc sgplot data=mom sganno=jeff;*/
/*	where name_ in ("p01","p10","p10-p01");*/
/*	series x=month_ y=sigma_/group=name_;*/
/*	xaxis values=(&min. to &max. by year10) valueshint valuesformat=yymmn6.;*/
/*	styleattrs datacontrastcolors=(red blue magenta) datalinepatterns=(solid);*/
/*	inset "wurgler sentiment first quartiles";*/
/*run;*/

/*cancelled as poor*/

/*proc sgplot data=mom sganno=mich;*/
/*	where name_ in ("p01","p10","p10-p01");*/
/*	series x=month_ y=sigma_/group=name_;*/
/*	xaxis values=(&min. to &max. by year10) valueshint valuesformat=yymmn6.;*/
/*	styleattrs datacontrastcolors=(red blue magenta) datalinepatterns=(solid);*/
/*	inset "michigan sentiment first quartiles";*/
/*run;*/

proc sgplot data=mom sganno=john;
	where name_ in ("p01","p10","p10-p01");
	series x=month_ y=sigma_/group=name_;
	xaxis values=(&min. to &max. by year10) valueshint valuesformat=yymmn6.;
	styleattrs datacontrastcolors=(red blue magenta) datalinepatterns=(solid);
	inset "ex-post drawdown and recovery indicators";
run;

ods results=on;

quit;
