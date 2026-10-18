Oh No My Hair! 素材库 v1 — 2026-10-18

请先查看 previews/asset_library_overview.jpg。

最新画面
• ui/previews/title_main_menu_preview.png：已确认的亮金黄 Logo 标题主菜单，Start Game / About。
• ui/previews/salon_map_preview.png：已确认的简洁四落点地图。双人停在第一关；最后一关使用锁门和 ??? 隐藏内容。
• ui/source/：保留这两张图的生成原始尺寸版本。
重要：这两张是完整静态视觉预览，文字和按钮已经绘制在图片里；尚未拆分成新版背景、人物、Logo、按钮和路线图层，也没有点击、存档或移动逻辑。不要把整张预览当成无文字背景后再叠加一套文字。正式接入需要分层素材或重建 UI。

开场动画素材
• cutscene/panels/：11 张无字幕 PNG，1280×720；按文件编号播放，总长 39 秒。
• cutscene/optional_sfx/：镜头 04、05 的 SNIP! 可选版本，与对应无字版本二选一。
• docs/cutscene_timeline.json：镜头时长、英文字幕、建议运镜；图像路径相对于素材库根目录。
• docs/storyboard.csv：可用表格软件查看的镜头清单。
• docs/opening_subtitles_en.srt：39 秒英文字幕时间轴，无音频。
分镜末句 Today, we just wanted a good haircut. 与结尾 Bad hair. Good friends. 呼应。

可复用旧版分层
• reusable_earlier_title_parts/：此前静态标题页的背景、双人、前景，以及四张透明待机切片。
这些分层对应较早的站立构图，不是新动态主菜单的分层。旧粉色 Logo、旧版 Press any key 标题预览、被否定的理发店剖面地图均未收录。
使用 landing_characters.png，或者用两张人物/身体与两张马尾切片重组；不要同时叠加这两套。
四张待机切片保持同一 1280×720 画布注册，可精确重组原双人层；马尾仅适合轻微摆动，不是完整旋转骨骼或逐帧动画。

参考与说明
• references/：你提供的两位主角参考和已确认的风格样图；不包含商业游戏封面参考。
• docs/ui_flow_and_copy.json：页面流程、About 文案和共享通关规则；仅规格，未实现。
• docs/latest_ui_generation_prompts.json：当前标题主菜单和简化地图的英文出图提示。
• docs/asset_manifest.json / asset_manifest.csv：图片相对路径、尺寸、透明度、用途、状态和 SHA-256。

Godot 4 接入
1. 先以 1280×720 为参考分辨率导入 cutscene/panels；开启合适的 2D 纹理过滤。
2. 用 TextureRect 或 Sprite2D 显示分镜，字幕使用单独 Label/字幕条，底部预留 140 px。
3. AnimationPlayer / Tween 执行平移、缩放和淡入淡出；建议参数需在游戏实际视口检查，特写镜头不必强行推近 10–15%。
4. 用 JSON 时长驱动播放和跳过；过渡计入镜头时长，保持总长 39 秒。
5. 标题主菜单与地图需要按预览实现 UI；Start Game 进入地图，地图 Play 在首次开局先播放开场，之后进入所选关卡。
6. About 可显示：Created for GameJamPlus 26/27 / NPC Union / Singapore。
7. 四关共用一个进度；两位玩家一起前进。第四关未解锁时使用 ???，不展示 Boss。

生成视频
使用 11 张独立干净分镜作为各镜头首帧，不要用素材总览图生成视频。按 timeline/CSV 的顺序与时长剪辑，可先做静态图推拉，再叠加 SRT 和音效。图生视频时锁定无嘴火柴人造型、单线身体与粉/蓝发型，逐镜生成，再检查角色漂移。

交付范围与验证
这是图片素材和设计规格，不含视频、配音、音乐、音效文件、Godot 工程或已实现的播放器。
已检查图片解码、尺寸、透明度、切片重组、时间轴引用及 ZIP 完整性。尚未进行 Godot 实机运镜/裁切和交互测试；镜头 11 的通道需与你们实际 Fresh Cut 出生点衔接。
