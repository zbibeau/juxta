// Reception des rapports du kit Odaiji_Juxta. Le kit les ENVOIE DEPUIS LE POSTE DU CLIENT (session TeamViewer) quand ils peuvent faire evoluer l'outil.
// Stockage (au choix, les deux possibles) :
//   - depot GitHub PRIVE : variables GITHUB_TOKEN (Contents: read/write sur ce depot seul), GITHUB_REPO (ex. zbibeau/juxta-rapports), GITHUB_BRANCH (defaut main)
//   - mail Resend       : variables RESEND_API_KEY, REPORT_TO, REPORT_FROM (ex. onboarding@resend.dev)
const MAX = 250000;
const clean = (v, n) => String(v ?? "").replace(/[\r\n]+/g, " ").slice(0, n);
const slug = (v, n) => clean(v, n).replace(/[^A-Za-z0-9._-]+/g, "_").replace(/^_+|_+$/g, "") || "x";
const mask = (t) => t.replace(/[A-Za-z0-9+\/=]{80,}/g, "[base64-omis]").replace(/(codecps[^0-9]{0,6})\d{4,8}/gi, "$1****"); // ceinture et bretelles : le kit masque deja
export default async (req) => {
  if (req.method !== "POST") return new Response("POST uniquement", { status: 405 });
  let b;
  try { b = await req.json(); } catch { return new Response("JSON invalide", { status: 400 }); }
  const rapport = mask(String(b.rapport ?? ""));
  if (!rapport || rapport.length > MAX || b.kit !== "odaiji-juxta") return new Response("refuse", { status: 400 });
  const gh = process.env.GITHUB_TOKEN, repo = process.env.GITHUB_REPO, key = process.env.RESEND_API_KEY, to = process.env.REPORT_TO;
  if (!(gh && repo) && !(key && to)) return new Response("serveur non configure", { status: 500 });
  const sujet = `[Kit Odaiji] ${clean(b.raison, 60)} - ${clean(b.poste, 40)} - ${clean(b.os, 5)} v${clean(b.version, 12)} - ${clean(b.nom, 60)}`;
  let okGh = false, okMail = false;
  if (gh && repo) {
    const d = new Date(), pad = (n) => String(n).padStart(2, "0");
    const jour = `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())}`;
    const heure = `${pad(d.getUTCHours())}${pad(d.getUTCMinutes())}${pad(d.getUTCSeconds())}`;
    const path = `rapports/${jour}/${heure}_${slug(b.poste, 40)}_${slug(b.os, 5)}_v${slug(b.version, 12)}_${slug(b.raison, 30)}.txt`;
    const contenu = `${sujet}\n${"=".repeat(60)}\n${rapport}\n`;
    const r = await fetch(`https://api.github.com/repos/${repo}/contents/${path}`, {
      method: "PUT",
      headers: { Authorization: `Bearer ${gh}`, Accept: "application/vnd.github+json", "User-Agent": "odaiji-juxta-rapport", "Content-Type": "application/json" },
      body: JSON.stringify({ message: sujet.slice(0, 120), content: Buffer.from(contenu, "utf8").toString("base64"), branch: process.env.GITHUB_BRANCH || "main" }),
    });
    okGh = r.ok;
  }
  if (key && to) {
    const r = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify({ from: process.env.REPORT_FROM || "onboarding@resend.dev", to: [to], subject: sujet, text: rapport }),
    });
    okMail = r.ok;
  }
  return new Response(okGh || okMail ? "ok" : "echec envoi", { status: okGh || okMail ? 200 : 502 });
};
