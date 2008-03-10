%PVM_SENDSIG		Envía una señal a otra tarea PVM (página man signal(7))
%
%  info = pvm_sendsig(tid, signum)
%
%  tid  (int) identificador de la tarea
%  info (int) código retorno
%       0 PvmOk
%      -2 PvmBadParam
%     -14 PvmSysErr
%
%  signum (int) señal a enviar. Algunas señales POSIX.1 son
%      SIGHUP        1        A      Hangup detected on controlling terminal
%      SIGINT        2        A      Interrupt from keyboard
%      SIGQUIT       3        A      Quit from keyboard
%      SIGILL        4        A      Illegal Instruction
%      SIGABRT       6        C      Abort signal from abort(3)
%      SIGFPE        8        C      Floating point exception
%      SIGKILL       9       AEF     Kill signal
%      SIGSEGV      11        C      Invalid memory reference
%      SIGPIPE      13        A      Broken pipe: write to pipe with no readers
%      SIGALRM      14        A      Timer signal from alarm(2)
%      SIGTERM      15        A      Termination signal
%      SIGUSR1   30,10,16     A      User-defined signal 1
%      SIGUSR2   31,12,17     A      User-defined signal 2
%      SIGCHLD   20,17,18     B      Child stopped or terminated
%      SIGCONT   19,18,25            Continue if stopped
%      SIGSTOP   17,19,23    DEF     Stop process
%      SIGTSTP   18,20,24     D      Stop typed at tty
%      SIGTTIN   21,21,26     D      tty input for background process
%      SIGTTOU   22,22,27     D      tty output for background process
%
%  Implementación MEX completa: src/pvm_sendsig.c, pvm/MEX/pvm_sendsig.mexlx

