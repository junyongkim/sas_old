resetline;
option linesize=128 pagesize=max;
goption xpixels=640 ypixels=480 border;

proc iml;
	beta=0.95;
	a=1;
	alpha=0.33;
	delta=0.1;
	kstar=((1/beta-(1-delta))/(a*alpha))**(1/(alpha-1));
	kmin=0.25*kstar;
	kmax=1.75*kstar;
	n=100;
	do i=1 to n;
		if i=1 then kgrid=kmin;
		else kgrid=kgrid//(kmin+(i-1)/(n-1)*(kmax-kmin));
	end;
	k1=kgrid+(kstar-kgrid)/2;
	tol=1e-12;
	maxits=300;
	dif=1e+6;
	its=0;
	result=kgrid||k1;
	start bell(k) global(kgrid,c,v,a,k0,alpha,delta,beta);
		klo=max(sum(k>kgrid),1);
		if klo=nrow(kgrid) then klo=klo-1;
		khi=klo+1;
		cc=c[klo]+(c[khi]-c[klo])/(kgrid[khi]-kgrid[klo])*(k-kgrid[klo]);
		uu=log(cc);
		v0=uu/(1-beta);
		c0=a*k0**alpha+(1-delta)*k0-k;
		goal=log(c0)+beta*v0;
		return(goal);
	finish bell;
	do while(dif>tol&its<maxits);
		c=j(n,1);
		u=j(n,1);
		v=j(n,1);
		do i=1 to n;
			c[i]=a*kgrid[i]**alpha+(1-delta)*kgrid[i]-k1[i];
			if its=0 then c[i]=max(c[i],1e-12);
			u[i]=log(c[i]);
			v[i]=u[i]/(1-beta);
		end;
		do i=1 to n;
			k0=kgrid[i];
			con=j(2,1,.);
			con[1,1]=kmin;
			con[2,1]=a*k0**alpha+(1-delta)*k0-1e-12;
			call nlptr(rc,k2,"bell",k1[i],{1,0},con);
			if i=1 then k11=k2;
			else k11=k11//k2;
		end;
		dif=norm(k11-k1);
		its=its+1;
		k1=k11;
		result=result||k11;
	end;
	result=c||v||result;
	create result from result;
	append from result;
quit;

symbol i=join;
proc gplot data=result;
	plot col1*col3;
	plot col2*col3;
	plot col3*col3
		col4*col3
		col5*col3
		col6*col3
		col7*col3
		col8*col3
		col304*col3/overlay;
run;
symbol;

quit;
