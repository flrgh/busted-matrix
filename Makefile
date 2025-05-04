ROCKSPEC := $(wildcard *.rockspec)

.PHONY: test
test:
	busted

.PHONY: lint
lint:
	luacheck src spec
	luarocks lint $(ROCKSPEC)
