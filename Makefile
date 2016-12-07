.PHONY: test clean leak_detection

SILENCE:=@
ECHO_FLAG:=-n
CC:=g++

CPPUTEST_INCLUDE_DIR := /usr/local/include/CppUTest
CPPUTEST_EXT_INCLUDE_DIR := /usr/local/include/CppUTestExt
CPPUTEST_LIB_DIR := /usr/local/lib

PROJECT_NAME := C-demo project
VERSION := $(shell cat VERSION)

RED := $(shell tput setaf 1)
GREEN := $(shell tput setaf 2)
YELLOW := $(shell tput setaf 3)
BOLD := $(shell tput bold)
RESET:= $(shell tput sgr0)

INC_DIR := include
SRC_DIR := src
TST_DIR := test
OBJ_DIR := build

HEADER_FILES := $(wildcard $(INC_DIR)/*.h)
SOURCE_FILES := $(wildcard $(SRC_DIR)/*.c)
TEST_FILES   := $(wildcard $(TST_DIR)/*.cpp)

PRODUCTION_OBJECT_FILES = $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SOURCE_FILES))
TEST_OBJECT_FILES = $(patsubst $(TST_DIR)/%.cpp,$(OBJ_DIR)/%.o,$(TEST_FILES))

CPPFLAGS += -Wall
CPPFLAGS += -fdiagnostics-color
CPPFLAGS += -I$(CPPUTEST_INCLUDE_DIR)
CPPFLAGS += -I$(CPPUTEST_EXT_INCLUDE_DIR)
CPPFLAGS += -I$(INC_DIR)
LD_LIBRARIES = -L$(CPPUTEST_LIB_DIR) -lCppUTest -lCppUTestExt
MEMORY_LEAK_MACROS = $(CPPUTEST_INCLUDE_DIR)/MemoryLeakDetectorMallocMacros.h
INC =

help:
	@echo '---------------------------------------------------'
	@echo ' $(PROJECT_NAME) $(VERSION) make interface'
	@echo '---------------------------------------------------'
	@echo 'Header files:            $(HEADER_FILES)'
	@echo 'Source files:            $(SOURCE_FILES)'
	@echo 'Test files:              $(TEST_FILES)'
	@echo 'Production object files: $(PRODUCTION_OBJECT_FILES)'
	@echo 'Test object files:       $(TEST_OBJECT_FILES)'


# BUILDING TARGETS
$(OBJ_DIR):
	$(SILENCE)mkdir -p $@

$(OBJ_DIR)/%.o : $(SRC_DIR)/%.c $(INC_DIR)/production.h
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

clean:
	@echo $(ECHO_FLAG) "Cleaning up.. "
	$(SILENCE)rm -rf $(OBJ_DIR)
	@echo "$(GREEN)$(BOLD)Done$(RESET)"

# UNIT TESTING TARGETS
test: $(OBJ_DIR) leak_detection $(OBJ_DIR)/testsuite
	$(SILENCE)./build/testsuite -c

vtest: $(OBJ_DIR) leak_detection $(OBJ_DIR)/testsuite
	$(SILENCE)./build/testsuite -c -v

leak_detection:
	$(SILENCE)$(eval INC += -include $(MEMORY_LEAK_MACROS))

$(OBJ_DIR)/testsuite: $(PRODUCTION_OBJECT_FILES) $(TEST_OBJECT_FILES)
	@echo $(ECHO_FLAG) "Linking test suite..         "
	$(SILENCE)$(CC) $^ $(LD_LIBRARIES) -o $@
	@echo "$(GREEN)$(BOLD)Done$(RESET)"
	@echo "---"

$(TEST_OBJECT_FILES): $(TEST_FILES)
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

files:
	@echo 'Header files:            $(HEADER_FILES)'
	@echo 'Source files:            $(SOURCE_FILES)'
	@echo 'Test files:              $(TEST_FILES)'
	@echo 'Production object files: $(PRODUCTION_OBJECT_FILES)'
	@echo 'Test object files:       $(TEST_OBJECT_FILES)'
