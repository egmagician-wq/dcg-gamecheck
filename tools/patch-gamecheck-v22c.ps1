# v2.2c — شيبس آخر الفحوصات بدون أرقام + شريط التعديل اليدوي بعرض الصفحة تحت الكروت
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$p = Join-Path $root 'assets\gamecheck.js'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$js = [System.IO.File]::ReadAllText($p, $utf8)

$edits = @(
    # شيل الرقم من شيبس آخر الفحوصات
    @{
        old = '<a class="gc-recent-chip" href="${this.checkUrl({game:r.id})}">${r.n} <b>${r.s}</b></a>'
        new = '<a class="gc-recent-chip" href="${this.checkUrl({game:r.id})}">${r.n}</a>'
    },
    # شيل صف التعديل من جوه جدول الكروت
    @{
        old = '<tr><td colspan="2" id="gc-edit-cell" style="text-align:center;background:#fff"><a href="#" id="gc-edit-specs" style="font-weight:700">&#9999;&#65039; المواصفات مش مظبوطة؟ عدّلها يدوياً</a>${this.specs.source==="auto"&&/intel|iris|uhd|مدمج/i.test(this.specs.gpuName||"")?`<div style="font-size:12px;color:#b26a00;margin-top:5px">عندك كرت NVIDIA أو AMD منفصل؟ المتصفح أحياناً يكتشف الكرت المدمج فقط — اختر كرتك الحقيقي من التعديل اليدوي.</div>`:""}</td></tr>'
        new = ''
    },
    # شريط التعديل كعنصر مستقل بعرض الصفحة بعد الكروت
    @{
        old = 'renderDetectBanner(){const e=g("#detect-banner");if(!e||!this.specs)return;'
        new = 'renderDetectBanner(){const e=g("#detect-banner");if(!e||!this.specs)return;let eb=document.getElementById("gc-edit-bar");eb||(eb=document.createElement("div"),eb.id="gc-edit-bar",e.parentNode&&e.parentNode.insertBefore(eb,e.nextSibling)),eb.innerHTML=`<a href="#" id="gc-edit-specs">&#9999;&#65039; المواصفات مش مظبوطة؟ عدّلها يدوياً</a>${this.specs.source==="auto"&&/intel|iris|uhd|مدمج/i.test(this.specs.gpuName||"")?`<span class="gc-edit-note">عندك كرت NVIDIA أو AMD منفصل؟ المتصفح أحياناً يكتشف الكرت المدمج فقط — اختر كرتك الحقيقي.</span>`:""}`;'
    }
)

$i = 0
foreach ($e in $edits) {
    $i++
    if (-not $js.Contains($e.old)) { throw "v22c: النص $i مش موجود" }
    $js = $js.Replace($e.old, $e.new)
    Write-Host "[OK] v22c تعديل $i"
}
[System.IO.File]::WriteAllText($p, $js, $utf8)
Write-Host "تم"
