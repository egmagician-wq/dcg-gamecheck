# v3b — إصلاح تناقض حالة الفشل:
# لو اللعبة أضعف من الحد الأدنى، لا نعرض "إعدادات متوسطة" ولا نطاق FPS وهمي —
# نعرض رسالة متسقة ونوجّه للبدائل الأخف.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$p = Join-Path $root 'assets\gamecheck.js'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$js = [System.IO.File]::ReadAllText($p, $utf8)

$edits = @(
    @{
        old = '<p class="fps-est">تقدير تقريبي للـ FPS: ${e.fpsEstimate.min}–${e.fpsEstimate.max} إطار</p>'
        new = '<p class="fps-est">${e.verdict==="fail"?"الأداء المتوقع: أقل من "+e.fpsEstimate.min+" إطار — تحت الحد الأدنى":"تقدير تقريبي للـ FPS: "+e.fpsEstimate.min+"–"+e.fpsEstimate.max+" إطار"}</p>'
    },
    @{
        old = '<p class="gc-settings-rec">الإعدادات المقترحة لجهازك: <strong>${n}</strong></p>'
        new = '<p class="gc-settings-rec">${e.verdict==="fail"?"الحل: جرّب أحد البدائل الأخف المقترحة بالأسفل":"الإعدادات المقترحة لجهازك: <strong>"+n+"</strong>"}</p>'
    },
    @{
        old = 'renderGameInfoBox(e){const r=e.game,o=this.settingsForScore(e.overallScore);'
        new = 'renderGameInfoBox(e){const r=e.game,o=e.verdict==="fail"?"غير مناسبة لجهازك":this.settingsForScore(e.overallScore);'
    }
)

$i = 0
foreach ($e in $edits) {
    $i++
    if (-not $js.Contains($e.old)) { throw "v3b: النص $i مش موجود" }
    $js = $js.Replace($e.old, $e.new)
    Write-Host "[OK] v3b تعديل $i"
}
[System.IO.File]::WriteAllText($p, $js, $utf8)
Write-Host "تم"
