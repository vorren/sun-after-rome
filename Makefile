# Sun After Rome — LÖVE build system
#
# Targets:
#   run         - Launch the game
#   enet        - Compile lua-enet binding (requires libenet + LuaJIT headers)
#   test        - Run the test suite
#   smoke-test  - Run LÖVE smoke test (catches runtime errors)
#   clean       - Remove compiled output
#   repl        - Launch LÖVE with REPL thread

LOVE ?= love
LUAJIT_INC ?= /opt/homebrew/include/luajit-2.1
ENET_INC ?= /opt/homebrew/include
ENET_LIB ?= /opt/homebrew/lib
LUAJIT_LIB ?= luajit-5.1

.PHONY: all run enet test smoke-test clean repl help

all: run

## run : Launch the game
run:
	$(LOVE) .

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
test:
	@echo "--- Running tests ---"
	LUA_PATH=";;./lib/?.lua;./?.lua;./?/init.lua" LUA_CPATH=";;./lib/?.so" lua test/run.lua

## smoke-test : Run LÖVE smoke test (catches runtime errors)
smoke-test:
	@echo "--- Running smoke test ---"
	$(LOVE) . --smoke-test; echo "Exit code: $$?"

## clean : Remove compiled output
clean:
	rm -f lib/fennel.lua lib/fennelview.lua

## repl : Launch LÖVE (REPL thread starts automatically in love.load)
repl:
	$(LOVE) .

## help : List targets
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## //'
