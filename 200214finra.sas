/*------------------------------------------------
200214finra
downloads the finra margin stats (csv sas7bdat)
------------------------------------------------*/
filename finra temp;

proc http url="https://www.finra.org/investors/learn-to-invest/advanced-investing/margin-statistics" out=finra;
run;

data finra(drop=line);
	infile finra truncover;
	input line $32767.;
	if count(line,"td data");
	length name $32 data $12;
	name=compress(scan(line,2,'"')," '*/");
	data=tranwrd(scan(reverse(scan(reverse(line),2,">")),1,"<"),"Sept","Sep");
	if name="MonthYear" then i+1;
run;

proc transpose out=finra(drop=i _name_);
	by i;
	id name;
	var data;
run;

data finra;
	set finra;
	if cmiss(debitbalances)=0 then Stat="1_FINRA+NYSE";
	else if cmiss(debitbalancesinmarginaccounts)=0 then stat="2_NYSE";
	else if cmiss(debitbalancesincustomerscashandm)=0 then stat="3_FINRA";
	if cmiss(debitbalancesincustomerssecuriti)=0 then stat="4_FINRA2";
	Date=input(monthyear,monyy10.);
run;

libname desktop "!userprofile\desktop\";

proc sql;
	create table desktop.finra as
		select stat,
			date format=yymmn6.,
			input(DebitBalances,comma12.) as DebitBalances,
			input(CreditBalances,comma12.) as CreditBalances,
			input(DebitBalancesinMarginAccounts,comma12.) as DebitBalancesinMarginAccounts,
			input(FreeCreditBalancesinCashAccounts,comma12.) as FreeCreditBalancesinCashAccounts,
			input(FreeCreditBalancesinMarginAccoun,comma12.) as FreeCreditBalancesinMarginAccoun,
			input(DebitBalancesinCustomersCashandM,comma12.) as DebitBalancesinCustomersCashandM,
			input(FreeandOtherCreditBalancesinCust,comma12.) as FreeandOtherCreditBalancesinCust,
			input(DebitBalancesinCustomersSecuriti,comma12.) as DebitBalancesinCustomersSecuriti,
			input(FreeCreditBalancesinCustomersCas,comma12.) as FreeCreditBalancesinCustomersCas,
			input(FreeCreditBalancesinCustomersSec,comma12.) as FreeCreditBalancesinCustomersSec
		from finra
		order by stat,date;
quit;

proc export replace file="!userprofile\desktop\finra.csv";
run;
