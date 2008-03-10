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

#ifndef _M2LIBPVME_H_
#define _M2LIBPVME_H_

#include "mex_m4_m5.h"


	/* PVM Control */

void m2pvme_is			(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvme_default_config	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvme_start_pvmd		(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvme_halt		(int, mxArray*[], int, mxArrayIn*[]) ;


	/* Process Control */

void m2pvme_spawn		(int, mxArray*[], int, mxArrayIn*[]) ;


	/* Packing and Unpacking */

void m2pvme_pkmat		(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvme_upkmat		(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvme_upkmat_name		(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvme_upkmat_rest		(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvme_pkarray		(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvme_upkarray		(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvme_upkarray_name	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvme_upkarray_rest	(int, mxArray*[], int, mxArrayIn*[]) ;


#endif  /*_M2LIBPVME_H_*/


