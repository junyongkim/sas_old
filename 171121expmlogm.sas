resetline;
ods html close;
ods graphics off;
ods listing;
option linesize=128 pagesize=max;
goption xpixels=640 ypixels=480 border;

proc iml;
	start expm(input);
		call eigen(eval,evec,input);
		output=evec*diag(exp(eval))*evec`;
		return(output);
	finish;
	start logm(input);
		call eigen(eval,evec,input);
		output=evec*diag(log(eval))*evec`;
		return(output);
	finish;
	x=rannor(j(100,4,1));
	a=cov(x);
	b=expm(a);
	c=logm(b);
	d=logm(a);
	e=expm(d);
	print a[format=12.4],,
		b[format=12.4],,
		c[format=12.4],,
		d[format=12.4],,
		e[format=12.4];
quit;
