%FDEP	to show a function's dependencies
%
%	FDEP dissects a MATLAB (ML) file and iteratively looks for
%	all user defined functions (modules), which are used
%	during runtime
%
%	FDEP retrieves for each module its
%		- subfunctions
%		- nested functions
%		- anonymous functions
%		- number of calls to f/eval constructs
%	   and all
%		- ML stock functions
%		- ML built-in functions
%		- ML classes
%		- ML toolboxes
%	   that it uses
%
%	runtime options and returned macros create user-friendly,
%	comprehensible, and interactive GUIs, which
%		- list the results in various panels
%		- plot a full dependency matrix
%
%	in essence, FDEP is a wrapper for DEPFUN and MLINT;
%	however, due to an efficient pruning engine
%	it is considerably faster
%
%	see also: depfun, depdir, ckdepfun, mlint, which
%		  and the accompanying HTML file
%
%SYNTAX
%-------------------------------------------------------------------------------
%		P = FDEP(FNAM);
%		P = FDEP(FNAM,OPT1,OPT2,...);
%
%INPUT
%-------------------------------------------------------------------------------
% FNAM	:	M-file (function or script) or P-file
%		- only ML entities can be extracted from
%		  standalone P-files, which do NOT have a
%		  corresponding M-file
%
% OPT	:	description
% --------------------------------------------
% -q	:	do NOT show runtime processing
% -l	:	show module list
% -m	:	show dependency matrix
%
%OUTPUT
%-------------------------------------------------------------------------------
% P		a structure, which returns all information from the lex parser;
%		fields, which are of common interest, are these macros
%
% P.macro()		call macro with default args
% P.macro(arg,...)	call macro with arguments arg1,...
%
%		arg	description
%		--------------------------------------------------------
%  .list	()	create the GUI that lists the results
%		M	- activate module M
%  .help	()	show help for the listing panels in a window
%		1	- show help in the command window
%  .plot	()	create the GUI that shows the dependency matrix
%		N1,...	- show nodes N1,...
%			  numeric input syntax ([M#column/M#row],...)
%			  only valid nodes are shown with guiding lines
%  .find	M1,...	show the synopsis of modules M1,...
%  .get		M1,...	retrieve all data of modules M1,...
%  .mhelp	M1,...	show all data of module M1,... in a window
%
%		Mx	may be numeric or the name of an existing module
%
%		for more help, see the accompanying HTML file
%
%EXAMPLE
%-------------------------------------------------------------------------------
%		p=fdep('myfile');
%		p.list();		% show module list
%		p.plot();		% show dependency matrix
%		p.find(2);		% show synopsis of module #2
%		d=p.get('foo');		% retrieve data of module <foo>

% for software developers
%
%		mn=2;				% module number
% access module data
%		p.fun(mn)			% module name
%		p.fun(p.mix{mn})		% calls	TO
%		p.fun(p.cix{mn})		% calls	FROM
% access ML data
%		fn=1				% stock	function group
%		p.mlfun{fn}(p.mlix{sn,fn})

% created:
%	us	07-Mar-2006
% modified:
%	us	14-Nov-2007 13:16:06	/ FEX R2007a

%-------------------------------------------------------------------------------
function	po=fdep(varargin)

		magic='FDEP';
		ver='14-Nov-2007 13:16:06';
		dopt={
			'-toponly'
			'-quiet'
		};
		mopt={
			'-m3'
			'-calls'
		};

	if	nargout
		po=[];
	end
	if	~nargin
		help(mfilename);
		return;
	end

		[p,par]=ini_engine(ver,magic,dopt,mopt,varargin{:});
	if	isempty(p)
		return;
	end

		tim=clock;
		[p,par]=get_dep(p,par,p.fun{1});
		p.runtime(1)=etime(clock,tim);

		tim=clock;
		p=ini_engine(p,par);
		p.runtime(2)=etime(clock,tim);

% needed to make sure all macros contain the latest parameters!
		p=flib(magic,p,2);
	if	par.opt.lflg
		p=p.list();
		p=flib(magic,p,1);			% needed!
	end
	if	par.opt.mflg
		p=p.plot();
		p=flib(magic,p,1);			% needed
	end
	if	~p.ncall				&&...
		~par.opt.qflg
		disp(sprintf('-------------  NO USER-DEFINED DEPENDENCIES FOUND'));
		p.find(1);
	end
	if	nargout
		po=p;
	end
end
%-------------------------------------------------------------------------------
function	[p,par]=ini_engine(ver,magic,dopt,mopt,varargin)

% output parameters
% - description	TIX		0			1
%---------------------------------------------------------------
%		calls to	no			yes
%		recursive	no			yes
%		evals		no			yes
%		type		script			function
%
% - description .SUB().n
%---------------------------------------------------------------
%		1		functions outside the scope
%		2		subfunctions
%		3		nested functions
%		4		anonymous functions
%		5		user defined functions
%		6		ML stock functions
%		7		ML built-in functions
%		8		calls to eval..
%		9		ML classes
%		10		other classes
%		11		ML tbx
%
% - description .CALL{x,n}
%---------------------------------------------------------------
%		1		user defined functions
%		2		ML stock functions
%		3		ML built-in functions
%		4		ML classes
%		5		other classes
%		6		ML tbx

	if	nargin > 2

		p=[];
		par=[];
		fnam=varargin{1};
		fnam=which(fnam);
	if	~exist(fnam,'file')
		disp(sprintf('%s> invalid file <%s> = %s',magic,varargin{1},fnam));
		return;
	end
	if	isempty(fnam)
		disp(sprintf('%s> file not found <%s>',magic,varargin{1}));
		return;
	end
		[fpat,frot]=fileparts(fnam);

% simple option parser
		opt.qflg=false;
		opt.lflg=false;
		opt.mflg=false;
	if	nargin > 4
	for	i=1:numel(varargin)
	switch	varargin{i}
	case	'-q'
		opt.qflg=true;
	case	'-l'
		opt.lflg=true;
	case	'-m'
		opt.mflg=true;
	end
	end
	end

% engine parameters
		par.mlroot=[matlabroot,filesep,'toolbox'];
		par.opt=opt;
		par.dopt=dopt;
		par.mopt=mopt;
		par.x=0;				% loop
		par.xx=1;				% entry
		par.c=0;
		par.e=0;
		par.fix=[];
		par.spec=[0,0,0,0];
		par.dspec='RESP';
		par.ac={sprintf('%-4d: * %s',0,frot)};
		par.am={fnam};
		par.nn=11;
		par.nc=6;
		par.call=cell(1,6);
		par.call(1,1)={fnam};

		par.rexcls='^\w';			% module class
		par.rexmod='\w+$';			% module
		par.rexmod='(\w+$)|(\d+$)';
		par.rextbx='\w+';			% find toolboxes
		par.rexmbi='(?<=\().+(?=\))';		% full path to built-in
		par.rexscr='(?<=\\)\w+(?=\.m$)';	% file roots

		par.fdes={'FUNCTION','SCRIPT'};
		par.rdes={'no','yes'};
		par.edes={'not used','used','not known'};

		par.htag=@(t) sprintf('FDEP.list.help.%s',t.module{1});
		par.ltag=@(t) sprintf('FDEP.module.list.%s',t.module{1});
		par.ptag=@(t) sprintf('FDEP.dependency.matrix.%s',t.module{1});
		par.mtag=@(t) sprintf('FDEP.module.synopsis.%s',t);

		par.ixbi=5;

%{
	original color scheme
		par.mcol=[.75,1,1];			% color: modules
		par.fcol=[1,1,.75];			% color: module
		par.pcol=[.85,1,.85];			% color: main pg
%}
%	john d'errico adjustment
		par.mcol=[.85,1,1];			% color: modules
		par.fcol=[1,1,.85];			% color: module
		par.pcol=[.95,1,.95];			% color: main pg
		par.tcol=[0,0,1];			% color: text

		ss=get(0,'screensize');
		par.lwin=[.3*ss(3),100,.7*ss(3)-20,ss(4)-160];
		par.hwin=[10,50,.5*ss(3)-20,ss(4)-80];

% macros
		par.range=@(x) max(x)-min(x);	% replacement for <stats tbx>
% - descriptor: module
		par.mktxtm=@(a,b,ix) {
		sprintf('M-FILE       : %s',a.sub(ix).m)
		sprintf('P-FILE       : %s',a.sub(ix).p)
		sprintf('MODULE   %4d: %s',ix,a.module{ix})
		sprintf('type         : %s',b.fdes{a.tix(ix,4)+1})
		sprintf('created      : %s',b.date)
		sprintf('size         : %-1d bytes',b.size)
		sprintf('lines        : %-1d',a.sub(ix).l)
		sprintf('recursive    : %s',b.rdes{a.tix(ix,2)+1})
		sprintf('f/eval..     : %s',b.edes{a.tix(ix,3)+2*max([0,(a.tix(ix,5)-a.sub(ix).mp(1))])+1})
		sprintf('calls    TO  : %5d  user defined',numel(a.mix{ix}))
		sprintf('called   FROM: %5d  user defined',numel(a.cix{ix}))
		sprintf('calls in FILE: %5d',a.sub(ix).n(1))
		sprintf('subfunctions : %5d  inside  file',a.sub(ix).n(2))
		sprintf('nested       : %5d',a.sub(ix).n(3))
		sprintf('anonymous    : %5d',a.sub(ix).n(4))
		sprintf('f/eval..     : %5d',a.sub(ix).n(8))
		sprintf('ML      stock: %5d',numel(a.mlix{ix,1}))
		sprintf('ML  built-ins: %5d',numel(a.mlix{ix,2}))
		sprintf('ML    classes: %5d',numel(a.mlix{ix,3}))
		sprintf('OTHER classes: %5d',numel(a.mlix{ix,4}))
		sprintf('ML  toolboxes: %5d',numel(a.mlix{ix,5}))
		};

% - descriptor: main program
		par.mktxtf=@(a,b,ix) {
		sprintf('ROOT         : %s',a.module{1})
		sprintf('type         : %s',b.fdes{a.tix(1,4)+1})
		sprintf('recursive    : %s',b.rdes{a.tix(1,2)+1})
		sprintf('f/eval..     : %s',b.edes{a.tix(1,3)+2*max([0,(a.tix(1,5)-a.sub(1).mp(1))])+1})
		sprintf('FDEP  version: %s',a.FDEPver);
		sprintf('ML    version: %s',a.MLver)
		sprintf('ML      stock: %5d',a.nmlcall(1))
		sprintf('ML  built-ins: %5d',a.nmlcall(2))
		sprintf('ML    classes: %5d',a.nmlcall(3))
		sprintf('OTHER classes: %5d',a.nmlcall(4))
		sprintf('ML  toolboxes: %5d',numel(a.mlfun{5}))
		sprintf('runtime      : %10.4f sec',sum(a.runtime(1)));
		};

% templates
		par.ftmpl='M0';
		par.stmpl={
			'U'	3	false	@(x) regexp(x,par.rexmod,'match')
			'S'	3	true	@(x) regexp(x,par.rexmod,'match')
			'N'	3	true	@(x) regexp(x,par.rexmod,'match')
			'A'	[1,4]	true	''
		};
		par.stmpla.m=[];
		par.stmpla.p=[];
		par.stmpla.mp=[];
		par.stmpla.l=0;
		par.stmpla.n=[];
		par.stmpla.U.fn={''};
		par.stmpla.S.fn={''};
		par.stmpla.N.fn={''};
		par.stmpla.A.fn={''};

		par.mlfield={
			'MLfunction'
			'MLbuiltin'
			'MLclass'
			'OTHERclass'
			'MLtoolbox'
		};

		par.sn={
			'module'	false
			'fun'		false
			'sub'		false
			'mix'		true
			'cix'		true
			'mlix'		false
			'tix'		false
			'depth'		false
		};

		p.magic=magic;
		p.([magic,'ver'])=ver;
		p.MLver=version;
		p.rundate=datestr(clock);
		p.runtime=[0,0];
		p.par=[];
		p.file=fnam;
		p.ncall=0;
		p.nfun=0;
% user defined functions
		p.module={frot};
		p.fun={fnam};
		p.froot={[fpat,filesep,frot]};
		p.sub=par.stmpla;

		p.mix={};			% calls to
		p.cix={};			% called from
		p.mlix={};			% system calls
		p.tix=[];			% function type
		p.depth=[0,0];

% ML defined functions
		p.nmlcall=[0,0,0,0,0];
		p.mlfun=cell(1,5);
		p.tree={};
		p.rtree={};
		p.caller=[];
		p.mat=int8([]);
		p.lib=[];

	else
		p=ver;
		par=magic;

		p.nfun=numel(p.fun);

		ml=max(cellfun('length',par.ac));
		cm=[num2cell(1:numel(par.ac));par.ac.';par.am.'];
		fmt=sprintf('%%4d: %%-%ds -> %%s\n',ml+2);
		p.tree=sprintf(fmt,cm{:});
		p.tree=strread(p.tree,'%s','delimiter','','whitespace','');

		p.rtree=[char(p.rtree(:,1)),repmat('   ',size(p.rtree,1),1),char(p.rtree(:,2))];
	
		t=strrep(p.mlfun{1},[matlabroot,filesep,'toolbox',filesep],'');
		p.mlfun{5}=unique(regexp(t,par.rextbx,'match','once'));

		p.cix=cell(p.nfun,1);
		p.mlix=cell(p.nfun,5);

	for	i=1:p.nfun
		ix=ismember(p.fun,par.call{i,1});
		ix=par.fix(ix);
		p.mix{i,1}=ix.';
		p.cix(ix,1)=cellfun(@(x) [x,i],p.cix(ix,1),'uni',false);
	for	j=1:5
		ix=ismember(p.mlfun{j},par.call{i,j+1});
		p.mlix{i,j}=find(ix);
		p.nmlcall(j)=numel(ix);
	end
	end
		p=fsort(p,par);
		p=cmp_depmat(p);

	end
end
%-------------------------------------------------------------------------------
function	[p,par]=flib(magic,p,nr)

% retrieve latest parameter set
		[par,par]=ini_engine([],[],[],[],p.file);
		p.par=par;
% assign FDEP functions
% - do NOT change this tedious assingment!
% - requires a lot of time!
	for	i=1:nr
		p.lib=@()		flib(magic,p,2);
		p.help=@(varargin)	fdephelp(mfilename,p,'p',varargin{:});
		p.get=@(varargin)	dget(magic,p,varargin{:});
		p.find=@(varargin)	dfind(magic,p,true,varargin{:});
		p.list=@(varargin)	dlist(magic,p,varargin{:});
		p.plot=@(varargin)	dplot(magic,p,varargin{:});
		p.mhelp=@(varargin)	mhelp(magic,p,varargin{:});
	if	~isfield(p,'smod')
		p.smod=[];
	end
	end
end
%-------------------------------------------------------------------------------
function	[p,par]=get_dep(p,par,fnam)

		par.x=par.x+1;
		par.c=par.c+1;

		fnam=which(fnam);
		[fpat,frot]=fileparts(fnam);
		[p,par,dtmp,dmlf,dmod,dmcl,docl]=get_fun(p,par,fnam,frot);
		wtmp=dtmp;

		mltbx=strrep(dmlf,[matlabroot,filesep,'toolbox',filesep],'');
		mltbx=unique(regexp(mltbx,par.rextbx,'match','once'));
		par.call(par.xx,:)={dtmp(2:end),dmlf,dmod,dmcl,docl,mltbx};

	if	par.x > 1
		p.mlfun={
			unique([p.mlfun{1};dmlf])
			unique([p.mlfun{2};dmod])
			unique([p.mlfun{3};dmcl])
			unique([p.mlfun{4};docl])
			mltbx
		};
	else
		p.mlfun=par.call(1,2:end).';
	end

		tmpd=cellfun(@(x) x(1:find(x=='.',1,'last')-1),dtmp,'uni',false);
		ix=ismember(tmpd,p.froot);
		dtmp(ix)=[];
		ndtmp=numel(dtmp)-1;
		p.ncall=p.ncall+ndtmp+1;

	if	numel(dtmp) < 2
		m={'()'};
	else
		m=dtmp(2:end);
	end
		c=repmat({
			sprintf('%-4d: %s| %s',...
				par.x,repmat(' ',1,2*(par.c-1)),frot)
			},...
			numel(m),1);
		par.ac=[par.ac;c];
		par.am=[par.am;m];

		p.tix(par.x,:)=[1,par.spec];
	if	~numel(dtmp)
		ix=ismember(p.fun,wtmp(2:end));
		ofix='';
		p.tix(par.x,1)=0;
	if	any(ix)
		p.tix(par.x,1)=1;
		ofix=par.fix(ix);
		ofix=sprintf('%-1d ',ofix);
		ofix(end)='';
	end
		fnum=numel(find(ix));
		[p,par]=show_entry(p,par,frot,fnum,ofix);
	else

		keep=par.c;
		par.e=keep;
	for	i=1:numel(dtmp)
		[dpat,drot]=fileparts(dtmp{i});
		tmpd=[dpat,filesep,drot];
		ix=ismember(tmpd,p.froot);
	if	isempty(find(ix,1))
		p.fun=[p.fun;dtmp{i}];
		p.froot=[p.froot;{tmpd}];
		p.module=[p.module;{drot}];
	if	i == 1
		[p,par]=show_entry(p,par,frot,1,dtmp{i});
	end
		[p,par]=get_dep(p,par,dtmp{i});
	end
		par.e=keep;

	end
	end
		par.c=par.c-1;
end
%-------------------------------------------------------------------------------
function	[p,par,dtmp,dmlf,dmod,dmcl,docl]=get_fun(p,par,fnam,frot)

		par.spec=[0,0,0,0];

		[dtmp,dmod,dmcl,docx,docx,docx,docx,docl]=depfun(fnam,par.dopt{:});
		im=strmatch(par.mlroot,dtmp);
		dmlf=dtmp(im);
		dtmp(im)=[];

		[fa,fap]=farg(fnam,'-s','-d');

		dtmp{1}=fap.wnam;
	if	fap.mp(1)
		p.fun{end}=fap.wnam;
		dtmp{1}=fap.wnam;
	elseif	fap.mp(2)
		p.fun{end}=fap.pnam;
		dtmp{1}=fap.pnam;
	else
		p.fun{end}=fap.wnam;
	end

		ex=cellfun(@exist,fap.U.fn);
		dmod=unique([dmod;fap.U.fn(ex==par.ixbi)]);
		par.spec(4)=+fap.mp(2);
		p.sub(par.xx,1)=par.stmpla;
		p.sub(par.xx,1).m=fap.wnam;
		p.sub(par.xx,1).p=fap.pnam;
		p.sub(par.xx,1).mp=fap.mp;
		p.sub(par.xx,1).l=fap.par.nlen;
		p.sub(par.xx,1).n=zeros(1,par.nn);
		p.sub(par.xx,1).n(1,size(par.stmpl,1)+1:end)=...
			[numel(dtmp)-1,numel(im),numel(dmod),0,numel(dmcl),numel(docl),0];

		if	isempty(fa)
		[fext,fext,fext]=fileparts(fnam);
	if	strcmp(fext,fap.par.pext)
		p.sub(par.xx,1).l=nan;
		p.sub(par.xx,1).n([1,8])=nan;
	end
	if	~isempty(docx{1})
		par.spec(1)=1;
	end
		return;
	end
		p.sub(par.xx,1).n(1:numel(fap.n)-1)=fap.n([5,2:4]);

	if	~fap.par.nlen
		par.spec(3)=1;
		dmlf={};
		dmod={};
		dmcl={};
		docl={};
		return;
	end

	for	i=1:size(par.stmpl,1)
		fn=par.stmpl{i,1};
		p.sub(par.xx,1).(fn)=fap.(fn);
	end
		p.sub(par.xx,1).S.fn=fap.sub;
	if	fap.M.nx
		p.sub(par.xx,1).S.fd=[fap.M.fn;fap.S.fn];
		p.sub(par.xx,1).n(2)=p.sub(par.xx,1).n(2)+1;
		p.sub(par.xx,1).S.nx=p.sub(par.xx,1).S.nx+1;
		p.sub(par.xx,1).S.bx=[fap.M.bx,p.sub(par.xx,1).S.bx];
	end

	if	~fap.par.mfun
		par.spec(3)=1;
	end

		c=fap.par.call;
		sx=strmatch(par.stmpl{1,1},c);
		c=c(sx);
		f=regexp(c,par.rexmod,'match');
		f=[f{:}].';

		ir=strmatch(frot,f,'exact');
	if	numel(ir)
		f(ir)=[];
		par.spec(1)=1;
	end
		ir=[
			strmatch('eval',fap.par.ltok(:,2))
			strmatch('feval',fap.par.ltok(:,2))
		];
	if	numel(ir)
		par.spec(2)=1;
		p.sub(par.xx,1).n(8)=numel(ir);
	end

% SCRIPT
	if	par.spec(3)
		f=[frot;f];
		m=regexp(dtmp,par.rexscr,'match');
		m=[m{:}].';
		ix=ismember(m,f);
		dtmp=dtmp(ix);
	end
end
%-------------------------------------------------------------------------------
function	p=cmp_depmat(p)

		tix=(p.tix(:,1)~=0 | p.tix(:,2)~=0).';
		p.caller=p.module(tix);			% functions
		nc=(1:sum(tix)).';
		p.mat=zeros(p.nfun,'int8');
	for	i=1:p.nfun
		p.mat(p.mix{i},i)=1;
	if	p.tix(i,2)
		p.mat(i,i)=-1;
	end
	end
		p.mat(:,~tix)=[];
%		p.caller=p.caller(nc);
		p.mat=p.mat(:,nc);
end
%-------------------------------------------------------------------------------
function	[p,par]=show_entry(p,par,frot,fnum,fnam)

		par.fix(par.xx,1)=par.xx;
		p.depth(par.xx,1)=par.e;
		p.depth(par.xx,2)=par.c;

		sp=repmat(' ',1,2*(par.c-1));
	if	par.e > 0				&&...
		par.e < par.c
		sp(2*(par.e)-1)='.';
	end
		spec=repmat(' ',1,numel(par.dspec));
		spec(par.spec~=0)=par.dspec(par.spec~=0);

		cc=sprintf('%-4d %-2d: %s| %s',...
			par.xx,par.c,...
			sp,...
			frot);
		cm=sprintf('%4.4s %-1d: %s',...
			spec,fnum,fnam);
		p.rtree(par.xx,:)={cc,cm};
		par.xx=par.xx+1;

	if	~par.opt.qflg
		disp([cc,sprintf('\t'),cm]);
	end
end
%-------------------------------------------------------------------------------
function	p=fsort(p,par)

		ns=size(par.sn,1);
		[ix,ix]=sort(p.module(2:end));
		ix=[1;ix+1];
		[is,is]=sort(ix);
	for	i=1:ns
		fn=par.sn{i,1};
	if	par.sn{i,2}
	for	j=1:numel(p.(fn))
		p.(fn){j}=is(p.(fn){j}).';
	end
	end
		p.(fn)=p.(fn)(ix,:);
	end

end
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
% OUTPUT utilities
%
%	- dget
%	- dfind
%	- dlist
%	- dplot
%
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
function	tf=chkpar(magic,p)

		tf=false;
	if	isstruct(p)				&&...
		isfield(p,'magic')			&&...
		strmatch(magic,p.magic)
		tf=true;
		return;
	end
		disp(sprintf('%s> not a valid FDEP structure',magic));
end
%-------------------------------------------------------------------------------
function	r=dget(magic,p,varargin)

		r=[];
	if	nargin < 3
		disp(sprintf('%s> usage: P.get(TOKEN)',magic));
	if	~nargout
		clear r;
	end
		return;
	end
		narg=numel(varargin);

	if	narg < 3
	if	~chkpar(magic,p)
	if	~nargout
		clear r;
	end
		return;
	end
		p=dfind(magic,p,false,varargin{:});
	else
		p.ix=varargin{2};
	end

	if	~isempty(p.ix)
	for	i=1:numel(p.ix)
		ix=p.ix(i);
		tix=p.tix(ix,:);
		del=repmat('-',1,max([numel(p.fun{ix}),numel(p.file)]));

	if	narg < 3
		disp(sprintf('FDEP> find module #/name:%5d = <%s>',ix,p.fun{ix}));
	end

		ac=p.sub(ix).U.fn;
% check unassigned calls
	if	~isnan(p.sub(ix).n(1))			&&...
		p.sub(ix).n(1)

		au=[p.sub(ix).S.fd;p.sub(ix).N.fn];
		fu=p.sub(ix).U.fn;
		ct=p.fun(p.mix{ix});

		mu=max(cellfun(@numel,fu));
		fmt=sprintf('%%-%d.%ds   >   %%s',mu,mu);
		ac=cell(p.sub(ix).n(1),1);
		ex=cellfun(@exist,fu);			%#ok
		rx=strcmp(p.module(ix),fu);
		ex(rx)=-1;
	for	j=1:p.sub(ix).n(1)
		cu=p.sub(ix).U.fn{j};

		ax=strcmp(cu,au);
	if	any(ax)					&&...
		ex(j) ~= -1
		ex(j)=-2;
	end

	switch	ex(j)
	case	5
		ac{j}=sprintf(fmt,cu,	'ML   built-in');
	case	{2,6}
		tc=which(cu);
	if	any(strcmp(tc,ct))
		tc=sprintf(		'CALL %s',tc);
	else
		tc=sprintf(		'ML   %s',tc);
	end
		ac{j}=sprintf(fmt,cu,tc);
	case	0
		ac{j}=sprintf(fmt,cu,	'**** NOT FOUND');
	case	-1
		ac{j}=sprintf(fmt,cu,	'---- RECURSION');
	case	-2
		ac{j}=sprintf(fmt,cu,	'---- SUBFUNCTION or NESTED FUNCTION');
	end

	end
	end

% ID
		rtmp.magic=[p.magic,'module'];
		rtmp.([magic,'ver'])=p.([magic,'ver']);
		rtmp.MLver=p.MLver;
		rtmp.rundate=p.rundate;
% module(s) contents
		rtmp.MODULE_DESCRIPTION___________=del;
		rtmp.module=p.module{ix};
		rtmp.file=p.fun{ix};
		rtmp.parent=p.file;
		rtmp.index=ix;
		rtmp.type=p.par.fdes{tix(4)+1};
		rtmp.isscript=tix(4);
		rtmp.ispfile=isnan(p.sub(ix).l);
		rtmp.isrecursive=tix(2);
		rtmp.haseval=tix(3);
		rtmp.hascalls=numel(p.fun(p.mix{ix}));
		rtmp.iscalled=numel(p.fun(p.cix{ix}));
		rtmp.MODULE_FUNCTIONS___________=del;
		rtmp.calls=ac;
		rtmp.subfunction=p.sub(ix).S.fn;
		rtmp.nested=p.sub(ix).N.fn;
		rtmp.anonymous=p.sub(ix).A.fn;
		rtmp.callsTO=p.fun(p.mix{ix});
		rtmp.callsFROM=p.fun(p.cix{ix});
		rtmp.ML_FUNCTIONS___________=del;
	for	j=1:size(p.par.mlfield,1)
		fn=p.par.mlfield{j,1};
		rtmp.(fn)=p.mlfun{j}(p.mlix{ix,j});
	end
	if	i==1
		clear r;
		r=rtmp;
		r(numel(p.ix))=rtmp;			% allocate
	else
		r(i)=rtmp;
	end
	end
	end

end
%-------------------------------------------------------------------------------
function	po=dfind(magic,p,dflg,varargin)

	if	nargin < 3
		disp(sprintf('%s> usage: P.find(TOKEN,TOKEN,...)',magic));
	if	~nargout
		clear p;
	end
		return;
	end
	if	~chkpar(magic,p)
	if	nargout
		po=p;
	end
		return;
	end

		hdr='-------------';
		srch={
			'module'	true
			'fun'		false
		};

		ic=cellfun('isclass',varargin,'cell');
		narg=numel(varargin);

		p.ix=[];
		p.rm={};
		p.rf={};

	for	i=1:narg
	if	ic(i)
		varg=varargin{i};
	else
		varg=varargin(i);
	end
		nvarg=numel(varg);

	for	j=1:nvarg
		ix=[];

		carg=varg{j};
	if	ischar(carg)
	for	k=1:size(srch,1)
		fn=srch{k,1};
	if	srch{k,2}
		ix=strmatch(carg,p.(fn),'exact');
	else
		ix=strmatch(carg,p.(fn));
	end
	if	~isempty(ix)
		break;
	end
	end

	elseif	isnumeric(carg)
		ix=carg(carg>0 & carg<=p.nfun);
	end

		p.ix=[p.ix;ix(:)];
	for	k=1:numel(ix)
		cix=ix(k);
	if	~isempty(cix)
		fdir=dir(p.fun{cix});
		p.par.date=fdir.date;
		p.par.size=fdir.bytes;
		rm=p.par.mktxtm(p,p.par,cix);
		p.rm=[p.rm;rm];
		p.rf=[p.rf;rm;{hdr}];
	if	cix == 1
		rf=p.par.mktxtf(p,p.par,cix);
		p.rf=[p.rf;rf;{hdr}];

	end
	end	% K
	end	% J
	end	% I
	end

	if	~isempty(p.ix)
		p.rm(end)=[];
		p.rf(end)=[];
	end

	if	dflg
		disp(char(p.rf));
	end

	if	nargout
		po=p;
	end
end
%-------------------------------------------------------------------------------
function	p=dlist(magic,p,varargin)

	if	~chkpar(magic,p)
		return;
	end
		par=p.par;

		mrg=.01;
		l3=1/3;					% l = <el>!
		l4=1/5-mrg/5;
		xoff=0;
		yoff=mrg;
		ylen=l4-mrg-.02;
		xle2=2*l3-mrg;
		LB='listbox';
		fs=8;
		xpos=linspace(.5,1-mrg,6);
		dx1=xpos(2)-xpos(1);
		dx2=2*dx1;
		dx2=dx2-.01*dx1;
		dx1=dx1-.01*dx1;

		ftag=p.par.ltag(p);
		fh=findall(0,'tag',ftag);
	if	isempty(fh)
		fh=figure;
	end
		ss=get(0,'screensize');
		fp=[.25*ss(3),50,.75*ss(3)-20,ss(4)-80];
		set(fh,'position',fp);
		fcol=get(fh,'color');

% macros
% - text position
			spos=@(x) [x(1:2)+[0,x(4)+.003],.75*x(3),.02];

		pos={
%		tag	position			description
%----------------------------------------------------------------------------
		'M'	[mrg,yoff+2*l4,1/3-2*mrg,1-(yoff+2*l4)-1*mrg-.02],...
			'modules'
		'F'	[xoff+l3,yoff+3*l4,xle2,ylen],...
			'calls  TO'
		'F'	[xoff+l3,yoff+2*l4,xle2,ylen],...
			'called FROM'
		'S'	[xoff+l3,yoff+1*l4,xle2,ylen],...
			'subfunctions'
		'S'	[xoff+l3,yoff+0*l4,xle2,ylen],...
			'nested / anonymous functions'
		'SM'	[mrg,yoff+1*l4,1/3-2*mrg,ylen],...
			'main function'
		'S'	[mrg,yoff+0*l4,1/3-2*mrg,ylen],...
			'toolboxes'
		'T'	[xoff+l3,yoff+4*l4,xle2,ylen],...
			'module summary'
		};
		mpos={
%----------------------------------------------------------------------------
			[xpos(5),yoff+4*l4+ylen+.0025,dx1,.025],...
			'HELP',...
			@cb_help,...
			par.pcol
			[xpos(3),yoff+4*l4+ylen+.0025,dx2,.025],...
			'DEPENDENCY MATRIX',...
			@cb_map,...
			par.mcol
			[xpos(2),yoff+4*l4+ylen+.0025,dx1,.025],...
			'EDIT',...
			@cb_edit,...
			par.fcol
			[xpos(1),yoff+4*l4+ylen+.0025,dx1,.025],...
			'JOHN D''',...
			@cb_fs,...
			par.pcol
		};

		v=num2cell(1:p.nfun).';
		tix=p.tix(:,2:5)~=0;
		des=repmat(p.par.dspec,size(tix,1),1);
		des(~tix)='.';
		des=cellstr(des);

		maxs=max(cellfun(@numel,p.module))+3;
		fmt=sprintf('%%%dd: %%-%ds %%s',fix(log10(p.nfun))+1,maxs);
		flst=cellfun(@(x,y,z) sprintf(fmt,x,y,z),v,p.module,des,'uni',false);
		flst{1}=[flst{1},'   [MAIN]'];

		np=size(pos,1);
		lh=zeros(np,1);
		th=zeros(np,1);
		uh=zeros(2,1);
	for	i=np:-1:1
			cp=pos{i,2};
		lh(i)=uicontrol(...
			'tag',pos{i,1},...
			'units','normalized',...
			'position',cp,...
			'style',LB,...
			'userdata',1);
		th(i)=uicontrol(...
			'tag',[pos{i,1},'text'],...
			'units','normalized',...
			'position',spos(cp),...
			'style','text',...
			'string',pos{i,3},...
			'horizontalalignment','left',...
			'fontname','courier new',...
			'fontsize',11,...
			'fontweight','bold',...
			'backgroundcolor',fcol);
	end
		set(lh,...
			'callback',{@cb_list,p,par,lh,lh(end)},...
			'max',1,...
			'horizontalalignment','left',...
			'fontname','courier new',...
			'fontsize',fs,...
			'backgroundcolor',par.fcol,...
			'foregroundcolor',par.tcol);
		set(lh(1),'string',flst,...
			'backgroundcolor',par.mcol);
		set(lh(6),'string',par.mktxtf(p,par));
		set(lh(7),'string',p.mlfun{5},...
			'max',2);
		set(lh(6:7),...
			'backgroundcolor',par.pcol);
		set(lh(1:3),...
			'tooltipstring','*** click an ENTRY to show its contents ***');
		set(lh(4:5),...
			'tooltipstring','*** click an ENTRY to open the module at the function ***');
		set(lh(6),...
			'tooltipstring','*** click anywhere to show the MAIN module ***');
		set(lh(8),...
			'tooltipstring','*** click the first LINE to show full module contents ***');
		set(lh(7),...
			'hittest','off');

	for	i=1:size(mpos,1)
		uh(i)=uicontrol(...
			'callback',{mpos{i,3},p,lh,LB},...
			'units','normalized',...
			'position',mpos{i,1},...
			'string',mpos{i,2},...
			'fontname','courier new',...
			'fontsize',11,...
			'fontweight','bold',...
			'backgroundcolor',mpos{i,4});
	end

		set(fh,...
			'tag',ftag,...
			'toolbar','none',...
			'menubar','none',...
			'numberTitle','off',...
			'name',['MODULE LIST:   ',...
				strrep(p.file,'\','/')],...
			'color',fcol);

		n=1;
	if	~isempty(varargin)
	if	ischar(varargin{1})
		p=dfind(magic,p,false,varargin{1});
	if	~isempty(p.ix)
		n=p.ix;
	end
	else
		n=varargin{1};
	end
	end
		cb_list(lh(1),[],p,par,lh,lh(end),n);
		shg;

	if	~nargout
		clear p;
	else
		p.smod=@(ix) cb_list(lh(1),[],p,par,lh,lh(end),ix);
	end
end
%-------------------------------------------------------------------------------
% CALLBACK functions
%	- dlist
%-------------------------------------------------------------------------------
function	cb_map(h,e,p,lh,ix)			%#ok

		dplot(p.magic,p);
end
%-------------------------------------------------------------------------------
function	cb_edit(h,e,p,lh,ix)			%#ok

		v=get(lh(1),'userdata');
		edit(p.fun{v});
end
%-------------------------------------------------------------------------------
function	cb_sedit(h,e,p,par,ix,lh)		%#ok

		ud=get(h,'userdata');
	if	isempty(ud)
		return;
	end
		v=get(h,'value');
		opentoline(p.fun{ix},ud(v));
end
%-------------------------------------------------------------------------------
function	cb_fs(h,e,p,par,ix,lh)			%#ok

		lh=findall(gcf,'style',ix);
		cfs=get(lh(1),'fontsize');
		set(lh,'fontsize',cfs+1);
end
%-------------------------------------------------------------------------------
function	cb_help(h,e,p,lh,ix)			%#ok

		fdephelp(mfilename,p,'p',false);
end
%-------------------------------------------------------------------------------
function	cb_list(h,e,p,par,lh,lht,v)		%#ok

	if	~all(ishandle([h;lh;lht]))
		disp(sprintf('%s> handles invalid',p.magic));
		return;
	end
	if	nargin < 7
		v=get(h,'value');
	elseif	v <= 0					||...
		v > p.nfun
		disp(sprintf('%s> index out of range: %-1d [1:%-1d]',...
			p.magic,v,p.nfun));
		return;
	end
		t=get(h,'tag');
	if	isempty(v)				||...
		numel(v) > 1
		return;
	end
	switch	t
	case	'M'
	case	'F'
		s=cellstr(get(h,'string'));
	if	v <= 0 || v > numel(s)
		disp(sprintf('ERROR %5d',v));
		disp(s);
		return;
	end
		v=strmatch(s(v),p.fun,'exact');
	if	isempty(v);
		return;
	end
	case	'SM'
		v=1;
	case	'TB'
	case	'T'
		s=get(h,'string');
		m=get(lh(1),'value');
	if	v == 1
		fdephelp(mfilename,p,'m',true,m,s);
	end
		return;
	otherwise
		return;
	end

		set([lh(4:5);lht],...
			'userdata',[],...
			'string','');
		set(lh(2:end),'value',1);
		set(lh(1),'value',v);
		set(lht,'listboxtop',1);

		set(lh(2),'string',p.fun(p.mix{v}));
		set(lh(3),'string',p.fun(p.cix{v}));
	if	p.sub(v).n(2)
		tmpt=cellfun(@(x,y) sprintf('S(%5d): %s',y,x),p.sub(v).S.fn,num2cell(p.sub(v).S.bx(1,:)).','uni',false);
		tmpt{1}(1)='M';
		set(lh(4),...
			'userdata',p.sub(v).S.bx(1,:).',...
			'string',tmpt);
	end
		txtn={''};
		ln=[];
	if	p.sub(v).n(3)
		txtn=cellfun(@(x,y) sprintf('N(%5d): %s',y,x),p.sub(v).N.fn,num2cell(p.sub(v).N.bx(1,:)).','uni',false);
		ln=p.sub(v).N.bx(1,:).';
	end
	if	p.sub(v).n(4)
		tmpt=cellfun(@(x,y) sprintf('A(%5d): %s',y,x),p.sub(v).A.fn,num2cell(p.sub(v).A.bx(1,:)).','uni',false);
		txtn=[txtn;tmpt];
		ln=[ln;p.sub(v).A.bx(1,:).'];		%#ok
	end
	if	isempty(txtn{1})
		txtn=txtn(2:end);
	end
	if	numel(txtn)
		[ln,lnx]=sort(ln);
		set(lh(5),...
			'userdata',ln,...
			'string',txtn(lnx));
	end
		set(lh(4:5),...
			'callback',{@cb_sedit,p,par,v,lh}');

		set(lh(7),'value',p.mlix{v,5});

		fdir=dir(p.fun{v});
		par.date=fdir.date;
		par.size=fdir.bytes;
		txt=par.mktxtm(p,par,v);
		set(lht,'string',txt);
		set(lh(1),'userdata',v);

%{
	TEST	r2007a
		[z{1:8,1}]=depfun(p.module(v),'-toponly','-quiet');
		z{1}
		mlint(p.module(v),'-a','-calls')
%}
end
%-------------------------------------------------------------------------------
function	p=dplot(magic,p,varargin)

	if	~chkpar(magic,p)
			return;
	end
			ftag=p.par.ptag(p);

% one instance only
			fh=findall(0,'tag',ftag);
		if	~isempty(fh)
			figure(fh);
			shg;
			return;
		end

% common parameters
			mrks=5;
			cbtag='CALLBACK';
			fs=9;					% font size
			fn='courier new';			% font name
			afs=8;
			afn='arial';

			cs=sum(abs(p.mat~=0),1);
			ms=sum(abs(p.mat~=0),2);

			xv=linspace(0,1,numel(p.caller)+2);
			yv=linspace(0,1,numel(p.module)+2);
			apos=[.25,.1,.65,.65];
			xoff=-.02;
			yoff=1.02;
			lh=nan(length(p.caller),length(p.module));

			fh=figure;
			set(fh,...
				'position',p.par.lwin,...
				'tag',ftag);
			shg;
			ah=axes;
			set(ah,...
				'position',apos,...
				'xlim',[0,1],...
				'ylim',[0,1],...
				'fontname',afn,...
				'fontsize',afs);

% CALLERS
	for	i=1:numel(p.caller)
			com=sprintf('edit(''%s'')',p.caller{i});
			th=text(xv(i+1),yoff,p.caller{i},...
				'units','normalized',...
				'rotation',90,...
				'verticalalignment','middle',...
				'fontsize',fs,'fontname',fn,...
				'interpreter','none',...
				'buttondownfcn',com,...
				'tag','f');
	if	i == 1
			set(th,'color',[1 0 0]);
	end
			set(th,'tag','c');
	for	j=1:numel(p.module)
			mcol=[0 0 1];
			ix=strcmp(p.caller{i},p.module{j});
	if	p.mat(j,i) > 0
			mrk='+';
			mrkc=[0 0 1];
	elseif	p.mat(j,i) < 0
			mrk='o';
			mrkc='none';
	elseif	ix
			mrk='diamond';
			mrkc=[0 0 1];
	else
			mrk='';
	end
	if	p.tix(j,4)
			mrkc=[1 0 0];
			mcol=mrkc;
	end
	if	mrk
			um=uicontextmenu(...
				'tag','f',...
				'callback',{@cb_pos,p,i,j,cbtag,'m'},...
				'userdata',[]);
			lh(i,j)=line(i,j,...
				'tag','f',...
				'uicontextmenu',um,...
				'buttondownfcn',{@cb_pos,p,i,j,cbtag,'m'},...
				'marker',mrk,...
				'markersize',mrks,...
				'markerfacecolor',mrkc,...
				'linestyle','none',...
				'color',mcol,...
				'userdata',[]);
	end
	end
	end

% MODULES
			yv=fliplr(yv);
	for	i=1:numel(p.module);
			tcol=[0 0 0];
			smod='     ';
			mod=p.module{i};
			ix=isempty(find(strcmp(mod,p.caller),1));
	if	p.tix(i,3)
			smod(4)='E';
	end
	if	p.tix(i,4)
			smod(3)='S';
	end
			mod=sprintf('%s%s>',mod,smod);
	if	~ix
			mod(end)='+';
	end
			com=sprintf('edit(''%s'')',p.module{i});
			text(xoff,yv(i+1),mod,...
				'units','normalized',...
				'tag','m',...
				'buttondownfcn',com,...
				'horizontalalignment','right',...
				'fontsize',fs,'fontname',fn,...
				'interpreter','none',...
				'color',tcol,...
				'userdata',i);
	end
			set(ah,...
				'buttondownfcn',{@cb_ax,cbtag,'f'},...
				'xlim',[0 length(p.caller)+1],...
				'xtick',1:length(p.caller),...
				'xticklabel',cs,...
				'ydir','reverse',...
				'ylim',[0 length(p.module)+1],...
				'ytick',1:length(p.module),...
				'yaxislocation','right',...
				'yticklabel',ms,...
				'color','none');
			box on;
			axis square;

			xt=sprintf('%-1d caller(s)\n[+: link',size(p.mat,2));
			xt=[xt '  \o: recursive'];
			xt=[xt '  \diamondsuit: caller=module]'];
			yt=sprintf('%-1d module(s)\n',size(p.mat,1));
			yt=[yt '[+: a caller  >: not a caller  S: a script (red)  E: calls f/eval..]'];
			xlabel(xt,'fontsize',afs+2);
			ylabel(yt,'fontsize',afs+2);

			set(gcf,...
				'toolbar','none',...
				'menubar','none',...
				'numberTitle','off',...
				'name',['DEPENDENCY MATRIX:   ',...
					strrep(p.file,'\','/')],...
				'color',p.par.mcol);
			shg;

	if	nargin > 2
			pause(0);			% redraw!
	for	i=1:numel(varargin)
			d=varargin{i};
	if	numel(d) == 2				&&...
		isnumeric(d)				&&...
		ishandle(lh(d(1),d(2)))
			cb_pos(lh(d(1),d(2)),[],p,d(1),d(2),cbtag,'m');
	end
	end
	end

	if	~nargout
		clear p;
	end
end
%-------------------------------------------------------------------------------
% CALLBACK functions
%	- dplot
%-------------------------------------------------------------------------------
function	cb_pos(h,e,p,xd,yd,tag1,tag2)		%#ok

		ud=get(h,'userdata');
	if	isempty(ud)
		th=findall(gca,'tag',tag2,'userdata',yd);
		txt=get(th,'string');
		is=find(isspace(txt));
		txt(is(1))=':';
		txt(is(2:end))='';
		fs=get(th,'fontsize');
		xlim=get(gca,'xlim');
		ylim=get(gca,'ylim');
		xh=line(xlim.',[yd;yd],[-10,-10],'tag',tag1);
		yh=line([xd;xd],ylim.',[-10,-10],'tag',tag1);
		set([xh,yh],'color',.9*[1,1,1]);
		txt=sprintf('%s\n%s',p.caller{xd},txt);
		th=text(xd+.01*p.par.range(xlim),yd,10*ones(size(yd)),txt,...
			'tag',tag1,...
			'fontsize',fs+1,...
			'color',[1,0,0]);
		ud=[xh,yh,th];
	else
		delete(ud);
		ud=[];
	end
		set(h,'userdata',ud);
end
%-------------------------------------------------------------------------------
function	cb_ax(h,e,tag1,tag2)			%#ok

		th=findall(h,'tag',tag1);
	if	isempty(th)
		return;
	end
		delete(th);
		th=findall(h,'tag',tag2);
		set(th,'userdata',[]);
end
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
%
% FARG		a FEX file
% created:
%	us	02-Jan-2005
%
% download the latest standalone from
% http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=15924&objectType=FILE
%
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
function	[p,pp]=farg(varargin)

		magic='FARG';
		fver='14-Nov-2007 13:16:06';

% check i/o arguments
	if	~nargin
		help(mfilename);
	if	nargout
		p=[];
		pp=p;
	end
		return;
	end

% initialize common parameters
		[p,par]=ini_par(magic,fver,varargin{:});

% parse file
	if	~par.flg
		[p,par]=set_text(p,par,1);
		[p,par]=get_file(p,par);
	if	~par.flg
		[p,par]=get_calls(p,par);
		[p,par]=get_entries(p,par);
	end
		[p,par]=set_text(p,par,2);
	end

% finalize output
	if	nargout
		pp=p;
		pp.res=par.res;
	if	~par.opt.dflg				&&...
		isfield(pp,'par')
		pp=rmfield(pp,'par');
	else
		pp.par=par;
	end
		p=par.res;
	else
		clear p;
	end
end
%-------------------------------------------------------------------------------
function	[p,par]=ini_par(magic,fver,varargin)

		narg=nargin-2;

% initialize common parameters
		F=false;
		T=true;
		p.magic=magic;
		p.([magic,'ver'])=fver;
		p.MLver=version;
		p.rundate=datestr(now);
		p.fnam='';
		p.pnam='';
		p.wnam='';
		p.dnam='';
		p.mp=[true,true];
		p.res='';
		p.def={};
		p.sub={};
		p.ixm=[];

		par=p;
		par.txt={};
		par.opt=[];

		par.mopt={
			'-m3'
			'-calls'
		};
		par.lopt={
			'-m3'
			'-lex'
		};

% - very simple option parser
		par.opt.line=true;
		par.opt.sflg=true;
		par.opt.dflg=false;
	if	narg > 1
	for	i=1:narg
	switch	varargin{i}
	case	'-l'
		par.opt.line=false;
	case	'-s'
		par.opt.sflg=false;
	case	'-d'
		par.opt.dflg=true;
	end
	end
	end

		par.fmtnoop='%10d';
		par.fmtopen='<a href="matlab:opentoline(''%s'',%d)">NUMDIG</a>';
		par.fmtopen=strrep(par.fmtopen,'NUMDIG',par.fmtnoop);
		par.fmtmark=sprintf('__&&@@%s@@&&__',par.rundate);	% unique marker

		par.rexlex='(?<=(:.+:\s+)).+$';
		par.rexmod='(\w+$)|(\d+$)';
		par.lexerr='<LEX_ERR>';

		par.ftok={
			'+'	' '		% main function
			'-'	' '		% subroutine
			'.'	'    '		% nested
			'@'	'       '	% anonymous
		};
		par.lexstp={			% @ stop conditions
			'<EOL>'
			''';'''
			''','''
		};
		par.lexbrb={			% @ REVERSE search!
			'''('''
			'''{'''
			'''['''
		};
		par.lexbre={			% @ REVERSE search!
			''')'''
			'''}'''
			''']'''
		};
		par.lent={			% function delimiters
			'FUNCTION'	2
			'<EOL>'		2
		};

		par.scom=...
			@(x) textscan(x,'%d/%d(%d):%[^:]:%s');
		par.stmpl={
			'M'	3	true	@(x) regexp(x,par.rexmod,'match')
			'S'	3	false	@(x) regexp(x,par.rexmod,'match')
			'N'	3	true	@(x) regexp(x,par.rexmod,'match')
			'A'	[1,4]	true	@(x) regexp(x,par.rexmod,'match')
			'U'	3	false	@(x) regexp(x,par.rexmod,'match')
		};
		par.stmpla.n=zeros(1,size(par.stmpl,1));

		par.flg=true;
		par.fver=fver;
		par.rt=0;
		par.shdr=3;
		par.ooff=10-3;			% memo: opentoline offset - n*%+1
		par.mext='.m';
		par.pext={
			'.miss'		0	F
			'.var'		1	F
			'.m'		2	T
			'.mex'		3	T
			'.mdl'		4	T
			'.builtin'	5	T
			'.p'		6	T
			'.folder'	7	F
			'.java'		8	F
		};
		par.mlroot=[matlabroot,filesep,'toolbox'];
		par.ftyp={'SCRIPT','FUNCTION'};
		par.crlf=sprintf('\n');
		par.wspace=[' ',sprintf('\t')];
		par.bol='%%';

		p.n=par.stmpla.n;
	for	i=1:size(par.stmpl,1)
		fn=par.stmpl{i,1};
		par.stmpla.(fn).fn={''};
		par.stmpla.(fn).fd={''};
		par.stmpla.(fn).nx=0;
		par.stmpla.(fn).bx=[];
		par.stmpla.(fn).ex=[];
		par.stmpla.(fn).lx=[];
		p.(fn)=par.stmpla.(fn);
	end

% - get/check file name
		flg=false;
		par.fnam=varargin{1};
		ftype=exist(par.fnam,'file');
		[fpat,frot,fext]=fileparts(par.fnam);
	if	isempty(fext)				||...
		ftype ~= par.pext{3,2}
		par.fnam=[frot,par.mext];
	end
	if	ftype ~= par.pext{3,2}
		par.pnam=varargin{1};
	end

		par.pnam=which(par.pnam);
	if	isempty(par.pnam)
		par.mp(2)=false;
	end
		par.wnam=which(par.fnam);
		wtype=exist(par.wnam,'file');
	if	isempty(par.wnam)			||...
		wtype ~= par.pext{3,2}
		flg=true;
		par.mp(1)=false;
	if	par.opt.sflg
		disp(sprintf('FARG> ERROR   M-file not found'));
		disp(sprintf('-----------   %s',varargin{1}));
	end
	end
		par.dnam=dir(par.wnam);
	if	~flg
		par.dnam.ds=strread(par.dnam.date,'%s','whitespace',' ');
	end
	if	par.mp(2)				&&...
		~par.pext{ftype+1,3}
		par.mp=[false,false];
	end

% create output structure
		p.fnam=par.fnam;
		p.pnam=par.pnam;
		p.wnam=par.wnam;
		p.dnam=par.dnam;
		p.mp=par.mp;

		par.nlen=0;
		par.nlex=0;
		par.nfun=0;
		par.mfun=0;
		par.file=[];
		par.call=[];
		par.lex=[];
		par.ltok={};
		par.flg=flg;
		p.par=par;
end
%-------------------------------------------------------------------------------
function	[p,par]=get_file(p,par)

% contents
		par.file=textread(par.wnam,'%s','delimiter','\n','whitespace','');
		par.nlen=size(par.file,1);
% calls
		par.call=mlintmex(par.wnam,par.mopt{:});
		par.call=strread(par.call,'%s','delimiter','','whitespace','');
% tokens
		par.lex=mlintmex(par.wnam,par.lopt{:});
		ix=ismember(par.lex,par.wspace);
		par.lex(ix)='';
		par.lex=par.scom(par.lex);
		par.ltok=[par.lex{:,4},par.lex{:,5}];
		par.lex=cat(2,par.lex{1:3});
		par.nlex=size(par.ltok,1);

		lerr=sum(strcmp(par.ltok,par.lexerr),2);
	if	any(lerr)
		ix=find(lerr);
		nx=numel(ix);

		par.txt=[
			par.txt
			'DONE'
			{
%			sprintf('%s file                %s',par.bol,par.wnam)
			sprintf('%s LEX errors%6d',par.bol,nx)
			'LINE'
			}
		];
	for	i=1:nx
			nl=par.lex(ix(i),:);
	if	par.opt.line
			el=sprintf(par.fmtopen,par.wnam,nl(1),nl(1));
	else
			el=sprintf(par.fmtnoop,nl(1));
	end
			nl(2)=min([nl(2),numel(par.file{nl(1)})]);
			to=par.file{nl(1)}(nl(2));
		par.txt=[
			par.txt
			{
			sprintf('%s line  %s:   %-1d = <%s>',par.bol,el,nl(2),to)
			}
		];
	end
		par.txt(4,1)={
			sprintf('%s',repmat('-',1,size(char(par.txt(1:3)),2)))
		};
		par.flg=true;
		par.opt.sflg=true;
		return;
	end
end
%-------------------------------------------------------------------------------
function	[p,par]=get_calls(p,par)

	for	i=1:size(par.stmpl,1)
		fn=par.stmpl{i,1};
		v.(fn)=[];
		ix=~cellfun('isempty',regexp(par.call,['^',fn],'match'));
	if	any(ix)
		vtmp=par.stmpl{i,4}(par.call(ix));
		bx=cellfun(@(x) sscanf(x,'%*2s %d %d %*s'),par.call(ix),'uni',false);
		ex=bx;
	if	par.stmpl{i,3}
		ex=cellfun(@(x) sscanf(x,'%*2s %d %d %*s'),par.call(find(ix)+1),'uni',false);
	end
		p.n(i)=sum(ix);
		p.(fn).fn=[vtmp{:}].';
		p.(fn).nx=p.n(i);
		p.(fn).bx=[bx{:}];
		p.(fn).ex=[ex{:}];
	end
	end
		par.nfun=sum(p.n(1:4));
		par.mfun=sum(p.n(1:3));
end
%-------------------------------------------------------------------------------
function	[p,par]=get_entries(p,par)

		ixt=false(par.nlex,2);
	for	i=1:size(par.lent,1)
		ctok=par.lent{i,1};
		nmatch=par.lent{i,2};
		ixt(:,i)=sum(strcmp(ctok,par.ltok),2)==nmatch;
	end

% parse LEX output for function definitions
% - main/sub
		ixm=[];
		sr=[];
	if	par.nfun

		ixm=zeros(par.nfun,2);
		ixb=zeros(par.nfun,1);
		ixe=zeros(par.nfun,1);
		ixl=zeros(par.nfun,1);
		sr=cell(size(ixm,1),1);

	if	p.N.nx
		nix=p.N.bx(1,:);
	end
	if	par.mfun
		ixb(1:par.mfun,1)=find(ixt(:,1)==1);
	for	i=1:par.mfun
		ixl(i)=find(ixt(ixb(i)+1:end,2)==1,1,'first');
		sr{i}=par.ltok(ixb(i):ixb(i)+ixl(i),2);
		sr{i}=regexprep(sr{i},'^''','');
		sr{i}=regexprep(sr{i},'''$','');
		ixe(i)=par.lex(ixb(i)+ixl(i),1);
		ixb(i)=par.lex(ixb(i),1);
		sr{i}=sprintf('%s',sr{i}{2:end-1});
		ixm(i,:)=[ixb(i),min([i,2])];
% - nested
	if	p.N.nx
	if	any(ixb(i)<=nix)			&&...
		any(nix<=ixe(i))
		ixm(i,2)=3;
	end
	end
	end
	else
		i=0;
	end

% - anonymous
%   note to programmers: this is very tedious because MLINT
%   does NOT correctly evaluate start/end indices of
%   anonymous functions [r2007a: mlint -calls FUNCTION]!
%   currently, this requires
%   - get_anonymous()
%   - set_bracket()

	if	p.A.nx
		[ib,ib]=ismember(p.A.bx.',par.lex(:,1:2),'rows');

	for	ibx=1:numel(ib)
		nb=0;
	for	ix=ib(ibx):-1:1

		nb=nb+any(ismember(par.ltok{ix,2},par.lexbre));
	if	nb>0
		nb=nb-any(ismember(par.ltok{ix,2},par.lexbrb));
	elseif	~nb
		im=any(ismember(par.ltok{ix,2},par.lexstp));
	if	im
		ib(ibx)=ix+1;
		break;
	end
	end
	end
	end

		ixm(i+1:end,:)=[par.lex(ib,1),repmat(4,p.A.nx,1)];
		[ie,ie]=ismember(p.A.ex.',par.lex(:,1:2),'rows');

	for	ibx=1:numel(ie)
	for	ix=ie(ibx):par.nlex
		im=any(ismember(par.ltok{ix,2},par.lexstp));
	if	im
		ie(ibx)=ix-1;
		break;
	end
	end
	end
		p.A.lx=[ib(:).';ie(:).'];
		ss=get_anonymous(p,par);
		p.A.fn=ss;
		sr(ixm(:,2)==4)=ss;
		[ix,ix]=sort(ixm(:,1));
		sr=sr(ix);
		ixm=ixm(ix,:);
	end

		ixb=ixm(:,1);
	end
		p.ixm=ixm;

		[p,par,s]=set_text(p,par,3);

% create function entries
	if	par.nfun
		omax=0;
	for	i=1:par.nfun
		cn=i+par.shdr;
		s{cn}=sprintf('%s%6d|%s: %c %s',...
			par.bol,...
			i,...
			par.fmtmark,...
			par.ftok{ixm(i,2),1},...
			par.ftok{ixm(i,2),2});
		s{cn}=deblank(sprintf('%s%s',s{cn},sr{i}));
	if	par.opt.line
		of=sprintf(par.fmtopen,par.wnam,ixb(i),ixb(i));
	else
		of=sprintf(par.fmtnoop,ixb(i));
	end
		omax=max([omax,numel(of)]);
		s{cn}=strrep(s{cn},par.fmtmark,of);
	end
		s{par.shdr}=[par.bol,' ',sprintf(repmat('-',1,size(char(s),2)-omax+par.ooff))];
		ix=(ixm(:,2)==1) | (ixm(:,2)==2);
	if	any(ix)
		sf=[p.M.fn;p.S.fn];
		sf=sf(~cellfun(@isempty,sf));
		sd=sr(ix);
		ns=max(cellfun(@numel,sf));
		fmt=sprintf('%%-%ds   >   %%s',ns);
		sd=cellfun(@(a,b) sprintf(fmt,a,b),sf,sd,'uni',false);
		p.M.fd=sr(ixm(:,2)==1);
		p.S.fd=sr(ixm(:,2)==2);
		p.sub=sd;
	end
	else
		s=s(1);
	end

		p.def=sr;
		par.res=char(s);
end
%-------------------------------------------------------------------------------
function	ss=get_anonymous(p,par)

		ss=cell(p.A.nx,1);
	for	i=1:p.A.nx
		dtok=par.ltok(p.A.lx(1,i):p.A.lx(2,i),:);
		ix=~strncmp('<STRING>',dtok(:,1),8);
		ie= strncmp('<EOL>',dtok(:,1),5);
		iz=cellfun(@numel,dtok(:,1))==1;
		ix=xor(ix,iz);
		a=par.ltok(p.A.lx(1,i):p.A.lx(2,i),2);
		a(ix)=regexprep(a(ix),'^['']','');
		a(ix)=regexprep(a(ix),'['']$','');
		a(ie)={';'};
		a=sprintf('%s',a{:});
		a=strrep(a,'...','');
		a=strrep(a,''':'':''',':');
		ix=ismember(a,par.wspace);
		a(ix)='';
		ix=find(a=='@',1,'first');
		ix=find(a(ix:end)==')')+ix-1;
		a=[a(1:ix),' ',a(ix+1:end)];
		ss{i}=set_bracket(a);
	end
end
%-------------------------------------------------------------------------------
function	s=set_bracket(s)

		br={
			'[]'	1
			'()'	2
			'{}'	3
%			'<>'	4
		};
		ba=cell(size(br,1),1);
	for	i=1:size(br,1)
		bb=strfind(s,br{i,1}(1));
		be=strfind(s,br{i,1}(2));
		k=zeros(size(s));
		k(bb)=ones(size(bb));
		k(be)=-ones(size(be));
		k=cumsum(k);
		k=[k(end:-1:1),0];
	if	k(1) > 0
		bc=br{i,2}*ones(2,k(1));
	for	j=1:k(2)
		bc(1,j)=find(k(1:end-1)==j&k(2:end)==j-1,1,'first');
	end
		ba{i}=bc;
	end
	end

		ba=cat(2,ba{:});
	if	~isempty(ba)
		ba(1,:)=numel(s)-ba(1,:)+1;
		bc=sortrows(ba.',-1).';
		bc=bc(2,:);
		r=char(1:numel(bc)-1);
	for	i=1:size(br,1)
		r(bc==br{i,2})=br{i,1}(2);
	end
		s=[s,r];
	end
end
%-------------------------------------------------------------------------------
function	[p,par,s]=set_text(p,par,mode)

	switch	mode
	case	1
		par.txt(1,1)={
			sprintf('%s parsing...          %s',par.bol,par.wnam)
		};
		sdisp(par,char(par.txt));
		par.rt=clock;
		return;
	case	2
		par.rt=etime(clock,par.rt);
		par.txt(2,1)={
			sprintf('%s done                %.4f sec',par.bol,par.rt)
		};
	if	~par.flg
		sdisp(par,char(par.txt(2:end,1)));
		sdisp(par,char(par.res));
	else
		par.res=char(par.txt);
		sdisp(par,par.res(1+p.par.opt.sflg:end,:));
	end
		return;
	case	3
		par.txt=[
			par.txt
			{
			'DONE'
%			sprintf('%s LEX tokens          %-1d',par.bol,par.nlex)
%			sprintf('%s file type           %s',par.bol,par.ftyp{sign(par.mfun)+1})
%			sprintf('%s functions           %-1d',par.bol,par.nfun)
			sprintf('');
			}
		];

	if	~isempty(par.pnam)
		pc=par.pnam;
	else
		pc='';
	end

		s=cell(par.nfun+par.shdr,1);
		s{1}={
			sprintf('%s MATLAB version  :   %s',par.bol,par.MLver)
			sprintf('%s %.4s   version  :   %s',par.bol,par.magic,par.fver)
			sprintf('%s run    date     :   %s',par.bol,par.rundate)
			sprintf('%s',par.bol);
			sprintf('%s FILE            :   %s',par.bol,par.wnam)
			sprintf('%s - Pcode         :   %s',par.bol,pc)
			sprintf('%s - type          :   %s',par.bol,par.ftyp{sign(par.mfun)+1})
			sprintf('%s - date          :   %s',par.bol,par.dnam.ds{1})
			sprintf('%s - time          :      %s',par.bol,par.dnam.ds{2})
			sprintf('%s - size          :   %11d bytes',par.bol,par.dnam.bytes)
			sprintf('%s - lines         :   %11d',par.bol,par.nlen)
			sprintf('%s - LEX  tokens   :   %11d',par.bol,par.nlex)
			sprintf('%s - calls         :   %11d',par.bol,p.U.nx)
			sprintf('%s - functions     :   %11d',par.bol,par.nfun)
			sprintf('%s   - main        : %c %11d',par.bol,par.ftok{1,1},p.M.nx)
			sprintf('%s   - subroutines : %c %11d',par.bol,par.ftok{2,1},p.S.nx)
			sprintf('%s   - nested      : %c %11d',par.bol,par.ftok{3,1},p.N.nx)
			sprintf('%s   - anonymous   : %c %11d',par.bol,par.ftok{4,1},p.A.nx)
		};
		s{1}=char(s{1});

	if	par.nfun
		s{2}={
			sprintf('%s',par.bol)
			sprintf('%s FUNCTIONS',par.bol)
			sprintf('%s     #|line      : T  definition',par.bol)
		};
		s{2}=char(s{2});
		s{par.shdr}='x';
	end
	end
end
%-------------------------------------------------------------------------------
function	sdisp(par,txt)

	if	par.opt.sflg
		disp(txt);
	end
end
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
%
% DETAB		a FEX file
% created:
%	us	21-Apr-1992
%
% download the latest standalone from
% http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=10536&objectType=FILE
%
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
function	[ss,p]=detab(cstr,varargin)

% default parameters/options
		magic='DETAB';
		ver='14-Nov-2007 13:16:06';
		ss=[];
		p=[];
		fnam='CELL';

% - default options
		deftlen=8;
		deftchar=' ';

% - option template
		otmpl={
%		opt	ival	narg	defval		desc
%		----------------------------------------------
		'-t'	true	1	deftlen		'tab length in char'
		'-c'	true	1	deftchar	'tab end marker'
		'-l'	false	0	[]		'show listbox'
		'-lp'	false	1	{}		'listbox parameters'
		};

	if	nargin < 1
		help(mfilename);
		return;
	end
		[opt,par]=get_par(otmpl,varargin{:});

	if	ischar(cstr)
		fnam=which(cstr);
	if	~exist(cstr,'file')
		disp(sprintf('DETAB> file not found <%s>',fnam));
		return;
	end
		[fp,msg]=fopen(fnam,'rb');
	if	fp < 0
		disp(sprintf('DETAB> cannot open file <%s>',fnam));
		disp(sprintf('       %s',msg));
		return;
	end
		cstr=textscan(fp,'%s',...
			'delimiter','\n',...
			'whitespace','');
		fclose(fp);
		cstr=cstr{:};
	elseif	~iscell(cstr)
		disp('DETAB> input must be a file name or a cell');
		return;
	end

		tab=sprintf('\t');
% read argument

		p.magic=magic;
		p.ver=ver;
		p.mver=version;
		p.rundate=datestr(clock);
		p.runtime=clock;
		p.par=par;
		p.opt=opt;
		p.input=fnam;
		p.cs=size(cstr);
		p.ns=numel(cstr);
		p.nc=0;
		p.nl=0;
		p.nt=0;

% convert string cells only
		cstr=cstr(:);
		ix=cellfun('isclass',cstr,'char');
		p.nc=sum(ix);
	if	~p.nc
		ss=cstr;
		return;
	end
		ss=cstr(ix);

		tmax=max(cellfun('length',ss));
		tlen=p.opt.t.val;
		tt=tlen:tlen:tmax*tlen;
		p.par.tab=repmat(['.......',p.par.tc],1,ceil(tmax/tlen));
		ttb=sprintf('TAB=%-1d',tlen);
		p.par.tab(1:length(ttb))=ttb;

		p.runtime=clock;
% reconstruct absolute position based on cumulative TABs
	for	i=1:p.nc
		s=ss{i};
		tp=strfind(s,tab);
	if	~isempty(tp)
		nt=numel(tp);
		p.nl=p.nl+1;
		p.nt=p.nt+nt;
		tn=1:nt;
		tm=tt(tn);
		tx=tm-tp+tn;
		tx(end)=[];
		tx=[0,tx]+tp-tn;
		tx=tm-tx;
		tx=mod(tx-1,tlen)+1;
		tx=p.par.t(tx);
		ss{i,1}=regexprep(s,'\t',tx,'once');
	end
	end
		p.runtime=etime(clock,p.runtime);
		cstr(ix)=ss;
		ss=reshape(cstr,p.cs);
		
% show contents in listbox
	if	p.opt.l.flg
		blim=.005;
		clf;
		shg;
		p.par.uh=uicontrol('units','norm',...
			'position',[blim,blim,1-2*blim,1-2*blim],...
			'style','listbox',...
			'max',2,...
			'fontname','courier new',...
			'backgroundcolor',1*[.75 1 1],...
			'foregroundcolor',[0 0 1],...
			'tag',p.magic,...
			p.opt.lp.val{:});
% - fastes listbox fill mode (pcode!)
		sh=char([{p.par.tab};ss(ix)]);
		set(p.par.uh,'string',sh);
	end
end
%--------------------------------------------------------------------------------
function	[opt,par]=get_par(otmpl,varargin)
% option parser

		par.t=[];
		par.tab=[];

		narg=nargin-1;
	for	i=1:size(otmpl,1)
		[oflg,val,arg,dval]=otmpl{i,1:4};
		flg=oflg(2:end);
		opt.(flg).flg=val;
		opt.(flg).val=dval;
		ix=strcmp(oflg,varargin);
		ix=find(ix,1,'last');
	if	ix
		opt.(flg).flg=true;
	if	arg
	if	narg >= ix+arg
		opt.(flg).val=varargin{ix+1:ix+arg};
	else
		opt.(flg).flg=val;
	end
	end
	end
	end

% create TAB replacement templates
		tlen=opt.t.val;
		par.t=cell(tlen,1);
	for	i=1:tlen
		par.t{i,1}=sprintf('%*s',i,opt.c.val);
	end

% - tabulator marker
	if	~isempty(opt.c.val)	&&...
		~isspace(opt.c.val)
		par.tc=opt.c.val;
	else
		par.tc=char(166);	% <¦>
	end
		par.uh=[];
end
%--------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
%
% additional help sections
%
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
function	s=fdephelp(fnam,p,mode,dflg,varargin)

	if	nargin < 4
		mode='p';
		dflg=false;
	end

		hasfile=false;
	switch	mode
% listing panels' help
	case	'p'
		htag=p.par.htag(p);
	if	~isempty(findall(0,'tag',htag))
		return;
	end
		hasfile=true;
		tb='%@LISTHELP_BEG';
		te='%@LISTHELP_END';
		ftit='FDEP HELP';
% full module description
	case	'm'
		dflg=false;
		ucol=p.par.fcol;
		[s,htag,ftit]=show_module(p,varargin{:});
	if	isempty(ftit)
		return;
	end
	otherwise
		disp(sprintf('FDEP> invalid HELP id'));
		return;
	end

	if	hasfile
		ucol=p.par.pcol;
		s=textread([fnam,'.m'],'%s','delimiter','\n','whitespace','');
		ib=strmatch(tb,s);
		ie=strmatch(te,s);
		s=detab(s(ib+1:ie-1));
	end

	if	~dflg
		figure(...
			'tag',htag,...
			'position',p.par.hwin,...
			'numbertitle','off',...
			'menu','none',...
			'name',ftit);
		uicontrol(...
			'units','normalized',...
			'position',[0,0,1,1],...
			'style','listbox',...
			'horizontalalignment','left',...
			'max',2,...
			'string',s,...
			'fontname','courier new',...
			'fontsize',9,...
			'backgroundcolor',ucol,...
			'foregroundcolor',p.par.tcol);
	else
		disp(char(s));
	end
	if	~nargout
		clear s;
	end
end
%-------------------------------------------------------------------------------
function	mhelp(magic,p,varargin)

	if	nargin < 3
		return;
	end

	for	i=1:numel(varargin)
	if	~iscell(varargin{i})
		carg=varargin(i);
	else
		carg=varargin{i};
	end

	for	j=1:numel(carg)
		arg=carg{j};
	if	isnumeric(arg)
	for	k=1:numel(arg)
		p=dfind(magic,p,false,arg(k));
		fdephelp([],p,'m',true,p.ix,p.rm);
	end
	elseif	ischar(arg)
		p=dfind(magic,p,false,arg);
		fdephelp([],p,'m',true,p.ix,p.rm);
	end
	end
	end
end
%-------------------------------------------------------------------------------
function	[s,htag,ftit]=show_module(p,varargin)

	mlst={
%		fieldname		descriptor
%		------------------------------------------------------
		'subfunction'		'MAIN function / subfunctions'
		'nested'		'nested functions'
		'anonymous'		'anonymous functions'
		'callsTO'		'calls TO   modules'
		'callsFROM'		'calls FROM modules'
		'MLtoolbox'		'ML toolboxes'
		'MLfunction'		'ML stock functions'
		'MLbuiltin'		'ML built-in functions'
		'MLclass'		'ML classes'
		'OTHERclass'		'OTHER classes'
		'calls'			'calls in FILE'
	};

		htag=[];
		ftit=[];
		v=varargin{1};
		s=varargin{2};
		d=dget(p.magic,p,false,v,false);
	if	isempty(d)
		return;
	end

	if	~p.sub(v).mp(1)
		mlst(end,:)=[];
	end

		htag=p.par.mtag(d.module);
		otag=findall(0,'tag',htag);
	if	~isempty(otag)
		figure(otag);
		return;
	end

		nlst=size(mlst,1);
		nmax=max(cellfun(@numel,mlst(:,2)));
		fmt=sprintf('----- %%-%d.%ds: %%d',nmax,nmax);

		n=max(cellfun(@numel,s));
		s{end+1}=repmat('-',1,n);
	for	i=1:nlst
		ts=d.(mlst{i,1});
		ts=ts(~cellfun(@isempty,ts));
		ns=numel(ts);
		s{end+1}=sprintf(fmt,mlst{i,2},ns);		%#ok
	if	ns
		tn=num2cell(1:ns).';
		s(end+1:end+ns)=cellfun(@(a,b) sprintf('%4d:          %s',a,b),tn,ts,'uni',false);	%#ok
	end
		s(end+1)={''};					%#ok
	end
		ftit=sprintf('MODULE SYNOPSIS:   %s',d.module);
end
%-------------------------------------------------------------------------------
%@LISTHELP_BEG
% FDEP	version 14-Nov-2007 13:16:06
%
% the ML-file under investigation is the
%	root function = MAIN module
% a module is a user-defined ML-file living outside the root function
%	in a folder, which is part of ML's search path
% a module may be a ML-function (M- or P-file), a ML-script (M-file), or
%	a MEX/DLL-file (listed as P-file with correct extension)
% functions, which are called by an individual module, are grouped into
%	- subfunctions
%	- nested functions
%	- anonymous functions
%	- number of calls to f/eval constructs
%	- ML stock functions
%	- ML built-in functions
%	- ML classes
%	- ML toolboxes
% most panels have tooltips
%
% modules
%-------------------------------------------------------------------------------
%	a list of all modules, which are called by the MAIN module
%	the MAIN module is always on top of the list, all other modules are
%	   sorted in alphabetical order and show information in 3 columns
%		1	# of the module
%			- this number must be used for command line access of
%			  numeric module information by the macros
%				p.find(M#,...);
%				p.get(M#,...);
%				p.mhelp(M#);
%				p.list(M#,...);
%				p.plot([Mx/My],...);
%		2	name of the module
%		3	special attributes of the module
%				R: module calls itself (recursive)
%				E: module uses an EVAL/EVALIN/EVALC/FEVAL construct
%				S: module is a SCRIPT
%				P: module is or has a P-file
%	CLICKING on a name activates the module and shows its contents
%
% main function
%-------------------------------------------------------------------------------
%	shows a synopsis of the MAIN module including a summary of the calls of
%	   all its modules for each group of ML functions, version information,
%	   and the runtime
%	CLICKING in this box will activate the MAIN module
%
% toolboxes
%-------------------------------------------------------------------------------
%	shows a list of all toolboxes that are used by the modules
%	those that are used by the currently selected module are highlighted
%	CLICKING in this box has no effect
%
% module summary
%-------------------------------------------------------------------------------
%	shows the summary of the current module including its attributes and
%	   the exact number of calls for each group of functions
%	all function group entries are sorted
%	all calls found in the function are shown in sequence and may be
%	   repeated (same call in different subfunctions)
%	if both M- and P-FILE names are shown, the M-file is used
%	   to extract all data, but the P-FILE will be called during runtime
%	if only a P-FILE name is shown (standalone), only ML entities
%	   can be extracted due to the limitations of MLINT
%	to retrieve this information from the command window, use macro
%		p.find(M1,...);
%	CLICKING on the first line will show the full synopsis in a window
%	to show the full synopsis from the command window, use macro
%		p.mhelp(M1,...);
%
% calls  TO
%-------------------------------------------------------------------------------
%	shows all modules that the current module calls
%	CLICKING on a name activates the module in <modules> and shows its
%	   contents
%
% called FROM
%-------------------------------------------------------------------------------
%	shows all modules that call the current module
%	CLICKING on a name activates the module in <modules> and shows its
%	   contents
%
% subfunctions
%-------------------------------------------------------------------------------
%	shows subfunctions of the current module in the format
%		M(line#): function name > definition of MAIN/first function
%		S(line#): function name > definition of subfunction
%	this box is only filled, if the module is a ML function
%	CLICKING on a name opens the module in the editor at its line
%
% nested / anonymous functions
%-------------------------------------------------------------------------------
%	shows function definitions of the current module in the format
%		A(line#): definition of anonymous function
%		N(line#): definition of nested    function
%	CLICKING on a name opens the module in the editor at its line
%
% JOHN D'
%-------------------------------------------------------------------------------
%	utility in honor of John D'errico, a senior and most respected
%	   FEX and CSSM contributor, with very poor eyesight
%	CLICKING on the button will grow the fontsize by 1 point every
%	   time
%
% EDIT
%-------------------------------------------------------------------------------
%	opens the current module in the editor
%
% DEPENDENCY MATRIX
%-------------------------------------------------------------------------------
%	displays the dependency matrix of the MAIN module
%
% HELP
%-------------------------------------------------------------------------------
%	shows this help in a window
%	to show this help from the command window, use macro
%		p.help();	displays contents in a window
%		p.help(1);	displays contents in the command window
%
%@LISTHELP_END
%-------------------------------------------------------------------------------