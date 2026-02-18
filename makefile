# -----
PROGNAME     = psxmcr
VERSION      = alpha
SRCDIR       = ./

# -----
# Default host compiler
#CC          ?= /usr/bin/gcc

# Cross compilers
CCWIN        ?= /usr/bin/x86_64-w64-mingw32-gcc
CCWIN32      ?= /usr/bin/i686-w64-mingw32-gcc
# Other tools
RM           = rm --force --verbose
MKDIR_P      = mkdir --parents --verbose
OBJCOPY      = objcopy
CPPCHECK     = cppcheck
ASTYLE       = astyle
CODESPELL    = codespell
CURL         = curl --silent --show-error

SRC          := $(wildcard $(SRCDIR)/*.c)
HEADERS      := $(wildcard $(SRCDIR)/*.h)

# -----
CFLAGS_BASE  = -std=c2x -pipe -fno-plt -g3 -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -fstrict-overflow -ftrapv
CFLAGS_64    = -m64 -march=x86-64 -mtune=generic
CFLAGS_32    = -m32 -march=i386 -mtune=generic

CFLAGS_WARN  = -Wpedantic -Wall -Wextra -Wformat=2 -Wconversion -Wpointer-arith -Wshadow -Wundef -Wdouble-promotion -Wstrict-prototypes -Wold-style-definition
CFLAGS_HIDE  = -Wno-conversion

CFLAGS_DEBUG = -Og -DDEBUG

OPTIMIZE     = -O2 -flto -fstack-protector-strong -fstack-clash-protection -D_FORTIFY_SOURCE=2 -fPIE -pie -Wl,-O1 -Wl,--sort-common -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -Wl,-z,pack-relative-relocs -Wl,--build-id -Wl,--enable-linker-version
OPTIMIZE_WIN = -O2 -flto -fstack-protector-strong -fstack-clash-protection -static

ASAN_FLAGS   = -fsanitize=address,undefined

# -----
TARGET_LIN_DBG   = $(PROGNAME)_$(VERSION).Og
TARGET_LIN_64    = $(PROGNAME)_$(VERSION).bin
TARGET_LIN_32    = $(PROGNAME)32_$(VERSION).bin
TARGET_WIN_64    = $(PROGNAME)_$(VERSION).exe
TARGET_WIN_32    = $(PROGNAME)32_$(VERSION).exe
TARGET_MSYS_64   = $(PROGNAME)_$(VERSION).msys.exe
TARGET_MSYS_32   = $(PROGNAME)32_$(VERSION).msys.exe

# -----
all: linuxdebug

release: linux linux32 windows windows32

# Linux host
linuxdebug: $(TARGET_LIN_DBG)
linux:      $(TARGET_LIN_64)
linux32:    $(TARGET_LIN_32)
windows:    $(TARGET_WIN_64)
windows32:  $(TARGET_WIN_32)

# Windows host
windows-msys:   $(TARGET_MSYS_64)
windows32-msys: $(TARGET_MSYS_32)

# -----
$(TARGET_LIN_DBG): $(SRC) $(HEADERS)
	$(CC) -o $@ $(SRC) $(CFLAGS_BASE) $(CFLAGS_64) $(CFLAGS_WARN) $(CFLAGS_HIDE) $(CFLAGS_DEBUG) $(ASAN_FLAGS) -Werror
	$(OBJCOPY) --compress-debug-sections $@

$(TARGET_LIN_64): $(SRC) $(HEADERS)
	@echo "Building Release Target (64-bit Linux): $@"
	$(CC) -o $@ $(SRC) $(CFLAGS_BASE) $(CFLAGS_64) $(CFLAGS_WARN) $(CFLAGS_HIDE) $(OPTIMIZE)
	$(OBJCOPY) --only-keep-debug --compress-debug-sections $@ $@.debug
	$(OBJCOPY) --strip-unneeded --remove-section=.comment --add-gnu-debuglink=$@.debug $@

$(TARGET_LIN_32): $(SRC) $(HEADERS)
	@echo "Building Release Target (32-bit Linux): $@"
	$(CC) -o $@ $(SRC) $(CFLAGS_BASE) $(CFLAGS_32) $(CFLAGS_WARN) $(CFLAGS_HIDE) $(OPTIMIZE)
	$(OBJCOPY) --only-keep-debug --compress-debug-sections $@ $@.debug
	$(OBJCOPY) --strip-unneeded --remove-section=.comment --add-gnu-debuglink=$@.debug $@

$(TARGET_WIN_64): $(SRC) $(HEADERS)
	@echo "Building Release Target (64-bit Windows): $@"
	$(CCWIN) -o $@ $(SRC) $(CFLAGS_BASE) $(CFLAGS_64) $(CFLAGS_WARN) $(CFLAGS_HIDE) $(OPTIMIZE_WIN)
	$(OBJCOPY) --strip-unneeded --remove-section=.comment $@

$(TARGET_WIN_32): $(SRC) $(HEADERS)
	@echo "Building Release Target (32-bit Windows): $@"
	$(CCWIN32) -o $@ $(SRC) $(CFLAGS_BASE) $(CFLAGS_32) $(CFLAGS_WARN) $(CFLAGS_HIDE) $(OPTIMIZE_WIN)
	$(OBJCOPY) --strip-unneeded --remove-section=.comment $@

$(TARGET_MSYS_64): $(SRC) $(HEADERS)
	@echo "Building Release Target (64-bit MSYS): $@"
	gcc -o $@ $(SRC) $(CFLAGS_BASE) $(CFLAGS_64) $(CFLAGS_WARN) $(CFLAGS_HIDE) $(OPTIMIZE_WIN)
	$(OBJCOPY) --strip-unneeded --remove-section=.comment $@

$(TARGET_MSYS_32): $(SRC) $(HEADERS)
	@echo "Building Release Target (32-bit MSYS): $@"
	gcc -o $@ $(SRC) $(CFLAGS_BASE) $(CFLAGS_32) $(CFLAGS_WARN) $(CFLAGS_HIDE) $(OPTIMIZE_WIN)
	$(OBJCOPY) --strip-unneeded --remove-section=.comment $@

clean:
	$(RM) $(TARGET_LIN_DBG) \
	      $(TARGET_LIN_64) $(TARGET_LIN_64).debug \
	      $(TARGET_LIN_32) $(TARGET_LIN_32).debug \
	      $(TARGET_WIN_64) \
	      $(TARGET_WIN_32) \
	      $(TARGET_MSYS_64) \
	      $(TARGET_MSYS_32) \
	      src/*.pch
	$(RM) -r ./.codespell

# Static code analysis
cppcheck:
	$(CPPCHECK) --template=gcc --std=c2x --force --error-exitcode=-1 \
	            --enable=all --disable=missingInclude --check-level=exhaustive \
	            $(SRCDIR)/*.[ch]

# Code formatting
codeformat:
	$(ASTYLE) --style=linux --break-closing-braces --add-braces \
	          --indent-preproc-cond --formatted --align-pointer=name \
	          --squeeze-lines=2 --suffix=none --pad-header --pad-oper \
	          $(SRCDIR)/*.[ch]

codespell:
	$(MKDIR_P) ./.codespell
	$(CURL) --output-dir ./.codespell --remote-name https://raw.githubusercontent.com/codespell-project/codespell/master/codespell_lib/data/dictionary.txt
	$(CURL) --output-dir ./.codespell --remote-name https://raw.githubusercontent.com/codespell-project/codespell/master/codespell_lib/data/dictionary_rare.txt
	$(CODESPELL) --dictionary=./.codespell/dictionary.txt --dictionary=./.codespell/dictionary_rare.txt \
	             --count --builtin clear,rare,informal,names \
	             --skip="./.*,./gcovr/*" \
	             .

install:

run: $(TARGET_LIN_DBG)
	./$(TARGET_LIN_DBG)
