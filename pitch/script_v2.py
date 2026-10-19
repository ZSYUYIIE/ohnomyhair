"""v2 pitch content: the two-voice script (docs/Oh_No_My_Hair_Pitch_Script_v2.txt)
as scene data for the Remotion project. A = guy voice, B = girl voice.
Run: python -I script_v2.py  ->  writes script_v2.json next to this file.
"""
import json
from pathlib import Path

A, B = "A", "B"
VOICES = {A: "en-US-BrianMultilingualNeural", B: "en-US-EmmaMultilingualNeural"}

SCENES = [
    dict(id="hook", kind="hero", title="Bad hair. Good friends.", eyebrow="OH NO MY HAIR · A CO-OP PUZZLE PLATFORMER", lines=[
        (A, "Hi, we're NPC Union. I'm ZSYUYIIE."),
        (B, "And I'm ChenHongshan333. We made this game in a forty-eight hour game jam, where the theme was Better Together."),
        (A, "It's called Oh No My Hair. It's a puzzle platformer for two people sharing one keyboard, and neither of you can finish it alone."),
    ]),
    dict(id="story", kind="story", title="One snip too many", eyebrow="THE STORY", lines=[
        (B, "Two friends get to a salon right before closing, and the barber leaves his robot assistant in charge."),
        (A, "The robot cuts way too much. Their hair gets powers, the robot locks the front door, and the two of them have to find another way out."),
    ]),
    dict(id="twins", kind="game", clip="carry_launch", title="Twin-Tails glides and carries", eyebrow="PLAYER ONE", lines=[
        (A, "Player one is Twin-Tails. She can glide and pull levers, and she can pick her friend up and fly with him."),
    ]),
    dict(id="pomp", kind="game", clip="fresh_cut", title="Pompadour dashes and parries", eyebrow="PLAYER TWO", lines=[
        (B, "Player two is Pompadour. He dashes through hair gel, knocks flying scissors back, and can launch his friend off the top of his head."),
        (A, "Every room is built around something one of them can't do on their own."),
    ]),
    dict(id="sling", kind="game", clip="sling_gel", title="The sling", eyebrow="OUR FAVOURITE MOVE", lines=[
        (A, "This is our favourite move. Twin-Tails carries Pompadour over a pit, and he throws himself out of her grip. He smashes through a wall of gel that grows back, and she has to glide through the hole before it closes."),
    ]),
    dict(id="parry", kind="game", clip="parry_catch", title="Return to sender", eyebrow="CATCH AND THROW", lines=[
        (B, "The enemy's scissors end up helping you. Pompadour knocks one back, and Twin-Tails catches it in her pigtails and throws it straight up into a service bell. Ring the bell, and the next door opens."),
    ]),
    dict(id="water", kind="game", clip="water", title="Wash and blow-dry", eyebrow="SALON HAZARDS", lines=[
        (A, "The salon gets in your way too. Wet hair from the shampoo showers stops working, so Twin-Tails can't glide, and Pompadour bounces off the gel."),
        (B, "A hair dryer fixes that, and its hot air lifts you up."),
    ]),
    dict(id="boss", kind="game", clip="boss", title="The assistant", eyebrow="THE FINAL FIGHT", lines=[
        (B, "At the end, you fight the assistant itself. It throws scissors, charges across the room, and calls in backup robots."),
        (A, "You stun it with its own scissors, or by tricking it into a wall, then one of you lands on its head. Get hit, and it can swap your haircuts, so suddenly you have each other's powers."),
    ]),
    dict(id="theme", kind="duo", title="Talk to each other", eyebrow="WHY IT'S CO-OP", lines=[
        (A, "Both players have to matter in every room, so you end up shouting carry me, and wait for the water, at the person next to you. That's our favourite part."),
    ]),
    dict(id="audience", kind="audience", title="Who it's for", eyebrow="PLAYERS", lines=[
        (B, "It's for friends, siblings and couples who like puzzles. You only need one keyboard and a browser."),
    ]),
    dict(id="market", kind="market", title="Games like it", eyebrow="SIMILAR GAMES", lines=[
        (A, "There are already good co-op puzzle games. Pico Park 2 is built for groups of two to eight, and ibb and obb is a two-player game about gravity."),
        (B, "Ours is smaller, and each of you has a power the other one doesn't. We still have to find out whether people want that."),
    ]),
    dict(id="prototype", kind="prototype", title="Playable now", eyebrow="WHAT EXISTS TODAY", lines=[
        (B, "The prototype is finished and playable on itch dot io. Four chapters, twelve rooms, and a boss with three phases, with saved progress."),
    ]),
    # Budget scenes: filled from the global USD research (docs/Oh No My Hair global USD budget.md).
    dict(id="budget", kind="budget", title="What it costs", eyebrow="12 WEEKS · USD", lines=[]),
    dict(id="costs", kind="costs", title="If we raise nothing", eyebrow="THE FALLBACK", lines=[]),
    dict(id="roadmap", kind="roadmap", title="Twelve weeks", eyebrow="THE PLAN", lines=[
        (B, "Weeks one to four are playtests and fixing the tutorial. Weeks five to eight are polish, and the Steam page goes up by week eight. Weeks nine to twelve are accessibility, bug fixes, and the release."),
    ]),
    dict(id="validation", kind="validation", title="How we'll know it works", eyebrow="NEXT PLAYTEST", lines=[
        (A, "Next, we want to watch twenty pairs play. We'll check whether they finish the tutorial without help, where they get stuck, and whether they want one more room."),
        (B, "The game already logs where players die, and bots that play with human-sized mistakes flag rooms that need perfect timing. We haven't tested with outside players yet, so those are goals for now."),
    ]),
    dict(id="team", kind="team", title="NPC UNION", eyebrow="WHO WE ARE", lines=[
        (B, "That's us, NPC Union. We're looking for playtesters, feedback, and mentoring to get this finished."),
    ]),
    dict(id="end", kind="end", title="Bring a friend.", eyebrow="THANKS FOR WATCHING", lines=[
        (A, "Scan the code, grab a friend, and give it a go."),
        (B, "Thanks for watching!"),
    ]),
]

BUDGET_FILE = Path(__file__).with_name("budget_lines.json")


def main():
    scenes = []
    budget = json.loads(BUDGET_FILE.read_text(encoding="utf-8")) if BUDGET_FILE.exists() else {}
    for s in SCENES:
        s = dict(s)
        if s["id"] in budget:
            s["lines"] = [tuple(x) for x in budget[s["id"]]]
        s["lines"] = [{"speaker": sp, "voice": VOICES[sp], "text": t} for sp, t in s["lines"]]
        s["text"] = " ".join(l["text"] for l in s["lines"])
        scenes.append(s)
    out = Path(__file__).with_name("script_v2.json")
    out.write_text(json.dumps(scenes, indent=2, ensure_ascii=False), encoding="utf-8")
    words = sum(len(s["text"].split()) for s in scenes)
    print(f"{len(scenes)} scenes, {words} words -> {out.name}")


if __name__ == "__main__":
    main()
