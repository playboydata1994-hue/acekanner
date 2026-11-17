"""Build the public ACEkanner web pages (GitHub Pages) from docs/play/*.md.

Pages: docs/index.html, docs/privacy/, docs/terms/, docs/delete-account/.
GitHub Pages serves the docs/ folder of main (Settings → Pages → Deploy from a
branch → main → /docs). docs/.nojekyll makes it serve the files as they are.
Requires the `markdown` package (pip install markdown==3.7).

Usage (from the repository root):
    python3 -I tools/play/build_pages.py
"""
import html
import os
import re
import sys

import markdown
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DOCS = os.path.join(ROOT, "docs", "play")
SITE = os.path.join(ROOT, "docs")
SUPPORT = "espinosanoli1994@gmail.com"

PAGES = [
    ("privacy", "PRIVACY_POLICY.md", "Privacy Policy"),
    ("terms", "TERMS_OF_USE.md", "Terms of Use"),
    ("delete-account", "ACCOUNT_DELETION.md", "Delete your account"),
]

CSS = """
:root{--bg:#f8fafc;--card:#fff;--ink:#0f172a;--muted:#475569;--line:#e2e8f0;--brand:#1d4ed8;--brand-ink:#fff;--link:#1d4ed8;--code:#f1f5f9}
@media (prefers-color-scheme:dark){:root{--bg:#0b1220;--card:#111a2e;--ink:#e2e8f0;--muted:#94a3b8;--line:#1e293b;--brand:#1e3a8a;--brand-ink:#fff;--link:#93c5fd;--code:#1e293b}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.6 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
header{background:var(--brand);color:var(--brand-ink)}
header .bar{max-width:760px;margin:0 auto;padding:14px 16px;display:flex;align-items:center;gap:12px}
header a{color:inherit;text-decoration:none;font-weight:700;font-size:18px;display:flex;align-items:center;gap:10px}
header img{width:32px;height:32px;border-radius:8px}
nav{max-width:760px;margin:0 auto;padding:0 16px 12px;display:flex;flex-wrap:wrap;gap:6px 16px;font-size:14px}
nav a{color:#dbeafe;text-decoration:none}nav a[aria-current]{color:#fff;text-decoration:underline}
main{max-width:760px;margin:24px auto;padding:0 16px}
article{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:8px 24px 24px}
h1{font-size:28px;line-height:1.25;margin:20px 0 12px}h2{font-size:20px;margin:28px 0 8px}
p,li{color:var(--ink)}a{color:var(--link)}
table{border-collapse:collapse;width:100%;display:block;overflow-x:auto;font-size:15px}
th,td{border:1px solid var(--line);padding:8px 10px;text-align:left;vertical-align:top}
th{background:var(--code)}
code{background:var(--code);padding:1px 5px;border-radius:5px;font-size:14px}
footer{max-width:760px;margin:24px auto 40px;padding:0 16px;color:var(--muted);font-size:14px}
.cards{display:grid;gap:12px;margin:20px 0}
.cards a{display:block;background:var(--card);border:1px solid var(--line);border-radius:14px;padding:16px 18px;text-decoration:none;color:var(--ink)}
.cards a strong{display:block;color:var(--link);font-size:17px}
.cards a span{color:var(--muted);font-size:15px}
@media (max-width:520px){article{padding:4px 16px 18px}h1{font-size:24px}}
"""


def shell(title, body, current, prefix):
    links = [("", "Home")] + [(slug + "/", name) for slug, _, name in PAGES]
    cur = ' aria-current="page"'
    nav = "".join(
        f'<a href="{prefix}{href}"{cur if href == current else ""}>{html.escape(name)}</a>'
        for href, name in links
    )
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)} · ACEkanner</title>
<link rel="icon" href="{prefix}icon.png">
<style>{CSS}</style>
</head>
<body>
<header><div class="bar"><a href="{prefix}"><img src="{prefix}icon.png" alt="">ACEkanner</a></div><nav>{nav}</nav></header>
<main>{body}</main>
<footer>ACEkanner · NYE94, Philippines · <a href="mailto:{SUPPORT}">{SUPPORT}</a></footer>
</body>
</html>
"""


def main():
    os.makedirs(SITE, exist_ok=True)
    for slug, src, title in PAGES:
        text = open(os.path.join(DOCS, src), encoding="utf-8").read()
        left = re.findall(r"\[[A-Z][A-Z ]+\]|PENDING", text)
        if left:
            sys.exit(f"{src}: unfilled placeholders {sorted(set(left))}")
        body = markdown.markdown(text, extensions=["tables"], output_format="html")
        out = os.path.join(SITE, slug)
        os.makedirs(out, exist_ok=True)
        with open(os.path.join(out, "index.html"), "w", encoding="utf-8") as f:
            f.write(shell(title, f"<article>{body}</article>", slug + "/", "../"))
    home = f"""<article>
<h1>ACEkanner</h1>
<p>Check shaded multiple-choice answer sheets with your phone camera. ACEkanner prints the
answer sheets, reads them in seconds, scores them with your answer key and shows which
questions your class missed most. Made for teachers and instructors in the Philippines.</p>
<p>Student names, answers and scores stay on your phone, in an encrypted database.</p>
<div class="cards">
<a href="privacy/"><strong>Privacy Policy</strong><span>What ACEkanner keeps, where, and your rights under RA 10173.</span></a>
<a href="terms/"><strong>Terms of Use</strong><span>Free plan, Premium subscription and checking results.</span></a>
<a href="delete-account/"><strong>Delete your account</strong><span>How to delete your ACEkanner account and what is deleted.</span></a>
</div>
<p>Support: <a href="mailto:{SUPPORT}">{SUPPORT}</a></p>
</article>"""
    with open(os.path.join(SITE, "index.html"), "w", encoding="utf-8") as f:
        f.write(shell("Answer sheet checker", home, "", ""))
    Image.open(os.path.join(ROOT, "store", "play_icon_512.png")).convert("RGB").resize(
        (192, 192), Image.LANCZOS).save(os.path.join(SITE, "icon.png"), optimize=True)
    open(os.path.join(SITE, ".nojekyll"), "w").close()
    for rel in ["index.html", "icon.png", ".nojekyll"] + [slug + "/index.html" for slug, _, _ in PAGES]:
        print(os.path.join("docs", rel))


if __name__ == "__main__":
    main()
