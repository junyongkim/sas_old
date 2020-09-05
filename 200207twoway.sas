/*------------------------------------------------
200207twoway
computes 5x5 (june) portfolios by crsp + compustat
------------------------------------------------*/

%let wrds=wrds.wharton.upenn.edu 4016;
signon wrds username=_prompt_;
rsubmit;

/*------------------------------------------------
variable 1
------------------------------------------------*/

data _1;
	set crsp.msf;
	_1=abs(prc)*shrout;
	if month(date)=6 and _1;
	keep permno date _1;
run;

/*------------------------------------------------
variable 2
------------------------------------------------*/

data _2;
	set comp.funda;
	where fyear and indfmt="INDL" and consol="C" and popsrc="D" and datafmt="STD";
	by gvkey fyear datadate;
	if first.fyear;
	be=coalesce(seq,ceq+upstk,at-lt)+coalesce(txditc,0)-coalesce(pstkrv,pstkl,upstk);
	me=prcc_c*csho;
	if be>0 and me then _2=be/me;
	if _2;
	keep gvkey fyear datadate _2;
run;

proc sql;
	create table _2 as
	select lpermno,fyear,_2
	from _2 a join crsp.ccmxpf_lnkhist b
	on a.gvkey=b.gvkey and linkdt<=datadate<=coalesce(linkenddt,"31dec2999"d)
	where linkprim in ("P","C") and linktype in ("LC","LU");
quit;

/*------------------------------------------------
variable 1 + variable 2
------------------------------------------------*/

proc sql;
	create table _3 as
	select permno,date,_1,_2
	from _1 join _2
	on permno=lpermno and year(date)-1=fyear;
quit;

/*------------------------------------------------
shrcd + exchcd
------------------------------------------------*/

data _4;
	set crsp.msenames;
	by permno;
	if last.permno then nameendt=intnx("mon",nameendt,1)-1;
	keep permno namedt nameendt shrcd exchcd;
run;

proc sql;
	create table _3 as
	select a.*,exchcd
	from _3 a join _4 b
	on a.permno=b.permno and namedt<=date<=nameendt
	where 9<shrcd<12
	order by date;
quit;

/*------------------------------------------------
sorting
------------------------------------------------*/

proc univariate noprint;
	where exchcd=1;
	by date;
	var _1 _2;
	output pctlpre=_1 _2 pctlpts=20 40 60 80 out=_5;
run;

data _3;
	merge _3 _5;
	by date;
	if _1>_180 then do;
		if _2>_280 then _3=25;
		else if _2>_260 then _3=24;
		else if _2>_240 then _3=23;
		else if _2>_220 then _3=22;
		else _3=21;
	end;
	else if _1>_160 then do;
		if _2>_280 then _3=20;
		else if _2>_260 then _3=19;
		else if _2>_240 then _3=18;
		else if _2>_220 then _3=17;
		else _3=16;
	end;
	else if _1>_140 then do;
		if _2>_280 then _3=15;
		else if _2>_260 then _3=14;
		else if _2>_240 then _3=13;
		else if _2>_220 then _3=12;
		else _3=11;
	end;
	else if _1>_120 then do;
		if _2>_280 then _3=10;
		else if _2>_260 then _3=9;
		else if _2>_240 then _3=8;
		else if _2>_220 then _3=7;
		else _3=6;
	end;
	else do;
		if _2>_280 then _3=5;
		else if _2>_260 then _3=4;
		else if _2>_240 then _3=3;
		else if _2>_220 then _3=2;
		else _3=1;
	end;
	keep permno date _3;
run;

/*------------------------------------------------
sorting + delisting-adjusted return
------------------------------------------------*/

proc sql;
	create table _6 as
	select a.permno,date as date label="",(1+ret)*sum(1,dlret)*100-100 as ret format=best8.,abs(prc)*shrout/(1+ret) as size
	from crsp.msf a left join crsp.msedelist b
	on a.permno=b.permno and intnx("mon",date,0)=intnx("mon",dlstdt,0);
quit;

proc sql;
	create table _6 as
	select a.*,_3
	from _6 a join _3 b
	on a.permno=b.permno and ifn(month(a.date)>6,year(a.date),year(a.date)-1)=year(b.date)
	where ret and size
	order by date,_3;
quit;

/*------------------------------------------------
portfolio return
------------------------------------------------*/

proc means noprint;
	by date _3;
	var ret;
	weight size;
	output out=_7 mean=;
run;

proc transpose out=_7(drop=_name_);
	by date;
	id _3;
	var ret;
run;

proc download;
run;

endrsubmit;

proc export replace file="!userprofile\desktop\200207twoway.csv";
run;
