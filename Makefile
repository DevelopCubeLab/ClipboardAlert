THEOS_DEVICE_IP = 192.168.1.109
THEOS_DEVICE_PORT = 22
THEOS_DEVICE_USER = root

ARCHS = arm64
TARGET := iphone:clang:latest:7.0


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ClipboardAlert

ClipboardAlert_FILES = Tweak.x
ClipboardAlert_CFLAGS = -fobjc-arc
ClipboardAlert_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

# after-install::
# 	install.exec "killall -9 Storyboard"

after-install:: 
	@$(THEOS_DEVICE_IP) "killall -9 SpringBoard"