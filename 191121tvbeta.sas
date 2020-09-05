/*************************************************
191121tvbeta
computes time-varying fama-french betas
*************************************************/

resetline;
dm"log;clear;output;clear;";
option nodate nonumber nolabel ls=128 ps=max;

proc datasets kill nolist;
run;

/**/

filename _ "%sysfunc(getoption(work))\_.zip";

proc http method="get" out=_
	url="https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_daily_CSV.zip";
run;

filename _ zip "%sysfunc(getoption(work))\_.zip";

data factor(drop=i);
	infile _(F-F_Research_Data_Factors_daily.CSV) dsd;
	input day rmrf smb hml rf;
	if day<lag(day) then i+1;
	if i=0 and day>0;
run;

/**/

filename _ "%sysfunc(getoption(work))\_.zip";

proc http method="get" out=_
	url="https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/10_Portfolios_Prior_12_2_Daily_CSV.zip";
run;

filename _ zip "%sysfunc(getoption(work))\_.zip";

data portfolio(drop=i);
	infile _(10_Portfolios_Prior_12_2_Daily.CSV) dsd;
	input day p01-p10;
	if day<lag(day) then i+1;
	if i=0 and day>0;
run;

/**/

filename _ "%sysfunc(getoption(work))\_.csv";

proc http method="get" out=_
	url="https://fred.stlouisfed.org/graph/fredgraph.csv?id=USRECM";
run;

data nber;
	infile _ firstobs=2;
	input x1 yymmdd10. +1 y1;
	if y1;
	display="fill";
	fillcolor="black";
	filltransparency=0.9;
	layer="front";
	x1space="datavalue";
	y1space="wallpercent";
	function="polygon ";
	y1=0;
	output;
	function="polycont";
	y1=100;
	output;
	x1=intnx("month",x1,0,"e");
	output;
	y1=0;
	output;
run;

/**/

data all(drop=i);
	merge portfolio factor;
	by day;
	array p(*) p:;
	do i=1 to dim(p);
		p(i)=p(i)-rf;
	end;
	month=int(day/100);
run;

proc transpose out=all;
	by day month rmrf smb hml;
	var p:;
run;

proc sort;
	by _name_ day;
run;

proc reg noprint outest=all(rename=(_name_=name_));
	where col1>.;
	by _name_ month;
	model col1=rmrf smb hml;
run;

proc transpose out=all;
	by name_ month;
	var rmrf smb hml _rmse_;
run;

proc sort;
	by name_ _name_ month;
run;

data all;
	set all;
	if _name_="_RMSE_" then col1=col1*sqrt(252);
	risk=mean(col1,lag1(col1),lag2(col1),lag3(col1),lag4(col1),lag5(col1),lag6(col1),lag7(col1),lag8(col1),lag9(col1),lag10(col1),lag11(col1));
	if _name_^=lag11(_name_) then risk=.;
	month_=intnx("month",input(put(month,6.),yymmn6.),0,"e");
run;

data _(drop=risk1 risk10);
	merge all(where=(name_="p01") rename=(risk=risk1))
		all(where=(name_="p10") rename=(risk=risk10));
	by _name_ month;
	name_="p10-p01";
	risk=risk10-risk1;
run;

proc append base=all;
run;

proc sql noprint;
	select min(month_),max(month_) into :min trimmed,:max trimmed from all where risk>.;
quit;

/**/

ods listing gpath="!userprofile\desktop\";
ods graphics/reset imagename="191121tvbeta" width=1920 height=1080 noborder;
option label;
ods results=off;

proc sgplot data=all sganno=nber(where=(&min.<=x1<=&max.));
	where name_ in ("p01","p10") and _name_="rmrf";
	series x=month_ y=risk/group=name_;
	xaxis values=(&min. to &max. by year10) valueshint valuesformat=yymmn6. label="month";
	yaxis label="rmrf beta";
	styleattrs datacontrastcolors=(red blue) datalinepatterns=(solid);
	keylegend/title="";
run;

proc sgplot data=all sganno=nber(where=(&min.<=x1<=&max.));
	where name_ in ("p01","p10") and _name_="smb";
	series x=month_ y=risk/group=name_;
	xaxis values=(&min. to &max. by year10) valueshint valuesformat=yymmn6. label="month";
	yaxis label="smb beta";
	styleattrs datacontrastcolors=(red blue) datalinepatterns=(solid);
	keylegend/title="";
run;

proc sgplot data=all sganno=nber(where=(&min.<=x1<=&max.));
	where name_ in ("p01","p10") and _name_="hml";
	series x=month_ y=risk/group=name_;
	xaxis values=(&min. to &max. by year10) valueshint valuesformat=yymmn6. label="month";
	yaxis label="hml beta";
	styleattrs datacontrastcolors=(red blue) datalinepatterns=(solid);
	keylegend/title="";
run;

proc sgplot data=all sganno=nber(where=(&min.<=x1<=&max.));
	where name_ in ("p01","p10") and _name_="_RMSE_";
	series x=month_ y=risk/group=name_;
	xaxis values=(&min. to &max. by year10) valueshint valuesformat=yymmn6. label="month";
	yaxis label="residual sigma";
	styleattrs datacontrastcolors=(red blue) datalinepatterns=(solid);
	keylegend/title="";
run;

option nolabel;
ods results=on;

quit;
