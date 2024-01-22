PROGNAME     = psxmcr
#CC          = /usr/bin/gcc
#CC          = /usr/bin/clang
CCWIN        = /usr/bin/x86_64-w64-mingw32-gcc
CCWIN32      = /usr/bin/i686-w64-mingw32-gcc

CFLAGS       = -std=c2x -pipe -fno-plt -g3 -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer
CFLAGS64     = -m64 -march=x86-64 -mtune=generic
CFLAGS32     = -m32 -march=i386 -mtune=generic

DEBUG        = -Og -DDEBUG
OPTIMIZE     = -O2 -flto -fstack-protector-strong -fstack-clash-protection -D_FORTIFY_SOURCE=2 -Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now
OPTIMIZE_WIN = -O2 -flto -fstack-protector-strong -fstack-clash-protection -D_FORTIFY_SOURCE=0 -static

WARNINGS     = -Wpedantic -Wall -Wextra -Wformat -Wformat-security -Wpointer-arith -Wshadow -Wstrict-prototypes
HIDE         = -Wno-conversion -Wno-gnu-binary-literal

ASAN         = -fsanitize=address,undefined,leak
COVERAGE     = -fprofile-arcs -ftest-coverage
ANALYZE      = -fanalyzer

SRCDIR=./
SRC=$(SRCDIR)/*.c
HEADERS=$(SRCDIR)/*.h

all: $(PROGNAME).Og

lin: $(PROGNAME).bin
lin32: $(PROGNAME)32.bin

#linux host
mingw-win: $(PROGNAME).exe
mingw-win32: $(PROGNAME)32.exe

#windows host
win: $(PROGNAME).msys.exe
win32: $(PROGNAME)32.msys.exe

$(PROGNAME).Og: $(SRC)
	$(CC) -o $@ $^ $(CFLAGS) $(CFLAGS64) $(WARNINGS) $(HIDE) $(DEBUG) -Werror

$(PROGNAME).bin: $(SRC)
	$(CC) -o $@ $^ $(CFLAGS) $(CFLAGS64) $(WARNINGS) $(HIDE) $(OPTIMIZE)
	objcopy --only-keep-debug $@ $@.debug
	objcopy --strip-unneeded $@
	objcopy --add-gnu-debuglink=$@.debug $@

$(PROGNAME)32.bin: $(SRC)
	$(CC) -o $@ $^ $(CFLAGS) $(CFLAGS32) $(WARNINGS) $(HIDE) $(OPTIMIZE)
	objcopy --only-keep-debug $@ $@.debug
	objcopy --strip-unneeded $@
	objcopy --add-gnu-debuglink=$@.debug $@

$(PROGNAME).exe: $(SRC)
	$(CCWIN) -o $@ $^ $(CFLAGS) $(CFLAGS64) $(WARNINGS) $(HIDE) $(OPTIMIZE_WIN)
	objcopy --strip-unneeded $@

$(PROGNAME)32.exe: $(SRC)
	$(CCWIN32) -o $@ $^ $(CFLAGS) $(CFLAGS32) $(WARNINGS) $(HIDE) $(OPTIMIZE_WIN)
	objcopy --strip-unneeded $@

$(PROGNAME).msys.exe: $(SRC)
	gcc -o $@ $^ $(CFLAGS) $(CFLAGS64) $(WARNINGS) $(HIDE) $(OPTIMIZE_WIN)
	objcopy --strip-unneeded $@

$(PROGNAME)32.msys.exe: $(SRC)
	gcc -o $@ $^ $(CFLAGS) $(CFLAGS32) $(WARNINGS) $(HIDE) $(OPTIMIZE_WIN)
	objcopy --strip-unneeded $@

clean:
	rm -vf $(PROGNAME)*

cppcheck:
	cppcheck --template=gcc --std=c11 --force --error-exitcode=-1 --enable=all $(SRCDIR)/*.c
	#git runner doesn't support some options yet
	#--check-level=exhaustive --disable=missingInclude

