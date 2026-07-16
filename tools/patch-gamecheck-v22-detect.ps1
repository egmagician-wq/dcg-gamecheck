# v2.2 — تحسين دقة اكتشاف المواصفات (رد على شكاوى "المواصفات غلط"):
# 1) طلب كرت الشاشة القوي من المتصفح (اللابتوبات بكرتين كانت بتظهر Intel فقط)
# 2) الرام: المتصفح يقف عند 8 كحد أقصى — نعرض "أو أكثر" بدل رقم يبدو نهائياً
# 3) رابط تعديل واضح على كارت المواصفات + تنبيه أصحاب الكروت المنفصلة
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$p = Join-Path $root 'assets\gamecheck.js'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$js = [System.IO.File]::ReadAllText($p, $utf8)

$edits = @(
    @{
        old = 'e=t.getContext("webgl")||t.getContext("experimental-webgl");'
        new = 'e=t.getContext("webgl",{powerPreference:"high-performance"})||t.getContext("webgl")||t.getContext("experimental-webgl");'
    },
    @{
        old = 'const r=e.getContext("webgl");if(!r)'
        new = 'const r=e.getContext("webgl",{powerPreference:"high-performance"})||e.getContext("webgl");if(!r)'
    },
    @{
        old = 'الذاكرة (RAM)</td><td>${this.specs.ram} GB</td></tr>'
        new = 'الذاكرة (RAM)</td><td>${this.specs.ram} GB${this.specs.source==="auto"&&this.specs.ram>=8?" أو أكثر":""}</td></tr>'
    },
    @{
        old = 'مساحة فارغة</td><td>${r}</td></tr>'
        new = 'مساحة فارغة</td><td>${r}</td></tr><tr><td colspan="2" style="text-align:center;background:#fff"><a href="#" id="gc-edit-specs" style="font-weight:700">&#9999;&#65039; المواصفات مش مظبوطة؟ عدّلها يدوياً</a>${this.specs.source==="auto"&&/intel|iris|uhd|مدمج/i.test(this.specs.gpuName||"")?`<div style="font-size:12px;color:#b26a00;margin-top:5px">عندك كرت NVIDIA أو AMD منفصل؟ المتصفح أحياناً يكتشف الكرت المدمج فقط — اختر كرتك الحقيقي من التعديل اليدوي.</div>`:""}</td></tr>'
    },
    @{
        old = 'bindEvents(){g("#btn-detect")?.addEventListener'
        new = 'bindEvents(){document.addEventListener("click",t=>{const n=t.target&&t.target.closest?t.target.closest("#gc-edit-specs"):null;if(!n)return;t.preventDefault();const s=g("#advanced-panel");if(s){s.open=!0;const m=s.querySelector(".gc-nested");m&&(m.open=!0),s.scrollIntoView({behavior:"smooth",block:"start"})}}),g("#btn-detect")?.addEventListener'
    }
)

$i = 0
foreach ($e in $edits) {
    $i++
    if (-not $js.Contains($e.old)) { throw "v22: النص $i مش موجود" }
    $js = $js.Replace($e.old, $e.new)
    Write-Host "[OK] v22 تعديل $i"
}
[System.IO.File]::WriteAllText($p, $js, $utf8)
Write-Host "تم — دقة الاكتشاف اتحسنت"
