/*------------------------------------------------
200219riskmanagedmomentum
replicates barroso santa-clara 2015 using french
------------------------------------------------*/
/*------------------------------------------------
downloads monthly momentum
------------------------------------------------*/
filename momm "%sysfunc(getoption(work))\momm";

proc http url="http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/10_portfolios_prior_12_2_csv.zip" out=momm;
run;

filename momm zip "%sysfunc(getoption(work))\momm";

data momm;
	infile momm(10_Portfolios_Prior_12_2.CSV) dsd truncover firstobs=12 obs=1127;
	input date p1-p10;
	wml=p10-p1;
run;

/*------------------------------------------------
downloads daily momentum
------------------------------------------------*/
filename momd "%sysfunc(getoption(work))\momd";

proc http url="http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/10_portfolios_prior_12_2_daily_csv.zip" out=momd;
run;

filename momd zip "%sysfunc(getoption(work))\momd";

data momd;
	infile momd(10_Portfolios_Prior_12_2_Daily.CSV) dsd truncover firstobs=11 obs=24551;
	input date p1-p10;
	wml=p10-p1;
run;

/*------------------------------------------------
computes scaling factors from daily momentum and
applies the factors to monthly momentum
------------------------------------------------*/
proc expand data=momd(keep=date wml) method=none out=sc(where=(int(date/100)^=int(dat/100)));
	id date;
	convert date=dat/tout=(lead 1);
	convert wml=sc/tout=(square nomiss movave 126 trimleft 125 *21 /12 sqrt reciprocal);
run;

proc sql;
	create table wml as
	select a.date,a.wml,a.wml*sc as wmlsc format=12.2
	from momm a join sc b
	on a.date=int(b.dat/100)
	order by date;
quit;

proc means max min mean std kurt skew maxdec=2;
	var wml wmlsc;
run;
