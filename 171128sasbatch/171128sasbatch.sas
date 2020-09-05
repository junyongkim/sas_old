resetline;
ods html close;
ods graphics off;
ods listing;
option linesize=128 pagesize=max;
goption xpixels=640 ypixels=480 border;

proc iml;
	n=(1:100)`;
	x=rannor(j(100,1,1));
	y=x+rannor(j(100,1,1));
	dataset=n||x||y;
	create dataset(rename=(col1=n
		col2=x
		col3=y)) from dataset;
	append from dataset;
quit;

proc export data=dataset
	outfile="C:\Users\junyong\Desktop\171128sasbatch.csv"
	replace;
run;

quit;
