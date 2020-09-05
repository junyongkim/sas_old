resetline;
ods html close;
ods graphics off;
ods listing;
option linesize=128 pagesize=max;
goption xpixels=1024 ypixels=768 border;

%let numberofsimulations=1000;
%let sizeofsimulations=1000;
data simulateddata;
	do s=1 to &numberofsimulations.;
		do n=1 to &sizeofsimulations.;
			x=rannor(1);
			w=2*ranbin(1,1,0.5)-1;
			y=w*x;
			if n=1 then do;
				cumulatex=x;
				cumulatey=y;
			end;
			else do;
				cumulatex+x;
				cumulatey+y;
			end;
			sequencex=cumulatex/sqrt(n);
			sequencey=cumulatey/sqrt(n);
			output;
		end;
	end;
run;

axis1 order=(-4 to 4 by 1);
axis2 order=(-4 to 4 by 1);
symbol v=dot cv=blue;
proc gplot data=simulateddata;
	plot sequencey*sequencex/vaxis=axis1 haxis=axis2;
	where n=1;
run;

proc gplot data=simulateddata;
	plot sequencey*sequencex/vaxis=axis1 haxis=axis2;
	where n=&sizeofsimulations.;
run;

quit;
