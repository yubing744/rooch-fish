# RoochFish 合约技术方案

## 1. 需求描述

### 1.1 项目背景

RoochFish 是一款基于 Rooch 区块链平台的多人在线游戏。玩家通过购买和控制虚拟鱼在一个动态的鱼塘中进行竞争。游戏结合了成长、策略和经济元素，旨在为玩家提供有趣且具有经济激励的游戏体验。

### 1.2 功能概述

- **鱼的购买和生成**：玩家使用 RGAS 代币购买鱼，鱼在鱼塘中随机生成位置。
- **鱼的移动和成长**：玩家控制鱼的移动，通过吃掉比自己小的鱼或食物来增加大小。
- **投喂食物**：玩家可以使用 RGAS 代币向鱼塘投喂食物，食物在鱼塘中随机生成位置。
- **分成机制**：投喂食物的玩家在鱼销毁时可以获得一定比例的分成。
- **鱼的销毁和奖励**：鱼可以移动到出口位置进行销毁，玩家根据鱼的大小获得 RGAS 代币奖励。

### 1.3 非功能需求

- **安全性**：合约需要防止作弊和攻击，确保游戏公平性。
- **性能**：合约应高效，最小化 Gas 消耗。
- **可扩展性**：代码设计应便于后续功能扩展。
- **用户体验**：简化交互操作，提供及时的反馈。

## 2. 需求分析

### 2.1 角色分析

- **玩家**：游戏的参与者，可以购买鱼、控制鱼的移动、投喂食物、领取奖励。
- **鱼**：玩家控制的虚拟实体，有大小、位置等属性。
- **食物**：鱼可以吃的物品，用于增加鱼的大小。
- **鱼塘**：游戏的主舞台，包含鱼和食物。

### 2.2 功能分析

#### 2.2.1 鱼的购买和生成

- 玩家需要一种方式使用 RGAS 代币购买鱼。
- 鱼在购买后，需要在鱼塘中随机生成位置。
- 鱼具有初始大小和其他属性。

#### 2.2.2 鱼的移动和成长

- 玩家可以控制鱼的移动方向（上下左右）。
- 鱼可以通过以下方式成长：
  - 吃掉比自己小的鱼。
  - 吃掉鱼塘中的食物。
- 鱼的大小影响其能吃掉哪些鱼和奖励多少代币。

#### 2.2.3 投喂食物

- 玩家可以花费 RGAS 代币向鱼塘投喂食物。
- 食物在鱼塘中随机生成位置。
- 食物被鱼吃掉后会增加鱼的大小。

#### 2.2.4 分成机制

- 投喂食物的玩家在鱼销毁时获得分成。
- 分成比例根据投喂的食物数量和鱼的大小计算。
- 需要记录每个玩家投喂的食物数量。

#### 2.2.5 鱼的销毁和奖励

- 鱼可以移动到出口位置进行销毁。
- 玩家根据鱼的大小获得 RGAS 代币奖励。
- 奖励需要从某个资金池或合约余额中支付。

### 2.3 技术需求

- **随机数生成**：用于鱼和食物的随机位置生成。
- **状态管理**：记录鱼、食物、玩家投喂记录等状态。
- **对象系统**：使用 Move 的对象系统管理游戏实体。
- **时间操作**：可能需要记录时间戳，防止某些时间攻击。
- **安全措施**：防止重入攻击、溢出等常见智能合约漏洞。

## 3. 概要设计

### 3.1 模块划分

1. **RoochFish 主模块**：包含游戏的主要逻辑和入口函数。
2. **Fish 模块**：定义鱼的结构和行为。
3. **Food 模块**：定义食物的结构和生成机制。
4. **Pond 模块**：管理鱼塘的状态，包括鱼和食物的位置。
5. **Player 模块**：管理玩家的投喂记录和奖励结算。
6. **Utils 工具模块**：提供随机数生成、数学计算等辅助功能。

### 3.2 数据结构

- **Fish**：
  - 所属玩家地址
  - 大小（u64）
  - 位置（x, y 坐标）
  - 唯一标识符（id）
- **Food**：
  - 大小（固定值）
  - 位置（x, y 坐标）
  - 唯一标识符（id）
- **PondState**：
  - 鱼列表（映射或向量）
  - 食物列表（映射或向量）
- **PlayerState**：
  - 投喂食物数量
  - 累计分成

### 3.3 关键流程

- **鱼的购买**：调用购买函数，扣除 RGAS 代币，生成新的 Fish 对象并添加到 PondState 中。
- **鱼的移动**：玩家发送交易调用移动函数，更新 Fish 的位置。
- **吃鱼和食物**：在移动后，检查当前位置是否有可吃的鱼或食物，更新大小和状态。
- **投喂食物**：玩家调用投喂函数，扣除 RGAS 代币，生成新的 Food 对象并添加到 PondState 中，记录投喂数量。
- **鱼的销毁**：当鱼移动到出口位置，调用销毁函数，计算并发放奖励，销毁 Fish 对象，结算投喂玩家的分成。

## 4. 详细设计

### 4.1 模块和函数设计

#### 4.1.1 RoochFish 主模块

```move
module <ADDR>::RoochFish {
    use std::vector;
    use moveos_std::object::{Self, Object};
    use moveos_std::tx_context::TxContext;
    use <ADDR>::Fish;
    use <ADDR>::Food;
    use <ADDR>::Pond;
    use <ADDR>::Player;

    public entry fun purchase_fish(ctx: &mut TxContext);
    public entry fun move_fish(fish_id: u64, direction: u8, ctx: &mut TxContext);
    public entry fun feed_food(amount: u64, ctx: &mut TxContext);
    public entry fun destroy_fish(fish_id: u64, ctx: &mut TxContext);
}
```

#### 4.1.2 Fish 模块

```move
module <ADDR>::Fish {
    use moveos_std::object::{Object};
    use moveos_std::tx_context::TxContext;

    struct Fish has key, store {
        id: u64,
        owner: address,
        size: u64,
        position: (u64, u64),
    }

    public fun new(owner: address, id: u64, ctx: &mut TxContext): Object<Self::Fish>;
    public fun move(fish: &mut Self::Fish, direction: u8);
    public fun grow(fish: &mut Self::Fish, amount: u64);
}
```

#### 4.1.3 Food 模块

```move
module <ADDR>::Food {
    use moveos_std::object::{Object};
    use moveos_std::tx_context::TxContext;

    struct Food has key, store {
        id: u64,
        size: u64,
        position: (u64, u64),
    }

    public fun new(id: u64, ctx: &mut TxContext): Object<Self::Food>;
}
```

#### 4.1.4 Pond 模块

```move
module <ADDR>::Pond {
    use std::vector;
    use <ADDR>::Fish;
    use <ADDR>::Food;

    struct PondState has key {
        fishes: vector<Object<Fish::Fish>>,
        foods: vector<Object<Food::Food>>,
    }

    public fun add_fish(fish: Object<Fish::Fish>);
    public fun remove_fish(fish_id: u64);
    public fun add_food(food: Object<Food::Food>);
    public fun remove_food(food_id: u64);
    public fun get_state(): &mut Self::PondState;
}
```

#### 4.1.5 Player 模块

```move
module <ADDR>::Player {
    use std::vector;

    struct PlayerState has key {
        owner: address,
        feed_amount: u64,
        reward: u64,
    }

    public fun add_feed(owner: address, amount: u64);
    public fun add_reward(owner: address, amount: u64);
    public fun get_state(owner: address): &mut Self::PlayerState;
}
```

#### 4.1.6 Utils 工具模块

```move
module <ADDR>::Utils {
    use moveos_std::simple_rng;

    public fun random_position(): (u64, u64);
}
```

### 4.2 函数逻辑详解

#### 4.2.1 购买鱼函数

```move
public entry fun purchase_fish(ctx: &mut TxContext) {
    // 扣除固定的 RGAS 代币
    coin::burn<RGAS>(ctx.sender(), purchase_amount);

    // 生成新的鱼
    let fish_id = generate_unique_id();
    let position = Utils::random_position();
    let fish = Fish::new(ctx.sender(), fish_id, initial_size, position, ctx);

    // 将鱼添加到鱼塘
    Pond::add_fish(fish);
}
```

#### 4.2.2 移动鱼函数

```move
public entry fun move_fish(fish_id: u64, direction: u8, ctx: &mut TxContext) {
    // 验证鱼的所有权
    let fish = Pond::get_fish_mut(fish_id);
    assert!(fish.owner == ctx.sender(), ErrorFishNotOwned);

    // 移动鱼的位置
    Fish::move(&mut fish, direction);

    // 检查当前位置是否有可吃的鱼或食物
    handle_collisions(&mut fish, ctx);
}
```

#### 4.2.3 投喂食物函数

```move
public entry fun feed_food(amount: u64, ctx: &mut TxContext) {
    // 扣除 RGAS 代币
    coin::burn<RGAS>(ctx.sender(), amount);

    // 记录投喂数量
    Player::add_feed(ctx.sender(), amount);

    // 生成新的食物
    for i in 0..amount {
        let food_id = generate_unique_id();
        let position = Utils::random_position();
        let food = Food::new(food_id, position, ctx);
        Pond::add_food(food);
    }
}
```

#### 4.2.4 销毁鱼函数

```move
public entry fun destroy_fish(fish_id: u64, ctx: &mut TxContext) {
    // 验证鱼的所有权和位置
    let fish = Pond::get_fish(fish_id);
    assert!(fish.owner == ctx.sender(), ErrorFishNotOwned);
    assert!(is_at_exit(fish.position), ErrorNotAtExit);

    // 计算奖励
    let reward = calculate_reward(fish.size);

    // 分发奖励
    coin::mint<RGAS>(ctx.sender(), reward);

    // 结算投喂玩家的分成
    distribute_rewards(fish.size);

    // 从鱼塘中移除鱼
    Pond::remove_fish(fish_id);
}
```

### 4.3 关键算法

#### 4.3.1 随机位置生成

```move
public fun random_position(): (u64, u64) {
    let x = simple_rng::rand_u64_range(0, pond_width);
    let y = simple_rng::rand_u64_range(0, pond_height);
    (x, y)
}
```

#### 4.3.2 碰撞处理

```move
fun handle_collisions(fish: &mut Fish::Fish, ctx: &mut TxContext) {
    // 检查是否有可吃的鱼
    for other_fish in Pond::get_state().fishes {
        if fish.id != other_fish.id && fish.position == other_fish.position {
            if fish.size > other_fish.size {
                // 吃掉其他鱼
                fish.size += other_fish.size;
                Pond::remove_fish(other_fish.id);
            }
        }
    }

    // 检查是否有食物
    for food in Pond::get_state().foods {
        if fish.position == food.position {
            // 吃掉食物
            fish.size += food.size;
            Pond::remove_food(food.id);
        }
    }
}
```

#### 4.3.3 奖励和分成计算

```move
fun calculate_reward(size: u64): u64 {
    base_reward * size
}

fun distribute_rewards(fish_size: u64) {
    // 计算总的投喂量
    let total_feed = get_total_feed();

    // 给每个投喂玩家分发比例奖励
    for player in get_all_players() {
        let share = (player.feed_amount / total_feed) * fish_size * reward_ratio;
        Player::add_reward(player.owner, share);
    }
}
```

### 4.4 数据存储和访问

- 使用 `PondState` 来存储鱼和食物的全局状态。
- 每个玩家的投喂记录和奖励记录存在 `PlayerState` 中。
- 通过对象系统的 `Object<T>` 来管理鱼和食物，支持移动语义和资源安全。

## 5. 测试用例

### 5.1 测试环境准备

- 使用 Move 的测试框架，编写单元测试函数。
- 测试模块需要标记为 `#[test_only]`。

### 5.2 测试用例列表

#### 测试用例 1：购买鱼

- **步骤**：
  1. 模拟一个玩家账户，调用 `purchase_fish`。
  2. 检查 RGAS 代币余额是否正确扣除。
  3. 检查鱼是否正确添加到鱼塘中。
- **预期结果**：鱼成功创建，玩家代币扣除正确。

#### 测试用例 2：鱼的移动和成长

- **步骤**：
  1. 玩家控制鱼移动到有食物的位置。
  2. 调用 `move_fish`。
  3. 检查鱼的大小是否增加。
  4. 检查食物是否从鱼塘中移除。
- **预期结果**：鱼成功吃掉食物，大小正确增加。

#### 测试用例 3：投喂食物

- **步骤**：
  1. 玩家调用 `feed_food`，投喂一定数量的食物。
  2. 检查 RGAS 代币余额扣除是否正确。
  3. 检查食物是否正确添加到鱼塘中。
  4. 检查玩家的投喂记录是否更新。
- **预期结果**：食物成功添加，玩家投喂记录更新正确。

#### 测试用例 4：销毁鱼并获得奖励

- **步骤**：
  1. 玩家控制鱼移动到出口位置。
  2. 调用 `destroy_fish`。
  3. 检查玩家是否获得正确的奖励代币。
  4. 检查鱼是否从鱼塘中移除。
  5. 检查投喂玩家是否获得分成。
- **预期结果**：奖励和分成正确发放，鱼正确销毁。

#### 测试用例 5：尝试吃比自己大的鱼

- **步骤**：
  1. 创建两条鱼，A 和 B，B 比 A 大。
  2. 控制 A 移动到 B 的位置。
  3. 调用 `move_fish`。
  4. 检查鱼的状态。
- **预期结果**：A 不能吃掉 B，鱼的状态不变。

#### 测试用例 6：安全性测试

- **步骤**：
  1. 模拟非所有者尝试移动或销毁其他玩家的鱼。
  2. 调用相关函数。
- **预期结果**：操作被拒绝，抛出预期的错误。

### 5.3 测试断言

- 使用 `assert!` 来验证函数执行的结果。
- 检查状态变化是否符合预期。

### 5.4 测试结果记录

- 记录每个测试用例的执行结果。
- 对于失败的测试，分析原因并修复代码。
