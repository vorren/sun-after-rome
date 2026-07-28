# Aurelius --- Fennel + LÖVE build system
#
# Targets:
#   run         - Launch the game
#   build       - AOT compile all Fennel to Lua
#   enet        - Compile lua-enet binding (requires libenet + LuaJIT headers)
#   test        - Run the test suite
#   smoke-test  - Run LÖVE smoke test (catches runtime errors)
#   clean       - Remove compiled output
#   repl        - Launch LÖVE with REPL thread

FENNEL ?= fennel
LOVE ?= love
LUAFENNEL := lib/fennel.lua
LUAJIT_INC ?= /opt/homebrew/include/luajit-2.1
ENET_INC ?= /opt/homebrew/include
ENET_LIB ?= /opt/homebrew/lib
LUAJIT_LIB ?= luajit-5.1

SRC := $(shell find src -name '*.fnl')
TEST := $(shell find test -name '*.fnl')
SRC_LUA := $(SRC:%.fnl=%.lua)
TEST_LUA := $(TEST:%.fnl=%.lua)

.PHONY: all run build enet test clean repl help

all: build

## run : Launch the game
run:
	$(LOVE) .

## build : AOT compile all Fennel to Lua
build: $(SRC_LUA)
	@echo "build: compiled $(words $(SRC_LUA)) module(s)"

%.lua: %.fnl $(LUAFENNEL)
	@mkdir -p $(dir $@)
	$(FENNEL) --compile $< > $@

## enet : Compile lua-enet binding (requires libenet + LuaJIT headers)
enet: lib/enet.so

lib/enet.so: /tmp/lua-enet/enet.c
	gcc -O2 -fPIC -shared -o $@ $< \
	  -I$(LUAJIT_INC) -I$(ENET_INC) \
	  -L$(ENET_LIB) -l$(LUAJIT_LIB) -lenet -lm
	@echo "enet: compiled lua-enet binding"

/tmp/lua-enet/enet.c:
	@echo "enet: cloning lua-enet..."
	git clone --depth 1 https://github.com/leafo/lua-enet.git /tmp/lua-enet

## test : Run the test suite
test: build $(TEST_LUA)
	@echo "--- Running tests ---"
	LUA_PATH=";;./lib/?.lua;./?.lua;./?/init.lua" LUA_CPATH=";;./lib/?.so" lua test/run.lua

## smoke-test : Run LÖVE smoke test (catches runtime errors)
smoke-test: build $(TEST_LUA)
	@echo "--- Running smoke test ---"
	$(LOVE) . --smoke-test; echo "Exit code: $$?"

test/%.lua: test/%.fnl $(LUAFENNEL)
	$(FENNEL) --compile $< > $@

## clean : Remove compiled output
clean:
	rm -f src/*.lua src/**/*.lua test/*.lua

## repl : Launch LÖVE (REPL thread starts automatically in love.load)
repl:
	$(LOVE) .

## help : List targets
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## //'
