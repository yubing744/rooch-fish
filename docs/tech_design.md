# RoochFish 合约技术方案（优化版）

## 1. 引言

### 1.1 项目背景

"RoochFish" 是一款基于 Rooch 区块链平台的多人在线游戏。玩家通过购买和控制虚拟鱼在多个动态鱼塘中进行竞争。游戏结合了成长、策略和经济元素，旨在为玩家提供有趣且具有经济激励的游戏体验。游戏引入了体力系统和简化的食物来源追踪机制，增加了策略深度和游戏平衡性。

### 1.2 技术方案目的

本技术方案旨在详细描述 RoochFish 游戏的合约实现，包括需求分析、系统设计和详细实现方案等。该方案将指导开发团队高效、安全地完成合约开发。

## 2. 需求概述

### 2.1 功能需求

- **鱼的购买与生成**：玩家使用 RGAS 代币购买鱼，鱼在鱼塘中随机生成位置，具有初始大小和体力值。
- **鱼的移动与体力**：玩家控制鱼的移动，移动消耗体力，体力每秒自动恢复。体力为0时无法移动。
- **鱼的成长**：鱼通过吃掉比自己小的鱼或食物来增加大小，并在吃食物或小鱼时立即恢复体力。
- **鱼的销毁与奖励**：鱼可以移动到出口位置销毁，玩家根据鱼的大小获得 RGAS 代币奖励。鱼达到最大大小会“撑死”，并产生食物。
- **投喂食物**：玩家使用 RGAS 代币向鱼塘投喂食物，食物在鱼塘中随机生成位置。
- **食物来源追踪**：食物记录其来源的玩家地址，用于奖励分配。
- **奖励分配**：在鱼销毁或撑死时，按照一定比例分配奖励给开发者、鱼的所有者和食物来源的玩家。
- **新鱼保护机制**：新生鱼在1分钟内不能被其他鱼吃掉。

### 2.2 非功能需求

- **安全性**：合约需防止作弊和攻击，保证游戏公平性。
- **性能**：优化合约执行效率，降低 Gas 消耗。
- **可扩展性**：代码设计需易于扩展，支持未来功能添加。
- **用户体验**：简化交互流程，确保及时反馈和良好体验。

## 3. 系统分析

### 3.1 角色分析

- **玩家**：购买和控制鱼，投喂食物，获得奖励。
- **鱼**：游戏中的主要实体，具有大小、体力、位置等属性。
- **食物**：鱼可以吃的物品，增加鱼的大小并恢复体力。
- **鱼塘**：游戏的主要场景，容纳鱼和食物。

### 3.2 关键实体与属性

#### 鱼（Fish）

- **id**：唯一标识符
- **owner**：所有者地址
- **size**：大小
- **position**：位置（x, y）
- **stamina**：体力值（0-10）
- **last_stamina_update**：上次体力恢复的时间戳
- **created_at**：创建时间戳
- **food_sources**：食物来源记录（列表）

#### 食物（Food）

- **id**：唯一标识符
- **size**：大小
- **value**：价值
- **position**：位置（x, y）
- **feeder**：食物来源的玩家地址

#### 玩家（Player）

- **address**：玩家地址
- **feed_amount**：累积投喂食物数量
- **reward**：累积获得的奖励

#### 鱼塘（Pond）

- **fishes**：当前鱼的列表
- **foods**：当前食物的列表
- **max_fish_size**：鱼的最大大小限制

## 4. 系统设计

### 4.1 模块结构

- **RoochFish 主模块**：游戏的主要逻辑和入口函数。
- **Fish 模块**：定义鱼的结构和行为。
- **Food 模块**：定义食物的结构和行为。
- **Pond 模块**：管理鱼塘的状态。
- **Player 模块**：管理玩家的投喂和奖励记录。
- **Utils 工具模块**：提供辅助函数，如随机数生成、时间获取等。

### 4.2 数据结构设计

#### Fish 模块

```move
struct Fish has key, store {
    id: u64,
    owner: address,
    size: u64,
    position: (u64, u64),
    stamina: u8,
    last_stamina_update: u64,
    created_at: u64,
    food_sources: vector<(address, u64)>,
}
```

#### Food 模块

```move
struct Food has key, store {
    id: u64,
    size: u64,
    value: u64,
    position: (u64, u64),
    feeder: address,
}
```

#### Player 模块

```move
struct Player has key, store {
    address: address,
    feed_amount: u64,
    reward: u64,
}
```

#### Pond 模块

```move
struct PondState has key, store {
    fishes: vector<Object<Fish>>,
    foods: vector<Object<Food>>,
    max_fish_size: u64,
}
```

### 4.3 关键算法与逻辑

#### 4.3.1 体力系统

- **自动恢复**：鱼每秒恢复1点体力，最大为10点。
- **移动消耗**：每次移动消耗1点体力，体力不足无法移动。
- **即时恢复**：吃掉食物或小鱼，体力立即恢复到10点。

#### 4.3.2 移动逻辑

- **边界检测**：确保鱼的移动不超出鱼塘范围。
- **碰撞检测**：检测与其他鱼或食物的碰撞。

#### 4.3.3 吃鱼和吃食物

- **吃鱼条件**：只能吃掉比自己小的鱼，且目标鱼不在保护期内。
- **吃食物**：增加鱼的大小，并恢复体力。
- **食物来源记录**：记录食物的 feeder 地址和价值，用于奖励分配。

#### 4.3.4 奖励分配

- **鱼销毁时**：
  - 1% 奖励给开发者。
  - 79% 奖励给鱼的所有者。
  - 20% 根据食物来源按贡献比例分配给投喂者。
- **鱼撑死时**：
  - 1% 奖励给开发者。
  - 20% 根据食物来源按贡献比例分配给投喂者。
  - 79% 转化为食物，由其他鱼食用时给鱼的所有者带来收益。

## 5. 模块详细设计

### 5.1 RoochFish 主模块

```move
module <ADDR>::RoochFish {
    public entry fun purchase_fish(ctx: &mut TxContext);
    public entry fun move_fish(fish_id: u64, direction: u8, ctx: &mut TxContext);
    public entry fun feed_food(amount: u64, ctx: &mut TxContext);
    public entry fun destroy_fish(fish_id: u64, ctx: &mut TxContext);
}
```

#### 函数说明

- **purchase_fish**：玩家购买鱼，生成新鱼并添加到鱼塘。
- **move_fish**：玩家控制鱼的移动，处理体力和碰撞逻辑。
- **feed_food**：玩家投喂食物，生成食物并添加到鱼塘。
- **destroy_fish**：玩家销毁鱼，领取奖励并处理分配。

### 5.2 Fish 模块

```move
module <ADDR>::Fish {
    struct Fish has key, store { ... }

    public fun new(owner: address, id: u64, ctx: &mut TxContext): Object<Fish>;

    public fun move(fish: &mut Fish, direction: u8, ctx: &mut TxContext);

    public fun grow(fish: &mut Fish, amount: u64, feeder: address);

    public fun is_protected(fish: &Fish, current_time: u64): bool;

    public fun auto_recover_stamina(fish: &mut Fish, current_time: u64);
}
```

#### 函数说明

- **new**：创建新鱼，初始化属性。
- **move**：处理鱼的移动，消耗体力。
- **grow**：鱼吃掉食物或小鱼，增加大小并恢复体力，记录食物来源。
- **is_protected**：判断鱼是否在保护期内。
- **auto_recover_stamina**：自动恢复体力。

### 5.3 Food 模块

```move
module <ADDR>::Food {
    struct Food has key, store { ... }

    public fun new(id: u64, feeder: address, size: u64, value: u64, ctx: &mut TxContext): Object<Food>;
}
```

#### 函数说明

- **new**：创建新食物，记录来源和价值。

### 5.4 Pond 模块

```move
module <ADDR>::Pond {
    struct PondState has key, store { ... }

    public fun add_fish(fish: Object<Fish>);

    public fun remove_fish(fish_id: u64);

    public fun add_food(food: Object<Food>);

    public fun remove_food(food_id: u64);

    public fun get_state(): &mut PondState;
}
```

#### 函数说明

- **add_fish**：将鱼添加到鱼塘。
- **remove_fish**：从鱼塘移除鱼。
- **add_food**：将食物添加到鱼塘。
- **remove_food**：从鱼塘移除食物。
- **get_state**：获取鱼塘当前状态。

### 5.5 Player 模块

```move
module <ADDR>::Player {
    struct Player has key, store { ... }

    public fun add_feed(address: address, amount: u64);

    public fun add_reward(address: address, amount: u64);

    public fun get_state(address: address): &mut Player;
}
```

#### 函数说明

- **add_feed**：记录玩家的投喂数量。
- **add_reward**：添加玩家的奖励。
- **get_state**：获取玩家的状态信息。

### 5.6 Utils 工具模块

```move
module <ADDR>::Utils {
    public fun random_position(): (u64, u64);

    public fun current_timestamp(): u64;
}
```

#### 函数说明

- **random_position**：生成随机的位置坐标。
- **current_timestamp**：获取当前时间戳。

## 6. 实现细节

### 6.1 购买鱼

```move
public entry fun purchase_fish(ctx: &mut TxContext) {
    let sender = ctx.sender();
    // 扣除 RGAS 代币
    coin::burn<RGAS>(sender, purchase_amount);

    // 创建新鱼
    let fish_id = generate_unique_id();
    let position = Utils::random_position();
    let created_at = Utils::current_timestamp();
    let fish = Fish::new(sender, fish_id, ctx);

    // 添加到鱼塘
    Pond::add_fish(fish);
}
```

### 6.2 鱼的移动

```move
public entry fun move_fish(fish_id: u64, direction: u8, ctx: &mut TxContext) {
    let current_time = Utils::current_timestamp();
    let fish = Pond::get_fish_mut(fish_id);

    // 验证所有权
    assert!(fish.owner == ctx.sender(), ErrorFishNotOwned);

    // 自动恢复体力
    Fish::auto_recover_stamina(&mut fish, current_time);

    // 检查体力
    assert!(fish.stamina >= 1, ErrorInsufficientStamina);

    // 消耗体力
    fish.stamina -= 1;

    // 移动鱼
    Fish::move(&mut fish, direction, ctx);

    // 处理碰撞
    handle_collisions(&mut fish, ctx);

    // 检查是否撑死
    if fish.size >= Pond::get_state().max_fish_size {
        handle_overgrown_fish(&fish, ctx);
    }
}
```

### 6.3 投喂食物

```move
public entry fun feed_food(amount: u64, ctx: &mut TxContext) {
    let feeder = ctx.sender();
    // 扣除 RGAS 代币
    coin::burn<RGAS>(feeder, amount);

    // 记录投喂
    Player::add_feed(feeder, amount);

    // 生成食物
    for _ in 0..amount {
        let food_id = generate_unique_id();
        let food = Food::new(food_id, feeder, 1, 1, ctx); // 假设每单位食物大小和价值为1
        Pond::add_food(food);
    }
}
```

### 6.4 鱼的销毁

```move
public entry fun destroy_fish(fish_id: u64, ctx: &mut TxContext) {
    let fish = Pond::get_fish(fish_id);

    // 验证所有权和位置
    assert!(fish.owner == ctx.sender(), ErrorFishNotOwned);
    assert!(is_at_exit(fish.position), ErrorNotAtExit);

    // 计算奖励
    let total_reward = calculate_reward(fish.size);

    // 分配奖励
    distribute_rewards(&fish, total_reward);

    // 移除鱼
    Pond::remove_fish(fish_id);
}
```

### 6.5 处理撑死的鱼

```move
fun handle_overgrown_fish(fish: &Fish::Fish, ctx: &mut TxContext) {
    let fish_size = fish.size;
    let total_value = calculate_reward(fish_size);

    // 分配奖励
    distribute_rewards(fish, total_value);

    // 生成食物
    let remaining_value = total_value * 79 / 100;
    let food_value = remaining_value / 10;
    let food_size = fish_size / 10;

    for _ in 0..10 {
        let food_id = generate_unique_id();
        let food = Food::new(food_id, fish.owner, food_size, food_value, ctx);
        Pond::add_food(food);
    }

    // 移除鱼
    Pond::remove_fish(fish.id);
}
```

### 6.6 奖励分配

```move
fun distribute_rewards(fish: &Fish::Fish, total_reward: u64) {
    let dev_reward = total_reward / 100;
    coin::mint<RGAS>(DEVELOPER_ADDRESS, dev_reward);

    let owner_reward = total_reward * 79 / 100;
    coin::mint<RGAS>(fish.owner, owner_reward);

    let feeder_reward = total_reward * 20 / 100;
    let total_food_value = 0u64;
    let mut contributions = Table::new<address, u64>();

    for (feeder, value) in &fish.food_sources {
        total_food_value += *value;
        let entry = Table::get_mut_with_default(&mut contributions, *feeder, 0);
        *entry += *value;
    }

    if total_food_value > 0 {
        for (feeder, value) in Table::iter(&contributions) {
            let share = (*value * feeder_reward) / total_food_value;
            Player::add_reward(*feeder, share);
        }
    }
}
```

## 7. 测试计划

### 7.1 测试用例

#### 用例 1：体力消耗与恢复

- **步骤**：
  1. 创建鱼，初始体力应为10。
  2. 移动鱼一次，体力应减1。
  3. 等待1秒，体力应加1。

- **预期结果**：体力正确消耗和恢复。

#### 用例 2：鱼的移动和碰撞

- **步骤**：
  1. 控制鱼移动到有食物的位置。
  2. 检查鱼的大小和体力。

- **预期结果**：鱼的大小增加，体力恢复至10。

#### 用例 3：鱼的销毁和奖励

- **步骤**：
  1. 控制鱼移动到出口位置。
  2. 销毁鱼，检查玩家的余额和奖励记录。

- **预期结果**：玩家获得正确的奖励，投喂者的奖励正确分配。

#### 用例 4：鱼撑死处理

- **步骤**：
  1. 使鱼达到最大大小限制。
  2. 检查鱼是否撑死，是否生成食物。

- **预期结果**：鱼撑死，生成食物，奖励正确分配。

### 7.2 测试工具和环境

- 使用 Move 语言的测试框架编写单元测试。
- 模拟多种场景，确保逻辑正确。

## 8. 安全性考虑

- **权限控制**：确保只有鱼的所有者可以控制和销毁鱼。
- **防作弊**：防止恶意玩家篡改体力值、大小等关键属性。
- **随机性安全**：使用安全的随机数生成，防止位置预测。
- **防止重放攻击**：添加事务检查，防止重复操作。

## 9. 性能优化

- **数据结构优化**：使用高效的数据结构（如映射、向量）管理鱼和食物。
- **减少存储占用**：简化数据结构，降低链上存储成本。
- **批量操作**：支持批量投喂减少交易次数。

## 10. 未来扩展

- **多鱼塘支持**：引入不同规则和奖励的鱼塘。
- **特殊能力**：为鱼添加特殊技能或属性。
- **社交功能**：加入玩家互动、组队等功能。
- **活动和赛事**：定期举办游戏内活动，增加活跃度。

## 11. 结论

本技术方案详细描述了 RoochFish 游戏的合约设计和实现方法，重点优化了食物来源追踪和奖励分配机制。通过简化数据结构和逻辑，既确保了游戏的趣味性和公平性，又降低了实现和维护的复杂度。希望该方案能有效指导开发，打造一款受欢迎的区块链游戏。
