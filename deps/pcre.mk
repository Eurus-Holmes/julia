## PCRE ##
include $(SRCDIR)/pcre.version

ifneq ($(USE_BINARYBUILDER_PCRE),1)
# Force optimization for PCRE flags (Issue #11668)
PCRE_CFLAGS := -O3
PCRE_LDFLAGS := $(RPATH_ESCAPED_ORIGIN)

ifeq ($(OS),emscripten)
PCRE_CFLAGS += -fPIC
PCRE_JIT = --disable-jit
else ifeq ($(OS),OpenBSD)
# jit will need RWX memory
PCRE_JIT = --disable-jit
else
PCRE_JIT = --enable-jit
endif

$(SRCCACHE)/pcre2-$(PCRE_VER).tar.bz2: | $(SRCCACHE)
	$(JLDOWNLOAD) $@ https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$(PCRE_VER)/pcre2-$(PCRE_VER).tar.bz2

$(SRCCACHE)/pcre2-$(PCRE_VER)/source-extracted: $(SRCCACHE)/pcre2-$(PCRE_VER).tar.bz2
	$(JLCHECKSUM) $<
	cd $(dir $<) && $(TAR) -jxf $(notdir $<)
	echo 1 > $@

checksum-pcre: $(SRCCACHE)/pcre2-$(PCRE_VER).tar.bz2
	$(JLCHECKSUM) $<

$(BUILDDIR)/pcre2-$(PCRE_VER)/build-configured: $(SRCCACHE)/pcre2-$(PCRE_VER)/source-extracted
	mkdir -p $(dir $@)
	cd $(dir $@) && \
	$(dir $<)/configure $(CONFIGURE_COMMON) $(PCRE_JIT) --includedir=$(build_includedir) CFLAGS="$(CFLAGS) $(PCRE_CFLAGS) -g -O0" LDFLAGS="$(LDFLAGS) $(PCRE_LDFLAGS)"
	echo 1 > $@

$(BUILDDIR)/pcre2-$(PCRE_VER)/build-compiled: $(BUILDDIR)/pcre2-$(PCRE_VER)/build-configured
	$(MAKE) -C $(dir $<) $(LIBTOOL_CCLD)
	echo 1 > $@

$(BUILDDIR)/pcre2-$(PCRE_VER)/build-checked: $(BUILDDIR)/pcre2-$(PCRE_VER)/build-compiled
ifeq ($(OS),$(BUILD_OS))
ifneq ($(OS),WINNT)
	$(MAKE) -C $(dir $@) check -j1
endif
endif
	echo 1 > $@

$(eval $(call staged-install, \
	pcre,pcre2-$$(PCRE_VER), \
	MAKE_INSTALL,$$(LIBTOOL_CCLD),, \
	rm -f $$(build_shlibdir)/libpcre2-posix.* && \
	$$(INSTALL_NAME_CMD)libpcre2-8.$$(SHLIB_EXT) $$(build_shlibdir)/libpcre2-8.$$(SHLIB_EXT)))

clean-pcre:
	-rm -f $(BUILDDIR)/pcre2-$(PCRE_VER)/build-configured $(BUILDDIR)/pcre2-$(PCRE_VER)/build-compiled
	-$(MAKE) -C $(BUILDDIR)/pcre2-$(PCRE_VER) clean

distclean-pcre:
	rm -rf $(SRCCACHE)/pcre2-$(PCRE_VER).tar.bz2 $(SRCCACHE)/pcre2-$(PCRE_VER) $(BUILDDIR)/pcre2-$(PCRE_VER)


get-pcre: $(SRCCACHE)/pcre2-$(PCRE_VER).tar.bz2
extract-pcre: $(SRCCACHE)/pcre2-$(PCRE_VER)/source-extracted
configure-pcre: $(BUILDDIR)/pcre2-$(PCRE_VER)/build-configured
compile-pcre: $(BUILDDIR)/pcre2-$(PCRE_VER)/build-compiled
fastcheck-pcre: check-pcre
check-pcre: $(BUILDDIR)/pcre2-$(PCRE_VER)/build-checked

else # USE_BINARYBUILDER_PCRE

$(eval $(call bb-install,pcre,PCRE,false))

endif
