rsubmit;

proc sql;
	create table sharpe11_breakpoint as
		select date,sharpe11
		from sharpe11 a
			join exchcd(where=(exchcd=1)) b
				on a.permno=b.permno and namedt<=date<=nameendt
		order by date;
quit;

proc univariate noprint;
	by date;
	var sharpe11;
	output out=sharpe11_breakpoint
		pctlpre=sharpe11
		pctlpts=10 20 30 40 50 60 70 80 90;
run;

proc datasets nolist;
	modify sharpe11_breakpoint;
	attrib _all_ label=" ";
run;

endrsubmit;
