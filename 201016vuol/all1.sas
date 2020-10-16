/*******************************************************************************
DOWNLOADS PANEL DATA BASED ON VUOL 2002 SEC 2
*******************************************************************************/
%let wrds=wrds.wharton.upenn.edu 4016;
signon wrds username=_prompt_;
rsubmit;

/***************************************
RET2 ADJUSTS DELISTING
***************************************/
proc sql;
	create table msf2 as
		select i.*,
			ifn(dlret>.z,sum(1,ret)*sum(1,dlret)-1,ret) as ret2,
			abs(prc)*shrout as size
		from crsp.msf i left join crsp.msedelist j
			on i.permno=j.permno & put(date,yymm.)=put(dlstdt,yymm.)
		order by permno,date;
quit;

/***************************************
COMPUTES REQUIRED PAST RETURNS
RET2T IS THE PREVIOUS MONTHLY RETURN
RET2T1 IS THE PREVIOUS ANNUAL RETURN
***************************************/
proc printto log="/dev/null";
run;

proc expand method=none out=msf2;
	by permno;
	id date;
	convert ret2=ret3/tout=(+1 nomiss movprod 12 trimleft 11 -1);
	convert size=size2/tout=(lag 12);
	convert retx=retx2/tout=(+1 nomiss movprod 12 trimleft 11 -1);
	convert ret2=ret2t/tout=(lag 1);
	convert ret2=ret2t1/tout=(+1 movprod 12 -1 lag 12);
	convert ret2=ret2t2/tout=(+1 movprod 12 -1 lag 24);
	convert ret2=ret2t3/tout=(+1 movprod 12 -1 lag 36);
	convert ret2=ret2t4/tout=(+1 movprod 12 -1 lag 48);
	convert ret2=ret2t5/tout=(+1 movprod 12 -1 lag 60);
run;

proc printto;
run;

data msenames2;
	set crsp.msenames;
	by permno;
	if last.permno then nameendt=intnx("mon",nameendt,0,"e");
run;

/***************************************
EXCLUDES NON-COMMON STOCKS
***************************************/
proc sql;
	create table msf3 as
		select i.*
		from msf2(where=(month(date)=5)) i
			join msenames2(where=(shrcd in (10,11))) j
				on i.permno=j.permno & namedt<=date<=nameendt
		order by permco,date;
quit;

/***************************************
COMPUTES VALUE-WEIGHTED ANNUAL RETURNS
COMPUTES NON-DIVIDEND ONES TO BACKFILL
***************************************/
proc summary;
	where size2>.;
	by permco date;
	var ret3 retx2;
	weight size2;
	output mean=ret3 retx2 out=msf4;
run;

/***************************************
GETS PAST RETURNS TO MEET REQUIREMENTS
***************************************/
proc summary data=msf3;
	by permco date;
	var size size2 ret2t ret2t1 ret2t2 ret2t3 ret2t4 ret2t5;
	output sum=size size2 ret2t ret2t1 ret2t2 ret2t3 ret2t4 ret2t5 out=msf5;
run;

data msf4;
	merge msf4 msf5;
	by permco date;
run;

/***************************************
PASSES SIZES TO COMPUSTAT DATA
***************************************/
data msf5;
	merge msf5 msf4;
	by permco date;
	size3=coalesce(size,size2*(1+retx2));
run;

proc sql undo_policy=none;
	create table msf5 as
		select gvkey,date,size3
		from msf5 join crsp.ccmxpf_lnkhist(where=(linkprim in ("P","C") &
			linktype in ("LC","LU")))
			on permco=lpermco & linkdt<=date<=coalesce(linkenddt,"31dec2100"d)
		order by gvkey,date;
quit;

/***************************************
GETS THE RISKFREE FOR RETURNS AND ROES
***************************************/
proc expand data=ff.factors_monthly method=none out=factors_monthly2;
	id date;
	convert rf=rf2/tout=(+1 nomiss movprod 12 trimleft 11 -1);
run;

/***************************************
COMPUTES 90-10 STOCK-RISKFREE RETURNS
SUBTRACTS RISKFREE SO .9*RET3-.9*RF2
***************************************/
proc sql;
	create table msf6 as
		select i.*,0.9*ret3-0.9*rf2 as ret4
		from msf4 i left join factors_monthly2 j on intnx("mon",i.date,0)=j.date
		order by permco,date;
quit;

/***************************************
HANDLES COMPUSTAT DATA
***************************************/
proc sql undo_policy=none;
/***************************************
COMPUTES BOOK-TO-MARKETS
***************************************/
	create table funda2 as
		select i.*,
			coalesce(ceq,ceql)+sum(txditc,txp,0) as book,
			size3/1000 as market,
			calculated book/calculated market as booktomarket
		from comp.funda(where=(fyear & indfmt="INDL" & consol="C" & popsrc="D" &
			datafmt="STD" & acctstd="DS")) i left join msf5 j
			on i.gvkey=j.gvkey & fyear=year(date)-1
		order by gvkey,fyear;
/***************************************
BACKFILLS MISSING BOOK-TO-MARKETS
***************************************/
	create table funda2 as
		select i.*,
			coalesce(i.book,
				j.book+i.ni-i.dv,
				i.booktomarket*j.market) as book2,
			ifn(calculated book2>0,calculated book2,.) as book3
		from funda2 i left join funda2 j on i.gvkey=j.gvkey & i.fyear=j.fyear+1
		order by gvkey,fyear;
/***************************************
COMPUTES ROES AND LEVERAGES
***************************************/
	create table funda2 as
		select i.*,
			max(coalesce(i.ni,i.book3-j.book3+i.dv),-j.book3)/j.book3 as roe,
			i.book3/sum(i.book3,i.dlc,i.dltt,i.pstk) as leverage
		from funda2 i left join funda2 j on i.gvkey=j.gvkey & i.fyear=j.fyear+1
		order by gvkey,fyear;
/***************************************
COMPUTES PORTFOLIO B/MS AND EXCESS ROES
***************************************/
	create table funda2 as
		select i.*,
			0.9*booktomarket+0.1 as booktomarket2,
			0.9*roe-0.9*rf2 as roe2
		from funda2 i left join factors_monthly2(where=(month(date)=5)) j
			on fyear=year(date)-1
		order by gvkey,fyear;
quit;

/***************************************
CHECKS IF OBSERVATIONS MEET REQUIREMENTS
***************************************/
proc sql undo_policy=none;
	create table funda3 as
		select i.*,j.fyr as fyrt1,
			j.book3 as bookt1,k.book3 as bookt2,l.book3 as bookt3,
			j.ni as nit1,k.ni as nit2,j.dltt as dlttt1,k.dltt as dlttt2
		from funda2 i
			left join funda2 j on i.gvkey=j.gvkey & i.fyear=j.fyear+1
			left join funda2 k on i.gvkey=k.gvkey & i.fyear=k.fyear+2
			left join funda2 l on i.gvkey=l.gvkey & i.fyear=l.fyear+3
		having fyrt1=12 & bookt1>. & bookt2>. & bookt3>. &
			nit1>. & nit2>. & dlttt1>. & dlttt2>. & 1/100<=booktomarket2<=100
		order by gvkey,fyear;
/***************************************
PASSES COMPUSTAT TO CRSP
***************************************/
	create table funda3 as
		select lpermco,i.*
		from funda3 i join crsp.ccmxpf_lnkhist(where=(linkprim in ("P","C") &
			linktype in ("LC","LU"))) j on i.gvkey=j.gvkey &
			linkdt<=datadate<=coalesce(linkenddt,"31dec2100"d)
		order by lpermco,datadate;
quit;

proc sql;
	create table msf7 as
		select i.*,j.size2 as size2t1,k.size2 as size2t2
		from msf6 i
			left join msf6 j on i.permco=j.permco & year(i.date)=year(j.date)+1
			left join msf6 k on i.permco=k.permco & year(i.date)=year(k.date)+2
		having size2>10000 & size2t1>. & size2t2>. & ret2t>. & ret2t1>. &
			ret2t2>. & ret2t3>. & ret2t4>. & ret2t5>.
		order by permco,date;
quit;

/***************************************
JOINS CRSP AND COMPUSTAT
***************************************/
proc sql;
	create table all1 as
		select i.permco+0 as permco format=best8.,
			i.date+0 as date format=yymmddn8.,
			log(1+i.ret4) as ret5 format=best8.,
			log(1+j.ret4) as ret51 format=best8.,
			log(1+k.roe2) as roe3 format=best8.,
			log(1+l.roe2) as roe31 format=best8.,
			log(k.leverage) as leverage2 format=best8.,
			log(l.leverage) as leverage21 format=best8.,
			log(k.booktomarket2) as booktomarket3 format=best8.,
			log(l.booktomarket2) as booktomarket31 format=best8.
		from msf7 i
			join msf7 j on i.permco=j.permco & year(i.date)=year(j.date)+1
			join funda3 k on i.permco=k.lpermco & year(i.date)=k.fyear+1
			join funda3 l on i.permco=l.lpermco & year(i.date)=l.fyear+2
		having ret5>. & ret51>. & roe3>. & roe31>. & leverage2>. &
			leverage21>. & booktomarket3>. & booktomarket31>.
		order by permco,date;
quit;

proc download;
run;

endrsubmit;

data _null_;
	infile "%sysfunc(pathname(work))\all1.sas7bdat" recfm=f;
	input;
	file "!userprofile\desktop\sas_old\201016vuol\all1.sas7bdat" recfm=n;
	put _infile_;
run;
