/*runs volatility scaling for french factors changing volatility windows*/
filename fm "%sysfunc(getoption(work))\fm";
filename fd "%sysfunc(getoption(work))\fd";
filename gm "%sysfunc(getoption(work))\gm";
filename gd "%sysfunc(getoption(work))\gd";
filename mm "%sysfunc(getoption(work))\mm";
filename md "%sysfunc(getoption(work))\md";
filename sm "%sysfunc(getoption(work))\sm";
filename sd "%sysfunc(getoption(work))\sd";
filename lm "%sysfunc(getoption(work))\lm";
filename ld "%sysfunc(getoption(work))\ld";

proc http url="https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_CSV.zip" out=fm;
proc http url="https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_daily_CSV.zip" out=fd;
proc http url="https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_5_Factors_2x3_CSV.zip" out=gm;
proc http url="https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_5_Factors_2x3_daily_CSV.zip" out=gd;
proc http url="https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Momentum_Factor_CSV.zip" out=mm;
proc http url="https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Momentum_Factor_daily_CSV.zip" out=md;
proc http url="https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_ST_Reversal_Factor_CSV.zip" out=sm;
proc http url="https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_ST_Reversal_Factor_daily_CSV.zip" out=sd;
proc http url="https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_LT_Reversal_Factor_CSV.zip" out=lm;
proc http url="https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_LT_Reversal_Factor_daily_CSV.zip" out=ld;
run;

filename fm zip "%sysfunc(getoption(work))\fm";
filename fd zip "%sysfunc(getoption(work))\fd";
filename gm zip "%sysfunc(getoption(work))\gm";
filename gd zip "%sysfunc(getoption(work))\gd";
filename mm zip "%sysfunc(getoption(work))\mm";
filename md zip "%sysfunc(getoption(work))\md";
filename sm zip "%sysfunc(getoption(work))\sm";
filename sd zip "%sysfunc(getoption(work))\sd";
filename lm zip "%sysfunc(getoption(work))\lm";
filename ld zip "%sysfunc(getoption(work))\ld";

data fm;
	infile fm(F-F_Research_Data_Factors.CSV) dsd truncover;
	input date mktrf smb hml rf;
	if 100000<date<999999;
data fd;
	infile fd(F-F_Research_Data_Factors_daily.CSV) dsd truncover;
	input dat mktrf smb hml rf;
	if 10000000<dat<99999999;
	date=int(dat/100);
data gm;
	infile gm(F-F_Research_Data_5_Factors_2x3.CSV) dsd truncover;
	input date mktrf smb hml rmw cma rf;
	if 100000<date<999999;
data gd;
	infile gd(F-F_Research_Data_5_Factors_2x3_daily.CSV) dsd truncover;
	input dat mktrf smb hml rmw cma rf;
	if 10000000<dat<99999999;
	date=int(dat/100);
data mm;
	infile mm(F-F_Momentum_Factor.CSV) dsd truncover;
	input date mom;
	if 100000<date<999999;
data md;
	infile md(F-F_Momentum_Factor_daily.CSV) dsd truncover;
	input dat mom;
	if 10000000<dat<99999999;
	date=int(dat/100);
data sm;
	infile sm(F-F_ST_Reversal_Factor.CSV) dsd truncover;
	input date str;
	if 100000<date<999999;
data sd;
	infile sd(F-F_ST_Reversal_Factor_daily.CSV) dsd truncover;
	input dat str;
	if 10000000<dat<99999999;
	date=int(dat/100);
data lm;
	infile lm(F-F_LT_Reversal_Factor.CSV) dsd truncover;
	input date ltr;
	if 100000<date<999999;
data ld;
	infile ld(F-F_LT_Reversal_Factor_daily.CSV) dsd truncover;
	input dat ltr;
	if 10000000<dat<99999999;
	date=int(dat/100);
run;

%macro scale(setm,varm,setd,vard,var);

%do movave=21 %to 504 %by 21;

data m;
	set &setm.(keep=date &varm. rename=(&varm.=m));
data d;
	set &setd.(keep=date &vard. dat rename=(&vard.=d));
proc expand method=none out=w;
	id dat;
	convert d=w/tout=(nomiss square movave &movave. trimleft %eval(&movave.-1) *252 sqrt reciprocal *10 lag 1);
proc sort nodupkey;
	by date;
data m;
	merge m w(keep=date w);
	by date;
	s=w*m;
run;

ods listing close;
ods results=off;

proc means n mean std skew kurt min q1 median q3 max stackods;
	var m s;
	ods output summary=r;
run;

ods results=on;
ods listing;

data r;
	Var=put("&var.",5.);
	Movave=&movave./21;
	set r;
	Sharpe=mean/stddev*sqrt(12);
	if _n_=1 then do;
		if movave=1 then movave=0;
		else delete;
	end;
proc append base=scale;
run;

%end;

%mend;

proc delete data=scale;
run;

%scale(fm,mktrf,fd,mktrf,MKTRF)
%scale(fm,smb,fd,smb,SMB)
%scale(fm,hml,fd,hml,HML)
%scale(gm,smb,gd,smb,SMB5)
%scale(gm,rmw,gd,rmw,RMW)
%scale(gm,cma,gd,cma,CMA)
%scale(mm,mom,md,mom,MOM)
%scale(sm,str,sd,str,STR)
%scale(lm,ltr,ld,ltr,LTR)

proc export replace file="!userprofile\desktop\scale.csv";
proc sort data=scale out=scale2;
	by movave var;
run;

%macro scale2(var);

proc transpose data=scale2 out=&var.(drop=_name_ _label_);
	by movave;
	id var;
	var &var.;
run;

data &var.;
	format Movave MKTRF SMB HML SMB5 RMW CMA MOM STR LTR best6.;
	set &var.;
run;

proc export replace file="!userprofile\desktop\scale_&var..csv";
run;

%mend;

%scale2(mean)
%scale2(stddev)
%scale2(skew)
%scale2(kurt)
%scale2(sharpe)
