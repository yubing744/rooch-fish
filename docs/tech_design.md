# RoochFish 合约技术方案（更新版）

## 1. 需求描述

### 1.1 项目背景

RoochFish 是一款基于 Rooch 区块链平台的多人在线游戏。玩家通过购买和控制虚拟鱼在多个动态鱼塘中进行竞争。游戏结合了成长、策略和经济元素，旨在为玩家提供有趣且具有经济激励的游戏体验。

### 1.2 功能概述

- **鱼的购买和生成**：玩家使用 RGAS 代币购买鱼，鱼在鱼塘中随机生成位置。
- **鱼的移动和成长**：玩家控制鱼的移动，通过吃掉比自己小的鱼或食物来增加大小。
- **投喂食物**：玩家可以使用 RGAS 代币向鱼塘投喂食物，食物在鱼塘中随机生成位置。
- **分成机制**：投喂食物的玩家在鱼销毁时可以获得一定比例的分成。
- **鱼的销毁和奖励**：鱼可以移动到出口位置进行销毁，玩家根据鱼的大小获得 RGAS 代币奖励。
- **最大鱼大小限制**：鱼达到最大大小时会"撑死"并转化为食物。
- **新鱼保护机制**：新生鱼在1分钟内不能被其他鱼吃掉。

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
- 新生鱼有1分钟的保护期。

#### 2.2.2 鱼的移动和成长

- 玩家可以控制鱼的移动方向（上下左右）。
- 鱼可以通过以下方式成长：
  - 吃掉比自己小的鱼。
  - 吃掉鱼塘中的食物。
- 鱼的大小影响其能吃掉哪些鱼和奖励多少代币。
- 鱼有最大大小限制，达到后会"撑死"并转化为食物。

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
- 1% 的奖励分配给开发者。

### 2.3 技术需求

- **随机数生成**：用于鱼和食物的随机位置生成。
- **状态管理**：记录鱼、食物、玩家投喂记录等状态。
- **对象系统**：使用 Move 的对象系统管理游戏实体。
- **时间操作**：记录时间戳，用于新鱼保护机制。
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
  - 创建时间戳
- **Food**：
  - 大小（固定值）
  - 位置（x, y 坐标）
  - 唯一标识符（id）
- **PondState**：
  - 鱼列表（映射或向量）
  - 食物列表（映射或向量）
  - 最大鱼大小限制
- **PlayerState**：
  - 投喂食物数量
  - 累计分成

### 3.3 关键流程

- **鱼的购买**：调用购买函数，扣除 RGAS 代币，生成新的 Fish 对象并添加到 PondState 中。
- **鱼的移动**：玩家发送交易调用移动函数，更新 Fish 的位置。
- **吃鱼和食物**：在移动后，检查当前位置是否有可吃的鱼或食物，更新大小和状态。
- **投喂食物**：玩家调用投喂函数，扣除 RGAS 代币，生成新的 Food 对象并添加到 PondState 中，记录投喂数量。
- **鱼的销毁**：当鱼移动到出口位置，调用销毁函数，计算并发放奖励，销毁 Fish 对象，结算投喂玩家的分成。
- **鱼的"撑死"**：检查鱼是否达到最大大小，如果是，则将其转化为食物。

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
        created_at: u64,
    }

    public fun new(owner: address, id: u64, ctx: &mut TxContext): Object<Self::Fish>;
    public fun move(fish: &mut Self::Fish, direction: u8);
    public fun grow(fish: &mut Self::Fish, amount: u64);
    public fun is_protected(fish: &Self::Fish, current_time: u64): bool;
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
        max_fish_size: u64,
    }

    public fun add_fish(fish: Object<Fish::Fish>);
    public fun remove_fish(fish_id: u64);
    public fun add_food(food: Object<Food::Food>);
    public fun remove_food(food_id: u64);
    public fun get_state(): &mut Self::PondState;
    public fun check_and_handle_overgrown_fish();
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
    public fun current_timestamp(): u64;
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
    let created_at = Utils::current_timestamp();
    let fish = Fish::new(ctx.sender(), fish_id, initial_size, position, created_at, ctx);

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

    // 检查是否达到最大大小
    if fish.size >= Pond::get_state().max_fish_size {
        handle_overgrown_fish(fish);
    }
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
    let dev_reward = reward / 100; // 1% 给开发者
    let player_reward = reward - dev_reward;
    coin::mint<RGAS>(DEVELOPER_ADDRESS, dev_reward);
    coin::mint<RGAS>(ctx.sender(), player_reward);

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

好的，我们继续从4.3.2开始：

#### 4.3.2 碰撞处理

```move
fun handle_collisions(fish: &mut Fish::Fish, ctx: &mut TxContext) {
    let current_time = Utils::current_timestamp();

    // 检查是否有可吃的鱼
    for other_fish in Pond::get_state().fishes {
        if fish.id != other_fish.id && fish.position == other_fish.position {
            if fish.size > other_fish.size && !Fish::is_protected(other_fish, current_time) {
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

#### 4.3.3 处理超大鱼

```move
fun handle_overgrown_fish(fish: &Fish::Fish) {
    // 将鱼转化为10份食物
    for _ in 0..10 {
        let food_id = generate_unique_id();
        let position = Utils::random_position();
        let food = Food::new(food_id, fish.size / 10, position, ctx);
        Pond::add_food(food);
    }

    // 从鱼塘中移除鱼
    Pond::remove_fish(fish.id);
}
```

#### 4.3.4 奖励和分成计算

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

#### 4.3.5 新鱼保护机制

```move
public fun is_protected(fish: &Fish::Fish, current_time: u64): bool {
    current_time - fish.created_at < 60 // 60秒保护期
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
  4. 检查开发者是否获得1%的奖励。
  5. 检查鱼是否从鱼塘中移除。
  6. 检查投喂玩家是否获得分成。
- **预期结果**：奖励和分成正确发放，鱼正确销毁。

#### 测试用例 5：新鱼保护机制

- **步骤**：
  1. 创建一条新鱼。
  2. 尝试用另一条大鱼在1分钟内吃掉新鱼。
  3. 等待1分钟后再次尝试。
- **预期结果**：1分钟内新鱼不能被吃掉，1分钟后可以被吃掉。

#### 测试用例 6：鱼达到最大大小

- **步骤**：
  1. 创建一条鱼并使其不断成长。
  2. 当鱼达到最大大小时，移动鱼。
  3. 检查鱼是否转化为食物。
- **预期结果**：鱼成功转化为10份食物，原鱼从鱼塘中移除。

#### 测试用例 7：安全性测试

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

## 6. 安全性考虑

- 实现访问控制，确保只有鱼的所有者可以控制和销毁鱼。
- 使用安全的随机数生成方法，防止预测攻击。
- 实现交易限制，防止短时间内的大量操作。
- 仔细处理数学计算，防止整数溢出。
- 实现紧急暂停机制，以应对潜在的安全问题。

## 7. 性能优化

- 优化数据结构，使用适当的集合类型来存储鱼和食物。
- 实现批量处理机制，减少交易次数。
- 使用链下计算和链上验证的模式来处理复杂的逻辑。

## 8. 未来扩展

- 实现多个鱼塘，每个鱼塘有不同的规则和奖励机制。
- 添加特殊能力或道具系统，增加游戏的策略性。
- 实现排行榜和成就系统，增加游戏的社交性和竞争性。
- 考虑实现跨链功能，允许不同区块链上的玩家参与游戏。

## 9. 结论

本技术方案详细描述了 RoochFish 游戏的实现细节，包括核心功能、数据结构、关键算法和测试策略。通过这个设计，我们可以实现一个安全、高效且有趣的区块链游戏。在实际开发过程中，可能需要根据具体情况进行调整和优化。
