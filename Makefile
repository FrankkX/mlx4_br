include $(TOPDIR)/rules.mk

PKG_NAME:=mlx4_br
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/mlx4_br
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Fix SR-IOV VF communication in Linux bridge
  URL:=https://github.com/yujincheng08/mlx4_br
  DEPENDS:=+libstdcpp
endef

define Package/mlx4_br/description
  Driver/daemon to allow adding mlx4/ixgbe/iavf VF into linux bridge (br-lan).
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./main.cc $(PKG_BUILD_DIR)/
	$(CP) ./package/openwrt/mlx4_br $(PKG_BUILD_DIR)/init.d
endef

define Build/Compile
	$(CXX) $(PKG_BUILD_DIR)/main.cc -std=c++17 \
		$(TARGET_CXXFLAGS) $(TARGET_CPPFLAGS) $(TARGET_LDFLAGS) \
		-Wno-ignored-attributes -static -s -fno-exceptions -fno-rtti -Os -flto \
		-fdata-sections -ffunction-sections -Wl,--gc-sections -lstdc++ -o $(PKG_BUILD_DIR)/mlx4_br
endef

define Package/mlx4_br/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/mlx4_br $(1)/usr/bin/
	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/init.d $(1)/etc/init.d/mlx4_br
endef

$(eval $(call BuildPackage,mlx4_br))
