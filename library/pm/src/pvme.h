/*
 * libpvme routines
 * 
 * Copyright (c) 1995-1999 University of Rostock, Germany, 
 * Institute of Automatic Control. All rights reserved.
 *
 * See file ``Copyright'' for terms of copyright.
 *
 * Authors: S. Pawletta, A. Westphal
 *
 */

#ifndef _PVME_H_
#define _PVME_H_

#include "matrix_m4_m5.h"


#define	PvmeErr	-100	/* common error code used by libpvme routines */


	/* pvmectrl.c	PVM Control */

int pvme_is		();
int pvme_default_config	(int conf_lines, char **conf);
int pvme_start_pvmd	(int argc, char **argv, int block);
int pvme_halt		();


	/* pvmeupk.c	Packing and Unpacking */

int pvme_pkmat		(mxArray *pm);
int pvme_pkmat_bypass	(mxArray *pm, char *Name);
int pvme_upkmat		(mxArray **ppm);
int pvme_upkmat_name	(char *Name);
int pvme_upkmat_rest	(mxArray **ppm, char *Name);
int pvme_pkarray	(mxArray *pm);
int pvme_upkarray	(mxArray **ppm);
int pvme_upkarray_name	(char *Name);
int pvme_upkarray_rest	(mxArray **ppm, char *Name);


	/* pvmeprocctrl.c	Process Control */

int pvme_spawn		(char *task, char **argv, 
			 int flag, char *where, 
			 int ntask, int *tids);

#endif  /*_PVME_H_*/


