rsubmit;

proc sql;
	create table sharpe11 as
		select permno+0 as permno,
			date+0 as date,
			ret+0 as sharpe11
		from crsp.msf
		group by permno
		having n(ret)
		order by permno,date;
quit;

proc expand method=none out=sharpe11(where=(ave11>. and std11>0));
	by permno;
	id date;
	convert sharpe11=ave11/tout=(nomiss movave 11 trimleft 10);
	convert sharpe11=std11/tout=(nomiss movstd 11 trimleft 10);
run;

data sharpe11(drop=ave11 std11);
	set sharpe11;
	sharpe11=ave11/std11;
run;

endrsubmit;
