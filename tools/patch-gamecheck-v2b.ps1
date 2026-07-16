# v2.0b — حراسة القياسات: تلغى بأمان لو التاب مخفي أو حصل throttling
# (عشان زائر بيبدل التابات أثناء الفحص مياخدش نتيجة غلط، والفحص ميعلقش)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$p = Join-Path $root 'assets\gamecheck.js'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$js = [System.IO.File]::ReadAllText($p, $utf8)

$edits = @(
    @{
        old = 'async function cpuBenchScore(){try{const t=performance.now();let e=0,r=0;for(;;){const o=performance.now()-t;if(o>=650)break;for(let a=0;a<1e5;a++)r+=Math.sqrt(a)*Math.sin(a%7);e+=1e5,e%5e5===0&&await new Promise(a=>setTimeout(a,0))}const n=performance.now()-t,s=e/Math.max(1,n);'
        new = 'async function cpuBenchScore(){try{if(document.visibilityState!=="visible")return 0;const t=performance.now();let e=0,r=0;for(;;){const o=performance.now()-t;if(o>=650)break;for(let a=0;a<1e5;a++)r+=Math.sqrt(a)*Math.sin(a%7);e+=1e5;if(e%5e5===0){const a=performance.now();if(await new Promise(c=>setTimeout(c,0)),performance.now()-a>300||document.visibilityState!=="visible")return 0}}const n=performance.now()-t,s=e/Math.max(1,n);'
    },
    @{
        old = 'let i=0;const l=performance.now(),p=()=>{const k=performance.now()-l;if(k>=1200){t(Math.round(i/(k/1e3)));return}r.uniform1f(m,k*.001);for(let w=0;w<6;w++)r.drawArrays(r.TRIANGLES,0,3);r.finish&&r.finish(),i++,requestAnimationFrame(p)};requestAnimationFrame(p)}catch{t(0)}})}'
        new = 'if(document.visibilityState!=="visible"){t(0);return}let i=0,d=!1;const y=k=>{d||(d=!0,t(k))},l=performance.now();let v=l;const p=()=>{const k=performance.now();if(k-v>300){y(0);return}v=k;const x=k-l;if(x>=1200){y(Math.round(i/(x/1e3)));return}r.uniform1f(m,x*.001);for(let w=0;w<6;w++)r.drawArrays(r.TRIANGLES,0,3);r.finish&&r.finish(),i++,requestAnimationFrame(p)};setTimeout(()=>y(0),5e3),requestAnimationFrame(p)}catch{t(0)}})}'
    }
)

$i = 0
foreach ($e in $edits) {
    $i++
    if (-not $js.Contains($e.old)) { throw "v2b: النص $i مش موجود" }
    $js = $js.Replace($e.old, $e.new)
    Write-Host "[OK] v2b تعديل $i"
}
[System.IO.File]::WriteAllText($p, $js, $utf8)
Write-Host "تم — القياسات بقت محمية"
