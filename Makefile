XC_FRAMEWORKS_DIR  = $(shell pwd)/SnapScan/SnapScan/Frameworks
VENDOR_DIR         = $(shell pwd)/vendor
REALM_VERSION      = 2.8.0
# swift version used in realm framework dir
SWIFT_VERSION      = 3.1
vendored_realm     = $(VENDOR_DIR)/realm-swift-$(REALM_VERSION)
realm_zip_name     = realm-swift-$(REALM_VERSION).zip
realm_download_url = https://static.realm.io/downloads/swift/$(realm_zip_name)

gitdescribe='basename `git rev-parse --show-toplevel` | tr "\n" "@"; \
                       git rev-parse --abbrev-ref HEAD | tr "\n" "@"; \
                       git rev-parse --short HEAD' \

.PHONY: all
all: submodulestatus realm_frameworks
	$(MAKE) -C vendor

.PHONY : submodulestatus
submodulestatus :
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
	(curl $(realm_download_url) > $(realm_zip_name)) && \
	unzip $(realm_zip_name) && \
	rm $(realm_zip_name) && \
