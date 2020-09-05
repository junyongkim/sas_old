/*------------------------------------------------
200207bmmo
deviates a bit from /sas/decile/bm.sas
------------------------------------------------*/

/*------------------------------------------------
downloads historical be
------------------------------------------------*/

filename h "%sysfunc(getoption(work))\h";

proc http url="https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Historical_BE_Data.zip" out=h;
run;

filename h zip "%sysfunc(getoption(work))\h";

data h;
	infile h(DFF_BE_With_Nonindust.txt);
	input lpermno b e _1926-_2001;
run;

filename h;

proc transpose out=h;
	by lpermno b e;
run;

data h;
	set h;
	fyear=input(substr(_name_,2),4.)-1;
	be=col1;
	if b<=fyear+1<=e;
	keep lpermno fyear be;
run;

%let wrds=wrds.wharton.upenn.edu 4016;
signon wrds username=_prompt_;
rsubmit;

proc upload;
run;

proc sql;
	create table h as
		select lpermno,fyear,be/abs(prc)/shrout*1000 as bm
		from h a join crsp.msf b
		on lpermno=permno and fyear=year(date)
		where month(date)=12 and be>0 and abs(prc)>0 and shrout>0
		order by lpermno,fyear;
quit;

/*------------------------------------------------
computes bm
------------------------------------------------*/

data bm;
	set compa.funda;
	where fyear and indfmt="INDL" and consol="C" and popsrc="D" and datafmt="STD";
	by gvkey fyear;
	if first.fyear;
	be=coalesce(seq,ceq+upstk,at-lt)+coalesce(txditc,0)-coalesce(pstkrv,pstkl,upstk);
	me=prcc_c*csho;
	if be>0 and me>0 then bm=be/me;
	if bm>.;
	keep gvkey fyear datadate bm;
run;

proc sql;
	create table bm as
		select lpermno,fyear,bm
		from bm a join crsp.ccmxpf_lnkhist b
		on a.gvkey=b.gvkey and linkdt<=datadate<=coalesce(linkenddt,"31dec2019"d)
		where linkprim in ("P","C") and linktype in ("LC","LU")
		order by lpermno,fyear;
quit;

data bm;
	merge h bm;
	by lpermno fyear;
run;

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
joins monthly ret and bm
------------------------------------------------*/

proc sql;
	create table retbm as
		select a.*,bm
		from ret a join bm b
		on permno=lpermno and ifn(month(date)>6,year(date)-1,year(date)-2)=fyear
		order by date;
quit;

/*------------------------------------------------
computes monthly decile equal/value ret by bm
------------------------------------------------*/

proc univariate noprint;
	where exchcd=1;
	by date;
	var bm mo;
	output pctlpre=bm mo pctlpts=20 40 60 80 out=retbmdec;
run;

data retbm;
	merge retbm retbmdec;
	by date;
	if bm>bm80 then do;
		if mo>mo80 then dec=25;
		else if mo>mo60 then dec=24;
		else if mo>mo40 then dec=23;
		else if mo>mo20 then dec=22;
		else if mo>. then dec=21;
	end;
	else if bm>bm60 then do;
		if mo>mo80 then dec=20;
		else if mo>mo60 then dec=19;
		else if mo>mo40 then dec=18;
		else if mo>mo20 then dec=17;
		else if mo>. then dec=16;
	end;
	else if bm>bm40 then do;
		if mo>mo80 then dec=15;
		else if mo>mo60 then dec=14;
		else if mo>mo40 then dec=13;
		else if mo>mo20 then dec=12;
		else if mo>. then dec=11;
	end;
	else if bm>bm20 then do;
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
	drop bm20--mo80;
run;

proc sort;
	by date dec;
run;

proc means noprint;
	by date dec;
	var ret;
	weight size;
	output out=bmm mean=;
run;

proc transpose prefix=bmm out=bmm(keep=date bm:);
	by date;
	id dec;
	var ret;
run;

proc means data=retbm noprint;
	by date dec;
	var ret;
	output out=bmme mean=;
run;

proc transpose prefix=bmme out=bmme(keep=date bm:);
	by date;
	id dec;
	var ret;
run;

data bmm;
	merge bmm bmme;
	by date;
	if n(of bmm1--bmme25);
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
joins daily ret and bm
------------------------------------------------*/

proc sql;
	create table retd as
		select a.*,mo
		from retd a join mo b
		on a.permno=b.permno and intnx("mon",a.date,0)=intnx("mon",b.date,0);
quit;

proc sql;
	create table retdbm as
		select a.*,bm
		from retd a join bm b
		on permno=lpermno and ifn(month(date)>6,year(date)-1,year(date)-2)=fyear
		order by date;
quit;

/*------------------------------------------------
computes daily decile equal/value ret by bm
------------------------------------------------*/

proc univariate noprint;
	where exchcd=1;
	by date;
	var bm mo;
	output pctlpre=bm mo pctlpts=20 40 60 80 out=retdbmdec;
run;

data retdbm;
	merge retdbm retdbmdec;
	by date;
	if bm>bm80 then do;
		if mo>mo80 then dec=25;
		else if mo>mo60 then dec=24;
		else if mo>mo40 then dec=23;
		else if mo>mo20 then dec=22;
		else if mo>. then dec=21;
	end;
	else if bm>bm60 then do;
		if mo>mo80 then dec=20;
		else if mo>mo60 then dec=19;
		else if mo>mo40 then dec=18;
		else if mo>mo20 then dec=17;
		else if mo>. then dec=16;
	end;
	else if bm>bm40 then do;
		if mo>mo80 then dec=15;
		else if mo>mo60 then dec=14;
		else if mo>mo40 then dec=13;
		else if mo>mo20 then dec=12;
		else if mo>. then dec=11;
	end;
	else if bm>bm20 then do;
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
	drop bm20--mo80;
run;

proc sort;
	by date dec;
run;

proc means noprint;
	by date dec;
	var ret;
	weight size;
	output out=bmd mean=;
run;

proc transpose prefix=bmd out=bmd(keep=date bm:);
	by date;
	id dec;
	var ret;
run;

proc means data=retdbm noprint;
	by date dec;
	var ret;
	output out=bmde mean=;
run;

proc transpose prefix=bmde out=bmde(keep=date bm:);
	by date;
	id dec;
	var ret;
run;

data bmd;
	merge bmd bmde;
	by date;
	if n(of bmd1--bmde25);
run;

proc download;
run;

endrsubmit;

proc export data=bmm replace file="!userprofile\desktop\bmmom.csv";
run;

proc export data=bmd replace file="!userprofile\desktop\bmmod.csv";
run;
