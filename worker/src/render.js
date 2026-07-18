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
  const n = g.nameAr, en = g.name;
  const minCpu = rs ? rs.min.cpu : cpuReqLabel(g.min.cpuScore);
  const minGpu = rs ? rs.min.gpu : "";
  const minRam = rs ? rs.min.ram : g.min.ram + " GB";
  const minStorage = rs ? rs.min.storage : g.min.storage + " GB";
  const recStorage = rs ? rs.rec.storage : g.rec.storage + " GB";
  const minRamNum = parseInt(String(minRam), 10) || g.min.ram;
  const faq = [];
  faq.push({
    q: `هل جهازي يشغّل ${n} (${en})؟`,
    a: `استخدم الفحص أعلى هذه الصفحة — يقيس المعالج وكرت الشاشة والرام تلقائياً من المتصفح ويقارنها بمتطلبات ${n} ويعطيك نتيجة فورية من 100 مع تقدير FPS، بدون تحميل أي برامج.`,
  });
  faq.push({
    q: `ما هي متطلبات تشغيل ${n} (${en}) على الكمبيوتر؟`,
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
    faq.map(f => `<details class="gc-faq-item"><summary class="gc-faq-q">${esc(f.q)}</summary><p class="gc-faq-a">${esc(f.a)}</p></details>`).join("\n");
  const schema = '<script type="application/ld+json">{"@context":"https://schema.org","@type":"FAQPage","mainEntity":[' +
    faq.map(f => `{"@type":"Question","name":"${escJson(f.q)}","acceptedAnswer":{"@type":"Answer","text":"${escJson(f.a)}"}}`).join(",") +
    "]}</script>";
  return html + "\n" + schema;
}

function relatedBlock(g, games, checkBase) {
  const rel = games.filter(x => x.category === g.category && x.id !== g.id && hasRealArticle(x)).slice(0, 4);
  if (!rel.length) return "";
  const items = rel.map(r =>
    `<li><a href="${checkBase}/${esc(r.id)}/">متطلبات تشغيل ${esc(r.nameAr)} <span class="gc-en-name">${esc(r.name)}</span></a> — <a href="${esc(r.downloadUrl)}">تحميل اللعبة</a></li>`
  ).join("\n");
  return `<div id="gc-related-block"><h2>ألعاب مشابهة قد تهمك</h2>\n<ul>\n${items}\n</ul></div>`;
}

// فقرات مقدمة متغيّرة (مش قالب ثابت) — بتختار صياغة حسب هاش معرف اللعبة
// عشان مفيش صفحتين بنفس الجملة بالظبط (Google's "remove the variable" thin-content test)
function hashPick(seed, arr) {
  let h = 0;
  for (let i = 0; i < seed.length; i++) h = (h * 31 + seed.charCodeAt(i)) >>> 0;
  return arr[h % arr.length];
}

function weightPhrase(w) {
  return w === "light" ? "من الألعاب الخفيفة اللي بتشتغل على معظم الأجهزة"
    : w === "heavy" ? "من الألعاب الثقيلة اللي محتاجة جهاز قوي نسبياً"
    : "لعبة متوسطة المتطلبات";
}

function introParagraphs(g, rs) {
  const n = esc(g.nameAr), en = esc(g.name);
  const minRamNum = rs ? (parseInt(String(rs.min.ram), 10) || g.min.ram) : g.min.ram;
  const ramText = `${minRamNum} GB رام`;
  const p1Templates = [
    m => `متطلبات تشغيل ${n} (${en}) على الكمبيوتر تبدأ من ${m} — استخدم الفحص أدناه لمعرفة هل جهازك يشغّلها في ثوانٍ من غير تحميل أي برنامج.`,
    m => `عايز تعرف هل جهازك يشغّل ${n} (${en})؟ الحد الأدنى المطلوب ${m}. جرّب الفحص التلقائي أدناه وشوف النتيجة فوراً.`,
    m => `${n} (${en}) محتاجة ${m} على الأقل للتشغيل. الفحص أدناه بيقارن مواصفات جهازك بالمتطلبات فعلياً ويديك نتيجة دقيقة.`,
  ];
  const p1 = hashPick(g.id, p1Templates)(ramText);

  const yearPub = rs && rs.publisher ? ` من إنتاج ${esc(rs.publisher)}${rs.year ? " سنة " + rs.year : ""}` : "";
  const heavyNote = g.weight === "heavy" ? "، ومن الأفضل التأكد من مواصفات جهازك قبل التحميل لأنها من الألعاب الثقيلة" : "";
  const p2Templates = [
    () => `اللعبة${yearPub} من تصنيف ${esc(g.category)}، و${weightPhrase(g.weight)}. الفحص هنا بيقيس أداء معالجك وكرت شاشتك فعلياً من المتصفح — مش مجرد مطابقة أرقام — عشان النتيجة تبقى أدق.`,
    () => `${n}${yearPub} لعبة ${esc(g.category)}${heavyNote}. أداتنا تفحص جهازك الحقيقي بدل الاعتماد على تخمين اسم الكرت بس.`,
  ];
  const p2 = hashPick(g.id + "x", p2Templates)();
  return `<div class="gc-page-intro"><p>${p1}</p><p>${p2}</p></div>`;
}

export function buildGamePage(g, rs, gpuMap, games, opts) {
  const base = opts.checkBase;
  const site = opts.site;
  const nameAr = esc(g.nameAr);
  const img = g.imageUrl
    ? `<div style="text-align:center"><img src="${esc(g.imageUrl)}" alt="متطلبات تشغيل ${nameAr} على الكمبيوتر" style="width:auto!important;max-width:100%!important;height:auto!important;border-radius:6px" loading="lazy"/></div>\n`
    : "";
  const dl = hasRealArticle(g)
    ? `<h2>تحميل ${nameAr} للكمبيوتر</h2>
<p>بعد ما تتأكد أن جهازك يشغّل اللعبة، حمّلها من مقال التحميل الكامل على موقعنا:</p>
<p style="text-align:center"><a class="downloadpcgame" href="${esc(g.downloadUrl)}" style="${CTA}">&#11015;&#65039; تحميل لعبة ${nameAr} للكمبيوتر</a></p>`
    : "";
  const notes = rs && rs.notes ? `<p><strong>ملاحظة:</strong> ${esc(rs.notes)}</p>` : "";
  const src = rs ? `المتطلبات الرسمية من ${esc(rs.publisher)}` : "تقديرات فريق الموقع بناءً على تجارب التشغيل";
  const today = new Date().toISOString().slice(0, 10);
  const articleLink = hasRealArticle(g)
    ? `<p style="text-align:center;font-size:15px">&#128196; <a href="${esc(g.downloadUrl)}"><strong>متطلبات تشغيل ${nameAr} الكاملة بالتفصيل + روابط التحميل — في مقال اللعبة</strong></a></p>`
    : "";
  const content = `
${breadcrumb(g, base, site)}
${introParagraphs(g, rs)}
${opts.appHtml || ""}
${img}
<h2>ملخص متطلبات تشغيل ${nameAr}</h2>
${reqTable(g, rs, gpuMap)}
${notes}
${articleLink}
<p><strong>الفرق ببساطة:</strong> الحد الأدنى يعني أن اللعبة ستعمل بإعدادات منخفضة (حوالي ${g.baseFps.min} FPS)، أما المواصفات الموصى بها فتعني لعباً سلساً على إعدادات متوسطة إلى عالية (${g.baseFps.rec} FPS أو أكثر).</p>

<h2>الأداء المتوقع حسب كرت الشاشة</h2>
${fpsTable(g, gpuMap, base)}

${infoBox(g, rs)}
${dl}
${faqBlock(g, rs)}
${relatedBlock(g, games, base)}
<p style="font-size:13px;color:#777">آخر تحديث: ${today} — المصدر: ${src}.</p>
${videoGameSchema(g, rs, site)}
`;
  return {
    title: `هل جهازي يشغّل ${g.nameAr} (${g.name})؟ — فحص فوري لمتطلبات التشغيل و FPS`,
    desc: `افحص هل جهازك يشغّل ${g.nameAr} (${g.name}) في 5 ثوانٍ: فحص تلقائي من المتصفح، نتيجة من 100، تقدير FPS، وملخص الحد الأدنى والموصى به.`,
    canonical: `${site}/check/${g.id}/`,
    image: g.imageUrl || "",
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
