SHELL=/bin/bash

VERSION := $(shell git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")

all: debian openwrt

openwrt: binary
	@echo "Building openwrt APK package"
	$(eval TMP := $(shell mktemp -d))
	@mkdir -p $(TMP)/root/usr/bin
	cp mlx4_br $(TMP)/root/usr/bin/ -af
	chmod +x $(TMP)/root/usr/bin/mlx4_br
	@mkdir -p $(TMP)/root/etc/init.d
	cp package/openwrt/mlx4_br $(TMP)/root/etc/init.d/ -af
	chmod +x $(TMP)/root/etc/init.d/mlx4_br

	# Create post-install script for APK
	@mkdir -p $(TMP)/scripts
	cp package/openwrt/control/postinst $(TMP)/scripts/post-install
	chmod +x $(TMP)/scripts/post-install

	# Prefer apk mkpkg if available (OpenWrt 25.12+ / apk-tools 3.x)
	@if command -v apk >/dev/null 2>&1 && apk mkpkg --help >/dev/null 2>&1; then \
		echo "Using apk mkpkg"; \
		apk mkpkg \
			--info "name:mlx4_br" \
			--info "version:$(VERSION)" \
			--info "description:Driver to allow adding mlx4/mlx5/iavf/ixgbevf VF into linux bridge" \
			--info "arch:all" \
			--info "license:GPL-2.0-only" \
			--info "origin:https://github.com/yujincheng08/mlx4_br" \
			--info "maintainer:yujincheng08" \
			--info "url:https://github.com/yujincheng08/mlx4_br" \
			--script "post-install:$(TMP)/scripts/post-install" \
			--files "$(TMP)/root" \
			--output "mlx4_br-$(VERSION).apk"; \
	else \
		echo "apk mkpkg not found, falling back to legacy IPK packaging"; \
		tar --owner=root --group=root -zcf $(TMP)/data.tar.gz -C $(TMP)/root .; \
		cp -a package/openwrt/control $(TMP)/control; \
		chmod +x $(TMP)/control/*; \
		sed -i "s/Version:.*/Version: $(VERSION)/" $(TMP)/control/control; \
		tar --owner=root --group=root -zcf $(TMP)/control.tar.gz -C $(TMP)/control .; \
		cp package/openwrt/debian-binary $(TMP)/debian-binary -af; \
		rm -rf $(TMP)/root $(TMP)/control $(TMP)/scripts; \
		tar --owner=root --group=root -zcf mlx4_br_$(VERSION)_x86-64.ipk -C $(TMP) .; \
	fi
	rm -rf $(TMP)
	@echo "Cleanup openwrt package"

debian: binary
	@echo "Building debian package"
	$(eval TMP := $(shell mktemp -d))
	@mkdir -p $(TMP)/usr/bin
	cp mlx4_br $(TMP)/usr/bin/ -af
	chmod +x $(TMP)/usr/bin/mlx4_br
	@mkdir -p $(TMP)/lib/systemd/system
	@if [ -f package/debian/mlx4_br.service ]; then \
		cp package/debian/mlx4_br.service $(TMP)/lib/systemd/system/ -af; \
	fi
	@if [ -d package/debian/DEBIAN ]; then \
		cp package/debian/DEBIAN $(TMP)/ -raf; \
		sed -i "s/Version:.*/Version: $(VERSION)/" $(TMP)/DEBIAN/control; \
		dpkg-deb -b -Zgzip $(TMP) mlx4_br.$(VERSION).deb; \
	else \
		echo "Warning: package/debian/DEBIAN not found, skipping deb package"; \
	fi
	rm -rf $(TMP)
	@echo "Cleanup debian package"

binary:
	$(CXX) main.cc -std=c++17 -Wno-ignored-attributes -static -s -fno-exceptions -fno-rtti -Os -flto -fdata-sections -ffunction-sections -Wl,--gc-sections -lstdc++ -o mlx4_br
	@if command -v upx >/dev/null 2>&1; then upx -9 mlx4_br; else echo "upx not found, skipping compression"; fi

.PHONY: clean
clean:
	rm -f mlx4_br mlx4_br*.apk mlx4_br*.ipk mlx4_br*.deb
