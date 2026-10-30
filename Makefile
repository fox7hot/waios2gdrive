TARGET := iphone:clang:latest:15.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = waios2gdrive

waios2gdrive_FILES = Tweak.x
waios2gdrive_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/tweak.mk
