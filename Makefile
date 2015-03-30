ARCHS = armv7s armv7 arm64
TARGET = iPhone:8.0

GO_EASY_ON_ME = 1
ADDITIONAL_CFLAGS = -fobjc-arc

include theos/makefiles/common.mk

TWEAK_NAME = SBThemer
SBThemer_FILES = Tweak.xm
SBThemer_FRAMEWORKS = CoreGraphics UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
