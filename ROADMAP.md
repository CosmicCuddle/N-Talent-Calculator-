# N Talent Calculator — Maintainer Roadmap

**Repository:** https://github.com/CosmicCuddle/N-Talent-Calculator-  
**Primary branch:** main  
**Client:** World of Warcraft 3.3.5a, build 12340, Lua 5.1  
**Maintained separately from:** https://github.com/CosmicCuddle/N-Addon-Collection  
**Roadmap updated:** 10 October 2026  
**Current main-branch version:** 0.1.0-alpha.11 — Saved Builds and Sharing implementation merged; awaiting real-client verification  
**Release status:** standalone alpha; do not describe as production-ready  
**Last confirmed in-game correction:** 0.1.0-alpha.10 — Vanilla Dual Wield and Contagion

This is the working record for ongoing maintenance. Read **Current status**, **Next task**, **Known limitations**, and **Working on the project** before changing code. Update it with *every* implementation or behavior change, including bug fixes, data updates and UI adjustments. Write what actually happened; do not mark an item complete because a test is planned or a PR is open.

## Current status and boundaries

The calculator is a stand-alone WoW addon in the NTalentCalculator installation folder. It is a **planner**, not a replacement for the game's talent frame: clicks never train, unlearn or spend real character talent points. The source repository also contains the build scripts and tests. The generated DBC data is **not** committed; it is generated during GitHub Actions builds and packaged in the installable ZIP.

The public **N Addon Collection v2.0.0 does not contain this addon**. It must stay that way unless a later release is explicitly approved. The collection development integration was explored in N-Addon-Collection PR #5; do **not** merge that old stacked PR directly into current main without rebasing and reviewing its outdated assumptions. The original source of truth for talent code is this repository.

The most recent player check confirms the Vanilla capstone corrections in alpha.10. Earlier player screenshots established that the basic trees, tier display, icon selection and settings worked, but some background and prerequisite-arrow refinements went through multiple iterations. Automated rendering mocks are not equivalent to screenshots from the actual WoW client. Treat unfinished visual verification as open.

## Architecture and exact files

| Path | Responsibility | Safeguard |
| --- | --- | --- |
| NTalentCalculator/NTalentCalculator.toc | 3.3.5a interface, addon version, optional NCore dependency, SavedVariables and Lua load order | Keep Interface 30300 and folder name stable |
| NTalentCalculator/Engine.lua | talent availability, prerequisite ranks, point budget, character era, class choice, NT1 encoding/decoding, named build persistence | No real character talent mutation; validate every imported build |
| NTalentCalculator/Progression.lua | reads the existing server read-only Individual Progression response, with quest milestone fallback | Never infer an era purely from character level |
| NTalentCalculator/UI.lua | draggable three-tree window, class/tier header, icons, backgrounds, prerequisite lines, counters, Saved Builds and share code controls | Preserve ESC behavior, readable scale, Lua 5.1 compatibility |
| NTalentCalculator/Data.lua | generated server-specific 830-talent/30-tree/10-class dataset with spell icons and tooltips | Generated in CI; do not hand-edit or commit |
| config/talent-data.json | approved website revision and Git blob hashes for compressed talent and visual data | Deliberately update only after DBC review |
| scripts/build_talent_data.py | decode and verify the pinned website snapshot, then serialize safe Lua data | Fails on unexpected content, class totals or hashes |
| scripts/build_addon.py | build the install-ready NTalentCalculator directory ZIP | Test this ZIP, not GitHub's source-code ZIP |
| tests/test_talent_engine.lua | point and rank rules, NT1 round-trip, era restrictions | Includes real Vanilla capstone names |
| tests/test_real_capstones.lua | regression using generated DBC data, including actual talent IDs/columns | Must remain enabled in CI |
| tests/test_talent_progression.lua | tier parsing, hidden quest fallback | Test boundaries 7/8 and 12/13 |
| tests/test_talent_ui.lua | simulated 3.3.5a frame and input behavior | Cannot guarantee final live client appearance |
| .github/workflows/validate.yml | generate approved data, run tests and upload the installable test ZIP | Never publish a normal release just because CI succeeded |

### Exact era rules — preserve these

| Progression | Server tier | Maximum player level | Planner points | Visible talent positions |
| --- | --- | --- | --- | --- |
| Vanilla | 0–7 | 60 | 51 | all of rows 1–6; only the central capstone in row 7 |
| The Burning Crusade | 8–12 | 70 | 61 | all of rows 1–8; only the approved capstone in row 9 |
| Wrath of the Lich King | 13+ | 80 | 71 | all 11 rows |

Era selection uses the existing read-only .ipsvc data request and the ##IPSVC##PD~tier response. Completed milestone flags beginning at 66008 (TBC) and 66013 (Wrath) provide an era-only fallback. The interface must not pretend to know an exact tier when it only knows the quest-era result.

**Verified custom Vanilla DBC exceptions, corrected in alpha.10:** Shaman Enhancement row 7 centre is Dual Wield, Talent ID 1690, and Warlock Affliction row 7 centre is Contagion, Talent ID 1669. Stormstrike (901) and Dark Pact (1022) are off-centre talents on the same row, hidden until TBC. Retain the actual TBC Paladin Holy off-centre case, Divine Illumination (1747). The current website calculator has already corrected these rules.

### Website interoperability

The Resource Hub calculator repository is https://github.com/CosmicCuddle/Naxxramas-Resource-Hub/tree/main/talents. The addon uses its custom DBC-derived dataset, pinned to website commit e2e861d05c4f3d13f850886c973cb66bc60cc849. The pinned blobs and hashes are written in config/talent-data.json.

NT1 codes are the common format. A code contains the era, class, and sorted base-36 talent-ID/rank pairs, for example NT1:vanilla:warrior:2t-1. Preserve the format on import and export. Invalid or later-era builds must be refused without altering the current plan. Older malformed Vanilla codes with Stormstrike/Dark Pact are *not* automatically remapped. WoW 3.3.5a has no reliable clipboard-write API, so the button **selects** an edit-box string for Ctrl+C rather than claiming to copy it automatically.

## Completed work — history worth keeping

| Phase | Result | Verification status |
| --- | --- | --- |
| 0.1.0-alpha.1 | independent repo, ten classes, IP era detection, three trees, NT1 sharing, rank validation, SavedVariables groundwork | CI passed; initial in-game UI screenshots obtained |
| alpha.2 | dim/greyscale unavailable talent icons and explain locked requirements | CI passed; appearance reviewed |
| alpha.3–alpha.6 | class-specific artwork attempts, fitted borders, ESC key, streamlined spacing and three-part progression header | iterative screenshot review; alpha.6 header approved |
| alpha.7–alpha.8 | revised art placement and DBC prerequisite connectors, corrected after screenshots showed patchy backgrounds and unclear arrows | CI passed; final visual verification on alpha.8+ still needed |
| alpha.9 | remove opaque black backing behind rank numbers | CI passed; visual result pending/ongoing |
| alpha.10 | correct Vanilla Enhancement Dual Wield and Affliction Contagion | **confirmed fixed by player** |
| alpha.11 | in-window Saved Builds and Sharing, alphabetical name selection, two-click confirmation for overwrite/delete | [PR #11](https://github.com/CosmicCuddle/N-Talent-Calculator-/pull/11) merged as e96db7754f8d8fff777e3da37a8e9a6340e8c942; [main CI passed](https://github.com/CosmicCuddle/N-Talent-Calculator-/actions/runs/38062985487); **not yet player-approved** |

Use a separate release note or Git commit for each meaningful version. Do not treat the alpha versions as stable releases.

## Awaiting client acceptance — alpha.11 Saved Builds and Sharing

**Goal:** make the previously hidden Save and Load commands accessible in the talent window without losing website NT1 compatibility.

**Implementation:** maintain the existing named-build data in account SavedVariables (NTalentCalculatorDB.builds). Add a saved-name input, previous/next name selection, Save, Load and Delete buttons. Keep the existing editable NT1 share-code field with Show code/Import/Reset actions. Add a visible status message, and require a second press before replacing a different existing code or deleting a saved build.

**Acceptance tests:**

- [x] Existing exported codes and SavedVariables format remain unchanged.
- [x] ListBuildNames returns names in a predictable, case-insensitive order; deleting one entry doesn't change other entries.
- [x] Buttons are implemented for entering and choosing saved names, Save, Load and two-step Delete/Replace.
- [x] Automated Lua 5.1 UI tests pass for no overwrites on first click, deletion confirmation, alphabetical selection, and restored build points. Verified by [Actions run 38062796981](https://github.com/CosmicCuddle/N-Talent-Calculator-/actions/runs/38062796981).
- [x] Main-branch GitHub Actions run [38062985487](https://github.com/CosmicCuddle/N-Talent-Calculator-/actions/runs/38062985487) passed and uploaded n-talent-calculator-test containing version 0.1.0-alpha.11.
- [ ] In WoW, at Vanilla tier and across common UI scales, the new footer controls do not overlap talent rows or each other.
- [ ] Saved builds survive /reload and a full game restart; names and NT1 codes remain intact.
- [ ] A saved TBC/WotLK build cannot bypass a Vanilla character's current era. An invalid or incompatible load leaves the current plan untouched.
- [ ] Ctrl+C from the share-code box imports successfully on the current website and the inverse direction works.
- [ ] ESC closes the window even when either edit field has focus; /ntalent remains usable after reopening.
- [ ] Verify that an empty name, missing build, duplicate name, and confirmed Delete produce understandable feedback.

**Next immediate task:** install the alpha.11 GitHub Actions test ZIP on the user's WoW 3.3.5a client and inspect the new saved-build footer at Vanilla tier. Enter two names, Save each, use the arrows, Load after Reset, confirm Delete and Save overwrite, and check /reload and Ctrl+C import/export. Record screenshots and any Lua errors before calling the UI finished.

**Exit criteria:** screenshot of the footer plus the saved/reloaded build test from the user. Only then mark alpha.11 visually verified. Do not publish a full stable calculator release purely on mocked UI tests.

## Next task — after alpha.11 is tested

**P1: make Saved Builds dependable across real sessions and eras.** Start by verifying the actual location of NTalentCalculator SavedVariables after a logout, including no shared-folder confusion with NCore. Exercise stored builds for each of the three eras; decide whether load should remain strict on the character's era (current behavior) or offer non-applying preview mode. Keep strict validation unless explicitly approved.

**P2: polish the sharing workflow.** Consider showing a clearly marked website-compatible NT1 code plus an optional website URL, but do not claim an automatic clipboard capability. Any website URL feature must match the Resource Hub's actual routing and encoding. Test long codes and text-field focus across screen sizes.

**P3: artwork and connector acceptance sweep.** Test at least Rogue, Warlock, Shaman, Paladin and a Wrath Death Knight; cover a row-7 Vanilla capstone, row-9 TBC capstone and all 11 Wrath rows. Recheck arrow routes after investing and removing prerequisite points, and ensure no arrows connect talents hidden by the current era.

**P4: version and release readiness.** Re-test all ten classes, compare complex NT1 builds with the website, review Lua error logs, confirm the standalone install ZIP has exactly one NTalentCalculator directory and contains generated Data.lua. Only then consider a separate addon prerelease. Collection inclusion is a separate product decision, not implied by a standalone release.

## Build, test and install procedure

1. Work in this source repository, on a new branch from main; do not edit the copied addon inside the collection or its GitHub Actions artifact.
2. Modify runtime files and relevant tests, then **update this ROADMAP.md in the same PR** with changed behavior, verification evidence, limitations, and the precise next task.
3. Let .github/workflows/validate.yml regenerate the pinned talent data. It runs Python/package checks and Lua 5.1 syntax, dataset, capstone, progression, engine and UI tests.
4. Download the **n-talent-calculator-test** artifact from a successful run and extract the *inner* N-Talent-Calculator-vX.Y.Z-alpha.N.zip. GitHub's automatic source ZIP lacks Data.lua and should not be used for installation.
5. **Close WoW completely** before replacing Interface/AddOns/NTalentCalculator. Back up the current folder and the corresponding WTF SavedVariables file first. Avoid having two NTalentCalculator folders.
6. Launch WoW 3.3.5a; type /ntalent. Check current tier, talent rows, spell names, click-to-plan, buttons, import/export and ESC.
7. Record the in-game result here. When satisfied, merge the tested PR, allow main's CI to pass, and record the exact commit/run/artifact as the baseline.

To build locally, obtain the exact website snapshot listed in config/talent-data.json and run:

    python3 scripts/build_talent_data.py --source /path/to/Naxxramas-Resource-Hub --output NTalentCalculator/Data.lua
    python3 scripts/build_addon.py --output-dir dist

Data.lua and the dist ZIP are generated products, not source files. Keep the approved source hash checks active.

## Risk register / unresolved issues

| Risk | Current handling | Next verification |
| --- | --- | --- |
| Custom DBC talent mismatch | Pinned source, real-data tests for 1690/1669, exceptions listed above | Recheck after any website DBC export update |
| Server IP response unavailable | Quest-era fallback only; planner otherwise waits | Test server request on characters with/without Companion |
| Previous-era build imported | Engine rejects incompatible NT1 codes | Test GUI load with saved later-era build |
| SavedVariables corruption or loss | No schema migration; backup before replacing addon | Test persistent named builds on restart |
| Accidental overwrite/delete | Two-step GUI confirmation | Test with identical and different codes |
| False in-game UI confidence | Lua mocked UI is not an actual client render | Require screenshots and small-screen testing |
| Copied sources in collection | Keep standalone as canonical | Don't merge old collection PR #5 blindly |
| WoW API limitations | Lua 5.1, game-native textures and clipboard selection | Do not use retail WoW APIs or newer Lua features |

## Recovery and rollback

- **Code change not merged:** close the PR or reset the development branch; main and the previously downloaded artifact stay available.
- **Code merged but bad:** revert the commit in GitHub or submit a corrective PR. Don't rewrite public release tags.
- **Addon client regression:** exit the game and restore the prior NTalentCalculator folder. Keep a backup of WTF SavedVariables; only restore them if needed, as replacing them can erase newer named builds.
- **Wrong data snapshot:** restore prior config/talent-data.json pin, rebuild via CI and run all real-DBC tests; do not patch generated Data.lua manually.
- **Incorrect talent plan after update:** reset or re-import only the planner code. The calculator should not have changed actual trained talents.

## Roadmap upkeep — required with each change

For every source PR, update:

1. **Current status:** version/branch and whether functionality was tested in the game or CI only.
2. **Completed work:** exact change and which behavior it replaces.
3. **In progress and Next task:** move the next unchecked action to the top; include acceptance checks and dependent files.
4. **Known limitations:** new compatibility or rollback caveats.
5. **References:** PR, commit, test workflow run and screenshot observations when available.

Keep entries short enough to scan but specific enough to reproduce. Use ordinary maintainer terminology, not a conversational recap. Do not mark a test as passed without recorded evidence. The README is a user guide; **this is the authoritative development handover**.
