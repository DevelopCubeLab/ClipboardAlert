THEOS_DEVICE_IP = 192.168.1.109
THEOS_DEVICE_PORT = 22
THEOS_DEVICE_USER = root

ARCHS = arm64
TARGET := iphone:clang:latest:7.0

LANG ?= en

ifeq ($(LANG), en)
    LOCALIZED_STRINGS = en_strings.xm
else ifeq ($(LANG), zh)
    LOCALIZED_STRINGS = zh_strings.xm
else
    LOCALIZED_STRINGS = default_strings.xm
endif


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ClipboardAlert

ClipboardAlert_FILES = Tweak.x
ClipboardAlert_CFLAGS = -fobjc-arc
ClipboardAlert_FRAMEWORKS = UIKit
ClipboardAlert_RESOURCES = Resources/en.lproj/Localizable.strings Resources/zh-Hans.lproj/Localizable.strings

include $(THEOS_MAKE_PATH)/tweak.mk

after-install:: 
	@$(THEOS_DEVICE_IP) "killall -9 SpringBoard"
	
after-stage::
	@echo "Copying .dylib to parent directory..."
	cp $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/$(TWEAK_NAME).dylib ../$(TWEAK_NAME)/
	@echo "Copy completed."

