// Reception des rapports du kit Odaiji_Juxta (envoyes automatiquement quand ils peuvent faire evoluer l'outil).
// Variables Netlify : RESEND_API_KEY, REPORT_TO, REPORT_FROM (ex. onboarding@resend.dev).
const MAX = 250000;
const clean = (v, n) => String(v ?? "").replace(/[\r\n]+/g, " ").slice(0, n);
export default async (req) => {
  if (req.method !== "POST") return new Response("POST uniquement", { status: 405 });
  let b;
  try { b = await req.json(); } catch { return new Response("JSON invalide", { status: 400 }); }
  const rapport = String(b.rapport ?? "");
  if (!rapport || rapport.length > MAX || b.kit !== "odaiji-juxta") return new Response("refuse", { status: 400 });
  const key = process.env.RESEND_API_KEY, to = process.env.REPORT_TO;
  if (!key || !to) return new Response("serveur non configure", { status: 500 });
  const sujet = `[Kit Odaiji] ${clean(b.raison, 60)} - ${clean(b.poste, 40)} - ${clean(b.os, 5)} v${clean(b.version, 12)} - ${clean(b.nom, 60)}`;
  const r = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify({ from: process.env.REPORT_FROM || "onboarding@resend.dev", to: [to], subject: sujet, text: rapport }),
  });
  return new Response(r.ok ? "ok" : "echec envoi", { status: r.ok ? 200 : 502 });
};
