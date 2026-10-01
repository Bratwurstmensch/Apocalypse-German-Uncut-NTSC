from pathlib import Path
import subprocess, sys
here=Path(__file__).resolve().parent
print('Apocalypse - German Uncut TRUE NTSC 60Hz v1.0')
print('by Bratwurstmensch')
print()
de=input('Path to ORIGINAL German Track 1 BIN: ').strip().strip('"')
us=input('Path to ORIGINAL USA Track 1 BIN: ').strip().strip('"')
t2=input('Path to German Track 2 BIN (optional; Enter to auto-detect): ').strip().strip('"')
dep=Path(de)
if not t2:
    c=dep.parent/'Apocalypse (Germany) (Track 2).bin'
    t2=str(c) if c.exists() else ''
cmd=[sys.executable,str(here/'build_apocalypse.py'),'--mode','ntsc','--german',de,'--usa',us,'--outdir',str(dep.parent)]
if t2: cmd += ['--track2',t2]
raise SystemExit(subprocess.call(cmd))
