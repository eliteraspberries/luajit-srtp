AR?=		ar
CC?=		clang

ifeq ("$(TARGET)","")
TARGET:=	$(shell $(CC) $(CFLAGS) -dumpmachine | sed -e 's/[0-9.]*$$//')
endif
SYS:=		$(shell echo "$(TARGET)" | awk -F- '{print $$3}')

CFLAGS+=	--target=$(TARGET)

ifeq ("$(SYS)","darwin")
SDKROOT:=	$(shell xcrun --sdk macosx --show-sdk-path)
AR:=		$(shell xcrun --sdk macosx --find ar)
CC:=		$(shell xcrun --sdk macosx --find clang)
CPPFLAGS+=	-isysroot $(SDKROOT)
CFLAGS+=	--sysroot=$(SDKROOT)
LDFLAGS+=	--sysroot=$(SDKROOT)
CFLAGS+=	-mmacosx-version-min=10.9
LDFLAGS+=	--target=$(TARGET)
endif

ifeq ($(shell uname -s),Darwin)
DYLD_LIBRARY_PATH:=	$(shell pwd)/build/$(TARGET)/lib:$(DYLD_LIBRARY_PATH)
LUA:=				DYLD_LIBRARY_PATH="$(DYLD_LIBRARY_PATH)" luajit
else
LUA:=				luajit
endif
LUA_CPATH:=			$(shell pwd)/build/$(TARGET)/lib/?

.PHONY: mbedtls
mbedtls: build-mbedtls.sh
	/bin/sh build-mbedtls.sh

.PHONY: lib
lib: mbedtls

.PHONY: libsrtp
libsrtp: build-libsrtp.sh lib
	/bin/sh build-libsrtp.sh

.PHONY: so
so: libsrtp

INCLUDES:= srtp.h crypto_types.h auth.h cipher.h

.PHONY: includes
includes: pre.sed
	$(MAKE) libsrtp
	for h in $(INCLUDES); do \
		cp -f build/$(TARGET)/include/srtp2/$$h $$h; \
		for i in $(shell seq 1 100); do \
			cp -f $$h $$h.orig; \
			sed -f pre.sed < $$h.orig > $$h; \
		done \
	done

%.txt: %.sed
	$(MAKE) includes
	for h in $(INCLUDES); do sed -f $< < $$h >> $@; done

srtp.lua: srtp.lua.in types.txt functions.txt defines.txt
	sed -e '/{{types}}/{r types.txt' -e 'd' -e '}' \
		-e '/{{functions}}/{r functions.txt' -e 'd' -e '}' \
		-e '/{{defines}}/{r defines.txt' -e 'd' -e '}' \
		< srtp.lua.in > srtp.lua

.PHONY: test
test: srtp.lua
	LUA_CPATH="$(LUA_CPATH)" $(LUA) srtp.lua

.PHONY: cleanup
cleanup:
	rm -rf mbedtls-3.[0-9].[0-9]
	rm -rf libsrtp-2.[0-9].[0-9]
	rm -f $(INCLUDES) *.h.orig
	rm -f types.txt functions.txt defines.txt
	$(MAKE) -f android/Makefile cleanup

.PHONY: clean
clean: cleanup
	rm -f srtp.lua
	rm -rf build/*
	$(MAKE) -f android/Makefile clean
