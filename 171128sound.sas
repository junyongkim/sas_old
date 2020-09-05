resetline;
ods html close;
ods graphics off;
ods listing;
option linesize=128 pagesize=max;
goption xpixels=640 ypixels=480 border;

data sound;
	do repeat=1 to 2;
		call sound(659.28,225);
		call sound(587.36,75);
		call sound(659.28,300);
		call sound(587.36,600);
		call sound(493.92,225);
		call sound(440.00,75);
		call sound(493.92,300);
		call sound(440.00,600);
	end;
run;

quit;
