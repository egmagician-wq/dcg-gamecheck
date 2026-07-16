# ترقية v2.0 على assets/gamecheck.js:
# 1) benchmark حقيقي للمعالج وكرت الشاشة أثناء الفحص + مساحة القرص تلقائياً
# 2) اقتراحات ذكية: لو اللعبة مش هتشتغل، نرشح ألعاباً تعمل فعلاً على جهاز الزائر
# 3) "فحص ألعاب شائعة" (البلوكين) يتغير عشوائياً كل زيارة
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$p = Join-Path $root 'assets\gamecheck.js'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$js = [System.IO.File]::ReadAllText($p, $utf8)

$edits = @(
    # --- 1أ) دوال القياس الفعلي (تُحقن قبل دالة تقييم المعالج) ---
    @{
        old = 'function _(t,e){const r=(e||"").toLowerCase();'
        new = 'async function cpuBenchScore(){try{const t=performance.now();let e=0,r=0;for(;;){const o=performance.now()-t;if(o>=650)break;for(let a=0;a<1e5;a++)r+=Math.sqrt(a)*Math.sin(a%7);e+=1e5,e%5e5===0&&await new Promise(a=>setTimeout(a,0))}const n=performance.now()-t,s=e/Math.max(1,n);let m=Math.round(14*Math.log2(Math.max(2,s/500)));return m<15&&(m=15),m>95&&(m=95),r===1/0?m:m}catch{return 0}}function gpuBenchFps(){return new Promise(t=>{try{const e=document.createElement("canvas");e.width=512,e.height=512;const r=e.getContext("webgl");if(!r){t(0);return}const o=r.createShader(r.VERTEX_SHADER);r.shaderSource(o,"attribute vec2 p;void main(){gl_Position=vec4(p,0.,1.);}"),r.compileShader(o);const a=r.createShader(r.FRAGMENT_SHADER);r.shaderSource(a,"precision mediump float;uniform float u;void main(){float c=0.;for(int i=0;i<220;i++){c+=sin(float(i)*u+gl_FragCoord.x*.01)*cos(float(i)+gl_FragCoord.y*.01);}gl_FragColor=vec4(c*.001+.5,.4,.6,1.);}"),r.compileShader(a);const c=r.createProgram();r.attachShader(c,o),r.attachShader(c,a),r.linkProgram(c),r.useProgram(c);const n=r.createBuffer();r.bindBuffer(r.ARRAY_BUFFER,n),r.bufferData(r.ARRAY_BUFFER,new Float32Array([-1,-1,3,-1,-1,3]),r.STATIC_DRAW);const s=r.getAttribLocation(c,"p");r.enableVertexAttribArray(s),r.vertexAttribPointer(s,2,r.FLOAT,!1,0,0);const m=r.getUniformLocation(c,"u");let i=0;const l=performance.now(),p=()=>{const k=performance.now()-l;if(k>=1200){t(Math.round(i/(k/1e3)));return}r.uniform1f(m,k*.001);for(let w=0;w<6;w++)r.drawArrays(r.TRIANGLES,0,3);r.finish&&r.finish(),i++,requestAnimationFrame(p)};requestAnimationFrame(p)}catch{t(0)}})}async function diskFreeGb(){try{if(navigator.storage&&navigator.storage.estimate){const t=await navigator.storage.estimate();if(t&&t.quota)return Math.max(1,Math.round(t.quota/.6/1e9))}}catch{}return 0}function _(t,e){const r=(e||"").toLowerCase();'
    },
    # --- 1ب) دالة refineSpecs على الكلاس (تحدّث المواصفات بنتائج القياس) ---
    @{
        old = 'getScanEls(){const e=g("#gc-center")'
        new = 'async refineSpecs(){try{const t=this.specs;if(!t)return;const e=t.source==="auto",[r,o,a]=await Promise.all([e?cpuBenchScore():Promise.resolve(0),e?gpuBenchFps():Promise.resolve(0),!t.storage||t.storage<=0?diskFreeGb():Promise.resolve(0)]);r>0&&(t.cpuScore=Math.round(.5*t.cpuScore+.5*r),t.cpuName=(t.cores||4)+" أنوية — أداء مُقاس فعلياً"),o>0&&(t.gpuScore=Math.min(100,Math.max(5,Math.round(t.gpuScore*(o>=55?1.05:o>=35?.95:o>=20?.8:.6))))),a>0&&(t.storage=a,t.storageEst=!0),F(t),this.renderDetectBanner()}catch{}}getScanEls(){const e=g("#gc-center")'
    },
    # --- 1ج) تشغيل القياس الفعلي بالتوازي مع أنيميشن الفحص ---
    @{
        old = 'this.scanning=!0,this.startScanMode();try{await ee(r,e,E.SCAN_MS),await this.fadeOutScan()}finally{this.endScanMode()}'
        new = 'this.scanning=!0,this.startScanMode();try{await Promise.all([ee(r,e,E.SCAN_MS),this.refineSpecs()]),await this.fadeOutScan()}finally{this.endScanMode()}'
    },
    # --- 1د) الفحص التلقائي: نكتشف المواصفات قبل الفحص مش بعده (عشان القياس يشتغل عليها) ---
    @{
        old = 'async handleDetect(){const e=this.gameId?this.games.find(r=>r.id===this.gameId):null;await this.playScan(e?.nameAr),this.specs=this.autoDetect(),F(this.specs),'
        new = 'async handleDetect(){const e=this.gameId?this.games.find(r=>r.id===this.gameId):null;this.specs=this.autoDetect(),F(this.specs),await this.playScan(e?.nameAr),'
    },
    # --- 1هـ) عرض المساحة التقديرية في جدول المواصفات ---
    @{
        old = 'const r=this.specs.storage>0?`${this.specs.storage} GB`:"غير محددة — أدخلها من تخصيص الفحص"'
        new = 'const r=this.specs.storage>0?(this.specs.storageEst?`≈ ${this.specs.storage} GB (تقديرية)`:`${this.specs.storage} GB`):"غير محددة — أدخلها من تخصيص الفحص"'
    },
    # --- 2أ) اقتراحات ذكية مبنية على جهاز الزائر ---
    @{
        old = 'getRelatedSuggestions(e,r){const o=[],a=new Set([e.id]),c=s=>{!s||a.has(s.id)||(a.add(s.id),o.push(s))};return e.alternatives?.forEach(s=>c(this.games.find(m=>m.id===s.id))),r<=75&&this.specs&&this.games.filter(m=>m.id!==e.id&&m.weight!=="heavy").map(m=>({g:m,s:U(this.specs,m).overallScore})).filter(m=>m.s>=80).sort((m,i)=>i.s-m.s).forEach(m=>c(m.g)),this.games.filter(s=>s.category===e.category&&s.id!==e.id).forEach(s=>c(s)),te.forEach(s=>c(this.games.find(m=>m.id===s))),o.slice(0,8)}'
        new = 'getRelatedSuggestions(e,r){const o=[],a=new Set([e.id]),c=s=>{!s||a.has(s.id)||(a.add(s.id),o.push(s))};if(this.specs&&r<80){const n=this.games.filter(m=>m.id!==e.id&&this.hasRealArticle(m)).map(m=>({g:m,f:U(this.specs,m)})).filter(m=>m.f.verdict!=="fail").sort((m,i)=>{const l=(m.g.category===e.category?0:1)-(i.g.category===e.category?0:1);return l!==0?l:i.f.overallScore-m.f.overallScore});e.alternatives?.forEach(s=>{const m=n.find(i=>i.g.id===s.id);m&&c(m.g)}),n.forEach(s=>c(s.g))}else e.alternatives?.forEach(s=>c(this.games.find(m=>m.id===s.id))),this.games.filter(s=>s.category===e.category&&s.id!==e.id).forEach(s=>c(s)),te.forEach(s=>c(this.games.find(m=>m.id===s)));return o.slice(0,8)}'
    },
    # --- 2ب) عنوان الاقتراحات حسب الحالة ---
    @{
        old = 'renderSuggestLinks(e,r){if(r>=80)return"";const o=e.filter(a=>this.hasRealArticle(a)).slice(0,10);return this.renderDownloadChips("ألعاب مقترحة",o)}'
        new = 'renderSuggestLinks(e,r){if(r>=80)return"";const o=e.filter(a=>this.hasRealArticle(a)).slice(0,10);return this.renderDownloadChips(r<55?"بدائل أخف تعمل على جهازك بسلاسة":"ألعاب مقترحة تناسب جهازك",o,r<55?"مرتبة حسب توافقها مع مواصفات جهازك":"")}'
    },
    # --- 3أ) قائمة "فحص متطلبات ألعاب شائعة" تتخلط عشوائياً كل زيارة ---
    @{
        old = 'const r=["gta-v","cyberpunk-2077","red-dead-2","valorant","minecraft","elden-ring","fortnite","cs2","witcher-3","god-of-war","baldurs-gate-3","hogwarts-legacy","warzone","the-last-of-us-1","lol","palworld","forza-horizon-5","genshin","the-sims-4","helldivers-2","pes-2018","pes-2013","fifa-18","gta-sa","cod4","ea-fc-25","marvel-rivals","spider-man-remastered"],o=new Set,a=[];for(const c of r){const n=this.games.find(s=>s.id===c);n&&!o.has(n.id)&&(o.add(n.id),a.push(n))}for(const c of this.games)if(!o.has(c.id)&&(o.add(c.id),a.push(c),a.length>=60))break;'
        new = 'const a=[...this.games];for(let c=a.length-1;c>0;c--){const n=Math.floor(Math.random()*(c+1)),s=a[c];a[c]=a[n],a[n]=s}a.length>60&&(a.length=60);'
    },
    # --- 3ب) روابط "فحص ألعاب شائعة" العلوية تتغير عشوائياً كل زيارة ---
    @{
        old = 'renderSpiderLinks(){let e=document.getElementById("gc-spider")'
        new = 'renderPopular(){const e=g(".gc-popular");if(!e)return;const r=this.games.filter(o=>this.hasRealArticle(o)),a=[...(r.length>=8?r:this.games)];for(let o=a.length-1;o>0;o--){const c=Math.floor(Math.random()*(o+1)),n=a[o];a[o]=a[c],a[c]=n}e.innerHTML=a.slice(0,8).map(o=>`<a class="internal-link" href="?game=${o.id}">هل جهازي يشغّل ${o.nameAr}${h}</a>`).join("")}renderSpiderLinks(){let e=document.getElementById("gc-spider")'
    },
    @{
        old = 'this.renderSpiderLinks(),window.addEventListener("popstate"'
        new = 'this.renderSpiderLinks(),this.renderPopular(),window.addEventListener("popstate"'
    }
)

$i = 0
foreach ($e in $edits) {
    $i++
    if (-not $js.Contains($e.old)) {
        throw "التعديل رقم $i — النص الأصلي مش موجود: $($e.old.Substring(0, [Math]::Min(70, $e.old.Length)))"
    }
    $js = $js.Replace($e.old, $e.new)
    Write-Host "[OK] تعديل $i"
}

[System.IO.File]::WriteAllText($p, $js, $utf8)
Write-Host "`nتم حفظ gamecheck.js (v2.0)"
