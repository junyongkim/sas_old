/*************************************************
200907format
customs asterisk parenthesis formats
*************************************************/
proc format;
	picture asterisk
		(fuzz=0 round)									/*exact match*/
		low-<0		=	"LOW "							/*-infinity*/
		0-0.01		=	"*** "							/*0 inclusive*/
		0.01<-0.05	=	"**  "
		0.05<-0.1	=	"*   "
		0.1<-1		=	"    "
		1<-high		=	"HIGH";							/*+infinity*/
	picture parenthesis
		(fuzz=0 round)									/*exact match*/
		low--99.995		=	"NEGATIVE"
		-99.995<-0		=	"0009.00)"	(prefix="(-")	/*minimum -99.99*/
		0-<999.995		=	"0009.00)"	(prefix="(")	/*maximum 999.99*/
		999.995-high	=	"POSITIVE";
run;
