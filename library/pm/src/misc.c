/*
 * miscellaneous functions
 * 
 * Copyright (c) 1995-1999 University of Rostock, Germany, 
 * Institute of Automatic Control. All rights reserved.
 *
 * Copyright (c) 1997 University of Rostock, Germany, 
 * Institute of Automatic Control. All rights reserved.
 *
 * See file ``Copyright'' for terms of copyright.
 *
 * Authors: S. Pawletta
 *	    T. T. Binh (StrReshape)
 *	    A. Westphal
 *
 */

#include "misc.h"

#include "mex_m4_m5.h"
#include <stdlib.h>


/************************************************************************
 *									*
 * Matlab -> C -> Matlab conversions; used in wrapper functions		*
 *									*
 ************************************************************************/

int 
mat_matlab_names2str(		/* Converts multi-string matrix containing matlab names */
				/* to an array of C-strings. The converted matlab names are */
				/* shorten to mxMAXNAM if necessary and all characters starting */
				/* from the first occured blank are striped. */
				/* The array is allocated by the routine using mxCalloc(). */
				/* If the matrix is empty the routine returns NULL for the C-strings */
				/* In case of error -> return = -1 otherwise return = 0 */
	mxArray	*pm,		/* input arg: multi-string matrix to convert */
	char	***strings,	/* output arg: C-string array allocated by this routine using mxCalloc */
	int	*num_str)	/* output arg: number of strings */
{

	int	i,j;	/* loop indices */
#ifndef M4
	char	*buf;
	int	buflen;
	int	status;
#endif


	if ( (*num_str = mxGetM(pm)) ) {

#ifndef M4
		buflen = (mxGetM(pm) * mxGetN(pm)) + 1;
		buf    = mxCalloc(buflen, sizeof(char));
		if (buf == NULL)
			return -1;
		status = mxGetString(pm, buf, buflen); 
		if (status)
			return -1;
#endif
		if ( ! (*strings = mxCalloc(*num_str,sizeof(char*))) ) 
			return -1;

		for (i=0; i<*num_str; ++i) {
			if ( ! ((*strings)[i] = mxCalloc(mxMAXNAM,sizeof(char))) ) 
				return -1;
			for (j=0; j<mxGetN(pm) && j<mxMAXNAM-1; ++j) {
#ifndef M4
				(*strings)[i][j]=buf[i+j*mxGetM(pm)];
#else
				(*strings)[i][j]=(char) mxGetPr(pm)[i+(j*(*num_str))];
#endif
				if ((*strings)[i][j] == ' ') {
					break;
				}
			}
			(*strings)[i][j] = (char) 0; 
		}
	}
	else {
		if ( ! (*strings = mxCalloc(1,sizeof(char*))) ) 
			return -1;
		(*strings)[0] = NULL;
	}

	return 0;
}
		



int 
strmat2str(			/* Converts multi-string matrix to an array of C-strings. */
				/* Only trailing blanks are striped. */
				/* The array is allocated by the routine using mxCalloc(). */
				/* If the matrix is empty the routine returns NULL for the C-strings */
				/* In case of error -> return = -1 otherwise return = 0 */
	mxArrayIn *pm,		/* input arg: multi-string matrix to convert */
	char	***strings,	/* output arg: C-string array allocated by this routine using mxCalloc */
	int	*num_str)	/* output arg: number of strings */
{

	int	i,j;	/* loop indices */
#ifndef M4
	char	*buf;
	int	buflen;
	int	status;
#endif


	if ( (*num_str = mxGetM(pm)) ) {

#ifndef M4
		buflen = (mxGetM(pm) * mxGetN(pm)) + 1;
		buf    = mxCalloc(buflen, sizeof(char));
		if (buf == NULL)
			return -1;
		status = mxGetString(pm, buf, buflen); 
		if (status)
			return -1;
#endif
		if ( ! (*strings = mxCalloc(*num_str,sizeof(char*))) ) 
			return -1;

		for (i=0; i<*num_str; ++i) {
			if ( ! ((*strings)[i] = mxCalloc(mxGetN(pm)+1,sizeof(char))) ) 
				return -1;
			for (j=0; j<mxGetN(pm); ++j) 
#ifndef M4
				(*strings)[i][j]=buf[i+j*mxGetM(pm)];
#else
				(*strings)[i][j]=(char) mxGetPr(pm)[i+(j*(*num_str))];
#endif
			for (j=mxGetN(pm)-1; j>=0; --j) 
				if ((*strings)[i][j] != ' ') 
					break;
			(*strings)[i][j+1] = (char) 0; 
		}
#ifndef M4
		mxFree(buf);
#endif
	}
	else {
		if ( ! (*strings = mxCalloc(1,sizeof(char*))) ) 
			return -1;
		(*strings)[0] = NULL;
	}

	return 0;
}
		


int 
str2strmat(			/* Converts array of C-strings to a multi-string matrix. */
#ifndef M4
				/* The matrix is allocated by the routine using mxCreateCharMatrixFromStrings(). */
#else
				/* The matrix is allocated by the routine using mxCreateFull(). */
#endif
				/* If the array is empty the routine returns an empty matrix */
				/* In case of error -> return = -1 otherwise return = 0 */
	const char **strings,	/* input arg: array of C-strings to convert */
	int	num_str,	/* input arg: number of strings */
	mxArray	**pm)		/* output arg: pointer to newly allocated matrix*/
{

#ifndef M4
	if ( ! (*pm = 	mxCreateCharMatrixFromStrings(num_str,strings)) ) 
		return -1;
	
#else
        size_t  strl, strlmax=0;        /* length, max length of strings */
        int     i,j;                    /* loop indices */

        for (i=0; i<num_str; ++i) {
                strl = strlen(strings[i]);
                strlmax = (strl > strlmax) ? strl : strlmax;
        }
                
        if ( ! (*pm = mxCreateFull(num_str,(int)strlmax,REAL)) ) 
                return -1;
        
        for (i=0; i<num_str; ++i) {
                strl = (int) strlen(strings[i]);
                for (j=0; j<strl; ++j) 
                        mxGetPr(*pm)[i+(j*num_str)] = (double) strings[i][j];
                for (j=strl; j<strlmax; ++j) 
                        mxGetPr(*pm)[i+(j*num_str)] = (double) ' ';
        }

        mxSetString(*pm);

#endif
	return 0;
}
		


int
strmat2strnull(			/* Like strmat2str(), but the resulting C-String array is NULL-terminated */
				/* i.e. strings[last_string]=NULL */
	mxArray	*pm,		/* input arg: multi-string matrix to convert */
	char	***strings)	/* output arg: C-string array allocated by this routine using mxCalloc */
{

	int	num_str;	/* number of strings */
	int	i,j;		/* loop indices */
#ifndef M4
	char *buf;
	int   buflen;
	int   status;
#endif


	if ( (num_str = mxGetM(pm)) ) {

#ifndef M4
		buflen = (mxGetM(pm) * mxGetN(pm)) + 1;
		buf    = mxCalloc(buflen, sizeof(char));
		if (buf == NULL)
			return -1;
		status = mxGetString(pm, buf, buflen); 
		if (status)
			return -1;

		if ( ! (*strings = mxCalloc(num_str,sizeof(char*))) ) 
			return -1;
#else
		if ( ! (*strings = mxCalloc(num_str+1,sizeof(char*))) ) 
			return -1;
#endif

		for (i=0; i<num_str; ++i) {
			if ( ! ((*strings)[i] = mxCalloc(mxGetN(pm)+1,sizeof(char))) ) 
				return -1;
			for (j=0; j<mxGetN(pm); ++j) 
#ifndef M4
				(*strings)[i][j]=buf[i+j*mxGetM(pm)];
#else
				(*strings)[i][j]=(char) mxGetPr(pm)[i+(j*(num_str))];
#endif
			for (j=mxGetN(pm)-1; j>=0; --j) 
				if ((*strings)[i][j] != ' ') 
					break;
			(*strings)[i][j+1] = (char) 0; 
		}
		(*strings)[num_str] = (char) 0; 
#ifndef M4
		mxFree(buf);
#endif
		}
	else {
		if ( ! (*strings = mxCalloc(1,sizeof(char*))) ) 
			return -1;
		(*strings)[0] = NULL;
	}

	return 0;
}

		

int 
mat2int(			/* Converts matrix to an int array. */
				/* The array is allocated by the routine using mxCalloc(). */
				/* If the matrix is empty the routine returns NULL for the int array */
				/* In case of error -> return = -1 otherwise return = 0 */
	mxArray	*pm,		/* input arg: matrix to convert */
	int	**ia,		/* output arg: int array allocated by this routine using mxCalloc */
	int	*num_i)		/* output arg: length of int array */
{

	int	i;		/* loop indices */

	if ( (*num_i = mxGetM(pm) * mxGetN(pm)) ) {

		if ( ! (*ia = mxCalloc(*num_i,sizeof(int))) ) 
			return -1;

		for (i=0; i<*num_i; ++i)
			(*ia)[i] = (int) mxGetPr(pm)[i];
	}
	else 
		(*ia) = NULL;


	return 0;
}


		
int 
int2mat(			/* Converts int array to a matrix. */
				/* The matrix is allocated by the routine using mxCreateFull(). */
				/* If the array is empty the routine returns an empty matrix */
				/* In case of error -> return = -1 otherwise return = 0 */
	int	*ia,		/* input arg: int array to convert */
	int	num_i,		/* input arg: length of int array */
	mxArray	**pm)		/* output arg: pointer to newly allocated matrix*/
{

	int	i;		/* loop indices */

	if ( ! (*pm = mxCreateDoubleMatrix(num_i,1,mxREAL)) ) 
		return -1;

	for (i=0; i<num_i; ++i)
		mxGetPr(*pm)[i] = (double) ia[i];

	return 0;
}
		


int 
StrReshape(			/* implementation from Binh */
	char	*strings,
	char	**newstrings,
	int	nrows,
	int	ncols)
{
     /* convert a C-style string into string matrix with the given structure
      * (ncols and nrows - maximum number of columns and rows respectively)
      * without any blank in string
      */ 

        int   i, j;

        for (i=0; i < nrows;i++){
            if ( ! ( newstrings[i] = mxCalloc(ncols+1,sizeof(char))))
                return -1;

            for (j=0; j < ncols;j++)
	        if (strings[i +(j*(nrows))] != ' ')
                    newstrings[i][j] = strings[i +(j*(nrows))];
                else
                    break;
        }

        return 0;
}



/************************************************************************
 *									*
 * Subscription / unsubscription of multiple atexit functions 		*
 * for a MEX-file.							*
 *									*
 ************************************************************************/

/* 
 * Internals:
 * (We can't use the name ATEXIT_MAX because it is used in 
 *  /usr/include/sys/limits.h, atleast in AIX4.1. Therefor we use
 *  MEXATEXIT* instead.)
 * MEXATEXIT_MAX is a constant specifying the maximum number of atexit
 *		functions that can be registered.
 * MEXATEXIT	is a persistent array containing pointers to the registered
 *		atexit functions.
 * atExitMain() is the ''main'' atexit function (with matlab's mexAtExit()
 *		only one atexit function can be registered). 
 *		When atExitMain() is called, it evaluates all atexit functions
 *		registered in MEXATEXIT in reverse order.
 *		atExitMain() returns and generates no errors.
 * Interface:
 * int atExitSubscribe(&func) registers at its first call atExitMain()
 *		as ''main'' atexit function to matlab and subscribes func as
 *		one atexit function, i.e. writes &func to MEXATEXIT.
 *		Return values less than zero indivate an error.
 * int atExitIsSubscribed(&func) returns 1 if func is a subscribed atexit 
 *		function and 0 otherwise.
 *		Returns and generates no errors.
 * int atExitUnsubscribe(&func) unsubscribes func as atexit function,
 *		i.e. removes &func from MEXATEXIT.
 *		Return values less than zero indivate an error.
 * atExitList() displays MEXATEXIT (only for debuging purposes).
 *		Returns and generates no errors.
 */

#define MEXATEXIT_MAX 2

static void (* MEXATEXIT [MEXATEXIT_MAX] ) (); 

static void 
atExitMain() 	 
{
	int i;

	/* evaluate atexit functions in reverse order */
	for (i=MEXATEXIT_MAX; i>0; i--) {
		if (MEXATEXIT[i-1]) {
			MEXATEXIT[i-1]();
		}
	}
	return;
}

int 
atExitSubscribe( void (*func)() ) 
{
	static int atExitMain_subscribed = 0;
	int i;

	/* register at first call atExitMain() as ''main'' atexit 
	 * function to matlab */
	if (!atExitMain_subscribed) {
		if (mexAtExit(&atExitMain)) {
			printf("atExitSubscribe(): mexAtExit() failed\n");
			return -1;
		}
		atExitMain_subscribed = 1;
	}

	/* subscribe func */
	for (i=0; i<MEXATEXIT_MAX; i++) {
		if (MEXATEXIT[i]==(void(*)())0) {
			MEXATEXIT[i] = func;
			break;
		}
	}

	/* error if max number of atexit functions reached */
	if (i==MEXATEXIT_MAX) {
		printf("atExitSubscribe(): Can't subscribe exit "
		       "function. Maximum number reached.\n");
		return -1;
	}

	return 0;
}

int 
atExitIsSubscribed( void (*func)() ) 
{
	int i;

	/* lookfor func */
	for (i=0; i<MEXATEXIT_MAX; i++) {
		if (MEXATEXIT[i]==func) {
			return 1;
			break;
		}
	}

	return 0;
}

int 
atExitUnsubscribe( void (*func)() ) 
{
	int i;

	/* unsubscribe func */
	for (i=0; i<MEXATEXIT_MAX; i++) {
		if (MEXATEXIT[i]==func) {
			MEXATEXIT[i] = (void(*)()) 0;
			break;
		}
	}

	/* error if func was not subscribed */
	if (i==MEXATEXIT_MAX) {
		printf("atExitUnsubscribe(): Can't unsubscribe. "
		       "Function was not subscribed\n");
		return -1;
	}

	return 0;
}

void 
atExitList() 
{
	int i;

	/* display MEXATEXIT */
	printf("MEXATEXIT_MAX = %i\n",MEXATEXIT_MAX);
	for (i=0; i<MEXATEXIT_MAX; i++) {
		printf("MEXATEXIT[%i] = %x\n",i,MEXATEXIT[i]);
	}
	return;
}







