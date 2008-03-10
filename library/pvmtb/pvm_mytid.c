#include <stdio.h>
#include "pvm3.h"
int main(int argc, char*argv[]){
	int tid;
	tid=pvm_mytid();
	printf("TID==%d\n",tid);
	return(0);
}

