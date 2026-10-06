// Reception des rapports du kit Odaiji_Juxta. Le kit les ENVOIE DEPUIS LE POSTE DU CLIENT (diag, depannage, installation, sentinelle).
// Stockage (au choix, les deux possibles) :
//   - depot GitHub PRIVE : GITHUB_TOKEN (Contents: read/write sur ce depot seul), GITHUB_REPO (proprietaire/nom du depot prive), GITHUB_BRANCH (defaut main)
//   - mail Resend       : RESEND_API_KEY, REPORT_TO, REPORT_FROM
// Authentification (v1.1) :
//   - ODAIJI_KEYS="cle1=cabinet-a,cle2=cabinet-b" : une cle par cabinet, revocable (retirer la ligne = cle refusee).
//     Le kit lit la cle dans cle-envoi.txt (a cote du kit ou dans ProgramData\MadeForMed / ~/Library/Application Support/MadeForMed), JAMAIS dans le zip public.
//   - REQUIRE_KEY=1 : refuse tout envoi sans cle valide. Sans REQUIRE_KEY : un envoi sans cle est accepte mais marque "non-identifie".
//   - Une cle fournie mais inconnue est TOUJOURS refusee (401).
// Idempotent : un meme rapport renvoye (file d'attente du kit) n'est stocke qu'une fois. Battements de la sentinelle : un fichier par poste, ecrase a chaque envoi.
import { createHash } from "node:crypto";

const MAX = 250000, MAX_BEAT = 8000, PAR_HEURE = 60;
const hits = new Map(); // limitation en memoire (au mieux : une instance de fonction)
const clean = (v, n) => String(v ?? "").replace(/[\r\n]+/g, " ").slice(0, n);
const slug = (v, n) => clean(v, n).replace(/[^A-Za-z0-9._-]+/g, "_").replace(/^_+|_+$/g, "") || "x";
const CLES = "numNatPs|numeroNatPs|finess|nir|numSecu\\w*|numeroSecu\\w*|dateNaissance|nomPatient|prenomPatient|rpps|adeli";
export const mask = (t) => t
  .replace(/[A-Za-z0-9+\/=]{80,}/g, "[base64-omis]")
  .replace(/(codecps[^0-9]{0,6})\d{4,8}/gi, "$1****")
  .replace(new RegExp(`(?<![A-Za-z])((?:${CLES})\\W{1,6})[A-Za-z0-9]{3,}`, "gi"), "$1[masque]")
  .replace(/\b\d{13,15}\b/g, (m) => (/^20\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])([01]\d|2[0-3])[0-5]\d[0-5]\d$/.test(m) ? m : "[nir-masque]"));   // un horodatage AAAAMMJJhhmmss valide (en-tete des transcriptions) n'est pas un NIR
const rep = (status, obj) => new Response(JSON.stringify(obj), { status, headers: { "content-type": "application/json" } });

function auth(req) {
  const given = (req.headers.get("x-odaiji-key") || "").trim();
  const table = Object.fromEntries((process.env.ODAIJI_KEYS || "").split(",").map((s) => s.trim()).filter(Boolean).map((s) => { const i = s.indexOf("="); return [s.slice(0, i), s.slice(i + 1)]; }));
  if (given) return table[given] ? { ok: true, cabinet: table[given] } : { ok: false, why: "cle inconnue" };
  if (process.env.REQUIRE_KEY === "1") return { ok: false, why: "cle requise" };
  return { ok: true, cabinet: "non-identifie" };
}
function limite(req) {
  const ip = req.headers.get("x-nf-client-connection-ip") || req.headers.get("x-forwarded-for") || "?";
  const h = Math.floor(Date.now() / 3600000), k = ip + "|" + h; const n = (hits.get(k) || 0) + 1; hits.set(k, n);
  if (hits.size > 5000) for (const x of hits.keys()) if (!x.endsWith("|" + h)) hits.delete(x);
  return n > PAR_HEURE;
}
async function ghPut(repo, token, branch, path, contenu, message, sha) {
  const r = await fetch(`https://api.github.com/repos/${repo}/contents/${path}`, {
    method: "PUT",
    headers: { Authorization: `Bearer ${token}`, Accept: "application/vnd.github+json", "User-Agent": "odaiji-juxta-rapport", "Content-Type": "application/json" },
    body: JSON.stringify({ message: message.slice(0, 120), content: Buffer.from(contenu, "utf8").toString("base64"), branch, ...(sha ? { sha } : {}) }),
  });
  return r;
}
async function ghSha(repo, token, branch, path) {
  const r = await fetch(`https://api.github.com/repos/${repo}/contents/${path}?ref=${branch}`, { headers: { Authorization: `Bearer ${token}`, Accept: "application/vnd.github+json", "User-Agent": "odaiji-juxta-rapport" } });
  if (!r.ok) return undefined; try { return (await r.json()).sha; } catch { return undefined; }
}

export default async (req) => {
  if (req.method !== "POST") return rep(405, { ok: false, erreur: "POST uniquement" });
  const a = auth(req);
  if (!a.ok) return rep(401, { ok: false, erreur: a.why });
  if (limite(req)) return rep(429, { ok: false, erreur: "trop d'envois" });
  let b;
  try { b = await req.json(); } catch { return rep(400, { ok: false, erreur: "JSON invalide" }); }
  const beat = b.type === "battement";
  const brut = String(b.rapport ?? "");
  if (brut.length > (beat ? MAX_BEAT : MAX)) return rep(413, { ok: false, erreur: "trop gros" });
  const rapport = mask(brut);
  if (b.kit !== "odaiji-juxta" || !rapport) return rep(400, { ok: false, erreur: "refuse" });
  const gh = process.env.GITHUB_TOKEN, repo = process.env.GITHUB_REPO, key = process.env.RESEND_API_KEY, to = process.env.REPORT_TO;
  if (!(gh && repo) && !(key && to)) return rep(500, { ok: false, erreur: "serveur non configure" });
  const branch = process.env.GITHUB_BRANCH || "main";
  const posteId = /^[0-9a-f-]{8,40}$/i.test(String(b.poste_id ?? "")) ? String(b.poste_id).toLowerCase() : "";
  const sujet = `[Kit Odaiji] ${clean(b.raison, 60)} - ${clean(b.poste, 40)} - ${clean(b.os, 5)} v${clean(b.version, 12)} - ${clean(b.nom, 60)}`;
  let okGh = false, okMail = false, id = "";
  if (gh && repo) {
    if (beat) {
      const path = `parc/battements/${posteId || slug(b.poste, 40)}.json`;
      const contenu = JSON.stringify({ recu: new Date().toISOString(), cabinet: a.cabinet, poste: clean(b.poste, 40), poste_id: posteId, os: clean(b.os, 5), version: clean(b.version, 12), battement: rapport }) + "\n";
      let r = await ghPut(repo, gh, branch, path, contenu, `battement ${clean(b.poste, 40)}`, await ghSha(repo, gh, branch, path));
      if (r.status === 409 || r.status === 422) r = await ghPut(repo, gh, branch, path, contenu, `battement ${clean(b.poste, 40)}`, await ghSha(repo, gh, branch, path));
      okGh = r.ok; id = path;
    } else {
      const d = new Date(), pad = (n) => String(n).padStart(2, "0");
      const jour = `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())}`;
      const heure = `${pad(d.getUTCHours())}${pad(d.getUTCMinutes())}${pad(d.getUTCSeconds())}`;
      const h6 = createHash("sha1").update(`${posteId}|${clean(b.nom, 80)}|${rapport}`).digest("hex").slice(0, 6);
      const path = `rapports/${jour}/${heure}_${slug(b.poste, 40)}_${slug(b.os, 5)}_v${slug(b.version, 12)}_${slug(b.raison, 30)}_${h6}.txt`;
      const contenu = `${sujet}\ncabinet : ${a.cabinet}\nposte_id : ${posteId || "?"}\n${"=".repeat(60)}\n${rapport}\n`;
      const r = await ghPut(repo, gh, branch, path, contenu, sujet);
      okGh = r.ok || r.status === 422; id = path; // 422 : meme fichier deja la (renvoi de la file d'attente) = succes
    }
  }
  if (key && to && !beat) {
    const r = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify({ from: process.env.REPORT_FROM || "onboarding@resend.dev", to: [to], subject: sujet, text: rapport }),
    });
    okMail = r.ok;
  }
  return okGh || okMail ? rep(200, { ok: true, id }) : rep(502, { ok: false, erreur: "echec envoi" });
};
