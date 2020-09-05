/*************************************************
191112french
downloads data from french's website and displays
second-pass regressions and related stats
*************************************************/

resetline;
dm"log;clear;output;clear;";
option nodate nonumber nolabel ls=128 ps=max;

proc datasets kill nolist;
run;

/*download*/

%macro http(url,infile,data,input,equal);

filename _ "%sysfunc(getoption(work))\_.zip";

proc http method="get" out=_
	url="&url.";
run;

filename _ zip "%sysfunc(getoption(work))\_.zip";

%if &equal.=0 %then %do;data &data.;%end;
%else %do;data &data. &data.eq;%end;
	infile _(&infile.) dsd;
	input month &input.;
	if month<lag(month) then delete+1;
	if month>. and delete=0 then output &data.;
	%if &equal.=1 %then %do;else if month>. and delete=1 then output &data.eq;%end;
	drop delete;
run;

%mend;

/*regress*/

%macro iml(merge,where,array,keep);

data _01(drop=i);
	merge &merge.;
	where &where.;
	by month;
	array p(*) &array.;
	do i=1 to dim(p);
		p(i)=p(i)-rf;
	end;
	if p(1)>.;
run;

proc contents data=_01(drop=month &keep. rf) noprint out=_02;
run;

proc iml;
	use _01(keep=&keep.);
		read all var _all_ into f;
	close _01;
	t=nrow(f);
	k=ncol(f);
	f=j(t,1)||f;
	omega=(f-mean(f))`*(f-mean(f))/t;
	use _01(drop=month &keep. rf);
		read all var _all_ into re;
	close _01;
	n=ncol(re);
	rbare=mean(re)`;
	beta=re`*f*inv(f`*f);
	sigma=(re-f*beta`)`*(re-f*beta`)/t;
	grs=(t-n-k)/n*beta[,1]`*inv(sigma)*beta[,1]/(1+mean(f)*ginv(omega)*mean(f)`);
	grs_p=1-probf(grs,n,t-n-k);
	beta[,1]=j(n,1);
	lambda_o=inv(beta`*beta)*beta`*rbare;
	lambda_o_v=(inv(beta`*beta)*beta`*sigma*beta*inv(beta`*beta)*(1+lambda_o`*ginv(omega)*lambda_o)+omega)/t;
	lambda_o_t=lambda_o/sqrt(vecdiag(lambda_o_v));
	alpha_o=rbare-beta*lambda_o;
	alpha_o_v=(i(n)-beta*inv(beta`*beta)*beta`)*sigma*(i(n)-beta*inv(beta`*beta)*beta`)*(1+lambda_o`*ginv(omega)*lambda_o)/t;
	mape_o=mean(abs(alpha_o));
	rsquare_o=var(beta*lambda_o)/var(rbare)*100;
	lns_o=alpha_o`*ginv(alpha_o_v)*alpha_o;
	lns_o_p=1-probchi(lns_o,n-k);
	lambda_g=inv(beta`*inv(sigma)*beta)*beta`*inv(sigma)*rbare;
	lambda_g_v=(inv(beta`*inv(sigma)*beta)*(1+lambda_g`*ginv(omega)*lambda_g)+omega)/t;
	lambda_g_t=lambda_g/sqrt(vecdiag(lambda_g_v));
	alpha_g=rbare-beta*lambda_g;
	alpha_g0=rbare-beta[,1]*inv(beta[,1]`*inv(sigma)*beta[,1])*beta[,1]`*inv(sigma)*rbare;
	alpha_g_v=(sigma-beta*inv(beta`*inv(sigma)*beta)*beta`)*(1+lambda_g`*ginv(omega)*lambda_g)/t;
	mape_g=mean(abs(alpha_g));
	rsquare_g=100-alpha_g`*inv(sigma)*alpha_g/(alpha_g0`*inv(sigma)*alpha_g0)*100;
	lns_g=alpha_g`*ginv(alpha_g_v)*alpha_g;
	lns_g_p=1-probchi(lns_g,n-k);
	footnote="&merge.";
	use _02(rename=(name=name));
		read all var{name};
	close _02;
	name=substr(name,1,8);
	_02=beta*lambda_o||beta*lambda_g||rbare;
	call symputx("min",min(_02));
	call symputx("max",max(_02));
	create _02 from _02[rowname=name colname={"pred_o","pred_g","real"}];
		append from _02[rowname=name];
	close _02;
	call symputx("grs",grs);
	call symputx("grs_p",grs_p);
	call symputx("lns_o",lns_o);
	call symputx("lns_o_p",lns_o_p);
	call symputx("rsquare_o",rsquare_o);
	call symputx("mape_o",mape_o);
	call symputx("lns_g",lns_g);
	call symputx("lns_g_p",lns_g_p);
	call symputx("rsquare_g",rsquare_g);
	call symputx("mape_g",mape_g);
	title "&merge.";
	print grs grs_p,,lambda_o lambda_o_t lambda_g lambda_g_t,,lns_o lns_o_p lns_g lns_g_p,,rsquare_o mape_o rsquare_g mape_g,,footnote;
	title;
quit;

/*data _02;*/
/*	set _02;*/
/*	if substr(name,6,1)="5" then do;*/
/*		name_=name;*/
/*		group=1;*/
/*	end;*/
/*	else if substr(name,6,1)="1" then do;*/
/*		name_=name;*/
/*		group=2;*/
/*	end;*/
/*run;*/

/*proc sort;*/
/*	by group name;*/
/*run;*/

/*ods listing gpath="!userprofile\desktop\";*/
/*ods graphics/reset imagename="%sysfunc(translate(&merge.,_,%str( )))_ols";*/
/*ods results=off;*/

/*proc sgplot noautolegend;*/
/*	xaxis min=&min. max=&max.;*/
/*	yaxis min=&min. max=&max.;*/
/*	scatter x=pred_o y=real/datalabel=name_ group=group;*/
/*	lineparm x=0 y=0 slope=1;*/
/*	inset ("grs"="%sysfunc(putn(&grs.,8.2))"*/
/*		"grs_p"="%sysfunc(putn(&grs_p.,8.2))"*/
/*		"lns_o"="%sysfunc(putn(&lns_o.,8.2))"*/
/*		"lns_o_p"="%sysfunc(putn(&lns_o_p.,8.2))"*/
/*		"rsquare_o"="%sysfunc(putn(&rsquare_o.,8.2))"*/
/*		"mape_o"="%sysfunc(putn(&mape_o.,8.2))")/title="&merge. ols";*/
/*run;*/

/*ods graphics/reset imagename="%sysfunc(translate(&merge.,_,%str( )))_gls";*/

/*proc sgplot noautolegend;*/
/*	xaxis min=&min. max=&max.;*/
/*	yaxis min=&min. max=&max.;*/
/*	scatter x=pred_g y=real/datalabel=name_ group=group;*/
/*	lineparm x=0 y=0 slope=1;*/
/*	inset ("grs"="%sysfunc(putn(&grs.,8.2))"*/
/*		"grs_p"="%sysfunc(putn(&grs_p.,8.2))"*/
/*		"lns_g"="%sysfunc(putn(&lns_g.,8.2))"*/
/*		"lns_g_p"="%sysfunc(putn(&lns_g_p.,8.2))"*/
/*		"rsquare_g"="%sysfunc(putn(&rsquare_g.,8.2))"*/
/*		"mape_g"="%sysfunc(putn(&mape_g.,8.2))")/title="&merge. gls";*/
/*run;*/

/*ods results=on;*/

%mend;

/*factors*/

%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_CSV.zip,F-F_Research_Data_Factors.CSV,ff3,rm_rf smb hml rf,0);
%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Momentum_Factor_CSV.zip,F-F_Momentum_Factor.CSV,ffm,wml,0);
%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_5_Factors_2x3_CSV.zip,F-F_Research_Data_5_Factors_2x3.CSV,ff5,rm_rf smb hml rmw cma rf,0);

/*10 portfolios*/

/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Portfolios_Formed_on_ME_CSV.zip,Portfolios_Formed_on_ME.CSV,p010sz,neg p030 p070 p100 q1-q5 d01-d10,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Portfolios_Formed_on_BE-ME_CSV.zip,Portfolios_Formed_on_BE-ME.CSV,p010bm,neg p030 p070 p100 q1-q5 d01-d10,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Portfolios_Formed_on_OP_CSV.zip,Portfolios_Formed_on_OP.CSV,p010op,p030 p070 p100 q1-q5 d01-d10,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Portfolios_Formed_on_INV_CSV.zip,Portfolios_Formed_on_INV.CSV,p010in,p030 p070 p100 q1-q5 d01-d10,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Portfolios_Formed_on_E-P_CSV.zip,Portfolios_Formed_on_E-P.CSV,p010ep,neg p030 p070 p100 q1-q5 d01-d10,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Portfolios_Formed_on_CF-P_CSV.zip,Portfolios_Formed_on_CF-P.CSV,p010cp,neg p030 p070 p100 q1-q5 d01-d10,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Portfolios_Formed_on_D-P_CSV.zip,Portfolios_Formed_on_D-P.CSV,p010dp,neg p030 p070 p100 q1-q5 d01-d10,1);*/

/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/10_Portfolios_Prior_12_2_CSV.zip,10_Portfolios_Prior_12_2.CSV,p010mo,d01-d10,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/10_Portfolios_Prior_1_0_CSV.zip,10_Portfolios_Prior_1_0.CSV,p010sr,d01-d10,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/10_Portfolios_Prior_60_13_CSV.zip,10_Portfolios_Prior_60_13.CSV,p010lr,d01-d10,1);*/

/*5x5 portfolios*/

/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_5x5_CSV.zip,25_Portfolios_5x5.CSV,p025szbm,sz1bm1-sz1bm5 sz2bm1-sz2bm5 sz3bm1-sz3bm5 sz4bm1-sz4bm5 sz5bm1-sz5bm5,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_OP_5x5_CSV.zip,25_Portfolios_ME_OP_5x5.CSV,p025szop,sz1op1-sz1op5 sz2op1-sz2op5 sz3op1-sz3op5 sz4op1-sz4op5 sz5op1-sz5op5,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_INV_5x5_CSV.zip,25_Portfolios_ME_INV_5x5.CSV,p025szin,sz1in1-sz1in5 sz2in1-sz2in5 sz3in1-sz3in5 sz4in1-sz4in5 sz5in1-sz5in5,1);*/
%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_Prior_12_2_CSV.zip,25_Portfolios_ME_Prior_12_2.CSV,p025szmo,sz1mo1-sz1mo5 sz2mo1-sz2mo5 sz3mo1-sz3mo5 sz4mo1-sz4mo5 sz5mo1-sz5mo5,1);
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_Prior_1_0_CSV.zip,25_Portfolios_ME_Prior_1_0.CSV,p025szsr,sz1sr1-sz1sr5 sz2sr1-sz2sr5 sz3sr1-sz3sr5 sz4sr1-sz4sr5 sz5sr1-sz5sr5,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_Prior_60_13_CSV.zip,25_Portfolios_ME_Prior_60_13.CSV,p025szlr,sz1lr1-sz1lr5 sz2lr1-sz2lr5 sz3lr1-sz3lr5 sz4lr1-sz4lr5 sz5lr1-sz5lr5,1);*/

/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_AC_5x5_CSV.zip,25_Portfolios_ME_AC_5x5.csv,p025szac,sz1ac1-sz1ac5 sz2ac1-sz2ac5 sz3ac1-sz3ac5 sz4ac1-sz4ac5 sz5ac1-sz5ac5,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_BETA_5x5_CSV.zip,25_Portfolios_ME_BETA_5x5.csv,p025szbe,sz1be1-sz1be5 sz2be1-sz2be5 sz3be1-sz3be5 sz4be1-sz4be5 sz5be1-sz5be5,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_NI_5x5_CSV.zip,25_Portfolios_ME_NI_5x5.csv,p025szni,sz1ni1-sz1ni7 sz2ni1-sz2ni7 sz3ni1-sz3ni7 sz4ni1-sz4ni7 sz5ni1-sz5ni7,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_VAR_5x5_CSV.zip,25_Portfolios_ME_VAR_5x5.csv,p025szva,sz1va1-sz1va5 sz2va1-sz2va5 sz3va1-sz3va5 sz4va1-sz4va5 sz5va1-sz5va5,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/25_Portfolios_ME_RESVAR_5x5_CSV.zip,25_Portfolios_ME_RESVAR_5x5.csv,p025szrv,sz1rv1-sz1rv5 sz2rv1-sz2rv5 sz3rv1-sz3rv5 sz4rv1-sz4rv5 sz5rv1-sz5rv5,1);*/

/*10x10 portfolios*/

/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/100_Portfolios_10x10_CSV.zip,100_Portfolios_10x10.CSV,p100szbm,sz01bm01-sz01bm10 sz02bm01-sz02bm10 sz03bm01-sz03bm10 sz04bm01-sz04bm10 sz05bm01-sz05bm10 sz06bm01-sz06bm10 sz07bm01-sz07bm10 sz08bm01-sz08bm10 sz09bm01-sz09bm10 sz10bm01-sz10bm10,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/100_Portfolios_ME_OP_10x10_CSV.zip,100_Portfolios_ME_OP_10x10.CSV,p100szop,sz01op01-sz01op10 sz02op01-sz02op10 sz03op01-sz03op10 sz04op01-sz04op10 sz05op01-sz05op10 sz06op01-sz06op10 sz07op01-sz07op10 sz08op01-sz08op10 sz09op01-sz09op10 sz10op01-sz10op10,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/100_Portfolios_ME_INV_10x10_CSV.zip,100_Portfolios_ME_INV_10x10.CSV,p100szin,sz01in01-sz01in10 sz02in01-sz02in10 sz03in01-sz03in10 sz04in01-sz04in10 sz05in01-sz05in10 sz06in01-sz06in10 sz07in01-sz07in10 sz08in01-sz08in10 sz09in01-sz09in10 sz10in01-sz10in10,1);*/

/*industry portfolios*/

/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/5_Industry_Portfolios_CSV.zip,5_Industry_Portfolios.CSV,z05,z1-z5,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/10_Industry_Portfolios_CSV.zip,10_Industry_Portfolios.CSV,z10,z01-z10,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/12_Industry_Portfolios_CSV.zip,12_Industry_Portfolios.CSV,z12,z01-z12,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/17_Industry_Portfolios_CSV.zip,17_Industry_Portfolios.CSV,z17,z01-z37,1);*/
%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/30_Industry_Portfolios_CSV.zip,30_Industry_Portfolios.CSV,z30,z01-z30,1);
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/38_Industry_Portfolios_CSV.zip,38_Industry_Portfolios.CSV,z38,z01-z38,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/48_Industry_Portfolios_CSV.zip,48_Industry_Portfolios.CSV,z48,z01-z48,1);*/
/*%http(https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/49_Industry_Portfolios_CSV.zip,49_Industry_Portfolios.CSV,z49,z01-z49,1);*/

/*tests*/

%iml(p025szmo ff3,month>=196307,sz:,rm_rf smb hml);
/*%iml(p025szmo ff3 ffm,month>=196307,sz:,rm_rf smb hml wml);*/
/*%iml(p025szmo ff3 z30,month>=196307,sz: z:,rm_rf smb hml);*/
/*%iml(p025szmo ff3 z30 ffm,month>=196307,sz: z:,rm_rf smb hml wml);*/
/*%iml(p025szmo ff5,month>=196307,sz:,rm_rf smb hml rmw cma);*/
/*%iml(p025szmo ff5 ffm,month>=196307,sz:,rm_rf smb hml rmw cma wml);*/
/*%iml(p025szmo ff5 z30,month>=196307,sz: z:,rm_rf smb hml rmw cma);*/
/*%iml(p025szmo ff5 z30 ffm,month>=196307,sz: z:,rm_rf smb hml rmw cma wml);*/

quit;
