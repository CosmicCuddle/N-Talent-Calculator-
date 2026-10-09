# N Talent Calculator

An experimental **WoW 3.3.5a talent calculator for the Naxxramas AzerothCore server**, with individual-progression-specific talent rows, the server's custom Talent/Spell DBC snapshot, and website-compatible `NT1` talent build codes.

**Status: work in progress — client-testing alpha.** This is the standalone canonical source repository. The [N Addon Collection](https://github.com/CosmicCuddle/N-Addon-Collection) will import an approved, pinned snapshot of this repository, rather than maintain a second copy.

## What it does

- Shows three talent trees, talent icons, current/next rank spell descriptions and a planner point budget.
- **Greys out and fades unavailable talents** until enough earlier-row points or prerequisite talent ranks have been invested. Hover for the exact requirement; already-selected talents remain vibrant.
- Displays authentic **Blizzard 3.3.5a specialization artwork** for all 30 trees using textures already in the WoW client, rendered in front of the dark panel backdrop so the artwork is actually visible while talent icons stay in the foreground.
- Uses precisely fitted talent icon frames with a 2px border; **Escape** closes the planner, including when the share-code text field has focus.
- Reads **Individual Progression tiers** using the existing server read-only `.ipsvc data` protocol (`##IPSVC##PD~<tier>`), with completed milestone quests as a fallback.
- Restricts Vanilla tiers 0–7 to rows 1–6 plus a single capstone in row 7; TBC tiers 8–12 to rows 1–8 plus a single capstone in row 9; WotLK tiers 13+ to all 11 rows.
- Preserves off-centre server capstones: Stormstrike (901), Dark Pact (1022), Divine Illumination (1747).
- Exports and imports **NT1 codes** compatible with the [website calculator](https://github.com/CosmicCuddle/Naxxramas-Resource-Hub/tree/main/talents).
- Saves named builds using the addon's own `NTalentCalculatorDB` SavedVariables.

**Planning only:** This addon does not spend, unlearn, or change your character's actual talents. It does not change server settings or DBC files.

## In-game commands

| Command | Action |
| --- | --- |
| `/ntalent` or `/ntc` | Open or close calculator |
| `/ntalent refresh` | Request current Individual Progression tier |
| `/ntalent code` | Select a compatible NT1 build code for Ctrl+C |
| `/ntalent import NT1:...` | Import a build from the website or another player |
| `/ntalent save NAME` | Save current planned build |
| `/ntalent load NAME` | Restore a saved planned build |

## Installing the test build

1. Back up your existing `Interface/AddOns/NTalentCalculator/` folder if it exists and the corresponding account `WTF/.../SavedVariables/NTalentCalculator.lua` file.
2. Open the newest successful **Validate and package Talent Calculator** GitHub Actions run for this branch/PR.
3. Download the `n-talent-calculator-test` artifact, then open the inner `N-Talent-Calculator-v0.1.0-alpha.4.zip` inside it.
4. Extract the **one** `NTalentCalculator` folder directly into `World of Warcraft/Interface/AddOns/`.
5. Start WoW 3.3.5a; enable `N Talent Calculator` in the AddOns screen, and type `/ntalent`.

`NCore` is an optional dependency in the standalone addon. When installed through N Addon Suite, the collection adds a *required* `NCore` dependency to its packaged copy so the central suite manager can control it. The original addon remains installable independently.

**Do not install two `NTalentCalculator` folders from different packages.** If updating, replace the existing addon directory; leave your character's SavedVariables intact.

## Data integrity and releases

The source of truth is a **pinned October 2026 website calculator snapshot** generated from the user's customised `Talent.dbc`, `TalentTab.dbc`, `Spell.dbc`, and `SpellIcon.dbc`. It contains 830 talents in 30 trees for 10 classes, including custom Rend Flurry Talent ID 3000.

Files `config/talent-data.json` and `scripts/build_talent_data.py` pin and verify the website commit and exact Git object hashes. GitHub Actions generates `NTalentCalculator/Data.lua` and includes it in a complete installable ZIP. GitHub's automatic repository source ZIP is **not an installable addon**, because generated `Data.lua` is intentionally omitted from source control.

Run the same build locally from checkouts of the pinned website repository and this repository:

```bash
python3 scripts/build_talent_data.py --source /path/to/Naxxramas-Resource-Hub --output NTalentCalculator/Data.lua
python3 scripts/build_addon.py --output-dir dist
```

Offline tests cover data origin, Lua 5.1 syntax, Vanilla/TBC/WotLK visibility, capstones, prerequisites, IP response parsing, original website share codes and a simulated 3-tree UI. These do not replace tests on a real WoW 3.3.5a client.

## Development and rollback

Work on development branches and review pull requests before publishing releases. The current N Addon Collection v1.0.0 remains intact. To roll back this addon, close WoW, restore your backed-up `NTalentCalculator` folder and optionally saved builds if needed.

**Known remaining work:** Verify the corrected visible client-native backgrounds across all 30 specializations and UI scales; validate complex cross-platform NT1 codes, IP tier transitions, precise rank effects, saved builds and optional module enable/disable after Reload UI.

See [the collection integration PR](https://github.com/CosmicCuddle/N-Addon-Collection/pull/5) for experimental v2 suite integration.
