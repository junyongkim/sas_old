/*******************************************************************************
REPLICATES VUOL 2002 TABLE 1
*******************************************************************************/
data _null_;
	infile "!userprofile\desktop\sas_old\201016vuol\all1.sas7bdat" recfm=f;
	input;
	file "%sysfunc(pathname(work))\all1.sas7bdat" recfm=n;
	put _infile_;
run;

/***************************************
DEMEANS BY CROSS-SECTION
***************************************/
proc sql;
	create table all2 as
		select *,
			ret5-mean(ret5) as ret5d,
			ret51-mean(ret51) as ret51d,
			roe3-mean(roe3) as roe3d,
			roe31-mean(roe31) as roe31d,
			leverage2-mean(leverage2) as leverage2d,
			leverage21-mean(leverage21) as leverage21d,
			booktomarket3-mean(booktomarket3) as booktomarket3d,
			booktomarket31-mean(booktomarket31) as booktomarket31d
		from all1(where=(1954<=year(date)-1<=1996))
		group by year(date)
		order by permco,date;
quit;

ods select none;
ods results=off;

proc means maxdec=4 stackodsoutput mean std min q1 median q3 max;
	var ret5 roe3 leverage2 booktomarket3 ret5d roe3d leverage2d booktomarket3d;
	label ret5="$r$" roe3="$e^{GAAP}-f$"
		leverage2="$lev$" booktomarket3="$\theta$"
		ret5d="$\tilde{r}$" roe3d="$\tilde{e}^{GAAP}$"
		leverage2d="$\tilde{lev}$" booktomarket3d="$\tilde{\theta}$";
	ods output summary=tab1(drop=variable);
run;

ods results=on;
ods select all;

proc export replace file="!userprofile\desktop\sas_old\201016vuol\tab1.csv";
run;
