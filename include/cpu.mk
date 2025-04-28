# Get number of CPU cores
NPROC := $(shell nproc)

# Set number of parallel jobs to number of CPU cores
JOBS ?= $(NPROC)
