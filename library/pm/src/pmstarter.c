/*
 * stand alone matlab starter
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include "pvm3.h"
#include <string.h>
#ifdef WIN32
#include <process.h>
#else
#include "unistd.h"
#endif


#define CMD_MAX		3
#define CMD_ARGS_MAX	30

#ifndef WIN32 /* Unix */
#define TERM_CMD	"xterm"
#define TERM_ARGS1	"-sb -sl 500 -j -T "
#define TERM_ARGS2      " -e "
#define NICE_CMD	"/usr/bin/nice"
#define NICE_LOW        19 
#define NICE_NORMAL     10 /* can only set if spawning task has nice <=10 */
/*#define MATLAB_ARGS	"-nosplash -xrm *Desk:0 -xrm *preloadIDE:Off -nojvm"*/
#define MATLAB_ARGS	"-nosplash -nojvm"
#endif

static void  adjustrunmode(char *cmd[], char *cmdargs[], char mode);
static void  adjustpriority(char *cmd[], char *cmdargs[], char *priority);
static void  adjustmatlab(char *cmd[], char *cmdargs[], char *matlabver);
static char* getrunmode();
static char* getmatlabcmd(char *matlabver);
static void  append(int max, char *arv[], char *str);
static void  print(char *arv[]);


int main(int argc, char **argv) {
  
  char	mode;
  char	*matlabver;
  char	*priority;
  char	*cmd[CMD_MAX];
  char	*cmdargs[CMD_ARGS_MAX];
  int	i;
  
  
  /*
   * process calling arguments
   */
  
  switch (argc) {
    
  case 2:
    
    /*
     * print usage (dpmatlab --help)
     */
    printf("Usage: pmstart \n");
    printf("5 | 6      (matlab version)\n");
    printf("normal | low   (priority)\n");
    printf("console | output filename (runmode)\n");
#define NUMDIRECT 3
    printf("DISPLAY=...\n");
    printf("PMSPAWN_BLOCK=1 | 0\n");
    printf("PMSPAWN_WD=...\n");
    printf("PMSPAWN_TRY=...\n");
    printf("PMSPAWN_CATCH=...\n");
    printf("PMSPAWN_VM=vmid\n");
#define ARGCTOTAL 10	/* one is added for argv[0] */
    exit(EXIT_SUCCESS);
    
  case ARGCTOTAL:
    /*
     * controlled mode; take over args
     */
    mode = 'c';
    printf("Arguments given:\n");
    for (i=1; i<ARGC2ENV+1; i++) {
      printf("%s\n",argv[i]);
      if ( putenv(argv[i]) ) {
	printf("Fatal Error: while writing "
	       "arguments to environment.");
	exit(EXIT_FAILURE);
      }
    }
    printf("%s \n",argv[i]); matlabver = argv[i];
    i++;
    printf("%s \n",argv[i]); priority  = argv[i];
    break;
    
  case 1:
    
    /*
     * default mode
     */
    
    mode = 'd';
    printf("Defaults:\n");
#ifdef M4
    matlabver = "4";      printf("%s\n",matlabver);
#else
    matlabver = "6";      printf("%s\n",matlabver);
#endif
    priority  = "normal"; printf("%s\n",priority);
    runmode = "console";
    break;
    
  default:
    
    /*
     * error
     */
    
    printf("Fatal Error: Wrong number of arguments given,\n"
	   "             see dpmatlab --help\n"); 
    printf("argc: %d\n",argc);
    printf("argv:\n");
    print(argv);
    exit(EXIT_FAILURE);
  };
  
  
  /*
   * adjust command and arguments for start up
   */
  
  cmd[0] = cmdargs[0] = (char*)0;
  adjustrunmode(cmd, cmdargs, mode);
  adjustpriority(cmd, cmdargs, priority);
  adjustmatlab(cmd, cmdargs, matlabver);
  
  /*
   * start matlab
   */
  
  printf("execvp() the following:\n");
  printf("commands (only the first one):\n");
  print(cmd);
  printf("arguments:\n");
  print(cmdargs);
  fflush(stdout);
  if ( execvp(cmd[0],cmdargs) ) {
    printf("Fatal Error: execvp() failed.\n");
  }
  
  /* this point should never reached */
  exit(EXIT_FAILURE);
}


#ifdef WIN32

static void
adjustrunmode(char *cmd[], char *cmdargs[], char mode) {
  char	*runmode;
  
  if ( mode == 'c' ) {
    runmode = getrunmode();
    if ( !strcmp(runmode,"bg") ) {
      /*
       * controlled/background:
       */
      append(CMD_MAX,      cmd,     "cmd");
      append(CMD_ARGS_MAX, cmdargs, "cmd /c start /min");
      
      return;
    }
  }

  /*
   * default or controlled/foreground:
   * adjust terminal
   */
  
  append(CMD_MAX,      cmd,     "cmd");
  append(CMD_ARGS_MAX, cmdargs, "cmd /c start");
  
  return;
}


static void
adjustpriority(char *cmd[], char *cmdargs[], char *priority) {
  
  if ( !strcmp(priority,"low") ) {
    append(CMD_ARGS_MAX, cmdargs, "/low");
  }
  
  return;
}


static void
adjustmatlab(char *cmd[], char *cmdargs[], char *matlabver) {
  char	*matlabcmd;
  
  matlabcmd = getmatlabcmd(matlabver);
  append(CMD_ARGS_MAX, cmdargs, matlabcmd);
  
  return;
}


#else /* Unix */


static void
adjustrunmode(char *cmd[], char *cmdargs[], char mode) {
  char	*runmode;
  
  if ( mode == 'c' ) {
    runmode = getrunmode();
    if ( !strcmp(runmode,"bg") ) {
      /*
       * controlled/background:
       * don't adjust terminal
       */
      return;
    }
  }
  
  /*
   * default or controlled/foreground:
   * adjust terminal
   */
  
  append(CMD_MAX,      cmd,     TERM_CMD);
  append(CMD_ARGS_MAX, cmdargs, TERM_CMD);
  append(CMD_ARGS_MAX, cmdargs, TERM_ARGS1);
  append(CMD_ARGS_MAX, cmdargs, getenv("HOST"));
  append(CMD_ARGS_MAX, cmdargs, TERM_ARGS2);
  return;
}


static void
adjustpriority(char *cmd[], char *cmdargs[], char *priority) {
  int curr_nice, nice_incr, nice_limit;
  char nice_incr_str[4];  
  char ch;
  
  if ( !strcmp(priority,"low") ) {
    nice_limit = NICE_LOW;
  }
  else {
    nice_limit = NICE_NORMAL;
  }
  
  /* get current priority! */
  curr_nice = nice(0);
  nice_incr = nice_limit - curr_nice;
  if (nice_incr < 0) {
    nice_incr = 0;
  }
  sprintf(nice_incr_str,"-%d",nice_incr);

  append(CMD_MAX,      cmd,     NICE_CMD);
  append(CMD_ARGS_MAX, cmdargs, NICE_CMD);
  append(CMD_ARGS_MAX, cmdargs, nice_incr_str);
  
  return;
}


static void
adjustmatlab(char *cmd[], char *cmdargs[], char *matlabver) {
  char	*matlabcmd;
  
  matlabcmd = getmatlabcmd(matlabver);
  append(CMD_MAX,      cmd,     matlabcmd);
  append(CMD_ARGS_MAX, cmdargs, matlabcmd);
  append(CMD_ARGS_MAX, cmdargs, MATLAB_ARGS);
  
  return;
}

#endif


static char*
getrunmode() {
  char	*runmode;
  
  if ( !( runmode = getenv("PMSPAWN_RUNMODE") ) ) {
    printf("Fatal Error: Can't determine run mode.\n"
	   "             Environ. var. PMSPAWN_RUNMODE not set.\n");
    exit(EXIT_FAILURE);
  }
  
  return (runmode);
}


static char*
getmatlabcmd(char *matlabver) {
  char	*matlabcmd;
  
  if ( !strcmp(matlabver,"4") ) {
    if ( !( matlabcmd = getenv("M4_CMD") ) ) {
      /* then we expect */
      matlabcmd = "matlab";
    }
  }
  else if ( !strcmp(matlabver,"5") ) {
    if ( !( matlabcmd = getenv("M5_CMD") ) ) {
      /* then we expect */
      matlabcmd = "matlab";
    }
  }
  else {
    if ( !( matlabcmd = getenv("M6_CMD") ) ) {
      /* then we expect */
      matlabcmd = "matlab";
		}
  }
  return (matlabcmd);
}

static void
append(int max, char *arv[], char *str) {
  int 	i;
  char	*str_tmp;
  
  for (i=0; i<max-1; i++) {
    if ( arv[i] == NULL ) {
      break;
    }
  }
  
  if ( strlen(str) == 0 ) {
		return;
  }
  
  /*
   * str must be duplicated because strtok(3) modifies
   * the string it tokenise; 
   * str_tmp may not be freed after processing because
   * arv[] holds pointers to parts of str_tmp's content
   * and is returned outside;
   * str_tmp is freed automatically at process exit
   */
  str_tmp = strdup(str);
  
  arv[i] = strtok(str_tmp," ");
  i++;
  
  while ( ( arv[i]=strtok(NULL," ") ) ) {
    if ( i>=max ) {
      printf("Fatal Error: Too many commands or arguments.\n");
      exit(EXIT_FAILURE);
    }
    i++;
  }
  
  return;
}


static void
print(char *arv[]) {
  int 	i;
  
  for (i=0; arv[i]!=NULL; i++) {
    printf("[%d]: %s\n",i,arv[i]);
  }
  
  return;
}





