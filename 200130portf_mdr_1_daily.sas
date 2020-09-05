/*************************************************
200130portf_mdr_1_daily
computes maximum daily return decile portfolio
daily returns
mimics the global-q data
*************************************************/

%let wrds=wrds.wharton.upenn.edu 4016;
signon wrds username=_prompt_;

rsubmit;

proc sql;
	create table dsf as select *,max(ret) as max from crsp.dsf where ret>-1 group by permno,intnx("mon",date,0) having date=max(date) and sum(ret>-1)>14;
	create table dsf as select a.*,abs(a.prc)*a.shrout/(1+a.ret) as size1,max as max1 from crsp.dsf a left join dsf b on a.permno=b.permno and intnx("mon",a.date,0)=intnx("mon",b.date,1);
	create table dsf as select a.*,exchcd from dsf a left join crsp.dsenames b on a.permno=b.permno and namedt<=date<=nameendt where ret>-1 and max1 and size1 and shrcd in (10,11) order by date;
quit;

proc univariate noprint;
	where exchcd=1;
	by date;
	var max1;
	output out=max1 pctlpre=max1 pctlpts=0 10 20 30 40 50 60 70 80 90 100;
run;

proc sql;
	create table dsf as select a.*,max10,max110,max120,max130,max140,max150,max160,max170,max180,max190,max1100 from dsf a left join max1 b on a.date=b.date order by date,max1;
quit;

data dsf;
	set dsf;
	if max1 then do;
		if max1<=max110 then rank_Mdr_1=1;
		else if max1<=max120 then rank_mdr_1=2;
		else if max1<=max130 then rank_mdr_1=3;
		else if max1<=max140 then rank_mdr_1=4;
		else if max1<=max150 then rank_mdr_1=5;
		else if max1<=max160 then rank_mdr_1=6;
		else if max1<=max170 then rank_mdr_1=7;
		else if max1<=max180 then rank_mdr_1=8;
		else if max1<=max190 then rank_mdr_1=9;
		else rank_mdr_1=10;
	end;
	ret=ret*100;
run;

proc means noprint;
	where rank_mdr_1;
	by date rank_mdr_1;
	var ret;
	weight size1;
	output out=rank_mdr_1(drop=_:) mean=ret_vw;
	format ret 8.4;
run;

proc download;
run;

endrsubmit;

proc export file="!userprofile\desktop\portf_mdr_1_daily.csv" replace;
run;

quit;
