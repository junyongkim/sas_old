resetline;
ods html close;
ods graphics off;
ods listing;
option linesize=128 pagesize=max;
goption xpixels=640 ypixels=480 border;

%let numberofsimulations=1000;
%let sizeofsimulations=100;
data simulateddata;
	label s= n= t= x= y= x1= y1=;
	do s=1 to &numberofsimulations.;
		cumulatex=0;
		cumulatey=0;
		do n=1 to &sizeofsimulations.;
			t=n;
			x=1+rannor(1);
			*x=rannor(1);/*if x is centered*/
			y=rannor(1);
			cumulatex+x;
			cumulatey+y;
			xbarn=cumulatex/n;
			ybart=cumulatey/t;
			scalexbarn=xbarn*sqrt(n);
			scaleybart=ybart*sqrt(t);
			sequence=scalexbarn*scaleybart/sqrt(n);
			*sequence=scalexbarn*scaleybart;/*if x is centered*/
			output;
		end;
	end;
run;

%macro symbolplot;
%do symbol=1 %to &numberofsimulations.;
symbol&symbol. i=join;
%end;
%mend;
%symbolplot;
proc gplot data=simulateddata;
	plot sequence*n=s/nolegend;
	label sequence="the sequence";
	label n="n=t";
run;
%macro cancelsymbolplot;
%do symbol=1 %to &numberofsimulations.;
symbol&symbol.;
%end;
%mend;
%cancelsymbolplot;

proc univariate data=simulateddata;
	var sequence;
	where n=&sizeofsimulations.;
	histogram/normal(mu=0,sigma=1);
run;

quit;
