# Task runner. `just` lists the recipes; CI runs `just ci`.

# List the recipes
default:
    @just --list

# Build the project
build:
    @echo "nothing to build"

# Run the tests
test:
    @echo "nothing to test"

# Check the code without changing files
lint:
    ./scripts/lint.sh

# Format the code in place
format:
    @echo "nothing to format"

# Run everything CI runs
ci: lint build test
