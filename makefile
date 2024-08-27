PROGNAME     = psxmcr
#CC          = /usr/bin/gcc
#CC          = /usr/bin/clang
CCWIN        = /usr/bin/x86_64-w64-mingw32-gcc
CCWIN32      = /usr/bin/i686-w64-mingw32-gcc

CFLAGS       = -std=c2x -pipe -fno-plt -g3 -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer
CFLAGS64     = -m64 -march=x86-64 -mtune=generic
CFLAGS32     = -m32 -march=i386 -mtune=generic

DEBUG        = -Og -DDEBUG #-Wl,--enable-linker-version
OPTIMIZE     = -O2 -flto -fstack-protector-strong -fstack-clash-protection -D_FORTIFY_SOURCE=2 -fPIE -pie -Wl,-O1 -Wl,--sort-common -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -Wl,-z,pack-relative-relocs #-Wl,--enable-linker-version
OPTIMIZE_WIN = -O2 -flto -fstack-protector-strong -fstack-clash-protection -static

WARNINGS     = -Wpedantic -Wall -Wextra -Wformat=2 -Wconversion -Wpointer-arith -Wshadow -Wundef -Wdouble-promotion -Wstrict-prototypes -Wold-style-definition
HIDE         = -Wno-conversion -Wno-gnu-binary-literal #clang

ASAN         = -fsanitize=address,undefined
COVERAGE     = -fprofile-arcs -ftest-coverage
ANALYZE      = -fanalyzer

SRCDIR       = ./
VERSION      = alpha
SRC          = $(SRCDIR)/*.c
HEADERS      = $(SRCDIR)/*.h

all: $(PROGNAME)_$(VERSION).Og

release: all linux linux32 windows windows32

linux:   $(PROGNAME)_$(VERSION).bin
linux32: $(PROGNAME)32_$(VERSION).bin

#linux host
windows:   $(PROGNAME)_$(VERSION).exe
windows32: $(PROGNAME)32_$(VERSION).exe

#windows host
windows-msys:   $(PROGNAME)_$(VERSION).msys.exe
windows32-msys: $(PROGNAME)32_$(VERSION).msys.exe

$(PROGNAME)_$(VERSION).Og: $(SRC)
	$(CC) -o $@ $^ $(CFLAGS) $(CFLAGS64) $(WARNINGS) $(HIDE) $(DEBUG) $(ASAN) -Werror
	objcopy --compress-debug-sections $@

$(PROGNAME)_$(VERSION).bin: $(SRC)
	$(CC) -o $@ $^ $(CFLAGS) $(CFLAGS64) $(WARNINGS) $(HIDE) $(OPTIMIZE)
	objcopy --only-keep-debug --compress-debug-sections $@ $@.debug
	objcopy --strip-unneeded --remove-section=.comment --add-gnu-debuglink=$@.debug $@

$(PROGNAME)32_$(VERSION).bin: $(SRC)
	$(CC) -o $@ $^ $(CFLAGS) $(CFLAGS32) $(WARNINGS) $(HIDE) $(OPTIMIZE)
	objcopy --only-keep-debug --compress-debug-sections $@ $@.debug
	objcopy --strip-unneeded --remove-section=.comment --add-gnu-debuglink=$@.debug $@

$(PROGNAME)_$(VERSION).exe: $(SRC)
	$(CCWIN) -o $@ $^ $(CFLAGS) $(CFLAGS64) $(WARNINGS) $(HIDE) $(OPTIMIZE_WIN)
	objcopy --strip-unneeded --remove-section=.comment $@

$(PROGNAME)32_$(VERSION).exe: $(SRC)
	$(CCWIN32) -o $@ $^ $(CFLAGS) $(CFLAGS32) $(WARNINGS) $(HIDE) $(OPTIMIZE_WIN)
	objcopy --strip-unneeded --remove-section=.comment $@

$(PROGNAME)_$(VERSION).msys.exe: $(SRC)
	gcc -o $@ $^ $(CFLAGS) $(CFLAGS64) $(WARNINGS) $(HIDE) $(OPTIMIZE_WIN)
	objcopy --strip-unneeded --remove-section=.comment $@

$(PROGNAME)32_$(VERSION).msys.exe: $(SRC)
	gcc -o $@ $^ $(CFLAGS) $(CFLAGS32) $(WARNINGS) $(HIDE) $(OPTIMIZE_WIN)
	objcopy --strip-unneeded --remove-section=.comment $@
clean:
	rm -vf $(PROGNAME)* *.gcno

cppcheck:
	cppcheck --template=gcc --std=c11 --force --error-exitcode=-1 --enable=all --disable=missingInclude --check-level=exhaustive $(SRCDIR)/*.c

codespell:
	codespell --count --builtin clear,rare,informal,names
