libname s "!userprofile\desktop\sas_old\200929sharper\ret_sharpe11\";

rsubmit;

proc sql;
	create table ret_sharpe11_10 as
		select date,
			sum(ifn(sharpe11=0,size1,.)*ret)/sum(ifn(sharpe11=0,size1,.)) as s0,
			sum(ifn(sharpe11=1,size1,.)*ret)/sum(ifn(sharpe11=1,size1,.)) as s1,
			sum(ifn(sharpe11=2,size1,.)*ret)/sum(ifn(sharpe11=2,size1,.)) as s2,
			sum(ifn(sharpe11=3,size1,.)*ret)/sum(ifn(sharpe11=3,size1,.)) as s3,
			sum(ifn(sharpe11=4,size1,.)*ret)/sum(ifn(sharpe11=4,size1,.)) as s4,
			sum(ifn(sharpe11=5,size1,.)*ret)/sum(ifn(sharpe11=5,size1,.)) as s5,
			sum(ifn(sharpe11=6,size1,.)*ret)/sum(ifn(sharpe11=6,size1,.)) as s6,
			sum(ifn(sharpe11=7,size1,.)*ret)/sum(ifn(sharpe11=7,size1,.)) as s7,
			sum(ifn(sharpe11=8,size1,.)*ret)/sum(ifn(sharpe11=8,size1,.)) as s8,
			sum(ifn(sharpe11=9,size1,.)*ret)/sum(ifn(sharpe11=9,size1,.)) as s9
		from ret_sharpe11
		group by date
		order by date;
quit;

proc download out=s.ret_sharpe11_10;
run;

endrsubmit;
