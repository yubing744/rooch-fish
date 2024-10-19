# 定义变量
PACKAGE_NAME = rooch_fish
GAS_BUDGET = 1000
PACKAGE_PATH = .
BUILD_DIR = $(PACKAGE_PATH)/build
SOURCES_DIR = $(PACKAGE_PATH)/sources
TESTS_DIR = $(PACKAGE_PATH)/tests

# 默认目标
all: build

# 构建合约
build:
	@echo "Building the Move package..."
	rooch move build --path $(PACKAGE_PATH) --named-addresses rooch_fish=default --json

# 发布合约
publish:
	@echo "Publishing the Move package..."
	rooch client publish --path $(PACKAGE_PATH) --gas-budget $(GAS_BUDGET) --named-addresses rooch_fish=default

# 测试合约
test:
	@echo "Running tests..."
	rooch move test --path $(PACKAGE_PATH) --skip-fetch-latest-git-deps --named-addresses rooch_fish=default

# 清理构建文件
clean:
	@echo "Cleaning build directory..."
	rm -rf $(BUILD_DIR)

# 帮助信息
help:
	@echo "Makefile for Sui Move project"
	@echo ""
	@echo "Usage:"
	@echo "  make build	 - Build the Move package"
	@echo "  make publish   - Publish the Move package"
	@echo "  make test	  - Run tests"
	@echo "  make clean	 - Clean build directory"
	@echo "  make help	  - Show this help message"

.PHONY: all build publish test clean help