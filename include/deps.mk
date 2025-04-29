# ===========================================================================
# Dependencies configuration
# ===========================================================================

# Required packages for building
REQUIRED_PKGS := \
	build-essential \
	libncurses-dev \
	flex \
	bison \
	libssl-dev \
	libelf-dev \
	zlib1g-dev \
	dwarves \
	git \
	bc \
	pkg-config \
	python3-setuptools \
	python3-dev \
	swig \
	libgnutls28-dev

# Check if running on Ubuntu/Debian
ifeq ($(shell which apt-get 2>/dev/null),)
    $(error This script requires apt-get. Please run on Ubuntu/Debian system)
endif

# ===========================================================================
# Dependencies targets
# ===========================================================================

.PHONY: check-deps install-deps

check-deps:
	@echo "Checking required packages..."
	@missing=0; \
	for pkg in $(REQUIRED_PKGS); do \
		if ! dpkg -s $$pkg >/dev/null 2>&1; then \
			echo "  ✗ $$pkg"; \
			missing=1; \
		else \
			echo "  ✓ $$pkg"; \
		fi; \
	done; \
	if [ $$missing -eq 1 ]; then \
		echo; \
		echo "Some required packages are missing."; \
		echo "Run 'make install-deps' to install them."; \
		echo "Continuing with download..."; \
	else \
		echo; \
		echo "All required packages are installed."; \
	fi

install-deps:
	@echo "Installing required packages..."
	@sudo apt-get update
	@sudo apt-get install -y $(REQUIRED_PKGS)
	@echo
	@echo "All required packages have been installed successfully."
