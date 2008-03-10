/*
 * M4/M5 compatibility
 * 
 * Copyright (c) 1998-1999 University of Rostock, Germany, 
 * Institute of Automatic Control. All rights reserved.
 *
 * See file ``Copyright'' for terms of copyright.
 *
 * Authors: S. Pawletta
 *
 */

#ifndef _MEX_M4_M5_H_
#define _MEX_M4_M5_H_


#include "matrix_m4_m5.h"
#include <mex.h>


#ifdef M4 /*--------------------- Matlab 4 ---------------------*/

#define mexPutArray(parray,workspace) mexPutMatrix(parray)
#define mexGetArrayPtr(name,workspace) mexGetMatrixPtr(name)
#ifdef NEEDMEXLOCK
static int MEXLOCK;
#define mexIsLocked() MEXLOCK
#define mexLock()     MEXLOCK=1
#define mexUnlock()   MEXLOCK=0
#endif

#endif


#endif  /*_MEX_M4_M5_H_*/

