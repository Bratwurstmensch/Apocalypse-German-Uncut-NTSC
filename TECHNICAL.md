# Technical notes

## German Uncut PAL
The final PAL binary is identical to the previously tested v0.4 state. Only 8 raw CD sectors differ from the verified German original. The patch restores the previously disabled/simplified gore paths and removes the German-only blue-blood override. Mode2/Form1 EDC/ECC was regenerated for modified sectors.

Output SHA-256: `031dab98cd43343a48e77068e368924101b00627bd49db775c3612abeec0c31f`

## TRUE NTSC 60 Hz
The TRUE NTSC output is identical to the successfully tested v0.9 binary state. The builder:

1. verifies both original Track 1 hashes,
2. uses the genuine US executable from the user's SLUS-00373 image,
3. applies only the German localization/address adjustments stored in the small `APEXLOC1` patch,
4. retains the German disc layout, speech, movies and XA/CD content,
5. maps the German title/loading graphics into the US frontend resource slots,
6. imports the NTSC-specific WAD assets `marketin.bmr`, `control.rle`, `city_7.psx` and `wh_t.trg` from the user's US image,
7. regenerates Mode2/Form1 EDC/ECC for rewritten sectors,
8. verifies the final SHA-256.

`tube_7.psx` is byte-identical between the verified German and US builds and is not part of the final censorship fix.

Output SHA-256: `89b8dabbd7d083d610c3904ffa0ea5d8beca8aae07542a1001f5663d649c1440`

## Why the US disc is required for TRUE NTSC
Earlier test packages embedded a multi-megabyte sector delta because the German image was the only input. The public builder instead reads the original US code/assets from the user's own US image. This keeps the distributed patch package small, transparent and free of a complete donor executable.

## Development methodology / AI disclosure
The reverse-engineering work documented here was carried out through an AI-assisted workflow using ChatGPT. This includes comparative analysis of the German, European and US binaries, identification of censorship changes, patch design, builder generation and documentation. Bratwurstmensch served as project initiator/director and hands-on tester, providing the original dumps and reporting emulator behavior after each test build.

The builders and notes are intentionally included to make the AI-produced work inspectable and reproducible rather than presenting it as hand-authored reverse engineering.
