// توليد محتوى صفحات الفحص — دوال نقية (تُختبر بـ node وتعمل داخل الووركر)
// الهيكل مبني على دراسة PCGameBenchmark وCan You Run It + مميزاتنا الحصرية
export function esc(s) {
  return String(s ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}
function escJson(s) {
  return String(s ?? "").replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/[\r\n]+/g, " ");
}

const TBL = "width:100%;border-collapse:collapse;margin:12px 0;font-size:15px";
const TH = "background:#5b7178;color:#fff;padding:9px 8px;border:1px solid #4a5d63;text-align:right";
const TD = "background:#f5f5f5;color:#333;padding:9px 8px;border:1px solid #ddd;text-align:right";
const CTA = "display:inline-block;background:#206155;color:#fff;padding:12px 26px;border-radius:4px;font-weight:700;text-decoration:none;font-size:16px";

export function hasRealArticle(g) {
  const u = (g.downloadUrl || "").trim();
  return !!u && !/\/search\?/i.test(u) && /downloadcomputergames\.net\/\d{4}\/\d{2}\//i.test(u);
}

function weightAr(w) {
  return w === "light" ? "خفيفة" : w === "heavy" ? "ثقيلة" : "متوسطة";
}
function gpuReqLabel(score, gpuMap) {
  const t = [...gpuMap.gpus].sort((a, b) => a.score - b.score).find(x => x.score >= score);
  return t ? t.label + " أو أقوى" : "كرت شاشة قوي حديث";
}
function cpuReqLabel(score) {
  if (score >= 70) return "Intel Core i7 / Ryzen 7 أو أقوى";
  if (score >= 55) return "Intel Core i5 / Ryzen 5 أو أقوى";
  if (score >= 40) return "Intel Core i3 / Ryzen 3 أو أقوى";
  return "معالج ثنائي النواة على الأقل";
}

function breadcrumb(g, checkBase, site) {
  const html = `<p style="font-size:13px;color:#777;margin:0 0 10px"><a href="${site}/">الرئيسية</a> &laquo; <a href="${checkBase}/">فحص متطلبات التشغيل</a> &laquo; ${esc(g.nameAr)}</p>`;
  const schema = `<script type="application/ld+json">{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"الرئيسية","item":"${site}/"},{"@type":"ListItem","position":2,"name":"فحص متطلبات تشغيل الألعاب","item":"${site}/check/"},{"@type":"ListItem","position":3,"name":"${escJson(g.nameAr)}","item":"${site}/check/${g.id}/"}]}</script>`;
  return html + schema;
}

function videoGameSchema(g, rs, site) {
  const o = {
    "@context": "https://schema.org",
    "@type": "VideoGame",
    name: g.name,
    alternateName: g.nameAr,
    gamePlatform: "PC",
    operatingSystem: "Windows",
    applicationCategory: "Game",
    url: `${site}/check/${g.id}/`,
  };
  if (g.imageUrl) o.image = g.imageUrl;
  if (rs && rs.publisher) o.publisher = { "@type": "Organization", name: rs.publisher };
  return `<script type="application/ld+json">${JSON.stringify(o)}</script>`;
}

function reqTable(g, rs, gpuMap) {
  const rows = rs
    ? [
        ["نظام التشغيل", rs.min.os, rs.rec.os],
        ["المعالج (CPU)", rs.min.cpu, rs.rec.cpu],
        ["كرت الشاشة (GPU)", rs.min.gpu, rs.rec.gpu],
        ["الذاكرة (RAM)", rs.min.ram, rs.rec.ram],
        ["مساحة التخزين", rs.min.storage, rs.rec.storage],
        ["DirectX", rs.min.dx, rs.rec.dx],
      ]
    : [
        ["المعالج (CPU)", cpuReqLabel(g.min.cpuScore), cpuReqLabel(g.rec.cpuScore)],
        ["كرت الشاشة (GPU)", gpuReqLabel(g.min.gpuScore, gpuMap), gpuReqLabel(g.rec.gpuScore, gpuMap)],
        ["الذاكرة (RAM)", g.min.ram + " GB", g.rec.ram + " GB"],
        ["مساحة التخزين", g.min.storage + " GB", g.rec.storage + " GB"],
      ];
  const body = rows.map(r =>
    `<tr><th scope="row" style="${TH}">${esc(r[0])}</th><td style="${TD}">${esc(r[1])}</td><td style="${TD}">${esc(r[2])}</td></tr>`
  ).join("\n");
  return `<table style="${TBL}">
<thead><tr><th style="${TH}">المكوّن</th><th style="${TH}">الحد الأدنى</th><th style="${TH}">الموصى به</th></tr></thead>
<tbody>
${body}
</tbody>
</table>`;
}

function fpsTable(g, gpuMap, checkBase) {
  const wf = g.weight === "light" ? 1.15 : g.weight === "heavy" ? 0.85 : 1.0;
  const tiers = gpuMap.gpus.filter(t => [12, 18, 28, 38, 45, 58, 72, 82].includes(t.score));
  const rows = tiers.map(t => {
    let ratio = t.score / g.rec.gpuScore;
    if (ratio > 1.2) ratio = 1.2;
    const fps = g.baseFps.rec * ratio * wf;
    const lo = Math.max(15, Math.round(fps * 0.75));
    const hi = Math.max(lo, Math.round(fps * 1.1));
    const verdict = t.score >= g.rec.gpuScore ? "&#9989; ممتاز — إعدادات عالية"
      : t.score >= g.min.gpuScore ? "&#9888;&#65039; جيد — إعدادات متوسطة/منخفضة"
      : "&#10060; أضعف من الحد الأدنى";
    const fpsTxt = t.score < g.min.gpuScore ? "&mdash;" : `${lo}&ndash;${hi} FPS`;
    return `<tr><th scope="row" style="${TH}">${esc(t.label)}</th><td style="${TD}">${fpsTxt}</td><td style="${TD}">${verdict}</td></tr>`;
  }).join("\n");
  return `<table style="${TBL}">
<thead><tr><th style="${TH}">كرت الشاشة</th><th style="${TH}">FPS المتوقع تقريباً</th><th style="${TH}">التقييم</th></tr></thead>
<tbody>
${rows}
</tbody>
</table>
<p style="font-size:13px;color:#777">* الأرقام تقديرية على دقة 1080p وتختلف حسب المعالج والرام وإعدادات اللعبة — استخدم <a href="${checkBase}/?game=${esc(g.id)}">أداة الفحص</a> لتقدير أدق لجهازك. ولا تنسَ تحديث تعريف كرت الشاشة من موقع NVIDIA أو AMD قبل اللعب.</p>`;
}

function infoBox(g, rs) {
  const rows = [
    ["&#127918;", "اسم اللعبة", g.nameAr + " (" + g.name + ")"],
    ["&#128193;", "التصنيف", g.category],
    ["&#9878;&#65039;", "مستوى الثقل", weightAr(g.weight)],
    ["&#128190;", "الرام الأدنى", g.min.ram + " GB"],
    ["&#128191;", "حجم التثبيت تقريباً", g.rec.storage + " GB"],
    ["&#128187;", "متوافقة مع", rs ? rs.min.os : "Windows"],
  ];
  if (rs && rs.publisher) rows.push(["&#127970;", "الناشر", rs.publisher + (rs.year ? " — " + rs.year : "")]);
  const body = rows.map(r =>
    `<tr><th scope="row" style="${TH}">${r[0]} ${esc(r[1])}</th><td style="${TD}">${esc(r[2])}</td></tr>`
  ).join("\n");
  return `<h2>معلومات سريعة عن ${esc(g.nameAr)}</h2>
<table style="${TBL}"><tbody>
${body}
</tbody></table>`;
}

function faqItems(g, rs) {
  const n = g.nameAr;
  const minCpu = rs ? rs.min.cpu : cpuReqLabel(g.min.cpuScore);
  const minGpu = rs ? rs.min.gpu : "";
  const minRam = rs ? rs.min.ram : g.min.ram + " GB";
  const minStorage = rs ? rs.min.storage : g.min.storage + " GB";
  const recStorage = rs ? rs.rec.storage : g.rec.storage + " GB";
  const minRamNum = parseInt(String(minRam), 10) || g.min.ram;
  const faq = [];
  faq.push({
    q: `ما هي متطلبات تشغيل ${n} على الكمبيوتر؟`,
    a: `الحد الأدنى لتشغيل ${n}: معالج ${minCpu}، رام ${minRam}${minGpu ? "، كرت شاشة " + minGpu : ""}، ومساحة فارغة ${minStorage}.`,
  });
  faq.push(minRamNum <= 4 ? {
    q: `هل تعمل ${n} على جهاز بـ 4 جيجا رام؟`,
    a: `نعم — الحد الأدنى الرسمي للعبة هو ${minRam}، وجهاز بـ 4GB رام يشغّلها بإعدادات منخفضة إلى متوسطة مع إغلاق البرامج الأخرى أثناء اللعب.`,
  } : {
    q: `هل تعمل ${n} على جهاز بـ 4 جيجا رام؟`,
    a: `لا يُنصح بذلك — اللعبة تحتاج ${minRam} رام كحد أدنى، وبـ 4GB ستواجه تقطيعاً حاداً أو لن تعمل إطلاقاً.`,
  });
  faq.push(g.min.gpuScore <= 18 ? {
    q: `هل تعمل ${n} بكرت الشاشة المدمج (بدون كرت خارجي)؟`,
    a: `نعم — ${n} من الألعاب التي تعمل على كروت الشاشة المدمجة مثل Intel HD بإعدادات منخفضة، لكن كرت شاشة منفصل يمنحك تجربة أفضل بكثير.`,
  } : {
    q: `هل تعمل ${n} بكرت الشاشة المدمج (بدون كرت خارجي)؟`,
    a: `الكروت المدمجة القديمة أضعف من الحد الأدنى المطلوب — ستحتاج كرت شاشة منفصلاً أو معالجاً حديثاً برسوميات قوية لتشغيلها بشكل مقبول.`,
  });
  if (rs) {
    const win7 = /Windows (XP|Vista|7)/i.test(rs.min.os);
    faq.push({
      q: `هل تعمل ${n} على ويندوز 7؟`,
      a: win7
        ? `نعم — الحد الأدنى الرسمي هو ${rs.min.os}، فاللعبة تعمل على ويندوز 7 والأنظمة الأحدث.`
        : `النظام الأدنى الرسمي هو ${rs.min.os} — قد لا تعمل اللعبة على ويندوز 7 أو قد تواجه مشاكل، ويُنصح بويندوز 10 أو أحدث.`,
    });
  }
  faq.push({
    q: `كم تبلغ مساحة ${n} على الهارد؟`,
    a: `تحتاج اللعبة مساحة فارغة حوالي ${recStorage} — تأكد من توفرها على القرص قبل التحميل.`,
  });
  faq.push({
    q: `كيف أعرف إذا كان جهازي يشغّل ${n} قبل التحميل؟`,
    a: `اضغط زر «افحص جهازك الآن» في هذه الصفحة — أداة GameCheck تفحص مواصفات جهازك تلقائياً من المتصفح وتقارنها بمتطلبات ${n} وتعطيك نتيجة من 100 مع تقدير FPS.`,
  });
  return faq;
}

function faqBlock(g, rs) {
  const faq = faqItems(g, rs);
  const html = `<h2>أسئلة شائعة عن متطلبات ${esc(g.nameAr)}</h2>\n` +
    faq.map(f => `<h3>${esc(f.q)}</h3>\n<p>${esc(f.a)}</p>`).join("\n");
  const schema = '<script type="application/ld+json">{"@context":"https://schema.org","@type":"FAQPage","mainEntity":[' +
    faq.map(f => `{"@type":"Question","name":"${escJson(f.q)}","acceptedAnswer":{"@type":"Answer","text":"${escJson(f.a)}"}}`).join(",") +
    "]}</script>";
  return html + "\n" + schema;
}

function relatedBlock(g, games, checkBase) {
  const rel = games.filter(x => x.category === g.category && x.id !== g.id && hasRealArticle(x)).slice(0, 4);
  if (!rel.length) return "";
  const items = rel.map(r =>
    `<li><a href="${checkBase}/${esc(r.id)}/">متطلبات تشغيل ${esc(r.nameAr)}</a> — <a href="${esc(r.downloadUrl)}">تحميل اللعبة</a></li>`
  ).join("\n");
  return `<h2>ألعاب مشابهة قد تهمك</h2>\n<ul>\n${items}\n</ul>`;
}

export function buildGamePage(g, rs, gpuMap, games, opts) {
  const base = opts.checkBase;
  const site = opts.site;
  const nameAr = esc(g.nameAr);
  const img = g.imageUrl
    ? `<div style="text-align:center"><img src="${esc(g.imageUrl)}" alt="متطلبات تشغيل ${nameAr} على الكمبيوتر" style="max-width:100%;border-radius:6px" loading="lazy"/></div>\n`
    : "";
  const dl = hasRealArticle(g)
    ? `<h2>تحميل ${nameAr} للكمبيوتر</h2>
<p>بعد ما تتأكد أن جهازك يشغّل اللعبة، حمّلها من مقال التحميل الكامل على موقعنا:</p>
<p style="text-align:center"><a class="downloadpcgame" href="${esc(g.downloadUrl)}" style="${CTA}">&#11015;&#65039; تحميل لعبة ${nameAr} للكمبيوتر</a></p>`
    : "";
  const notes = rs && rs.notes ? `<p><strong>ملاحظة:</strong> ${esc(rs.notes)}</p>` : "";
  const src = rs ? `المتطلبات الرسمية من ${esc(rs.publisher)}` : "تقديرات فريق الموقع بناءً على تجارب التشغيل";
  const content = `
${breadcrumb(g, base, site)}
${img}
<p>تبحث عن <strong>متطلبات تشغيل ${nameAr}</strong> (${esc(g.name)}) على الكمبيوتر؟ في هذا الدليل تجد <strong>الحد الأدنى والمواصفات الموصى بها</strong>، وجدول <strong>الأداء المتوقع (FPS)</strong> حسب كرت الشاشة، وأداة مجانية تفحص جهازك في ثوانٍ وتخبرك: <strong>هل جهازك يشغّل ${nameAr} أم لا؟</strong></p>

<h2>متطلبات تشغيل ${nameAr} على الكمبيوتر</h2>
${reqTable(g, rs, gpuMap)}
${notes}
<p><strong>الفرق ببساطة:</strong> الحد الأدنى يعني أن اللعبة ستعمل بإعدادات منخفضة (حوالي ${g.baseFps.min} FPS)، أما المواصفات الموصى بها فتعني لعباً سلساً على إعدادات متوسطة إلى عالية (${g.baseFps.rec} FPS أو أكثر).</p>

<div style="text-align:center;background:#eef5f3;border:1px solid #cfe3de;border-radius:6px;padding:20px;margin:18px 0">
<p style="font-weight:700;font-size:17px;margin:0 0 12px">هل جهازك يشغّل ${nameAr}؟ اعرف في 5 ثوانٍ</p>
<p style="margin:0 0 14px">أداة GameCheck تفحص المعالج وكرت الشاشة والرام تلقائياً من المتصفح — بدون تحميل أي برامج (على عكس المواقع الأجنبية) — وتعطيك نتيجة من 100 مع تقدير FPS.</p>
<a class="downloadpcgame" href="${base}/?game=${esc(g.id)}" style="${CTA}">&#128269; افحص جهازك الآن</a>
</div>

<h2>الأداء المتوقع حسب كرت الشاشة</h2>
${fpsTable(g, gpuMap, base)}

${infoBox(g, rs)}
${dl}
${faqBlock(g, rs)}
${relatedBlock(g, games, base)}
<p style="font-size:13px;color:#777">المصدر: ${src}.</p>
${videoGameSchema(g, rs, site)}
`;
  return {
    title: `متطلبات تشغيل ${g.nameAr} على الكمبيوتر — الحد الأدنى والموصى به`,
    desc: `متطلبات تشغيل ${g.nameAr} (${g.name}) للكمبيوتر: الحد الأدنى والموصى به، الأداء المتوقع FPS، وافحص هل جهازك يشغلها مجاناً في ثوانٍ.`,
    canonical: `${site}/check/${g.id}/`,
    content,
  };
}

export function buildSitemap(games, site) {
  const urls = [`${site}/check/`].concat(games.map(g => `${site}/check/${g.id}/`));
  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls.map(u => `<url><loc>${u}</loc></url>`).join("\n")}
</urlset>`;
}
