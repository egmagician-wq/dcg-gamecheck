# v2.5 — دفعة شاملة:
# 1) توحيد قسم الألعاب المقترحة (شيل "ألعاب قد تناسبك"، "بدائل أخف" فقط عند fail وتخفي القسم من السيرفر)
# 2) الأسئلة الشائعة الديناميكية تتحول لـ details/summary
# 3) أسماء إنجليزية جنب العربية في العنوان الديناميكي والشيبس والقوائم
# 4) تبسيط renderDetectBanner (شيل حيلة نقل DOM، استهداف #gc-gpu-note الثابت بدل ما ننشئ عنصر)
# 5) حذف مستمع النقر القديم لـ #gc-edit-specs (بقى مالوش داعي، details/summary بيتعامل لوحده)
#
# ملحوظة: الملف المصدر بيستخدم CRLF جوه الـ template literals، فأي نص متعدد الأسطر
# بيتبني بـ -join "`r`n" صراحة عشان يتطابق بالظبط (مش بالاعتماد على سطور الملف الخام).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$p = Join-Path $root 'assets\gamecheck.js'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$js = [System.IO.File]::ReadAllText($p, $utf8)

$old1 = @(
    '${this.renderCtaRow(e)}${this.renderShareBtn(e)}',
    '        ${this.renderDownloadChips("ألعاب قد تناسبك",this.gamesThatFit(e.game.id,e.overallScore),"مختارة حسب مواصفات جهازك — تتغيّر من جهاز لآخر")}',
    '        <table class="gc-req-table gc-req-compare">'
) -join "`r`n"
$new1 = @(
    '${this.renderCtaRow(e)}${this.renderShareBtn(e)}',
    '        <table class="gc-req-table gc-req-compare">'
) -join "`r`n"

$old3 = @(
    'renderRelatedBlock(e){const r=this.getRelatedSuggestions(e.game,e.overallScore),o=this.getHubLink(e.game);return`',
    '      ${this.renderSuggestLinks(r,e.overallScore)}',
    '      <div class="gc-suggest-hubs">'
) -join "`r`n"
$new3 = @(
    'renderRelatedBlock(e){const r=this.getRelatedSuggestions(e.game,e.overallScore),o=this.getHubLink(e.game),srv=document.getElementById("gc-related-block");srv&&(srv.style.display=e.verdict==="fail"?"none":"");return`',
    '      ${this.renderSuggestLinks(r,e.verdict)}',
    '      <div class="gc-suggest-hubs">'
) -join "`r`n"

$old10 = @(
    '      <div class="gc-faq-item">',
    '        <h3 class="gc-faq-q"><u><span>${a.q}</span></u></h3>',
    '        <p class="gc-faq-a">${a.a}</p>',
    '      </div>`).join("")}'
) -join "`r`n"
$new10 = @(
    '      <details class="gc-faq-item">',
    '        <summary class="gc-faq-q">${a.q}</summary>',
    '        <p class="gc-faq-a">${a.a}</p>',
    '      </details>`).join("")}'
) -join "`r`n"

$edits = @(
    @{ old = $old1; new = $new1 },
    @{
        old = 'renderSuggestLinks(e,r){if(r>=80)return"";const o=e.filter(a=>this.hasRealArticle(a)).slice(0,10);return this.renderDownloadChips(r<55?"بدائل أخف تعمل على جهازك بسلاسة":"ألعاب مقترحة تناسب جهازك",o,r<55?"مرتبة حسب توافقها مع مواصفات جهازك":"")}'
        new = 'renderSuggestLinks(e,verdict){if(verdict!=="fail")return"";const o=e.filter(a=>this.hasRealArticle(a)).slice(0,5);return this.renderDownloadChips("بدائل أخف تعمل على جهازك بسلاسة",o,"مرتبة حسب توافقها مع مواصفات جهازك")}'
    },
    @{ old = $old3; new = $new3 },
    @{
        old = 'te.forEach(s=>c(this.games.find(m=>m.id===s)));return o.slice(0,8)}weightAr(e){'
        new = 'te.forEach(s=>c(this.games.find(m=>m.id===s)));return o.slice(0,5)}weightAr(e){'
    },
    @{
        old = 'renderDownloadChips(e,r,o=""){const a=r.filter(s=>this.hasRealArticle(s));if(!a.length)return"";const c=a.map(s=>`<a class="gc-dl-chip" href="${this.gameDownloadUrl(s)}" target="_blank" rel="noopener">تحميل لعبة ${s.nameAr}</a>`).join("")'
        new = 'renderDownloadChips(e,r,o=""){const a=r.filter(s=>this.hasRealArticle(s));if(!a.length)return"";const c=a.map(s=>`<a class="gc-dl-chip" href="${this.gameDownloadUrl(s)}" target="_blank" rel="noopener">تحميل لعبة ${s.nameAr} <span class="gc-en-name">${s.name}</span></a>`).join("")'
    },
    @{
        old = 'e.innerHTML=a.slice(0,8).map(o=>`<a class="internal-link" href="${this.checkUrl({game:o.id})}">هل جهازي يشغّل ${o.nameAr}${h}</a>`).join("")}'
        new = 'e.innerHTML=a.slice(0,8).map(o=>`<a class="internal-link" href="${this.checkUrl({game:o.id})}">هل جهازي يشغّل ${o.nameAr} <span class="gc-en-name">(${o.name})</span>${h}</a>`).join("")}'
    },
    @{
        old = '`هل جهازي يشغل ${c.nameAr}${h} - فحص المتطلبات و FPS`'
        new = '`هل جهازي يشغل ${c.nameAr} (${c.name})${h} - فحص المتطلبات و FPS`'
    },
    @{
        old = '`هل جهازي يشغل <span class="highlight">${c.nameAr}</span>${h}`'
        new = '`هل جهازي يشغل <span class="highlight">${c.nameAr}</span> <span class="gc-en-name">(${c.name})</span>${h}`'
    },
    @{
        old = 'renderDetectBanner(){const e=g("#detect-banner");if(!e||!this.specs)return;let eb=document.getElementById("gc-edit-bar");eb||(eb=document.createElement("div"),eb.id="gc-edit-bar",e.parentNode&&e.parentNode.insertBefore(eb,e.nextSibling));if(!eb.dataset.wired){eb.dataset.wired="1";const adv=document.getElementById("advanced-panel"),man=adv&&adv.querySelector(".gc-nested");man&&eb.parentNode&&(man.classList.add("gc-manual-inline"),eb.parentNode.insertBefore(man,eb.nextSibling))}eb.innerHTML=`<a href="#" id="gc-edit-specs">&#9999;&#65039; المواصفات مش مظبوطة؟ عدّلها يدوياً</a>${this.specs.source==="auto"&&/intel|iris|uhd|مدمج/i.test(this.specs.gpuName||"")?`<span class="gc-edit-note">عندك كرت NVIDIA أو AMD منفصل؟ المتصفح أحياناً يكتشف الكرت المدمج فقط — اختر كرتك الحقيقي.</span>`:""}`;const r=this.specs.storage>0?'
        new = 'renderDetectBanner(){const e=g("#detect-banner");if(!e||!this.specs)return;const nt=g("#gc-gpu-note");nt&&(nt.textContent=this.specs.source==="auto"&&/intel|iris|uhd|مدمج/i.test(this.specs.gpuName||"")?" — لاحظنا كرت شاشة مدمج، لو عندك كرت منفصل اختاره من هنا":"");const r=this.specs.storage>0?'
    },
    @{
        old = 'bindEvents(){document.addEventListener("click",t=>{const n=t.target&&t.target.closest?t.target.closest("#gc-edit-specs"):null;if(!n)return;t.preventDefault();const m=document.querySelector(".gc-manual-inline")||g("#advanced-panel")?.querySelector(".gc-nested");m&&(m.open=!m.open,m.open&&m.scrollIntoView({behavior:"smooth",block:"nearest"}))}),g("#btn-detect")?.addEventListener'
        new = 'bindEvents(){g("#btn-detect")?.addEventListener'
    },
    @{ old = $old10; new = $new10 }
)

$i = 0
foreach ($e in $edits) {
    $i++
    if (-not $js.Contains($e.old)) { throw "v25: النص $i مش موجود" }
    $js = $js.Replace($e.old, $e.new)
    Write-Host "[OK] v25 تعديل $i"
}
[System.IO.File]::WriteAllText($p, $js, $utf8)
Write-Host "تم — v2.5 (10 تعديلات)"
