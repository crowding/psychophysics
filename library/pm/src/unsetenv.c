/*
 * mex function for deleting an environment variable
 * 
 * Copyright (c) 1998-1999 University of Rostock, Germany, 
 * Institute of Automatic Control. All rights reserved.
 *
 * See file ``Copyright'' for terms of copyright.
 *
 * Authors: S. Pawletta (Dec 98, initial version)
 *	    A. Westphal (Dec 98, revised for systems without unsetenv(3) )
 *
 */

#include "mex_m4_m5.h"
#include <stdlib.h>
#ifdef NOUNSETENV
#include <string.h>
#endif

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
 
	char *str;
	int  n;


	/*
	 * check for proper number of arguments 
	 */
	if (nrhs != 1) {
		mexErrMsgTxt("One input argument is required.");
	}
	if (nlhs != 0) {
		mexErrMsgTxt("None output argument is accepted.");
	}


	/*
	 * read and check input argument 
	 */

	if(!mxIsChar(prhs[0]) || mxGetM(prhs[0])!=1) {
		mexErrMsgTxt("input argument must be a single string");
	}
	n=mxGetN(prhs[0])+1;
#ifndef NOUNSETENV
	if(!(str=(char*)mxCalloc(n,sizeof(char)))) {
		mexErrMsgTxt("mxCalloc() failed");
	}
#else
	if(!(str=(char*)calloc(n+1,sizeof(char)))) { /* persistent and	 */
		mexErrMsgTxt("mxCalloc() failed");   /* additional space */
	}					     /* space for '='    */
#endif
	if(mxGetString(prhs[0],str,n)) {
		mexErrMsgTxt("mxGetString(prhs[0],str,n) failed");
	}

	/*
	 * delete environment variable
	 */

#ifndef NOUNSETENV
	unsetenv(str);		/* really delete environ var */
#else
	strcat(str,"=");
	putenv(str);		/* set to empty */
#endif

	/*
	 * free allocated memory
	 */
#ifndef NOUNSETENV
	mxFree(str);
#else
	/* with putenv(3) we must leave it persistent */
#endif

	return;
}

