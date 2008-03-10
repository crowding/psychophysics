/*
 * wrapper for libpvm3 routines
 * 
 * Copyright (c) 1995-1999 University of Rostock, Germany, 
 * Institute of Automatic Control. All rights reserved.
 *
 * See file ``Copyright'' for terms of copyright.
 *
 * Authors: S. Pawletta (1995, initial version)
 *          A. Westphal (May 98, revised for PVM3.4.BETA6)
 *          S. Pawletta (Dec 98, revised for M4/M5 compatibility)
 */

#ifndef _M2LIBPVM_H_
#define _M2LIBPVM_H_

#include "mex_m4_m5.h"

		/* PVM Control */

void m2pvm_addhosts	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_delhosts	(int, mxArray*[], int, mxArrayIn*[]) ;

	        /* Setting and Getting Options */

void m2pvm_getopt	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_setopt	(int, mxArray*[], int, mxArrayIn*[]) ;

		/* Process Control */

void m2pvm_spawn	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_export	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_unexport	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_catchout	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_kill		(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_exit		(int, mxArray*[], int, mxArrayIn*[]) ;

		/* Information */

void m2pvm_mytid	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_parent	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_pstat	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_mstat	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_config	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_tasks	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_tidtohost	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_perror	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_archcode	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_getfds	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_version	(int, mxArray*[], int, mxArrayIn*[]) ;

		/* Signaling */

void m2pvm_sendsig	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_notify	(int, mxArray*[], int, mxArrayIn*[]) ;

	        /* Message Buffers */

void m2pvm_initsend	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_mkbuf	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_getsbuf	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_getrbuf	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_setsbuf	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_setrbuf	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_bufinfo	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_freebuf	(int, mxArray*[], int, mxArrayIn*[]) ;

               /* Packing/Unpacking Data */

void m2pvm_pkint	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_upkint	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_pkdouble	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_upkdouble	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_pkstr	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_upkstr	(int, mxArray*[], int, mxArrayIn*[]) ;

               /* Sending and Receiving */

void m2pvm_send		(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_mcast	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_probe	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_recv		(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_trecv	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_nrecv	(int, mxArray*[], int, mxArrayIn*[]) ;

		/* Master Pvmd Data Base */

void m2pvm_putinfo	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_recvinfo	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_getmboxinfo	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_delinfo	(int, mxArray*[], int, mxArrayIn*[]) ;

                /* Group Functions */
/*
void m2pvm_joingroup	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_lvgroup	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_getinst	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_gsize	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_gettid	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_barrier	(int, mxArray*[], int, mxArrayIn*[]) ;
void m2pvm_gids		(int, mxArray*[], int, mxArrayIn*[]) ;
*/

#endif  /*_M2LIBPVM_H_*/
