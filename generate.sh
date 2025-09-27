#!/bin/bash

SOURCE_DIR="$(pwd)/source"
DEST_DIR="$(pwd)/opb"
CVC5_BIN=""

usage() {
    echo "Usage: $0 --cvc5 PATH [--source DIR] [--dest DIR]"
    echo
    echo "Required:"
    echo "  --cvc5 PATH    Path to cvc5 binary"
    echo
    echo "Optional:"
    echo "  --source DIR   Source directory (default: \$(pwd)/source)"
    echo "  --dest DIR     Destination directory (default: \$(pwd)/opb)"
    echo "  -h, --help     Show this help message"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --cvc5|-c)
            CVC5_BIN="$2"
            shift 2
            ;;
        --source|-s)
            SOURCE_DIR="$2"
            shift 2
            ;;
        --dest|-d)
            DEST_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

if [[ -z "$CVC5_BIN" ]]; then
    echo "Error: --cvc5 PATH is required"
    usage
fi

echo "Using cvc5: $CVC5_BIN"
echo "Source dir: $SOURCE_DIR"
echo "Destination dir: $DEST_DIR"

for FILE in "$SOURCE_DIR"/*; do
    BASENAME="$(basename "$FILE")"
    if [[ "$BASENAME" == *.smt2 ]]; then
        BASENAME="${BASENAME%.smt2}"
    fi
    NEW_FILE="$DEST_DIR/$BASENAME.opb"

    mkdir -p "$(dirname "$NEW_FILE")"

    pb_result=$("$CVC5_BIN" "$FILE" --bv-solver=pb-blast --bv-pb-solver=roundingsat -t bv-pb-rs-input)

    last_line=$(echo "$pb_result" | tail -n 1 | sed 's/^/* /')
    other_lines=$(echo "$pb_result" | sed '$d')

    echo "Creating: $NEW_FILE"
    sed 's/^/* /' "$FILE" > "$NEW_FILE"
    echo "$last_line" >> "$NEW_FILE"
    echo "$other_lines" >> "$NEW_FILE"
done

for FILE in "$DEST_DIR"/*; do
    if ! grep -q 'variable' "$FILE"; then
        echo "Deleting $FILE"
        rm "$FILE"
    fi
done

for FILE in "$DEST_DIR"/*; do
    count=$(grep -o 'variable' "$FILE" | wc -l)
    if [ "$count" -gt 1 ]; then
        echo "Deleting $FILE (contains $count occurrences of 'variable')"
        rm "$FILE"
    fi
done
