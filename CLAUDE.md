# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Ziqi Xu's academic personal site: a Jekyll site built from the [Academic Pages](https://github.com/academicpages/academicpages.github.io) template (itself a fork of Minimal Mistakes), deployed by GitHub Pages from `master` at https://ziqixu-research.github.io. There is no test suite and no CI build step — pushing to `master` publishes.

Most files are upstream template code. The personalized surface is small and worth knowing before editing anything: `_config.yml`, `_data/*`, `_pages/about.md`, `_pages/publications.html`, `_publications/*`, `_includes/news.html`, `_includes/selected_publications.html`, `_includes/publications-list-item.html`, `_includes/publications-authors-fragment.html`, and the custom `_sass/layout/_news.scss`, `_selected_publications.scss`, `_publications_yearbar.scss`, `_cv_page.scss`, `_sass/include/_accent_pink.scss`, `_sass/include/_global_link_vars.scss`. Prefer changing those over touching theme internals — upstream sync is already effectively abandoned, but keeping edits localized keeps the site debuggable.

## Commands

```bash
bundle install                              # Ruby deps (Gemfile.lock is gitignored)
bundle exec jekyll serve -l -H localhost    # dev server on :4000, live reload
bundle exec jekyll build                    # one-off build into _site/ (gitignored)
docker compose up                           # containerized alternative, also :4000
```

`_config.yml` is **not** reloaded by `serve` — restart the process after changing it.

JavaScript is not built by Jekyll. `assets/js/main.min.js` is a committed bundle produced from `assets/js/_main.js` + vendored plugins. After editing `_main.js` or `assets/js/plugins/*`:

```bash
npm install && npm run build:js   # (or: npm run watch:js)
```

`assets/js/_main.js` and `assets/js/plugins/` are excluded from the Jekyll build in `_config.yml`, so only the minified bundle ships.

CV JSON regeneration (only relevant if the `/cv-json/` page is re-enabled — see below):

```bash
./scripts/update_cv_json.sh    # _pages/cv.md -> _data/cv.json (interactive prompt at the end)
```

## Ruby 4 compatibility

The local Ruby is 4.x, but `github-pages` pins Liquid 4.0.3, which still calls the removed `Object#tainted?`. `_plugins/taint_compat.rb` monkey-patches no-op `tainted?`/`untaint` to keep local builds working. Custom `_plugins/` do **not** run on GitHub Pages — that's fine here because GitHub's own build uses a compatible Ruby. Don't move site logic into `_plugins/`; it will silently not run in production.

## Content model

Four collections (`_config.yml` → `collections`), all with `permalink: /:collection/:path/`: `_publications`, `_talks`, `_teaching`, `_portfolio`. `_pages/` holds the standalone pages; `_posts/`, `_portfolio/`, `_talks/` still contain upstream placeholder content that isn't linked from the nav.

The homepage (`_pages/about.md`, `permalink: /`) is prose plus two data-driven blocks:

- **News** — `_data/news.yml` → `_includes/news.html`. Newest first; `body` is Markdown.
- **Selected projects** — `_data/selected_publications.yml` → `_includes/selected_publications.html`. Curated and independent of `_publications/`; the file's header comments document every supported key (`image`, `image_contain`, `note_blue`/`note_orange`, `buttons` with `style: award`). Images go in `/images/` at the site root, not next to the YAML.

Header nav is `_data/navigation.yml`. Commenting out an entry hides the link without removing the page (Teaching and the JSON CV are currently hidden this way).

### Publication ordering — `author_sort_key`

`_pages/publications.html` groups `site.publications` by calendar year (newest year first), then sorts within a year by the **`author_sort_key`** front-matter field. Jekyll can't sort by a computed tuple, so the key packs author position and date into one ascending integer:

```
author_sort_key = author_position * 100000000
                + (9999 - year)    * 10000
                + (99   - month)   * 100
                + (99   - day)
```

e.g. `2025-09-15`, first author → `1 79749084`. Ascending sort therefore yields: first-author papers first, and within the same position, newer first. When adding a publication, set `author_position` and compute `author_sort_key` to match — a wrong key silently misplaces the entry with no build error. Two accepted-but-unpublished 2026 papers deliberately use the month/day slots `99`/`98` to pin them to the top of their year.

### Author name highlighting

`site.author.publication_highlight_name` (`"Xu Z"` in `_config.yml`) is the string that gets wrapped in `<span class="pub-item__self">` to visually mark the site owner. It is applied by literal string split/replace in two places: `_includes/publications-authors-fragment.html` (publications list, matching the `Xu Z` initials style used in `_publications/*` front matter) and `_includes/news.html`. It is **not** applied to `_data/selected_publications.yml` — those entries use full names and mark the author with inline `<u>Ziqi Xu</u>` instead.

### CV

Two independent paths exist:

- `/cv/` (`_pages/cv.md`) — the live one. Just embeds and links `files/cv.pdf`; peer-reviewed papers intentionally live only on `/publications/`. Updating the CV means replacing the PDF.
- `/cv-json/` (`_pages/cv-json.md` → `_includes/cv-template.html` → `_data/cv.json`) — upstream's structured CV, currently unlinked from the nav. `_layouts/cv-layout.html` belongs to this path and is not used by any page.

## Styling

`assets/css/main.scss` is the single entry point and its `@import` list is **order-sensitive** (variables and theme partials must precede layout partials). Add new partials to `_sass/layout/` and register them there.

Theming: `site_theme` in `_config.yml` selects a light/dark pair under `_sass/theme/` interpolated into `main.scss` at build time. Runtime light/dark switching is handled in `assets/js/_main.js` via a `data-theme` attribute on `<html>` plus `localStorage`, defaulting to the system preference — so any new CSS color needs to work under both, ideally via the existing variables in `_sass/include/_global_link_vars.scss` and `_sass/include/_accent_pink.scss` (the site's rose accent overrides).

## GitHub Actions

`.github/workflows/scrape_talks.yml` runs `talkmap.ipynb` on pushes touching `_talks/**` or `talkmap.ipynb`: it geocodes talk locations and **commits back to the repo**. Expect an automated "Automated update of talk locations" commit after editing talks, and pull before continuing. The talk map page is currently disabled (`talkmap_link: false`).
