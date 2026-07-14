# ============================================================
# generate-seo-content.ps1
# يولّد محتوى SEO جاهز للصق في بلوجر من كتالوج GameCheck:
#   out\posts\<id>.html      مقال "متطلبات تشغيل" كامل (بوست جديد)
#   out\posts\<id>.meta.txt  العنوان + الرابط الثابت + الوصف + الـ labels
#   out\sections\<id>.html   بلوك مختصر يُلصق داخل مقال التحميل الموجود
#
# الاستخدام:
#   .\tools\generate-seo-content.ps1              # كل الألعاب اللي ليها realSpecs
#   .\tools\generate-seo-content.ps1 -Ids gta-v,pes-2018
# ============================================================
param(
    [string[]]$Ids
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$toolUrl = 'https://www.downloadcomputergames.net/p/gamecheck.html'

# ---------- تحميل البيانات ----------
$catalog   = (Get-Content (Join-Path $root 'data\game-requirements.json') -Raw -Encoding UTF8 | ConvertFrom-Json).games
$realSpecs = Get-Content (Join-Path $root 'data\real-specs.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$gpuMap    = (Get-Content (Join-Path $root 'data\gpu-map.json') -Raw -Encoding UTF8 | ConvertFrom-Json).gpus

$outPosts    = Join-Path $root 'out\posts'
$outSections = Join-Path $root 'out\sections'
New-Item -ItemType Directory -Force $outPosts | Out-Null
New-Item -ItemType Directory -Force $outSections | Out-Null

$utf8 = New-Object System.Text.UTF8Encoding($false)

function Write-Utf8([string]$path, [string]$content) {
    [System.IO.File]::WriteAllText($path, $content, $utf8)
}

function Escape-Json([string]$s) {
    if ($null -eq $s) { return '' }
    return $s.Replace('\', '\\').Replace('"', '\"').Replace("`r", '').Replace("`n", ' ')
}

function Escape-Html([string]$s) {
    if ($null -eq $s) { return '' }
    return $s.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')
}

# ---------- ستايلات الجداول (inline عشان تشتغل في أي قالب بلوجر) ----------
$tableStyle = 'width:100%;border-collapse:collapse;margin:12px 0;font-size:15px'
$thStyle    = 'background:#5b7178;color:#fff;padding:9px 8px;border:1px solid #4a5d63;text-align:right'
$tdStyle    = 'background:#f5f5f5;color:#333;padding:9px 8px;border:1px solid #ddd;text-align:right'
$ctaStyle   = 'display:inline-block;background:#206155;color:#fff;padding:12px 26px;border-radius:4px;font-weight:700;text-decoration:none;font-size:16px'

# ---------- جدول المتطلبات (الحد الأدنى / الموصى به) ----------
function New-ReqTable($g, $rs) {
    $rows = @(
        @('نظام التشغيل',      $rs.min.os,      $rs.rec.os),
        @('المعالج (CPU)',     $rs.min.cpu,     $rs.rec.cpu),
        @('كرت الشاشة (GPU)',  $rs.min.gpu,     $rs.rec.gpu),
        @('الذاكرة (RAM)',     $rs.min.ram,     $rs.rec.ram),
        @('مساحة التخزين',     $rs.min.storage, $rs.rec.storage),
        @('DirectX',           $rs.min.dx,      $rs.rec.dx)
    )
    $body = ''
    foreach ($r in $rows) {
        $body += "<tr><th scope=""row"" style=""$thStyle"">$(Escape-Html $r[0])</th><td style=""$tdStyle"">$(Escape-Html $r[1])</td><td style=""$tdStyle"">$(Escape-Html $r[2])</td></tr>`n"
    }
    return @"
<table style="$tableStyle">
<thead><tr><th style="$thStyle">المكوّن</th><th style="$thStyle">الحد الأدنى</th><th style="$thStyle">الموصى به</th></tr></thead>
<tbody>
$body</tbody>
</table>
"@
}

# ---------- جدول الأداء المتوقع FPS حسب كرت الشاشة ----------
function New-FpsTable($g) {
    $weightFactor = 1.0
    if ($g.weight -eq 'light') { $weightFactor = 1.15 }
    if ($g.weight -eq 'heavy') { $weightFactor = 0.85 }

    $tiers = $gpuMap | Where-Object { $_.score -in @(12, 18, 28, 38, 45, 58, 72, 82) }
    $rows = ''
    foreach ($t in $tiers) {
        $ratio = $t.score / [double]$g.rec.gpuScore
        if ($ratio -gt 1.2) { $ratio = 1.2 }
        $fps = $g.baseFps.rec * $ratio * $weightFactor
        $lo = [Math]::Max(15, [Math]::Round($fps * 0.75))
        $hi = [Math]::Round($fps * 1.1)

        if ($t.score -ge $g.rec.gpuScore)     { $verdict = '&#9989; ممتاز — إعدادات عالية' }
        elseif ($t.score -ge $g.min.gpuScore) { $verdict = '&#9888;&#65039; جيد — إعدادات متوسطة/منخفضة' }
        else                                  { $verdict = '&#10060; أضعف من الحد الأدنى' }

        if ($t.score -lt $g.min.gpuScore) { $fpsTxt = '&mdash;' }
        else { $fpsTxt = "$lo&ndash;$hi FPS" }

        $rows += "<tr><th scope=""row"" style=""$thStyle"">$(Escape-Html $t.label)</th><td style=""$tdStyle"">$fpsTxt</td><td style=""$tdStyle"">$verdict</td></tr>`n"
    }
    return @"
<table style="$tableStyle">
<thead><tr><th style="$thStyle">كرت الشاشة</th><th style="$thStyle">FPS المتوقع تقريباً</th><th style="$thStyle">التقييم</th></tr></thead>
<tbody>
$rows</tbody>
</table>
<p style="font-size:13px;color:#777">* الأرقام تقديرية على دقة 1080p وتختلف حسب المعالج والرام وإعدادات اللعبة — استخدم <a href="${toolUrl}?game=$($g.id)">أداة الفحص</a> لتقدير أدق لجهازك.</p>
"@
}

# ---------- الأسئلة الشائعة ----------
function New-Faq($g, $rs) {
    $nameAr = $g.nameAr
    $faq = @()

    $faq += @{
        q = "ما هي متطلبات تشغيل $nameAr على الكمبيوتر؟"
        a = "الحد الأدنى لتشغيل $nameAr هو: معالج $($rs.min.cpu)، رام $($rs.min.ram)، كرت شاشة $($rs.min.gpu)، ومساحة $($rs.min.storage) على نظام $($rs.min.os)."
    }

    $minRamNum = 0
    if ("$($rs.min.ram)" -match '(\d+)') { $minRamNum = [int]$Matches[1] }
    if ($minRamNum -le 4) {
        $faq += @{
            q = "هل تعمل $nameAr على جهاز بـ 4 جيجا رام؟"
            a = "نعم — الحد الأدنى الرسمي للعبة هو $($rs.min.ram)، وجهاز بـ 4GB رام يشغّلها بإعدادات منخفضة إلى متوسطة مع إغلاق البرامج الأخرى أثناء اللعب."
        }
    } else {
        $faq += @{
            q = "هل تعمل $nameAr على جهاز بـ 4 جيجا رام؟"
            a = "لا يُنصح بذلك — اللعبة تحتاج $($rs.min.ram) رام كحد أدنى رسمي، وبـ 4GB ستواجه تقطيعاً حاداً أو لن تعمل إطلاقاً."
        }
    }

    if ($g.min.gpuScore -le 18) {
        $faq += @{
            q = "هل تعمل $nameAr بكرت الشاشة المدمج (بدون كرت خارجي)؟"
            a = "نعم — $nameAr من الألعاب التي تعمل على كروت الشاشة المدمجة مثل Intel HD بإعدادات منخفضة، لكن كرت شاشة منفصل يمنحك تجربة أفضل بكثير."
        }
    } else {
        $faq += @{
            q = "هل تعمل $nameAr بكرت الشاشة المدمج (بدون كرت خارجي)؟"
            a = "الكروت المدمجة القديمة أضعف من الحد الأدنى المطلوب ($($rs.min.gpu)) — ستحتاج كرت شاشة منفصلاً أو معالجاً حديثاً برسوميات قوية لتشغيلها."
        }
    }

    $faq += @{
        q = "كم تبلغ مساحة $nameAr على الهارد؟"
        a = "تحتاج اللعبة مساحة فارغة حوالي $($rs.rec.storage) — تأكد من توفرها على القرص قبل التحميل."
    }

    $faq += @{
        q = "كيف أعرف إذا كان جهازي يشغّل $nameAr قبل التحميل؟"
        a = "استخدم أداة GameCheck المجانية على موقعنا — تفحص مواصفات جهازك تلقائياً من المتصفح وتقارنها بمتطلبات $nameAr وتعطيك نتيجة من 100 مع تقدير FPS."
    }

    # HTML
    $html = "<h2>أسئلة شائعة عن متطلبات $(Escape-Html $nameAr)</h2>`n"
    foreach ($f in $faq) {
        $html += "<h3>$(Escape-Html $f.q)</h3>`n<p>$(Escape-Html $f.a)</p>`n"
    }

    # JSON-LD (يدوي عشان النص العربي يفضل مقروءاً)
    $items = @()
    foreach ($f in $faq) {
        $items += '{"@type":"Question","name":"' + (Escape-Json $f.q) + '","acceptedAnswer":{"@type":"Answer","text":"' + (Escape-Json $f.a) + '"}}'
    }
    $schema = '<script type="application/ld+json">{"@context":"https://schema.org","@type":"FAQPage","mainEntity":[' + ($items -join ',') + ']}</script>'

    return ($html + $schema)
}

# ---------- روابط داخلية لألعاب من نفس التصنيف ----------
function New-RelatedLinks($g) {
    $related = $catalog | Where-Object {
        $_.category -eq $g.category -and $_.id -ne $g.id -and $_.downloadUrl -match 'downloadcomputergames\.net/\d{4}/\d{2}/'
    } | Select-Object -First 4
    if (-not $related) { return '' }
    $links = ''
    foreach ($r in $related) {
        $links += "<li><a href=""$($r.downloadUrl)"">تحميل لعبة $(Escape-Html $r.nameAr) للكمبيوتر</a></li>`n"
    }
    return @"
<h2>ألعاب مشابهة قد تناسب جهازك</h2>
<ul>
$links</ul>
"@
}

# ---------- بلوك الفحص (CTA) ----------
function New-CtaBlock($g) {
    return @"
<div style="text-align:center;background:#eef5f3;border:1px solid #cfe3de;border-radius:6px;padding:20px;margin:18px 0">
<p style="font-weight:700;font-size:17px;margin:0 0 12px">هل جهازك يشغّل $(Escape-Html $g.nameAr)؟ اعرف في 5 ثوانٍ</p>
<p style="margin:0 0 14px">أداة GameCheck تفحص المعالج وكرت الشاشة والرام تلقائياً من المتصفح، وتقارنها بمتطلبات اللعبة وتعطيك نتيجة من 100 مع تقدير FPS — مجاناً وبدون تحميل برامج.</p>
<a class="downloadpcgame" href="${toolUrl}?game=$($g.id)" style="$ctaStyle">&#128269; افحص جهازك الآن</a>
</div>
"@
}

# ---------- توليد المقال الكامل (بوست جديد) ----------
function New-Post($g, $rs) {
    $nameAr = Escape-Html $g.nameAr
    $nameEn = Escape-Html $g.name
    $variants = ($rs.kwVariants | Select-Object -Skip 1) -join '، '
    $today = Get-Date -Format 'yyyy/MM/dd'

    $img = ''
    if ($g.imageUrl) {
        $img = "<div style=""text-align:center""><img src=""$($g.imageUrl)"" alt=""متطلبات تشغيل $nameAr على الكمبيوتر"" title=""متطلبات تشغيل $nameAr"" style=""max-width:100%;border-radius:6px"" /></div>`n"
    }

    $downloadBlock = ''
    if ($g.downloadUrl -match 'downloadcomputergames\.net/\d{4}/\d{2}/') {
        $downloadBlock = @"
<h2>تحميل $nameAr للكمبيوتر</h2>
<p>بعد ما تتأكد أن جهازك يشغّل اللعبة، يمكنك تحميلها مباشرة من مقال التحميل الكامل على موقعنا:</p>
<p style="text-align:center"><a class="downloadpcgame" href="$($g.downloadUrl)" style="$ctaStyle">&#11015;&#65039; تحميل لعبة $nameAr للكمبيوتر</a></p>
"@
    }

    $notes = ''
    if ($rs.notes) {
        $notes = "<p><strong>ملاحظة:</strong> $(Escape-Html $rs.notes)</p>`n"
    }

    return @"
<!-- متطلبات تشغيل $nameAr — مولّد تلقائياً بتاريخ $today من dcg-gamecheck -->
$img
<p>تبحث عن <strong>متطلبات تشغيل $nameAr</strong> ($nameEn) على الكمبيوتر؟ في هذا الدليل ستجد <strong>الحد الأدنى والمواصفات الموصى بها</strong> بالتفصيل من المصدر الرسمي ($(Escape-Html $rs.publisher))، مع جدول <strong>الأداء المتوقع (FPS)</strong> حسب كرت الشاشة، وأداة مجانية تفحص جهازك في ثوانٍ وتخبرك: <strong>هل جهازك يشغّل $nameAr أم لا؟</strong> — وتُعرف اللعبة أيضاً باسم: $variants.</p>

<h2>متطلبات تشغيل $nameAr على الكمبيوتر</h2>
$(New-ReqTable $g $rs)
$notes
<p><strong>الفرق ببساطة:</strong> الحد الأدنى يعني أن اللعبة ستعمل بإعدادات منخفضة (حوالي $($g.baseFps.min) FPS)، أما المواصفات الموصى بها فتعني لعباً سلساً بدون تقطيع على إعدادات متوسطة إلى عالية ($($g.baseFps.rec) FPS أو أكثر).</p>

$(New-CtaBlock $g)

<h2>الأداء المتوقع حسب كرت الشاشة</h2>
$(New-FpsTable $g)

$downloadBlock
$(New-Faq $g $rs)
$(New-RelatedLinks $g)
<p style="font-size:13px;color:#777">آخر تحديث للمتطلبات: $today — المصدر: المتطلبات الرسمية من $(Escape-Html $rs.publisher).</p>
"@
}

# ---------- توليد بلوك المقال الموجود ----------
function New-Section($g, $rs) {
    $nameAr = Escape-Html $g.nameAr
    return @"
<!-- بلوك متطلبات التشغيل — يُلصق داخل مقال تحميل $nameAr (وضع HTML في محرر بلوجر) -->
<h2>متطلبات تشغيل $nameAr على الكمبيوتر</h2>
<p>قبل التحميل، تأكد أن جهازك يلبي <strong>متطلبات تشغيل $nameAr</strong> — هذا الجدول يوضح الحد الأدنى والمواصفات الموصى بها رسمياً:</p>
$(New-ReqTable $g $rs)
$(New-CtaBlock $g)
"@
}

# ---------- ملف الميتا ----------
function New-Meta($g, $rs) {
    $title = "متطلبات تشغيل $($g.nameAr) على الكمبيوتر — الحد الأدنى والموصى به"
    $desc = "تعرف على متطلبات تشغيل $($g.nameAr) ($($g.name)) للكمبيوتر: الحد الأدنى والموصى به، الأداء المتوقع FPS، وافحص هل جهازك يشغلها مجاناً."
    return @"
=== عنوان البوست (Title) ===
$title

=== الرابط الثابت المقترح (Custom Permalink) ===
system-requirements-$($g.id)

=== وصف البحث (Search Description) ===
$desc

=== التصنيفات (Labels) ===
متطلبات تشغيل الألعاب, $($g.category)

=== روابط داخلية مطلوبة بعد النشر ===
1) أضف رابط هذا البوست داخل مقال التحميل: $($g.downloadUrl)
2) اطلب فهرسة الرابط من Google Search Console بعد النشر مباشرة.
3) أضف رابط البوست المنشور في data/req-posts.json بالشكل: "$($g.id)": "رابط-البوست" — عشان روابط (فحص ألعاب شائعة) في صفحة الأداة تتحول له تلقائياً.
"@
}

# ---------- التنفيذ ----------
$targetIds = $realSpecs.PSObject.Properties.Name | Where-Object { $_ -ne '_comment' }
if ($Ids) { $targetIds = $targetIds | Where-Object { $_ -in $Ids } }

$done = 0
foreach ($id in $targetIds) {
    $g = $catalog | Where-Object id -eq $id
    if (-not $g) { Write-Warning "id غير موجود في الكتالوج: $id"; continue }
    $rs = $realSpecs.$id

    Write-Utf8 (Join-Path $outPosts "$id.html")     (New-Post $g $rs)
    Write-Utf8 (Join-Path $outPosts "$id.meta.txt") (New-Meta $g $rs)
    Write-Utf8 (Join-Path $outSections "$id.html")  (New-Section $g $rs)
    $done++
    Write-Host "[OK] $id — $($g.nameAr)"
}
Write-Host "`nتم توليد $done لعبة => out\posts + out\sections"
