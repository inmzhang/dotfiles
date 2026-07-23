# Citations — footnote style + mandatory verification

## Mechanics (already wired in the template)

- `config-common(show-bibliography-as-footnote: bibliography("refs.bib",
  title: none))` in the theme show rule.
- In slides: plain `@key` → renders `[n]` + full reference as a footnote
  on that slide.
- Final slide (before `#show: appendix`):

```typst
== References
#set text(size: 14pt)
#magic.bibliography(title: none)
```

Cite where it matters: borrowed figures/data, quantitative claims,
methods being compared against, and the paper(s) the talk is built on.
Don't footnote common knowledge — a slide with four footnotes has three
too many.

## Verification workflow (before delivery, every entry)

A wrong citation projected to a room is worse than none. For each
`refs.bib` entry, verify title, author list, year, and venue against a
primary source:

```bash
# arXiv (best for physics/CS): returns title + authors
curl -s "http://export.arxiv.org/api/query?id_list=1706.03762" | head -40

# DOI via Crossref: returns title + author families + year
curl -s "https://api.crossref.org/works/10.1103/PhysRevA.86.032324" \
  | python3 -c "import json,sys; m=json.load(sys.stdin)['message']; \
print(m['title'][0]); print([a['family'] for a in m.get('author',[])]); \
print(m['issued']['date-parts'][0][0])"
```

Rules:

- Never invent a DOI or arXiv id. If lookup fails, cite what is
  verifiable (e.g., arXiv version) or flag the entry to the user.
- Year/venue mismatches are common for arXiv-then-published papers —
  prefer the published venue, keep `eprint` field as a bonus.
- Include a DOI or arXiv id in every entry when one exists; typst's
  IEEE style renders them compactly.
- After verifying, note in your handoff message which source verified
  each entry (arXiv API / Crossref / publisher page).

## Bib entry shape

```bibtex
@article{fowler2012,
  author  = {Fowler, Austin G. and Mariantoni, Matteo and
             Martinis, John M. and Cleland, Andrew N.},
  title   = {Surface codes: Towards practical large-scale quantum computation},
  journal = {Physical Review A},
  volume  = {86},
  pages   = {032324},
  year    = {2012},
  doi     = {10.1103/PhysRevA.86.032324},
}
```
