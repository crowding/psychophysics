/*
 * miscellaneous functions
 * 
 * Copyright (c) 1995-1999 University of Rostock, Germany, 
 * Institute of Automatic Control. All rights reserved.
 *
 * Copyright (c) 1997 University of Magdeburg, Germany, 
 * Institute of Automation. All rights reserved.
 *
 * See file ``Copyright'' for terms of copyright.
 *
 * Authors: S. Pawletta
 *	    T. T. Binh (StrReshape)
 *	    A. Westphal
 *
 */


#ifndef _MISC_H_
#define _MISC_H_


#ifdef WIN32
        #include <time.h>
#else
        #include <sys/time.h>
#endif
#include "matrix_m4_m5.h"


/* 
 * Matlab -> C -> Matlab conversions; used in wrapper functions
 */

int mat_matlab_names2str  (mxArray *pm, char ***strings, int *num_str);
int strmat2str		  (mxArrayIn *pm, char ***strings, int *num_str);
int str2strmat		  (const char **strings, int num_str, mxArray **pm);
int strmat2strnull	  (mxArray *pm, char ***strings);
int mat2int		  (mxArray *pm, int **ia, int *num_i);
int int2mat		  (int *ia, int num_i, mxArray **pm);
		

/* 
 * Matlab -> C -> Matlab conversions; Binh's functions
 */

int StrReshape	      (char *strings, char **newstrings, int nrows, int ncols);


/*
 * Subscription / unsubscription of multiple atexit functions 
 * for a MEX-file
 */

int  atExitSubscribe	( void (*func)() );
int  atExitIsSubscribed	( void (*func)() );
int  atExitUnsubscribe	( void (*func)() );
void atExitList		();


#endif  /*_MISC_H_*/
