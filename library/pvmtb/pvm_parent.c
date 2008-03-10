#include <stdio.h>
#include "pvm3.h"
int main(int argc, char*argv[]){
	int parent;
	parent=pvm_parent();
	printf("Parent==%d\n",parent);
	return(0);
}

