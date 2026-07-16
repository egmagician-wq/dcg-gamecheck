# v2.1 — مستشار الترقية + زرار المشاركة + آخر الفحوصات
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$p = Join-Path $root 'assets\gamecheck.js'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$js = [System.IO.File]::ReadAllText($p, $utf8)

$edits = @(
    # --- الدوال الجديدة (تُحقن قبل renderPopular) ---
    @{
        old = 'renderPopular(){const e=g(".gc-popular")'
        new = 'pushRecent(t,e){try{const r=JSON.parse(localStorage.getItem("dcg-gc-recent")||"[]").filter(o=>o.id!==t.id);r.unshift({id:t.id,n:t.nameAr,s:e.overallScore}),r.length>5&&(r.length=5),localStorage.setItem("dcg-gc-recent",JSON.stringify(r)),this.renderRecent()}catch{}}renderRecent(){try{const t=JSON.parse(localStorage.getItem("dcg-gc-recent")||"[]");let e=document.getElementById("gc-recent");if(!t.length){e&&e.remove();return}if(!e){e=document.createElement("div"),e.id="gc-recent";const r=document.querySelector(".gc-search-wrap");if(!r||!r.parentNode)return;r.parentNode.insertBefore(e,r.nextSibling)}e.innerHTML=`<span class="gc-recent-title">&#128337; آخر فحوصاتك:</span> `+t.map(r=>`<a class="gc-recent-chip" href="${this.checkUrl({game:r.id})}">${r.n} <b>${r.s}</b></a>`).join(" ")}catch{}}shareResult(t){const e=this.fullCheckUrl({game:t.game.id}),r="نتيجة فحص جهازي للعبة "+t.game.nameAr+": "+t.overallScore+"/100 — افحص جهازك أنت كمان: ";if(navigator.share)navigator.share({title:"GameCheck",text:r,url:e}).catch(()=>{});else if(navigator.clipboard)navigator.clipboard.writeText(r+e).then(()=>{const o=document.getElementById("gc-share-btn");o&&(o.textContent="✅ تم نسخ الرابط — الصقه لأصحابك")}).catch(()=>{window.prompt("انسخ الرابط:",e)});else window.prompt("انسخ الرابط:",e)}renderShareBtn(t){return`<div class="gc-share-row"><button type="button" id="gc-share-btn" class="gc-share-btn">&#128228; شارك نتيجتك مع أصحابك</button></div>`}renderUpgradeAdvisor(t){if(!this.specs)return"";const e=this.specs,r=this.siteGames||this.games,o=[{l:"زيادة الرام إلى 16 جيجا",c:e.ram<16,s:{...e,ram:16}},{l:"كرت شاشة من فئة GTX 1660 / RX 580",c:e.gpuScore<58,s:{...e,gpuScore:58}},{l:"معالج حديث من فئة i5",c:e.cpuScore<60,s:{...e,cpuScore:60}}].filter(a=>a.c).map(a=>{const c=r.filter(n=>{const s=U(e,n),m=U(a.s,n);return s.verdict==="fail"&&m.verdict!=="fail"});return{l:a.l,k:c.length,x:c.slice(0,3)}}).filter(a=>a.k>0).sort((a,c)=>c.k-a.k).slice(0,2);return o.length?`<div class="gc-upgrade-box"><strong>&#128161; مستشار الترقية — لو طوّرت جهازك:</strong><ul>`+o.map(a=>`<li>&#11014;&#65039; ${a.l} &larr; هتقدر تشغّل <b>${a.k} لعبة إضافية</b> من ألعاب موقعنا (مثل: ${a.x.map(c=>c.nameAr).join("، ")})</li>`).join("")+`</ul></div>`:""}renderPopular(){const e=g(".gc-popular")'
    },
    # --- زرار المشاركة بعد زرار التحميل ---
    @{
        old = '${this.renderCtaRow(e)}'
        new = '${this.renderCtaRow(e)}${this.renderShareBtn(e)}'
    },
    # --- مستشار الترقية قبل جدول معلومات اللعبة ---
    @{
        old = '${this.renderGameInfoBox(e)}'
        new = '${this.renderUpgradeAdvisor(e)}${this.renderGameInfoBox(e)}'
    },
    # --- ربط زرار المشاركة بعد رسم النتيجة ---
    @{
        old = 'r.querySelectorAll("a[data-id]").forEach('
        new = '(()=>{const b=r.querySelector("#gc-share-btn");b&&b.addEventListener("click",()=>this.shareResult(e))})(),r.querySelectorAll("a[data-id]").forEach('
    },
    # --- حفظ الفحص في آخر الفحوصات ---
    @{
        old = 'const a=U(this.specs,o);this.renderDetectBanner(),this.renderResult(a)'
        new = 'const a=U(this.specs,o);this.pushRecent(o,a),this.renderDetectBanner(),this.renderResult(a)'
    },
    # --- عرض شريط آخر الفحوصات عند فتح الصفحة ---
    @{
        old = 'this.renderSpiderLinks(),this.renderPopular(),window.addEventListener'
        new = 'this.renderSpiderLinks(),this.renderPopular(),this.renderRecent(),window.addEventListener'
    }
)

$i = 0
foreach ($e in $edits) {
    $i++
    if (-not $js.Contains($e.old)) { throw "v21: النص $i مش موجود" }
    $js = $js.Replace($e.old, $e.new)
    Write-Host "[OK] v21 تعديل $i"
}
[System.IO.File]::WriteAllText($p, $js, $utf8)
Write-Host "تم — v2.1"
