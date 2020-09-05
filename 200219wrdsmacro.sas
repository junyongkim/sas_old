/*------------------------------------------------
200219wrdsmacro
enables sas macros by wrds
------------------------------------------------*/
%macro wrdsmacro(code=);

filename code url "https://wrds-www.wharton.upenn.edu/pages/support/research-wrds/macros/&code/";

data _null_;
	infile code truncover;
	input code $32767.;
	code=htmldecode(code);
	if count(code,"<code") then i+1;
	if count(code,"<code") then code=scan(code,4,">");
	if count(lag(code),"/code") then i+-1;
	if count(code,"/code") then code=scan(code,1,"<");
	file "%sysfunc(getoption(work))\code";
	if i then put code;
run;

%include "%sysfunc(getoption(work))\code";

%mend;

%wrdsmacro(code=wrds-macros-winsorize)
/*%wrdsmacro(code=wrds-macros-return-gap)*/
/*%wrdsmacro(code=wrds-macros-cvccmlnksas)*/
%wrdsmacro(code=wrds-macros-betas)
%wrdsmacro(code=wrds-macro-nwords)
%wrdsmacro(code=wrds-macro-idvol)
%wrdsmacro(code=wrds-macro-populate)
/*%wrdsmacro(code=wrds-program-taq6sas)*/
%wrdsmacro(code=wrds-macro-indclass)
%wrdsmacro(code=wrds-macro-crspmerge)
%wrdsmacro(code=wrds-macro-fm)
%wrdsmacro(code=wrds-macro-trade_date_windows)
%wrdsmacro(code=wrds-macro-oclink)
%wrdsmacro(code=wrds-macro-iclink)
%wrdsmacro(code=wrds-macro-tclink)
%wrdsmacro(code=wrds-macros-ffi48)
/*%wrdsmacro(code=wrds-macro-merge_funda_crsp_bycusipsas)*/
%wrdsmacro(code=wrds-macro-paraparse)
%wrdsmacro(code=wrds-macro-ccm)
%wrdsmacro(code=wrds-macro-lineparaparse)
/*%wrdsmacro(code=rrloop-rolling-regresson-macro)*/
/*%wrdsmacro(code=wrds-macros-ccm_lnktablesas)*/
%wrdsmacro(code=wrds-macro-compound)
/*%wrdsmacro(code=taq_event_windows)*/
/*%wrdsmacro(code=wrds-program-taq_daily_variablessas)*/
%wrdsmacro(code=wrds-macro-quarterize)
%wrdsmacro(code=wrds-macro-indratios)
%wrdsmacro(code=wrds-macros-evtstudy)
/*%wrdsmacro(code=macros-portfolios-size)*/
%wrdsmacro(code=wrds-macros-run-event-study)
/*%wrdsmacro(code=wrds-macros-market-book-ratios)*/
/*%wrdsmacro(code=wrds-macros-option-pricing-models)*/
/*%wrdsmacro(code=wrds-macros-momentum-strategiesportfolios)*/
%wrdsmacro(code=wrds-marcos-csv)
%wrdsmacro(code=wrds-macros-make-dummies)
%wrdsmacro(code=wrds-macros-neut)
%wrdsmacro(code=wrds-macros-textparse)
%wrdsmacro(code=wrds-macros-vw_avgprice)
/*%wrdsmacro(code=wrds-macro-trace)*/
