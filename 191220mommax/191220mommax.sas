/*************************************************
191220mommax
this code use crsp to form value-weighted
1) 30-40-30 portfolios by ret(-12,-2)
2) quintile portfolios by ret(-12,-2)
3) decile portfolios by ret(-12,-2)
4) 30-40-30 portfolios by max(-1)
5) quintile portfolios by max(-1)
6) decile portfolios by max(-1)
7) 5x5 portfolios by ret(-12,-2)
and compute their number of stocks information
*************************************************/

%let wrds=wrds.wharton.upenn.edu 4016;
signon wrds username=_prompt_;

rsubmit;

/*add size1 and r122 to msf*/

data msf;
	set crsp.msf;
	mon=intnx("mon",date,0);
	size=abs(prc)*shrout;
	size1=ifn(permno=lag(permno),lag(size),.);
	ret2=ifn(permno=lag2(permno),lag2(ret),.);
run;

proc printto log="nul:";
run;

proc expand method=none out=msf;
	by permno;
	id date;
	convert ret2=r122/tout=(+1 nomiss movprod 11 -1 trimleft 10);
run;

proc printto;
run;

/*make dsf monthly and add max*/

proc sql;
	create table dsf as
	select *,intnx("mon",date,0) as mon,max(ret) as max
	from crsp.dsf
	group by permno,mon
	having date=max(date)
	order by permno,date;
quit;

/*merge msf and dsf and add max1*/

data msf;
	merge msf(in=a) dsf(keep=permno mon max);
	by permno mon;
	if a;
	max1=ifn(permno=lag(permno),lag(max),.);
run;

/*extend msenames to include all monthly msf observations*/

data msenames;
	set crsp.msenames;
	by permno namedt;
	if last.permno then nameendt=intnx("mon",nameendt,0,"e");
run;

/*join msf and msenames and exclude unncecessary observations*/

proc sql;
	create table msf as
	select a.*
	from msf a join msenames b
	on a.permno=b.permno and namedt<=date<=nameendt and ^missing(ret) and size1>0 and (r122>. or ^missing(max1)) and shrcd in (10,11)
	order by date,permno;
quit;

/*compute nyse unconditional decile breakpoints*/

proc univariate noprint;
	where hexcd=1;
	by date;
	var r122 max1;
	output out=msf1 pctlpre=r122u max1u pctlpts=0 10 20 30 40 50 60 70 80 90 100;
run;

/*compute nyse conditional decile breakpoints*/

proc univariate data=msf noprint;
	where hexcd=1 and r122>. and ^missing(max1);
	by date;
	var r122 max1;
	output out=msf2 pctlpre=r122c max1c pctlpts=0 10 20 30 40 50 60 70 80 90 100;
run;

/*************************************************
merge msf and breakpoints and form 61 portfolios
p1 for 30-40-30 by r122
p2 for quintiles by r122
p3 for deciles by r122
p4 for 30-40-30 by max1
p5 for quintiles by max1
p6 for deciles by max1
p7 for 5x5 portfolios by r122 and max1
*************************************************/

data msf;
	merge msf msf1 msf2;
	by date;
	if r122>. then do;
		if r122<=r122u30 then p1="r122up030";
		else if r122<=r122u70 then p1="r122up070";
		else p1="r122up100";
		if r122<=r122u20 then p2="r122uq1";
		else if r122<=r122u40 then p2="r122uq2";
		else if r122<=r122u60 then p2="r122uq3";
		else if r122<=r122u80 then p2="r122uq4";
		else p2="r122uq5";
		if r122<=r122u10 then p3="r122ud01";
		else if r122<=r122u20 then p3="r122ud02";
		else if r122<=r122u30 then p3="r122ud03";
		else if r122<=r122u40 then p3="r122ud04";
		else if r122<=r122u50 then p3="r122ud05";
		else if r122<=r122u60 then p3="r122ud06";
		else if r122<=r122u70 then p3="r122ud07";
		else if r122<=r122u80 then p3="r122ud08";
		else if r122<=r122u90 then p3="r122ud09";
		else p3="r122ud10";
	end;
	if ^missing(max1) then do;
		if max1<=max1u30 then p4="max1up030";
		else if max1<=max1u70 then p4="max1up070";
		else p4="max1up100";
		if max1<=max1u20 then p5="max1uq1";
		else if max1<=max1u40 then p5="max1uq2";
		else if max1<=max1u60 then p5="max1uq3";
		else if max1<=max1u80 then p5="max1uq4";
		else p5="max1uq5";
		if max1<=max1u10 then p6="max1ud01";
		else if max1<=max1u20 then p6="max1ud02";
		else if max1<=max1u30 then p6="max1ud03";
		else if max1<=max1u40 then p6="max1ud04";
		else if max1<=max1u50 then p6="max1ud05";
		else if max1<=max1u60 then p6="max1ud06";
		else if max1<=max1u70 then p6="max1ud07";
		else if max1<=max1u80 then p6="max1ud08";
		else if max1<=max1u90 then p6="max1ud09";
		else p6="max1ud10";
	end;
	if r122>. and ^missing(max1) then do;
		if r122<=r122c20 then do;
			if max1<=max1c20 then p7="r122cmax1c11";
			else if max1<=max1c40 then p7="r122cmax1c12";
			else if max1<=max1c60 then p7="r122cmax1c13";
			else if max1<=max1c80 then p7="r122cmax1c14";
			else p7="r122cmax1c15";
		end;
		else if r122<=r122c40 then do;
			if max1<=max1c20 then p7="r122cmax1c21";
			else if max1<=max1c40 then p7="r122cmax1c22";
			else if max1<=max1c60 then p7="r122cmax1c23";
			else if max1<=max1c80 then p7="r122cmax1c24";
			else p7="r122cmax1c25";
		end;
		else if r122<=r122c60 then do;
			if max1<=max1c20 then p7="r122cmax1c31";
			else if max1<=max1c40 then p7="r122cmax1c32";
			else if max1<=max1c60 then p7="r122cmax1c33";
			else if max1<=max1c80 then p7="r122cmax1c34";
			else p7="r122cmax1c35";
		end;
		else if r122<=r122c80 then do;
			if max1<=max1c20 then p7="r122cmax1c41";
			else if max1<=max1c40 then p7="r122cmax1c42";
			else if max1<=max1c60 then p7="r122cmax1c43";
			else if max1<=max1c80 then p7="r122cmax1c44";
			else p7="r122cmax1c45";
		end;
		else do;
			if max1<=max1c20 then p7="r122cmax1c51";
			else if max1<=max1c40 then p7="r122cmax1c52";
			else if max1<=max1c60 then p7="r122cmax1c53";
			else if max1<=max1c80 then p7="r122cmax1c54";
			else p7="r122cmax1c55";
		end;
	end;
run;

/*form p1 p2 p3 portfolios by r122*/

proc sort;
	by date r122;
run;

%macro meanstranspose(where,out);

/*compute value-weighted returns*/

proc means data=msf noprint;
	where &where. ne "";
	by date &where.;
	var ret;
	weight size1;
	output out=&out. mean=ret;
run;

/*save the number of stocks*/

proc transpose out=n&out.(drop=_:);
	by date;
	id &where.;
	var _freq_;
run;

/*go from panel to time-series*/

proc transpose data=&out. out=&out.(drop=_:);
	by date;
	id &where.;
	var ret;
run;

%mend;

%meanstranspose(p1,msf1);
%meanstranspose(p2,msf2);
%meanstranspose(p3,msf3);

/*form p4 p5 p6 portfolios by max1*/

proc sort data=msf;
	by date max1;
run;

%meanstranspose(p4,msf4);
%meanstranspose(p5,msf5);
%meanstranspose(p6,msf6);

/*form p7 portfolios by r122 and max1*/

proc sort data=msf;
	by date p7;
run;

%meanstranspose(p7,msf7);

/*************************************************
rename the number of stocks to merge
from r122up030 to n122up030
*************************************************/

data nmsf1;
	merge nmsf1-nmsf7;
	by date;
run;

proc transpose out=nmsf1;
	by date;
run;

data nmsf1;
	set nmsf1;
	substr(_name_,1,1)="n";
run;

proc transpose out=nmsf1(drop=_:);
	by date;
run;

/*merge returns and number information*/

data msf1;
	format date yymmddn8.;
	merge msf1-msf7 nmsf1;
	by date;
	format r122up030--r122cmax1c55 best16.;
run;

endrsubmit;

/*export date, 61 returns, 61 numbers to desktop as csv*/

libname _ server=wrds slibref=work;

proc export data=_.msf1 file="!userprofile\desktop\191220mommax.csv" replace;
run;

quit;
