/*
 * pvme control functions
 * 
 * Copyright (c) 1998-1999 University of Rostock, Germany, 
 * Institute of Automatic Control. All rights reserved.
 *
 * See file ``Copyright'' for terms of copyright.
 *
 * Author: A. Westphal (Nov 98, initial version)
 *
 */


#include "pvme.h"

#include <pvm3.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

int pvme_spawn(char *task, char **argv, int flag, char *where, int ntask, int *tids){
/* spawn PVM tasks, wait for their "enrolling" as PVM instances, 
	return the number of spawned tasks and their tids */
	int	wherevm, ntaskvm, info, retinfo;
	struct	pvmtaskinfo *taskp;
	int i, j, counter;

	int timed_out;
	time_t stime, ttime;
	#ifndef TIMEOUT
		int TIMEOUT = 120;
	#endif

	/* get infos of all running PVM tasks */
	/* taskp[x].ti_tid, taskp[x].ti_ptid and 
		taskp[x].ti_flag will be used*/

	/* for all the tasks on the virtual machine */
	wherevm = 0; 
	timed_out = 0;

	/* spawn the new tasks */
	retinfo = pvm_spawn(task, argv, flag, where, ntask, tids);
	if (retinfo < 1) {
		printf("pvme_spawn: pvm_spawn() failed");
		return(PvmeErr);
	}


	/* get the status of spawned tasks */

	time(&stime);
	while (!timed_out) {
		time(&ttime);
		if ((ttime - stime ) > TIMEOUT)
			timed_out = 1;
		counter = 0;
		/* get new ID's */
		info = pvm_tasks(wherevm,&ntaskvm,&taskp);
		for (i=0; i<retinfo; i++) {
			for (j=0; j<ntaskvm; j++) {
				/* compare the tids with the tid and the ptid
					of each task */
				if (((tids[i] == taskp[j].ti_tid) || (tids[i] == taskp[j].ti_ptid)) && (taskp[j].ti_flag == 4))
					counter = counter++;
			}
		}
		if (counter == retinfo)
			break;
	}

	if (timed_out)
		printf("pvme_spawn: timeout after %d seconds\n", TIMEOUT);

	/* find out the tid for each instance - even it is a directly
		spawned instance or its child (i.e. spawned via 'XTERM') */
	for (i=0; i<retinfo; i++) {
		info = pvm_tasks(tids[i],&ntaskvm,&taskp);
		if ((tids[i] != taskp[0].ti_tid) && (tids[i] == taskp[0].ti_ptid))
			tids[i] = taskp[0].ti_ptid;
		if (taskp[0].ti_flag != 4)
			tids[i] = PvmDSysErr;
	}

return (retinfo);
}



