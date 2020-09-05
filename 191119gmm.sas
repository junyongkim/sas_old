/*************************************************
191119gmm
estimates second-pass regressions using ols, gls
and reports newey-west (3) gmm standard errors
*************************************************/

resetline;
dm"log;clear;output;clear;";
option nodate nonumber nolabel ls=128 ps=max;

proc datasets kill nolist;
run;

%macro http(url,data,infile,input,equalweight);

filename _01 "%sysfunc(getoption(work))\_01.zip";

proc http method="get" out=_01
	url="https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/&url.";
run;

filename _01 zip "%sysfunc(getoption(work))\_01.zip";

option nonotes;

data &data.(drop=i);
	infile _01(&infile.) dsd;
	input month &input.;
	if month<lag(month) then i+1;
	if i=&equalweight. and month>0;
run;

option notes;

%mend;

%macro iml(merge,where,k);

data all(drop=month _: rf i);
	merge &merge.;
	where &where.;
	by month;
	array p(*) p:;
	do i=1 to dim(p);
		p(i)=p(i)-rf;
	end;
run;

proc iml;
	use all;
		read all var _all_ into all;
	close all;
	k=&k.;
	t=nrow(all);
	n=ncol(all)-k;
	r=all[,1:n];
	f=all[,n+1:n+k]||j(t,1);
/**/
	b=ginv(f`*f)*f`*r;
	e=r-f*b;
	s=cov(e)*(t-1)/t;
	o=cov(f)*(t-1)/t;
	grs=(t-n-k)/n*b[k+1,]*ginv(s)*b[k+1,]`/(1+mean(f)*ginv(o)*mean(f)`);
	grsp=1-probf(grs,n,t-n-k);
	mpet=mean(abs(b[k+1,]`));
	cpet=b[k+1,]*ginv(diag(cov(r)*(t-1)/t))*b[k+1,]`;
/**/
	b=b[1:k,]`||j(n,1);
	er=mean(r)`;
	lo=ginv(b`*b)*b`*er;
	lov=(ginv(b`*b)*b`*s*b*ginv(b`*b)*(1+lo`*ginv(o)*lo)+o)/t;
	lot=lo/sqrt(vecdiag(lov));
	ao=er-b*lo;
	aov=(i(n)-b*ginv(b`*b)*b`)*s*(i(n)-b*ginv(b`*b)*b`)*(1+lo`*ginv(o)*lo)/t;
	chio=ao`*ginv(aov)*ao;
	chiop=1-probchi(chio,n-k);
	rsqo=1-(ao`*ao)/((er-mean(er))`*(er-mean(er)));
	mpeo=mean(abs(ao));
	cpeo=ao`*ginv(diag(cov(r)*(t-1)/t))*ao;
/**/
	lg=ginv(b`*ginv(s)*b)*b`*ginv(s)*er;
	lgi=ginv(j(1,n)*ginv(s)*j(n,1))*j(1,n)*ginv(s)*er;
	lgv=(ginv(b`*ginv(s)*b)*(1+lo`*ginv(o)*lo)+o)/t;
	lgt=lg/sqrt(vecdiag(lgv));
	ag=er-b*lg;
	agv=(s-b*ginv(b`*ginv(s)*b)*b`)*(1+lg`*ginv(o)*lg)/t;
	chig=ag`*ginv(agv)*ag;
	chigp=1-probchi(chig,n-k);
	rsqg=1-(ag`*ginv(cov(r)*(t-1)/t)*ag)/((er-lgi)`*ginv(cov(r)*(t-1)/t)*(er-lgi));
	mpeg=mean(abs(ag));
	cpeg=ag`*ginv(diag(cov(r)*(t-1)/t))*ag;
/**/
	ugo=hdir(f,e)||r-lo`*b`;
	ugo=ugo-mean(ugo);
	do j=0 to 13;
		if j=0 then sgo=ugo`*ugo/t;
		else sgo=sgo+(13-j)/13*(ugo[1+j:t,]`*ugo[1:t-j,]+ugo[1:t-j,]`*ugo[1+j:t,])/(t-j);
	end;
	ago=(i((k+1)*n)||j((k+1)*n,n,0))//(j(k+1,(k+1)*n,0)||b`);
	fg=f`*f/t;
	dgo=-((i(n)@fg||j((k+1)*n,k+1,0))//(i(n)@(0||lo[1:k]`)||b));
	lovg=ginv(ago*dgo)*ago*sgo*ago`*ginv(ago*dgo)`/t;
	lotg=lo/sqrt(vecdiag(lovg))[(k+1)*n+1:(k+1)*n+1+k];
/**/
	ugg=hdir(f,e)||r-lg`*b`;
	ugg=ugg-mean(ugg);
	do j=0 to 13;
		if j=0 then sgg=ugg`*ugg/t;
		else sgg=sgg+(13-j)/13*(ugg[1+j:t,]`*ugg[1:t-j,]+ugg[1:t-j,]`*ugg[1+j:t,])/(t-j);
	end;
	agg=(i((k+1)*n)||j((k+1)*n,n,0))//(j(k+1,(k+1)*n,0)||b`*ginv(s));
	dgg=-((i(n)@fg||j((k+1)*n,k+1,0))//(i(n)@(0||lg[1:k]`)||ginv(s)*b));
	lgvg=ginv(agg*dgg)*agg*sgg*agg`*ginv(agg*dgg)`/t;
	lgtg=lg/sqrt(vecdiag(lgvg))[(k+1)*n+1:(k+1)*n+1+k];
/**/
	print=shape(lo||lot||lotg,1)`//
		shape(lg||lgt||lgtg,1)`//
		grs//
		grsp//
		chio//
		chiop//
		chig//
		chigp//
		rsqo//
		rsqg//
		mpet//
		cpet//
		mpeo//
		cpeo//
		mpeg//
		cpeg;
	if k=3 then print=print[1:9]//j(9,1,.)//print[10:21]//j(9,1,.)//print[22:38];
	else if k=4 then print=print[1:9]//j(6,1,.)//print[10:24]//j(6,1,.)//print[25:44];
	else if k=5 then print=print[1:15]//j(3,1,.)//print[16:33]//j(3,1,.)//print[34:50];
	create _(rename=(col1=%sysfunc(compress(&merge.)))) from print;
	append from print;
quit;

data table;
	merge table _;
run;

%mend;

/**/

%macro imlall1(test);

%iml(&test. i30 f3,month>=196307,3);
%iml(&test. i30 f3 fm,month>=196307,4);
%iml(&test. i30 f5,month>=196307,5);
%iml(&test. i30 f5 fm,month>=196307,6);

%mend;

/**/

%macro imlall2(test);

%iml(&test. f3,month>=196307,3);
%iml(&test. f3 fm,month>=196307,4);
%iml(&test. f5,month>=196307,5);
%iml(&test. f5 fm,month>=196307,6);
%iml(&test. i30 f3,month>=196307,3);
%iml(&test. i30 f3 fm,month>=196307,4);
%iml(&test. i30 f5,month>=196307,5);
%iml(&test. i30 f5 fm,month>=196307,6);

%mend;

/**/

%http(25_Portfolios_5x5_CSV.zip,pszbm025,25_Portfolios_5x5.CSV,p001-p025,0);
%http(25_Portfolios_ME_OP_5x5_CSV.zip,pszop025,25_Portfolios_ME_OP_5x5.CSV,p001-p025,0);
%http(25_Portfolios_ME_INV_5x5_CSV.zip,pszin025,25_Portfolios_ME_INV_5x5.CSV,p001-p025,0);
%http(25_Portfolios_BEME_OP_5x5_CSV.zip,pbmop025,25_Portfolios_BEME_OP_5x5.CSV,p001-p025,0);
%http(25_Portfolios_BEME_INV_5x5_CSV.zip,pbmin025,25_Portfolios_BEME_INV_5x5.CSV,p001-p025,0);
%http(25_Portfolios_OP_INV_5x5_CSV.zip,popin025,25_Portfolios_OP_INV_5x5.CSV,p001-p025,0);

/**/

%http(25_Portfolios_ME_Prior_12_2_CSV.zip,pszmo025,25_Portfolios_ME_Prior_12_2.CSV,p001-p025,0);
%http(25_Portfolios_ME_Prior_12_2_CSV.zip,pszmo025eq,25_Portfolios_ME_Prior_12_2.CSV,p001-p025,1);
%http(25_Portfolios_ME_Prior_1_0_CSV.zip,pszsr025,25_Portfolios_ME_Prior_1_0.CSV,p001-p025,0);
%http(25_Portfolios_ME_Prior_1_0_CSV.zip,pszsr025eq,25_Portfolios_ME_Prior_1_0.CSV,p001-p025,1);
%http(25_Portfolios_ME_Prior_60_13_CSV.zip,pszlr025,25_Portfolios_ME_Prior_60_13.CSV,p001-p025,0);
%http(25_Portfolios_ME_Prior_60_13_CSV.zip,pszlr025eq,25_Portfolios_ME_Prior_60_13.CSV,p001-p025,1);

/**/

%http(25_Portfolios_ME_AC_5x5_CSV.zip,pszac025,25_Portfolios_ME_AC_5x5.csv,p001-p025,0);
%http(25_Portfolios_ME_BETA_5x5_CSV.zip,pszbe025,25_Portfolios_ME_BETA_5x5.csv,p001-p025,0);
%http(25_Portfolios_ME_NI_5x5_CSV.zip,pszni025,25_Portfolios_ME_NI_5x5.csv,_01 _02 p001-p005 _03 _04 p006-p010 _05 _06 p011-p015 _07 _08 p016-p020 _09 _10 p021-p025,0);
%http(25_Portfolios_ME_VAR_5x5_CSV.zip,pszva025,25_Portfolios_ME_VAR_5x5.csv,p001-p025,0);
%http(25_Portfolios_ME_RESVAR_5x5_CSV.zip,pszrv025,25_Portfolios_ME_RESVAR_5x5.csv,p001-p025,0);

/**/

%http(Portfolios_Formed_on_ME_CSV.zip,psz010,Portfolios_Formed_on_ME.CSV,_1-_9 p001-p010,0);
%http(Portfolios_Formed_on_BE-ME_CSV.zip,pbm010,Portfolios_Formed_on_BE-ME.CSV,_1-_9 p001-p010,0);
%http(Portfolios_Formed_on_OP_CSV.zip,pop010,Portfolios_Formed_on_OP.CSV,_1-_8 p001-p010,0);
%http(Portfolios_Formed_on_INV_CSV.zip,pin010,Portfolios_Formed_on_INV.CSV,_1-_8 p001-p010,0);
%http(Portfolios_Formed_on_E-P_CSV.zip,pep010,Portfolios_Formed_on_E-P.CSV,_1-_9 p001-p010,0);
%http(Portfolios_Formed_on_CF-P_CSV.zip,pcf010,Portfolios_Formed_on_CF-P.CSV,_1-_9 p001-p010,0);
%http(Portfolios_Formed_on_D-P_CSV.zip,pdp010,Portfolios_Formed_on_D-P.CSV,_1-_9 p001-p010,0);

/**/

%http(10_Portfolios_Prior_12_2_CSV.zip,pmo010,10_Portfolios_Prior_12_2.CSV,p001-p010,0);
%http(10_Portfolios_Prior_12_2_CSV.zip,pmo010eq,10_Portfolios_Prior_12_2.CSV,p001-p010,1);
%http(10_Portfolios_Prior_1_0_CSV.zip,psr010,10_Portfolios_Prior_1_0.CSV,p001-p010,0);
%http(10_Portfolios_Prior_1_0_CSV.zip,psr010eq,10_Portfolios_Prior_1_0.CSV,p001-p010,1);
%http(10_Portfolios_Prior_60_13_CSV.zip,plr010,10_Portfolios_Prior_60_13.CSV,p001-p010,0);
%http(10_Portfolios_Prior_60_13_CSV.zip,plr010eq,10_Portfolios_Prior_60_13.CSV,p001-p010,1);

/**/

%http(Portfolios_Formed_on_AC_CSV.zip,pac010,Portfolios_Formed_on_AC.csv,_1-_5 p001-p010,0);
%http(Portfolios_Formed_on_BETA_CSV.zip,pbe010,Portfolios_Formed_on_BETA.csv,_1-_5 p001-p010,0);
%http(Portfolios_Formed_on_NI_CSV.zip,pni010,Portfolios_Formed_on_NI.csv,_1-_7 p001-p010,0);
%http(Portfolios_Formed_on_VAR_CSV.zip,pva010,Portfolios_Formed_on_VAR.csv,_1-_5 p001-p010,0);
%http(Portfolios_Formed_on_RESVAR_CSV.zip,prv010,Portfolios_Formed_on_RESVAR.csv,_1-_5 p001-p010,0);

/**/

%http(30_Industry_Portfolios_CSV.zip,i30,30_Industry_Portfolios.CSV,p101-p130,0);

/**/

%http(F-F_Research_Data_Factors_CSV.zip,f3,F-F_Research_Data_Factors.CSV,rmrf smb hml rf,0);
%http(F-F_Research_Data_5_Factors_2x3_CSV.zip,f5,F-F_Research_Data_5_Factors_2x3.CSV,rmrf smb hml rmw cma rf,0);
%http(F-F_Momentum_Factor_CSV.zip,fm,F-F_Momentum_Factor.CSV,wml,0);

/**/

data table;
	input table $ @@;
	output;
	if _n_<15 then do;
		table="";
		output;
		output;
	end;
	else if _n_<18 then do;
		table="";
		output;
	end;
	cards;
olsrmrf smb hml rmw cma wml constant
glsrmrf smb hml rmw cma wml constant
grsf olschisq glschisq olsrsq glsrsq
tsmpe tscpe olsmpe olscpe glsmpe glscpe
	;
run;

/**/

%imlall2(pszbm025);
%imlall2(pszop025);
%imlall2(pszin025);
%imlall2(pbmop025);
%imlall2(pbmin025);
%imlall2(popin025);

/**/

%imlall2(pszmo025);
%imlall2(pszmo025eq);
%imlall2(pszsr025);
%imlall2(pszsr025eq);
%imlall2(pszlr025);
%imlall2(pszlr025eq);

/**/

%imlall2(pszac025);
%imlall2(pszbe025);
%imlall2(pszni025);
%imlall2(pszva025);
%imlall2(pszrv025);

/**/

%imlall1(psz010);
%imlall1(pbm010);
%imlall1(pop010);
%imlall1(pin010);
%imlall1(pep010);
%imlall1(pcf010);
%imlall1(pdp010);

/**/

%imlall1(pmo010);
%imlall1(pmo010eq);
%imlall1(psr010);
%imlall1(psr010eq);
%imlall1(plr010);
%imlall1(plr010eq);

/**/

%imlall1(pac010);
%imlall1(pbe010);
%imlall1(pni010);
%imlall1(pva010);
%imlall1(prv010);

/**/

proc delete data=_;
run;

/**/

quit;
