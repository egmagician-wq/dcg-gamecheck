# v2.3 — الدقة الكاملة:
# 1) دعم لصق مواصفات ويندوز (زر Copy في الإعدادات ← النظام ← حول) إنجليزي وعربي
# 2) دعم ?spec= في الرابط (أساس برنامج الفحص الخارجي زي Can You Run It)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$p = Join-Path $root 'assets\gamecheck.js'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$js = [System.IO.File]::ReadAllText($p, $utf8)

$edits = @(
    # --- 1) محلل صيغة "حول الجهاز" من إعدادات ويندوز (EN + AR) قبل محلل dxdiag ---
    @{
        old = 'function O(t){if(!t.trim())return null;'
        new = 'function parseWinAbout(t){try{const e=t.match(/(?:Processor|المعالج)\s*[:\t]?\s*(.+)/i),r=t.match(/(?:Installed RAM|ذاكرة الوصول العشوائي[^\n]*المثبتة|الذاكرة المثبتة)\s*[:\t]?\s*([\d.,]+)\s*(?:GB|جيجا)/i),o=t.match(/(?:Graphics Card|بطاقة الرسومات|بطاقة رسومات)\s*[:\t]?\s*(.+)/i);if(!e||!r&&!o)return null;const a=r?Math.max(2,Math.round(parseFloat(r[1].replace(",",".")))):8;return{cpuName:e[1].trim().replace(/\s{2,}.*$/,"").slice(0,60),gpuName:o?o[1].trim().slice(0,60):"Unknown GPU",ramGb:a,os:"Windows"}}catch{return null}}function O(t){if(!t.trim())return null;const wa=parseWinAbout(t);if(wa)return wa;'
    },
    # --- رسالة الخطأ تشمل الطريقتين ---
    @{
        old = 'لم نتمكن من قراءة dxdiag — تأكد من لصق النص كاملاً'
        new = 'لم نتمكن من قراءة المواصفات — الصق النص كاملاً كما نسخته من إعدادات ويندوز (زر Copy) أو من تقرير dxdiag'
    },
    # --- 2) دالة قراءة المواصفات من الرابط ?spec= (base64url JSON) ---
    @{
        old = 'async refineSpecs(){try{const t=this.specs'
        new = 'applySpecParam(t){try{let e=t.get("spec");if(!e)return;e=e.replace(/-/g,"+").replace(/_/g,"/");for(;e.length%4;)e+="=";const r=JSON.parse(decodeURIComponent(escape(atob(e))));if(!r||!r.cpu&&!r.gpu)return;const o=j(String(r.gpu||""),this.gpuMap),a=N(String(r.cpu||""),4,this.gpuMap);F({ram:Math.max(2,parseInt(r.ram,10)||8),gpuScore:o.score,gpuName:String(r.gpu||o.label).slice(0,60),cpuScore:a,cpuName:String(r.cpu||"").slice(0,60),cores:parseInt(r.cores,10)||4,storage:Math.max(0,parseInt(r.storage,10)||0),os:"Windows",source:"dxdiag"})}catch{}}async refineSpecs(){try{const t=this.specs'
    },
    # --- تفعيلها عند فتح الصفحة ---
    @{
        old = 'await this.loadCatalog(),this.specs=H()||this.autoDetect(),'
        new = 'await this.loadCatalog(),this.applySpecParam(e),this.specs=H()||this.autoDetect(),'
    }
)

$i = 0
foreach ($e in $edits) {
    $i++
    if (-not $js.Contains($e.old)) { throw "v23: النص $i مش موجود" }
    $js = $js.Replace($e.old, $e.new)
    Write-Host "[OK] v23 تعديل $i"
}
[System.IO.File]::WriteAllText($p, $js, $utf8)
Write-Host "تم — الدقة الكاملة جاهزة"
