/*------------------------------------------------
200207szmo
deviates a bit from /sas/decile/sz.sas
------------------------------------------------*/

%let w=wrds.wharton.upenn.edu 4016;
signon w username=_prompt_;
rsubmit;

proc sql;
	create table mexchcd as
		select permno,namedt,case when namedt=max(namedt) then intnx("mon",nameendt,0,"e") else nameendt end as nameendt,shrcd,exchcd
		from crsp.msenames
		where shrcd>.z and exchcd>.z
		group by permno;
quit;

proc printto log="/dev/null";
run;

proc expand data=crsp.msf(keep=permno date ret prc shrout) method=none out=msf;
	by permno;
	id date;
	convert ret=mo/tout=(+1 nomiss movprod 11 -1 trimleft 10 lag 2);
run;

proc printto;
run;

proc sql;
	create table mall as
		select a.permno,date,ret*100 as ret,abs(prc)*shrout/(1+ret) as sz,mo,exchcd
		from msf a join mexchcd b
		on a.permno=b.permno and namedt<=date<=nameendt
		where ret>.z and prc>.z and shrout>.z and mo>.z and shrcd in (10,11)
		order by date;
	create table dall as
		select a.permno,a.date,a.ret*100 as ret,abs(prc)*shrout/(1+a.ret) as sz,b.sz as sz_,mo,c.exchcd
		from (crsp.dsf a join mall b on a.permno=b.permno and intnx("mon",a.date,0)=intnx("mon",b.date,0))
			join crsp.dsenames c on a.permno=c.permno and namedt<=a.date<=nameendt
		where a.ret>.z and prc>.z and shrout>.z and sz_>.z and mo>.z and shrcd in (10,11)
		order by date;
quit;

proc univariate data=mall noprint;
	where exchcd=1;
	by date;
	var sz mo;
	output out=msz pctlpre=sz mo pctlpts=20 40 60 80;
run;

proc univariate data=dall noprint;
	where exchcd=1;
	by date;
	var sz_ mo;
	output out=dsz pctlpre=sz mo pctlpts=20 40 60 80;
run;

data mall;
	merge mall msz;
	by date;
	if sz>sz80 then do;
		if mo>mo80 then rank=25;
		else if mo>mo60 then rank=24;
		else if mo>mo40 then rank=23;
		else if mo>mo20 then rank=22;
		else rank=21;
	end;
	else if sz>sz60 then do;
		if mo>mo80 then rank=20;
		else if mo>mo60 then rank=19;
		else if mo>mo40 then rank=18;
		else if mo>mo20 then rank=17;
		else rank=16;
	end;
	else if sz>sz40 then do;
		if mo>mo80 then rank=15;
		else if mo>mo60 then rank=14;
		else if mo>mo40 then rank=13;
		else if mo>mo20 then rank=12;
		else rank=11;
	end;
	else if sz>sz20 then do;
		if mo>mo80 then rank=10;
		else if mo>mo60 then rank=9;
		else if mo>mo40 then rank=8;
		else if mo>mo20 then rank=7;
		else rank=6;
	end;
	else do;
		if mo>mo80 then rank=5;
		else if mo>mo60 then rank=4;
		else if mo>mo40 then rank=3;
		else if mo>mo20 then rank=2;
		else rank=1;
	end;
run;

proc sort;
	by date rank;
run;

data dall;
	merge dall dsz;
	by date;
	if sz_>sz80 then do;
		if mo>mo80 then rank=25;
		else if mo>mo60 then rank=24;
		else if mo>mo40 then rank=23;
		else if mo>mo20 then rank=22;
		else rank=21;
	end;
	else if sz_>sz60 then do;
		if mo>mo80 then rank=20;
		else if mo>mo60 then rank=19;
		else if mo>mo40 then rank=18;
		else if mo>mo20 then rank=17;
		else rank=16;
	end;
	else if sz_>sz40 then do;
		if mo>mo80 then rank=15;
		else if mo>mo60 then rank=14;
		else if mo>mo40 then rank=13;
		else if mo>mo20 then rank=12;
		else rank=11;
	end;
	else if sz_>sz20 then do;
		if mo>mo80 then rank=10;
		else if mo>mo60 then rank=9;
		else if mo>mo40 then rank=8;
		else if mo>mo20 then rank=7;
		else rank=6;
	end;
	else do;
		if mo>mo80 then rank=5;
		else if mo>mo60 then rank=4;
		else if mo>mo40 then rank=3;
		else if mo>mo20 then rank=2;
		else rank=1;
	end;
run;

proc sort;
	by date rank;
run;

proc means data=mall noprint;
	by date rank;
	var ret;
	weight sz;
	output out=szmv mean=;
run;

proc transpose prefix=szmv out=szmv;
	by date;
	id rank;
	var ret;
run;

proc means data=mall noprint;
	by date rank;
	var ret;
	output out=szme mean=;
run;

proc transpose prefix=szme out=szme;
	by date;
	id rank;
	var ret;
run;

proc means data=dall noprint;
	by date rank;
	var ret;
	weight sz;
	output out=szdv mean=;
run;

proc transpose prefix=szdv out=szdv;
	by date;
	id rank;
	var ret;
run;

proc means data=dall noprint;
	by date rank;
	var ret;
	output out=szde mean=;
run;

proc transpose prefix=szde out=szde;
	by date;
	id rank;
	var ret;
run;

data szm;
	merge szmv(rename=(date=date)) szme;
	by date;
	label date=;
	format date yymmddn8. szm: best8.;
	drop _name_;
run;

proc download;
run;

data szd;
	merge szdv(rename=(date=date)) szde;
	by date;
	label date=;
	format date yymmddn8. szd: best8.;
	drop _name_;
run;

proc download;
run;

endrsubmit;

proc export data=szm replace file="!userprofile\desktop\szmom.csv";
run;

proc export data=szd replace file="!userprofile\desktop\szmod.csv";
run;
