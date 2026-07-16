# v2.0c — المساحة الفارغة تتقاس فور فتح الصفحة (مش بس أثناء الفحص) + نص احتياطي قصير
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$p = Join-Path $root 'assets\gamecheck.js'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$js = [System.IO.File]::ReadAllText($p, $utf8)

$edits = @(
    @{
        old = 'this.specs=H()||this.autoDetect(),this.specs.storage===100&&this.specs.source==="auto"&&(this.specs.storage=0),F(this.specs),'
        new = 'this.specs=H()||this.autoDetect(),this.specs.storage===100&&this.specs.source==="auto"&&(this.specs.storage=0),F(this.specs),(!this.specs.storage||this.specs.storage<=0)&&diskFreeGb().then(t=>{t>0&&this.specs&&(!this.specs.storage||this.specs.storage<=0)&&(this.specs.storage=t,this.specs.storageEst=!0,F(this.specs),this.renderDetectBanner())}),'
    },
    @{
        old = ':"غير محددة — أدخلها من تخصيص الفحص"'
        new = ':"غير محددة"'
    },
    @{
        old = 'const a=[...pr,...rs];a.length>60&&(a.length=60);'
        new = 'const a=[...pr,...rs];a.length>15&&(a.length=15);'
    }
)

$i = 0
foreach ($e in $edits) {
    $i++
    if (-not $js.Contains($e.old)) { throw "v2c: النص $i مش موجود" }
    $js = $js.Replace($e.old, $e.new)
    Write-Host "[OK] v2c تعديل $i"
}
[System.IO.File]::WriteAllText($p, $js, $utf8)
Write-Host "تم"
