
include $(TOPDIR)/rules.mk

PKG_NAME:=mlx4-br
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/mlx4-br
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Automatic MAC address propagation for supported NICs
  DEPENDS:=+libstdcpp
endef

define Package/mlx4-br/description
  Learn bridge forwarding database MAC addresses and propagate them
  to supported NIC hardware filters.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/main.cc $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(TARGET_CXX) \
		$(TARGET_CXXFLAGS) \
		-std=gnu++20 \
		-Wno-ignored-attributes \
		-fno-exceptions \
		-fno-rtti \
		-Os \
		$(PKG_BUILD_DIR)/main.cc \
		-o $(PKG_BUILD_DIR)/mlx4_br \
		$(TARGET_LDFLAGS)
endef

define Package/mlx4-br/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/mlx4_br $(1)/usr/bin/mlx4_br

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/mlx4_br.init $(1)/etc/init.d/mlx4_br
endef

$(eval $(call BuildPackage,mlx4-br))
