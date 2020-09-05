/*************************************************
191209cochrane
estimates ols, gls, gmm, and emm using portfolios
and factors
*************************************************/

%macro cochrane(data,merge,array,rf,if,keep);

data &data.;
	merge &merge.;
	by time;
	array r(*) &array.;
	do i=1 to dim(r);
		r(i)=r(i)-&rf.;
	end;
	if &if.;
	keep &array. &keep.;
run;

proc iml;
	use &data.;
		read all var _all_ into z;
	close;
	k=%sysfunc(countw(&keep.));
	n=ncol(z)-k;
	t=nrow(z);
	r=z[,1:n];
	rm=mean(r)`;
	rv=cov(r)*(t-1)/t;
	f=z[,n+1:n+k]||j(t,1);
	fm=mean(f)`;
	fv=cov(f)*(t-1)/t;
	b=inv(f`*f)*f`*r;
	a=b[k+1,]`;
	am=mean(abs(a));
	an=a`*inv(diag(rv))*a;
	u=r-f*b;
	br=mean(1-var(u)`/var(r)`);
	s=cov(u)*(t-1)/t;
	grs=(t-n-k)/n*a`*inv(s)*a/(1+fm`*ginv(fv)*fm);
	grsp=1-cdf("f",grs,n,t-n-k);
	b=b[1:k,]`||j(n,1);
	o=inv(b`*b)*b`*rm;
	ov=(inv(b`*b)*b`*s*b*inv(b`*b)*(1+o`*ginv(fv)*o)+fv)/t;
	ot=o/sqrt(vecdiag(ov));
	ou=hdir(f,u)||r-o`*b`;
	oa=block(i(n*(k+1)),b`);
	od=-block(f`*f/t@i(n),b);
	od[n*(k+1)+1:n*(k+2),1:n*k]=-o[1:k]`@i(n);
	os=ou`*ou/t+(ou[1:t-1,]`*ou[2:t,]+ou[2:t,]`*ou[1:t-1,])/t/2;
	ow=inv(oa*od)*oa*os*oa`*inv(oa*od)`/t;
	oz=o/sqrt(vecdiag(ow)[n*(k+1)+1:(n+1)*(k+1)]);
	c=rm-b*o;
	cm=mean(abs(c));
	cn=c`*inv(diag(rv))*c;
	cv=(i(n)-b*inv(b`*b)*b`)*s*(i(n)-b*inv(b`*b)*b`)*(1+o`*ginv(fv)*o)/t;
	cc=c`*ginv(cv)*c;
	cp=1-cdf("chisq",cc,n-k);
	cw=(i(n*(k+2))-od*inv(oa*od)*oa)*os*(i(n*(k+2))-od*inv(oa*od)*oa)`/t;
	cd=mean(ou)*ginv(cw)*mean(ou)`;
	cq=1-cdf("chisq",cd,n-k-1);
	or=1-var(c)/var(rm);
	g=inv(b`*inv(s)*b)*b`*inv(s)*rm;
	gv=(inv(b`*inv(s)*b)*(1+g`*ginv(fv)*g)+fv)/t;
	gt=g/sqrt(vecdiag(gv));
	gu=hdir(f,u)||r-g`*b`;
	ga=block(i(n*(k+1)),b`*inv(s));
	gd=-block(f`*f/t@i(n),inv(s)*b);
	gd[n*(k+1)+1:n*(k+2),1:n*k]=-g[1:k]`@i(n);
	gs=gu`*gu/t+(gu[1:t-1,]`*gu[2:t,]+gu[2:t,]`*gu[1:t-1,])/t/2;
	gw=inv(ga*gd)*ga*gs*ga`*inv(ga*gd)`/t;
	gz=g/sqrt(vecdiag(gw)[n*(k+1)+1:(n+1)*(k+1)]);
	gc=rm-b*g;
	d=rm-b*g;
	dm=mean(abs(d));
	dn=d`*inv(diag(rv))*d;
	dv=(s-b*inv(b`*inv(s)*b)*b`)*(1+g`*ginv(fv)*g)/t;
	dc=d`*ginv(dv)*d;
	dp=1-cdf("chisq",dc,n-k);
	dw=(i(n*(k+2))-gd*inv(ga*gd)*ga)*gs*(i(n*(k+2))-gd*inv(ga*gd)*ga)`/t;
	dd=mean(gu)*ginv(dw)*mean(gu)`;
	dq=1-cdf("chisq",dd,n-k-1);
	gr=inv(j(1,n)*inv(s)*j(n,1))*j(1,n)*inv(s)*rm;
	gr=rm-gr;
	gr=1-d`*inv(rv)*d/(gr`*inv(rv)*gr);
	r=r/100;
	rm=rm/100;
	f=f[,1:k]/100;
	hd=r`*f/t;
	hw=inv(r`*r/t);
	hb=inv(hd`*hw*hd)*hd`*hw*rm;
	hu=-hdir(1-f*hb,r);
	hs=hu`*hu/t+(hu[1:t-1,]`*hu[2:t,]+hu[2:t,]`*hu[1:t-1,])/t/2;
	hv=inv(hd`*hw*hd)*hd`*hw*hs*hw*hd*inv(hd`*hw*hd)/t;
	ht=hb/sqrt(vecdiag(hv));
	hj=sqrt(mean(hu)*hw*mean(hu)`);
	hjp=root(hs)*root(hw)`*(i(n)-root(hw)*hd*inv(hd`*hw*hd)*hd`*root(hw)`)*root(hw)*root(hs)`;
	call randseed(1);
	hjp=mean(randfun(5000||n-k,"chisq",1)*eigval(hjp)[1:n-k]>t*hj**2);
	eb=inv(hd`*inv(hs)*hd)*hd`*inv(hs)*rm;
	eu=-hdir(1-f*eb,r);
	ev=inv(hd`*inv(hs)*hd)/t;
	et=eb/sqrt(vecdiag(ev));
	sh=t*mean(eu)*inv(hs)*mean(eu)`;
	shp=1-cdf("chisq",sh,n-k);
	y=shape(o||ot||oz,1)`//
		shape(g||gt||gz,1)`//
		shape(hb||ht,1)`//
		shape(eb||et,1)`//
		grs//grsp//
		cc//cp//cd//cq//
		dc//dp//dd//dq//
		hj//hjp//
		sh//shp//
		br//am//an//
		or//cm//cn//
		gr//dm//dn;
	create &data.(rename=(col1=&data.)) from y;
		append from y;
	close;
quit;

%mend;
