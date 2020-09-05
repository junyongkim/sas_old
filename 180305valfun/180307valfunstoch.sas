resetline;
option linesize=128 pagesize=max;
goption xpixels=640 ypixels=480 border;

proc iml;
	sigma=2;
	beta=0.95;
	delta=0.1;
	alpha=0.33;
	kstar=(alpha/(1/beta-(1-delta)))**(1/(1-alpha));
	n=100;
	kmin=0.25*kstar;
	kmax=1.75*kstar;
	do i=1 to n;
		if i=1 then kmat=kmin;
		else kmat=kmat//(kmat[i-1]+(kmax-kmin)/(n-1));
	end;
	v0=j(n,3,0);
	v1=j(n,3,.);
	k11=j(n,3,.);
	c1=j(n,3,.);
	tol=0.01;
	maxits=300;
	dif=9e+9;
	its=0;
	amat={1.1,1.0,0.9};
	prob=j(3,3,1/3);
	start valfun2(k) global(kmat,n,v0,k0,alpha,delta,sigma,beta,amat,prob,j);
		klo=max(sum(k>kmat),1);
		if klo=n then klo=klo-1;
		khi=klo+1;
		gg=v0[klo,]+(k-kmat[klo])*(v0[khi,]-v0[klo,])/(kmat[khi]-kmat[klo]);
		c=amat[j]*k0**alpha-k+(1-delta)*k0;
		if c<=0 then val=-888888-888*abs(c);
		else val=(1/(1-sigma))*(c**(1-sigma)-1)+beta*gg*prob[j,]`;
		return (val);
	finish valfun2;
	do while(dif>tol&its<maxits);
		do j=1 to 3;
			do i=1 to n;
				k0=kmat[i];
				opt={1,0};
				con=kmin//kmax;
				call nlpqn(rc,k1,"valfun2",k0,opt,con);
				v1[i,j]=valfun2(k1);
				k11[i,j]=k1;
				c1[i,j]=amat[j]*k0**alpha-k1+(1-delta)*k0;
			end;
		end;
		dif=norm(v1-v0);
		v0=v1;
		its=its+1;
	end;
	valfun=kmat||v0||k11||c1;
	create valfun(rename=(col1=k
		col2=v1
		col3=v2
		col4=v3
		col5=k11
		col6=k12
		col7=k13
		col8=c1
		col9=c2
		col10=c3)) from valfun;
	append from valfun;
quit;

symbol i=join;
proc gplot data=valfun;
	plot v1*k v2*k v3*k/overlay;
	plot k11*k k12*k k13*k k*k/overlay;
	plot c1*k c2*k c3*k/overlay;
run;
symbol;

quit;
