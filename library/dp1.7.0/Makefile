# debug output enabled
#PARAMS= -lpvm3 -DDEBUG 

#debug output disabled
PARAMS= -lpvm3

m2pvm.mexmac: m2pvm.c
	mex $(PARAMS) m2pvm.c

clean:
	rm -f m2pvm.mexmac *~
