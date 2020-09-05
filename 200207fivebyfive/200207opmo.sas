/*------------------------------------------------
200207opmo
deviates a bit from /sas/decile/op.sas
------------------------------------------------*/

%let wrds=wrds.wharton.upenn.edu 4016;
signon wrds username=_prompt_;
rsubmit;

/*------------------------------------------------
computes op
------------------------------------------------*/

data op;
	set compa.funda;
	where fyear and indfmt="INDL" and consol="C" and popsrc="D" and datafmt="STD";
	by gvkey fyear;
	if first.fyear;
	be=coalesce(seq,ceq+upstk,at-lt)+coalesce(txditc,0)-coalesce(pstkrv,pstkl,upstk);
	if be>0 then op=(revt-sum(cogs,tie,xsga))/be;
	if op>.;
	keep gvkey fyear datadate op;
run;

proc sql;
	create table op as
		select lpermno,fyear,op
		from op a join crsp.ccmxpf_lnkhist b
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
joins monthly ret and op
------------------------------------------------*/

proc sql;
	create table retop as
		select a.*,op
		from ret a join op b
		on permno=lpermno and ifn(month(date)>6,year(date)-1,year(date)-2)=fyear
		order by date;
quit;

/*------------------------------------------------
computes monthly decile equal/value ret by op
------------------------------------------------*/

proc univariate noprint;
	where exchcd=1;
	by date;
	var op mo;
	output pctlpre=op mo pctlpts=20 40 60 80 out=retopdec;
run;

data retop;
	merge retop retopdec;
	by date;
	if op>op80 then do;
		if mo>mo80 then dec=25;
		else if mo>mo60 then dec=24;
		else if mo>mo40 then dec=23;
		else if mo>mo20 then dec=22;
		else if mo>. then dec=21;
	end;
	else if op>op60 then do;
		if mo>mo80 then dec=20;
		else if mo>mo60 then dec=19;
		else if mo>mo40 then dec=18;
		else if mo>mo20 then dec=17;
		else if mo>. then dec=16;
	end;
	else if op>op40 then do;
		if mo>mo80 then dec=15;
		else if mo>mo60 then dec=14;
		else if mo>mo40 then dec=13;
		else if mo>mo20 then dec=12;
		else if mo>. then dec=11;
	end;
	else if op>op20 then do;
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
	drop op20--mo80;
run;

proc sort;
	by date dec;
run;

proc means noprint;
	by date dec;
	var ret;
	weight size;
	output out=opm mean=;
run;

proc transpose prefix=opm out=opm(keep=date op:);
	by date;
	id dec;
	var ret;
run;

proc means data=retop noprint;
	by date dec;
	var ret;
	output out=opme mean=;
run;

proc transpose prefix=opme out=opme(keep=date op:);
	by date;
	id dec;
	var ret;
run;

data opm;
	merge opm opme;
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
joins daily ret and op
------------------------------------------------*/

proc sql;
	create table retd as
		select a.*,mo
		from retd a join mo b
		on a.permno=b.permno and intnx("mon",a.date,0)=intnx("mon",b.date,0);
quit;

proc sql;
	create table retdop as
		select a.*,op
		from retd a join op b
		on permno=lpermno and ifn(month(date)>6,year(date)-1,year(date)-2)=fyear
		order by date;
quit;

/*------------------------------------------------
computes daily decile equal/value ret by op
------------------------------------------------*/

proc univariate noprint;
	where exchcd=1;
	by date;
	var op mo;
	output pctlpre=op mo pctlpts=20 40 60 80 out=retdopdec;
run;

data retdop;
	merge retdop retdopdec;
	by date;
	if op>op80 then do;
		if mo>mo80 then dec=25;
		else if mo>mo60 then dec=24;
		else if mo>mo40 then dec=23;
		else if mo>mo20 then dec=22;
		else if mo>. then dec=21;
	end;
	else if op>op60 then do;
		if mo>mo80 then dec=20;
		else if mo>mo60 then dec=19;
		else if mo>mo40 then dec=18;
		else if mo>mo20 then dec=17;
		else if mo>. then dec=16;
	end;
	else if op>op40 then do;
		if mo>mo80 then dec=15;
		else if mo>mo60 then dec=14;
		else if mo>mo40 then dec=13;
		else if mo>mo20 then dec=12;
		else if mo>. then dec=11;
	end;
	else if op>op20 then do;
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
	drop op20--mo80;
run;

proc sort;
	by date dec;
run;

proc means noprint;
	by date dec;
	var ret;
	weight size;
	output out=opd mean=;
run;

proc transpose prefix=opd out=opd(keep=date op:);
	by date;
	id dec;
	var ret;
run;

proc means data=retdop noprint;
	by date dec;
	var ret;
	output out=opde mean=;
run;

proc transpose prefix=opde out=opde(keep=date op:);
	by date;
	id dec;
	var ret;
run;

data opd;
	merge opd opde;
	by date;
run;

proc download;
run;

endrsubmit;

proc export data=opm replace file="!userprofile\desktop\opmom.csv";
run;

proc export data=opd replace file="!userprofile\desktop\opmod.csv";
run;
