/*
 * wrapper for libpvm3 routines
 * 
 * Copyright (c) 1995-1999 University of Rostock, Germany, 
 * Institute of Automatic Control. All rights reserved.
 *
 * Copyright (c) 1997 University of Magdeburg, Germany, 
 * Institute of Automation. All rights reserved.
 *
 * See file ``Copyright'' for terms of copyright.
 *
 * Authors: S. Pawletta, M. Suesse
 *	    T. T. Binh, A. Westphal (M5 code where it differs from M4)
 *
 */

#include "m2libpvm.h"
#include "misc.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pvm3.h>


/************************************************************************
 * 	 								*
 * PVM Control 								*
 * 	 								*
 ************************************************************************/

/*-------------------------------------------------------------------*/
void m2pvm_addhosts(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
#ifdef M4
        char    **hosts;
        int     nhosts;
        int     *infos;

        if ( strmat2str(prhs[0],&hosts,&nhosts) )
                mexErrMsgTxt("m2pvm_start_pvmd(): strmat2str failed.\n");

        infos = mxCalloc(nhosts,sizeof(int));
        plhs[0] = mxCreateFull(1,1,REAL);

        (mxGetPr(plhs[0]))[0] = (double) pvm_addhosts(hosts,nhosts,infos);

        if ( int2mat(infos,nhosts,&plhs[1]) )
                mexErrMsgTxt("m2pvm_start_pvmd(): int2mat failed.\n");

#else
	char	*hosts, **tmphosts;
	int	nhosts;
	int	*infos, i;

	/* initialize nhosts and hosts */
	nhosts=mxGetM(prhs[0]);
	hosts = mxCalloc(mxGetM(prhs[0])*mxGetN(prhs[0])+1, sizeof(char));

	mxGetString(prhs[0],hosts,(mxGetM(prhs[0]) * mxGetN(prhs[0])) + 1);

	infos = mxCalloc(nhosts,sizeof(int));
	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

        tmphosts = (char **)mxCalloc(nhosts, sizeof(char*)); 
        *tmphosts= hosts;

	(mxGetPr(plhs[0]))[0] = (double) pvm_addhosts(tmphosts,nhosts,infos);

        plhs[1] = mxCreateDoubleMatrix(nhosts,1,mxREAL);
	for (i=0; i< nhosts; i++)
		mxGetPr(plhs[1])[i] = (double)  infos[i];

#endif
	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_delhosts(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
#ifdef M4
        char    **hosts;
        int     nhosts;
        int     *infos;

        if ( strmat2str(prhs[0],&hosts,&nhosts) )
                mexErrMsgTxt("m2pvm_start_pvmd(): strmat2str failed.\n");

        infos = mxCalloc(nhosts,sizeof(int));
        plhs[0] = mxCreateFull(1,1,REAL);

        (mxGetPr(plhs[0]))[0] = (double) pvm_delhosts(hosts,nhosts,infos);

        if ( int2mat(infos,nhosts,&plhs[1]) )
                mexErrMsgTxt("m2pvm_start_pvmd(): int2mat failed.\n");

#else
	char	*hosts, **tmphosts;
	int	nhosts;
	int	*infos, i;

	/* initialize nhosts and hosts */
	nhosts=mxGetM(prhs[0]);
	hosts = mxCalloc(mxGetM(prhs[0])*mxGetN(prhs[0])+1, sizeof(char));

	mxGetString(prhs[0],hosts,(mxGetM(prhs[0]) * mxGetN(prhs[0])) + 1);

	infos = mxCalloc(nhosts,sizeof(int));
	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

        tmphosts = (char **)mxCalloc(nhosts, sizeof(char*)); 
        *tmphosts= hosts;

	(mxGetPr(plhs[0]))[0] = (double) pvm_delhosts(tmphosts,nhosts,infos);

        plhs[1] = mxCreateDoubleMatrix(nhosts,1,mxREAL);

	for (i=0; i< nhosts; i++)
		mxGetPr(plhs[1])[i] = (double)  infos[i];

#endif
	return;
}


/************************************************************************
 * 	 								*
 * Setting and Getting Options						*
 * 	 								*
 ************************************************************************/

/*-------------------------------------------------------------------*/
void m2pvm_getopt(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	int	what;

	what = (int) mxGetScalar(prhs[0]);

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

	mxGetPr(plhs[0])[0] = (double) pvm_getopt(what);

	return;
}

/*-------------------------------------------------------------------*/
void m2pvm_setopt(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	int	what;
	int	val;

	what = (int) mxGetScalar(prhs[0]);
	val  = (int) mxGetScalar(prhs[1]);

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

	mxGetPr(plhs[0])[0] = (double) pvm_setopt(what,val);

	return;
}


/************************************************************************
 * 	 								*
 * Process Control 								*
 * 	 								*
 ************************************************************************/

/*-------------------------------------------------------------------*/
void m2pvm_spawn(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
        char    **task;
        char    **argv;
        int     flag;
        char    **where;
        int     ntask;
        int     *tids;
        int     trash;

        if ( strmat2str(prhs[0],&task,&trash) )
                mexErrMsgTxt("m2pvm_spawn(): strmat2str failed.\n");

        if ( strmat2strnull(prhs[1],&argv) )
                mexErrMsgTxt("m2pvm_spawn(): strmat2strnull failed.\n");

        flag = (int) mxGetScalar(prhs[2]);

        if ( strmat2str(prhs[3],&where,&trash) )
                mexErrMsgTxt("m2pvm_spawn(): strmat2str failed.\n");

        ntask = (int) mxGetScalar(prhs[4]);

        tids = mxCalloc(ntask,sizeof(int));

        plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

        (mxGetPr(plhs[0]))[0] = (double) pvm_spawn(*task,argv,flag,
						   *where,ntask,tids);
        
        if ( int2mat(tids,ntask,&plhs[1]) )
                mexErrMsgTxt("m2pvm_spawn(): int2mat failed.\n");

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_export(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
        char *name;
        int  strl;

        strl = mxGetN(prhs[0])+1;
        if ( !( name = (char*) mxCalloc(strl,sizeof(char)) ) )
                mexErrMsgTxt("m2pvm_export(): mxCalloc() failed.\n");
        if ( mxGetString(prhs[0],name,strl)) 
                mexErrMsgTxt("m2pvm_export(): mxGetString() failed.\n");

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

        (mxGetPr(plhs[0]))[0] = (double) pvm_export(name);

        return;
}


/*-------------------------------------------------------------------*/
void m2pvm_unexport(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
        char *name;
        int  strl;

        strl = mxGetN(prhs[0])+1;
        if ( !( name = (char*) mxCalloc(strl,sizeof(char)) ) )
                mexErrMsgTxt("m2pvm_export(): mxCalloc() failed.\n");
        if ( mxGetString(prhs[0],name,strl))
                mexErrMsgTxt("m2pvm_export(): mxGetString() failed.\n");

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

        (mxGetPr(plhs[0]))[0] = (double) pvm_unexport(name);

        return;
}


/*-------------------------------------------------------------------*/
void m2pvm_catchout(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	FILE	*stream;

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

	if (nrhs == 0)
		(mxGetPr(plhs[0]))[0] = (double) pvm_catchout(NULL);

	else {
		stream = (FILE*) (int) mxGetScalar(prhs[0]);
		(mxGetPr(plhs[0]))[0] = (double) pvm_catchout(stream);

	}
	
	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_kill(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	int	tid;

	tid = (int) mxGetScalar(prhs[0]);

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

	(mxGetPr(plhs[0]))[0] = (double) pvm_kill(tid);

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_exit(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	mxGetPr(plhs[0])[0] = (double) pvm_exit();

	return;
}


/************************************************************************
 * 	 								*
 * Information 								*
 * 	 								*
 ************************************************************************/

/*-------------------------------------------------------------------*/
void m2pvm_mytid(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

	mxGetPr(plhs[0])[0] = (double) pvm_mytid();

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_parent(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

	(mxGetPr(plhs[0]))[0] = (double) pvm_parent();

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_pstat(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	int	tid;

	tid = (int) mxGetScalar(prhs[0]);

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

	(mxGetPr(plhs[0]))[0] = (double) pvm_pstat(tid);

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_mstat(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	char	*host;
	int	strl;

	strl = mxGetN(prhs[0])+1;
	host = (char*) mxCalloc(strl,sizeof(char));
	if ( mxGetString(prhs[0],host,strl) )
		mexErrMsgTxt("m2pvm_mstat(): mxGetString() failed.");
	
	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
	
	(mxGetPr(plhs[0]))[0] = (double) pvm_mstat(host);
	
   	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_config(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
#ifdef M4
        int     nhost, narch;
        struct  pvmhostinfo *hostp;
        double  *dtids, *speeds;
        char    **hosts, **archs;
        int     i;

        plhs[0] = mxCreateFull(1,1,REAL);
        (mxGetPr(plhs[0]))[0] = (double) pvm_config(&nhost,&narch,&hostp);

        plhs[1] = mxCreateFull(1,1,REAL);
        (mxGetPr(plhs[1]))[0] = (double) nhost;

        plhs[2] = mxCreateFull(1,1,REAL);
        (mxGetPr(plhs[2]))[0] = (double) narch;

        plhs[3] = mxCreateFull(nhost,1,REAL);           
        dtids = mxGetPr(plhs[3]);
        hosts = (char**) mxCalloc(nhost,sizeof(char*));
        archs = (char**) mxCalloc(nhost,sizeof(char*));
        plhs[6] = mxCreateFull(nhost,1,REAL);   
        speeds = mxGetPr(plhs[6]);

        for (i=0; i<nhost; i++) {
                dtids[i] = (double) (hostp[i].hi_tid);
                hosts[i] = hostp[i].hi_name;
                archs[i] = hostp[i].hi_arch;
                speeds[i] = (double) (hostp[i].hi_speed);
        }

        if ( str2strmat(hosts,nhost,&plhs[4]) )
                mexErrMsgTxt("m2pvm_config(): str2strmat() failed.");

        if ( str2strmat(archs,nhost,&plhs[5]) )
                mexErrMsgTxt("m2pvm_config(): str2strmat() failed.");

#else
	int	nhost, narch;
	struct	pvmhostinfo *hostp;
	double	*dtids, *speeds;
	const char	**hosts, **archs;
	int	i;

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
	(mxGetPr(plhs[0]))[0] = (double) pvm_config(&nhost,&narch,&hostp);

	plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL);
	(mxGetPr(plhs[1]))[0] = (double) nhost;

	plhs[2] = mxCreateDoubleMatrix(1,1,mxREAL);
	(mxGetPr(plhs[2]))[0] = (double) narch;

	plhs[3] = mxCreateDoubleMatrix(nhost,1,mxREAL);		
	dtids = mxGetPr(plhs[3]);
	hosts = (const char**) mxCalloc(nhost,sizeof(char*));
	archs = (const char**) mxCalloc(nhost,sizeof(char*));
	plhs[6] = mxCreateDoubleMatrix(nhost,1,mxREAL);	
	speeds = mxGetPr(plhs[6]);

	for (i=0; i<nhost; i++) {
		dtids[i] = (double) (hostp[i].hi_tid);
		hosts[i] = hostp[i].hi_name;
		archs[i] = hostp[i].hi_arch;
		speeds[i] = (double) (hostp[i].hi_speed);
	}

	plhs[4]=mxCreateCharMatrixFromStrings(nhost,hosts);
	plhs[5]=mxCreateCharMatrixFromStrings(nhost,archs);

#endif
	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_tasks(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
#ifdef M4
        int     where;
        int     ntask;
        struct  pvmtaskinfo *taskp;
        double  *tids, *ptids, *dtids, *flags;
        char    **aouts;
        int     i;

        where = (int) mxGetScalar(prhs[0]);

        plhs[0] = mxCreateFull(1,1,REAL);
        (mxGetPr(plhs[0]))[0] = (double) pvm_tasks(where,&ntask,&taskp);

        plhs[1] = mxCreateFull(1,1,REAL);
        (mxGetPr(plhs[1]))[0] = (double) ntask;

        plhs[2] = mxCreateFull(ntask,1,REAL);           /* tids */
        tids = mxGetPr(plhs[2]);
        plhs[3] = mxCreateFull(ntask,1,REAL);           /* ptids */
        ptids = mxGetPr(plhs[3]);
        plhs[4] = mxCreateFull(ntask,1,REAL);           /* dtids */
        dtids = mxGetPr(plhs[4]);
        plhs[5] = mxCreateFull(ntask,1,REAL);           /* flags */
        flags = mxGetPr(plhs[5]);
        aouts = (char**) mxCalloc(ntask,sizeof(char*)); /* names of tasks */

        for (i=0; i<ntask; i++) {
                tids[i] = (double) (taskp[i].ti_tid);
                ptids[i] = (double) (taskp[i].ti_ptid);
                dtids[i] = (double) (taskp[i].ti_host);
                flags[i] = (double) (taskp[i].ti_flag);
                aouts[i] = taskp[i].ti_a_out;
        }

        if ( str2strmat(aouts,ntask,&plhs[6]) )
                mexErrMsgTxt("m2pvm_tasks(): str2strmat() failed.");

#else
	int	where;
	int	ntask;
	struct	pvmtaskinfo *taskp;
	double	*tids, *ptids, *dtids, *flags;
	const char	**aouts;
	int	i;

	where = (int) mxGetScalar(prhs[0]);

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
	(mxGetPr(plhs[0]))[0] = (double) pvm_tasks(where,&ntask,&taskp);

	plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL);
	(mxGetPr(plhs[1]))[0] = (double) ntask;

	plhs[2] = mxCreateDoubleMatrix(ntask,1,mxREAL);		/* tids */
	tids = mxGetPr(plhs[2]);
	plhs[3] = mxCreateDoubleMatrix(ntask,1,mxREAL);		/* ptids */
	ptids = mxGetPr(plhs[3]);
	plhs[4] = mxCreateDoubleMatrix(ntask,1,mxREAL);		/* dtids */
	dtids = mxGetPr(plhs[4]);
	plhs[5] = mxCreateDoubleMatrix(ntask,1,mxREAL);		/* flags */
	flags = mxGetPr(plhs[5]);
	aouts = (const char**) mxCalloc(ntask,sizeof(char*));	/* names of tasks */

	for (i=0; i<ntask; i++) {
		tids[i] = (double) (taskp[i].ti_tid);
		ptids[i] = (double) (taskp[i].ti_ptid);
		dtids[i] = (double) (taskp[i].ti_host);
		flags[i] = (double) (taskp[i].ti_flag);
		aouts[i] = taskp[i].ti_a_out;
	}

	plhs[6] = mxCreateCharMatrixFromStrings(ntask,aouts);

#endif
	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_tidtohost(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	int	tid;

	tid = (int) mxGetScalar(prhs[0]);

	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	mxGetPr(plhs[0])[0] = (double) pvm_tidtohost(tid);

 	return;
}

/*-------------------------------------------------------------------*/
void m2pvm_perror(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	char	*msg;
	int	strl;

	strl = mxGetN(prhs[0])+1;
	msg  = (char*) mxCalloc(strl,sizeof(char));
	if ( mxGetString(prhs[0],msg,strl) )
		mexErrMsgTxt("m2pvm_perror(): mxGetString() failed");

	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	mxGetPr(plhs[0])[0] = (double) pvm_perror(msg);

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_archcode(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	char	*arch;
	int	strl;

	strl = mxGetN(prhs[0])+1;
	arch = (char*) mxCalloc(strl,sizeof(char));
	if ( mxGetString(prhs[0],arch,strl) )
		mexErrMsgTxt("m2pvm_archcode(): mxGetString() failed");

	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	mxGetPr(plhs[0])[0] = (double) pvm_archcode(arch);

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_getfds(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
#ifdef M4
        int     nfds;
        int     *fds;

        nfds = pvm_getfds(&fds);

        plhs[0]=mxCreateFull(1,1,REAL);
        mxGetPr(plhs[0])[0] = (double) nfds;

        int2mat(fds,nfds,&plhs[1]);

#else
	int	nfds, i;
	int	*fds;

	nfds =  pvm_getfds(&fds);

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
	mxGetPr(plhs[0])[0] = (double) nfds;

        plhs[1] = mxCreateDoubleMatrix(nfds,1,mxREAL);
	for (i=0; i< nfds; i++)
		mxGetPr(plhs[1])[i] = (double)  fds[i];

#endif
	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_version(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	const char	*ver;

	ver = pvm_version();

	if ( str2strmat(&ver,1,&plhs[0]) )
		mexErrMsgTxt("m2pvm_version(): str2strmat() failed.");

	return;
}


/************************************************************************
 * 	 								*
 * Signaling 								*
 * 	 								*
 ************************************************************************/
 
/*-------------------------------------------------------------------*/
void m2pvm_sendsig(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	int	tid, signum;

	tid    = (int) mxGetScalar(prhs[0]);
	signum = (int) mxGetScalar(prhs[1]);

	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	mxGetPr(plhs[0])[0] = pvm_sendsig(tid, signum);

	return;
}

/*-------------------------------------------------------------------*/
void m2pvm_notify(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
#ifdef M4
        int     what, msgtag, cnt, trash;
        int     *tids=NULL;

        what   = (int) mxGetScalar(prhs[0]);
        msgtag = (int) mxGetScalar(prhs[1]);
        cnt    = (int) mxGetScalar(prhs[2]);
        if ( mat2int(prhs[3],&tids,&trash) )
                mexErrMsgTxt("m2pvm_notify(): mat2int() failed.");
        
        plhs[0]=mxCreateFull(1,1,REAL);

        mxGetPr(plhs[0])[0] = (double) pvm_notify(what,msgtag,cnt,tids);

#else
	int	what, msgtag, cnt, trash, i;
	int	*tids=NULL;

	what   = (int) mxGetScalar(prhs[0]);
	msgtag = (int) mxGetScalar(prhs[1]);
	cnt    = (int) mxGetScalar(prhs[2]);

        trash = mxGetM(prhs[3]) * mxGetN(prhs[3]);
        tids  = mxCalloc(trash,sizeof(int));

	for (i=0; i< trash; i++)
	    tids[i] = (int) mxGetPr(prhs[3])[i];
	
	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	mxGetPr(plhs[0])[0] = (double) pvm_notify(what,msgtag,cnt,tids);
	
#endif
	return;
}


/************************************************************************
 * 	 								*
 *  Message Buffers							*
 * 	 								*
 ************************************************************************/

/*-------------------------------------------------------------------*/
void m2pvm_initsend(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	int	encoding;

	encoding=(int)mxGetScalar(prhs[0]);

	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	(mxGetPr(plhs[0]))[0]=(double)pvm_initsend(encoding);

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_mkbuf(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	int	encoding;

	encoding=(int)mxGetScalar(prhs[0]);

	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	(mxGetPr(plhs[0]))[0]=(double)pvm_mkbuf(encoding);

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_freebuf(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	(mxGetPr(plhs[0]))[0]=(double)pvm_freebuf((int)mxGetScalar(prhs[0]));

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_getsbuf(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	(mxGetPr(plhs[0]))[0]=(double)pvm_getsbuf();

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_getrbuf(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	(mxGetPr(plhs[0]))[0]=(double)pvm_getrbuf();

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_setsbuf(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	(mxGetPr(plhs[0]))[0]=pvm_setsbuf((int)mxGetScalar(prhs[0]));

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_setrbuf(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	(mxGetPr(plhs[0]))[0]=pvm_setrbuf((int)mxGetScalar(prhs[0]));

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_bufinfo(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	int	bufid, bytes, msgtag, tid;

	bufid = (int) mxGetScalar(prhs[0]);

	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	mxGetPr(plhs[0])[0] = (double) pvm_bufinfo(bufid,&bytes,&msgtag,&tid);

	plhs[1]=mxCreateDoubleMatrix(1,1,mxREAL);
	mxGetPr(plhs[1])[0] = (double) bytes;

	plhs[2]=mxCreateDoubleMatrix(1,1,mxREAL);
	mxGetPr(plhs[2])[0] = (double) msgtag;

	plhs[3]=mxCreateDoubleMatrix(1,1,mxREAL);
	mxGetPr(plhs[3])[0] = (double) tid;

	return;
}


/************************************************************************
 * 	 								*
 * Packing and Unpacking Data						*
 * 	 								*
 ************************************************************************/

/*-------------------------------------------------------------------*/
void m2pvm_pkdouble(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	double	*dp;
	int	nitem,stride;

	dp     = mxGetPr(prhs[0]);
	nitem  = (int) mxGetScalar(prhs[1]);
	stride = (int) mxGetScalar(prhs[2]);
	
	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

	mxGetPr(plhs[0])[0] = (double) pvm_pkdouble(dp,nitem,stride);

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_upkdouble(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	int	nitem,stride;
	double	*dp;

	nitem  = (int) mxGetScalar(prhs[0]);
	stride = (int) mxGetScalar(prhs[1]);
	
	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

	plhs[1] = mxCreateDoubleMatrix(nitem,1,mxREAL);
	dp = mxGetPr(plhs[1]);

	mxGetPr(plhs[0])[0] = (double) pvm_upkdouble(dp,nitem,stride);

	return;
}


/*-------------------------------------------------------------------*/
/*
void m2pvm_pkint(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {

	int	*intarray, nitem, stride;

implementation from Binh;
the following cast isn't a
solution for platforms where
sizeof(double) and sizeof(int)
are different
	intarray = (int *) mxGetPr(prhs[0]);
	nitem    = (int) mxGetScalar(prhs[1]);
	stride   = (int) mxGetScalar(prhs[2]);
	
	plhs[0]  = mxCreateDoubleMatrix(1,1,mxREAL);

	mxGetPr(plhs[0])[0] = (double) pvm_pkint(intarray,nitem,stride);

	return;
}
*/
/*-------------------------------------------------------------------*/

/* the following routine is not extremely fast due to that the integer
 * reply is cast into double before sent back to Matlab.
 */
/* Implementation by E. Svahn Nov 2000 */
void m2pvm_upkint(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
	int	nitem,stride,i;
 	int	*ip;
	double  *dp;

	nitem  = (int) mxGetScalar(prhs[0]);
 	stride = (int) mxGetScalar(prhs[1]);
	
 	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

 	plhs[1] = mxCreateDoubleMatrix(nitem,1,mxREAL);
	
 	dp = (double *) mxGetPr(plhs[1]);

	ip = mxCalloc(nitem, sizeof(int));
 	if (ip==0) 
	  mexErrMsgTxt("m2pvm_upkint: mxCalloc failed");
	
	mxGetPr(plhs[0])[0] = (double) pvm_upkint(ip,nitem,stride);
	for (i=0; i<nitem ; i++) {
	  mxGetPr(plhs[1])[i] = (double) ip[i];
	}
	mxFree(ip); 
	
 	return;
}


/*-------------------------------------------------------------------*/
/*
void m2pvm_upkstr(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
	char	*str;
        int      len;

implementation from Binh;
it isn't a 1 by 1 mapping
onto pvm_upkstr(PVM3)
        if ((pvm_upkint(&len,1,1)) < 0)
	    mexErrMsgTxt("m2pvm_upkstr(): pvm_upkint() failed.");

        str = mxCalloc(len,sizeof(char));

        if ((pvm_upkstr(str)) < 0)
	    mexErrMsgTxt("m2pvm_upkstr(): pvm_upkstr() failed.");

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

        plhs[0] = mxCreateString(str);
         
	return;
}
*/
/*-------------------------------------------------------------------*/


/*-------------------------------------------------------------------*/
/*
void m2pvm_pkstr(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
	char	*str;
        int      trash, info;

        trash = (mxGetM(prhs[0]) * mxGetN(prhs[0])) +1;
        str = mxCalloc(trash,sizeof(char));
  	mxGetString(prhs[0],str,trash);

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

implementation from Binh;
it isn't a 1 by 1 mapping
onto pvm_pkstr(PVM3)
        if ( (info = pvm_pkint( &trash,1 ,1)) < 0)
	    mexErrMsgTxt("m2pvm_pkstr(): pvm_pkint() failed.");

        if ( (info = pvm_pkstr(str)) < 0)
	    mexErrMsgTxt("m2pvm_pkstr(): pvm_pkstr() failed.");

	mxGetPr(plhs[0])[0] = (double) info;
   
	return;
}
*/
/*-------------------------------------------------------------------*/


/************************************************************************
 * 	 								*
 * Sending and Receiving						*
 * 	 								*
 ************************************************************************/

/*-------------------------------------------------------------------*/
void m2pvm_send(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	int	tid, msgtag;

	tid    = (int) mxGetScalar(prhs[0]);
	msgtag = (int) mxGetScalar(prhs[1]);

	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	(mxGetPr(plhs[0]))[0] = (double) pvm_send(tid,msgtag);

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_mcast(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
#ifdef M4
        int     *tids;
        int     ntask,msgtag;

        if ( mat2int(prhs[0],&tids,&ntask) )
                mexErrMsgTxt("m2pvm_mcast(): mat2int() failed.");

        msgtag = (int) mxGetScalar(prhs[1]);

        plhs[0]=mxCreateFull(1,1,REAL);

        mxGetPr(plhs[0])[0] = (double) pvm_mcast(tids,ntask,msgtag);

#else
	int	*tids;
	int	ntask, msgtag, i;

        ntask = mxGetM(prhs[0]) * mxGetN(prhs[0]);
        tids  = mxCalloc(ntask,sizeof(int));

	for (i=0; i< ntask; i++)
	    tids[i] = (int) mxGetPr(prhs[0])[i];

	msgtag = (int) mxGetScalar(prhs[1]);

	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	(mxGetPr(plhs[0]))[0] = (double) pvm_mcast(tids,ntask,msgtag);
	
#endif
	return;
}


#ifndef WIN32
#include <signal.h>
#endif
/*-------------------------------------------------------------------*/
void m2pvm_recv(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
#ifndef WIN32
	/* direct linkage to pvm_recv with signal handling */
	int		tid, msgtag, info=0;

	sigset_t	newmask, oldmask, pendmask;
	struct timeval	tmout;

	tid    = (int) mxGetScalar(prhs[0]);
	msgtag = (int) mxGetScalar(prhs[1]);

	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	sigemptyset(&oldmask); /*added by ES*/
	sigemptyset(&newmask);
	sigaddset(&newmask,SIGINT);
	/* block SIGINT and save current signal mask */
	if ( sigprocmask(SIG_BLOCK, &newmask, &oldmask) < 0 ) {
		mexErrMsgTxt("sigprocmask() failed.\n");
	}
   
	tmout.tv_sec  = 1;
	tmout.tv_usec = 0;

	while ( info == 0 ) {

		info = pvm_trecv(tid,msgtag,&tmout);

		if ( sigpending(&pendmask) < 0 ) {
			mexErrMsgTxt("sigpending() failed.\n");
		}
		if ( sigismember(&pendmask, SIGINT) ) {
			break;
		}
	}

	/* reset signal mask which unblocks SIGINT */
	/*	if ( sigprocmask(SIG_SETMASK, &oldmask, NULL) ) { */
	/* the above line is replaced by the following, E. Svahn */
	if ( sigprocmask(SIG_SETMASK, &oldmask, &newmask) ) {
		mexErrMsgTxt("sigprocmask() failed.\n");
	}

	mxGetPr(plhs[0])[0] = (double) info;

#else
	/* direct linkage to pvm_recv without any signal handling */
	int	tid, msgtag;

	tid    = (int) mxGetScalar(prhs[0]);
	msgtag = (int) mxGetScalar(prhs[1]);

	plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	mxGetPr(plhs[0])[0] = (double) pvm_recv(tid,msgtag);

#endif
	return;
}


#ifndef WIN32
#include <signal.h>
#endif
/*-------------------------------------------------------------------*/
void m2pvm_trecv ( int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[] ) {
/*-------------------------------------------------------------------*/
#ifndef WIN32
	/* direct linkage to pvm_trecv with signal handling */
        int             tid, msgtag, info=0;

        long            tmrest;
        sigset_t        newmask, oldmask, pendmask;
        struct timeval  tmout;

        tid           = (int)  mxGetScalar(prhs[0]);
        msgtag        = (int)  mxGetScalar(prhs[1]);
        tmout.tv_sec  = (long) mxGetScalar(prhs[2]);
        tmout.tv_usec = (long) mxGetScalar(prhs[3]);

        plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

	sigemptyset(&oldmask); /*added by ES*/
        sigemptyset(&newmask);
        sigaddset(&newmask,SIGINT);
        /* block SIGINT and save current signal mask */
        if ( sigprocmask(SIG_BLOCK, &newmask, &oldmask) < 0 ) {
                mexErrMsgTxt("sigprocmask() failed.\n");
        }
   
        if ( tmout.tv_sec < 1 ) {

                info = (double) pvm_trecv(tid,msgtag,&tmout);
        }
        else {

                tmrest        = tmout.tv_sec;
                tmout.tv_sec  = 1;
                tmout.tv_usec = 0;

                while ( info == 0  &&  tmrest > 0 ) {

                        info = pvm_trecv(tid,msgtag,&tmout);

                        tmrest = tmrest - tmout.tv_sec;

                        if ( sigpending(&pendmask) < 0 ) {
                                mexErrMsgTxt("sigpending() failed.\n");
                        }
                        if ( sigismember(&pendmask, SIGINT) ) {
                                break;
                        }
                }
        }

        /* reset signal mask which unblocks SIGINT */
	/*        if ( sigprocmask(SIG_SETMASK, &oldmask, NULL) ) {*/
        if ( sigprocmask(SIG_SETMASK, &oldmask, &newmask) ) {
                mexErrMsgTxt("sigprocmask() failed.\n");
        }

        mxGetPr(plhs[0])[0] = (double) info;

#else
	/* direct linkage to pvm_trecv without any signal handling */
        int             tid, msgtag;
        struct timeval  tmout;

        tid           = (int)  mxGetScalar(prhs[0]);
        msgtag        = (int)  mxGetScalar(prhs[1]);
        tmout.tv_sec  = (long) mxGetScalar(prhs[2]);
        tmout.tv_usec = (long) mxGetScalar(prhs[3]);

        plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

        mxGetPr(plhs[0])[0] = (double) pvm_trecv(tid,msgtag,&tmout);

#endif
        return;
}


/*-------------------------------------------------------------------*/
void m2pvm_nrecv(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	int	tid, msgtag;

	tid    = (int) mxGetScalar(prhs[0]);
	msgtag = (int) mxGetScalar(prhs[1]);

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

	(mxGetPr(plhs[0]))[0] = (double) pvm_nrecv(tid,msgtag);

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_probe(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	int	tid, msgtag;

	tid    = (int) mxGetScalar(prhs[0]);
	msgtag = (int) mxGetScalar(prhs[1]);

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

	(mxGetPr(plhs[0]))[0] = (double) pvm_probe(tid,msgtag);

	return;
}


/************************************************************************
 * 	 								*
 * Master Pvmd Data Base 						*
 * 	 								*
 ************************************************************************/

/*-------------------------------------------------------------------*/
void m2pvm_putinfo(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
        char    *name;
        int     namelen;
        int     bufid;
        int     flags;

        namelen = mxGetN(prhs[0]) +1;
        name    = mxCalloc(namelen,sizeof(char));
        mxGetString(prhs[0],name,namelen);

        bufid = (int) mxGetScalar(prhs[1]);

        flags = (int) mxGetScalar(prhs[2]);

        plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

        (mxGetPr(plhs[0]))[0] = (double) pvm_putinfo(name,bufid,flags);

        return;
}


/*-------------------------------------------------------------------*/
void m2pvm_recvinfo(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
        char    *name;
        int     namelen;
        int     index;
        int     flags;

        namelen = mxGetN(prhs[0]) +1;
        name    = mxCalloc(namelen,sizeof(char));
        mxGetString(prhs[0],name,namelen);

        index = (int) mxGetScalar(prhs[1]);

        flags = (int) mxGetScalar(prhs[2]);

        plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

        (mxGetPr(plhs[0]))[0] = (double) pvm_recvinfo(name,index,flags);

        return;
}


/*-------------------------------------------------------------------*/
void m2pvm_delinfo(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
        char    *name;
        int     namelen;
        int     index;
        int     flags;

        namelen = mxGetN(prhs[0]) +1;
        name    = mxCalloc(namelen,sizeof(char));
        mxGetString(prhs[0],name,namelen);

        index = (int) mxGetScalar(prhs[1]);

        flags = (int) mxGetScalar(prhs[2]);

        plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

        (mxGetPr(plhs[0]))[0] = (double) pvm_delinfo(name,index,flags);

        return;
}


/*-------------------------------------------------------------------*/
void m2pvm_getmboxinfo(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
  /* implementation from A. Westphal - not ready
   * Modified by E. Svahn Nov 2000 - Working!
  */
        char    *pattern;
        int     nclasses;
        struct pvmmboxinfo *classes;
        char **mi_name;                   /* class name */
        double  *mi_nentries;             /* # of entries for this class */
        mxArray  *mi_indices;             /* mbox entry indices */
        mxArray  *mi_owners;              /* mbox entry owner tids */
        mxArray  *mi_flags;               /* mbox entry flags */
        mxArray  *vector_ptr;
        int     trash,i,n,dims[2];

        trash = (mxGetM(prhs[0]) * mxGetN(prhs[0])) +1;
        pattern = mxCalloc(trash, sizeof(char));
        mxGetString(prhs[0],pattern,trash);

        /* info, pvm_getmboxinfo() */
        plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
        (mxGetPr(plhs[0]))[0] = (double) pvm_getmboxinfo(pattern,&nclasses,
							 &classes);

        /* number of classes */
        plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL);
        (mxGetPr(plhs[1]))[0] = (double) nclasses;

        /* names of classes */
        mi_name = (char**) mxCalloc(nclasses,sizeof(char*));

        /* number of entries for each class */
        plhs[3] = mxCreateDoubleMatrix(nclasses,1,mxREAL);      
        mi_nentries = mxGetPr(plhs[3]);

        /* create cell arrays*/
        dims[0]=nclasses;
        dims[1]=1;

        /* mbox entry indices */
        mi_indices = mxCreateCellArray(2, dims); 

        /* mbox entry owner tids */
       	mi_owners = mxCreateCellArray(2, dims); 

        /* mbox entry flags */
	mi_flags = mxCreateCellArray(2, dims); 

        /* put data from struct into arrays */
        dims[1]=0;
        for(i=0; i<nclasses; i++) {
                /* classes */
                mi_name[i] = classes[i].mi_name;
                /* entries */
                mi_nentries[i] = (double) classes[i].mi_nentries;

                /* cell arrays common */
                dims[0]=i;
		/* indices */
		vector_ptr = mxCreateDoubleMatrix(1,classes[i].mi_nentries,mxREAL);
		for(n=0; n<classes[i].mi_nentries ; n++) {
		  (mxGetPr(vector_ptr))[n] = (double) classes[i].mi_indices[n];
		}
		trash = mxCalcSingleSubscript(mi_indices, 2, dims);
                mxSetCell(mi_indices, trash, vector_ptr);
		/* owners */
		vector_ptr = mxCreateDoubleMatrix(1,classes[i].mi_nentries,mxREAL);
		for(n=0; n<classes[i].mi_nentries ; n++) {
		  (mxGetPr(vector_ptr))[n] = (double) classes[i].mi_owners[n];
		}
		trash = mxCalcSingleSubscript(mi_indices, 2, dims);
                mxSetCell(mi_owners, trash, vector_ptr);
                /* flags */
		vector_ptr = mxCreateDoubleMatrix(1,classes[i].mi_nentries,mxREAL);
		for(n=0; n<classes[i].mi_nentries ; n++) {
		  (mxGetPr(vector_ptr))[n] = (double) classes[i].mi_flags[n];
		}
		trash = mxCalcSingleSubscript(mi_indices, 2, dims);
                mxSetCell(mi_flags, trash, vector_ptr);
        }

        plhs[2] = mxCreateCharMatrixFromStrings(nclasses,(const char **)mi_name);
        plhs[4] = mi_indices;
        plhs[5] = mi_owners; 
        plhs[6] = mi_flags; 
        return;
}


/************************************************************************
 * 	 								*
 * Group Functions	  						*
 *									*
 * from Binhs dp898 version;						*
 * currently not in use							*
 * 	 								*
 ************************************************************************/

#if 0
/*-------------------------------------------------------------------*/
void m2pvm_joingroup(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	char	*group_name;
	int	 trash;

        if ( nrhs != 1 )
            mexErrMsgTxt("Only 1 input argument expected. ");
  
        if (!mxIsChar(prhs[0]))
            mexErrMsgTxt("A string expected at input argument.");     

        trash = (mxGetM(prhs[0]) * mxGetN(prhs[0])) +1;
        group_name = mxCalloc(trash, sizeof(char));
	mxGetString(prhs[0],group_name,trash);
       
        if (nlhs) {
            plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
            (mxGetPr(plhs[0]))[0] = (double) pvm_joingroup(group_name);
        }
        else
            pvm_joingroup(group_name);

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_lvgroup(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	char	*group_name;
	int	 trash;


        if ( nrhs != 1 )
            mexErrMsgTxt("Only 1 input argument expected. ");

        if (!mxIsChar(prhs[0]))
            mexErrMsgTxt("A string expected at input argument.");     


        trash = (mxGetM(prhs[0]) * mxGetN(prhs[0])) +1;
        group_name = mxCalloc(trash, sizeof(char));
	mxGetString(prhs[0],group_name,trash);

        if (nlhs) {
	    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
	    (mxGetPr(plhs[0]))[0] = (double) pvm_lvgroup(group_name);
        }
        else
            pvm_lvgroup(group_name);

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_getinst(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	char	*group_name;
	int	 trash, tid;
        

        if ( nrhs != 2 )
            mexErrMsgTxt("Two input arguments expected. ");

        if (!mxIsChar(prhs[0]))
            mexErrMsgTxt("A string expected at input argument.");     

        trash = (mxGetM(prhs[0]) * mxGetN(prhs[0])) +1;
        group_name = mxCalloc(trash, sizeof(char));
	mxGetString(prhs[0],group_name,trash);

        tid = (int)mxGetScalar(prhs[1]);

        if (nlhs) {
	    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
	    (mxGetPr(plhs[0]))[0] = (double) pvm_getinst(group_name, tid);
        }
        else
            pvm_getinst(group_name, tid);

	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_gsize(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	char	*group_name;
	int	 trash;
        

        if ( nrhs != 1 )
            mexErrMsgTxt("Only 1 input argument expected. ");

        if (!mxIsChar(prhs[0]))
            mexErrMsgTxt("A string expected at input argument.");     

        trash = (mxGetM(prhs[0]) * mxGetN(prhs[0])) +1;
        group_name = mxCalloc(trash, sizeof(char));
	mxGetString(prhs[0],group_name,trash);

        if (nlhs == 1) {
	    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
	    (mxGetPr(plhs[0]))[0] = (double) pvm_gsize(group_name);
        }
        else
            mexErrMsgTxt("Only 1 output argument expected. ");

	return;
}



/*-------------------------------------------------------------------*/
void m2pvm_gettid(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	char	*group_name;
	int	 trash, inum;
        

        if ( nrhs != 2 )
            mexErrMsgTxt("Two input arguments expected. ");

        if (!mxIsChar(prhs[0]))
            mexErrMsgTxt("A string expected at input argument.");     

        trash = (mxGetM(prhs[0]) * mxGetN(prhs[0])) +1;
        group_name = mxCalloc(trash, sizeof(char));
	mxGetString(prhs[0],group_name,trash);

        inum = (int)mxGetScalar(prhs[1]);

        if (nlhs) {
	    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
	    (mxGetPr(plhs[0]))[0] = (double) pvm_gettid(group_name, inum);
        }
        else
            mexErrMsgTxt("Only 1 output argument expected. ");
            
	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_gids(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	char	*group_name;
	int	 trash, inum, i;
        

        if ( nrhs != 1 )
            mexErrMsgTxt("Only one input argument expected. ");

        if (!mxIsChar(prhs[0]))
            mexErrMsgTxt("A string expected at input argument.");     

        trash = (mxGetM(prhs[0]) * mxGetN(prhs[0])) +1;
        group_name = mxCalloc(trash, sizeof(char));
	mxGetString(prhs[0],group_name,trash);

        inum = pvm_gsize(group_name);

        if (nlhs == 1) {
	    plhs[0] = mxCreateDoubleMatrix(1,inum, mxREAL);
            for (i=0; i < inum; i++) 
	       (mxGetPr(plhs[0]))[i] = (double) pvm_gettid(group_name, i);
        }
        else
            mexErrMsgTxt("Only 1 output argument expected. ");
            
	return;
}


/*-------------------------------------------------------------------*/
void m2pvm_barrier(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	char	*group_name;
	int	 trash, count;
        

        if ( nrhs > 2 )
            mexErrMsgTxt("Two input arguments expected. ");

        if (!mxIsChar(prhs[0]))
            mexErrMsgTxt("A string expected at input argument.");     

        trash = (mxGetM(prhs[0]) * mxGetN(prhs[0])) +1;
        group_name = mxCalloc(trash, sizeof(char));
	mxGetString(prhs[0],group_name,trash);

        /* check that second argument is numeric */
        if ( nrhs == 2) {
            if (!mxIsNumeric(prhs[1]))
                mexErrMsgTxt("The 2nd argument must be a numeric vector.");
            count = mxGetScalar( prhs[1] );
        } else
            count=pvm_gsize(group_name);

	plhs[0] = mxCreateDoubleMatrix(1,1, mxREAL);
	(mxGetPr(plhs[0]))[0] = (double) pvm_barrier(group_name, count);
            
	return;
}
#endif


