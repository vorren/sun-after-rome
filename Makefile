# Aurelius --- Fennel + LÖVE build system
#
# Targets:
#   run     - Launch the game
#   build   - AOT compile all Fennel to Lua
#   test    - Run the test suite
#   clean   - Remove compiled output
#   repl    - Launch LÖVE with REPL thread

FENNEL ?= fennel
LOVE ?= love
LUAFENNEL := lib/fennel.lua

SRC := $(shell find src -name '*.fnl')
TEST := $(shell find test -name '*.fnl')
SRC_LUA := $(SRC:%.fnl=%.lua)
TEST_LUA := $(TEST:%.fnl=%.lua)

.PHONY: all run build test clean repl help

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

## test : Run the test suite
test: $(TEST_LUA)
	@echo "--- Running tests ---"
	@fail=0; \
	for t in test/*_test.lua; do \
	  echo "--- $$t"; \
	  LUA_PATH=";;./lib/?.lua;./?.lua;./?/init.lua" LUA_CPATH=";;./lib/?.so" lua $$t || fail=1; \
	done; \
	exit $$fail

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
