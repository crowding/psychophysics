/*
 * pvme control functions
 * 
 * Copyright (c) 1995-1999 University of Rostock, Germany, 
 * Institute of Automatic Control. All rights reserved.
 *
 * See file ``Copyright'' for terms of copyright.
 *
 * Authors: S. Pawletta, A. Westphal
 *
 */


#include "pvme.h"

#include "misc.h"
#include <pvm3.h>
#include <stdio.h>
#include <signal.h>
#ifndef WIN32
#include <unistd.h>
#endif
#include <string.h>


/********************************************************
 *							*
 * bypass for pvm_start_pvmd() for M4/Linux		*
 *							*
 * Attention: unsafe implementation; dirty conversion	*
 *	      of return value from system(3)         	*
 *							*
 ********************************************************/

#ifdef PVMD_BYPASS
#include <string.h>
#include <stdlib.h>
static int	
pvm_start_pvmd_bypass(int argc, char **argv, int block)
{
	int	i, info, cmdlength=0;
	char	*cmd;

	/* 
	 * check block, wrong setting could be dangerous 
	 */
	if (block!=0 && block !=1) {
		printf("pvm_start_pvmd_bybass(): block parameter is "
		       "other than 0 or 1\n");
		return (PvmeErr);
	}

	/* 
	 * calculate cmdlength 
	 */
	cmdlength = strlen("pvm_start_pvmd b");
	for (i=0; i<argc; i++) {
		cmdlength = cmdlength + 1 + strlen(argv[i]);
	}

	/* 
	 * allocate and fill cmd 
 	 */
	cmd = (char*) mxCalloc(cmdlength+1,sizeof(char));
	if (!cmd) {
		printf("pvm_start_pvmd_bybass(): mxCalloc() failed\n");
		return (PvmeErr);
	}
	strcat(cmd,"pvm_start_pvmd");
	if (block) {
		strcat(cmd," 1");
	}
	else {
		strcat(cmd," 0");
	}
	for (i=0; i<argc; i++) {
		strcat(cmd," "); strcat(cmd,argv[i]); 
	}
		
	/*
	 * evaluate cmd
	 */
	info = system(cmd);

	/*
	 * dirty conversion of system()'s return code
	 */
	if (info == 0) {
		return (PvmOk);
	}
	if (info == 58368) {
		return (PvmDupHost);
	}
	if (info == 61952) {
		return (PvmSysErr);
	}
	if (info == 32512) {
		printf("pvm_start_pvmd_bypass(): executable pvm_start_pvmd "
		       "cannot be found;\n");
		return (PvmeErr);
	}
	printf("pvm_start_pvmd_bypass(): system() returns: %i\n",info);
	printf("pvm_start_pvmd_bypass(): system() returns unknown error code");
	return (PvmeErr);
}
#endif /*PVM_DBYPASS*/ /* bypass for M4/Linux*/


/************************
 *			*
 * internal functions	*
 *			*
 ************************/

static int  pvmestartpvmd(int argc, char **argv, int block);
static void pvmeAtExitpvmhalt ();

static int 
pvmestartpvmd(int argc, char **argv, int block)
{
	int	info;

#ifdef PVMD_BYPASS
	info = pvm_start_pvmd_bypass(argc,argv,block);
#else
	info = pvm_start_pvmd(argc,argv,block);
#endif
	if ( info == PvmOk ) {
		if ( atExitSubscribe(&pvmeAtExitpvmhalt) < 0 ) {
			printf("pvmestartpvmd(): atExitSubscribed() failed.\n");
			return (PvmeErr);
		}
	}

	return (info);
}


static void 
pvmeAtExitpvmhalt () 
{
	printf("pvmeAtExitpvmhalt(): this process is dying or losing its linkage to PVM.\n"
	       "It has been started PVM, but not halted.\n"
	       "Possibly PVM is still running.\n");
	return;
}


/************************
 *			*
 * interface functions	*
 *			*
 ************************/

int
pvme_is()
{
	if ( pvm_mytid() < 0 ) {
		return 0;
	}
	else {
		return 1;
	}
}


int
pvme_default_config(int conf_lines, char **conf)
{
	char	tmpfilename[FILENAME_MAX];
	FILE	*ff;
	int i;
#ifdef WIN32
	char *temporary, *uid;
#endif

	/* write default configuration to temporary/pvmedefconf.(uid) */
#ifndef WIN32
	/* on unix */
	if ( 0 > sprintf(tmpfilename,"/tmp/pvmedefconf.%u",getuid()) ) {
		printf("pvme_default_config(): sprintf() failed.\n");
		return (PvmeErr);
	}
#else
	/* on windows */
	temporary = getenv("TEMP");
	if (temporary == NULL){
		temporary = getenv("TMP");
		if (temporary == NULL){
			printf("pvme_default_config(): no TEMP or TMP set .\n");
			return (PvmeErr);
		}
	}
	uid = getenv("USERNAME");
	if ( 0 > sprintf(tmpfilename,"%s\\pvmedefconf.%s",temporary,uid) ) {
		printf("pvme_default_config(): sprintf() failed.\n");
		return (PvmeErr);
	}
#endif
	if ( !(ff = fopen(tmpfilename,"w")) ) {
		printf("pvme_default_config(): fopen() failed.\n");
		return (PvmeErr);
	}
	for (i=0; i<conf_lines; i++) {
  		if ( 0 > fprintf(ff,"%s\n",conf[i]) ) {
			printf("pvme_default_config(): fprintf() failed.\n");
			return (PvmeErr);
		}
	}
	if ( 0 > fclose(ff) ) {
		printf("pvme_default_config(): fclose() failed.\n");
		return (PvmeErr);
	}

	return 0;
}

/* implementation from A. Westphal */
int 					
pvme_start_pvmd(int argc, char **argv, int block)
{
	char	tmpfilename[FILENAME_MAX];
	char	*tmpname;
	FILE	*stream;
	int	i;
#ifdef WIN32
	char *temporary, *uid;
#endif

	/* empty conf */
	if ( argc == 0 ) {
		return ( pvmestartpvmd(argc,argv,block) );
	}

	/* default conf */
	if ( argc == 1 && !strcmp(argv[0],"d") ) {
#ifndef WIN32
		if ( 0 > sprintf(tmpfilename,"/tmp/pvmedefconf.%u",getuid()) ) {
			printf("pvme_start_pvmd(): sprintf() failed.\n");
			return (PvmeErr);
		}
#else
		/* win32 ergaenzen */
		temporary = getenv("TEMP");
		if (temporary == NULL){
			temporary = getenv("TMP");
			if (temporary == NULL){
				printf("pvme_start_pvmd(): no TEMP or TMP set .\n");
				return (PvmeErr);
			}
		}
		uid = getenv("USERNAME");
		if ( 0 > sprintf(tmpfilename,"%s\\pvmedefconf.%s",temporary,uid) ) {
			printf("pvme_start_pvmd(): sprintf() failed.\n");
			return (PvmeErr);
		}
#endif
		argv[0] = tmpfilename;
		return ( pvmestartpvmd(argc,argv,block) );
	}

	/* file conf */
	/* the last string in argv have to be a valid filename */
	/* valid parameters are: -dmask, -nname, -s, -S, -f
		(see also the PVM manual) */
	if ( argc >= 1 ) {
	/* last parameter should be the hostfile - make a test with fopen */
	  stream = fopen(argv[argc-1],"r");
	  if (stream != NULL) {
	    /* assume its a hostfile or is there anybody who use 
	       the parameters... */
	    fclose(stream);
	    return ( pvmestartpvmd(argc,argv,block) );
	  }
	}


	/* matrix conf */
	if ( argc >= 1 && strcmp(argv[0],"d") ) {
	/* its no empty, default or file configuration -parameters for pvmd 
	   start are directly given in a string matrix */

		/* look for an unused filename */
		if ((tmpname = tmpnam(NULL)) == NULL ){
			printf("pvme_start_pvmd(): tmpnam() failed");
			return (PvmeErr);
		}
		/* create a temporary file */
		if ((stream = fopen(tmpname, "w+")) == NULL) {
			printf("pvme_start_pvmd(): fopen() failed");
			return (PvmeErr);
		}
		/* write config data into the temporary file */
		for (i=0; i<argc; i++) {
  			if ( 0 > fprintf(stream,"%s\n",argv[i]) ) {
				printf("pvme_start_pvmd(): fprintf() failed.\n");
				return (PvmeErr);
			}
		}
		fclose(stream);
		/* call the pvmd_starter */
		argc = 1;
		argv[0] = tmpname;
		i = pvmestartpvmd(argc,argv,block);
		if (remove(tmpname) != 0) {
				printf("pvme_start_pvmd(): remove() failed.\n");
				return (PvmeErr);
		}
		return i;
	}
	printf("pvme_start_pvmd(): damon startup failed\n");
	return (PvmeErr);
}


#if 0
/* implementation from S. Pawletta */
int 
pvme_start_pvmd(int argc, char **argv, int block)
{
        char    tmpfilename[FILENAME_MAX];

        /* empty conf */
        if ( argc == 0 ) {
                return ( pvmestartpvmd(argc,argv,block) );
        }

        /* default conf */
        if ( argc == 1 && !strcmp(argv[0],"d") ) {
                if ( 0 > sprintf(tmpfilename,"/tmp/pvmedefconf.%u",getuid()) ) {
                        printf("pvme_start_pvmd(): sprintf() failed.\n");
                        return (PvmeErr);
                }
                argv[0] = tmpfilename;
                return ( pvmestartpvmd(argc,argv,block) );
        }

        printf("pvme_start_pvmd(): Currently only empty or default conf is "
               "implemented\n");
        return (PvmeErr);
}
#endif

 
int 
pvme_halt() 
{
	int	info;
	void (*old_handler)(int); 

	/* unsubscribe pvmeAtExitpvmhalt() if it was subscribed */
	if ( atExitIsSubscribed(&pvmeAtExitpvmhalt) ) {
		if ( atExitUnsubscribe(&pvmeAtExitpvmhalt) ) {
			printf("pvme_halt(): atExitUnsubscribe() failed\n");
			return (PvmeErr);
		}
	}

	/* ignore SIGTERM */
	if ( (old_handler = signal(SIGTERM,SIG_IGN)) == SIG_ERR ) {
		printf("pvme_halt(): signal() failed\n");
		return (PvmeErr);
	}

	/* shutdown pvm */
	info = pvm_halt();

	/* restore original handler for SIGTERM */
	if ( (signal(SIGTERM,old_handler)) == SIG_ERR ) {
		printf("pvme_halt(): signal() failed\n");
		return (PvmeErr);
	}

	/* check return code of pvm_halt */
	if ( info < 0 ) {
		printf("pvme_halt(): pvm_halt() failed\n");
		return (info);
	}

	/* reset libpvm3 */
	pvm_exit();

        return (PvmOk);
}


