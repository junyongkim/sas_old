resetline;
option ls=128 ps=max;
goption xpixels=640 ypixels=480 border;

libname _180208 "/home/uwm/junyong/data/180208";

data _180208.helloworld;
	call streaminit(1);
	do i=1 to 100;
		x=rand("normal");
		output;
	end;
run;

quit;