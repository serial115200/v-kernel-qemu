# Get number of CPU cores
NPROC := $(shell nproc)

# Set number of parallel jobs to number of CPU cores
JOBS ?= $(NPROC)

# Get host information
HOST_OS := $(shell uname -s)
HOST_ARCH := $(shell uname -m)
HOST_KERNEL := $(shell uname -r)
HOST_DISTRO := $(shell lsb_release -ds 2>/dev/null || cat /etc/*-release 2>/dev/null | head -n1 || echo "Unknown")
HOST_CPU := $(shell cat /proc/cpuinfo | grep "model name" | head -n1 | cut -d: -f2 | sed 's/^[ \t]*//')

# Display host information
.PHONY: host-info
host-info:
	@echo "Host Information:"
	@echo "  OS: $(HOST_OS)"
	@echo "  Architecture: $(HOST_ARCH)"
	@echo "  Kernel: $(HOST_KERNEL)"
	@echo "  Distribution: $(HOST_DISTRO)"
	@echo "  CPU: $(HOST_CPU)"
	@echo "  CPU Cores: $(NPROC)"
	@echo "  Parallel Jobs: $(JOBS)"
