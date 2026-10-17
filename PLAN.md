# Bad Hair Day：Godot 开发计划

> 两个剪坏头发的朋友，必须靠各自离谱的发型配合着逃出失控的理发店。
>
> **一句话玩法**：你们俩**互相借用对方的头发能力**，一起**逃出理发店**，前提是**谁都没法单独过关**。

| 项目 | 决定 |
|---|---|
| Jam 主题 | **Better Together**（主）+ **Something's Off**（加分） |
| 类型 | 2D 横版合作解谜 + 轻战斗（森林冰火人 × 简化版空洞骑士） |
| 团队 | 2 名开发者，有编程经验，没做过游戏、没用过 Godot |
| 引擎 | **Godot 4.7.x 标准版（不要 .NET 版）+ GDScript** |
| 玩家 | 2 人，本地同屏（同一键盘，或键盘 + 手柄），不做联机 |
| 内容 | 2 种发型、每种 2 个技能、1–2 个组合技、2 种小兵、3 个短关卡（约 5–8 分钟） |
| 平台 | Web (HTML5) 给评委直接在浏览器玩，另附 Windows 版 |

---

## 0. 动手之前（第 0–2 小时）

### 0.1 先确认 Jam 规则
- 截止时间和**时区**、提交平台（多半是 itch.io）、素材是否必须自制、能不能用 CC0 素材。
- 规则要求“Jam 开始前已经动工的项目不算数”，所以游戏代码一律在 Jam 开始后再写。装工具、练教程不受限制。

### 0.2 环境准备（两人都要装）
1. 从 godotengine.org 下载 **Godot 4.7.x 标准版**（不是 .NET 版：Godot 4 的 C# 项目导不出 Web 版）。
2. Editor → *Manage Export Templates* → 下载导出模板，版本要和编辑器完全一致。
3. 新建项目：
   - Renderer 选 **Compatibility**，Web 导出最稳。
   - Project Settings → Display → Window：Viewport **640×360**，Window Override **1280×720**，Stretch Mode `viewport`，Scale Mode `integer`（像素风缩放不会糊）。
   - Rendering → Textures → Default Texture Filter 设为 **Nearest**（像素风必须）。
4. Git：在这个仓库里建项目。`.gitignore` 加上 `.godot/` 和 `/build/`。
5. **第 2 小时之前先做一次空项目的 Web 导出**，确认能在浏览器里打开。Web 预设里的 *Thread Support* 保持**关闭**，这样不需要 COOP/COEP 头，itch.io 上也不会白屏。

### 0.3 Godot 速成（每人约 1.5 小时，可以和 0.2 一起做）
- 把官方教程 *Your first 2D game* 跟着做一遍，要学会：场景/节点、`CharacterBody2D` + `move_and_slide()`、`Area2D` 信号、Input Map、实例化场景。
- 只记这一条坑：**4.x 里 `move_and_slide()` 不带参数**，先设置 `velocity` 再调用，而且**不要再乘 delta**。

---

## 1. 游戏设计（MVP 锁定版）

### 1.1 两个角色

| | 玩家 A：双马尾 “The Helicopter” | 玩家 B：美式前刺 “The Parry” |
|---|---|---|
| 技能键（按住） | **滑翔**：下落速度封顶，缓慢下降 | **前刺冲撞**：短冲刺，撞碎“脆墙”、击退小兵 |
| 攻击键（点按） | **甩发**：近身横扫，敌人**眩晕 1 秒**，不掉血 | **弹反**：0.15 秒判定窗口，把飞来的剪刀**原路打回** |
| 机关交互 | 用马尾**拉拉杆 / 抓挂钩**（固定距离判定，不做真绳索物理） | 顶开障碍物、触发重压开关 |

### 1.2 组合技（最重要，是 Better Together 的核心）
1. **马尾吊运**（必做）：A 走到 B 身边按住技能，B 就挂在 A 下方，A 带着 B 滑翔过深坑。挂着人时 A 下落得更快，所以 A 必须找高处起跳。
2. **人肉弹射**（必做）：A 站在 B 头上，B 按技能，把 A 弹到高处。
3. **弹反定向**（第 2 关用）：B 弹反剪刀，A 拉拉杆转动“反射板”，剪刀被折射后打中高处开关或敌人。

> 设计原则：普通小兵**一个人也能打**，合作只是更快。**机关和出口必须两个人配合**才能过。不要每一秒都强制合作，否则一个人手残就会卡死两个人。

### 1.3 敌人（只做 4 个基础系统：巡逻、冲撞、发射投射物、受伤）

| 敌人 | 行为（有限状态机） | 和头发的互动 |
|---|---|---|
| 电推剪机器人（近战） | `PATROL → STUNNED → DEAD`，第二天再加 `CHARGE` | A 甩发眩晕，B 冲撞击退/扣血 |
| 剪刀发射器（远程，固定位置） | 用 Timer 定时发射剪刀 | B 弹反剪刀，剪刀可以打敌人和开关 |
| *（可选）理发机器人 Boss* | 交替发剪刀和冲撞，复用上面两种逻辑 | 弹反打晕它，再用弹射把队友送去打弱点 |

### 1.4 三个关卡（每关 1–2 屏，**单屏固定镜头**，像森林冰火人）
1. **L1 “糟糕的发型”（教学）**：A 学滑翔，B 学冲撞。深坑必须靠马尾吊运过去，出口前有一面脆墙要 B 撞开。
2. **L2 “弹反合作”**：剪刀发射器 + 拉杆 + 反射板，弹回的剪刀要打中高处开关才开门。再放一只电推剪机器人练战斗。
3. **L3 “理发师的店”（综合）**：在压力下（发射器不停射击、加上小兵）连续使用两个组合技。时间够就把 Boss 放在这一关。

**胜利条件**：两个人都站进 `ExitZone` 才过关。
**失败**：任意一人 HP 归零，两人一起回到检查点（不做单人复活，省掉同步问题）。

### 1.5 Something's Off（便宜但有效的反转）
因为技能是挂在玩家身上的子节点（见第 2 节），**交换两人的发型只要约 20 行代码**：
- L3 中途理发师“好心帮你们修发型”，结果**两人的发型互换**（A 变成前刺，B 变成双马尾），画面上出现 “Wait. What?”。
- 结局再加一句文字反转：理发师要把头发恢复正常，但恢复了就没有超能力了，你们选择**保留烂发型**。

这一项排在第一优先级的拓展：做完 MVP 后先做它，比 Boss 便宜得多。

---

## 2. Godot 技术架构

### 2.1 目录结构
```
project.godot
autoload/
  game.gd              # 关卡切换、重开、检查点、暂停
scenes/
  player/
    player.tscn        # CharacterBody2D，两名玩家共用同一个场景
    player.gd
    abilities/
      hair_ability.gd  # 基类：on_skill_pressed / held / released, on_attack
      twin_tails.gd    # 滑翔 + 甩发 + 吊运
      pompadour.gd     # 冲撞 + 弹反 + 弹射
  enemies/
    clipper_bot.tscn / .gd
    scissor_turret.tscn / .gd
    scissor.tscn / .gd # 投射物，可以被弹反
  props/
    lever, door, pressure_plate, breakable_wall, deflector, switch, exit_zone, checkpoint
  levels/
    level_01.tscn  level_02.tscn  level_03.tscn
  ui/
    title.tscn  hud.tscn  win.tscn
assets/
  art/  audio/  fonts/
```

### 2.2 玩家场景
```
Player (CharacterBody2D)        player.gd，@export var player_id := 1
├── Sprite2D / AnimatedSprite2D
├── CollisionShape2D            # 一个胶囊或矩形，不要多个碰撞体
├── Ability (Node)              # 挂 twin_tails.gd 或 pompadour.gd，换发型就是换这个节点
├── HitBox (Area2D)             # 攻击判定，平时关闭，攻击时开启几帧
├── HurtBox (Area2D)            # 受伤判定，带 0.7 秒无敌
├── GrabArea (Area2D)           # 马尾吊运 / 拉拉杆的检测范围
├── HeadPad (Area2D)            # 头顶区域，用于“人肉弹射”
└── HairLine (Line2D)           # 吊运时画一条头发曲线，纯视觉
```

### 2.3 碰撞层（第 2 小时之前定好，写进 Project Settings → Layer Names）
| 层 | 名字 | 说明 |
|---|---|---|
| 1 | world | 地形、墙、平台 |
| 2 | players | |
| 3 | enemies | |
| 4 | player_attack | 玩家攻击判定、**被弹反后的剪刀** |
| 5 | enemy_attack | 敌人攻击判定、敌方剪刀 |
| 6 | interactables | 拉杆、开关、挂钩、出口 |

> 记住：layer 是“我是谁”，mask 是“我要检测谁”。A 要检测到 B，B 的 layer 必须在 A 的 mask 里。剪刀被弹反时，只需要把它的 layer 从 5 改成 4、mask 从 players 改成 enemies + interactables。

### 2.4 输入映射（Project Settings → Input Map）
动作按玩家编号命名，同一份 `player.gd` 用 `player_id` 拼出动作名。

| 动作 | P1（双马尾） | P2（前刺） | 手柄 |
|---|---|---|---|
| `pN_left` / `pN_right` | A / D | ← / → | 左摇杆、十字键 |
| `pN_jump` | W | ↑ | A / ✕ |
| `pN_skill`（按住） | F | K | RB / R1 |
| `pN_attack` | G | L | X / □ |

- **第 1 天就测键盘冲突（ghosting）**：两个人同时按住多个键，看有没有键丢失。有的话就让一个人用手柄。手柄绑定在 Input Map 里按 device 区分：device 0 → P1，device 1 → P2。
- 屏幕上和 itch 页面上都要写清楚操作方式，评委不会去猜。

### 2.5 角色控制器骨架（手感参数用“高度 + 时间”反推，不要瞎调数字）
```gdscript
class_name Player
extends CharacterBody2D

@export var player_id := 1
@export var run_speed := 140.0
@export var jump_height := 56.0      # 像素：16px 瓦片 × 3.5
@export var time_to_apex := 0.35
@export var fall_multiplier := 1.8
@export var coyote_time := 0.1
@export var jump_buffer := 0.12

@onready var ability: HairAbility = $Ability
@onready var gravity := 2.0 * jump_height / pow(time_to_apex, 2)
@onready var jump_velocity := -2.0 * jump_height / time_to_apex

var carried_by: Player = null        # 被马尾吊运时不受自身物理控制
var max_fall_speed := INF            # 滑翔时由 ability 压低
var _coyote := 0.0
var _buffer := 0.0

func act(action: String) -> StringName:
	return StringName("p%d_%s" % [player_id, action])

func _physics_process(delta: float) -> void:
	if carried_by:
		global_position = carried_by.global_position + Vector2(0, 24)
		velocity = Vector2.ZERO
		return

	_coyote = coyote_time if is_on_floor() else _coyote - delta
	_buffer -= delta
	if Input.is_action_just_pressed(act("jump")):
		_buffer = jump_buffer
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = jump_velocity
		_buffer = 0.0
		_coyote = 0.0
	if Input.is_action_just_released(act("jump")) and velocity.y < 0.0:
		velocity.y *= 0.45             # 短按小跳，长按大跳

	var g := gravity * (fall_multiplier if velocity.y > 0.0 else 1.0)
	velocity.y = minf(velocity.y + g * delta, max_fall_speed)
	velocity.x = Input.get_axis(act("left"), act("right")) * run_speed

	ability.tick(self, delta)          # 发型能力读取输入、修改 velocity / max_fall_speed
	move_and_slide()
```

### 2.6 关键机制的实现思路（全部选最省时间的写法）
- **滑翔**：按住技能且 `velocity.y > 0` 时 `max_fall_speed = 60`（吊运队友时调到 110）。
- **马尾吊运**：按下技能时，如果 `GrabArea` 里有队友，就设置 `teammate.carried_by = self`；松开技能或队友按跳就释放。头发用 `Line2D` 两点连线画出来。**不做真实绳索物理。**
- **拉拉杆**：拉杆有 `func interact(by: Player)`，A 在 `GrabArea` 范围内按技能就调用。拉杆发出 `toggled(on)` 信号，门 / 反射板去连接这个信号。
- **弹反**：攻击键打开 `HitBox` 约 0.15 秒，冷却 0.4 秒。剪刀进入 HitBox 就调用 `scissor.deflect(dir)`：速度反向、换碰撞层（见 2.3），再加 0.05 秒顿帧（hit-stop）和屏幕震动。
- **人肉弹射**：B 的 `HeadPad` 里有队友，并且 B 按下技能时，设置 `teammate.velocity.y = jump_velocity * 1.6`。
- **统一受伤接口**（第 2 小时定死，两个人都按这个写）：
  ```gdscript
  func take_hit(damage: int, stun_time: float = 0.0, knockback := Vector2.ZERO) -> void
  ```
  玩家、小兵、Boss、脆墙都实现它。每次挥击要记录已命中的对象，同一下只算一次伤害。
- **机关统一用信号**：`activated` / `deactivated`。关卡里在编辑器中连线，代码不需要互相引用。
- **小兵 FSM**：参考聊天里的 `clipper_enemy.gd`（巡逻 + 撞墙转向 + `take_hit` 眩晕）。第一版只做 `PATROL / STUNNED / DEAD`。巡逻放在连续平台上（暂时不做悬崖检测）。
- **镜头**：每关单屏固定 `Camera2D`。如果一关是两屏，镜头跟随两人中点，并用 `limit_*` 限制在关卡范围内。
- **玩家受伤**：0.7 秒无敌 + 闪烁 + 击退。死亡后通过 `Game.respawn_at_checkpoint()` 让两人一起复位。

---

## 3. 分工（尽量避免两个人改同一个 .tscn，否则 Git 冲突非常难解）

| Dev A：核心玩法 | Dev B：关卡与体验 |
|---|---|
| `player.tscn`、控制器、手感参数 | `TileMapLayer` + TileSet（带碰撞）、3 个关卡场景 |
| 两种发型能力、两个组合技 | 拉杆、门、开关、反射板、脆墙、出口、检查点 |
| HitBox/HurtBox、受伤、无敌帧 | 电推剪机器人、剪刀发射器、剪刀投射物 |
| 发型互换（Something's Off） | 标题、HUD、胜利/失败界面、`game.gd` 关卡流程 |
| 屏幕震动、顿帧、受击闪烁 | 音效 / 音乐接入、Web 导出、itch 页面 |

**第 2 小时之前一起定下来，之后不再改**：碰撞层表、输入动作名、`take_hit` 和 `interact` 接口、`activated` 信号、瓦片尺寸（16px）、目录结构。
**Git 规则**：每人只改自己负责的场景；改别人的场景前先在群里说一声；少量多次提交，每 1–2 小时 pull 一次。

---

## 4. 48 小时时间表（第 1 天结束前必须有一个完整可玩的关卡）

| 时间 | Dev A | Dev B | 里程碑 |
|---|---|---|---|
| **H0–2** | 一起：建项目、定接口和碰撞层、设置 Input Map | 同左；测试 Web 导出 | 空项目能在浏览器打开 |
| **H2–8** | 两个**彩色方块**能跑跳，手感调好；滑翔 + 冲撞 | 灰盒版 L1；拉杆/门/出口；电推剪 PATROL | **灰盒 L1 两人能通关** |
| H8–12 | 睡觉 | 睡觉 | |
| **H12–20** | 马尾吊运、人肉弹射、弹反 | 剪刀发射器 + 剪刀 + 反射板；灰盒 L2 | 组合技全部可用 |
| H20–24 | 受伤、无敌帧、死亡和检查点复位 | 灰盒 L3、关卡切换、胜利界面 | **完整流程：标题 → L1 → L2 → L3 → 胜利** |
| H24–30 | 睡觉，并**找一个外人试玩**，删掉没有效果的东西 | 同左 | 试玩反馈清单 |
| **H30–38** | 发型互换反转；顿帧 / 震动 / 粒子 | 替换美术（像素风）、动画、音效、BGM | 美术 + 手感都到位 |
| **H38–44** | **功能冻结**：只修崩溃和卡关 | 同左；在别的电脑上测 Web 版 | 无软锁 |
| **H44–48** | 截图、录 GIF | 导出、写 itch 页面、**在 H46 前提交** | **已提交到 Jam（不是只上传了页面）** |

**砍功能的顺序**（时间不够就从上往下砍）：Boss → 电推剪的 CHARGE 状态 → 结局文字反转 → 发型互换 → L3 缩成一屏。
**永远不砍**：两人移动、两个组合技、3 个关卡（实在不行 L3 可以很短）、重开、胜利界面。

---

## 5. 美术和音频（两个人都是程序员，所以选最省事的做法）
- 全程先用**彩色方块**，H30 之后再换美术。
- 风格：16×16 瓦片，一套调色板（比如 Lospec 上的 PICO-8 或 Endesga 32），角色 16×24 左右。**头发轮廓要夸张**，一眼就能分清谁是谁，这是角色的辨识度。
- 素材可以用 Kenney（CC0），或者用 Aseprite / LibreSprite / Piskel 自己画。只需要 4–6 帧：待机、跑、跳、技能。
- 音效用 jsfxr 或 ChipTone 生成 5 个（跳、弹反“叮”、冲撞、受伤、开门），配 1 首循环 BGM。
- 所有外部素材在页面的 Credits 里写明来源和许可证。

---

## 6. 提交检查清单
- [ ] Web 版在**另一台电脑**的浏览器上能玩（itch：*This file will be played in the browser*，设置 viewport 1280×720，打开全屏按钮）。
- [ ] Windows 版解压后，在没装 Godot 的电脑上能运行。
- [ ] 标题画面和 itch 页面都写了两名玩家的按键。
- [ ] 没有卡死，R 键或菜单可以重开当前关。
- [ ] 页面包含：一句话简介、选择的主题（Better Together + Something's Off）、截图 / GIF、操作说明、Credits。
- [ ] **作品已经提交到 Jam 的 submission**，而不只是建了项目页。

---

## 7. 第一个原型要验证什么（H2–8 的目标）
> 两个方块 + 一个剪刀发射器 + 一个拉杆 + 一扇门：A 拉住拉杆让挡板移开，B 掐准时机弹反剪刀，剪刀打中开关开门，两人都到出口才过关。

如果这个没有美术的版本，两个人玩起来已经需要沟通、有时机压力、失败了还想再来一次，那核心玩法就成立了。第二天专心做内容和打磨，不要再去碰未经验证的新系统。
