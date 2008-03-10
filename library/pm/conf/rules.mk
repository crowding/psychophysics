#	make rules
#
#	Copyright (c) 1995-1999 University of Rostock, Germany, 
#	Institute of Automatic Control. All rights reserved.
#
#	See file ``Copyright'' for terms of copyright.
#
#	Author: S. Pawletta


.c:
	$(CC) $(CFLAGS) $(LDFLAGS) $< $(LIBS) -o $@


.c.$(MEXSUFFIX):
	$(CC) $(CFLAGS) -I$(MEXINC) $(MEXLDFLAGS) $< $(MEXLIB) $(HLIBS) -o $@

