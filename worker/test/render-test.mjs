// اختبار توليد الصفحات بدون كلاودفلير: node worker/test/render-test.mjs
import { readFileSync, writeFileSync, mkdirSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import { buildGamePage, buildSitemap, hasRealArticle } from "../src/render.js";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const games = JSON.parse(readFileSync(join(root, "data/game-requirements.json"), "utf8")).games;
const realSpecs = JSON.parse(readFileSync(join(root, "data/real-specs.json"), "utf8"));
const gpuMap = JSON.parse(readFileSync(join(root, "data/gpu-map.json"), "utf8"));

const opts = { checkBase: "/check", site: "https://www.downloadcomputergames.net" };
let failures = 0;
const check = (label, cond) => { console.log((cond ? "[OK] " : "[FAIL] ") + label); if (!cond) failures++; };

// 1) لعبة بمواصفات رسمية (gta-v)
const gta = games.find(g => g.id === "gta-v");
const p1 = buildGamePage(gta, realSpecs["gta-v"], gpuMap, games, opts);
check("gta-v: العنوان يستهدف (هل جهازي يشغل) بالعربي والإنجليزي", p1.title.includes("هل جهازي يشغّل جتا 5") && p1.title.includes("GTA V"));
check("gta-v: ملخص المتطلبات موجود", p1.content.includes("المواصفات المطلوبة لتشغيل جتا 5"));
check("gta-v: رابط المقال للمتطلبات الكاملة", p1.content.includes("متطلبات تشغيل جتا 5 الكاملة بالتفصيل"));
check("gta-v: جدول رسمي فيه اسم معالج حقيقي", p1.content.includes("Core 2 Quad Q6600"));
check("gta-v: canonical صحيح", p1.canonical === "https://www.downloadcomputergames.net/check/gta-v/");
check("gta-v: زر الفحص يشاور على /check/?game=", p1.content.includes('/check/?game=gta-v'));
check("gta-v: فيه FAQ schema", p1.content.includes('"@type":"FAQPage"'));
check("gta-v: فيه VideoGame schema", p1.content.includes('"@type":"VideoGame"'));
check("gta-v: فيه Breadcrumb schema", p1.content.includes('"@type":"BreadcrumbList"'));
check("gta-v: فيه سؤال ويندوز 7", p1.content.includes("هل تعمل جتا 5 على ويندوز 7؟"));
check("gta-v: فيه زر التحميل", p1.content.includes("download-gta-5-for-pc.html"));
check("gta-v: فقرتا المقدمة موجودتان قبل ملخص المتطلبات", p1.content.includes('class="gc-page-intro"') && p1.content.indexOf('class="gc-page-intro"') < p1.content.indexOf("المواصفات المطلوبة لتشغيل"));
check("gta-v: فقرة المقدمة فيها الاسمين", /gc-page-intro[\s\S]*?جتا 5[\s\S]*?GTA V/.test(p1.content));
check("gta-v: الأسئلة الشائعة details/summary مش h3", p1.content.includes('<details class="gc-faq-item">') && !p1.content.includes("<h3>هل جهازي يشغّل"));
check("gta-v: قسم ألعاب مشابهة له id ثابت", p1.content.includes('id="gc-related-block"'));
check("gta-v: تاريخ آخر تحديث موجود", /آخر تحديث: \d{4}-\d{2}-\d{2}/.test(p1.content));
check("gta-v: image في الناتج", p1.image && p1.image.length > 0);

// 2) لعبة بدون مواصفات رسمية (تتولد من الكتالوج)
const w3 = games.find(g => g.id === "witcher-3");
const p2 = buildGamePage(w3, null, gpuMap, games, opts);
check("witcher-3: جدول مشتق فيه فئة كرت", /GTX|RX|RTX/.test(p2.content));
check("witcher-3: فيه جدول FPS", p2.content.includes("FPS المتوقع تقريباً"));
check("witcher-3: مفيش undefined في الصفحة", !p2.content.includes("undefined"));

// 3) الـ sitemap
const sm = buildSitemap(games, opts.site);
check("sitemap: فيه كل الألعاب + الرئيسية", (sm.match(/<url>/g) || []).length === games.length + 1);
check("sitemap: فيه gta-v", sm.includes("/check/gta-v/"));

// 4) كل صفحات الكتالوج تتولد بدون أخطاء
let genErrors = 0;
for (const g of games) {
  try {
    const p = buildGamePage(g, realSpecs[g.id] || null, gpuMap, games, opts);
    if (!p.content || p.content.includes("undefined") || p.content.includes("NaN")) genErrors++;
  } catch (e) { genErrors++; console.log("  خطأ في: " + g.id + " — " + e.message); }
}
check(`توليد كل الصفحات (${games.length} لعبة) بدون undefined/NaN`, genErrors === 0);

// عيّنة للمعاينة
const outDir = join(root, "worker", "test", "out");
mkdirSync(outDir, { recursive: true });
const wrap = c => `<!doctype html><html dir="rtl" lang="ar"><head><meta charset="utf-8"><title>عينة</title></head><body style="max-width:860px;margin:0 auto;padding:0 14px;font-family:Tahoma;line-height:1.9">${c}</body></html>`;
writeFileSync(join(outDir, "sample-gta-v.html"), wrap(p1.content));
writeFileSync(join(outDir, "sample-witcher-3.html"), wrap(p2.content));

console.log(failures === 0 ? "\nكل الاختبارات نجحت ✓ — العينات في worker/test/out/" : `\n${failures} اختبار فشل!`);
process.exit(failures === 0 ? 0 : 1);
