/*************************************************
191203max

computes monthly max portfolio returns max is from
bali, cakici, and whitelaw (2011)

in the results, r and n mean returns and numbers
v and e mean value- and equal-weighted portfolios
p means 30-70-100 portfolios
q means quintile portfolios
d means decile portfolios
t means 25 size-max portfolios

the results include 172 variables after date
43=3+5+10+25 value-weighted returns and numbers
43 equal-weighted returns and numbers

some missing values in 25 portfolios until 1944
no missing value after 1945
*************************************************/

resetline;
dm"log;clear;output;clear;";
option nodate nonumber nolabel ls=128 ps=max;
%let wrds=wrds.wharton.upenn.edu 4016;
signon wrds username=_prompt_;
libname crsp server=wrds slibref=crsp;
libname _ server=wrds slibref=work;

rsubmit;

proc datasets kill nolist;
run;

/*excludes missing values*/

proc sql;
	create table dsf as
	select distinct permno,intnx("month",date,1) as date,max(ret) as max1
	from crsp.dsf
	where ^missing(ret)
	group by permno,intnx("month",date,1)
	order by date,permno;
quit;

/*includes 10 and 11 as us common stocks*/

data msf;
	set crsp.msf;
	size=abs(prc)*shrout;
	size1=ifn(permno=lag(permno) and intnx("month",date,0)=intnx("month",lag(date),1),lag(size),.);
run;

proc sql;
	create table msf as
	select a.*,max1
	from (msf a join crsp.msenames b
	on a.permno=b.permno and b.namedt<=a.date<=b.nameendt) join dsf c
	on a.permno=c.permno and intnx("month",a.date,0)=c.date
	where shrcd in (10,11)
	order by permno,date;
quit;

proc sort;
	where ^missing(ret) and max1>. and size1>0;
	by date max1;
run;

/*use nyse size and max breakpoints*/

proc univariate noprint;
	where hexcd=1;
	by date;
	var max1 size1;
	output out=msf1 pctlpre=max1 size1 pctlpts=10 20 30 40 50 60 70 80 90;
run;

/*_1 for 30-70-100, _2 for quintile, _3 for decile, _4 for 25 size-max*/

data msf;
	merge msf msf1;
	by date;
	if max1<=max130 then _1=0;
	else if max1<=max170 then _1=1;
	else _1=2;
	if max1<=max120 then _2=0;
	else if max1<=max140 then _2=1;
	else if max1<=max160 then _2=2;
	else if max1<=max180 then _2=3;
	else _2=4;
	if max1<=max110 then _3=0;
	else if max1<=max120 then _3=1;
	else if max1<=max130 then _3=2;
	else if max1<=max140 then _3=3;
	else if max1<=max150 then _3=4;
	else if max1<=max160 then _3=5;
	else if max1<=max170 then _3=6;
	else if max1<=max180 then _3=7;
	else if max1<=max190 then _3=8;
	else _3=9;
	if size1<=size120 then do;
		if max1<=max120 then _4=0;
		else if max1<=max140 then _4=1;
		else if max1<=max160 then _4=2;
		else if max1<=max180 then _4=3;
		else _4=4;
	end;
	else if size1<=size140 then do;
		if max1<=max120 then _4=5;
		else if max1<=max140 then _4=6;
		else if max1<=max160 then _4=7;
		else if max1<=max180 then _4=8;
		else _4=9;
	end;
	else if size1<=size160 then do;
		if max1<=max120 then _4=10;
		else if max1<=max140 then _4=11;
		else if max1<=max160 then _4=12;
		else if max1<=max180 then _4=13;
		else _4=14;
	end;
	else if size1<=size180 then do;
		if max1<=max120 then _4=15;
		else if max1<=max140 then _4=16;
		else if max1<=max160 then _4=17;
		else if max1<=max180 then _4=18;
		else _4=19;
	end;
	else do;
		if max1<=max120 then _4=20;
		else if max1<=max140 then _4=21;
		else if max1<=max160 then _4=22;
		else if max1<=max180 then _4=23;
		else _4=24;
	end;
run;

%macro sort(out,by,weight);

proc sort data=msf out=&out.;
	by date &by.;
run;

proc means noprint;
	by date &by.;
	var ret;
	%if &weight.=1 %then %do;weight size1;%end;
	output out=&out. n=num mean=ret;
run;

%mend;

%sort(msf1,_1,1);
%sort(msf2,_2,1);
%sort(msf3,_3,1);
%sort(msf4,_4,1);
%sort(msf5,_1,0);
%sort(msf6,_2,0);
%sort(msf7,_3,0);
%sort(msf8,_4,0);

data msf(keep=date n: r:);
	format date
		rvp030 rvp070 rvp100 rvq1-rvq5 rvd01-rvd10 rvt11-rvt15 rvt21-rvt25 rvt31-rvt35 rvt41-rvt45 rvt51-rvt55
		rep030 rep070 rep100 req1-req5 red01-red10 ret11-ret15 ret21-ret25 ret31-ret35 ret41-ret45 ret51-ret55
		nvp030 nvp070 nvp100 nvq1-nvq5 nvd01-nvd10 nvt11-nvt15 nvt21-nvt25 nvt31-nvt35 nvt41-nvt45 nvt51-nvt55
		nep030 nep070 nep100 neq1-neq5 ned01-ned10 net11-net15 net21-net25 net31-net35 net41-net45 net51-net55 best16.;
	merge msf1(where=(_1=0) rename=(num=nvp030 ret=rvp030))
		msf1(where=(_1=1) rename=(num=nvp070 ret=rvp070))
		msf1(where=(_1=2) rename=(num=nvp100 ret=rvp100))
		msf2(where=(_2=0) rename=(num=nvq1 ret=rvq1))
		msf2(where=(_2=1) rename=(num=nvq2 ret=rvq2))
		msf2(where=(_2=2) rename=(num=nvq3 ret=rvq3))
		msf2(where=(_2=3) rename=(num=nvq4 ret=rvq4))
		msf2(where=(_2=4) rename=(num=nvq5 ret=rvq5))
		msf3(where=(_3=0) rename=(num=nvd01 ret=rvd01))
		msf3(where=(_3=1) rename=(num=nvd02 ret=rvd02))
		msf3(where=(_3=2) rename=(num=nvd03 ret=rvd03))
		msf3(where=(_3=3) rename=(num=nvd04 ret=rvd04))
		msf3(where=(_3=4) rename=(num=nvd05 ret=rvd05))
		msf3(where=(_3=5) rename=(num=nvd06 ret=rvd06))
		msf3(where=(_3=6) rename=(num=nvd07 ret=rvd07))
		msf3(where=(_3=7) rename=(num=nvd08 ret=rvd08))
		msf3(where=(_3=8) rename=(num=nvd09 ret=rvd09))
		msf3(where=(_3=9) rename=(num=nvd10 ret=rvd10))
		msf4(where=(_4=0) rename=(num=nvt11 ret=rvt11))
		msf4(where=(_4=1) rename=(num=nvt12 ret=rvt12))
		msf4(where=(_4=2) rename=(num=nvt13 ret=rvt13))
		msf4(where=(_4=3) rename=(num=nvt14 ret=rvt14))
		msf4(where=(_4=4) rename=(num=nvt15 ret=rvt15))
		msf4(where=(_4=5) rename=(num=nvt21 ret=rvt21))
		msf4(where=(_4=6) rename=(num=nvt22 ret=rvt22))
		msf4(where=(_4=7) rename=(num=nvt23 ret=rvt23))
		msf4(where=(_4=8) rename=(num=nvt24 ret=rvt24))
		msf4(where=(_4=9) rename=(num=nvt25 ret=rvt25))
		msf4(where=(_4=10) rename=(num=nvt31 ret=rvt31))
		msf4(where=(_4=11) rename=(num=nvt32 ret=rvt32))
		msf4(where=(_4=12) rename=(num=nvt33 ret=rvt33))
		msf4(where=(_4=13) rename=(num=nvt34 ret=rvt34))
		msf4(where=(_4=14) rename=(num=nvt35 ret=rvt35))
		msf4(where=(_4=15) rename=(num=nvt41 ret=rvt41))
		msf4(where=(_4=16) rename=(num=nvt42 ret=rvt42))
		msf4(where=(_4=17) rename=(num=nvt43 ret=rvt43))
		msf4(where=(_4=18) rename=(num=nvt44 ret=rvt44))
		msf4(where=(_4=19) rename=(num=nvt45 ret=rvt45))
		msf4(where=(_4=20) rename=(num=nvt51 ret=rvt51))
		msf4(where=(_4=21) rename=(num=nvt52 ret=rvt52))
		msf4(where=(_4=22) rename=(num=nvt53 ret=rvt53))
		msf4(where=(_4=23) rename=(num=nvt54 ret=rvt54))
		msf4(where=(_4=24) rename=(num=nvt55 ret=rvt55))
		msf5(where=(_1=0) rename=(num=nep030 ret=rep030))
		msf5(where=(_1=1) rename=(num=nep070 ret=rep070))
		msf5(where=(_1=2) rename=(num=nep100 ret=rep100))
		msf6(where=(_2=0) rename=(num=neq1 ret=req1))
		msf6(where=(_2=1) rename=(num=neq2 ret=req2))
		msf6(where=(_2=2) rename=(num=neq3 ret=req3))
		msf6(where=(_2=3) rename=(num=neq4 ret=req4))
		msf6(where=(_2=4) rename=(num=neq5 ret=req5))
		msf7(where=(_3=0) rename=(num=ned01 ret=red01))
		msf7(where=(_3=1) rename=(num=ned02 ret=red02))
		msf7(where=(_3=2) rename=(num=ned03 ret=red03))
		msf7(where=(_3=3) rename=(num=ned04 ret=red04))
		msf7(where=(_3=4) rename=(num=ned05 ret=red05))
		msf7(where=(_3=5) rename=(num=ned06 ret=red06))
		msf7(where=(_3=6) rename=(num=ned07 ret=red07))
		msf7(where=(_3=7) rename=(num=ned08 ret=red08))
		msf7(where=(_3=8) rename=(num=ned09 ret=red09))
		msf7(where=(_3=9) rename=(num=ned10 ret=red10))
		msf8(where=(_4=0) rename=(num=net11 ret=ret11))
		msf8(where=(_4=1) rename=(num=net12 ret=ret12))
		msf8(where=(_4=2) rename=(num=net13 ret=ret13))
		msf8(where=(_4=3) rename=(num=net14 ret=ret14))
		msf8(where=(_4=4) rename=(num=net15 ret=ret15))
		msf8(where=(_4=5) rename=(num=net21 ret=ret21))
		msf8(where=(_4=6) rename=(num=net22 ret=ret22))
		msf8(where=(_4=7) rename=(num=net23 ret=ret23))
		msf8(where=(_4=8) rename=(num=net24 ret=ret24))
		msf8(where=(_4=9) rename=(num=net25 ret=ret25))
		msf8(where=(_4=10) rename=(num=net31 ret=ret31))
		msf8(where=(_4=11) rename=(num=net32 ret=ret32))
		msf8(where=(_4=12) rename=(num=net33 ret=ret33))
		msf8(where=(_4=13) rename=(num=net34 ret=ret34))
		msf8(where=(_4=14) rename=(num=net35 ret=ret35))
		msf8(where=(_4=15) rename=(num=net41 ret=ret41))
		msf8(where=(_4=16) rename=(num=net42 ret=ret42))
		msf8(where=(_4=17) rename=(num=net43 ret=ret43))
		msf8(where=(_4=18) rename=(num=net44 ret=ret44))
		msf8(where=(_4=19) rename=(num=net45 ret=ret45))
		msf8(where=(_4=20) rename=(num=net51 ret=ret51))
		msf8(where=(_4=21) rename=(num=net52 ret=ret52))
		msf8(where=(_4=22) rename=(num=net53 ret=ret53))
		msf8(where=(_4=23) rename=(num=net54 ret=ret54))
		msf8(where=(_4=24) rename=(num=net55 ret=ret55));
	by date;
	date=input(put(date,yymmddn8.),8.);
run;

endrsubmit;

proc export data=_.msf file="!userprofile\desktop\191203max.csv" replace;
run;

quit;
