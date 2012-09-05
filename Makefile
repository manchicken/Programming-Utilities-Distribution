# Makefile

# Paths are set here
BINPATH=__BIN_PATH__
LIBPATH=__LIB_PATH__
DATAPATH=__DATA_PATH__
PUD_GLOBAL_CONFIG=\"__GLOBAL_CONFIG__\"
PUD_VERSION=\"`cat VERSION`\"

# If your machine has different commands for these programs (these commands are standard for most GNU setups) then change them accordingly.
CC=gcc -Wall -Wno-unused -ggdb3 -DPUD_GLOBAL_CONFIG=$(PUD_GLOBAL_CONFIG) -DPUD_PROG_VERSION=$(PUD_VERSION)
RM=rm -f
AR=ar rs
RANLIB=ranlib
CP=cp -rf

all: libpud.a
	$(CC) -o sizeof sizeof.c
	$(CC) newpl.c -o newpl -L./ -lpud
	$(CC) newpm.c -o newpm -L./ -lpud
	$(CC) newc.c -o newc -L./ -lpud
	$(CC) newcc.c -o newcc -L./ -lpud
	$(CC) newh.c -o newh -L./ -lpud
	$(CC) newphp.c -o newphp -L./ -lpud
	$(CC) pudconf.c -o pudconf -L./ -lpud

clean:
	$(RM) sizeof libpud.o libpud.a newpl newpm newc newphp newcc newh pudconf

libpud.o: libpud.c
	$(CC) -c $< -o $@

libpud.a: libpud.o
	$(AR) $@ libpud.o
	$(RANLIB) $@
