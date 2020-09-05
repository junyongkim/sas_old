/*************************************************
191201hjdist
computes hansen-jagannathan distance hj stat from
jagannathan and wang (1996)
replicates results of jagannathan and wang (2007)
*************************************************/

resetline;
dm"log;clear;output;clear;";
option nodate nonumber nolabel ls=128 ps=max;

%macro french(url,data,infile,input);

filename _ "%sysfunc(getoption(work))\_";

proc http method="get" out=_
	url="http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/&url.";
run;

filename _ zip "%sysfunc(getoption(work))\_";

data &data.;
	infile _(&infile.) dsd truncover;
	input time &input.;
	if time<lag(time) then i+1;
	if time>0;
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
	time=put(time,yymmn6.)+0;
	if time>0;
run;

%mend;

proc datasets kill nolist;
run;

%french(25_Portfolios_5x5_CSV.zip,p25,25_Portfolios_5x5.CSV,p1-p25);
%french(F-F_Research_Data_Factors_CSV.zip,f3,F-F_Research_Data_Factors.CSV,mktrf smb hml rf);
%fred(CPIAUCSL);

data all;
	set cpiaucsl;
	where mod(time,100)=12;
	time=int(time/100);
	cpiaucsl=cpiaucsl/lag(cpiaucsl);
run;

data all;
	merge p25(where=(i=2)) f3(where=(i=1)) all;
	by time;
	mktrf=mktrf/cpiaucsl;
	smb=smb/cpiaucsl;
	hml=hml/cpiaucsl;
	array p(*) p:;
	do i=1 to dim(p);
		p(i)=(p(i)-rf)/cpiaucsl;
	end;
	if 1954<=time<=2003;
	keep p: mktrf smb hml;
run;

proc iml;
	use all;
		read all var _all_ into all;
	close;
	k=3;
	t=nrow(all);
	n=ncol(all)-k;
	r=all[,1:n]/100;
	f=all[,n+1:n+k]/100;
	d=r`*f/t;
	w=inv(r`*r/t);
	b=inv(d`*w*d)*d`*w*mean(r)`;
	u=-hdir(1-f*b,r);
	g=mean(u)`;
	s=cov(u)*(t-1)/t;
	bv=inv(d`*w*d)*d`*w*s*w*d*inv(d`*w*d)/t;
	bt=b/sqrt(vecdiag(bv));
	h=sqrt(g`*w*g);
	a=root(s)*root(w)`*(i(n)-root(w)*d*inv(d`*w*d)*d`*root(w)`)*root(w)*root(s)`;
	hp=mean(rannor(j(5000,n-k,1))##2*eigval(a)[1:n-k]>t*h**2);
	print b bt h hp;
quit;
