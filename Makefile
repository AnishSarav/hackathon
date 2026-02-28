# ============================================================
#  EEG Brain State Classifier — Hackathon Makefile
# ============================================================
#
#  Quick start:
#      make setup      <- do this ONCE (creates venv + installs packages)
#      make simulate   <- test without headset
#      make run        <- live with OpenBCI headset
#
#  All commands:
#      make setup      Create virtual environment and install packages
#      make train      Retrain the model from CSV files
#      make simulate   Run simulated demo (no headset needed)
#      make run        Run live inference (default port: COM5)
#      make run-mac    Run live inference (auto-detect Mac serial port)
#      make clean      Remove virtual environment and cached files
#      make help       Show this help message
#
# ============================================================

# --- Configuration -----------------------------------------------------------
PYTHON       := python3
VENV_DIR     := .venv
VENV_PYTHON  := $(VENV_DIR)/bin/python
VENV_PIP     := $(VENV_DIR)/bin/pip
REQUIREMENTS := requirements.txt
SCRIPT       := inference.py

# Default serial port (override: make run PORT=/dev/ttyUSB0)
PORT         ?= COM5

# Default live session duration in seconds
DURATION     ?= 120

# Default classification window in seconds
WINDOW       ?= 4

# --- Detect OS for Mac serial port auto-detection ----------------------------
UNAME_S := $(shell uname -s)

# ============================================================
#  TARGETS
# ============================================================

.PHONY: help setup venv install train simulate run run-mac clean check

## Show all available commands
help:
	@echo ""
	@echo "============================================================"
	@echo "  EEG Brain State Classifier — Hackathon"
	@echo "============================================================"
	@echo ""
	@echo "  FIRST TIME SETUP:"
	@echo "      make setup          Create venv + install all packages"
	@echo ""
	@echo "  RUN:"
	@echo "      make simulate       Test with recorded CSV (no headset)"
	@echo "      make run            Live inference (default port: COM5)"
	@echo "      make run PORT=COM3  Live inference on specific port"
	@echo "      make run-mac        Live inference (auto-detect Mac port)"
	@echo ""
	@echo "  OTHER:"
	@echo "      make train          Retrain model from eeg_data/ CSVs"
	@echo "      make clean          Delete venv and cached files"
	@echo "      make check          Verify everything is installed"
	@echo ""
	@echo "  OPTIONS (pass as arguments):"
	@echo "      PORT=COM5           Serial port for OpenBCI headset"
	@echo "      DURATION=120        Live session length in seconds"
	@echo "      WINDOW=4            Classification window in seconds"
	@echo ""
	@echo "============================================================"
	@echo ""

## Create virtual environment
venv:
	@echo "Creating virtual environment in $(VENV_DIR)/ ..."
	@$(PYTHON) -m venv $(VENV_DIR)
	@echo "Done."

## Install all dependencies into the virtual environment
install: venv
	@echo "Installing packages from $(REQUIREMENTS) ..."
	@$(VENV_PIP) install --upgrade pip -q
	@$(VENV_PIP) install -r $(REQUIREMENTS)
	@echo ""
	@echo "All packages installed!"

## One-command setup: create venv + install everything
setup: install
	@echo ""
	@echo "============================================================"
	@echo "  Setup complete!"
	@echo "============================================================"
	@echo ""
	@echo "  Next steps:"
	@echo "    1. Put your eeg_data/ folder next to this Makefile"
	@echo "    2. Run:  make simulate     (test without headset)"
	@echo "    3. Run:  make run          (live with headset)"
	@echo ""
	@echo "============================================================"

## Verify the environment is working
check: $(VENV_PYTHON)
	@echo "Checking environment..."
	@$(VENV_PYTHON) -c "\
import numpy; print(f'  numpy       {numpy.__version__}'); \
import pandas; print(f'  pandas      {pandas.__version__}'); \
import scipy; print(f'  scipy       {scipy.__version__}'); \
import sklearn; print(f'  scikit-learn {sklearn.__version__}'); \
import matplotlib; print(f'  matplotlib  {matplotlib.__version__}'); \
import joblib; print(f'  joblib      {joblib.__version__}'); \
import brainflow; print(f'  brainflow   OK'); \
import pygame; print(f'  pygame      {pygame.ver}'); \
print(); print('  All good!')"

## Train / retrain the model from eeg_data/ CSV files
train: $(VENV_PYTHON)
	@echo "Training model..."
	@$(VENV_PYTHON) $(SCRIPT) --train

## Run simulated inference on a recorded CSV (no headset needed)
simulate: $(VENV_PYTHON)
	@echo "Running simulated inference..."
	@$(VENV_PYTHON) $(SCRIPT) --simulate --window $(WINDOW)

## Run live inference with OpenBCI headset
run: $(VENV_PYTHON)
	@echo "Starting live inference on port $(PORT)..."
	@$(VENV_PYTHON) $(SCRIPT) --port $(PORT) --window $(WINDOW) --duration $(DURATION)

## Run live inference with auto-detected Mac serial port
run-mac: $(VENV_PYTHON)
ifeq ($(UNAME_S),Darwin)
	$(eval MAC_PORT := $(shell ls /dev/tty.usbserial-* 2>/dev/null | head -1))
	@if [ -z "$(MAC_PORT)" ]; then \
		echo "ERROR: No USB serial device found."; \
		echo "  1. Is the Bluetooth dongle plugged in?"; \
		echo "  2. Try: ls /dev/tty.*"; \
		echo "  3. Or specify manually: make run PORT=/dev/tty.usbserial-XXXX"; \
		exit 1; \
	fi
	@echo "Auto-detected port: $(MAC_PORT)"
	@$(VENV_PYTHON) $(SCRIPT) --port $(MAC_PORT) --window $(WINDOW) --duration $(DURATION)
else
	@echo "run-mac is only for macOS. Use: make run PORT=COM5"
endif

## Remove virtual environment and generated files
clean:
	@echo "Cleaning up..."
	@rm -rf $(VENV_DIR)
	@rm -f brain_classifier.pkl
	@rm -f soothing_music.wav
	@find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	@echo "Cleaned. Run 'make setup' to start fresh."
