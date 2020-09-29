rsubmit;

proc sql;
	create table ret_sharpe11 as
		select a.*,sharpe11
		from ret a
			join sharpe11_rank b on a.permno=b.permno and intnx("month",a.date,0)=intnx("month",b.date,2)
		order by permno,date;
quit;

endrsubmit;
