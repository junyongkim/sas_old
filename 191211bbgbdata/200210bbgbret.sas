/*------------------------------------------------
downloads the bbgbdata file
------------------------------------------------*/
filename bbgbdata temp;

proc http url="https://raw.githubusercontent.com/junyongkim/misc/master/sas/191211bbgbdata/191226BBGBdata.xls" out=bbgbdata;
run;

proc import file=bbgbdata dbms=xls replace out=bbgbdata;
run;

%let wrds=wrds.wharton.upenn.edu 4016;
signon wrds username=_prompt_;
rsubmit;

proc upload;
run;

/*------------------------------------------------
joins the bbgbdata to returns to compute betas
------------------------------------------------*/
proc sql;
	create table beta as
		select permno,a.date,ret,r_me,vs,ty
		from crsp.msf a left join bbgbdata b
		on put(a.date,yymmn6.)=put(b.date,6.)
		order by permno,date;
quit;

/*------------------------------------------------
quarterizes the observations
------------------------------------------------*/
proc printto log="/dev/null";
run;

proc expand method=none out=beta;
	by permno;
	id date;
	convert ret/tout=(nomiss movsum 3 trimleft 2);
	convert r_me/tout=(nomiss movsum 3 trimleft 2);
	convert vs/tout=(nomiss dif 3);
	convert ty/tout=(nomiss dif 3);
run;

proc printto;
run;

/*------------------------------------------------
repeats each observation 36 times for betas
------------------------------------------------*/
data beta(drop=i);
	set beta;
	do i=1 to 36;
		datei=intnx("mon",date,i);
		output;
	end;
run;

/*------------------------------------------------
computes betas
------------------------------------------------*/
proc sort;
	by permno datei;
run;

proc printto log="/dev/null";
run;

proc reg noprint outest=beta(keep=permno datei r_me vs ty _edf_ where=(_edf_=32));
	by permno datei;
	model ret=r_me vs ty/edf;
quit;

proc printto;
run;

/*------------------------------------------------
joins returns and betas
------------------------------------------------*/
data exchcd;
	set crsp.msenames;
	by permno;
	if last.permno then nameendt=intnx("mon",nameendt,1)-1;
	keep permno namedt nameendt shrcd exchcd;
run;

proc sql;
	create table ret as
		select a.permno,date as date label="",ret*100 as ret format=best8.,abs(prc)*shrout/(1+ret) as size,shrcd,exchcd
		from crsp.msf a left join exchcd b
		on a.permno=b.permno and namedt<=date<=nameendt;
	create table ret as
		select a.*,r_me,vs,ty
		from ret a left join beta b
		on a.permno=b.permno and intnx("mon",a.date,0)=b.datei
		order by date;
quit;

/*------------------------------------------------
groups by vs and ty
------------------------------------------------*/
proc univariate noprint;
	where 9<shrcd<12 and exchcd=1;
	by date;
	var vs ty;
	output pctlpre=vs ty pctlpts=50 out=break;
run;

data ret;
	merge ret break;
	by date;
	if vs>vs50 then vs=1;
	else if vs>. then vs=0;
	if ty>ty50 then ty=1;
	else if ty>. then ty=0;
	drop vs50 ty50;
run;

/*------------------------------------------------
subgroups by r_me after vs
------------------------------------------------*/
proc sort;
	by date vs;
run;

proc univariate noprint;
	where 9<shrcd<12 and exchcd=1;
	by date vs;
	var r_me;
	output pctlpre=r_me pctlpts=20 40 60 80 out=break;
run;

data ret;
	merge ret break;
	by date vs;
	if vs=1 then do;
		if r_me>r_me80 then vs=9;
		else if r_me>r_me60 then vs=8;
		else if r_me>r_me40 then vs=7;
		else if r_me>r_me20 then vs=6;
		else if r_me>. then vs=5;
	end;
	else if vs=0 then do;
		if r_me>r_me80 then vs=4;
		else if r_me>r_me60 then vs=3;
		else if r_me>r_me40 then vs=2;
		else if r_me>r_me20 then vs=1;
		else if r_me>. then vs=0;
	end;
	drop r_me20--r_me80;
run;

/*------------------------------------------------
subgroups by r_me after ty
------------------------------------------------*/
proc sort;
	by date ty;
run;

proc univariate noprint;
	where 9<shrcd<12 and exchcd=1;
	by date ty;
	var r_me;
	output pctlpre=r_me pctlpts=20 40 60 80 out=break;
run;

data ret;
	merge ret break;
	by date ty;
	if ty=1 then do;
		if r_me>r_me80 then ty=9;
		else if r_me>r_me60 then ty=8;
		else if r_me>r_me40 then ty=7;
		else if r_me>r_me20 then ty=6;
		else if r_me>. then ty=5;
	end;
	else if ty=0 then do;
		if r_me>r_me80 then ty=4;
		else if r_me>r_me60 then ty=3;
		else if r_me>r_me40 then ty=2;
		else if r_me>r_me20 then ty=1;
		else if r_me>. then ty=0;
	end;
	drop r_me:;
run;

/*------------------------------------------------
2x5 portfolios by vs and r_me
------------------------------------------------*/
proc sort;
	by date vs;
run;

proc means noprint;
	where vs>. and ret>. and size>. and 9<shrcd<12;
	by date vs;
	var ret;
	weight size;
	output mean= out=vs;
run;

proc transpose prefix=vs out=vs(drop=_name_);
	by date;
	id vs;
	var ret;
run;

/*------------------------------------------------
2x5 portfolios by ty and r_me
------------------------------------------------*/
proc sort data=ret;
	by date ty;
run;

proc means noprint;
	where ty>. and ret>. and size>. and 9<shrcd<12;
	by date ty;
	var ret;
	weight size;
	output mean= out=ty;
run;

proc transpose prefix=ty out=ty(drop=_name_);
	by date;
	id ty;
	var ret;
run;

/*------------------------------------------------
merges the vs and ty portfolios
------------------------------------------------*/
data ret;
	merge vs ty;
	by date;
run;

proc download;
run;

endrsubmit;

proc export replace file="!userprofile\desktop\200210bbgbret.csv";
run;
