/*************************************************
191221moody
downloads the moody book-to-market data of french
*************************************************/

filename a "%sysfunc(getoption(work))\a";

proc http out=a url="http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/historical_be_data.zip";
run;

filename a zip "%sysfunc(getoption(work))\a";

data moody;
	infile a(DFF_BE_With_Nonindust.txt);
	input permno begin end y1926-y2001;
run;

proc transpose out=moody;
	by permno begin end;
	var y:;
run;

proc sql;
	create table moody as
	select permno,
		input(substr(_name_,2,4),4.) as year,
		col1 as moody
	from moody
	having begin<=year<=end and moody>-99.99
	order by permno,year;
quit;
