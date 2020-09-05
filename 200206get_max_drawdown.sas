/*------------------------------------------------
200206get_max_drawdown
replicates john's get_max_drawdown.m code
downloads ken's mkt series as an example
------------------------------------------------*/

filename z "%sysfunc(getoption(work))\z";

proc http url="https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_CSV.zip" out=z;
run;

filename z zip "%sysfunc(getoption(work))\z";

data f;
	infile z(F-F_Research_Data_Factors.CSV) dsd truncover;
	input date mkt_rf smb hml rf;
run;

/*++++++++++++++++++++++++++++++++++++++++++++++++
FEED THE DRAWDOWN BELOW WITH DATE AND RETURN ONLY
++++++++++++++++++++++++++++++++++++++++++++++++*/

data drawdown;
	set f;
	where 100000<=date<=999999;
	by date;
	return=mkt_rf+rf;
	keep date return;
run;

/*------------------------------------------------
this iml identifies d drawdowns and attached some
related drawdown variables to the initial data
------------------------------------------------*/

proc iml;
	use drawdown;
		read all var _all_;
	close;

/*++++++++++++++++++++++++++++++++++++++++++++++++
DETERMINE THE NUMBER OF DRAWDOWNS TO BE EXTRACTED
++++++++++++++++++++++++++++++++++++++++++++++++*/

	d=50;

/*------------------------------------------------
processes the ingredients
------------------------------------------------*/

	cumret=cuprod(1+return/100);
	t=nrow(return);
	drawdown=j(t,1,0);
	do s=1 to t;
		drawdown[s]=cumret[s]/max(cumret[1:s])-1;
	end;

/*------------------------------------------------
initializes the drawdown variables
------------------------------------------------*/

	drawdown_num=j(t,1,0);
	drawdown_num_startend=j(t,1,0);
	drawdown_max=j(t,1,0);
	drawdown_start_date=j(t,1,0);
	drawdown_end_date=j(t,1,0);
	drawdown_recovery_date=j(t,1,0);
	drawdown_startrecovery_idx=j(t,1,0);
	drawdown_startend_idx=j(t,1,0);
	drawdown_endrecovery_idx=j(t,1,0);

/*------------------------------------------------
fills the variables for each drawdown
------------------------------------------------*/

	drawdown_=drawdown;
	do c=1 to 50;
		i=loc(drawdown_=min(drawdown_));
		do j=i to 1 by -1 until(drawdown_[j]=0);
		end;
		do k=i to t until(drawdown_[k]=0);
		end;
		drawdown_num[j+1:k]=d;
		drawdown_num_startend[j+1:i]=c;
		drawdown_max[j+1:k]=min(drawdown_);
		drawdown_start_date[j+1:k]=date[j+1];
		drawdown_end_date[j+1:k]=date[i];
		drawdown_recovery_date[j+1:k]=date[k];
		drawdown_startrecovery_idx[j+1:k]=1:k-j;
		drawdown_startend_idx[j+1:i]=1:i-j;
		drawdown_endrecovery_idx[i+1:k]=1:k-i;
		drawdown_[j+1:k-1]=0;
	end;

/*------------------------------------------------
attaches the results to the original data
------------------------------------------------*/

	create drawdown var{date return cumret drawdown drawdown_num drawdown_num_startend drawdown_max drawdown_start_date drawdown_end_date drawdown_recovery_date drawdown_startrecovery_idx drawdown_startend_idx drawdown_endrecovery_idx};
		append;
	close;
quit;

/*++++++++++++++++++++++++++++++++++++++++++++++++
SPITS OUT THE CSV TO THE ADDRESS BELOW
++++++++++++++++++++++++++++++++++++++++++++++++*/

proc export replace file="!userprofile\desktop\drawdown.csv";
run;
