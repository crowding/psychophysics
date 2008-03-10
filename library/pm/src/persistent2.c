/*
 * Persistent M-Variables
 *
 * see persistent2.m for usage
 *
 * Copyright (c) 1998-1999 University of Rostock, Germany,
 * Institute of Automatic Control. All rights reserved.
 *
 * See file ``Copyright'' for terms of copyright.
 *
 * Authors: S. Pawletta (Dec 98, initial version for M4)
 *	    A. Westphal (Dec 98, ported to M5)
 *	    S. Pawletta (Dec 98, revised for M4/M5 compatibility)
 *
 */

/* patched by J. Ditterich for compatibility with MATLAB R13 */

#define V5_COMPAT /* V5 compatibility mode */

#include "misc.h"
#ifdef M4
#define NEEDMEXLOCK
#endif

#include "mex_m4_m5.h"
#include <stdlib.h>


/****************************************
 *					*
 * Configuration Constants		*
 *					*
 ****************************************/

#define	MAX_NUM_PERSVAR 7	/* maximum number of persistent variables */


/****************************************
 *					*
 * Persistent Space ''Object''		*
 *					*
 ****************************************/

				/* Interface Methods */

static void			/* restores a variable from the persistent */
openPersVar(char *var_name);	/* space into the caller's workspace;      */
				/* if it doesn't exist in the persistent   */
				/* space an empty matrix is created in the */
				/* caller's workspace			   */

static void			/* saves a variable from the caller's      */
closePersVar(char *var_name);	/* workspace into the persistent space     */

static void			/* displays persistent space informations  */
listPersVar();			/* including all contained variables	   */

static void			/* removes all variables from the 	   */
clearPersVar();			/* persistent space			   */


				/* Private Methods */

static void			/* creates empty matrix in the caller's	   */
createVarInWS(char *var_name);  /* workspace				   */

static void			/* restores variable from the persistent   */
restoreVarInWS(int idx);	/* space into the caller's workspace	   */

static void			/* creates a new variable in the           */
createVarInPS(int idx, 		/* persistent space			   */
	      mxArrayIn *pm_ws, 
	      int m, int n, int mn, 
	      char *var_name);

static void			/* updates an existing variable in the     */
updateVarInPS(int idx, 		/* persistent space			   */
	      mxArrayIn *pm_ws, 
	      int m, int n, int mn);

static void			/* removes a variable from the persistent  */
removeVarFromPS(int idx);	/* space				   */


static int			/* search functions upon the persistent    */
findVarInPS(char *var_name);	/* space returning indices (idx)	   */

static int
findNextVarInPS();

static int
findEmptyIdxInPS();


static int			/* access functions returning data from    */
getMaxNumVarInPS();		/* and about the persistent space	   */

static int
getNumVarInPS();

static char*
getVarNameFromPS(int idx);

static int
getVarDimMFromPS(int idx);

static int
getVarDimNFromPS(int idx);

static int
getVarMaxDimFromPS(int idx);


				/* Private Data	*/
static int
NUM_PERSVAR	 = 0;

static char 
PERSVAR_NAMES    [ MAX_NUM_PERSVAR ][ mxMAXNAM ];

static int 
PERSVAR_DIMS     [ MAX_NUM_PERSVAR ][ 2 ];

static int 
PERSVAR_MAX_DIMS [ MAX_NUM_PERSVAR ];

static double*
PERSVAR_DATA     [ MAX_NUM_PERSVAR ];


/****************************************
 *					*
 * MEX-File Locking & atExit-Handler	*
 *					*
 ****************************************/

static void		/* persistent2.mex is automatically locked by	*/
lock_persistent();	/* createVarInPS() via lock_persistent() when	*/
			/* variables appear in the persistent space and */
static void		/* it is unlocked by removeVarFromPS() via      */
unlock_persistent();	/* unlock_persistent() when the persistent 	*/
			/* space becomes empty;				*/
static void		/* lock_persistent()/unlock_persistent()	*/
persistentAtExit();	/* install/deinstall the atexit functions	*/
			/* persistentAtExit();				*/
			/* during execution persistentAtExit() displays */
			/* a warning message and calls displayPersVar() */
			/* and clearPersVar()				*/



/*-------------------------------------------------------------------*/
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	char	opcode[6];
	char	var_name[mxMAXNAM];

	if ( nrhs == 0 ) {
		listPersVar(); return;
	}
	if ( mxGetString(prhs[0],&opcode[0],6) ) {
		mexErrMsgTxt("First input argument doesn't contain a valid "
			     "operation mode.\n");
	}
	if ( !strcmp(opcode,"clear") ) {
		clearPersVar(); return;
	}
	if ( mxGetString(prhs[1],&var_name[0],mxMAXNAM) ) {
		mexErrMsgTxt("Second input argument isn't a variable name.\n");
	}
	if ( !strcmp(opcode,"open") ) {
		openPersVar(var_name); return;
	}
	if ( !strcmp(opcode,"close") ) {
		closePersVar(var_name); return;
	}
	mexErrMsgTxt("First input argument contains unknown operation mode.\n");

	return;
}


/*-------------------------------------------------------------------*
 * Persistent Space: Interface Methods				     *
 *-------------------------------------------------------------------*/

static void
openPersVar(char *var_name)
{
	int	idx_ps;

	if ( ( idx_ps=findVarInPS(var_name) ) >= 0 ) {
		/* 
		 * restore variable in caller's workspace
		 */
		restoreVarInWS(idx_ps);
	}
	else {
		/* 
		 * create new variable in caller's workspace
		 */
		createVarInWS(var_name);
	}

	return;
}


static void
closePersVar(char *var_name)
{
	int	idx_ps;
	int	m,n,mn;
	mxArrayIn	*pm_ws;

	/*
	 * get variable reference from caller's workspace
	 */
	if ( !( pm_ws = mexGetArrayPtr(var_name, "caller") ) ) {
		mexErrMsgTxt("Variable to make persistent does not exist.\n");
	}

	m  = mxGetM(pm_ws);
	n  = mxGetN(pm_ws);
	mn = m * n;
	if ( mn == 0 ) {
		/*
	 	 * variable in workspace is a empty matrix
		 */
		if ( ( idx_ps=findVarInPS(var_name) ) >= 0 ) {
			/*
			 * remove it from persistent space
			 */
			removeVarFromPS(idx_ps);
		}
	}
	else {
		/*
		 * variable in workspace is a non-empty matrix
		 */
		if ( ( idx_ps=findVarInPS(var_name) ) >= 0 ) {
			/*
			 * update variable in persistent space
			 */
			updateVarInPS(idx_ps,pm_ws,m,n,mn);
		}
		else {
			/*
			 * create new variable in persistent space
			 */
			if ( ( idx_ps=findEmptyIdxInPS() ) < 0 ) {
				mexErrMsgTxt("Can't make variable persistent. " 
					     "Maximum number reached.\n");
			}
			createVarInPS(idx_ps,pm_ws,m,n,mn,var_name);
		}
	}

	return;
}


static void
listPersVar()
{
	int 	idx_ps;

	mexPrintf("maximum number of persistent variables: %i\n",
		  getMaxNumVarInPS());
	mexPrintf("current number of persistent variables: %i\n",
		  getNumVarInPS());
	while ( ( idx_ps=findNextVarInPS() ) >= 0 ) {
		mexPrintf("[%i] ..%s.. \t %i %i \t %i\n",
			  idx_ps,
		  	  getVarNameFromPS(idx_ps),
		  	  getVarDimMFromPS(idx_ps),
		  	  getVarDimNFromPS(idx_ps),
		  	  getVarMaxDimFromPS(idx_ps));
	}

	return;
}


static void
clearPersVar()
{
	int	idx_ps;

	while ( ( idx_ps=findNextVarInPS() ) >= 0 ) {
		removeVarFromPS(idx_ps);
	}

	return;
}


/*-------------------------------------------------------------------*
 * Persistent Space: Private Methods				     *
 *-------------------------------------------------------------------*/

static void
createVarInWS(char *var_name)
{
	mxArray	*var_ptr;

	var_ptr = mxCreateDoubleMatrix(0,0,mxREAL);
	mxSetName(var_ptr,var_name);
	if ( mexPutArray(var_ptr,"caller") ) {
		mexErrMsgTxt("createPersVarInWS(): mexPutArray() failed.\n");
	}

	return;
}


static void
restoreVarInWS(int idx)
{
	mxArray *var_ptr;

	var_ptr = mxCreateDoubleMatrix(PERSVAR_DIMS[idx][0],
				       PERSVAR_DIMS[idx][1],
				       mxREAL);
   	mxSetName(var_ptr,PERSVAR_NAMES[idx]);
	memcpy(mxGetPr(var_ptr),PERSVAR_DATA[idx],
               PERSVAR_DIMS[idx][0] * PERSVAR_DIMS[idx][1] * sizeof(double));

	if ( mexPutArray(var_ptr,"caller") ) {
		mexErrMsgTxt("restorePersVarInWS(): mexPutArray() failed.\n");
	}

	return;
}


static void
createVarInPS(int idx, mxArrayIn *pm_ws, int m, int n, int mn, char *var_name)
{
	PERSVAR_DATA[idx] = (double*) calloc(mn,sizeof(double));
	if ( !PERSVAR_DATA[idx] ) {
		mexErrMsgTxt("createVarInPS(): calloc failed.\n");
	}
	PERSVAR_MAX_DIMS[idx] = mn;
	memcpy(PERSVAR_DATA[idx],mxGetPr(pm_ws),mn*sizeof(double));
	PERSVAR_DIMS[idx][0]  = m;
	PERSVAR_DIMS[idx][1]  = n;
	strcpy(PERSVAR_NAMES[idx],var_name);

	if ( 0 == NUM_PERSVAR++) {
		lock_persistent();
 	}

	return;
}


static void
updateVarInPS(int idx, mxArrayIn *pm_ws, int m, int n, int mn)
{
	if ( mn > PERSVAR_MAX_DIMS[idx] ) {
		/*
		 * old storage too small for new data,
		 * free it and create sufficient
		 */
		free(PERSVAR_DATA[idx]);
		PERSVAR_DATA[idx] = (double*) calloc(mn,sizeof(double));
		if ( !PERSVAR_DATA[idx] ) {
			mexErrMsgTxt("updateVarInPS(): calloc failed.\n");
		}
		PERSVAR_MAX_DIMS[idx] = mn;
	}
	memcpy(PERSVAR_DATA[idx],mxGetPr(pm_ws),mn*sizeof(double));
	PERSVAR_DIMS[idx][0]  = m;
	PERSVAR_DIMS[idx][1]  = n;

	return;
}


static void
removeVarFromPS(int idx)
{
	PERSVAR_NAMES[idx][0] = (char)0;
	PERSVAR_DIMS[idx][0]  = 0;
	PERSVAR_DIMS[idx][1]  = 0;
	PERSVAR_MAX_DIMS[idx] = 0;
	free(PERSVAR_DATA[idx]);
	PERSVAR_DATA[idx]     = (double*)0;

	if ( --NUM_PERSVAR == 0 ) {
		unlock_persistent();
 	}

	return;
}


/*-------------------------------------------------------------------*
 * Persistent Space: Private Methods (search functions)		     *
 *-------------------------------------------------------------------*/

static int
findVarInPS(char *var_name)
{
	int	idx;

	for (idx=0; idx<MAX_NUM_PERSVAR; idx++) {
		if ( !strcmp(var_name,PERSVAR_NAMES[idx]) ) {
			return idx;
		}
	}
	return -1;
}


static int
findNextVarInPS()
{
	static int	idx = 0;

	for (; idx<MAX_NUM_PERSVAR; idx++) {
		if ( PERSVAR_NAMES[idx][0] ) {
			return idx++;
		}
	}
	idx = 0;
	return -1;
}


static int
findEmptyIdxInPS()
{
	int	idx;

	for (idx=0; idx<MAX_NUM_PERSVAR; idx++) {
		if ( !PERSVAR_NAMES[idx][0] ) {
			return idx;
		}
	}
	return -1;
}


/*-------------------------------------------------------------------*
 * Persistent Space: Private Methods (access functions)		     *
 *-------------------------------------------------------------------*/

static int
getMaxNumVarInPS()
{
	return (MAX_NUM_PERSVAR);
}


static int
getNumVarInPS()
{
	return (NUM_PERSVAR);
}


static char*
getVarNameFromPS(int idx)
{
	return (PERSVAR_NAMES[idx]);
}


static int
getVarDimMFromPS(int idx)
{
	return (PERSVAR_DIMS[idx][0]);
}


static int
getVarDimNFromPS(int idx)
{
	return (PERSVAR_DIMS[idx][1]);
}


static int
getVarMaxDimFromPS(int idx)
{
	return (PERSVAR_MAX_DIMS[idx]);
}


/*-------------------------------------------------------------------*
 * MEX-File Locking & atExit-Handler				     *
 *-------------------------------------------------------------------*/

static void
lock_persistent()
{
	if ( !mexIsLocked() ) {
		mexLock();
		if ( atExitSubscribe(&persistentAtExit) < 0 ) {
			mexErrMsgTxt("lock_persistent(): atExitSubscribe() failed.\n"
				     "This is a bug probably. Please report it.\n");
		}
	}
	else {
		mexErrMsgTxt("lock_persistent(): persistent is already locked.\n"
			     "This is a bug probably. Please report it.\n");
	}
	return;
}


static void
unlock_persistent()
{
	if ( mexIsLocked() ) {
		mexUnlock();
		if ( atExitUnsubscribe(&persistentAtExit) < 0 ) {
			mexErrMsgTxt("unlock_persistent(): atExitUnsubscribe() failed.\n"
				     "This is a bug probably. Please report it.\n");
		}
	}
	else {
		mexErrMsgTxt("unlock_persistent(): persistent is already unlocked.\n"
			     "This is a bug probably. Please report it.\n");
	}
	return;
}


static void 
persistentAtExit()
{
	mexPrintf("persistentAtExit(): persistent.mex is cleared from Matlab "
		  "in an unexpected way.\n"
		  "The following persistent variables are getting lost:\n");
	listPersVar();
	clearPersVar();
	return;
}

