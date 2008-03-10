/*
 * mex function for changing or adding an environment variable
 * 
 * Copyright (c) 1995-1999 University of Rostock, Germany, 
 * Institute of Automatic Control. All rights reserved.
 *
 * See file ``Copyright'' for terms of copyright.
 *
 * Authors: S. Pawletta (1995, initial version as c0_putenv.c)
 *	 	        (Dec 98, renamed to putenv.c)
 * 	    A. Westphal (Dec 98, revised for M5)
 * 	    S. Pawletta (Dec 98, revised for M4/M5 compatibilty)
 *
 */

#include "mex_m4_m5.h"
#include <stdlib.h>

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
	if(!(str=(char*)calloc(n,sizeof(char)))) {
		mexErrMsgTxt("system call calloc(n,sizeof(char)) failed");
	}
	if(mxGetString(prhs[0],str,n)) {
		mexErrMsgTxt("mxGetString(prhs[0],str,n) failed");
	}

	
	/*
	 * put environment variable
	 */

	if(putenv(str)) {
		mexErrMsgTxt("library function putenv(3) failed");
	}


	/*
	 * one persistent object allocated: str
	 */

	return;
}

