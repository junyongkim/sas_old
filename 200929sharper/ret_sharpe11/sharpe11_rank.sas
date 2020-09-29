rsubmit;

proc sql;
	create table sharpe11_rank as
		select permno,
			a.date,
			case when sharpe11>sharpe1190 then 9
				when sharpe11>sharpe1180 then 8
				when sharpe11>sharpe1170 then 7
				when sharpe11>sharpe1160 then 6
				when sharpe11>sharpe1150 then 5
				when sharpe11>sharpe1140 then 4
				when sharpe11>sharpe1130 then 3
				when sharpe11>sharpe1120 then 2
				when sharpe11>sharpe1110 then 1
				else 0 end as sharpe11
		from sharpe11 a
			join sharpe11_breakpoint b
				on a.date=b.date
		order by permno,date;
quit;

endrsubmit;
