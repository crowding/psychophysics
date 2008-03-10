%TEV_MASK_CHECK		Comprueba bits en variable string máscara de traza
%
%  info = TEV_MASK_CHECK(mask, kind)
%
%  mask(string) máscara de TEV_MASK_LENGTH (36) chars a consultar
%  kind(string) nombre del bit de máscara a consultar
%       'FIRST'==0                                  ADDHOSTS   ==  0
%	BARRIER==1 BCAST==2   BUFINFO==3 CONFIG==4  DELETE     ==  5
%	DELHOSTS   EXIT       FREEBUF    GETFDS     GETINST    == 10
%	GETOPT     GETRBUF    GETSBUF    GETTID     GSIZE      == 15
%	HALT       INITSEND   INSERT     JOINGROUP  KILL       == 20
%	LOOKUP     LVGROUP    MCAST      MKBUF      MSTAT      == 25
%	MYTID      NOTIFY     NRECV      PARENT     PERROR     == 30
%	PKBYTE     PKCPLX     PKDCPLX    PKDOUBLE   PKFLOAT    == 35
%	PKINT      PKUINT     PKLONG     PKULONG    PKSHORT    == 40
%	PKUSHORT   PKSTR      PROBE      PSTAT      RECV       == 45
%	RECVF      SEND       SENDSIG    SETOPT     SETRBUF    == 50
%	SETSBUF    SPAWN      START_PVMD TASKS      TICKLE     == 55
%	TIDTOHOST  TRECV      UPKBYTE    UPKCPLX    UPKDCPLX   == 60
%	UPKDOUBLE  UPKFLOAT   UPKINT     UPKUINT    UPKLONG    == 65
%	UPKULONG   UPKSHORT   UPKUSHORT  UPKSTR     VERSION    == 70
%	REG_HOSTER REG_RM     REG_TASKER REG_TRACER NEWTASK    == 75
%	ENDTASK    SPNTASK    ARCHCODE   CATCHOUT   GETMWID    == 80
%	GETTMASK   HOSTSYNC   PACKF      PRECV      PSEND      == 85
%	REDUCE     SETMWID    SETTMASK   UNPACKF    GATHER     == 90
%	SCATTER    PUTINFO    GETINFO    DELINFO    GETMBOXINFO== 95
%	NEWCONTEXT FREECONTEXTSETCONTEXT GETCONTEXT SIBLINGS   ==100
%	GETMINFO   SETMINFO   ADDMHF     DELMHF     MHF_INVOKE ==105
%	TIMING     PROFILING  USER_DEFINED==108     MAX        ==108
%
%  info   (int) valor del bit de máscara interrogado
%      0 No activado
%      1    activado
%
%  Implementación MEX: src/TEV_MASK_CHECK.c, pvm/MEX/TEV_MASK_CHECK.mexlx

