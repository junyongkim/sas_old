/*************************************************
191103bbgb
replicates the results of campbell and vuolteenaho
*************************************************/

resetline;
dm"log;clear;output;clear;";
option nodate nonumber nolabel ls=128 ps=max;

proc datasets kill nolist;
run;

/*download the raw data*/
/*file and sheet are case-sensitive, while url is not*/

%macro http(url,file,dbms,out);

filename _0 "%sysfunc(getoption(work))\_.zip";

proc http method="get" out=_0
	url="&url.";
run;

filename _0 zip "%sysfunc(getoption(work))\_.zip";
filename _1 temp;

data _null_;
	infile _0(&file.) length=length eof=eof lrecl=32767 recfm=f unbuf;
	file _1 lrecl=32767 recfm=n;
	input;
	put _infile_ $varying32767. length;
	return;
	eof:stop;
run;

proc import file=_1 dbms=&dbms. out=&out. replace;
	getnames=no;
run;

%mend;

/*campbell and vuolteenaho (2004)*/

/*%http(http://mindhunter.dothome.co.kr/dec04_data_campbell.zip,BBGBdata.xls,xls,bbgb);*/
filename _1 temp;proc http url="https://raw.githubusercontent.com/junyongkim/misc/master/sas/191211bbgbdata/191226BBGBdata.xls" out=_1;run;proc import file=_1 dbms=xls replace out=bbgb;getnames=no;run;
/*size-bm, size-op, size-inv, size-mom, size-rev*/

%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_5x5_CSV.zip,25_Portfolios_5x5.CSV,csv,bm);
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_OP_5x5_CSV.zip,25_Portfolios_ME_OP_5x5.CSV,csv,op);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_INV_5x5_CSV.zip,25_Portfolios_ME_INV_5x5.CSV,csv,in);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_Prior_12_2_CSV.zip,25_Portfolios_ME_Prior_12_2.CSV,csv,mo);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_Prior_60_13_CSV.zip,25_Portfolios_ME_Prior_60_13.CSV,csv,re);*/

/*size-acc, size-bet, size-iss, size-ivol, lowercase csv in extension*/

/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_AC_5x5_CSV.zip,25_Portfolios_ME_AC_5x5.csv,csv,ac);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_BETA_5x5_CSV.zip,25_Portfolios_ME_BETA_5x5.csv,csv,et);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_NI_5x5_CSV.zip,25_Portfolios_ME_NI_5x5.csv,csv,ni);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_RESVAR_5x5_CSV.zip,25_Portfolios_ME_RESVAR_5x5.csv,csv,vo);*/

/*cv2004 data cleansing*/

data _bbgb(keep=month m ty pe vs em mem ncf ndr f r01-r20);
	set bbgb(rename=(f=f_ m=m_));
	where substr(a,1,1) in ("1","2");
	month=intnx("month",input(a,yymmn6.),0,"e");
	m=input(b,16.);
	ty=input(c,16.);
	pe=input(d,16.);
	vs=input(e,16.);
	if f_="NaN" then em=.;
	else em=input(f_,16.);
	mem=m-em;
	if h="NaN" then ncf=.;
	else ncf=input(h,16.);
	if g="NaN" then ndr=.;
	else ndr=input(g,16.);
	if i="NaN" then f=.;
	else f=exp(input(i,16.))-1;
	array pf(*) ai--bb;
	array pf_(*) r01-r20;
	do i_=1 to dim(pf);
		if pf(i_)="NaN" then pf_(i_)=.;
		else pf_(i_)=input(pf(i_),16.);
	end;
run;

/*french data cleansing*/

%macro data(data);

data _&data.(keep=month s:);
	set &data.;
	where substr(var1,1,1) in ("1","2");
	if var1<lag(var1) then delete+1;
	if delete then delete;
	month=intnx("month",input(var1,yymmn6.),0,"e");
	%do i=1 %to 5;
	%do j=1 %to 5;
	s&i.%substr(&data.,1,1)&j.=input(var%eval(5*&i.+&j.-4),16.)/100;
	%end;
	%end;
run;

%mend;

%data(bm);
/*%data(op);*/
/*%data(in);*/
/*%data(mo);*/
/*%data(re);*/
/*%data(ac);*/
/*%data(et);*/
/*%data(ni);*/
/*%data(vo);*/

/*replicate cv2004 table 1*/

proc iml;
	use _bbgb;
		read all var{m ty pe vs} into v;
	close _bbgb;
	table1=(mean(v)`||
		median(v)`||
		std(v)`||
		(min(v[,1])//min(v[,2])//min(v[,3])//min(v[,4]))||
		(max(v[,1])//max(v[,2])//max(v[,3])//max(v[,4]))||
		vecdiag(corr(v[1:876,]||v[2:877,])[5:8,1:4]))//
		(corr(v[1:876,]||v[2:877,])[,1:4]||j(8,2,.));
	print table1[format=8.3];
quit;

/*replicate cv2004 table 2 and table 3*/

ods listing close;
ods results=off;
ods output anova=_bbgb2;

proc varmax data=_bbgb print=diagnose outest=_bbgb1;
	model m ty pe vs/p=1;
	output lead=0 out=_bbgb0(keep=res:);
run;

ods output close;
ods results=on;
ods listing;

proc iml;
	use _bbgb0;
		read all var{res1 res2 res3 res4} into u;
	close _bbgb0;
	use _bbgb1 where(type="EST");
		read all var{ar1_1 ar1_2 ar1_3 ar1_4} into gamma;
	close _bbgb1;
	t=nrow(u);
	rho=0.95**(1/12);
	e1={1,0,0,0};
	lambda=rho*gamma*inv(i(4)-rho*gamma);
	function=(lambda`*e1+e1)||(lambda`*e1);
	news=u[2:t,]*function;
	_bbgb00={. .}//news;
	_bbgb10=shape(function||j(4,2,.),8);
	create _bbgb00 from _bbgb00;
		append from _bbgb00;
	close _bbgb00;
	create _bbgb10 from _bbgb10;
		append from _bbgb10;
	close _bbgb10;
quit;

data _bbgb0;
	merge _bbgb(keep=month) _bbgb0 _bbgb00;
	rename col1=RES5 col2=RES6;
run;

proc corr cov noprint out=_bbgb3;
	var res:;
run;

data _bbgb1;
	merge _bbgb1 _bbgb10;
run;

proc delete data=_bbgb00 _bbgb10;
run;

/*bootstraps for news*/

%let reps=250;

proc surveyselect data=_bbgb0(keep=month res1-res4) method=urs outhits samprate=1 reps=&reps. seed=1 outrandom noprint out=_bbgb4;
	where "1jan1929"d<=month<="30jun1963"d;
run;

proc surveyselect data=_bbgb0(keep=month res1-res4) method=urs outhits samprate=1 reps=&reps. seed=1 outrandom noprint out=_bbgb40;
	where "1jul1963"d<=month<="31dec2001"d;
run;

proc append base=_bbgb4;
run;

proc iml;
	use _bbgb where(month="31dec1928"d);
		read all var{m ty pe vs} into z;
	close _bbgb;
	use _bbgb1 where(type="EST");
		read all var{const ar1_1 ar1_2 ar1_3 ar1_4} into phi;
	close _bbgb1;
	use _bbgb4;
		read all var{res1 res2 res3 res4} into u;
	close _bbgb4;
	t=nrow(u)/&reps.+1;
	do s=1 to t;
		if s=1 then z=z`*j(1,&reps.);
		else z=phi[,1]*j(1,&reps.)+phi[,2:5]*z+u[(&reps.*s-&reps.-&reps.+1):(&reps.*s-&reps.),]`;
		if s=1 then _bbgb4=z`;
		else _bbgb4=_bbgb4//z`;
	end;
	create _bbgb4 from _bbgb4;
		append from _bbgb4;
	close _bbgb4;
quit;

data _bbgb4;
	replicate=mod(_n_-1,&reps.)+1;
	month=intnx("month","31dec1928"d,ceil(_n_/&reps.)-1,"e");
	set _bbgb4;
	rename col1=m col2=ty col3=pe col4=vs;
run;

proc sort;
	by replicate month;
run;

proc varmax noprint outest=_bbgb5(where=(type="EST"));
	by replicate;
	model m ty pe vs/p=1;
	output lead=0 out=_bbgb40(keep=res:);
run;

proc iml;
	use _bbgb40;
		read all var{res1 res2 res3 res4} into u;
	close _bbgb40;
	use _bbgb5;
		read all var{ar1_1 ar1_2 ar1_3 ar1_4} into gamma;
	close _bbgb5;
	t=nrow(u)/&reps.;
	rho=0.95**(1/12);
	e1={1,0,0,0};
	do i=1 to &reps.;
		u_=u[t*i-t+2:t*i,];
		gamma_=gamma[4*i-3:4*i,];
		lambda=rho*gamma_*inv(i(4)-rho*gamma_);
		function=(lambda`*e1+e1)||(lambda`*e1);
		news=u_*function;
		if i=1 then _bbgb41={. .}//news;
		else _bbgb41=_bbgb41//{. .}//news;
		if i=1 then _bbgb50=function;
		else _bbgb50=_bbgb50//function;
	end;
	create _bbgb41 from _bbgb41;
		append from _bbgb41;
	close _bbgb41;
	create _bbgb50 from _bbgb50;
		append from _bbgb50;
	close _bbgb50;
quit;

data _bbgb4;
	merge _bbgb4:;
	rename col1=RES5 col2=RES6;
run;

proc corr cov noprint out=_bbgb4;
	by replicate;
	var res:;
run;

proc sort;
	by _type_ _name_ replicate;
run;

proc means noprint;
	by _type_ _name_;
	var res:;
	output out=_bbgb4 std=/autoname;
run;

data _bbgb5;
	merge _bbgb5 _bbgb50;
	if name="m" then name="1m";
	else if name="ty" then name="2ty";
	else if name="pe" then name="3pe";
	else if name="vs" then name="4vs";
run;

proc sort;
	by name replicate;
run;

proc means noprint;
	by name;
	var const ar: col:;
	output out=_bbgb5 std=/autoname;
run;

proc iml;
	use _bbgb1;
		read all var{const ar1_1 ar1_2 ar1_3 ar1_4} into phi1;
	close _bbgb1;
	use _bbgb5;
		read all var{const_stddev ar1_1_stddev ar1_2_stddev ar1_3_stddev ar1_4_stddev} into phi2;
	close _bbgb5;
	use _bbgb2;
		read all var{rsquare fvalue};
	close _bbgb2;
	rsq=100*rsquare;
	use _bbgb3(where=(_type_ in ("CORR","STD") and substr(_name_,4,1) in ("","1","2","3","4")));
		read all var{res1 res2 res3 res4} into corr1;
	close _bbgb3;
	corr1=corr1[2:5,]+diag(corr1[1,])-i(4);
	use _bbgb4(where=(_type_ in ("CORR","STD") and substr(_name_,4,1) in ("","1","2","3","4")));
		read all var{res1_stddev res2_stddev res3_stddev res4_stddev} into corr2;
	close _bbgb4;
	corr2=corr2[1:4,]+diag(corr2[5,]);
	table2=(phi1[1,]||rsq[1]||fvalue[1])//
		(phi1[2,]||{. .})//
		(phi2[1,]||{. .})//
		(phi1[3,]||rsq[2]||fvalue[2])//
		(phi1[4,]||{. .})//
		(phi2[2,]||{. .})//
		(phi1[5,]||rsq[3]||fvalue[3])//
		(phi1[6,]||{. .})//
		(phi2[3,]||{. .})//
		(phi1[7,]||rsq[4]||fvalue[4])//
		(phi1[8,]||{. .})//
		(phi2[4,]||{. .})//
		(shape(corr1||corr2,8)||j(8,3,.));
	print table2[format=12.3];
quit;

proc iml;
	use _bbgb3;
		read all var _all_ into _bbgb3;
	close _bbgb3;
	use _bbgb1 where(type="EST");
		read all var{col1 col2} into _bbgb1;
	close _bbgb1;
	use _bbgb4;
		read all var _all_ into _bbgb4;
	close _bbgb4;
	use _bbgb5;
		read all var{col1_stddev col2_stddev} into _bbgb5;
	close _bbgb5;
	table31=shape(_bbgb3[5:6,5:6]||_bbgb4[11:12,7:8],4);
	table32=(_bbgb3[8,5]||_bbgb3[14,6])//
		(_bbgb4[15,7]||_bbgb4[5,8])//
		(_bbgb3[15,5]||_bbgb3[8,6])//
		(_bbgb4[6,7]||_bbgb4[15,8]);
	table33=shape(_bbgb3[10:13,5:6]||_bbgb4[1:4,7:8],8);
	table34=shape(_bbgb1||_bbgb5,8);
	table3=(table31||table32)//(table33||table34);
	print table3[format=8.4];
quit;

proc delete data=_bbgb40 _bbgb41 _bbgb50;
run;

/*merge cv2004 and french data*/

data _bm0(drop=i);
	merge _bbgb _bm;
	by month;
	where "1jul1963"d<=month<="31dec2001"d;
	array pf(*) r: s:;
	do i=1 to dim(pf);
		pf(i)=pf(i)-f;
	end;
	ncf1=lag(ncf);
	ndr1=lag(ndr);
run;

/*market variance*/

proc sql noprint;
	select var(mem)
	into :varmem trimmed
	from _bm0;
quit;

/*45 means*/

proc means noprint;
	var r: s:;
	output out=_bm1 mean=/autoname;
run;

proc transpose out=_bm1;
	var r: s:;
run;

data _bm2(drop=i);
	set _bm0;
	array pf(*) r: s:;
	do i=1 to dim(pf);
		pf(i)=log(1+pf(i)+f);
	end;
run;

/*45 cf betas and 45 dr betas*/

proc corr cov nocorr noprob noprint out=_bm2;
	var mem ncf ncf1 ndr ndr1 r: s:;
run;

data _bm2(drop=i);
	merge _bm2(where=(_name_="mem"))
		_bm2(drop=mem where=(_name_ in ("ncf","ncf1","ndr","ndr1")));
	by _type_;
	array pf(*) r01-r20 s:;
	do i=1 to dim(pf);
		pf(i)=pf(i)/mem;
		pf(i)+lag(pf(i));
	end;
	_name_=lag(_name_);
	if mod(_n_,2) then delete;
	d01=pf(41)-pf(21);
	d02=pf(42)-pf(22);
	d03=pf(43)-pf(23);
	d04=pf(44)-pf(24);
	d05=pf(45)-pf(25);
	d06=pf(25)-pf(21);
	d07=pf(30)-pf(26);
	d08=pf(35)-pf(31);
	d09=pf(40)-pf(36);
	d10=pf(45)-pf(41);
	d11=pf(5)-pf(1);
	d12=pf(10)-pf(6);
	d13=pf(15)-pf(11);
	d14=pf(20)-pf(16);
run;

proc transpose out=_bm2;
	var r: s: d:;
run;

proc sql;
	create table _bm1 as
	select b._name_ as name,
		col1 as rbar,
		ncf,
		ndr,
		ncf+ndr as beta
	from _bm1 a full join _bm2 b
	on substr(a._name_,1,find(a._name_,"_")-1)=b._name_
	order by b._name_;
quit;

/*second pass regressions*/

ods listing close;
ods results=off;
ods output parameterestimates=_bm2(where=(variable^="RESTRICT"));

proc reg;
	where rbar>.;
	model rbar=ncf ndr;
	output out=_bm10 p=rbar0;
	model rbar=ncf ndr/noint;
	output out=_bm11 p=rbar1;
	model rbar=ncf ndr;
	restrict ndr=&varmem.;
	output out=_bm12 p=rbar2;
	model rbar=ncf ndr/noint;
	restrict ndr=&varmem.;
	output out=_bm13 p=rbar3;
	model rbar=beta;
	output out=_bm14 p=rbar4;
	model rbar=beta/noint;
	output out=_bm15 p=rbar5;
run;

ods output close;
ods results=on;
ods listing;

data _bm1;
	merge _bm1:;
	by name;
	group=substr(name,1,1);
run;

proc delete data=_bm10-_bm15;
run;

/*replicate cv2004 figure 4*/

proc sql noprint;
	select max(rbar),max(rbar0),max(rbar1),max(rbar2),max(rbar3),max(rbar4),max(rbar5)
	into :mr trimmed,:mr0 trimmed,:mr1 trimmed,:mr2 trimmed,:mr3 trimmed,:mr4 trimmed,:mr5 trimmed
	from _bm1;
quit;

%macro sgplot;

ods listing gpath="!userprofile\desktop\";
ods graphics/imagefmt=png width=6.5in height=4.875in noborder;
ods results=off;

%do i=0 %to 5;

ods graphics/reset imagename="191103_&i.";

proc sgplot noborder noautolegend;
	scatter y=rbar x=rbar&i./group=group;
	styleattrs datasymbols=(triangle asterisk) datacontrastcolors=(blue red);
	lineparm y=0 x=0 slope=1/lineattrs=(color="lime");
	yaxis min=0 max=%sysfunc(max(&mr.,&mr0.,&mr1.,&mr2.,&mr3.,&mr4.,&mr5.)) display=(nolabel);
	xaxis min=0 max=%sysfunc(max(&mr.,&mr0.,&mr1.,&mr2.,&mr3.,&mr4.,&mr5.)) display=(nolabel);
run;

%end;

ods results=on;

%mend;

/*%sgplot;*/

/*fix r-squares using cv2004 equation 11*/

proc iml;
	use _bm1 where(rbar>.);
		read all var{rbar rbar0 rbar1 rbar2 rbar3 rbar4 rbar5};
	close _bm1;
	_bm3=1-ssq(rbar-rbar0)/ssq(rbar-mean(rbar))//
		1-ssq(rbar-rbar1)/ssq(rbar-mean(rbar))//
		1-ssq(rbar-rbar2)/ssq(rbar-mean(rbar))//
		1-ssq(rbar-rbar3)/ssq(rbar-mean(rbar))//
		1-ssq(rbar-rbar4)/ssq(rbar-mean(rbar))//
		1-ssq(rbar-rbar5)/ssq(rbar-mean(rbar));
	create _bm3 from _bm3;
		append from _bm3;
	close _bm3;
	use _bm0(keep=r: s:);
		read all var _all_ into e;
	close _bm0;
	invomega=diag(1/var(e));
	call symputx("pe0",(rbar-rbar0)`*invomega*(rbar-rbar0));
	call symputx("pe1",(rbar-rbar1)`*invomega*(rbar-rbar1));
	call symputx("pe2",(rbar-rbar2)`*invomega*(rbar-rbar2));
	call symputx("pe3",(rbar-rbar3)`*invomega*(rbar-rbar3));
	call symputx("pe4",(rbar-rbar4)`*invomega*(rbar-rbar4));
	call symputx("pe5",(rbar-rbar5)`*invomega*(rbar-rbar5));
quit;

/*bootstraps*/

proc transpose data=_bm0 out=_bm4;
	by month;
	var r: s:;
run;

proc sql;
	create table _bm4 as
	select month,_name_ as _name,
		col1 as rbar,
		col1-rbar+rbar0 as rbar0,
		col1-rbar+rbar1 as rbar1,
		col1-rbar+rbar2 as rbar2,
		col1-rbar+rbar3 as rbar3,
		col1-rbar+rbar4 as rbar4,
		col1-rbar+rbar5 as rbar5
	from _bm4 a full join _bm1 b
	on a._name_=b.name
	where substr(name,1,1) in ("r","s")
	order by month,_name_;
quit;

data _bm4;
	merge _bm4 _bm0(keep=month f n:);
	by month;
	mem=ncf+ndr;
run;

proc surveyselect data=_bm4 method=urs outhits samprate=1 reps=&reps. seed=1 noprint out=_bm4(rename=(replicate=_replicate));
	where "1aug1963"d<=month<="31dec2001"d;
	cluster month;
run;

proc sort;
	by _replicate _name;
run;

/*means and variances in bm5 and bm50*/

proc means noprint;
	by _replicate _name;
	var r:;
	output out=_bm5 mean=/autoname;
	output out=_bm50 var=/autoname;
run;

proc transpose data=_bm5 out=_bm5;
	by _replicate _name;
	var r:;
run;

proc transpose data=_bm50 out=_bm50;
	by _replicate _name;
	var r:;
run;

/*market variances in bm40*/

proc means data=_bm4 noprint;
	by _replicate;
	where _name="r01";
	var mem;
	output out=_bm40 var=mem;
run;

/*betas in bm4*/

data _bm4(drop=i);
	set _bm4;
	array pf(*) r:;
	do i=1 to dim(pf);
		pf(i)=log(1+pf(i)+f);
	end;
run;

proc corr cov nocorr noprob noprint out=_bm4;
	by _replicate _name;
	var mem ncf ncf1 ndr ndr1 r:;
run;

data _bm4(drop=i);
	merge _bm4(where=(_name_="mem"))
		_bm4(drop=mem where=(_name_ in ("ncf","ncf1","ndr","ndr1")));
	by _replicate _name _type_;
	array pf(*) r:;
	do i=1 to dim(pf);
		pf(i)=pf(i)/mem;
		pf(i)+lag(pf(i));
	end;
	_name_=lag(_name_);
	if mod(_n_,2) then delete;
run;

proc transpose out=_bm4;
	by _replicate _name;
	var r:;
run;

proc sql;
	create table _bm5 as
	select b._replicate,
		b._name,
		b._name_ as name_,
		col1 as rbar,
		ncf,
		ndr,
		ncf+ndr as beta
	from _bm5 a full join _bm4 b
	on a._replicate=b._replicate and a._name=b._name and substr(a._name_,1,find(a._name_,"_")-1)=b._name_
	order by b._replicate,b._name,b._name_;
quit;

/*rbar_ for constrained icapm estimates*/

data _bm5;
	merge _bm5 _bm40;
	by _replicate;
	rbar_=rbar-mem*ndr;
run;

proc sort;
	by name_ _replicate _name;
run;

/*standard deviation of market variances as icapm standard errors*/

proc sql noprint;
	select std(mem)
	into :stdmem
	from _bm40;
quit;

ods listing close;
ods results=off;
ods output parameterestimates=_bm4(where=(name_="rbar"));

proc reg data=_bm5(drop=_type_);
	by name_ _replicate;
	model rbar=ncf ndr;
	output out=_bm40 r=e0;
	model rbar=ncf ndr/noint;
	output out=_bm41 r=e1;
	model rbar_=ncf;
	output out=_bm42 r=e2;
	model rbar_=ncf/noint;
	output out=_bm43 r=e3;
	model rbar=beta;
	output out=_bm44 r=e4;
	model rbar=beta/noint;
	output out=_bm45 r=e5;
run;

ods output close;
ods results=on;
ods listing;

proc sort data=_bm4 out=_bm4;
	by model variable _replicate;
run;

proc means noprint;
	by model variable;
	var estimate;
	output out=_bm4 std=/autoname;
run;

data _bm40;
	merge _bm40-_bm45;
run;

proc sql;
	create table _bm40 as
	select a.*,col1
	from _bm40 a full join _bm50 b
	on a.name_=substr(b._name_,1,find(b._name_,"_")-1) and a._replicate=b._replicate and a._name=b._name
	where name_ in ("rbar0","rbar1","rbar2","rbar3","rbar4","rbar5")
	order by name_,_replicate,_name;
quit;

/*critical values*/

proc iml;
	use _bm40;
		read all var{e0 e1 e2 e3 e4 e5 col1} into e;
	close _bm40;
	pe=j(&reps.,6);
	do i=1 to 6;
		do j=1 to &reps.;
			pe[j,i]=e[(&reps.*45*i+45*j-&reps.*45-45+1):(&reps.*45*i+45*j-&reps.*45),i]`*diag(1/e[(&reps.*45*i+45*j-&reps.*45-45+1):(&reps.*45*i+45*j-&reps.*45),7])*e[(&reps.*45*i+45*j-&reps.*45-45+1):(&reps.*45*i+45*j-&reps.*45),i];
		end;
	end;
	call qntl(pe95,pe,0.95);
	call symputx("pea950",pe95[1]);
	call symputx("pea951",pe95[2]);
	call symputx("pea952",pe95[3]);
	call symputx("pea953",pe95[4]);
	call symputx("pea954",pe95[5]);
	call symputx("pea955",pe95[6]);
quit;

proc delete data=_bm40-_bm45 _bm50;
run;

/*second pass standard errors*/

data _bm4;
	set _bm4;
	output;
	if model in ("MODEL3","MODEL4") and variable="ncf" then do;
		variable="ndr";
		estimate_stddev=&stdmem.;
		output;
	end;
run;

/*first pass standard errors*/

proc transpose data=_bm5 out=_bm5;
	by _replicate;
	where name_="rbar";
	id _name;
	var ncf ndr;
run;

data _bm5;
	set _bm5;
	array pf(*) r: s:;
	d01=pf(41)-pf(21);
	d02=pf(42)-pf(22);
	d03=pf(43)-pf(23);
	d04=pf(44)-pf(24);
	d05=pf(45)-pf(25);
	d06=pf(25)-pf(21);
	d07=pf(30)-pf(26);
	d08=pf(35)-pf(31);
	d09=pf(40)-pf(36);
	d10=pf(45)-pf(41);
	d11=pf(5)-pf(1);
	d12=pf(10)-pf(6);
	d13=pf(15)-pf(11);
	d14=pf(20)-pf(16);
run;

proc transpose data=_bm5 out=_bm5;
	by _replicate;
	var d: r: s:;
run;

proc sort data=_bm5;
	by _name_ _replicate;
run;

proc means noprint;
	by _name_;
	var ncf ndr;
	output out=_bm5 std=/autoname;
run;

/*replicate cv2004 table 5 but size horizontally b/m vertically*/

proc iml;
	use _bm1;
		read all var{ncf ndr};
	close _bm1;
	use _bm5;
		read all var{ncf_stddev ndr_stddev};
	close _bm5;
	table5=(ncf[35:39]||ncf_stddev[35:39]||
		ncf[40:44]||ncf_stddev[40:44]||
		ncf[45:49]||ncf_stddev[45:49]||
		ncf[50:54]||ncf_stddev[50:54]||
		ncf[55:59]||ncf_stddev[55:59]||
		ncf[1:5]||ncf_stddev[1:5])//
		(shape(ncf[6:10]||ncf_stddev[6:10],1)||{. .})//
		(ndr[35:39]||ndr_stddev[35:39]||
		ndr[40:44]||ndr_stddev[40:44]||
		ndr[45:49]||ndr_stddev[45:49]||
		ndr[50:54]||ndr_stddev[50:54]||
		ndr[55:59]||ndr_stddev[55:59]||
		ndr[1:5]||ndr_stddev[1:5])//
		(shape(ndr[6:10]||ndr_stddev[6:10],1)||{. .})//
		(shape(ncf[15:19]||ncf_stddev[15:19],1)||(ncf[11]||ncf_stddev[11]))//
		(shape(ncf[20:24]||ncf_stddev[20:24],1)||(ncf[12]||ncf_stddev[12]))//
		(shape(ncf[25:29]||ncf_stddev[25:29],1)||(ncf[13]||ncf_stddev[13]))//
		(shape(ncf[30:34]||ncf_stddev[30:34],1)||(ncf[14]||ncf_stddev[14]))//
		(shape(ndr[15:19]||ndr_stddev[15:19],1)||(ndr[11]||ndr_stddev[11]))//
		(shape(ndr[20:24]||ndr_stddev[20:24],1)||(ndr[12]||ndr_stddev[12]))//
		(shape(ndr[25:29]||ndr_stddev[25:29],1)||(ndr[13]||ndr_stddev[13]))//
		(shape(ndr[30:34]||ndr_stddev[30:34],1)||(ndr[14]||ndr_stddev[14]));
	footnote="size horizontally b/m vertically";
	print table5[format=8.2],,footnote;
quit;

/*type b standard errors*/

proc varmax data=_bbgb noprint outest=_bm60;
	model m ty pe vs/p=1;
	output lead=0 out=_bm61(keep=res:);
run;

data _bm61;
	merge _bbgb(keep=month) _bm61;
run;

proc surveyselect data=_bm61 method=urs outhits samprate=1 reps=&reps. seed=1 outrandom noprint out=_bm62;
	where "1jan1929"d<=month<="30jun1963"d;
run;

proc surveyselect data=_bm61 method=urs outhits samprate=1 reps=&reps. seed=1 outrandom noprint out=_bm63;
	where "1jul1963"d<=month<="31dec2001"d;
run;

proc append base=_bm62;
run;

proc iml;
	use _bm60 where(type="EST");
		read all var{const ar1_1 ar1_2 ar1_3 ar1_4} into gamma;
	close _bm60;
	use _bm62;
		read all var{res1 res2 res3 res4} into u;
	close _bm62;
	use _bbgb where(month="31dec1928"d);
		read all var{m ty pe vs} into z0;
	close _bbgb;
	t=nrow(u)/&reps.;
	z=j(&reps.,1)*z0;
	do s=1 to t;
		z=j(&reps.,1)*gamma[,1]`+z*gamma[,2:5]`+u[(&reps.*s-&reps.+1):(&reps.*s),];
		if s=1 then _bm63=z;
		else _bm63=_bm63//z;
	end;
	create _bm63 from _bm63;
	append from _bm63;
quit;

data _bm62;
	merge _bm62(keep=month) _bm63;
	replicate=mod(_n_-1,&reps.)+1;
	month_=intnx("month","31dec1928"d,ceil(_n_/&reps.),"e");
	rename col1=m col2=ty col3=pe col4=vs;
run;

data _bm63;
	set _bbgb(keep=month m ty pe vs rename=(month=month_) where=(month_="31dec1928"d));
	do replicate=1 to &reps.;
		output;
	end;
run;

proc append base=_bm62;
run;

proc sort;
	by replicate month_;
run;

proc varmax noprint outest=_bm63;
	by replicate;
	model m ty pe vs/p=1;
	output lead=0 out=_bm64(keep=res:);
run;

proc iml;
	use _bm63 where(type="EST");
		read all var{ar1_1 ar1_2 ar1_3 ar1_4} into gamma;
	close _bm63;
	use _bm64;
		read all var{res1 res2 res3 res4} into u;
	close _bm64;
	t=nrow(u)/&reps.;
	rho=0.95**(1/12);
	e1={1,0,0,0};
	do i=1 to &reps.;
		gamma_=gamma[(4*i-4+1):(4*i),];
		u_=u[(t*i-t+2):(t*i),];
		lambda=rho*gamma_*inv(i(4)-rho*gamma_);
		function=(e1+lambda`*e1)||(lambda`*e1);
		news=u_*function;
		if i=1 then _bm63={. .}//news;
		else _bm63=_bm63//{. .}//news;
	end;
	create _bm63 from _bm63;
	append from _bm63;
quit;

data _bm62;
	merge _bm62(keep=month: replicate) _bm63;
	if "1aug1963"d<=month_<="31dec2001"d;
	col2=-col2;
	COL3=ifn(replicate=lag(replicate),lag(col1),.);
	COL4=ifn(replicate=lag(replicate),lag(col2),.);
run;

/**/

proc transpose data=_bm0 out=_bm63;
	by month;
	var r: s:;
run;

proc sql;
	create table _bm63 as
	select month,_name_ as _name,
		col1 as rbar,
		col1-rbar+rbar0 as rbar0,
		col1-rbar+rbar1 as rbar1,
		col1-rbar+rbar2 as rbar2,
		col1-rbar+rbar3 as rbar3,
		col1-rbar+rbar4 as rbar4,
		col1-rbar+rbar5 as rbar5
	from _bm63 a full join _bm1 b
	on a._name_=b.name
	where substr(name,1,1) in ("r","s")
	order by month,_name;
quit;

proc transpose out=_bm63;
	by month _name;
	var r:;
run;

proc sql;
	create table _bm62 as
	select a.month,a.replicate,a.month_,a.col1 as ncf,a.col2 as ndr,a.col3 as ncf1,a.col4 as ndr1,a.col1+a.col2 as mem,b._name,b._name_ as name_,b.col1
	from _bm62 a full join _bm63 b
	on a.month=b.month
	order by name_,replicate,_name,month_;
quit;

proc means noprint;
	by name_ replicate _name;
	var col1;
	output out=_bm63 mean=rbar var=omega;
run;

proc sort data=_bm62;
	by name_ replicate _name month_;
run;

proc sql;
	create table _bm62 as
	select a.*,log(1+col1+f) as COL2
	from _bm62 a full join _bm0 b
	on a.month=b.month
	order by name_,replicate,_name,month_;
quit;

proc corr cov nocorr noprob noprint out=_bm62;
	by name_ replicate _name;
	var col2 mem ncf ncf1 ndr ndr1;
run;

data _bm62;
	merge _bm62(where=(_name_="mem"))
		_bm62(drop=mem where=(_name_ in ("ncf","ncf1","ndr","ndr1")));
	by name_ replicate _name;
	col2=col2/mem;
	col2+lag(col2);
	_name_=lag(_name_);
	if mod(_n_,2)=0;
run;

data _bm64;
	set _bm62;
	by name_ replicate;
	if first.replicate;
run;

proc sql noprint;
	select std(mem) into :stdmem trimmed from _bm64 where name_="rbar";
quit;

proc transpose data=_bm62 out=_bm62;
	by name_ replicate _name;
	var col2;
run;

proc sql;
	create table _bm62(drop=_name_) as
	select a.*,rbar,omega,a.ncf+a.ndr as beta,rbar-mem*a.ndr as rbar_
	from (_bm62 a full join _bm63 b on a.name_=b.name_ and a.replicate=b.replicate and a._name=b._name) full join _bm64 c on a.name_=c.name_ and a.replicate=c.replicate
	order by name_,replicate,_name;
quit;

ods listing close;
ods results=off;
ods output parameterestimates=_bm63;

proc reg;
	by name_ replicate;
	model rbar=ncf ndr;
	output out=_bm64 r=e0;
	model rbar=ncf ndr/noint;
	output out=_bm65 r=e1;
	model rbar_=ncf;
	output out=_bm66 r=e2;
	model rbar_=ncf/noint;
	output out=_bm67 r=e3;
	model rbar=beta;
	output out=_bm68 r=e4;
	model rbar=beta/noint;
	output out=_bm69 r=e5;
run;

ods output close;
ods results=on;
ods listing;

proc sort data=_bm63;
	by model variable replicate;
	where name_="rbar";
run;

proc means noprint;
	by model variable;
	var estimate;
	output out=_bm63 std=/autoname;
run;

data _bm63;
	set _bm63;
	output;
	if model in ("MODEL3","MODEL4") and variable="ncf" then do;
		variable="ndr";
		estimate_stddev=&stdmem.;
		output;
	end;
run;

data _bm62;
	merge _bm62 _bm64-_bm69;
	where name_ in ("rbar0","rbar1","rbar2","rbar3","rbar4","rbar5");
run;

proc delete data=_bm64-_bm69;
run;

proc iml;
	use _bm62;
		read all var{e0 e1 e2 e3 e4 e5 omega} into e;
	close _bm62;
	pe=j(&reps.,6);
	do i=1 to &reps.;
		invomega=diag(1/e[(45*i-45+1):(45*i),7]);
		do j=1 to 6;
			e_=e[(&reps.*45*j+45*i-&reps.*45-45+1):(&reps.*45*j+45*i-&reps.*45),j];
			pe[i,j]=e_`*invomega*e_;
		end;
	end;
	create _bm62 from pe;
	append from pe;
	call qntl(pe95,pe,0.95);
	call symputx("peb950",pe95[1]);
	call symputx("peb951",pe95[2]);
	call symputx("peb952",pe95[3]);
	call symputx("peb953",pe95[4]);
	call symputx("peb954",pe95[5]);
	call symputx("peb955",pe95[6]);
quit;

/*replicate cv2004 table 7*/

proc iml;
	use _bm2;
		read all var{estimate};
	close _bm2;
	use _bm4;
		read all var{estimate_stddev};
	close _bm4;
	use _bm3;
		read all var{col1};
	close _bm3;
	use _bm63;
		read all var{estimate_stddev} into seb;
	close _bm63;
	table7=(shape(estimate[1:3]||estimate_stddev[1:3]||seb[1:3],9))||
		({.,.,.}//shape(estimate[4:5]||estimate_stddev[4:5]||seb[4:5],6))||
		(shape(estimate[6:8]||estimate_stddev[6:8]||seb[6:8],9))||
		({.,.,.}//shape(estimate[9:10]||estimate_stddev[9:10]||seb[9:10],6))||
		(estimate[11]//estimate_stddev[11]//seb[11]//{.,.,.}//estimate[12]//estimate_stddev[12]//seb[12])||
		({.,.,.,.,.,.}//estimate[13]//estimate_stddev[13]//seb[13]);
	table7=table7[1,]//
		1200*table7[1,]//
		table7[2,]//
		table7[3,]//
		table7[4,]//
		1200*table7[4,]//
		table7[5,]//
		table7[6,]//
		table7[7,]//
		1200*table7[7,]//
		table7[8,]//
		table7[9,]//
		100*col1`//
		{&pe0. &pe1. &pe2. &pe3. &pe4. &pe5.}//
		{&pea950. &pea951. &pea952. &pea953. &pea954. &pea955.}//
		{&peb950. &peb951. &peb952. &peb953. &peb954. &peb955.};
	print table7[format=8.4];
quit;

/*download extended sample*/

/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_CSV.zip,F-F_Research_Data_Factors.CSV,csv,m);*/
/**/
/*filename _0 "%sysfunc(getoption(work))\_.csv";*/
/**/
/*proc http method="get" out=_0*/
/*	url="https://fred.stlouisfed.org/graph/fredgraph.csv?id=T10Y2YM";*/
/*run;*/
/**/
/*proc import file=_0 dbms=csv out=ty replace;*/
/*	guessingrows=max;*/
/*run;*/
/**/
/*filename _0 "%sysfunc(getoption(work))\_.xls";*/
/**/
/*proc http method="get" out=_0*/
/*	url="http://www.econ.yale.edu/~shiller/data/ie_data.xls";*/
/*run;*/
/**/
/*proc import file=_0 dbms=xls out=pe replace;*/
/*	getnames=no;*/
/*	sheet="data";*/
/*run;*/
/**/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/6_Portfolios_2x3_CSV.zip,6_Portfolios_2x3.CSV,csv,vs);*/
/**/
/*/*cleanse extended sample*/*/
/**/
/*data _m;*/
/*	set m;*/
/*	where substr(var1,1,1) in ("1","2");*/
/*	if var1<lag(var1) then delete+1;*/
/*	if delete then delete;*/
/*	month=intnx("month",input(var1,yymmn6.),0,"e");*/
/*	m=log(1+input(var2,16.)/100);*/
/*	rf=log(1+input(var5,16.)/100);*/
/*run;*/
/**/
/*data _ty;*/
/*	set ty;*/
/*	month=intnx("month",date,0,"e");*/
/*	ty=t10y2ym;*/
/*run;*/
/**/
/*data _pe;*/
/*	set pe;*/
/*	where substr(a,1,1) in ("1","2");*/
/*	month=intnx("month",mdy(mod(100*a,100),1,int(a)),0,"e");*/
/*	if k="NA" then pe=.;*/
/*	else pe=log(k);*/
/*run;*/
/**/
/*data _vs0 _vs1;*/
/*	set vs;*/
/*	where substr(var1,1,1) in ("1","2");*/
/*	if var1<lag(var1) then delete+1;*/
/*	if delete=0 then output _vs0;*/
/*	if delete=7 then output _vs1;*/
/*	drop delete;*/
/*run;*/
/**/
/*data _vs0;*/
/*	set _vs0;*/
/*	month=intnx("month",input(var1,yymmn6.),0,"e");*/
/*	if month(month)=7 then diflogret=log(1+var2/100)-log(1+var4/100);*/
/*	else diflogret+log(1+var2/100)-log(1+var4/100);*/
/*	if month(month)<7 then month_=mdy(7,31,year(month)-1);*/
/*	else month_=mdy(7,31,year(month));*/
/*run;*/
/**/
/*data _vs1;*/
/*	set _vs1;*/
/*	month_=intnx("month",input(var1,yymmn6.),0,"e");*/
/*	diflogbm=log(var4/var2);*/
/*	if month(month_)=7;*/
/*run;*/
/**/
/*data _vs;*/
/*	merge _vs0 _vs1;*/
/*	by month_;*/
/*	vs=diflogbm+diflogret;*/
/*run;*/
/**/
/*data _bbgbext;*/
/*	merge _m _ty _pe _vs;*/
/*	by month;*/
/*	keep month m ty pe vs;*/
/*run;*/
/**/
/*proc delete data=_m _ty _pe _vs _vs0 _vs1;*/
/*run;*/
/**/
/*/*estimate correlations*/*/
/**/
/*proc sql;*/
/*	create table _bbgbext as*/
/*	select a.*,*/
/*		b.m as m_,*/
/*		b.ty as ty_,*/
/*		b.pe as pe_,*/
/*		b.vs as vs_*/
/*	from _bbgbext a full join _bbgb b*/
/*	on a.month=b.month*/
/*	order by month;*/
/*quit;*/
/**/
/*proc corr noprint out=_bbgbext0;*/
/*	var m m_ ty ty_ pe pe_ vs vs_;*/
/*run;*/

quit;
