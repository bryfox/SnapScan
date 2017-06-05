gitdescribe='basename `git rev-parse --show-toplevel` | tr "\n" "@"; \
                       git rev-parse --abbrev-ref HEAD | tr "\n" "@"; \
                       git rev-parse --short HEAD' \

.PHONY: all
all: submodulestatus
	$(MAKE) -C vendor

.PHONY : submodulestatus
submodulestatus :
	$(info ======= Submodule status: =======)
	@git submodule foreach --quiet $(gitdescribe) | column -t -s"@"; echo
