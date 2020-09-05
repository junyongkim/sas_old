resetline;
option nodate nonumber ls=128 ps=max;

proc datasets lib=work kill nolist;
run;

data _01;
	format i t x y;
	call streaminit(1);
	do t=1 to 200;
		x=rand("normal");
		do i=1 to 10;
			y=x+rand("normal");
			output;
		end;
	end;
run;

proc sort;
	by i t;
run;

%macro rolling;

%let time0=%sysfunc(time());

filename null dummy;
proc printto log=null;
run;

%do t=100 %to 200;

proc reg data=_01 outest=_99 noprint;
	model y=x;
	where &t.-99<=t<=&t.;
	by i;
run;

data _99;
	format i t beta;
	set _99(keep=i x rename=(x=beta));
	t=&t.;
run;

proc append base=_02 data=_99;
run;

%end;

proc sort;
	by i t;
run;

proc datasets lib=work nolist;
	delete _99;
run;

proc printto;
run;

%let time1=%sysfunc(putn(%sysevalf(%sysfunc(time())-&time0.),time12.4));
%put &time1.;

%mend;

%rolling;

quit;
