TARGET := iphone:clang:latest:15.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = waios2gdrive

waios2gdrive_FILES = Tweak.x
waios2gdrive_CFLAGS = -fobjc-arc
waios2gdrive_FRAMEWORKS = Foundation

include $(THEOS)/makefiles/library.mk
