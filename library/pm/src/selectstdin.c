/*
 *
 * 
 * Copyright (c) 1998-1999 University of Rostock, Germany, 
 * Institute of Automatic Control. All rights reserved.
 *
 * See file ``Copyright'' for terms of copyright.
 *
 * Author: S. Pawletta
 *
 */

#include "mex_m4_m5.h"
#ifndef WIN32
#include <sys/time.h>
#endif
#include <sys/types.h>
#ifndef WIN32
#include <unistd.h>
#endif
#if defined(RS6K) || defined(AIX46K)
#include <sys/select.h>
#endif
#include <string.h>


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
 
#ifdef WIN32
	mexErrMsgTxt("Not implemented for WIN32.");
#else
	fd_set		rset;
	struct timeval	tmout;
	int		info;

	FD_ZERO(&rset);

	FD_SET(STDIN_FILENO,&rset);

	tmout.tv_sec  = (int) mxGetScalar(prhs[0]);
	tmout.tv_usec = 0;

	info = select(STDIN_FILENO+1, &rset, NULL, NULL, &tmout);
	if ( info < 0 ) {
		mexErrMsgTxt("select() failed.\n");
	}

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
	mxGetPr(plhs[0])[0] = (double) info;

#endif
	return;
}

