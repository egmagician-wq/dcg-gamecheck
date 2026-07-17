# v2.4 — 3 إصلاحات:
# 1) تعديل المواصفات يدوياً يظهر في نفس المكان (بدون سكرول إجباري)
# 2) توحيد الروابط: كل التنقل الداخلي يبني مسارات نظيفة /check/<id>/ بدل ?game= لما الووركر يدعمها
# 3) الشريط بيعلق عند 0%: كان سببه انتظار تحميل الكتالوج (fetch) قبل بدء الأنيميشن — بيتلغي لو الووركر بعت الكتالوج جاهز في الصفحة، وبيتوازى (مش متسلسل) لو لسه محتاج fetch
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$p = Join-Path $root 'assets\gamecheck.js'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$js = [System.IO.File]::ReadAllText($p, $utf8)

$edits = @(
    # --- 3) loadCatalog: استخدام كتالوج جاهز من الصفحة لو موجود + توازي الجلب بدل التسلسل ---
    @{
        old = 'async loadCatalog(){this.gpuMap=K,this.games=q.games;try{const[e,r]=await Promise.all([fetch(re,{cache:"no-cache"}),fetch(oe,{cache:"no-cache"})]);if(e.ok){const o=await e.json();o.games?.length&&(this.games=o.games)}r.ok&&(this.gpuMap=await r.json())}catch{}this.reqPosts={};try{const n=await fetch("https://cdn.jsdelivr.net/gh/egmagician-wq/dcg-gamecheck@main/data/req-posts.json",{cache:"no-cache"});n.ok&&(this.reqPosts=await n.json())}catch{}this.siteGames=this.games.filter(t=>this.hasRealArticle(t)),this.siteGames.length||(this.siteGames=this.games)}'
        new = 'async loadCatalog(){if(this.gpuMap=K,this.games=q.games,this.reqPosts={},window.__GC_CATALOG__){const w=window.__GC_CATALOG__;w.games?.length&&(this.games=w.games),w.gpuMap&&(this.gpuMap=w.gpuMap),w.reqPosts&&(this.reqPosts=w.reqPosts)}else try{const[e,r,n]=await Promise.all([fetch(re,{cache:"no-cache"}),fetch(oe,{cache:"no-cache"}),fetch("https://cdn.jsdelivr.net/gh/egmagician-wq/dcg-gamecheck@main/data/req-posts.json",{cache:"no-cache"})]);if(e.ok){const o=await e.json();o.games?.length&&(this.games=o.games)}r.ok&&(this.gpuMap=await r.json()),n.ok&&(this.reqPosts=await n.json())}catch{}this.siteGames=this.games.filter(t=>this.hasRealArticle(t)),this.siteGames.length||(this.siteGames=this.games)}'
    },
    # --- 2أ) دوال مساعدة: كشف دعم المسارات النظيفة + استخراج معرف اللعبة من المسار ---
    @{
        old = '}return d}checkUrl(e={}){const r=this.getCheckBase(),o=new URL(r,window.location.origin);this.gameId&&!e.game&&!e.view&&o.searchParams.set("game",this.gameId);for(const[a,c]of Object.entries(e))c?o.searchParams.set(a,c):o.searchParams.delete(a);return o.pathname+o.search}fullCheckUrl(e={}){const r=this.getCheckBase(),o=new URL(r);for(const[a,c]of Object.entries(e))c&&o.searchParams.set(a,c);return o.toString()}'
        new = '}return d}supportsCleanPaths(){try{const t=new URL(this.getCheckBase());return t.pathname===""||t.pathname==="/"||t.pathname==="/check"}catch{return!1}}getGameIdFromLocation(){const t=new URLSearchParams(window.location.search);let e=t.get("game")||t.get("id");if(e)return e;if(!this.supportsCleanPaths())return null;let r="";try{r=new URL(this.getCheckBase()).pathname}catch{}let o=window.location.pathname;r&&o.startsWith(r)&&(o=o.slice(r.length)),o=o.replace(/^\/+|\/+$/g,"");return o&&!o.includes("/")?o:null}checkUrl(e={}){const r=this.getCheckBase(),n=e.game!==void 0?e.game:!e.view&&this.gameId?this.gameId:null;if(n&&!e.view&&this.supportsCleanPaths()){const o=new URL(r.replace(/\/$/,"")+"/"+n+"/",window.location.origin);for(const[a,c]of Object.entries(e))a!=="game"&&a!=="id"&&(c?o.searchParams.set(a,c):o.searchParams.delete(a));return o.pathname+o.search}const o=new URL(r,window.location.origin);this.gameId&&!e.game&&!e.view&&o.searchParams.set("game",this.gameId);for(const[a,c]of Object.entries(e))c?o.searchParams.set(a,c):o.searchParams.delete(a);return o.pathname+o.search}fullCheckUrl(e={}){const r=this.getCheckBase(),n=e.game!==void 0?e.game:null;if(n&&!e.view&&this.supportsCleanPaths()){const o=new URL(r.replace(/\/$/,"")+"/"+n+"/");for(const[a,c]of Object.entries(e))a!=="game"&&a!=="id"&&c&&o.searchParams.set(a,c);return o.toString()}const o=new URL(r);for(const[a,c]of Object.entries(e))c&&o.searchParams.set(a,c);return o.toString()}'
    },
    # --- 2ب) onPopState: استخدام نفس دالة استخراج المعرف (مسار أو باراميتر) ---
    @{
        old = 'async onPopState(){const e=new URLSearchParams(window.location.search);if(this.gameId=e.get("game")||e.get("id"),this.view=e.get("view")==="my-games"?"my-games":"check",this.view==="my-games"){this.showMyGames();return}'
        new = 'async onPopState(){const e=new URLSearchParams(window.location.search);if(this.gameId=this.getGameIdFromLocation(),this.view=e.get("view")==="my-games"?"my-games":"check",this.view==="my-games"){this.showMyGames();return}'
    },
    # --- 2ج) renderPopular: رابط مبني صح (مطلق) بدل href="?game=" النسبي الخاطئ على صفحات الألعاب ---
    @{
        old = 'e.innerHTML=a.slice(0,8).map(o=>`<a class="internal-link" href="?game=${o.id}">هل جهازي يشغّل ${o.nameAr}${h}</a>`).join("")}'
        new = 'e.innerHTML=a.slice(0,8).map(o=>`<a class="internal-link" href="${this.checkUrl({game:o.id})}">هل جهازي يشغّل ${o.nameAr}${h}</a>`).join("")}'
    },
    # --- 1أ) نقل بلوك "تعديل المواصفات يدوياً" ليجاور كارت المواصفات (مرة واحدة) ---
    @{
        old = 'renderDetectBanner(){const e=g("#detect-banner");if(!e||!this.specs)return;let eb=document.getElementById("gc-edit-bar");eb||(eb=document.createElement("div"),eb.id="gc-edit-bar",e.parentNode&&e.parentNode.insertBefore(eb,e.nextSibling)),eb.innerHTML='
        new = 'renderDetectBanner(){const e=g("#detect-banner");if(!e||!this.specs)return;let eb=document.getElementById("gc-edit-bar");eb||(eb=document.createElement("div"),eb.id="gc-edit-bar",e.parentNode&&e.parentNode.insertBefore(eb,e.nextSibling));if(!eb.dataset.wired){eb.dataset.wired="1";const adv=document.getElementById("advanced-panel"),man=adv&&adv.querySelector(".gc-nested");man&&eb.parentNode&&(man.classList.add("gc-manual-inline"),eb.parentNode.insertBefore(man,eb.nextSibling))}eb.innerHTML='
    },
    # --- 1ب) الضغط على "عدّلها يدوياً": فتح/إغلاق البلوك المجاور بدل السكرول لأسفل ---
    @{
        old = 'document.addEventListener("click",t=>{const n=t.target&&t.target.closest?t.target.closest("#gc-edit-specs"):null;if(!n)return;t.preventDefault();const s=g("#advanced-panel");if(s){s.open=!0;const m=s.querySelector(".gc-nested");m&&(m.open=!0),s.scrollIntoView({behavior:"smooth",block:"start"})}}),'
        new = 'document.addEventListener("click",t=>{const n=t.target&&t.target.closest?t.target.closest("#gc-edit-specs"):null;if(!n)return;t.preventDefault();const m=document.querySelector(".gc-manual-inline")||g("#advanced-panel")?.querySelector(".gc-nested");m&&(m.open=!m.open,m.open&&m.scrollIntoView({behavior:"smooth",block:"nearest"}))}),'
    }
)

$i = 0
foreach ($e in $edits) {
    $i++
    if (-not $js.Contains($e.old)) { throw "v24: النص $i مش موجود" }
    $js = $js.Replace($e.old, $e.new)
    Write-Host "[OK] v24 تعديل $i"
}
[System.IO.File]::WriteAllText($p, $js, $utf8)
Write-Host "تم — 3 إصلاحات"
