THEOS_PACKAGE_SCHEME ?= roothide
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
ARCHS = arm64e
NHB_PATH_LIBRARY = roothide
else ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
ARCHS = arm64 arm64e
NHB_PATH_LIBRARY =
else
$(error Choose THEOS_PACKAGE_SCHEME=rootless or roothide)
endif
TARGET = iphone:clang:latest:26.0
FINALPACKAGE = 1
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = NoHomeBar26
NoHomeBar26_FILES = Engine/Runtime.m
NoHomeBar26_CFLAGS = -fno-objc-arc -fstack-protector-strong -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations
NoHomeBar26_FRAMEWORKS = Foundation UIKit
NoHomeBar26_LIBRARIES = $(NHB_PATH_LIBRARY)
include $(THEOS_MAKE_PATH)/tweak.mk
