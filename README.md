# Apocalypse (PS1) – German Uncut / TRUE NTSC 60 Hz v1.0 RC1

**Author / release name:** Bratwurstmensch  
**Base game:** *Apocalypse* (PlayStation, 1998)  
**Target localization:** German (SLES-00835)

This project restores the violence effects removed from the German PlayStation release while keeping the complete German localization. It also provides an optional **TRUE NTSC 60 Hz** build based on the original US gameplay/rendering/timing code.

## Two editions

### German Uncut PAL
Keeps the original German PAL code/timing and restores:
- red blood instead of the German blue-blood override,
- dismemberment/gore routines,
- missing blood/gore fountains in death animations,
- German text, menus, speech, movies and CD audio unchanged.

**Required:** original German `Apocalypse (Germany) (Track 1).bin` (SLES-00835).

### German Uncut TRUE NTSC 60 Hz
Uses the **original US SLUS-00373 gameplay/rendering/timing executable as the code base**, then applies the German localization and German disc data. This avoids the cropped PAL→NTSC hybrid viewport and matches the genuine US NTSC behavior much more closely.

This means **60 Hz, not 60 FPS**. The game's internal frame rate remains whatever the original NTSC game produces.

**Required:**
- original German Track 1 (SLES-00835),
- original US Track 1 (SLUS-00373),
- German Track 2 for the generated CUE (Track 2 is byte-identical between the verified German and US dumps).

The TRUE NTSC builder deliberately requires both original Track 1 images. The package does **not** contain the US executable or complete game assets.

## Verified source hashes (SHA-256)

| File | SHA-256 |
|---|---|
| German Track 1 | `296e3cb77af3c7a9e89d569097c5fb9c9e644898c670c0622e9bfe6ce0e1b304` |
| USA Track 1 | `3d0fdbd75ae2377fb12f7acbb9878932e9ff985724d5f15811b02c0f3a115fd4` |
| German/USA Track 2 | `cb68f944093d63a57ac2fbb356c14bd013ac02e5f7c00ddf0d32237165234b0f` |

Expected output hashes:

| Edition | SHA-256 |
|---|---|
| German Uncut PAL v1.0 | `031dab98cd43343a48e77068e368924101b00627bd49db775c3612abeec0c31f` |
| German Uncut TRUE NTSC 60Hz v1.0 | `89b8dabbd7d083d610c3904ffa0ea5d8beca8aae07542a1001f5663d649c1440` |

## Windows usage

### PAL
Put the patch package somewhere, then run:

`Build_German_Uncut_PAL_v1.0.cmd`

Enter the path to the original German Track 1 when prompted. If German Track 2 is beside it with the standard filename, the CUE is created automatically.

### TRUE NTSC 60 Hz
Run:

`Build_German_Uncut_TRUE_NTSC_60Hz_v1.0.cmd`

The Windows builder is dependency-free beyond Windows PowerShell and asks for the original German and US Track 1 files. It compiles a small transparent C# helper in memory only for PlayStation CD EDC/ECC regeneration. No third-party patch executable is bundled.

Cross-platform users can call the auditable Python 3 reference builder at `tools/build_apocalypse.py` directly.

## What was censored in the German build?
Reverse comparison of SLES-00835, SLES-00460 and SLUS-00373 identified multiple independent changes rather than one global censorship switch:
- gore/dismemberment routines were replaced or simplified,
- particle blocks used by some death animations were removed,
- the German executable contains an extra blood-color override that explicitly writes **RGB (0, 0, 128)**, producing blue blood.

The PAL patch restores the relevant effects while preserving the German PAL build. The TRUE NTSC edition instead keeps the genuine US code path and localizes it.

## RC1 test status
Confirmed in emulator testing so far:
- boot and intro movies,
- main menu,
- German menus/text/speech,
- correct NTSC viewport in the TRUE NTSC build,
- red blood,
- dismemberment,
- restored blood fountains,
- initial gameplay without the earlier test-build freezes.

A complete start-to-finish playthrough is still recommended before changing the release label from **RC1** to **Final**.


## AI development disclosure
This project was created through an **AI-assisted development workflow using ChatGPT**. The reverse-engineering analysis, binary comparisons, patch logic, builder code and most of the documentation were produced with AI assistance.

**Bratwurstmensch** initiated and directed the project, supplied the required original game dumps, made the project decisions, performed the hands-on emulator testing and reported the results that guided each revision. No claim is made that the technical reverse engineering or code was written manually from scratch by the release author.

This disclosure is intentional: the project is published as an openly AI-assisted fan patch, and the included builders/technical notes are provided so others can inspect, reproduce and audit the work.

## Distribution / legal note
This is a fan-made binary patch/builder. **No complete disc image is included.** Users must supply their own verified original game images. No ownership of *Apocalypse*, its characters, code, audio, graphics or trademarks is claimed. All original game rights remain with their respective owners.

## Credits
**Patch / release:** Bratwurstmensch  
Thanks to everyone who tests the patch and reports reproducible issues.
