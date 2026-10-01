#!/usr/bin/env python3
from pathlib import Path
import argparse, hashlib, struct, shutil, sys
SECSZ=2352; USER=24; DAT=2048
DE_HASH="296e3cb77af3c7a9e89d569097c5fb9c9e644898c670c0622e9bfe6ce0e1b304"; US_HASH="3d0fdbd75ae2377fb12f7acbb9878932e9ff985724d5f15811b02c0f3a115fd4"; T2_HASH="cb68f944093d63a57ac2fbb356c14bd013ac02e5f7c00ddf0d32237165234b0f"
PAL_TARGET_HASH="031dab98cd43343a48e77068e368924101b00627bd49db775c3612abeec0c31f"; NTSC_TARGET_HASH="89b8dabbd7d083d610c3904ffa0ea5d8beca8aae07542a1001f5663d649c1440"

def sha256(path):
    h=hashlib.sha256()
    with open(path,'rb') as f:
        for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
    return h.hexdigest()

def make_tables():
    edc=[0]*256; ef=[0]*256; eb=[0]*256
    for i in range(256):
        x=i
        for _ in range(8): x=(x>>1) ^ (0xD8018001 if x&1 else 0)
        edc[i]=x&0xffffffff
        j=(i<<1) ^ (0x11D if i&0x80 else 0)
        ef[i]=j&0xff; eb[i^j]=i
    return edc,ef,eb
EDC,EF,EB=make_tables()
def edc_compute(src):
    x=0
    for b in src: x=(x>>8)^EDC[(x^b)&0xff]
    return x&0xffffffff

def ecc_compute(src,major_count,minor_count,major_mult,minor_inc):
    size=major_count*minor_count; d=bytearray(major_count*2)
    for major in range(major_count):
        idx=(major>>1)*major_mult+(major&1); a=b=0
        for _ in range(minor_count):
            t=src[idx]; idx+=minor_inc
            if idx>=size: idx-=size
            a^=t; b^=t; a=EF[a]
        a=EB[EF[a]^b]; d[major]=a; d[major+major_count]=a^b
    return d

def regen(sec):
    s=bytearray(sec)
    if not (s[15]==2 and not (s[18]&0x20)): return bytes(s)
    struct.pack_into('<I',s,2072,edc_compute(s[16:2072]))
    saved=bytes(s[12:16]); s[12:16]=b'\0'*4
    s[2076:2248]=ecc_compute(s[12:2076],86,24,2,86)
    s[2248:2352]=ecc_compute(s[12:2248],52,43,86,88)
    s[12:16]=saved
    return bytes(s)

def extract_iso(raw_path,extent,size):
    out=bytearray(); sectors=(size+DAT-1)//DAT
    with open(raw_path,'rb') as f:
        for j in range(sectors):
            f.seek((extent+j)*SECSZ+USER); out+=f.read(DAT)
    return bytes(out[:size])

def write_iso(raw_path,extent,payload):
    with open(raw_path,'r+b') as f:
        pos=0
        for j in range((len(payload)+DAT-1)//DAT):
            f.seek((extent+j)*SECSZ); sec=bytearray(f.read(SECSZ))
            n=min(DAT,len(payload)-pos); sec[USER:USER+n]=payload[pos:pos+n]
            sec=regen(sec); f.seek((extent+j)*SECSZ); f.write(sec); pos+=n

def parse_hed(hb):
    p=0; out={}
    while p<len(hb):
        e=hb.find(b'\0',p)
        if e<0: break
        name=hb[p:e].decode('ascii'); q=(e+1+3)&~3
        if q+8>len(hb): break
        off,size=struct.unpack_from('<II',hb,q)
        out[name]=(off,size,q+4); p=q+8
    return out

def asset(w,m,name):
    off,size,_=m[name]; return bytes(w[off:off+size])
def replace_same(w,m,name,data):
    off,size,_=m[name]
    if len(data)>size: raise ValueError(f'{name}: donor larger than destination slot')
    w[off:off+len(data)]=data
    if len(data)<size: w[off+len(data):off+size]=b'\0'*(size-len(data))

def apply_exe_patch(exe,patch_path):
    p=Path(patch_path).read_bytes()
    if p[:8]!=b'APEXLOC1': raise ValueError('Invalid EXE localization patch')
    n=struct.unpack_from('<I',p,8)[0]; pos=12; out=bytearray(exe)
    for _ in range(n):
        off,ln=struct.unpack_from('<II',p,pos); pos+=8
        out[off:off+ln]=p[pos:pos+ln]; pos+=ln
    if pos!=len(p): raise ValueError('Trailing/corrupt EXE patch data')
    return bytes(out)

def apply_apup(src,out,patch):
    shutil.copy2(src,out); p=Path(patch).read_bytes()
    if p[:8]!=b'APOCUNC1': raise ValueError('Invalid PAL patch')
    n=struct.unpack_from('<I',p,8)[0]; pos=12
    with open(out,'r+b') as f:
        for _ in range(n):
            off,ln=struct.unpack_from('<QI',p,pos); pos+=12; data=p[pos:pos+ln];pos+=ln
            f.seek(off);f.write(data)

def cue(path,bin_name,track2_name):
    txt=(f'FILE "{bin_name}" BINARY\\n'
         f'  TRACK 01 MODE2/2352\\n'
         f'    INDEX 01 00:00:00\\n'
         f'FILE "{track2_name}" BINARY\\n'
         f'  TRACK 02 AUDIO\\n'
         f'    INDEX 00 00:00:00\\n'
         f'    INDEX 01 00:02:00\\n')
    Path(path).write_text(txt,encoding='ascii')

def build_pal(de,track2,outdir,patchdir):
    if sha256(de)!=DE_HASH: raise SystemExit('German Track 1 hash mismatch.')
    if track2 and sha256(track2)!=T2_HASH: raise SystemExit('Track 2 hash mismatch.')
    outdir=Path(outdir);outdir.mkdir(parents=True,exist_ok=True)
    out=outdir/'Apocalypse (Germany) [German Uncut PAL v1.0] (Track 1).bin'
    apply_apup(de,out,Path(patchdir)/'Apocalypse_German_Uncut_PAL_v1.0.apup')
    if sha256(out)!=PAL_TARGET_HASH: raise SystemExit('PAL output validation failed.')
    if track2:
        cue(outdir/'Apocalypse (Germany) [German Uncut PAL v1.0].cue',out.name,Path(track2).name)
    print('PAL build OK:',out)

def build_ntsc(de,us,track2,outdir,patchdir):
    if sha256(de)!=DE_HASH: raise SystemExit('German Track 1 hash mismatch.')
    if sha256(us)!=US_HASH: raise SystemExit('USA Track 1 hash mismatch.')
    if track2 and sha256(track2)!=T2_HASH: raise SystemExit('Track 2 hash mismatch.')
    outdir=Path(outdir);outdir.mkdir(parents=True,exist_ok=True)
    out=outdir/'Apocalypse (Germany) [German Uncut TRUE NTSC 60Hz v1.0] (Track 1).bin'
    shutil.copy2(de,out)
    us_exe=extract_iso(us,24,1019904)
    exe=apply_exe_patch(us_exe,Path(patchdir)/'Apocalypse_TRUE_NTSC_German_EXE_v1.0.apx')
    dh=bytearray(extract_iso(de,522,5309)); dw=bytearray(extract_iso(de,525,31086592))
    uh=extract_iso(us,522,5309); uw=extract_iso(us,525,31086592)
    dm=parse_hed(dh); um=parse_hed(uh)
    for base in ['title']+[f'load{i:02d}' for i in range(1,12)]:
        replace_same(dw,dm,base+'.bmr',asset(dw,dm,'g_'+base+'.bmr'))
    for name in ['marketin.bmr','city_7.psx','wh_t.trg']:
        replace_same(dw,dm,name,asset(uw,um,name))
    ctrl=asset(uw,um,'control.rle'); replace_same(dw,dm,'control.rle',ctrl)
    struct.pack_into('<I',dh,dm['control.rle'][2],len(ctrl))
    write_iso(out,23,exe); write_iso(out,522,bytes(dh)); write_iso(out,525,bytes(dw))
    if sha256(out)!=NTSC_TARGET_HASH: raise SystemExit('TRUE NTSC output validation failed.')
    if track2:
        cue(outdir/'Apocalypse (Germany) [German Uncut TRUE NTSC 60Hz v1.0].cue',out.name,Path(track2).name)
    print('TRUE NTSC build OK:',out)

def main():
    ap=argparse.ArgumentParser(description='Apocalypse German Uncut v1.0 builder by Bratwurstmensch')
    ap.add_argument('--mode',choices=['pal','ntsc'],required=True)
    ap.add_argument('--german',required=True)
    ap.add_argument('--usa')
    ap.add_argument('--track2')
    ap.add_argument('--outdir',default='.')
    ap.add_argument('--patchdir',default=str(Path(__file__).resolve().parent.parent/'patches'))
    a=ap.parse_args()
    if a.mode=='pal': build_pal(a.german,a.track2,a.outdir,a.patchdir)
    else:
        if not a.usa: ap.error('--usa is required for ntsc mode')
        build_ntsc(a.german,a.usa,a.track2,a.outdir,a.patchdir)
if __name__=='__main__': main()
