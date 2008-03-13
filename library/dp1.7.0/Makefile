# debug output enabled
#PARAMS= -lpvm3 -DDEBUG 

#debug output disabled
PARAMS= -lpvm3

m2pvm.mexmac: m2pvm.c
	mex $(PARAMS) m2pvm.c -L$$PVM_ROOT/lib -L/opt/local/lib -I/opt/local/include

clean:
	rm -f m2pvm.mexmac *~
