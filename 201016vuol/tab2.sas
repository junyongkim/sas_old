/*******************************************************************************
REPLICATES VUOL 2002 TABLE 2
*******************************************************************************/
data _null_;
	infile "!userprofile\desktop\sas_old\201016vuol\all1.sas7bdat" recfm=f;
	input;
	file "%sysfunc(pathname(work))\all1.sas7bdat" recfm=n;
	put _infile_;
run;

proc sql;
	create table all2 as
		select *,year(date)-1 as y,1/n(permco) as weight,
			ret5-mean(ret5) as ret5d,
			ret51-mean(ret51) as ret51d,
			roe3-mean(roe3) as roe3d,
			roe31-mean(roe31) as roe31d,
			booktomarket3-mean(booktomarket3) as booktomarket3d,
			booktomarket31-mean(booktomarket31) as booktomarket31d
		from all1(where=(1954<=year(date)-1<=1996))
		group by year(date)
		order by date,permco;
quit;

proc iml;
/***************************************
MAKES STORAGES FOR LEAVE-ONE-OUT VALUES
***************************************/
	b=j(1996-1954+1,9,.);
	s=j(1996-1954+1,9,.);
	do i=1954 to 1996;
		use all2 where(y^=i);
		read all var{weight};
		read all var{ret5d booktomarket3d roe3d} into y;
		read all var{ret51d booktomarket31d roe31d} into x;
/***************************************
ADJUSTS WEIGHTS FOR SIGMAS
***************************************/
		w=weight/sum(weight)*nrow(weight);
		y=w#y;
		x=w#x;
		bi=inv(x`*x)*x`*y;
/***************************************
PASSES ANNUAL ESTIMATES TO THE STORAGE
***************************************/
		b[i-1953,]=shape(bi,1);
		s[i-1953,]=shape((y-x*bi)`*(y-x*bi)/(nrow(y)-ncol(x)),1);
	end;
	tab2=j(6,6,.);
/***************************************
TABULATES ESTIMATES AND STANDARD ERRORS
***************************************/
	tab2[{1 3 5},1:3]=shape(mean(b),3)`;
	tab2[{2 4 6},1:3]=shape(sqrt((nrow(b)-1)/nrow(b)*(b-b[:,])[##,]),3)`;
	tab2[{1 3 5},4:6]=shape(mean(s),3);
	tab2[{2 4 6},4:6]=shape(sqrt((nrow(s)-1)/nrow(s)*(s-s[:,])[##,]),3);
	mattrib tab2 format=8.4;
	COL0={"$\tilde{r}_t$","","$\tilde{\theta}_t$","","$\tilde{e}_t$",""};
	create tab2 from tab2[r=col0];
	append from tab2[r=col0];
quit;

proc export replace file="!userprofile\desktop\sas_old\201016vuol\tab2.csv";
run;
