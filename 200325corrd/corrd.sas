proc sql;
	create table ret as
		select permno,a.date,ret-rf as ret
		from crsp.dsf a join ff.factors_daily b on a.date=b.date where ret>.z
		order by permno,date;
quit;

%macro corr;

proc delete data=corr;
run;

%do i=1 %to 12*(2019-1928+1)+7;

proc sql noprint;
	select n(date) into :n trimmed from ff.factors_daily where intnx("mon","1jun1927"d,&i.-12)-1<date<intnx("mon","1jun1927"d,&i.);
quit;

proc sql;
	create table re as
		select *
		from ret where intnx("mon","1jun1927"d,&i.-12)-1<date<intnx("mon","1jun1927"d,&i.)
		group by permno
		having n(ret)=&n.
		order by date,permno;
quit;

proc transpose prefix=r out=r(drop=date _name_);
	by date;
	id permno;
run;

proc iml;
	use r;
	read all var _all_ into r;
	t=intnx("mon","1jun1927"d,&i.-1);
	t=100*year(t)+month(t);
	n=ncol(r);
	c=corr(r);
	c[do(1,n**2,n+1)]=.;
	c=c[:];
	create c var{t n c};
	append;
quit;

proc append base=corr;
run;

%end;

%mend;

option nonotes;

%corr

option notes;

proc export replace file="corrd.csv";
run;
