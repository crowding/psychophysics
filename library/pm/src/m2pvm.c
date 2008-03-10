/*
 * MEX-Function Switch
 * 
 * Copyright (c) 1995-1999 University of Rostock, Germany,
 * Institute of Automatic Control. All rights reserved.
 *
 * See file ``Copyright'' for terms of copyright.
 *
 * Authors: S. Pawletta, M. Suesse, A. Westphal
 *					
 */

#ifdef M4
#define NEEDMEXLOCK
#endif
#include "matrix_m4_m5.h" 
#include "m2pvm.h"
#include "m2libpvm.h"
#include "m2libpvme.h"
#include "misc.h"

/*-------------------------------------------------------------------*/
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]) {
/*-------------------------------------------------------------------*/

	int	opcode;		/* operation code */


	/* read operation code and drop it from input arg list */
	opcode	= (int) mxGetScalar(prhs[0]);
	prhs++;
	nrhs--;


	/* call wrapper routine */
   	switch (opcode) {


		/* 
		 * pvme_link() / pvme_unlink()
		 */

		case 1302:	pvme_link();				break;
		case 1303:	pvme_unlink(nlhs,plhs);			break;


		/*
		 * wrapper for libpvm3 routines
		 */

		/* PVM Control */
		case 101:	m2pvm_addhosts(nlhs,plhs,nrhs,prhs); break;
		case 102:	m2pvm_delhosts(nlhs,plhs,nrhs,prhs); break;

               /* Setting and Getting Options */
		case 200:	m2pvm_getopt(nlhs,plhs,nrhs,prhs); break;
		case 201:	m2pvm_setopt(nlhs,plhs,nrhs,prhs); break;

		/* Process Control */
		case 300:	m2pvm_spawn(nlhs,plhs,nrhs,prhs); break;
		case 301:	m2pvm_export(nlhs,plhs,nrhs,prhs); break;
		case 302:	m2pvm_unexport(nlhs,plhs,nrhs,prhs); break;
		case 303:	m2pvm_catchout(nlhs,plhs,nrhs,prhs); break;
		case 304:	m2pvm_kill(nlhs,plhs,nrhs,prhs); break;
		case 305:	m2pvm_exit(nlhs,plhs,nrhs,prhs); break;
      
		/* Information */
		case 400:	m2pvm_mytid(nlhs,plhs,nrhs,prhs); break;
		case 401:	m2pvm_parent(nlhs,plhs,nrhs,prhs); break;
		case 402:	m2pvm_pstat(nlhs,plhs,nrhs,prhs); break;
		case 403:	m2pvm_mstat(nlhs,plhs,nrhs,prhs); break;
		case 404:	m2pvm_config(nlhs,plhs,nrhs,prhs); break;
		case 405:	m2pvm_tasks(nlhs,plhs,nrhs,prhs); break;
		case 406:	m2pvm_tidtohost(nlhs,plhs,nrhs,prhs); break;
		case 407:	m2pvm_perror(nlhs,plhs,nrhs,prhs); break;
		case 408:	m2pvm_archcode(nlhs,plhs,nrhs,prhs); break;
		case 409:	m2pvm_getfds(nlhs,plhs,nrhs,prhs); break;
		case 410:	m2pvm_version(nlhs,plhs,nrhs,prhs);	break;

               /* Signaling */
		case 500:	m2pvm_sendsig(nlhs,plhs,nrhs,prhs); break;
		case 501:	m2pvm_notify(nlhs,plhs,nrhs,prhs); break;

		/* Message Buffers */
		case 600:	m2pvm_initsend(nlhs,plhs,nrhs,prhs); break;
		case 601:	m2pvm_mkbuf(nlhs,plhs,nrhs,prhs); break;
		case 602:	m2pvm_getsbuf(nlhs,plhs,nrhs,prhs); break;
		case 603:	m2pvm_getrbuf(nlhs,plhs,nrhs,prhs); break;
		case 604:	m2pvm_setsbuf(nlhs,plhs,nrhs,prhs); break;
		case 605:	m2pvm_setrbuf(nlhs,plhs,nrhs,prhs); break;
		case 606:	m2pvm_bufinfo(nlhs,plhs,nrhs,prhs); break;
		case 607:	m2pvm_freebuf(nlhs,plhs,nrhs,prhs); break;

		/* Packing/Unpacking Data */
		case 700:	m2pvm_pkdouble(nlhs,plhs,nrhs,prhs); break;
		case 703:	m2pvm_upkdouble(nlhs,plhs,nrhs,prhs); break;
		case 705:	m2pvm_upkint(nlhs,plhs,nrhs,prhs); break;
/*
		case 702:	m2pvm_pkint(nlhs,plhs,nrhs,prhs); break;
		case 701:	m2pvm_pkstr(nlhs,plhs,nrhs,prhs); break;
		case 704:	m2pvm_upkstr(nlhs,plhs,nrhs,prhs); break;
*/

		/* Sending and Receiving */
		case 800:	m2pvm_send(nlhs,plhs,nrhs,prhs); break;
		case 806:	m2pvm_mcast(nlhs,plhs,nrhs,prhs); break;
		case 807:	m2pvm_probe(nlhs,plhs,nrhs,prhs); break;
		case 801:	m2pvm_recv(nlhs,plhs,nrhs,prhs); break;
		case 809:	m2pvm_trecv(nlhs,plhs,nrhs,prhs); break;
		case 808:	m2pvm_nrecv(nlhs,plhs,nrhs,prhs); break;

		/* Master Pvmd Data Base */
		case 901: 	m2pvm_putinfo(nlhs,plhs,nrhs,prhs); break;
		case 902:	m2pvm_recvinfo(nlhs,plhs,nrhs,prhs); break;
		case 904:	m2pvm_getmboxinfo(nlhs,plhs,nrhs,prhs);	break;
		case 903:	m2pvm_delinfo(nlhs,plhs,nrhs,prhs); break;

                /* Group Functions */
/*
		case 1200:	m2pvm_joingroup(nlhs,plhs,nrhs,prhs); break;
		case 1201:	m2pvm_lvgroup(nlhs,plhs,nrhs,prhs); break;
		case 1202:	m2pvm_getinst(nlhs,plhs,nrhs,prhs); break;
		case 1203:	m2pvm_gsize(nlhs,plhs,nrhs,prhs); break;
		case 1204:	m2pvm_gettid(nlhs,plhs,nrhs,prhs); break;
		case 1205:	m2pvm_barrier(nlhs,plhs,nrhs,prhs); break;
		case 1206:	m2pvm_gids(nlhs,plhs,nrhs,prhs); break;
*/


		/*
		 * wrapper to libpvme routines
		 */

		/* m2pvmectrl.c, PVM Control */
		case 107:	m2pvme_is(nlhs,plhs,nrhs,prhs);		break;
		case 106:	m2pvme_default_config(nlhs,plhs,nrhs,prhs); break;
		case 105:	m2pvme_start_pvmd(nlhs,plhs,nrhs,prhs);	break;
		case 104:	m2pvme_halt(nlhs,plhs,nrhs,prhs); break;

		/* m2pvmeprocctrl.c, Process Control */
#ifndef M4
		case 306:	m2pvme_spawn(nlhs,plhs,nrhs,prhs); break;
#endif

		/* m2pvmeupk.c, Packing/Unpacking Data extensions */
#ifdef M4
		case  85:	m2pvme_pkmat(nlhs,plhs,nrhs,prhs); break;
		case 152:	m2pvme_upkmat(nlhs,plhs,nrhs,prhs); break;
		case 153:	m2pvme_upkmat_name(nlhs,plhs,nrhs,prhs); break;
		case 154:	m2pvme_upkmat_rest(nlhs,plhs,nrhs,prhs); break;
#else
		case 706:	m2pvme_pkarray(nlhs,plhs,nrhs,prhs); break;
		case 707:	m2pvme_upkarray(nlhs,plhs,nrhs,prhs); break;
		case 708:	m2pvme_upkarray_name(nlhs,plhs,nrhs,prhs); break;
		case 709:	m2pvme_upkarray_rest(nlhs,plhs,nrhs,prhs); break;
#endif
	
		default: mexErrMsgTxt("Function not implemented on this "
				      "platform or unknown operation code.\n");
	};

	return;
}

static void  
m2pvmAtExitWarning() 
{ 
        mexPrintf("m2pvmAtExitWarning(): this Matlab instance is dying or losing its\n" 
                  "linkage to PVM in an unexpected way.\n" 
                  "Possibly your DP/PVM system is now in an undefined state.\n"); 
        return; 
} 
 
 
static void 
pvme_link() 
{ 
        if ( !mexIsLocked() ) { 
                mexLock(); 
                if ( atExitSubscribe(&m2pvmAtExitWarning) < 0 ) { 
                        mexErrMsgTxt("pvme_link(): atExitSubscribe() failed.\n" 
                                     "This is a bug probably. Please report it.\n"); 
                } 
        } 
/*      else { 
                mexPrintf("This Matlab instance is already linked to PVM.\n"); 
        } 
*/      return; 
} 
 
static void 
pvme_unlink(int nlhs, mxArray *plhs[]) 
{ 
        plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL); 
 
 
        if ( mexIsLocked() ) { 
                mexUnlock(); 
                if ( atExitUnsubscribe(&m2pvmAtExitWarning) < 0 ) { 
                        mexErrMsgTxt("pvme_unlink(): atExitUnsubscribe() failed.\n" 
                                     "This is a bug probably. Please report it.\n"); 
                } 
                mxGetPr(plhs[0])[0] = (double) 0; 
        } 
/*      else { 
                mexPrintf("This Matlab instance is already unlinked from PVM.\n"); 
                mxGetPr(plhs[0])[0] = (double) -1; 
        } 
*/      return; 
} 



