# Changelog

## v1.0 RC1
- First public release candidate.
- German PAL uncensoring consolidated from the tested v0.4 binary state.
- TRUE NTSC build consolidated from the tested v0.9 binary state.
- TRUE NTSC public builder now requires original German + US Track 1 images instead of distributing a large donor-code delta.
- Added SHA-256 source/output verification.
- Added bilingual documentation and publication text.

## Development history
- v0.1: first restored gore routine; freeze on first hit.
- v0.2: fixed memory-arena collision; dismemberment worked.
- v0.3: restored missing death-animation particle/fountain blocks.
- v0.4: removed explicit German RGB (0,0,128) blue-blood override; working PAL Uncut baseline.
- v0.5–v0.6: experimental PAL→NTSC conversion; rejected due to incomplete viewport/timing parity.
- v0.7–v0.8: first true-US-code localization attempts; boot/frontend memory/path bugs fixed during testing.
- v0.9: genuine US code core + repaired frontend resource strategy; successful test baseline for TRUE NTSC.
