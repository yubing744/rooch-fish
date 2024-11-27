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
	rooch move publish --path $(PACKAGE_PATH) --named-addresses rooch_fish=default

# 初始化游戏世界
init-world:
	@echo "Init RoochFish world..."
	rooch move run --function  0x24840092564334fb3f5c63a864ff9c13bbdafaab906f48ee7178f26a3dc8554b::rooch_fish::init_world --json

# 查看游戏世界
view-world:
	rooch state --access-path /object/0x24840092564334fb3f5c63a864ff9c13bbdafaab906f48ee7178f26a3dc8554b::rooch_fish::GameState

# 查看游戏世界
view-ponds:
	rooch rpc request --method rooch_listFieldStates --params '["0x48954635d648a30c92751ebff4a6ee54bd8edfa3a97e7103c75f5cfd199c27a7", null, "8", {"decode": true, "showDisplay": true}]' --json

# 购买鱼
purchase_fish:
	rooch move run --function  0x24840092564334fb3f5c63a864ff9c13bbdafaab906f48ee7178f26a3dc8554b::rooch_fish::purchase_fish --args object_id:0x5e89df84a672ea3697916f3a2a2ada4c63586db573b2e8af666da7d2b1084fd6 --args u64:0 --json

# 查看购买的鱼ID
view_fish_ids:
	rooch move view --function 0x24840092564334fb3f5c63a864ff9c13bbdafaab906f48ee7178f26a3dc8554b::rooch_fish::get_pond_player_fish_ids --args object_id:0x5e89df84a672ea3697916f3a2a2ada4c63586db573b2e8af666da7d2b1084fd6 --args 0u64 --args 'address:default'

# 移动鱼
move_fish:
	rooch move run --function  0x24840092564334fb3f5c63a864ff9c13bbdafaab906f48ee7178f26a3dc8554b::rooch_fish::move_fish --args object_id:0x5e89df84a672ea3697916f3a2a2ada4c63586db573b2e8af666da7d2b1084fd6 --args u64:0 --args u64:5 --args u8:0 --json --gas-profile

# 测试合约
debug:
	@echo "Running tests..."
	rooch move test --path $(PACKAGE_PATH) --skip-fetch-latest-git-deps --ignore_compile_warnings --named-addresses rooch_fish=default pond

# 测试合约
test:
	@echo "Running tests..."
	rooch move test --path $(PACKAGE_PATH) --skip-fetch-latest-git-deps --ignore_compile_warnings --named-addresses rooch_fish=default

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