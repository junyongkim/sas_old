/*------------------------------------------------
200207inmo
deviates a bit from /sas/decile/in.sas
------------------------------------------------*/

%let wrds=wrds.wharton.upenn.edu 4016;
signon wrds username=_prompt_;
rsubmit;

/*------------------------------------------------
computes in
------------------------------------------------*/

data in;
	set compa.funda;
	where fyear and indfmt="INDL" and consol="C" and popsrc="D" and datafmt="STD";
	by gvkey fyear;
	if first.fyear;
	if at>0;
	keep gvkey fyear datadate at;
run;

proc sql;
	create table in as
	select a.gvkey,a.fyear,a.datadate,(a.at-b.at)/b.at as in
	from in a join in b
	on a.gvkey=b.gvkey and a.fyear=b.fyear+1;
quit;

proc sql;
	create table in as
		select lpermno,fyear,in
		from in a join crsp.ccmxpf_lnkhist b
		on a.gvkey=b.gvkey and linkdt<=datadate<=coalesce(linkenddt,"31dec2019"d)
		where linkprim in ("P","C") and linktype in ("LC","LU")
		order by lpermno,fyear;
quit;

/*------------------------------------------------
computes monthly ret
------------------------------------------------*/

data exchcd;
	set crsp.msenames;
	by permno;
	if last.gvkey then nameendt=intnx("mon",nameendt,1)-1;
	keep permno namedt nameendt shrcd exchcd;
run;

proc expand data=crsp.msf method=none out=mo;
	by permno;
	id date;
	convert ret=mo/tout=(lag 2 +1 nomiss movprod 11 -1 trimleft 10);
run;

proc sql;
	create table ret as
		select a.permno,date as date label="",ret*100 as ret format=best8.,abs(prc)*shrout/(1+ret) as size,exchcd,mo
		from mo a join exchcd b
		on a.permno=b.permno and namedt<=date<=nameendt
		where ret>.z and abs(prc) and shrout and 9<shrcd<12;
quit;

/*------------------------------------------------
joins monthly ret and in
------------------------------------------------*/

proc sql;
	create table retin as
		select a.*,in
		from ret a join in b
		on permno=lpermno and ifn(month(date)>6,year(date)-1,year(date)-2)=fyear
		order by date;
quit;

/*------------------------------------------------
computes monthly decile equal/value ret by in
------------------------------------------------*/

proc univariate noprint;
	where exchcd=1;
	by date;
	var in mo;
	output pctlpre=in mo pctlpts=20 40 60 80 out=retindec;
run;

data retin;
	merge retin retindec;
	by date;
	if in>in80 then do;
		if mo>mo80 then dec=25;
		else if mo>mo60 then dec=24;
		else if mo>mo40 then dec=23;
		else if mo>mo20 then dec=22;
		else if mo>. then dec=21;
	end;
	else if in>in60 then do;
		if mo>mo80 then dec=20;
		else if mo>mo60 then dec=19;
		else if mo>mo40 then dec=18;
		else if mo>mo20 then dec=17;
		else if mo>. then dec=16;
	end;
	else if in>in40 then do;
		if mo>mo80 then dec=15;
		else if mo>mo60 then dec=14;
		else if mo>mo40 then dec=13;
		else if mo>mo20 then dec=12;
		else if mo>. then dec=11;
	end;
	else if in>in20 then do;
		if mo>mo80 then dec=10;
		else if mo>mo60 then dec=9;
		else if mo>mo40 then dec=8;
		else if mo>mo20 then dec=7;
		else if mo>. then dec=6;
	end;
	else do;
		if mo>mo80 then dec=5;
		else if mo>mo60 then dec=4;
		else if mo>mo40 then dec=3;
		else if mo>mo20 then dec=2;
		else if mo>. then dec=1;
	end;
	drop in20--mo80;
run;

proc sort;
	by date dec;
run;

proc means noprint;
	by date dec;
	var ret;
	weight size;
	output out=inm mean=;
run;

proc transpose prefix=inm out=inm(keep=date in:);
	by date;
	id dec;
	var ret;
run;

proc means data=retin noprint;
	by date dec;
	var ret;
	output out=inme mean=;
run;

proc transpose prefix=inme out=inme(keep=date in:);
	by date;
	id dec;
	var ret;
run;

data inm;
	merge inm inme;
	by date;
run;

proc download;
run;

/*------------------------------------------------
computes daily ret
------------------------------------------------*/

proc sql;
	create table retd as
		select a.permno,date as date label="",ret*100 as ret format=best8.,abs(prc)*shrout/(1+ret) as size,exchcd
		from crsp.dsf a join crsp.dsenames b
		on a.permno=b.permno and namedt<=date<=nameendt
		where ret>.z and abs(prc) and shrout and 9<shrcd<12;
quit;

/*------------------------------------------------
joins daily ret and in
------------------------------------------------*/

proc sql;
	create table retd as
		select a.*,mo
		from retd a join mo b
		on a.permno=b.permno and intnx("mon",a.date,0)=intnx("mon",b.date,0);
quit;

proc sql;
	create table retdin as
		select a.*,in
		from retd a join in b
		on permno=lpermno and ifn(month(date)>6,year(date)-1,year(date)-2)=fyear
		order by date;
quit;

/*------------------------------------------------
computes daily decile equal/value ret by in
------------------------------------------------*/

proc univariate noprint;
	where exchcd=1;
	by date;
	var in mo;
	output pctlpre=in mo pctlpts=20 40 60 80 out=retdindec;
run;

data retdin;
	merge retdin retdindec;
	by date;
	if in>in80 then do;
		if mo>mo80 then dec=25;
		else if mo>mo60 then dec=24;
		else if mo>mo40 then dec=23;
		else if mo>mo20 then dec=22;
		else if mo>. then dec=21;
	end;
	else if in>in60 then do;
		if mo>mo80 then dec=20;
		else if mo>mo60 then dec=19;
		else if mo>mo40 then dec=18;
		else if mo>mo20 then dec=17;
		else if mo>. then dec=16;
	end;
	else if in>in40 then do;
		if mo>mo80 then dec=15;
		else if mo>mo60 then dec=14;
		else if mo>mo40 then dec=13;
		else if mo>mo20 then dec=12;
		else if mo>. then dec=11;
	end;
	else if in>in20 then do;
		if mo>mo80 then dec=10;
		else if mo>mo60 then dec=9;
		else if mo>mo40 then dec=8;
		else if mo>mo20 then dec=7;
		else if mo>. then dec=6;
	end;
	else do;
		if mo>mo80 then dec=5;
		else if mo>mo60 then dec=4;
		else if mo>mo40 then dec=3;
		else if mo>mo20 then dec=2;
		else if mo>. then dec=1;
	end;
	drop in20--mo80;
run;

proc sort;
	by date dec;
run;

proc means noprint;
	by date dec;
	var ret;
	weight size;
	output out=ind mean=;
run;

proc transpose prefix=ind out=ind(keep=date in:);
	by date;
	id dec;
	var ret;
run;

proc means data=retdin noprint;
	by date dec;
	var ret;
	output out=inde mean=;
run;

proc transpose prefix=inde out=inde(keep=date in:);
	by date;
	id dec;
	var ret;
run;

data ind;
	merge ind inde;
	by date;
run;

proc download;
run;

endrsubmit;

proc export data=inm replace file="!userprofile\desktop\inmom.csv";
run;

proc export data=ind replace file="!userprofile\desktop\inmod.csv";
run;
