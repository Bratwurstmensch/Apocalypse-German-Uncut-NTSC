param([string]$GermanTrack1,[string]$Track2)
$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $MyInvocation.MyCommand.Path
$Pkg=Split-Path -Parent $Root
$Patch=Join-Path $Pkg 'patches\Apocalypse_German_Uncut_PAL_v1.0.apup'
$Expected='296e3cb77af3c7a9e89d569097c5fb9c9e644898c670c0622e9bfe6ce0e1b304'; $Target='031dab98cd43343a48e77068e368924101b00627bd49db775c3612abeec0c31f'; $T2Expected='cb68f944093d63a57ac2fbb356c14bd013ac02e5f7c00ddf0d32237165234b0f'
if (-not $GermanTrack1) { $GermanTrack1=Read-Host 'Path to original Apocalypse (Germany) (Track 1).bin' }
$GermanTrack1=(Resolve-Path -LiteralPath $GermanTrack1).Path
if ((Get-FileHash $GermanTrack1 -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Expected) { throw 'German Track 1 SHA256 mismatch.' }
if (-not $Track2) { $c=Join-Path (Split-Path $GermanTrack1) 'Apocalypse (Germany) (Track 2).bin'; if(Test-Path -LiteralPath $c){$Track2=$c} }
if ($Track2 -and (Get-FileHash $Track2 -Algorithm SHA256).Hash.ToLowerInvariant() -ne $T2Expected) { throw 'Track 2 SHA256 mismatch.' }
$Dir=Split-Path $GermanTrack1; $Out=Join-Path $Dir 'Apocalypse (Germany) [German Uncut PAL v1.0] (Track 1).bin'
Copy-Item -LiteralPath $GermanTrack1 -Destination $Out -Force
$p=[IO.File]::OpenRead($Patch); $r=New-Object IO.BinaryReader($p)
try { if([Text.Encoding]::ASCII.GetString($r.ReadBytes(8)) -ne 'APOCUNC1'){throw 'Bad patch'}; $n=$r.ReadUInt32(); $o=[IO.File]::Open($Out,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite); try{ for($i=0;$i -lt $n;$i++){$off=[Int64]$r.ReadUInt64();$len=$r.ReadUInt32();$data=$r.ReadBytes($len);[void]$o.Seek($off,[IO.SeekOrigin]::Begin);$o.Write($data,0,$data.Length)} }finally{$o.Dispose()} }finally{$r.Dispose();$p.Dispose()}
if ((Get-FileHash $Out -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Target) { throw 'Output SHA256 validation failed.' }
if($Track2){ $cue=Join-Path $Dir 'Apocalypse (Germany) [German Uncut PAL v1.0].cue'; $t2=[IO.Path]::GetFileName($Track2); $bn=[IO.Path]::GetFileName($Out); $txt="FILE `"$bn`" BINARY`r`n  TRACK 01 MODE2/2352`r`n    INDEX 01 00:00:00`r`nFILE `"$t2`" BINARY`r`n  TRACK 02 AUDIO`r`n    INDEX 00 00:00:00`r`n    INDEX 01 00:02:00`r`n"; [IO.File]::WriteAllText($cue,$txt,[Text.Encoding]::ASCII)}
Write-Host 'SUCCESS - German Uncut PAL v1.0 created.' -ForegroundColor Green
Write-Host $Out
