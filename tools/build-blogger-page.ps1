# يبني صفحة بلوجر الرئيسية (gamecheck) بنفس فكرتها الأصلية:
# الغلاف (ستايل + سكيما + هيكل الصفحة) + كود التطبيق مدموجاً من assets/gamecheck.js
# الناتج: out\page\gamecheck-page.html — جاهز للصق في محرر صفحة بلوجر (وضع HTML)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

$top    = [System.IO.File]::ReadAllText((Join-Path $root 'tools\templates\page-top.html'), $utf8)
$js     = [System.IO.File]::ReadAllText((Join-Path $root 'assets\gamecheck.js'), $utf8)
$bottom = [System.IO.File]::ReadAllText((Join-Path $root 'tools\templates\page-bottom.html'), $utf8)

if ($js.Contains('</script')) { throw 'assets/gamecheck.js يحتوي على </script — لا يمكن دمجه inline بأمان' }

$page = $top.TrimEnd() + "`n" + $js.TrimEnd() + "`n</script>`n`n" + $bottom

$outDir = Join-Path $root 'out\page'
New-Item -ItemType Directory -Force $outDir | Out-Null
$outFile = Join-Path $outDir 'gamecheck-page.html'
[System.IO.File]::WriteAllText($outFile, $page, $utf8)
Write-Host "تم البناء: $outFile ($([Math]::Round($page.Length/1KB)) KB)"
