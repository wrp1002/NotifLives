#THEOS_PACKAGE_SCHEME=rootless

include $(THEOS)/makefiles/common.mk

SDKVERSION = 16.5

BUNDLE_NAME = NotifLivesPrefs

$(BUNDLE_NAME)_FILES = NLVRootListController.m
$(BUNDLE_NAME)_FRAMEWORKS = UIKit
$(BUNDLE_NAME)_PRIVATE_FRAMEWORKS = Preferences
$(BUNDLE_NAME)_INSTALL_PATH = /Library/PreferenceBundles
$(BUNDLE_NAME)_CFLAGS = -fobjc-arc
$(BUNDLE_NAME)_EXTRA_FRAMEWORKS = Cephei CepheiPrefs
$(BUNDLE_NAME)_LIBRARIES = sparkapplist

include $(THEOS_MAKE_PATH)/bundle.mk
