# v2.2b — إصلاح قص النصوص في كارت المواصفات:
# خلية رابط التعديل تاخد id عشان نسمح لها وحدها بلف السطر + تقصير نص المعالج المُقاس
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$p = Join-Path $root 'assets\gamecheck.js'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$js = [System.IO.File]::ReadAllText($p, $utf8)

$edits = @(
    @{
        old = '<tr><td colspan="2" style="text-align:center;background:#fff"><a href="#" id="gc-edit-specs"'
        new = '<tr><td colspan="2" id="gc-edit-cell" style="text-align:center;background:#fff"><a href="#" id="gc-edit-specs"'
    },
    @{
        old = 't.cpuName=(t.cores||4)+" أنوية — أداء مُقاس فعلياً"'
        new = 't.cpuName=(t.cores||4)+" أنوية (مُقاس)"'
    }
)

$i = 0
foreach ($e in $edits) {
    $i++
    if (-not $js.Contains($e.old)) { throw "v22b: النص $i مش موجود" }
    $js = $js.Replace($e.old, $e.new)
    Write-Host "[OK] v22b تعديل $i"
}
[System.IO.File]::WriteAllText($p, $js, $utf8)
Write-Host "تم"
