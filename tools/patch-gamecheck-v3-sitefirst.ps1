# v3 — ألعاب الموقع هي الأساس:
# كل الواجهات المرئية (البحث، القائمة المنسدلة، الألعاب الشائعة، "ألعاب تناسب جهازي")
# تعرض فقط الألعاب اللي ليها مقال تحميل حقيقي على الموقع (143 لعبة).
# الروابط المباشرة ?game= لباقي الألعاب تفضل شغالة (لخطة مقالات المتطلبات المستقبلية).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$p = Join-Path $root 'assets\gamecheck.js'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$js = [System.IO.File]::ReadAllText($p, $utf8)

$edits = @(
    @{
        old = 'n.ok&&(this.reqPosts=await n.json())}catch{}}async onPopState(){'
        new = 'n.ok&&(this.reqPosts=await n.json())}catch{}this.siteGames=this.games.filter(t=>this.hasRealArticle(t)),this.siteGames.length||(this.siteGames=this.games)}async onPopState(){'
    },
    @{
        old = 'const a=(e.value||"").trim().toLowerCase(),c=(a?this.games.filter(n=>n.name.toLowerCase().includes(a)||n.nameAr.includes(a)||n.id.includes(a)):this.games.slice(0,10)).slice(0,12);'
        new = 'const a=(e.value||"").trim().toLowerCase(),sg=this.siteGames||this.games,c=(a?sg.filter(n=>n.name.toLowerCase().includes(a)||n.nameAr.includes(a)||n.id.includes(a)):sg.slice(0,10)).slice(0,12);'
    },
    @{
        old = '<option value="">— اختر لعبة —</option>''+this.games.map('
        new = '<option value="">— اختر لعبة —</option>''+(this.siteGames||this.games).map('
    },
    @{
        old = 'const rp=this.reqPosts||{},pr=this.games.filter(c=>rp[c.id]),rs=this.games.filter(c=>!rp[c.id]);'
        new = 'const rp=this.reqPosts||{},pr=this.games.filter(c=>rp[c.id]),sg=this.siteGames||this.games,rs=sg.filter(c=>!rp[c.id]);'
    },
    @{
        old = '=B(this.specs,this.games)'
        new = '=B(this.specs,this.siteGames||this.games)'
    }
)

$i = 0
foreach ($e in $edits) {
    $i++
    if (-not $js.Contains($e.old)) { throw "v3: النص $i مش موجود" }
    $js = $js.Replace($e.old, $e.new)
    Write-Host "[OK] v3 تعديل $i"
}
[System.IO.File]::WriteAllText($p, $js, $utf8)
Write-Host "تم — ألعاب الموقع بقت الأساس"
