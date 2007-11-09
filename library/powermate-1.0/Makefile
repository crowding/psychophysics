all:	rotomatic pulseled

rotomatic:	rotomatic.o findpowermate.o
	$(CC) findpowermate.o rotomatic.o -o rotomatic

pulseled:	pulseled.o findpowermate.o
	$(CC) findpowermate.o pulseled.o -o pulseled

clean:
	rm -f *.o *~ rotomatic pulseled

%.o:    %.c
	$(CC) -O2 -Wall -c $< -o $@
