/*************************************************
191220maximax
this code uses max and idiosyncratic max to form
1) decile portfolios by max
2) decile portfolios by imax
3) 5x5 portfolios by max and imax
and exports 45 portfolio returns
*************************************************/

filename a "%sysfunc(getoption(work))\a";

proc http out=a url="https://raw.githubusercontent.com/junyongkim/sasmisc/master/191209french/191209french.sas";
run;

%include a;

%french(F-F_Research_Data_5_Factors_2x3_daily_CSV.zip,f5,F-F_Research_Data_5_Factors_2x3_daily.CSV,mktrf smb hml rmw cma rf);

data f5;
	set f5;
	date=input(put(time,8.),yymmdd8.);
	drop time i;
run;

%let wrds=wrds.wharton.upenn.edu 4016;
signon wrds username=_prompt_;

rsubmit;

data msf;
	set crsp.msf;
	mon=intnx("mon",date,0);
	size=abs(prc)*shrout;
	size1=ifn(permno=lag(permno),lag(size),.);
run;

proc upload data=f5;
run;

proc sort data=crsp.dsf out=dsf;
	where date>="1jul1963"d;
	by date permno;
run;

data dsf;
	merge dsf(in=a) f5;
	by date;
	if a;
	mon=intnx("mon",date,0);
	r=ret-rf;
run;

proc sort;
	by permno date;
run;

proc printto log="nul:";
run;

proc reg noprint;
	by permno mon;
	model r=mktrf smb hml rmw cma;
	output out=dsf r=res;
run;

proc printto;
run;

proc sql;
	create table dsf as
	select *,max(ret) as max,max(res+rf) as imax
	from dsf
	group by permno,mon
	having date=max(date)
	order by permno,date;
quit;

data msf;
	merge msf(in=a) dsf(keep=permno mon max imax);
	by permno mon;
	if a;
	max1=ifn(permno=lag(permno),lag(max),.);
	imax1=ifn(permno=lag(permno),lag(imax),.);
run;

data msenames;
	set crsp.msenames;
	by permno namedt;
	if last.permno then nameendt=intnx("mon",nameendt,0,"e");
run;

proc sql;
	create table msf as
	select a.*
	from msf a join msenames b
	on a.permno=b.permno and namedt<=date<=nameendt and ^missing(ret) and size1>0 and (^missing(max1) or imax1>.) and shrcd in (10,11)
	order by date,permno;
quit;

proc univariate noprint;
	where hexcd=1;
	by date;
	var max1 imax1;
	output out=msf1 pctlpre=max1u imax1u pctlpts=0 10 20 30 40 50 60 70 80 90 100;
run;

proc univariate data=msf noprint;
	where hexcd=1 and ^missing(max1) and imax1>.;
	by date;
	var max1 imax1;
	output out=msf2 pctlpre=max1c imax1c pctlpts=0 10 20 30 40 50 60 70 80 90 100;
run;

data msf;
	merge msf msf1 msf2;
	by date;
	if ^missing(max1) then do;
		if max1<=max1u10 then p1="max1ud01";
		else if max1<=max1u20 then p1="max1ud02";
		else if max1<=max1u30 then p1="max1ud03";
		else if max1<=max1u40 then p1="max1ud04";
		else if max1<=max1u50 then p1="max1ud05";
		else if max1<=max1u60 then p1="max1ud06";
		else if max1<=max1u70 then p1="max1ud07";
		else if max1<=max1u80 then p1="max1ud08";
		else if max1<=max1u90 then p1="max1ud09";
		else p1="max1ud10";
	end;
	if imax1>. then do;
		if imax1<=imax1u10 then p2="imax1ud01";
		else if imax1<=imax1u20 then p2="imax1ud02";
		else if imax1<=imax1u30 then p2="imax1ud03";
		else if imax1<=imax1u40 then p2="imax1ud04";
		else if imax1<=imax1u50 then p2="imax1ud05";
		else if imax1<=imax1u60 then p2="imax1ud06";
		else if imax1<=imax1u70 then p2="imax1ud07";
		else if imax1<=imax1u80 then p2="imax1ud08";
		else if imax1<=imax1u90 then p2="imax1ud09";
		else p2="imax1ud10";
	end;
	if ^missing(max1) and imax1>. then do;
		if max1<=max1c20 then do;
			if imax1<=imax1c20 then p3="max1cimax1c11";
			else if imax1<=imax1c40 then p3="max1cimax1c12";
			else if imax1<=imax1c60 then p3="max1cimax1c13";
			else if imax1<=imax1c80 then p3="max1cimax1c14";
			else p3="max1cimax1c15";
		end;
		else if max1<=max1c40 then do;
			if imax1<=imax1c20 then p3="max1cimax1c21";
			else if imax1<=imax1c40 then p3="max1cimax1c22";
			else if imax1<=imax1c60 then p3="max1cimax1c23";
			else if imax1<=imax1c80 then p3="max1cimax1c24";
			else p3="max1cimax1c25";
		end;
		else if max1<=max1c60 then do;
			if imax1<=imax1c20 then p3="max1cimax1c31";
			else if imax1<=imax1c40 then p3="max1cimax1c32";
			else if imax1<=imax1c60 then p3="max1cimax1c33";
			else if imax1<=imax1c80 then p3="max1cimax1c34";
			else p3="max1cimax1c35";
		end;
		else if max1<=max1c80 then do;
			if imax1<=imax1c20 then p3="max1cimax1c41";
			else if imax1<=imax1c40 then p3="max1cimax1c42";
			else if imax1<=imax1c60 then p3="max1cimax1c43";
			else if imax1<=imax1c80 then p3="max1cimax1c44";
			else p3="max1cimax1c45";
		end;
		else do;
			if imax1<=imax1c20 then p3="max1cimax1c51";
			else if imax1<=imax1c40 then p3="max1cimax1c52";
			else if imax1<=imax1c60 then p3="max1cimax1c53";
			else if imax1<=imax1c80 then p3="max1cimax1c54";
			else p3="max1cimax1c55";
		end;
	end;
run;

proc sort;
	by date max1;
run;

%macro meanstranspose(where,out);

proc means noprint;
	where &where. ne "";
	by date &where.;
	var ret;
	weight size1;
	output out=&out. mean=ret;
run;

proc transpose out=&out.(drop=_:);
	by date;
	id &where.;
	var ret;
run;

%mend;

%meanstranspose(p1,msf1);

proc sort data=msf;
	by date imax1;
run;

%meanstranspose(p2,msf2);

proc sort data=msf;
	by date p3;
run;

%meanstranspose(p3,msf3);

data msf1;
	merge msf1-msf3;
	by date;
run;

endrsubmit;

libname _ server=wrds slibref=work;

proc export data=_.msf1 file="!userprofile\desktop\191220maximax.csv" replace;
run;

quit;
