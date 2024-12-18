## 游戏策划：你鱼了吗（优化版）

### 1. 核心概念

"你鱼了吗"是一款基于 Rooch 区块链的多人在线游戏，玩家通过购买和控制虚拟鱼在多个动态鱼塘中进行竞争。游戏结合了成长、策略和经济元素，玩家可以通过吃掉其他鱼或收集食物来成长，并在特定条件下获得代币奖励。玩家还可以向鱼塘投喂食物，影响游戏经济并获得潜在收益。游戏引入了体力系统，增加了策略深度和平衡性。

### 2. 游戏机制和规则

#### 2.1 鱼塘系统

- **多鱼塘设计**：游戏包含多个鱼塘，每个鱼塘有不同的大小、容量和购买价格。
- **鱼塘参数**：每个鱼塘有固定的宽度、高度、最大鱼数量和最大食物数量。
- **最大鱼大小限制**：每个鱼塘设定一个最大鱼大小限制。当鱼的大小达到或超过这个限制时，鱼会"撑死"并消失，生成一定数量的食物（如10份），这些食物会随机分布在鱼塘中。
- **出口区域**：每个鱼塘都有特定的出口区域，鱼可以在此销毁获得奖励。

#### 2.2 购买和生成

- **购买鱼**：玩家使用 RGAS 代币在特定鱼塘中购买鱼，每个鱼塘的购买价格不同。
- **随机生成**：新鱼在鱼塘中随机生成位置，并赋予固定初始大小。
- **新鱼保护机制**：刚出生的鱼在1分钟内不能被其他鱼吃掉，提供初期保护。

#### 2.3 移动和成长

- **移动控制**：
  - 玩家可以控制鱼在鱼塘中的上下左右移动。
  - 每次移动消耗1点体力。
  - 当体力为0时，鱼无法移动。
- **体力系统**：
  - 每条鱼都有体力属性，最大值为10点。
  - 每秒自动恢复1点体力。
  - 体力不能超过最大值10点。
  - 吃掉食物或小鱼时，立即恢复10点体力。
- **成长机制**：
  - 吃掉比自己小的鱼以增加大小，并立即恢复10点体力。
  - 吃掉鱼塘中的食物以增加大小，并立即恢复10点体力。
  - 当鱼达到最大大小限制时，鱼会"撑死"并转化为食物。
- **边界限制**：鱼的移动受到鱼塘边界的限制。

#### 2.4 投喂和食物系统

- **投喂食物**：
  - 玩家可以使用 RGAS 代币向鱼塘投喂食物。
  - 投喂的食物数量会影响鱼塘中的食物总量。
- **食物生成**：食物在鱼塘中随机位置生成，数量有上限。

#### 2.5 交互和竞争

- **吃鱼规则**：鱼只能吃掉比自己小的鱼，吃掉后立即恢复10点体力。
- **食物消耗**：吃掉食物后，除了增加大小外，还会立即恢复10点体力。
- **新鱼保护**：新鱼在出生后的1分钟内受到保护，不能被其他鱼吃掉。
- **碰撞检测**：系统会自动检测鱼与鱼、鱼与食物之间的碰撞并处理结果。

#### 2.6 退出和奖励

- **出口机制**：鱼可以移动到鱼塘的特定出口区域进行销毁。
- **代币奖励**：
  - 鱼在出口销毁时，玩家根据鱼的大小获得 RGAS 代币奖励。
  - 奖励分配：
    - **1%** 的奖励分配给开发者，用于支持游戏的持续开发和维护。
    - **20%** 的奖励分配给投喂食物的玩家，基于鱼吃掉的食物中每个玩家投喂的食物占总食物的比例。
    - 剩余的奖励归鱼的拥有者所有。

#### 2.7 经济系统

- **全局经济**：游戏维护一个全局的玩家列表，记录总投喂量和玩家数量。
- **鱼塘经济**：每个鱼塘有独立的经济系统，包括玩家列表、总投喂量等。
- **体力管理**：玩家需要合理管理鱼的体力，在移动和休息之间找到平衡。

### 3. 玩家目标和策略

#### 3.1 主要目标

- **最大化收益**：通过培育大鱼并在适当时机销毁来获得最大的 RGAS 代币奖励。
- **生存和成长**：在竞争激烈的环境中生存并成为最大的鱼。

#### 3.2 策略考虑

- **鱼塘选择**：根据自己的策略和资金选择合适的鱼塘。
- **投资平衡**：平衡购买鱼、投喂食物和获取奖励之间的关系。
- **风险管理**：在成长过程中避免被更大的鱼吃掉。
- **时机把握**：选择合适的时机将鱼移动到出口区域获得奖励。
- **最大大小管理**：在鱼接近最大大小时，决定是否将鱼移动到出口区域以获得代币奖励，或者冒险继续增长以获取更多食物。
- **体力管理**：合理规划移动路径，避免体力耗尽导致无法及时躲避危险或捕食。
- **休息策略**：在安全区域让鱼休息恢复体力，为之后的快速移动做准备。
- **体力恢复策略**：权衡是否值得冒险去吃食物或小鱼来快速恢复体力。
- **攻守平衡**：在追逐猎物和保存体力之间做出选择，因为成功捕食可以立即恢复体力。
- **风险评估**：评估是否值得消耗体力去追逐食物或小鱼，考虑到成功后可以立即恢复体力。

### 4. 技术实现

#### 4.1 智能合约

- 使用 Move 语言编写智能合约，实现鱼塘、鱼、食物的核心逻辑。
- 实现购买、移动、成长、销毁和投喂等关键功能。
- 在鱼的属性中添加体力值，并实现体力消耗和恢复的逻辑。
- 在移动函数中加入体力检查，确保只有足够体力时才能移动。
- 在吃掉食物或小鱼的逻辑中添加立即恢复体力的功能。
- 确保体力恢复不会超过最大值10点。
- 保证合约的安全性和效率。

#### 4.2 前端开发

- 开发直观的用户界面，展示多个鱼塘和游戏状态。
- 实现实时更新和交互功能。
- 在用户界面中显示每条鱼的当前体力值。
- 实现体力恢复的视觉反馈，让玩家清楚地知道何时可以再次移动。
- 实现吃掉食物或小鱼时体力快速恢复的视觉效果，让玩家清楚地感知到体力的变化。
- 可以考虑添加一个特殊的动画或声音效果，以强调快速恢复体力。
- 集成区块链钱包，简化代币操作。

#### 4.3 后端服务

- 开发后端服务来处理高频更新和复杂计算。
- 实现游戏状态的同步和持久化。
- 实现体力自动恢复的计时器功能。
- 确保体力值的实时同步和更新。
- 优化体力恢复的计算逻辑，确保在正常恢复和快速恢复之间的平衡。
- 实现相关的数据统计，如玩家通过吃食物/小鱼恢复体力的次数，以便于后续的游戏平衡调整。

### 5. 未来扩展

- 引入新的鱼塘类型，增加游戏的多样性。
- 实现鱼的特殊能力或属性系统。
- 加入社交功能，如组队、公会等。
- 举办定期活动或比赛，增加游戏的趣味性。
- 根据玩家反馈和数据分析，调整体力系统的参数，以优化游戏平衡。
- 考虑引入更多与体力相关的特殊道具或技能，增加策略深度。
