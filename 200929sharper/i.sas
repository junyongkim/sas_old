libname f "!userprofile\desktop\french\sas7bdat\";

/*------------------------------------------------
i is the sharper momentum
j is the original momentum
------------------------------------------------*/
proc sql;
	create table i(drop=j k rename=(r=j s=i)) as
		select i.*,j.*,k.*,r9*100-r0*100 as r,s9*100-s0*100 as s
		from f.d001 i
			join r.ret_ret11_10(rename=(date=j)) j on put(date,6.)=put(j,yymmn6.)
			join s.ret_sharpe11_10(rename=(date=k)) k on put(date,6.)=put(k,yymmn6.)
		order by date;
quit;

proc model data=i;
	i=ai;
	j=aj;
	instruments/intonly;
	fit i j/gmm vardef=n kernel=(bart,13,0);
	ods select parameterestimates;
quit;

proc model data=i;
	i=ai+bi*mkt_rf;
	j=aj+bj*mkt_rf;
	fit i j/gmm vardef=n kernel=(bart,13,0);
	ods select parameterestimates;
quit;

proc model data=i;
	i=ai+bi*mkt_rf+ci*smb+di*hml;
	j=aj+bj*mkt_rf+cj*smb+dj*hml;
	fit i j/gmm vardef=n kernel=(bart,13,0);
	ods select parameterestimates;
quit;

proc model data=i;
	i=a+b*j;
	fit i/gmm vardef=n kernel=(bart,13,0);
	ods select parameterestimates;
quit;
