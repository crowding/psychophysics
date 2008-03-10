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

#ifndef _MATRIX_M4_M5_H_
#define _MATRIX_M4_M5_H_


#ifdef M4
#define OLDSTYLE	/* otherwise mxMAXNAM is not included and *
			 * the "new style" seems not to provide an *
			 * other method to determine the maximum   *
			 * length for the matrix name property     */
#endif


#include <matrix.h>


#ifdef M4 /*--------------------- Matlab 4 ---------------------*/

#define mxArray		Matrix
#define mxArrayIn	Matrix

typedef enum {
	mxREAL	  =	REAL,
	mxCOMPLEX =	COMPLEX
} mxComplexity;

#define mxCreateDoubleMatrix	mxCreateFull
#define mxIsChar		mxIsString
	

#else     /*--------------------- Matlab 5 ---------------------*/

#define mxArrayIn	const mxArray

#endif


#endif  /*_MATRIX_M4_M5_H_*/

