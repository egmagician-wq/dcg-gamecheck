// Cloudflare Worker — صفحات فحص متطلبات التشغيل على مسار /check/*
// يلبس ثيم بلوجر عبر صفحة shell ويحقن محتوى كل لعبة (مولّد من كتالوج الريبو)
import catalogData from "../../data/game-requirements.json";
import realSpecs from "../../data/real-specs.json";
import gpuMap from "../../data/gpu-map.json";
import reqPosts from "../../data/req-posts.json";
import pageTop from "../../tools/templates/page-top.html";
import pageBottom from "../../tools/templates/page-bottom.html";
import { buildGamePage, buildSitemap, esc } from "./render.js";

const SITE = "https://www.downloadcomputergames.net";
const SHELL_URL = SITE + "/p/shell.html";
const MARKER = "GC_CONTENT";
// نسخة مثبتة بترقيم commit — تتحدث مع كل نشر جديد (لا كاش قديم أبداً)
const APP_JS = "https://cdn.jsdelivr.net/gh/egmagician-wq/dcg-gamecheck@d24145817d3d50fbbcc98868d353a132f445ece5/assets/gamecheck.js";
const SHELL_TTL = 21600; // 6 ساعات

const games = catalogData.games;

// كتالوج جاهز محقون في كل صفحة — يغني التطبيق عن 3 طلبات شبكة لجلب البيانات (jsDelivr)
// عند بدء الفحص، فيلغي أي تأخير/تجمّد لشريط التقدم قبل ما يبدأ (السبب الأصلي كان انتظار الشبكة)
const CATALOG_SCRIPT = `<script>window.__GC_CATALOG__=${JSON.stringify({ games, gpuMap, reqPosts }).replace(/</g, "\\u003c")};</script>`;

// ثيم احتياطي بسيط لو صفحة الـ shell مش متاحة لأي سبب
const FALLBACK_SHELL = `<!doctype html><html dir="rtl" lang="ar"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>فحص متطلبات تشغيل الألعاب</title></head><body style="max-width:860px;margin:0 auto;padding:0 14px;font-family:Tahoma,Arial;line-height:1.9;color:#222"><p><a href="${SITE}/">&#8592; موقع تحميل ألعاب كمبيوتر</a></p>${MARKER}<p style="text-align:center"><a href="${SITE}/">downloadcomputergames.net</a></p></body></html>`;

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    let p = url.pathname;
    if (p.startsWith("/check")) p = p.slice("/check".length);
    if (!p.startsWith("/")) p = "/" + p;

    if (p === "/sitemap.xml") {
      return new Response(buildSitemap(games, SITE), {
        headers: { "content-type": "application/xml; charset=utf-8", "cache-control": "public, max-age=3600" },
      });
    }

    const checkBase = url.pathname.startsWith("/check") ? "/check" : "";

    // الصفحة الرئيسية للأداة: /check/ (تدعم ?game= كالمعتاد)
    if (p === "/" || p === "") {
      const html = await renderInShell(ctx, {
        title: "فحص متطلبات تشغيل الألعاب — هل جهازي يشغّل اللعبة؟",
        desc: "أداة عربية مجانية لفحص متطلبات تشغيل الألعاب: تقارن مواصفات جهازك بالحد الأدنى والموصى به وتعطيك نتيجة من 100 مع تقدير FPS — بدون تحميل برامج.",
        canonical: `${SITE}/check/`,
        content: homeContent(),
      });
      return htmlResponse(html, 300);
    }

    // صفحة لعبة: /check/<id>/
    const id = p.replace(/^\/+|\/+$/g, "");
    const g = games.find(x => x.id === id);
    if (!g) {
      const html = await renderInShell(ctx, {
        title: "الصفحة غير موجودة — فحص متطلبات تشغيل الألعاب",
        desc: "الصفحة المطلوبة غير موجودة.",
        canonical: `${SITE}/check/`,
        content: `<h2>اللعبة غير موجودة</h2><p>الرابط غير صحيح أو اللعبة غير متوفرة — <a href="${checkBase}/">ارجع لأداة الفحص</a> وابحث عن لعبتك.</p>`,
      });
      return htmlResponse(html, 60, 404);
    }

    const page = buildGamePage(g, realSpecs[g.id] || null, gpuMap, games, { checkBase, site: SITE, appHtml: appBlock(g) });
    const html = await renderInShell(ctx, page);
    return htmlResponse(html, 1800);
  },
};

function htmlResponse(html, sMaxAge, status = 200) {
  return new Response(html, {
    status,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": `public, s-maxage=${sMaxAge}, max-age=300`,
    },
  });
}

function homeContent() {
  // نفس صفحة الأداة: الستايل والسكيما (page-top) + الهيكل (page-bottom) + الكود من CDN
  // ملحوظة: قالب page-top يترك وسم <script> الأخير مفتوحاً (لأن نسخة بلوجر تحقن الكود داخله) — نقفله هنا
  const top = pageTop.replace(/^<!--[\s\S]*?-->/, "");
  return top + `\n</script>\n${CATALOG_SCRIPT}\n<script src="${APP_JS}" defer></script>\n` + pageBottom;
}

// الأداة التفاعلية مدمجة داخل صفحة اللعبة: الفحص يبدأ تلقائياً للعبة الصفحة
function appBlock(g) {
  const top = pageTop
    .replace(/^<!--[\s\S]*?-->/, "")
    .replace(/<script type="application\/ld\+json">[\s\S]*?<\/script>/g, ""); // السكيما العامة للصفحة الرئيسية فقط
  const bottom = pageBottom
    .replace(/<div class="gc-intro"[\s\S]*?<\/div>/, "")
    .replace(/<section class="gc-faq"[\s\S]*?<\/section>/, "")
    .replace("هل جهازي يشغّل اللعبة؟ — فحص متطلبات تشغيل الألعاب", "هل جهازي يشغّل " + g.nameAr + " (" + g.name + ")؟");
  return `<script>window.GC_GAME=${JSON.stringify(g.id)};</script>\n` + top + `\n</script>\n${CATALOG_SCRIPT}\n<script src="${APP_JS}" defer></script>\n` + bottom;
}

async function getShell(ctx) {
  const cache = caches.default;
  const key = new Request(SHELL_URL + "?__gcshell=1");
  const hit = await cache.match(key);
  if (hit) return await hit.text();
  try {
    const r = await fetch(SHELL_URL, { headers: { "user-agent": "dcg-gamecheck-worker" } });
    if (r.ok) {
      const t = await r.text();
      if (t.includes(MARKER)) {
        ctx.waitUntil(cache.put(key, new Response(t, {
          headers: { "content-type": "text/html; charset=utf-8", "cache-control": `s-maxage=${SHELL_TTL}` },
        })));
        return t;
      }
    }
  } catch (e) {}
  return FALLBACK_SHELL;
}

async function renderInShell(ctx, page) {
  const shell = await getShell(ctx);
  let html = shell.includes(MARKER)
    ? shell.replace(MARKER, page.content)
    : shell + page.content;
  // عنوان الصفحة
  html = html.replace(/<title>[\s\S]*?<\/title>/, `<title>${esc(page.title)}</title>`);
  // إزالة وسوم الميتا بتوع صفحة الـ shell (canonical/description/OG/Twitter) وإضافة بتوعنا
  html = html.replace(/<link[^>]*rel=['"]canonical['"][^>]*>\s*/gi, "");
  html = html.replace(/<meta[^>]*name=['"]description['"][^>]*>\s*/gi, "");
  html = html.replace(/<meta[^>]*property=['"]og:[a-z:]+['"][^>]*>\s*/gi, "");
  html = html.replace(/<meta[^>]*name=['"]twitter:[a-z:]+['"][^>]*>\s*/gi, "");
  const ogImage = page.image
    ? `<meta property="og:image" content="${esc(page.image)}"/><meta name="twitter:card" content="summary_large_image"/>`
    : `<meta name="twitter:card" content="summary"/>`;
  html = html.replace("</head>",
    `<link rel="canonical" href="${page.canonical}"/><meta name="description" content="${esc(page.desc)}"/><meta property="og:type" content="website"/><meta property="og:url" content="${page.canonical}"/><meta property="og:title" content="${esc(page.title)}"/><meta property="og:description" content="${esc(page.desc)}"/>${ogImage}</head>`);
  return html;
}
