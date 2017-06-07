# swift version used in realm framework dir
SWIFT_VERSION      := 3.1
REALM_VERSION      := 2.8.0
XCODE_PROJ_DIR     := $(shell pwd)/SnapScan/SnapScan
XC_FRAMEWORKS_DIR  := $(XCODE_PROJ_DIR)/Frameworks
VENDOR_DIR         := $(shell pwd)/vendor
REALM_ZIP_NAME     := realm-swift-$(REALM_VERSION).zip
REALM_DOWNLOAD_URL := https://static.realm.io/downloads/swift/$(REALM_ZIP_NAME)
vendored_realm     := $(VENDOR_DIR)/realm-swift-$(REALM_VERSION)

.PHONY: all
all: submodulestatus realm_frameworks tess_training_data
	$(MAKE) -C vendor

.PHONY : submodulestatus
submodulestatus :
	gitdescribe='basename `git rev-parse --show-toplevel` | tr "\n" "@"; \
	                       git rev-parse --abbrev-ref HEAD | tr "\n" "@"; \
	                       git rev-parse --short HEAD' \
	$(info ======= Submodule status: =======)
	@git submodule foreach --quiet $(gitdescribe) | column -t -s"@"; echo

########################
# Realm.io dependencies
########################

# Copy downloaded frameworks to Xcode project
.PHONY : realm_frameworks
realm_frameworks : $(XC_FRAMEWORKS_DIR)/Realm $(XC_FRAMEWORKS_DIR)/RealmSwift

$(XC_FRAMEWORKS_DIR)/Realm : $(vendored_realm)
	cp -R $(vendored_realm)/ios/swift-$(SWIFT_VERSION)/Realm.framework $(XC_FRAMEWORKS_DIR)

$(XC_FRAMEWORKS_DIR)/RealmSwift : $(vendored_realm)
	cp -R $(vendored_realm)/ios/swift-$(SWIFT_VERSION)/RealmSwift.framework $(XC_FRAMEWORKS_DIR)

# Download pre-built realm frameworks
$(vendored_realm) :
	cd $(VENDOR_DIR); \
	(curl $(REALM_DOWNLOAD_URL) > $(REALM_ZIP_NAME)) && \
	unzip $(REALM_ZIP_NAME) && \
	rm $(REALM_ZIP_NAME) && \

########################
# OCR training data
########################
OUTPUT_DATA_DIR := $(XCODE_PROJ_DIR)/tessdata
TESS_LANGUAGES  := eng
SOURCE_DATA     := $(foreach lang, $(TESS_LANGUAGES), $(addprefix $(VENDOR_DIR)/tessdata, /$(lang).*) )
tess_font       := $(OUTPUT_DATA_DIR)/pdf.ttf


.PHONY : tess_training_data
tess_training_data: $(OUTPUT_DATA_DIR) $(tess_font)
	cp $(SOURCE_DATA) $(OUTPUT_DATA_DIR)

$(tess_font) : $(OUTPUT_DATA_DIR)
	cp $(VENDOR_DIR)/tesseract-ocr/tessdata/pdf.ttf $(OUTPUT_DATA_DIR)

$(OUTPUT_DATA_DIR) :
	test -d $(OUTPUT_DATA_DIR) || mkdir $(OUTPUT_DATA_DIR)

########################
# Test
########################

# Note only simulator supported
TEST_SDK    = 10.3
SIM_DEVICE  = iPhone 6s
XCBUILD    := $(shell which xcodebuild)
SCHEME      = SnapScan

.PHONY : test
test : test_preflight test_build

.PHONY : test_preflight
test_preflight:
ifndef XCBUILD
    $(error "xcodebuild not found")
endif

.PHONY : test_build
test_build:
	xcodebuild -scheme $(SCHEME) build-for-testing

.PHONY : test_run
test_run:
	xcodebuild -scheme $(SCHEME) -sdk iphonesimulator$(TEST_SDK) -destination 'platform=iOS Simulator,name=$(SIM_DEVICE),OS=$(TEST_SDK)' test
