# تلميع SEO:
# 1) إلغاء تكرار الـ Schema: السكيما الديناميكية للأسئلة تشتغل فقط مع ?game=
#    (الصفحة الرئيسية تكتفي بالسكيما الثابتة في الـ HTML — جوجل يرفض تكرار FAQPage)
# 2) إلغاء حقن WebApplication schema المكرر (الثابتة موجودة في الـ HTML)
# 3) روابط "فحص متطلبات ألعاب شائعة": مقالات المتطلبات المنشورة تتثبت في الأول
#    (روابط حقيقية ثابتة للزحف)، والباقي هو اللي يتخلط عشوائياً
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$p = Join-Path $root 'assets\gamecheck.js'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$js = [System.IO.File]::ReadAllText($p, $utf8)

$edits = @(
    @{
        old = 'injectFaqSchema(){const r={"@context"'
        new = 'injectFaqSchema(){if(!this.gameId){const t=document.getElementById("gc-faq-schema");t&&t.remove();return}const r={"@context"'
    },
    @{
        old = 'this.renderFaq(),this.injectFaqSchema(),this.injectWebAppSchema(),this.renderSpiderLinks()'
        new = 'this.renderFaq(),this.injectFaqSchema(),this.renderSpiderLinks()'
    },
    @{
        old = 'const a=[...this.games];for(let c=a.length-1;c>0;c--){const n=Math.floor(Math.random()*(c+1)),s=a[c];a[c]=a[n],a[n]=s}a.length>60&&(a.length=60);'
        new = 'const rp=this.reqPosts||{},pr=this.games.filter(c=>rp[c.id]),rs=this.games.filter(c=>!rp[c.id]);for(let c=rs.length-1;c>0;c--){const n=Math.floor(Math.random()*(c+1)),s=rs[c];rs[c]=rs[n],rs[n]=s}const a=[...pr,...rs];a.length>60&&(a.length=60);'
    }
)

$i = 0
foreach ($e in $edits) {
    $i++
    if (-not $js.Contains($e.old)) { throw "seo: النص $i مش موجود" }
    $js = $js.Replace($e.old, $e.new)
    Write-Host "[OK] seo تعديل $i"
}
[System.IO.File]::WriteAllText($p, $js, $utf8)
Write-Host "تم"
