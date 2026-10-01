param(
  [string]$GermanTrack1,
  [string]$UsaTrack1,
  [string]$Track2
)
$ErrorActionPreference = 'Stop'
$ToolDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PkgDir = Split-Path -Parent $ToolDir
$ExePatch = Join-Path $PkgDir 'patches\Apocalypse_TRUE_NTSC_German_EXE_v1.0.apx'
$ExpectedDE = '296e3cb77af3c7a9e89d569097c5fb9c9e644898c670c0622e9bfe6ce0e1b304'
$ExpectedUS = '3d0fdbd75ae2377fb12f7acbb9878932e9ff985724d5f15811b02c0f3a115fd4'
$ExpectedT2 = 'cb68f944093d63a57ac2fbb356c14bd013ac02e5f7c00ddf0d32237165234b0f'
$ExpectedTarget = '89b8dabbd7d083d610c3904ffa0ea5d8beca8aae07542a1001f5663d649c1440'

$cs = @"
using System;
public static class ApocCd {
    static uint[] edc = new uint[256];
    static byte[] ef = new byte[256];
    static byte[] eb = new byte[256];
    static ApocCd() {
        for (int i=0;i<256;i++) {
            uint x=(uint)i;
            for(int k=0;k<8;k++) x=(x>>1)^(((x&1)!=0)?0xD8018001u:0u);
            edc[i]=x;
            int j=(i<<1)^(((i&0x80)!=0)?0x11D:0);
            ef[i]=(byte)(j&0xFF);
            eb[i^j]=(byte)i;
        }
    }
    static uint Edc(byte[] s,int off,int len) {
        uint x=0;
        for(int i=0;i<len;i++) x=(x>>8)^edc[(x^s[off+i])&0xFF];
        return x;
    }
    static void Ecc(byte[] s,int off,int majorCount,int minorCount,int majorMult,int minorInc,byte[] d,int destOff) {
        int size=majorCount*minorCount;
        for(int major=0;major<majorCount;major++) {
            int index=(major>>1)*majorMult+(major&1);
            byte a=0,b=0;
            for(int minor=0;minor<minorCount;minor++) {
                byte t=s[off+index]; index+=minorInc; if(index>=size) index-=size;
                a^=t; b^=t; a=ef[a];
            }
            a=eb[ef[a]^b]; d[destOff+major]=a; d[destOff+major+majorCount]=(byte)(a^b);
        }
    }
    public static byte[] Regen(byte[] input) {
        byte[] s=(byte[])input.Clone();
        if(s.Length!=2352) throw new ArgumentException("sector must be 2352 bytes");
        if(!(s[15]==2 && (s[18]&0x20)==0)) return s;
        uint v=Edc(s,16,2056);
        s[2072]=(byte)(v&0xFF); s[2073]=(byte)((v>>8)&0xFF); s[2074]=(byte)((v>>16)&0xFF); s[2075]=(byte)((v>>24)&0xFF);
        byte h0=s[12],h1=s[13],h2=s[14],h3=s[15]; s[12]=s[13]=s[14]=s[15]=0;
        Ecc(s,12,86,24,2,86,s,2076);
        Ecc(s,12,52,43,86,88,s,2248);
        s[12]=h0;s[13]=h1;s[14]=h2;s[15]=h3;
        return s;
    }
}
"@
Add-Type -TypeDefinition $cs -Language CSharp

function Read-IsoBytes {
  param([string]$Path,[long]$Extent,[long]$LogicalOffset,[int]$Length)
  [byte[]]$out = New-Object byte[] $Length
  $fs=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
  try {
    $done=0
    while($done -lt $Length) {
      [long]$p=$LogicalOffset+$done
      [long]$lba=$Extent+[long][Math]::Floor($p/2048.0)
      [int]$inside=[int]($p % 2048)
      [int]$take=[Math]::Min(2048-$inside,$Length-$done)
      [void]$fs.Seek($lba*2352+24+$inside,[IO.SeekOrigin]::Begin)
      $got=$fs.Read($out,$done,$take)
      if($got -ne $take){throw 'Unexpected end of raw track while reading ISO data.'}
      $done+=$take
    }
  } finally {$fs.Dispose()}
  return ,$out
}

function Write-IsoBytes {
  param([string]$Path,[long]$Extent,[long]$LogicalOffset,[byte[]]$Data)
  $fs=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
  try {
    $done=0
    while($done -lt $Data.Length) {
      [long]$p=$LogicalOffset+$done
      [long]$lba=$Extent+[long][Math]::Floor($p/2048.0)
      [int]$inside=[int]($p % 2048)
      [int]$take=[Math]::Min(2048-$inside,$Data.Length-$done)
      [byte[]]$sec=New-Object byte[] 2352
      [void]$fs.Seek($lba*2352,[IO.SeekOrigin]::Begin)
      $got=$fs.Read($sec,0,2352); if($got -ne 2352){throw 'Unexpected end of output track.'}
      [Array]::Copy($Data,$done,$sec,24+$inside,$take)
      [byte[]]$sec=[ApocCd]::Regen($sec)
      [void]$fs.Seek($lba*2352,[IO.SeekOrigin]::Begin); $fs.Write($sec,0,2352)
      $done+=$take
    }
  } finally {$fs.Dispose()}
}

function Parse-Hed {
  param([byte[]]$Bytes)
  $m=@{}; $p=0
  while($p -lt $Bytes.Length) {
    $e=$p; while($e -lt $Bytes.Length -and $Bytes[$e] -ne 0){$e++}
    if($e -ge $Bytes.Length){break}
    $name=[Text.Encoding]::ASCII.GetString($Bytes,$p,$e-$p)
    $q=[int](4*[Math]::Ceiling(($e+1)/4.0))
    if($q+8 -gt $Bytes.Length){break}
    [uint32]$off=[BitConverter]::ToUInt32($Bytes,$q)
    [uint32]$size=[BitConverter]::ToUInt32($Bytes,$q+4)
    $m[$name]=[pscustomobject]@{Offset=[long]$off;Size=[int]$size;SizePos=[int]($q+4)}
    $p=$q+8
  }
  return $m
}

function Copy-WadAsset {
  param([string]$SourceTrack,$SourceMap,[string]$SourceName,[string]$OutputTrack,$DestMap,[string]$DestName)
  $s=$SourceMap[$SourceName]; $d=$DestMap[$DestName]
  if($null -eq $s -or $null -eq $d){throw "Missing WAD entry: $SourceName -> $DestName"}
  if($s.Size -gt $d.Size){throw "Donor asset too large: $SourceName"}
  [byte[]]$data=Read-IsoBytes $SourceTrack 525 $s.Offset $s.Size
  Write-IsoBytes $OutputTrack 525 $d.Offset $data
  if($s.Size -lt $d.Size) {
    [byte[]]$zeros=New-Object byte[] ($d.Size-$s.Size)
    Write-IsoBytes $OutputTrack 525 ($d.Offset+$s.Size) $zeros
  }
}

Write-Host ''
Write-Host 'Apocalypse - German Uncut TRUE NTSC 60Hz v1.0' -ForegroundColor Cyan
Write-Host 'by Bratwurstmensch'
Write-Host ''
if(-not $GermanTrack1){$GermanTrack1=Read-Host 'Path to ORIGINAL German Track 1 BIN'}
if(-not $UsaTrack1){$UsaTrack1=Read-Host 'Path to ORIGINAL USA Track 1 BIN'}
$GermanTrack1=(Resolve-Path -LiteralPath $GermanTrack1).Path
$UsaTrack1=(Resolve-Path -LiteralPath $UsaTrack1).Path
if((Get-FileHash $GermanTrack1 -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ExpectedDE){throw 'German Track 1 SHA256 mismatch.'}
if((Get-FileHash $UsaTrack1 -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ExpectedUS){throw 'USA Track 1 SHA256 mismatch.'}
$Dir=Split-Path -Parent $GermanTrack1
if(-not $Track2){$c=Join-Path $Dir 'Apocalypse (Germany) (Track 2).bin';if(Test-Path -LiteralPath $c){$Track2=$c}}
if($Track2){$Track2=(Resolve-Path -LiteralPath $Track2).Path;if((Get-FileHash $Track2 -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ExpectedT2){throw 'Track 2 SHA256 mismatch.'}}
$Out=Join-Path $Dir 'Apocalypse (Germany) [German Uncut TRUE NTSC 60Hz v1.0] (Track 1).bin'
Copy-Item -LiteralPath $GermanTrack1 -Destination $Out -Force

Write-Host 'Reading original US executable ...'
[byte[]]$exe=Read-IsoBytes $UsaTrack1 24 0 1019904
$ps=[IO.File]::OpenRead($ExePatch);$br=New-Object IO.BinaryReader($ps)
try {
  if([Text.Encoding]::ASCII.GetString($br.ReadBytes(8)) -ne 'APEXLOC1'){throw 'Bad EXE localization patch.'}
  $count=$br.ReadUInt32()
  for($i=0;$i -lt $count;$i++){
    [int]$off=$br.ReadUInt32();[int]$len=$br.ReadUInt32();[byte[]]$b=$br.ReadBytes($len)
    if($b.Length -ne $len){throw 'EXE localization patch is truncated.'}
    [Array]::Copy($b,0,$exe,$off,$len)
  }
} finally {$br.Dispose();$ps.Dispose()}
Write-Host 'Installing localized US code core ...'
Write-IsoBytes $Out 23 0 $exe

[byte[]]$deHed=Read-IsoBytes $GermanTrack1 522 0 5309
[byte[]]$usHed=Read-IsoBytes $UsaTrack1 522 0 5309
$dm=Parse-Hed $deHed; $um=Parse-Hed $usHed
Write-Host 'Installing German frontend graphics into NTSC slots ...'
$names=@('title','load01','load02','load03','load04','load05','load06','load07','load08','load09','load10','load11')
foreach($n in $names){Copy-WadAsset $GermanTrack1 $dm ('g_'+$n+'.bmr') $Out $dm ($n+'.bmr')}
Write-Host 'Installing NTSC-specific WAD assets from original US disc ...'
foreach($n in @('marketin.bmr','city_7.psx','wh_t.trg')){Copy-WadAsset $UsaTrack1 $um $n $Out $dm $n}
Copy-WadAsset $UsaTrack1 $um 'control.rle' $Out $dm 'control.rle'
[byte[]]$ctrlSize=[BitConverter]::GetBytes([uint32]$um['control.rle'].Size)
[Array]::Copy($ctrlSize,0,$deHed,$dm['control.rle'].SizePos,4)
Write-IsoBytes $Out 522 0 $deHed

Write-Host 'Validating final SHA256 ...'
$h=(Get-FileHash $Out -Algorithm SHA256).Hash.ToLowerInvariant()
if($h -ne $ExpectedTarget){throw "TRUE NTSC output validation failed. Got $h"}
if($Track2){
  $Cue=Join-Path $Dir 'Apocalypse (Germany) [German Uncut TRUE NTSC 60Hz v1.0].cue'
  $bn=[IO.Path]::GetFileName($Out);$t2=[IO.Path]::GetFileName($Track2)
  $txt="FILE `"$bn`" BINARY`r`n  TRACK 01 MODE2/2352`r`n    INDEX 01 00:00:00`r`nFILE `"$t2`" BINARY`r`n  TRACK 02 AUDIO`r`n    INDEX 00 00:00:00`r`n    INDEX 01 00:02:00`r`n"
  [IO.File]::WriteAllText($Cue,$txt,[Text.Encoding]::ASCII)
}
Write-Host ''
Write-Host 'SUCCESS - TRUE NTSC 60Hz v1.0 created and hash-verified.' -ForegroundColor Green
Write-Host $Out
