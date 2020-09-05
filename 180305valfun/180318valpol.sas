resetline;
option linesize=128 pagesize=max;
goption xpixels=640 ypixels=480 border htext=1.8 ftext="Courier New";
%let r=0.3;
%let beta=0.9;
%let ngrid=500;

/******************************
Exact solution
******************************/

data exact;
	do kgrid=1/&ngrid. to 2 by 1/&ngrid.;
		kp=(1+&r.)*&beta.*kgrid;
		cp=(1-&beta.)*kgrid;
		v=&beta.*log(&beta.*(1+&r.))/(1-&beta.)**2+log(1-&beta.)/(1-&beta.)+1/(1-&beta.)*log(kgrid);
		output;
	end;
run;

symbol1 i=join ci=blue w=2;
symbol2 i=join ci=black w=1;
axis1 order=(0 to 3 by 0.5) minor=none;
axis2 order=(0 to 0.6 by 0.2) minor=none;
axis3 order=(-80 to 0 by 20) minor=none;
axis4 order=(0 to 2 by 0.5) minor=none;
proc gplot data=exact;
	plot (kp kgrid)*kgrid/overlay vaxis=axis1 haxis=axis4;
	plot cp*kgrid/vaxis=axis2 haxis=axis4;
	plot v*kgrid/vaxis=axis3 haxis=axis4;
run;
symbol;
axis;

/******************************
Value function iteration
******************************/

proc iml;
	r=&r.;
	beta=&beta.;
	kgrid=(1:&ngrid.)`/&ngrid.*2;
	v=j(&ngrid.,1);
	epsi=1e-6;
	crit=1;
	maxit=200;
	iter=0;
	do while(crit>epsi&iter<maxit);
		do i=1 to &ngrid.;
			c=kgrid[i]-kgrid/(1+r);
			do j=1 to &ngrid.;
				if c[j]<=0 then c[j]=.;
			end;
			u=log(c);
			vnewcand=u+beta*v;
			if (iter=0&i=1) then vnew=j(&ngrid.,1);
			vnew[i]=max(vnewcand);
			if (iter=0&i=1) then decision=j(&ngrid.,1);
			do j=1 to &ngrid.;
				if vnew[i]=vnewcand[j] then decision[i]=j;
			end;
		end;
		crit=norm(vnew-v);
		v=vnew;
		iter=iter+1;
	end;
	kp=j(&ngrid.,1);
	do i=1 to &ngrid.;
		kp[i]=kgrid[decision[i]];
	end;
	cp=(1+r)*kgrid-kp;
	valfun=kgrid||kp||cp||v;
	create valfun(rename=(col1=kgrid
		col2=kp
		col3=cp
		col4=v)) from valfun;
	append from valfun;
	print iter;
quit;

symbol1 i=join ci=red w=2;
symbol2 i=join ci=black w=1;
axis1 order=(0 to 3 by 0.5) minor=none;
axis2 order=(0 to 0.6 by 0.2) minor=none;
axis3 order=(-80 to 0 by 20) minor=none;
axis4 order=(0 to 2 by 0.5) minor=none;
proc gplot data=valfun;
	plot (kp kgrid)*kgrid/overlay vaxis=axis1 haxis=axis4;
	plot cp*kgrid/vaxis=axis2 haxis=axis4;
	plot v*kgrid/vaxis=axis3 haxis=axis4;
run;
symbol;
axis;

/******************************
Policy function iteration
******************************/

proc iml;
	r=&r.;
	beta=&beta.;
	kgrid=(1:&ngrid.)`/&ngrid.*2;
	kp=j(&ngrid.,1,1e-6);
	decision=j(&ngrid.,1);
	epsi=1e-12;
	crit=1;
	maxit=200;
	iter=0;
	do while(crit>epsi&iter<maxit);
		c=kgrid-kp/(1+r);
		u=log(c);
		do i=1 to &ngrid.;
			if i=1 then transition=j(&ngrid.,&ngrid.,0);
			transition[i,decision[i]]=1;
		end;
		v=solve(i(&ngrid.)-beta*transition,u);
		do i=1 to &ngrid.;
			c=kgrid[i]-kgrid/(1+r);
			do j=1 to &ngrid.;
				if c[j]<=0 then c[j]=.;
			end;
			u=log(c);
			vcand=u+beta*v;
			vmax=max(vcand);
			do j=1 to &ngrid.;
				if vmax=vcand[j] then decision[i]=j;
			end;
			if (iter=0&i=1) then kpnew=j(&ngrid.,1);
			kpnew[i]=kgrid[decision[i]];
		end;
		crit=norm(kpnew-kp);
		iter=iter+1;
		kp=kpnew;
	end;
	cp=kgrid-kp/(1+r);
	v=log(cp)+beta*v;
	polfun=kgrid||kp||cp||v;
	create polfun(rename=(col1=kgrid
		col2=kp
		col3=cp
		col4=v)) from polfun;
	append from polfun;
	print iter;
quit;

symbol1 i=join ci=green w=2;
symbol2 i=join ci=black w=1;
axis1 order=(0 to 3 by 0.5) minor=none;
axis2 order=(0 to 0.6 by 0.2) minor=none;
axis3 order=(-80 to 0 by 20) minor=none;
axis4 order=(0 to 2 by 0.5) minor=none;
proc gplot data=polfun;
	plot (kp kgrid)*kgrid/overlay vaxis=axis1 haxis=axis4;
	plot cp*kgrid/vaxis=axis2 haxis=axis4;
	plot v*kgrid/vaxis=axis3 haxis=axis4;
run;
symbol;
axis;

quit;
