/*
 * wrapper for libpvme routines
 *
 * Copyright (c) 1995-1999 University of Rostock, Germany,
 * Institute of Automatic Control. All rights reserved.
 *
 * See file ``Copyright'' for terms of copyright.
 *
 * Authors: S. Pawletta, A. Westphal
 *
 */

/* patched by J. Ditterich for compatibility with MATLAB R13 */

#define V5_COMPAT /* V5 compatibility mode */

#define PM /* for PM Toolbox */
#ifndef TMP_LOC
#define TMP_LOC "/tmp"
#endif

#include "m2libpvme.h"

#include <stdio.h>
#include <pvm3.h>
#include "pvme.h"
#include "misc.h"
#include "mat.h"  /* added by E. Svahn */

/************************************************************************
 * 	 								*
 * PVM Control 								*
 * 	 								*
 ************************************************************************/

/*-------------------------------------------------------------------*/
void m2pvme_is(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

	mxGetPr(plhs[0])[0] = (double) pvme_is();

	return;
}


/*-------------------------------------------------------------------*/
void m2pvme_default_config(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
        int     conf_lines;
        char	**conf;

	if ( strmat2str(prhs[0],&conf,&conf_lines) ) 
		mexErrMsgTxt("m2pvme_default_config(): strmat2str() failed.\n");
	
        plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL);

        (mxGetPr(plhs[0]))[0] = (double) pvme_default_config(conf_lines,conf);

        return;
}


/*-------------------------------------------------------------------*/
void m2pvme_start_pvmd(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
	int		 argc;
	char		**argv;
	int		block;
	
        if ( strmat2str(prhs[0],&argv,&argc) )
                mexErrMsgTxt("m2pvme_start_pvmd(): strmat2str failed.\n");
        block = (int) mxGetScalar(prhs[1]);

        plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

	(mxGetPr(plhs[0]))[0] = (double) pvme_start_pvmd(argc,argv,block);
	
	return;
}

 
/*-------------------------------------------------------------------*/
void m2pvme_halt(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

	mxGetPr(plhs[0])[0] = (double) pvme_halt();

	return;
}


/************************************************************************
 * 	 								*
 * Packing and Unpacking Data						*
 * 	 								*
 ************************************************************************/

#ifdef M4
/*-------------------------------------------------------------------*/
void m2pvme_pkmat(int nlhs, Matrix *plhs[], int nrhs, Matrix *prhs[]) {
/*-------------------------------------------------------------------*/
        char *name;
        int  strl;

        strl = mxGetN(prhs[1])+1;
        if ( !( name = (char*) mxCalloc(strl,sizeof(char)) ) )
                mexErrMsgTxt("m2pvme_pkmat(): mxCalloc() failed.\n");
        if ( mxGetString(prhs[1],name,strl))
                mexErrMsgTxt("m2pvme_pkmat(): mxGetString() failed.\n");

        plhs[0] = mxCreateFull(1,1,REAL);

        (mxGetPr(plhs[0]))[0] = (double) pvme_pkmat_bypass(prhs[0],name);

        return;
}


/*-------------------------------------------------------------------*/
void m2pvme_upkmat(int nlhs, Matrix *plhs[], int nrhs, Matrix *prhs[]) {
/*-------------------------------------------------------------------*/
        const char *mat_name;

        plhs[2] = mxCreateFull(1,1,REAL);

        (mxGetPr(plhs[2]))[0] = (double) pvme_upkmat(&plhs[0]);

        mat_name = mxGetName(plhs[0]);

        if ( !( plhs[1] = mxCreateString(mat_name) ) ) 
                mexErrMsgTxt("m2pvme_upkmat(): mxCreateString() failed.\n");

        return;
}


/*-------------------------------------------------------------------*/
void m2pvme_upkmat_name(int nlhs, Matrix *plhs[], int nrhs, Matrix *prhs[]) {
/*-------------------------------------------------------------------*/
        char mat_name[mxMAXNAM];

        plhs[1] = mxCreateFull(1,1,REAL);

        (mxGetPr(plhs[1]))[0] = (double) pvme_upkmat_name(mat_name);

        if ( !( plhs[0] = mxCreateString(mat_name) ) ) 
               mexErrMsgTxt("m2pvme_upkmat_name(): mxCreateString() failed.\n");

        return;
}


/*-------------------------------------------------------------------*/
void m2pvme_upkmat_rest(int nlhs, Matrix *plhs[], int nrhs, Matrix *prhs[]) {
/*-------------------------------------------------------------------*/

        plhs[1] = mxCreateFull(1,1,REAL);

        (mxGetPr(plhs[1]))[0] = (double) pvme_upkmat_rest(&plhs[0],(char*)0);

        return;
}


#else /* M5 */
/*-------------------------------------------------------------------*/
void m2pvme_pkarray(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
        char *name;
        int  strl;
		  mxArray   *array_ptr;

        strl = mxGetN(prhs[1])+1;
        if ( !( name = (char*) mxCalloc(strl,sizeof(char)) ) )
                mexErrMsgTxt("m2pvme_pkarray(): mxCalloc() failed.\n");
        if ( mxGetString(prhs[1],name,strl))
                mexErrMsgTxt("m2pvme_pkarray(): mxGetString() failed.\n");

        plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
		   array_ptr = (mxArray*) prhs[0];
		   mxSetName(array_ptr, name);

        (mxGetPr(plhs[0]))[0] = (double) pvme_pkarray(array_ptr);

        return;
}


/*-------------------------------------------------------------------*/
void m2pvme_upkarray(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
        const char *mat_name;

        plhs[2] = mxCreateDoubleMatrix(1,1,mxREAL);

        (mxGetPr(plhs[2]))[0] = (double) pvme_upkarray(&plhs[0]);

        mat_name = mxGetName(plhs[0]);

        if ( !( plhs[1] = mxCreateString(mat_name) ) ) 
                mexErrMsgTxt("m2pvme_upkarray(): mxCreateString() failed.\n");

	return;
}


/*-------------------------------------------------------------------*/
void m2pvme_upkarray_name(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
        char mat_name[mxMAXNAM];

        plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL);

        (mxGetPr(plhs[1]))[0] = (double) pvme_upkarray_name(mat_name);

        if ( !( plhs[0] = mxCreateString(mat_name) ) ) 
                mexErrMsgTxt("m2pvme_upkarray_name(): mxCreateString() failed.\n");

	return;
}


/* Modified by E. Svahn Nov 2000 as a temporary solution for transferring 
   Matlab user defined objects. */
/*-------------------------------------------------------------------*/
void m2pvme_upkarray_rest(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

  MATFile *pmat;
  char fname[256];
  mxArray *array_ptr;

  plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL);
  if((mxGetPr(plhs[1]))[0] = (double) pvme_upkarray_rest(&plhs[0],(char*)0)==1) {
  
    /* the data contains Matlab user defined objects! */

    /* save and load this mxArray so as it will be recognized as an object */

    /*
 object passing could be done by getting a default object from the workspace
 and then constructing the object in the workspace directly by using
 mxPutArray with each struct for each level...
	*/
	/*	
  array_ptr = mexGetArray("def","base");
  mxSetName(array_ptr, "defcopy");
  mexPutArray(array_ptr, "base");
  mxDestroyArray(array_ptr);
	*/
	  
    sprintf(fname,"%s/dp_%d.mat",TMP_LOC,pvm_mytid());
    /*printf(fname,"%s/dp_%d.mat",TMP_LOC,pvm_mytid());*/
  
    pmat = matOpen(fname, "w");
    if (pmat == NULL) {
      mexErrMsgTxt("m2libpvme:Error creating file for transferring object\n");
    }
    mxSetName(plhs[0], "objsl");
    
    if (matPutArray(pmat, plhs[0]) != 0) {
      mexErrMsgTxt("m2libpvme:m2pvme_upkarray_rest: Error saving temporary intermediate file for objects\n"); 
    } 
    
    if (matClose(pmat) != 0) {
      mexErrMsgTxt("m2libpvme:m2pvme_upkarray_rest:Error temporary intermediate file for object transfer\n");
    }
    
    
    /*  printf("class::::%s\n", mxGetClassName(plhs[0]));*/
    
    if ( !( plhs[0] = mxCreateString(fname) ) ) 
      mexErrMsgTxt("m2pvme_upkarray_rest(): mxCreateString() failed.\n");
    
  }
  return;
}

#endif /* M4/M5 */

 
/************************************************************************
 * 	 								*
 * Process Control							*
 * 	 								*
 ************************************************************************/

#ifndef M4
/*-------------------------------------------------------------------*/
void m2pvme_spawn(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/
 
	char	*task, *where, *argv, **newargv ;
	int	flag, ntask, *tids, trash, nrows, ncols;
	int     i;

	/* task to spawn	*/
	trash = (mxGetM(prhs[0]) * mxGetN(prhs[0])) +1;
	task = mxCalloc(trash,sizeof(char));
  	mxGetString(prhs[0],task,trash);

	/* arguments for the task */
	nrows = mxGetM(prhs[1]);
	ncols = mxGetN(prhs[1]);
	trash = (nrows * ncols) +1;
	argv = mxCalloc(trash,sizeof(char));
  	mxGetString(prhs[1],argv,trash);
	newargv = (char **)  mxCalloc(nrows+1,sizeof(char*));
	if  (StrReshape(argv, newargv, nrows, ncols))
   		mexErrMsgTxt("StrReshape() failed.\n");

	/* spawn method */
	flag = (int) mxGetScalar(prhs[2]);

	/* where */
	trash = (mxGetM(prhs[3]) * mxGetN(prhs[3])) +1;
	where = mxCalloc(trash,sizeof(char));
  	mxGetString(prhs[3],where,trash);      

	/* number of tasks to spawn */
	ntask = (int) mxGetScalar(prhs[4]);

	/* integer array for the ID's of spawned tasks (return value)*/
	tids = mxCalloc(ntask,sizeof(int));

	/* number of successful spawned tasks (return value)*/
	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

	/* call the extension function */
	(mxGetPr(plhs[0]))[0] = (double) pvme_spawn(task,newargv,flag,where,ntask,tids); 
	
	/* ID's of spawned tasks */
	plhs[1] = mxCreateDoubleMatrix(ntask,1,mxREAL);
	for (i=0; i<ntask; i++)
		mxGetPr(plhs[1])[i] = (double)  tids[i];
      
	return;
}
#endif /* no M4 */


