# Salon Map · Godot 4 Game Jam 资源包

## 直接运行（Godot 4.3+）

1. 解压 ZIP。在 Godot Project Manager 中导入本文件夹的 `project.godot`。
2. 等待资源导入完成，按 F6 运行 `salon_map/scenes/salon_map.tscn`，或按 F5 运行项目。
3. 点击关卡图标或下方标签，再点 Play。未解锁关卡会显示解锁条件。
4. 默认进入 UI 演示窗口。点 `Complete stage (demo)` 测试通关解锁和进度保存；这不是真实玩法。
5. Back 展示你提供的标题图；`Choose a stage` 返回地图。Esc 关闭演示/标题页。

## 接到已有项目（无需 Autoload）

只把整个 `salon_map` 文件夹复制到你的项目根目录，保持路径为 `res://salon_map/`。
不要用此包的 `project.godot` 覆盖你的现有项目配置。
打开 `salon_map.tscn`，选中根节点，在 Inspector 填写 Stage 1 Scene 到 Stage 4 Scene、Main Menu Scene。
场景路径正确时，Play 直接跳转到真实关卡。接好后关闭 Demo Mode；路径未填写会显示提示。

项目显示设置：Viewport Width=1672、Height=941，Stretch Mode=canvas_items、Aspect=keep。
场景使用固定设计坐标；等比例缩放保证点击区域与画面同步，非同宽高比会留边。
若自己的项目采用其他基准分辨率，请把此场景放进单独的 SubViewport 做整体缩放，或统一项目基准。

## 在真实关卡中保存通关，再回地图

```gdscript
const ProgressStore = preload("res://salon_map/scripts/progress_store.gd")

func on_level_won() -> void:
    var stage_id: int = int(get_tree().get_meta("salon_stage_id", 1))
    var error := ProgressStore.complete_stage(stage_id)
    if error != OK:
        push_error("Save failed: " + error_string(error))
        return
    get_tree().change_scene_to_file("res://salon_map/scenes/salon_map.tscn")
```

也可监听根节点信号 `stage_selected(stage_id)`、`play_requested(stage_id)`、`back_requested()`。
此包适合整场景跳转；如果嵌入你自己的 UI 管理器，由信号接管导航即可。
存档文件：`user://salon_map_progress.cfg`，与工作目录无关。仅在自己的游戏项目内持久化。
测试时可调用 `preload("res://salon_map/scripts/progress_store.gd").reset()` 清空进度。

## 文件说明

- `assets/backgrounds/map_clean.png`：1672×941 清理底图，去掉按钮、信息栏、旗帜数字和锁。
- `assets/backgrounds/title_screen.png`：你提供的第二张标题图，用作 Back 的演示返回页。
- `assets/ui/png/`：透明背景 UI，2 倍分辨率；默认/悬停/按下按钮、面板、徽章、锁、完成标记、选中圈。
- `assets/ui/svg/`：同一套 UI 的可编辑矢量源文件；SVG 颜色可直接修改。
- `assets/fonts/`：开源 DejaVu Sans Bold 字体及原始许可。该字体用于英文 UI，不提供完整中文字形。
- `data/palette.json`：配色表；`asset_manifest.json`：UI 文件逻辑尺寸和导出尺寸。
- `scenes/salon_map.tscn`：可在编辑器查看和调整的界面节点与点击区域。
- `scripts/`：关卡选择、跳转、锁定和存档逻辑。
- `docs/reference_map.png`：已确认的整图配色参考，不参与运行。

## 素材边界与提交

此版本采用「固定地图插画底图 + 独立动态 UI」，适合 Game Jam 快速接入。
地图、道路、人物、椅子、镜子、水盆、门和 SALON MAP 标题仍烘焙在底图中，不是透明的单独角色或道具。
关卡数字、锁、完成标记、标签文字、底部信息和按钮均独立，可实时更新。第一关金色底座仍属于底图。
本包不包含剪发玩法、角色动画、音效或导出模板。提交前替换演示入口，完成真实玩法并自行导出。
PNG 是高分辨率素材，Godot 会首次导入；不包含可删除的 `.godot` 缓存。
按钮等程序绘制的 SVG/PNG 及本包原创接入代码可随你的游戏使用、修改与提交。
背景由你提供的图像及本对话生成版本制作；原始参考图的权利由你确认。
Game Jam 若要求披露 AI 素材，请按活动规定说明地图背景经 AI 辅助改色与清理。
