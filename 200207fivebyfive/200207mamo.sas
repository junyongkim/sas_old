/*************************************************
200207mamo
deviates a bit from /sas/decile/max.sas
*************************************************/

%let wrds=wrds.wharton.upenn.edu 4016;
signon wrds username=_prompt_;

rsubmit;

proc sql;
	create table max as
	select permno,date,max(ret) as max
	from crsp.dsf
	where ret>.z
	group by permno,intnx("mon",date,0)
	having date=max(date);
quit;

proc printto log="/dev/null";
run;

proc expand data=crsp.msf(keep=permno date ret) method=none out=re(drop=ret);
	by permno;
	id date;
	convert ret=re/tout=(+1 nomiss movprod 11 -1 trimleft 10 lag 2);
run;

proc printto;
run;

proc sql;
	create table msf as
	select a.permno,a.date as date,ret*100 as ret,abs(prc)*shrout/(1+ret) as size,max,re
	from (crsp.msf a left join max b
	on a.permno=b.permno and intnx("mon",a.date,0)=intnx("mon",b.date,1)) left join re c on a.permno=c.permno and a.date=c.date;
	create table dsf as
	select a.permno,a.date as date,ret*100 as ret,abs(prc)*shrout/(1+ret) as size,max,re
	from (crsp.dsf a left join max b
	on a.permno=b.permno and intnx("mon",a.date,0)=intnx("mon",b.date,1)) left join re c on a.permno=c.permno and intnx("mon",a.date,0)=intnx("mon",c.date,0);
quit;

proc sql;
	create table exchcd as
	select permno,namedt,ifn(namedt=max(namedt),intnx("mon",nameendt,0,"e"),nameendt) as nameendt,shrcd,exchcd
	from crsp.msenames
	group by permno;
quit;

proc sql;
	create table msfe as
	select a.*,exchcd
	from msf a join exchcd b
	on a.permno=b.permno and namedt<=date<=nameendt
	where ret>.z and size>0 and max>.z and shrcd in (10,11)
	order by date;
	create table dsfe as
	select a.*,exchcd
	from dsf a join crsp.dsenames b
	on a.permno=b.permno and namedt<=date<=nameendt
	where ret>.z and size>0 and max>.z and shrcd in (10,11)
	order by date;
quit;

proc univariate data=msfe noprint;
	where exchcd=1;
	by date;
	var max re;
	output out=msfd pctlpre=max re pctlpts=20 40 60 80;
run;

proc univariate data=dsfe noprint;
	where exchcd=1;
	by date;
	var max re;
	output out=dsfd pctlpre=max re pctlpts=20 40 60 80;
run;

data msfa;
	merge msfe msfd;
	by date;
	if max>max80 then do;
		if re>re80 then rank=25;
		else if re>re60 then rank=24;
		else if re>re40 then rank=23;
		else if re>re20 then rank=22;
		else if re>. then rank=21;
	end;
	else if max>max60 then do;
		if re>re80 then rank=20;
		else if re>re60 then rank=19;
		else if re>re40 then rank=18;
		else if re>re20 then rank=17;
		else if re>. then rank=16;
	end;
	else if max>max40 then do;
		if re>re80 then rank=15;
		else if re>re60 then rank=14;
		else if re>re40 then rank=13;
		else if re>re20 then rank=12;
		else if re>. then rank=11;
	end;
	else if max>max20 then do;
		if re>re80 then rank=10;
		else if re>re60 then rank=9;
		else if re>re40 then rank=8;
		else if re>re20 then rank=7;
		else if re>. then rank=6;
	end;
	else if max>. then do;
		if re>re80 then rank=5;
		else if re>re60 then rank=4;
		else if re>re40 then rank=3;
		else if re>re20 then rank=2;
		else if re>. then rank=1;
	end;
run;

proc sort;
	by date rank;
run;

data dsfa;
	merge dsfe dsfd;
	by date;
	if max>max80 then do;
		if re>re80 then rank=25;
		else if re>re60 then rank=24;
		else if re>re40 then rank=23;
		else if re>re20 then rank=22;
		else if re>. then rank=21;
	end;
	else if max>max60 then do;
		if re>re80 then rank=20;
		else if re>re60 then rank=19;
		else if re>re40 then rank=18;
		else if re>re20 then rank=17;
		else if re>. then rank=16;
	end;
	else if max>max40 then do;
		if re>re80 then rank=15;
		else if re>re60 then rank=14;
		else if re>re40 then rank=13;
		else if re>re20 then rank=12;
		else if re>. then rank=11;
	end;
	else if max>max20 then do;
		if re>re80 then rank=10;
		else if re>re60 then rank=9;
		else if re>re40 then rank=8;
		else if re>re20 then rank=7;
		else if re>. then rank=6;
	end;
	else if max>. then do;
		if re>re80 then rank=5;
		else if re>re60 then rank=4;
		else if re>re40 then rank=3;
		else if re>re20 then rank=2;
		else if re>. then rank=1;
	end;
run;

proc sort;
	by date rank;
run;

proc means data=msfa noprint;
	by date rank;
	var ret;
	weight size;
	output out=maxmv mean=;
run;

proc means data=msfa noprint;
	by date rank;
	var ret;
	output out=maxme mean=;
run;

proc means data=dsfa noprint;
	by date rank;
	var ret;
	weight size;
	output out=maxdv mean=;
run;

proc means data=dsfa noprint;
	by date rank;
	var ret;
	output out=maxde mean=;
run;

proc transpose data=maxmv prefix=maxmv out=maxmv(drop=_:);
	by date;
	id rank;
	var ret;
run;

proc transpose data=maxme prefix=maxme out=maxme(drop=_:);
	by date;
	id rank;
	var ret;
run;

proc transpose data=maxdv prefix=maxdv out=maxdv(drop=_:);
	by date;
	id rank;
	var ret;
run;

proc transpose data=maxde prefix=maxde out=maxde(drop=_:);
	by date;
	id rank;
	var ret;
run;
rsubmit;
data maxm;
	merge maxmv maxme;
	by date;
	if n(of maxmv1--maxme25);
	label date=;
	format date yymmddn8. maxm: best8.;
run;

data maxd;
	merge maxdv maxde;
	by date;
	if n(of maxdv1--maxde25);
	label date=;
	format date yymmddn8. maxd: best8.;
run;

proc download data=maxm;
run;

proc download data=maxd;
run;

endrsubmit;

proc export data=maxm replace file="!userprofile\desktop\mamom.csv";
run;

proc export data=maxd replace file="!userprofile\desktop\mamod.csv";
run;
