# تعديلات جراحية على assets/gamecheck.js المضغوط:
# 1) إصلاح باج تقييم المعالج (نص فارغ بدل اسم المعالج)
# 2) تحميل خريطة مقالات المتطلبات req-posts.json
# 3) روابط "فحص ألعاب شائعة" تشاور على مقالات المتطلبات لو موجودة
# 4) إعادة استهداف العنوان العام للكلمة الأعلى بحثاً
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$p = Join-Path $root 'assets\gamecheck.js'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$js = [System.IO.File]::ReadAllText($p, $utf8)

$edits = @(
    @{
        old = 'function _(t,e){const r="".toLowerCase();'
        new = 'function _(t,e){const r=(e||"").toLowerCase();'
    },
    @{
        old = 'r.ok&&(this.gpuMap=await r.json())}catch{}}async onPopState(){'
        new = 'r.ok&&(this.gpuMap=await r.json())}catch{}this.reqPosts={};try{const n=await fetch("https://cdn.jsdelivr.net/gh/egmagician-wq/dcg-gamecheck@main/data/req-posts.json",{cache:"no-cache"});n.ok&&(this.reqPosts=await n.json())}catch{}}async onPopState(){'
    },
    @{
        old = '<a class="internal-link" href="${this.checkUrl({game:c.id})}">هل جهازي يشغل ${c.nameAr}${h}</a>'
        new = '<a class="internal-link" href="${this.reqPosts&&this.reqPosts[c.id]?this.reqPosts[c.id]:this.checkUrl({game:c.id})}">هل جهازي يشغل ${c.nameAr}${h}</a>'
    },
    @{
        old = 'GameCheck — هل جهازي يشغل اللعبة'
        new = 'فحص متطلبات تشغيل الألعاب — هل جهازي يشغل اللعبة'
    }
)

foreach ($e in $edits) {
    if (-not $js.Contains($e.old)) {
        throw "النص المطلوب تعديله مش موجود: $($e.old.Substring(0, [Math]::Min(60, $e.old.Length)))"
    }
    $js = $js.Replace($e.old, $e.new)
    Write-Host "[OK] $($e.old.Substring(0, [Math]::Min(50, $e.old.Length)))..."
}

[System.IO.File]::WriteAllText($p, $js, $utf8)
Write-Host "`nتم حفظ gamecheck.js بعد التعديلات."
