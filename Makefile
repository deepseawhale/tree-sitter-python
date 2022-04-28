VERSION := 0.19.1

# install directory layout
PREFIX ?= /usr/local
INCLUDEDIR ?= $(PREFIX)/include
LIBDIR ?= $(PREFIX)/lib
PCLIBDIR ?= $(LIBDIR)/pkgconfig

# collect C++ sources, and link if necessary
CPPSRC := $(wildcard src/*.cc)

# collect sources
SRC := $(wildcard src/*.c)
SRC += $(CPPSRC)
OBJ := $(addsuffix .o,$(basename $(SRC)))

# ABI versioning
SONAME_MAJOR := 0
SONAME_MINOR := 0

CFLAGS ?= -O3 -Wall -Wextra
CXXFLAGS ?= -O3 -Wall -Wextra
override CFLAGS += -std=gnu99 -fPIC
override CXXFLAGS += -fPIC

# OS-specific bits
ifeq ($(shell uname),Darwin)
	SOEXT = dylib
	SOEXTVER_MAJOR = $(SONAME_MAJOR).dylib
	SOEXTVER = $(SONAME_MAJOR).$(SONAME_MINOR).dylib
	LINKSHARED += -dynamiclib -Wl,-install_name,$(LIBDIR)/libtree-sitter-python.$(SONAME_MAJOR).dylib
else
	SOEXT = so
	SOEXTVER_MAJOR = so.$(SONAME_MAJOR)
	SOEXTVER = so.$(SONAME_MAJOR).$(SONAME_MINOR)
	LINKSHARED += -shared -Wl,-soname,libtree-sitter-python.so.$(SONAME_MAJOR)
endif
ifneq (,$(filter $(shell uname),FreeBSD NetBSD DragonFly))
	PCLIBDIR := $(PREFIX)/libdata/pkgconfig
endif

all: libtree-sitter-python.a libtree-sitter-python.$(SOEXTVER)

libtree-sitter-python.a: $(OBJ)
	$(AR) rcs $@ $^

libtree-sitter-python.$(SOEXTVER): $(OBJ)
	$(CC) $(LDFLAGS) $(LINKSHARED) $^ $(LDLIBS) -o $@
	ln -sf $@ libtree-sitter-python.$(SOEXT)
	ln -sf $@ libtree-sitter-python.$(SOEXTVER_MAJOR)

install: all
	install -d '$(DESTDIR)$(LIBDIR)'
	install -m755 libtree-sitter-python.a '$(DESTDIR)$(LIBDIR)'/libtree-sitter-python.a
	install -m755 libtree-sitter-python.$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/libtree-sitter-python.$(SOEXTVER)
	ln -sf libtree-sitter-python.$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/libtree-sitter-python.$(SOEXTVER_MAJOR)
	ln -sf libtree-sitter-python.$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/libtree-sitter-python.$(SOEXT)
	install -d '$(DESTDIR)$(INCLUDEDIR)'/tree_sitter
	install -m644 bindings/c/python.h '$(DESTDIR)$(INCLUDEDIR)'/tree_sitter/
	install -d '$(DESTDIR)$(PCLIBDIR)'
	sed -e 's|@LIBDIR@|$(LIBDIR)|;s|@INCLUDEDIR@|$(INCLUDEDIR)|;s|@VERSION@|$(VERSION)|' \
	    -e 's|=$(PREFIX)|=$${prefix}|' \
	    -e 's|@PREFIX@|$(PREFIX)|' \
	    -e 's|@ADDITIONALLIBS@|$(ADDITIONALLIBS)|' \
	    bindings/c/tree-sitter-python.pc.in > '$(DESTDIR)$(PCLIBDIR)'/tree-sitter-python.pc

clean:
	rm -f $(OBJ) libtree-sitter-python.a libtree-sitter-python.$(SOEXT) libtree-sitter-python.$(SOEXTVER_MAJOR) libtree-sitter-python.$(SOEXTVER)

.PHONY: all install clean
