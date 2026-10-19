"""v3's editable narration and production brief. Run before voice.py/build.py."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
VOICES = {"A": "en-US-BrianMultilingualNeural", "B": "en-US-EmmaMultilingualNeural"}


def line(speaker, text, at=None):
    return {"speaker": speaker, "text": text, **({"at": at} if at is not None else {})}


SCENES = [
    dict(id="hook", title="Throw me!", minimum=15, lead=0, kind="hook", lines=[
        line("A", "Ready?", .4), line("B", "Throw me!", 1.5),
        line("A", "Oh No My Hair. A two-player puzzle platformer where your haircut is your way out.", 7),
    ]),
    dict(id="story", title="One snip too many", minimum=12, lead=.5, kind="story", lines=[
        line("B", "Two friends visit a salon. The robot assistant cuts too much, their hair gets powers, and the front door locks. Now they have to escape together."),
    ]),
    dict(id="roles", title="Two haircuts. Two jobs.", minimum=17, lead=.5, kind="roles", lines=[
        line("A", "Twin-Tails can glide and carry her friend across gaps."),
        line("B", "Pompadour can dash through hair gel, parry scissors, and launch her from his head. Put those abilities together, and you can reach places neither friend could reach alone."),
    ]),
    dict(id="sling", title="The sling", minimum=28, lead=.5, kind="sling", lines=[
        line("A", "Here's the problem: this gel curtain grows back. Carrying your friend gets you to the wall, but you still can't get through."),
        line("B", "So she carries him over the gap. He dashes out of her grip and breaks the gel. She follows before it closes. Watch their timing."),
    ]),
    dict(id="parry", title="Return to sender", minimum=27, lead=.5, kind="parry", lines=[
        line("B", "This time, the door needs a bell that's out of reach. A parry sends a scissor back horizontally. That won't ring it."),
        line("A", "Twin-Tails catches the blue scissor, then tosses it straight up. The enemy's attack becomes the tool that opens your route. Both players have a job in that chain."),
    ]),
    dict(id="salon", title="Wash. Dry. Try again.", minimum=20, lead=.5, kind="salon", lines=[
        line("A", "The salon changes how your hair works. Get soaked and Twin-Tails can't glide. Pompadour can't break gel."),
        line("B", "Warm air dries you off and lifts Twin-Tails. Carry your friend into it, and you rise together. Now you have to choose when to cross the showers."),
    ]),
    dict(id="swap", title="Your haircut. My controls.", minimum=10, lead=.5, kind="swap", lines=[
        line("B", "Then a barber's chair swaps your haircuts. The powers go with the hair, so the person who was carrying now needs a lift. You have to switch jobs."),
    ]),
    dict(id="boss", title="The assistant is waiting", minimum=14, lead=.5, kind="boss", lines=[
        line("A", "The escape ends at the robot assistant. It charges, throws scissors, and brings in backup."),
        line("B", "Stun it, launch your friend, and land on its head. The moves you've learned become your way through the final fight."),
    ]),
    dict(id="audience", title="A game for the person next to you", minimum=16, lead=.5, kind="audience", lines=[
        line("B", "We're making this for two people who enjoy solving something together, sharing one keyboard. The prototype runs in a browser."),
        line("A", "PICO PARK and ibb and obb are useful reference points. Our focus is these hair-powered combinations, inside one mischievous salon."),
    ]),
    dict(id="proof", title="You can play it today", minimum=16, lead=.5, kind="proof", lines=[
        line("A", "The playable prototype has four chapters, twelve rooms, saved progress, and a three-phase boss."),
        line("B", "It starts with learning each haircut, then asks you to combine them under new conditions. Every exit needs both friends. You can try the full prototype on itch dot io."),
    ]),
    dict(id="team", title="Made by NPC Union", minimum=13, lead=.5, kind="team", lines=[
        line("B", "We're NPC Union: ChenHongshan333 and ZSYUYIIE. This started in a forty-eight-hour jam with the theme Better Together."),
        line("A", "We've kept iterating on the escape, the rooms, and how the two players help each other."),
    ]),
    dict(id="plan", title="Next: watch real pairs play", minimum=24, lead=.5, kind="plan", lines=[
        line("A", "Next, we want twenty pairs to play without us explaining the puzzles. Can they learn the first combo? Where do they keep failing? Do they choose another room?"),
        line("B", "Our proposed twelve-week plan starts with those tests and clearer tutorials, then room and audio polish, followed by accessibility, bug fixes, and release preparation. Those player results are still ahead of us."),
    ]),
    dict(id="budget", title="A focused production plan", minimum=18, lead=.5, kind="budget", lines=[
        line("A", "We estimate seventeen thousand two hundred US dollars for that twelve-week production plan. It covers our time, commissioned art and audio, launch costs, and a twenty-percent buffer."),
        line("B", "The immediate help we're looking for is playtesters and mentoring on onboarding and release planning."),
    ]),
    dict(id="end", title="Bring a friend.", minimum=14, lead=.6, kind="end", lines=[
        line("B", "Grab the person next to you and try the prototype. We'd love to see how you solve it together."),
        line("A", "Scan the code to play Oh No My Hair. Thanks for watching."),
    ]),
]

BRIEF = {
    "version": "v3", "mode": "autonomous-original",
    "authorization": "User asked to execute the preceding proposal, create a complete video and a new branch; no intermediate approval is needed.",
    "audience": "Game pitch jury / mentors; no formal scoring rubric supplied.",
    "format": {"width": 1920, "height": 1080, "fps": 30, "duration_seconds": [180, 300], "speech": "English, two temporary AI voices", "captions": "English burned-in and SRT"},
    "hook": "Hair-powered physical cooperation: carry, sling through gel, relay an enemy scissor into a bell.",
    "primary_ask": "Play the prototype; recruit the next cohort of 20 pairs and seek mentoring.",
    "truth_rules": ["No invented player results, traction, awards, member responsibilities or funding commitments.", "12 weeks and USD 17,200 are a proposed production plan, not a launch promise or funding already secured.", "Capture uses the real Godot renderer, physics, inputs and game audio. Any staged boss setup is documented as a mechanic demonstration.", "Hair swap changes the existing two friends' abilities, not the playable roster.", "Use an isolated capture save, never the user's normal progress."],
    "visual_tokens": {"ink": "#30203f", "cream": "#fff5df", "pink": "#f65a9d", "blue": "#74c7e5", "gold": "#ffdd47", "lilac": "#e8d9ef", "heading_font": "Fredoka", "body_font": "Nunito", "caption_px": 56, "safe_margin_px": 80},
    "direction": "Hand-drawn salon comedy; clean full-frame gameplay; pink and blue role markers; restrained ink titles and elastic punctuation. A continuous action takes priority over decorative motion.",
    "requirement_decisions": [
        {"requirement":"A complete 3-5 minute game pitch","decision":"14 sections; gameplay hook, cooperation proof, audience, current build, team, proposed plan/budget, playable CTA","evidence":"storyboard.txt; timeline.json"},
        {"requirement":"Show why two people are needed","decision":"Show carry alone failing, then the complete sling; show horizontal parry contrasted with an upward relay","evidence":"Scenes.tsx sling/parry; public/v3/failure.mp4, sling.mp4, parry.mp4"},
        {"requirement":"Replace temporary AI narration later","decision":"Keep full voice and music/effects stems, clean picture, per-line audio and editable SRT","evidence":"README.txt; voice.py; props-clean.json; props-voiceonly.json"},
        {"requirement":"Version and branch isolation","decision":"Use feat/pitch-v3 and a separate v3 Remotion entry without changing the v2 composition","evidence":"editor/src/v3/Root.tsx"},
    ],
    "feature_shots": {"core_cooperation":["hook","sling","parry"],"role_identity":["roles","swap"],"salon_rules":["salon"],"combat_payoff":["boss"],"existing_build":["proof"],"audience_and_next_step":["audience","team","plan","budget","end"]},
    "gallery_adaptation": {"card":"marker-underline-title","style_key":"marker-underline-title","source":"demos/typography/marker-underline-title/MarkerUnderlineTitle.tsx","commit":"43bd349a136651865ecfa6ea1cf012f6e957d304","local_implementation":"editor/src/v3/Marker.tsx","used_in":"end","preserved":"seeded dry-brush geometry; stroke f32-42; resting hold","adapted":"game palette, width and caption-safe placement","other_shots":"custom editorial gameplay, not claimed as Gallery copies"},
    "shotcraft_adaptations": ["Use the product-derived palette, preproduction specification, feature-to-shot mapping, hold/rest time, frame-pinned SFX, deterministic motion, two audio versions and independent final review.", "Game-specific exceptions to product-advert rules S1/Q8: retain actual game audio and characterful game music; no tech-house requirement, metallic UI orbit or launch-event particle finale.", "Gameplay camera treatments are custom editorial shots: source-frame spatial continuity and readable targets take priority over a template's camera movement."],
    "references": [
        "https://github.com/Vincentwei1021/video-shotcraft",
        "https://github.com/remotion-dev/skills",
        "https://github.com/blader/humanizer",
        "https://www.youtube.com/watch?v=t5MZhwGgXbk",
        "https://www.tinybuild.com/single-post/how-to-pitch-games-in-2024",
        ".agents/skills/game-feel/SKILL.md", ".agents/skills/audio-design/SKILL.md", ".agents/skills/game-ui-ux/SKILL.md",
    ],
    "reference_video_method": "Video identity and chapters checked; author's official companion article supplies the verified recommendations: snappy gameplay walkthrough, clear audience path, concise budget. No claim to have transcribed the full talk.",
}


def main():
    ROOT.mkdir(exist_ok=True)
    (ROOT / "script.json").write_text(json.dumps(SCENES, ensure_ascii=False, indent=2), encoding="utf-8")
    (ROOT / "production_brief.json").write_text(json.dumps(BRIEF, ensure_ascii=False, indent=2), encoding="utf-8")
    script = "OH NO MY HAIR / PITCH v3\nTemporary AI voices. A = Brian; B = Emma.\n\n"
    for s in SCENES:
        script += f"{s['id'].upper()} / {s['title']}\n" + "\n".join(f"{l['speaker']}: {l['text']}" for l in s["lines"]) + "\n\n"
    (ROOT / "read_aloud.txt").write_text(script, encoding="utf-8")
    print(len(SCENES), "sections;", sum(len(l["text"].split()) for s in SCENES for l in s["lines"]), "spoken words")


if __name__ == "__main__":
    main()
