#==============================================================================
#  MAKEFILE VARIABLES
#==============================================================================

# Variables for the make help printout
PROJECT_NAME := C-demo project
VERSION := $(shell cat VERSION)

# Binary names (not path, only file name)
PRODUCTION_BINARY_NAME := mymain
TEST_SUITE_BINARY_NAME := testsuite

# Entry file names (not path, only file name)
PRODUCTION_ENTRY_NAME := main.c
TEST_SUITE_ENTRY_NAME := all_tests.cpp

# Directory definitions
INC_DIR := include
SRC_DIR := src
TST_DIR := test
OBJ_DIR := build

# CppUTest path configuration - edit if you have a custom install location
CPPUTEST_INCLUDE_DIR     := /usr/local/include/CppUTest
CPPUTEST_EXT_INCLUDE_DIR := /usr/local/include/CppUTestExt
CPPUTEST_LIB_DIR         := /usr/local/lib

# Production source preparation
PRODUCTION_ENTRY_FILE   := $(SRC_DIR)/$(PRODUCTION_ENTRY_NAME)
HEADER_FILES            := $(wildcard $(INC_DIR)/*.h)
PRODUCTION_FILES        := $(filter-out $(PRODUCTION_ENTRY_FILE),$(wildcard $(SRC_DIR)/*.c))
PRODUCTION_ENTRY_OBJECT := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(PRODUCTION_ENTRY_FILE))
PRODUCTION_OBJECTS      := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(PRODUCTION_FILES))

# Unit testing source preparation
TEST_ENTRY_FILE         := $(TST_DIR)/$(TEST_SUITE_ENTRY_NAME)
TEST_FILES              := $(filter-out $(TEST_ENTRY_FILE),$(wildcard $(TST_DIR)/*.cpp))
TEST_ENTRY_OBJECT       := $(patsubst $(TST_DIR)/%.cpp,$(OBJ_DIR)/%.o,$(TEST_ENTRY_FILE))
TEST_OBJECTS            := $(patsubst $(TST_DIR)/%.cpp,$(OBJ_DIR)/%.o,$(TEST_FILES))

# Compilation related flags and parameters
CC:=g++
CPPFLAGS += -Wall
CPPFLAGS += -fdiagnostics-color
CPPFLAGS += -I$(CPPUTEST_INCLUDE_DIR)
CPPFLAGS += -I$(CPPUTEST_EXT_INCLUDE_DIR)
CPPFLAGS += -I$(INC_DIR)
LD_LIBRARIES = -L$(CPPUTEST_LIB_DIR) -lCppUTest -lCppUTestExt
MEMORY_LEAK_MACROS = $(CPPUTEST_INCLUDE_DIR)/MemoryLeakDetectorMallocMacros.h
INC=

# Makefile formatting variables
SILENCE:=@
ECHO_FLAG:=-n
RED := $(shell tput setaf 1)
GREEN := $(shell tput setaf 2)
YELLOW := $(shell tput setaf 3)
BOLD := $(shell tput bold)
RESET:= $(shell tput sgr0)


#==============================================================================
#  MAKE TARGETS
#==============================================================================

.PHONY: test clean leak_detection files help

# First make target = help
help:
	@echo '---------------------------------------------------------------------'
	@echo ' $(BOLD)$(YELLOW)$(PROJECT_NAME)$(RESET) $(BOLD)$(VERSION)$(RESET) make interface'
	@echo '---------------------------------------------------------------------'
	@echo ' $(BOLD)make [help]$(RESET) - Prints out this help message.'
	@echo ' $(BOLD)make test$(RESET)   - Compiles the whole test suite and runs it.'
	@echo ' $(BOLD)make build$(RESET)  - Compiles the project.'
	@echo ' $(BOLD)make files$(RESET)  - Prints out the files registered by make.'
	@echo ' $(BOLD)make clean$(RESET)  - Cleans up the build directory.'


#==============================================================================
#  PRODUCTION TARGETS
#==============================================================================

# Building prodution files
$(PRODUCTION_ENTRY_OBJECT) $(PRODUCTION_OBJECTS): $(PRODUCTION_ENTRY_FILE) $(PRODUCTION_FILES) $(HEADER_FILES)
	@echo $(ECHO_FLAG) "Compiling production code..  "
	$(SILENCE)$(CC) $(INC) $(CPPFLAGS) -c $^ 2> temp_error_file; if [ $$? -ne 0 ]; then touch _error_flag; fi; true
	$(SILENCE)if [ -f _error_flag ]; then \
	  rm -f _error_flag; \
		echo "$(RED)$(BOLD)Error$(RESET)"; \
		cat temp_error_file; \
		rm -f temp_error_file; \
		echo "$(RED)$(BOLD)Make aborted!$(RESET)"; \
		false; \
	else \
		if [ -s temp_error_file ]; then \
			echo "$(YELLOW)$(BOLD)Warning$(RESET)"; \
			cat temp_error_file; \
		else \
			echo "$(GREEN)$(BOLD)Done$(RESET)"; \
		fi \
	fi
	$(SILENCE)rm -f temp_error_file
	$(SILENCE)mv *.o $(OBJ_DIR)


#==============================================================================
#  UNIT TESTING TARGETS
#==============================================================================

# Main target for unit testing
test: $(OBJ_DIR) leak_detection $(OBJ_DIR)/$(TEST_SUITE_BINARY_NAME)
	$(SILENCE)./$(OBJ_DIR)/$(TEST_SUITE_BINARY_NAME) -c

# Verbose main target for unit testing
vtest: $(OBJ_DIR) leak_detection $(OBJ_DIR)/$(TEST_SUITE_BINARY_NAME)
	$(SILENCE)./$(OBJ_DIR)/$(TEST_SUITE_BINARY_NAME) -c -v

# Leak detection macro insertion
leak_detection:
	$(SILENCE)$(eval INC += -include $(MEMORY_LEAK_MACROS))

# Linking the unit testing binary
$(OBJ_DIR)/$(TEST_SUITE_BINARY_NAME): $(PRODUCTION_OBJECTS) $(TEST_OBJECTS) $(TEST_ENTRY_OBJECT)
	@echo $(ECHO_FLAG) "Linking test suite..         "
	$(SILENCE)$(CC) $^ $(LD_LIBRARIES) -o $@
	@echo "$(GREEN)$(BOLD)Done$(RESET)"
	@echo "---"

# Compiling unit test files with error handling
$(TEST_ENTRY_OBJECT) $(TEST_OBJECTS): $(TEST_FILES) $(TEST_ENTRY_FILE)
	@echo $(ECHO_FLAG) "Compiling testing code..     "
	$(SILENCE)$(CC) $(INC) $(CPPFLAGS) -c $^ 2> temp_error_file; if [ $$? -ne 0 ]; then touch _error_flag; fi; true
	$(SILENCE)if [ $$? -eq 0 ]; then \
		if [ -s temp_error_file ]; then \
			echo "$(YELLOW)$(BOLD)Warning$(RESET)"; \
			cat temp_error_file; \
		else \
			echo "$(GREEN)$(BOLD)Done$(RESET)"; \
		fi \
	else \
		echo "$(RED)$(BOLD)Error$(RESET)"; \
		cat temp_error_file; \
	fi
	$(SILENCE)rm -f temp_error_file
	$(SILENCE)mv *.o $(OBJ_DIR)


#==============================================================================
#  UTILITY TARGETS
#==============================================================================

# Creating the build directory
$(OBJ_DIR):
	$(SILENCE)mkdir -p $@

# Cleaning up the build directory
clean:
	@echo $(ECHO_FLAG) "Cleaning up.. "
	$(SILENCE)rm -rf $(OBJ_DIR)
	@echo "$(GREEN)$(BOLD)Done$(RESET)"

# File and target listing
files:
	@echo ' $(YELLOW)$(BOLD)Production files$(RESET)'
	@echo '   $(BOLD)Entry$(RESET):     $(PRODUCTION_ENTRY_FILE)'
	@echo '   $(BOLD)Headers$(RESET):   $(HEADER_FILES)'
	@echo '   $(BOLD)Sources$(RESET):   $(PRODUCTION_FILES)'
	@echo ' $(YELLOW)$(BOLD)Test files$(RESET)'
	@echo '   $(BOLD)Entry$(RESET):     $(TEST_ENTRY_FILE)'
	@echo '   $(BOLD)Sources$(RESET):   $(TEST_FILES)'
	@echo ' '
	@echo ' $(GREEN)$(BOLD)Production objects$(RESET)'
	@echo '   $(BOLD)Entry$(RESET):     $(PRODUCTION_ENTRY_OBJECT)'
	@echo '   $(BOLD)Objects$(RESET):   $(PRODUCTION_OBJECTS)'
	@echo ' $(GREEN)$(BOLD)Test objects$(RESET)'
	@echo '   $(BOLD)Entry$(RESET):     $(TEST_ENTRY_OBJECT)'
	@echo '   $(BOLD)Objects$(RESET):   $(TEST_OBJECTS)'

