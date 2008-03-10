/*
 * stand alone pvm_start_pvmd() caller
 * for bypass implementation of the libpvm3:pvm_start_pvmd()
 * problem with M4/Linux
 *
 * Synopsis:	pvm_start_pvmd block other_args
 *
 * Attention: unsafe implementation; no parameter sanity check etc.
 * 
 * Copyright (c) 1998-1999 University of Rostock, Germany, 
 * Institute of Automatic Control. All rights reserved.
 *
 * See file ``Copyright'' for terms of copyright.
 *
 * Author: S. Pawletta	(Oct 98, initial version)
 *
 */

#include "stdio.h"
#include "stdlib.h"
#include "pvm3.h"


int main(int argc, char **argv) {

	int  block;
	int  info;

	/* first argument must be parameter block */
	block = atoi(argv[1]);

	/* drop arguments argv[0] and argv[1] */
	argv[0] = argv[2];
	argc    = argc - 2;

	/* call libpvm3 function */
	info = pvm_start_pvmd(argc,argv,block);

	/* return info code */
	exit(info);
}

