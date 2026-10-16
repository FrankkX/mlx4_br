SHELL=/bin/bash

VERSION := $(shell git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")
# apk version must start with a digit (strip leading 'v' from tags)
PKG_VERSION := $(shell echo "$(VERSION)" | sed 's/^v//')

# Use fakeroot when available so packaged files are root:root
FAKEROOT := $(shell command -v fakeroot 2>/dev/null)

all: openwrt debian

openwrt: binary
	@echo "==> Building OpenWrt APK package (version=$(PKG_VERSION))"
	@command -v apk >/dev/null 2>&1 || { echo "ERROR: apk not found in PATH (need apk-tools 3.x)"; exit 1; }
	@apk --version
	$(eval TMP := $(shell mktemp -d))
	@mkdir -p $(TMP)/root/usr/bin
	cp -af mlx4_br $(TMP)/root/usr/bin/
	chmod 755 $(TMP)/root/usr/bin/mlx4_br
	@mkdir -p $(TMP)/root/etc/init.d
	cp -af package/openwrt/mlx4_br $(TMP)/root/etc/init.d/
	chmod 755 $(TMP)/root/etc/init.d/mlx4_br
	@mkdir -p $(TMP)/scripts
	cp -af package/openwrt/control/postinst $(TMP)/scripts/post-install
	chmod 755 $(TMP)/scripts/post-install
	@echo "==> Running apk mkpkg ..."
	$(FAKEROOT) apk mkpkg \
		--info "name:mlx4_br" \
		--info "version:$(PKG_VERSION)" \
		--info "description:Driver to allow adding mlx4/mlx5/iavf/ixgbevf VF into linux bridge" \
		--info "arch:noarch" \
		--info "license:GPL-2.0-only" \
		--info "origin:https://github.com/yujincheng08/mlx4_br" \
		--info "maintainer:yujincheng08" \
		--info "url:https://github.com/yujincheng08/mlx4_br" \
		--script "post-install:$(TMP)/scripts/post-install" \
		--files "$(TMP)/root" \
		--output "mlx4_br-$(PKG_VERSION).apk"
	@test -f "mlx4_br-$(PKG_VERSION).apk" || { echo "ERROR: APK was not created"; ls -la; exit 1; }
	@ls -la "mlx4_br-$(PKG_VERSION).apk"
	@file "mlx4_br-$(PKG_VERSION).apk" || true
	rm -rf $(TMP)
	@echo "==> OpenWrt APK built: mlx4_br-$(PKG_VERSION).apk"

debian: binary
	@echo "==> Building Debian package"
	$(eval TMP := $(shell mktemp -d))
	@mkdir -p $(TMP)/usr/bin
	cp -af mlx4_br $(TMP)/usr/bin/
	chmod 755 $(TMP)/usr/bin/mlx4_br
	@mkdir -p $(TMP)/lib/systemd/system
	@if [ -f package/debian/mlx4_br.service ]; then \
		cp -af package/debian/mlx4_br.service $(TMP)/lib/systemd/system/; \
	fi
	@if [ -d package/debian/DEBIAN ]; then \
		cp -raf package/debian/DEBIAN $(TMP)/; \
		sed -i "s/Version:.*/Version: $(PKG_VERSION)/" $(TMP)/DEBIAN/control; \
		dpkg-deb -b -Zgzip $(TMP) "mlx4_br.$(PKG_VERSION).deb"; \
		ls -la "mlx4_br.$(PKG_VERSION).deb"; \
	else \
		echo "Warning: package/debian/DEBIAN not found, skipping deb package"; \
	fi
	rm -rf $(TMP)
	@echo "==> Debian package step done"

binary:
	@echo "==> Compiling mlx4_br"
	$(CXX) main.cc -std=c++17 -Wno-ignored-attributes -static -s \
		-fno-exceptions -fno-rtti -Os -flto \
		-fdata-sections -ffunction-sections -Wl,--gc-sections \
		-lstdc++ -o mlx4_br
	@if command -v upx >/dev/null 2>&1; then \
		upx -9 mlx4_br; \
	else \
		echo "upx not found, skipping compression"; \
	fi
	@ls -la mlx4_br

.PHONY: clean
clean:
	rm -f mlx4_br mlx4_br*.apk mlx4_br*.ipk mlx4_br*.deb
