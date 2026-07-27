#!/bin/bash
# repl.sh --- Interactive REPL for Sun After Rome
# Run this in a separate terminal while the game is running.
# Usage: ./repl.sh

REPL_IN="repl.in"
REPL_OUT="repl.out"

# Truncate output
> "$REPL_OUT"

echo "Sun After Rome REPL"
echo "Type Fennel expressions, press Enter to evaluate."
echo "Type 'exit' to quit."
echo ""

while true; do
    read -r -p "> " code
    [ -z "$code" ] && continue
    [ "$code" = "exit" ] && break

    # Write expression to repl.in
    echo "$code" > "$REPL_IN"

    # Wait for result (poll repl.out)
    sleep 0.1
    while [ ! -s "$REPL_OUT" ]; do
        sleep 0.05
    done

    # Display result
    cat "$REPL_OUT"
    > "$REPL_OUT"
done
