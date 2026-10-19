# Pitch Final — 修复版 + 真人配音

在 `videos/Oh_No_My_Hair_Pitch_Final.mp4`（第一版，单人 AI 旁白）的基础上修复画面跳跃/闪烁，并把 AI 旁白换成真人录音。不是重新做一版 pitch：台词、页面、标题、配色、背景音乐和镜头顺序都沿用 Final。

| 文件 | 用途 |
|---|---|
| `recording_script.txt` | 录音稿（18 段，只读正文） |
| `build.py` | 识别录音 → 按稿对齐 → 切段、去掉重读和过长停顿 → 生成镜头时长、字幕、旁白轨 |
| `render.py` | 渲染画面，混合旁白与原背景音乐，输出 `videos/Oh_No_My_Hair_Pitch_Final_Fixed.mp4` 和 `.en.srt` |
| `qa.py` | 逐帧扫描成片与原版，列出场景内部的画面跳变 |
| `../editor/src/final/` | Remotion 合成（`data.ts` 由 `build.py` 生成） |

## 修了什么

Final 的游戏片段是循环播放的，而且每段录屏结尾都带着过关后切到下一个房间的转场。场景比片段长，于是画面会先闪到下一个房间、再跳回开头（例如 40 秒左右 Twin-Tails 那段）。逐帧比对后，同类问题共有：

| 场景 | Final 中的问题 | 修复 |
|---|---|---|
| Twin-Tails（约 0:28–0:43） | 片尾滑入 The Gel Curtain 房间，再跳回 The Washing Basin 开头 | 只播一次，截在转场之前，按场景长度调速 |
| Pompadour（约 0:43–0:57） | 片尾转场后跳回开头 | 同上 |
| Sling（约 0:57–1:14） | 停在等待画面 2 秒多，然后循环跳回 | 去掉等待（只有 HUD 计时在动），只播一次 |
| Water（约 1:30–1:48） | 结尾转场 + 跳回开头 | 截在转场之前 |
| Boss（约 1:48–2:07） | 片段循环跳回，随后 stomp 片段硬切盖上 | 不循环；boss → stomp 改为 8 帧叠化 |
| Prototype 卡片（约 2:50–3:07） | wet_coop 录屏在第 371 帧硬切到另一个画面，之后还循环 | 截在硬切之前，只播一次 |

Final 原画面上另有两处改动：Theme 页的黄色标签由 SOMETHING’S OFF 改为 JAM THEME: BETTER TOGETHER；预算拆分页卡片删去 “Online multiplayer excluded.”（见 `editor/src/final/Film.tsx` 的 `PATCHES`，补丁跟随该页原有的淡入淡出）。

页面布局沿用 Final：开场、故事、6 个游戏场景、Prototype、结尾由同一份 `PitchScene.tsx` 重新渲染（与 Final 逐像素比对，只差编码噪点）；Theme、Audience、Market、两页预算、Roadmap、Validation、Team 这 8 页的旧版布局已不在代码里，所以直接复用 Final 的原画面，只盖掉旧字幕条、按新旁白长度放慢或加快中段（两端的淡入淡出保持原速）。字幕按真人录音的词级时间重新生成，样式与 Final 相同。

`PitchScene.tsx` 只加了可选参数（`media`、`narration`、`storyCuts`），v2 的渲染结果不变。

## 替换配音

录音要求见 `recording_script.txt`：按顺序一次录完，段与段之间停 1.5–2 秒；读错就停一下，把整句重读，程序会剪掉读错的那一遍。m4a / wav / mp3 均可。

在仓库根目录：

```powershell
pitch/.venv-v3/Scripts/python.exe pitch/final_fix/build.py "C:/Recordings/pitch.m4a"
pitch/.venv-v3/Scripts/python.exe pitch/final_fix/render.py
pitch/.venv-v3/Scripts/python.exe pitch/final_fix/qa.py
```

`build.py` 会打印每段的匹配率、旁白长度、场景长度，以及剪掉的地方（`retake: …` 是重读，`pause …` 是超过 1.2 秒、被缩短到 0.6 秒的停顿）。只想检查对齐、不生成时间线时加 `--check-only`。识别模型在本机运行（faster-whisper `base.en`，缓存在 `build/pitch-v4-models`）。数字和人名被识别成别的写法（如 `$20,000`、`Perry`）不算重读，不会被剪；字幕始终用稿子原文。

### 剪辑清单（takes）

录音里整段重读、口头说明（"I'll say that again"）、即兴加词较多时，自动判断不可靠，就为这条录音写一份剪辑清单 `takes/<录音 sha256 前 12 位>.json`；`build.py` 发现同名清单会自动使用它。每段写明：

- `keep`：这一段用录音里的哪几段（秒），按播放顺序排列，可以从更早的一遍里借一句；
- `text`：这几段里实际说的话，字幕按它生成并对齐时间。

清单里还写明用哪个识别模型（`model`）。现有的 `takes/2edca47c302b.json` 对应 `hs_audio.m4a`：用 `medium.en` 识别，每段取最后一遍完整的朗读，Market 的最后一句取自第一遍（重读时漏了这一句），预算拆分一段不再用“Online multiplayer is outside this scope.”（之后计划加入联机），切点都落在静音处。清单内段落之间超过 1.2 秒的停顿按音量检测后缩短到 0.6 秒。

- 场景长度 = 0.4 秒 + 该段旁白 + 0.85 秒，与 Final 的节奏一致。
- 游戏画面按场景长度调速，最慢 0.5 倍；还不够长时停在最后一帧。
- 背景音乐用原来的 `calm.wav`，音量与 Final 相同；旁白高通 70 Hz、统一到 -17 LUFS，成片 -16 LUFS。

依赖：仓库里的 `pitch/.venv-v3`（已有 faster-whisper、numpy），`pitch/editor` 里 `npm install` 过的 Remotion，PATH 里的 FFmpeg。`build.py` 会把 Final.mp4 复制到 `editor/public/final/source.mp4`（已 git-ignore）作为 8 页复用画面的来源。
