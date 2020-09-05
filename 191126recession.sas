/*************************************************
191126recession
runs separate regressions during nber recessions
*************************************************/

resetline;
dm"log;clear;output;clear;";
option nodate nonumber nolabel ls=128 ps=max;

%macro french(url,data,infile,input);

filename _ "%sysfunc(getoption(work))\_";

proc http method="get" out=_
	url="https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/&url.";
run;

filename _ zip "%sysfunc(getoption(work))\_";

data &data.;
	infile _(&infile.) dsd truncover;
	input time &input.;
	if time<lag(time) then if+1;
	if time;
run;

%mend;

%macro fred(url);

filename _ "%sysfunc(getoption(work))\_";

proc http method="get" out=_
	url="https://fred.stlouisfed.org/graph/fredgraph.csv?id=&url.";
run;

data &url.;
	infile _ dsd truncover;
	input time yymmdd10. +1 &url.;
	time=input(put(time,yymmn6.),6.);
	if time;
run;

%mend;

/*proc datasets kill nolist;*/
/*run;*/
/**/
/*%french(F-F_Research_Data_Factors_CSV.zip,f3,F-F_Research_Data_Factors.CSV,rmrf smb hml rf);*/
/*%french(25_Portfolios_ME_Prior_12_2_CSV.zip,p25,25_Portfolios_ME_Prior_12_2.CSV,p1-p25);*/
/*%fred(usrec);*/

data all;
	merge p25(where=(if=0)) f3(where=(if=0)) usrec;
	by time;
	array p(*) p:;
	do i=1 to dim(p);
		p(i)=p(i)-rf;
	end;
	if p(1)>. and usrec=0;
	keep p: rmrf smb hml;
run;

proc iml;
	use all;
		read all var _all_ into all;
	close;
	k=3;
	t=nrow(all);
	n=ncol(all)-k;
	r=all[,1:n];
	v=cov(r)*(t-1)/t;
	f=all[,n+1:n+k]||j(t,1);
	o=cov(f)*(t-1)/t;
	b=inv(f`*f)*f`*r;
	s=cov(r-f*b)*(t-1)/t;
	e=mean(r)`;
	b=b[1:k,]`||j(n,1);
	lo=inv(b`*b)*b`*e;
	lov=(inv(b`*b)*b`*s*b*inv(b`*b)*(1+lo`*ginv(o)*lo)+o)/t;
	lot=lo/sqrt(vecdiag(lov));
	ao=e-b*lo;
	aov=(i(n)-b*inv(b`*b)*b`)*s*(i(n)-b*inv(b`*b)*b`)*(1+lo`*ginv(o)*lo)/t;
	co=ao`*ginv(aov)*ao;
	cop=1-cdf("chisq",co,n-k);
	lg=inv(b`*inv(s)*b)*b`*inv(s)*e;
	lgv=(inv(b`*inv(s)*b)*(1+lg`*ginv(o)*lg)+o)/t;
	lgt=lg/sqrt(vecdiag(lgv));
	ag=e-b*lg;
	agv=(s-b*inv(b`*inv(s)*b)*b`)*(1+lg`*ginv(o)*lg)/t;
	cg=ag`*ginv(agv)*ag;
	cgp=1-cdf("chisq",cg,n-k);
	print lo lot lg lgt,,co cop cg cgp;
	sgplot=(11:15)||(21:25)||(31:35)||(41:45)||(51:55);
	sgplot=sgplot`||b*lo||b*lg||e;
	create sgplot from sgplot;
	append from sgplot;
	call symputx("min",min(sgplot[,2:4]));
	call symputx("max",max(sgplot[,2:4]));
	call symputx("range",&max.-&min.);
	call symputx("mo",mean(abs(ao)));
	call symputx("co",co);
	call symputx("cop",cop);
	call symputx("mg",mean(abs(ag)));
	call symputx("cg",cg);
	call symputx("cgp",cgp);
quit;

ods listing gpath="!userprofile\desktop\";
ods graphics/reset;
ods results=off;

proc sgplot noautolegend noborder;
	text x=col2 y=col4 text=col1;
	lineparm x=0 y=0 slope=1;
	xaxis display=(nolabel) values=(&min. to &max. by %sysevalf(&range./5)) valuesformat=best4. offsetmin=0.05 offsetmax=0.05;
	yaxis display=(nolabel) values=(&min. to &max. by %sysevalf(&range./5)) valuesformat=best4. offsetmin=0.05 offsetmax=0.05;
	inset ("OLS mape"="%sysfunc(putn(&mo.,8.3))" "OLS chisq"="%sysfunc(putn(&co.,8.3))" "P-value"="%sysfunc(putn(&cop.,8.3))");
run;

proc sgplot noautolegend noborder;
	text x=col3 y=col4 text=col1;
	lineparm x=0 y=0 slope=1;
	xaxis display=(nolabel) values=(&min. to &max. by %sysevalf(&range./5)) valuesformat=best4. offsetmin=0.05 offsetmax=0.05;
	yaxis display=(nolabel) values=(&min. to &max. by %sysevalf(&range./5)) valuesformat=best4. offsetmin=0.05 offsetmax=0.05;
	inset ("GLS mape"="%sysfunc(putn(&mg.,8.3))" "GLS chisq"="%sysfunc(putn(&cg.,8.3))" "P-value"="%sysfunc(putn(&cgp.,8.3))");
run;

ods results=on;

quit;
