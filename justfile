# Task runner. `just` lists the recipes; CI runs `just ci`.

# List the recipes
default:
    @just --list

# Build the project
build:
    @echo "nothing to build"

# Run the tests
test:
    @echo "nothing to test here: CI runs the shared workflows against tests/"

# Check the code without changing files
lint:
    actionlint .github/workflows/*.yml

# Format the code in place
format:
    @echo "nothing to format"

# Run everything CI runs
ci: lint build test
