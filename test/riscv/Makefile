CC = gcc
CFLAGS += -I../../include
CFLAGS += -L../../build
CFLAGS += -lsyscall_intercept
CFLAGS += -fpic -shared

BIN_DIR = bin
BUILD_DIR = build
SRC_DIR = src

LD_LIBRARY_PATH = ./build:../../build
LD_PRELOAD = ./build

TESTS = clone \
		fcntl \
		mkdir \
		openat \
		read \
		statx \
		write


EXECUTABLES = $(BIN_DIR)/mkdir_test \
			  $(BIN_DIR)/clone_test \
			  $(BIN_DIR)/fcntl_test \
			  $(BIN_DIR)/openat_test \
			  $(BIN_DIR)/read_test \
			  $(BIN_DIR)/statx_test \
			  $(BIN_DIR)/write_test

INTERCEPT_LIBS = $(BUILD_DIR)/intercept_sys_mkdir.so \
				 $(BUILD_DIR)/intercept_sys_clone.so \
				 $(BUILD_DIR)/intercept_sys_fcntl.so \
				 $(BUILD_DIR)/intercept_sys_openat.so \
				 $(BUILD_DIR)/intercept_sys_read.so \
				 $(BUILD_DIR)/intercept_sys_statx.so \
				 $(BUILD_DIR)/intercept_sys_write.so

all: $(BIN_DIR) $(BUILD_DIR) $(EXECUTABLES) $(INTERCEPT_LIBS)

$(BUILD_DIR)/%.so: $(SRC_DIR)/%.c
	$(CC) -o $@ $< $(CFLAGS)

$(BIN_DIR)/%: $(SRC_DIR)/%.c
	$(CC) $< -o $@

test: $(TESTS)

$(TESTS):
	@echo "Running test: $@"
	@LD_LIBRARY_PATH=$(LD_LIBRARY_PATH) LD_PRELOAD=$(LD_PRELOAD)/intercept_sys_$@.so $(BIN_DIR)/$@_test \
		&& echo "Test $@ - \033[32mPASSED\033[0m" \
		|| echo "Test $@ - \033[31mFAILED\033[0m"
	@echo

clean:
	rm -f $(BIN_DIR)/*
	rm -f $(BUILD_DIR)/*
	rm -f *.txt
	rm -rf wrongdir/

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
