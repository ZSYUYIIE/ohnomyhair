# Oh No My Hair — Pitch V4

成片时长 **4:28.6**，1920×1080、30fps。分支 `feat/pitch-v4`，游戏基于拉取后的 `master` / `origin/master` **c51cacc**；旧 V3 素材单独归档后带入，没有覆盖最新游戏代码。

| 文件 | 用途 |
|---|---|
| [V4 成片](../videos/Oh_No_My_Hair_Pitch_v4.mp4) | 单人女性 AI 临时旁白、英文字幕、游戏音效和持续背景音乐 |
| [无背景音乐版](../videos/Oh_No_My_Hair_Pitch_v4_NoBGM.mp4) | 相同画面，保留旁白与游戏音效 |
| [干净画面版](../videos/Oh_No_My_Hair_Pitch_v4_Clean.mp4) | 无声、无烧录字幕，便于外部剪辑 |
| [直接朗读的稿子](recording_script.txt) | 一个人、一个完整录音，487 个英文词 |
| [字幕](../videos/Oh_No_My_Hair_Pitch_v4.en.srt) | 独立英文字幕 |
| [分镜与时码](storyboard.txt) | 14 段的顺序、时长和台词 |
| [制作决策](production_brief.json) | 需求、视觉来源、镜头卡与事实边界 |
| [技术自检](review/technical_checks.json) / [独立终检](review/independent_review.txt) | 最终编码文件的检查证据 |

顺序：游戏名与一句话定位 → 团队 → 故事 → 两人的能力 → 胶墙合作 → 弹反／接住／上抛 → 水与吹风机 → 换发型 → Boss → 受众 → 当前原型 → 计划 → 预算 → 试玩入口。

## 你录好之后如何替换

打开 `recording_script.txt`，**只读正文，按顺序录成一个文件**。不要读标题、时码；段落间自然停顿即可。安静环境正常语速，约每分钟 125–145 个英文词。无需自己切成十四段，也无需对齐当前 AI 的秒数。WAV、M4A、MP3 均可。把完整录音发给我，我就能替换。

在本项目根目录运行一个命令也可以完成替换：

```powershell
pitch/.venv-v3/Scripts/python.exe pitch/v4/replace_voice.py "C:/Recordings/my-pitch.m4a"
```

程序在本机识别、按稿对齐、切段，更新镜头时长、动作提示、字幕和音频，再导出三个 V4 文件并运行技术检查。背景音乐会按新旁白重新压低；不会再次调用 AI 配音。原 AI 分段会备份到 `pitch/v4/cache/voice-before-replacement/`。首次替换需要联网下载本地识别模型，此后不需要账号或云端转写服务。若台词匹配不足、段落边界不可靠或成片超出 3–5 分钟，会在覆盖旁白前停止并留下诊断文件。替换会覆盖当前 V4 导出文件；如想保留旧成片，请先另存。

只检查录音、不改旁白或成片：

```powershell
pitch/.venv-v3/Scripts/python.exe pitch/v4/replace_voice.py "C:/Recordings/my-pitch.m4a" --check-only
```

当前已用整段 AI 旁白作为替身完成对齐演练：95.3% 的稿件词被匹配，十四段截取互不重叠。尚未收到真人录音；这不是对实际真人录音或完整替换导出的验收。真人替换后仍应回看成片确认重音、发音与动作配合。

## 编辑和重建

依赖：Python 3.10+、Node 20+、FFmpeg/ffprobe、Chrome；重新采集另需 Godot。仓库内已有虚拟环境可直接使用。新环境安装 `pip install -r pitch/v4/requirements.txt`，在 `pitch/editor` 内运行 `npm install`，并确保 FFmpeg 在 PATH。视频和音频由 Git LFS 管理，拉取后应运行 `git lfs pull`。

```powershell
# 从仓库根目录执行；现有声音不会被重新合成
pitch/.venv-v3/Scripts/python.exe pitch/v4/build.py
pitch/.venv-v3/Scripts/python.exe pitch/v4/mix_audio.py
pitch/.venv-v3/Scripts/python.exe pitch/v4/render.py final --force
pitch/.venv-v3/Scripts/python.exe pitch/v4/qa.py
```

只有明确要重新生成临时 AI 配音时才运行 `voice.py`。临时声音为 Edge TTS `en-US-AnaNeural`，语速 +2%、音高 +1Hz。四条从零开始、全片等长的 48kHz 立体声 WAV 位于 `pitch/editor/public/v4/audio/`：`Narration`、`Music`、`SFX`、`Music_Effects`。外部剪辑软件中可以用新的 `Narration` 替换整轨；时长变化时应使用上面的自动重建流程。

Remotion 预览：在 `pitch/editor` 中运行 `npm run dev:v4`。`timeline.json` 是镜头、字幕与声音的共同时间依据，`build.py` 从稿件和词级时间生成它。交付导出由 Remotion 生成字卡，再由 FFmpeg 拼合真实游戏画面、烧录字幕和混音，避免逐帧浏览器导出过慢。改过字卡、字体或时间线后使用 `--force`，以更新图形与打包缓存。Remotion 与 FFmpeg 的文字栅格化可能有细微差别。

工作台通过 `editor/src/workbench.ts` 导入同一份时间线，提供镜头、字幕、旁白、音效、音乐轨。工作台的像素对照仅验证拆解导入与 Remotion 原合成一致；最终 MP4 另由技术自检检查。

## 素材与自检边界

所有游戏片段来自 **c51cacc 的真实 Godot 场景和物理运行**，由 `capture_*.gd` 及 `record.ps1` 可复现。胶墙、弹反、上抛、吹风机、水中合作、换发型来自实际机制操作。Boss 的站位、无敌保护和飞来剪刀经过演示调度；阶段二片段设置生命值以触发真实阶段效果。这些是机制演示，不是未经辅助的真人通关。采集使用独立进度文件，不覆盖玩家正常存档。

游戏源画面完整从 1280×720 缩放到 1440×810，放在 x240/y150；不裁切、不放大取景、不使用圆角遮罩。标签在上、字幕在下，均避开游戏 HUD。自检比较每个片段编码后的四角与按同一算法缩放的原始素材，并抽取每段进场／中间／停留画面。另检查全片解码、帧数、二维码、主版与无 BGM 版画面一致、旁白时间、全片音乐覆盖与响度。独立终检复查语义与画面的对应关系。甜美／舒适的听感仍需真人试听判断，报告没有把数值检测当作主观试听。

字幕采用 56px 字号，编码后采样字形约 47px 高，保留在游戏画面外的 76px 字幕条内。这是为了完整保留游戏 HUD 的紧凑排版选择，低于 skill 的 56px 实际字形高度建议，不宣称该项完全符合。工作台在第 400、2000、4800、7800 帧与 Remotion 原合成对照，超出每通道 2 级容差的差异像素均为 0%；最终 FFmpeg 编码另按上述检查验收。

4 章、12 个房间、3 个 Boss 阶段来自当前代码；20 对玩家测试、12 周、17,200 美元均为**拟议计划／估算**，画面已作标注，没有声称已获得资金或已有测试结果。

背景音乐复用游戏内 `assets/audio/music/calm.wav`，Boss 段轻叠 `boss.wav`；使用逐采样循环并在旁白下压低，录屏原声仅保留真实音效。复用现有游戏插画、字体、角色和 UI，不重新设计游戏外观。

使用 [video-shotcraft](https://github.com/Vincentwei1021/video-shotcraft) 的自主创作与独立审查流程；片尾采用 `marker-underline-title` 的**下划线片段适配**，保留固定随机种子与第 32–42 帧绘制，不宣称复现完整标题落地镜头。代码沿用 V3 已保存的 [Apache 许可证](../v3/LICENSE-shotcraft.txt) 和 [来源说明](../v3/NOTICE-shotcraft.txt)。叙事亦参考用户提供的 [How to Pitch Games](https://youtu.be/t5MZhwGgXbk)，相关外部论据与方法查证见 V3 归档文档。
