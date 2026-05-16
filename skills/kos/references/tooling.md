# Tooling Reference

CLI tools that extend the LLM's capabilities when working with a KOS vault.

## Recommended

### Obsidian Web Clipper

Browser extension that saves web articles as clean markdown files directly into your vault's `raw/` directory. Recommended if you ingest web content into your KOS vault. Not required if your sources are exclusively Field Notes scans, transcripts, or other non-web material.

* **Install:** Chrome Web Store — <https://chromewebstore.google.com/detail/obsidian-web-clipper/cnjifjpddelmedmihgijeibhnjfabmlf>
* **Setup:** After installing, configure the default vault location to point to your vault's `raw/` directory (a `raw/clippings/` subfolder is a common target)
* **When to use:** Saving articles, papers, blog posts, and any web-native source material into your vault for later ingestion

## Optional

### summarize

Summarize turns links, files, and media into sharp summaries with a real extraction pipeline. Use the CLI for automation or the Chrome Side Panel for one-click summaries.

- **Install:** `npm i -g @steipete/summarize`
- **Verify:** `summarize --version`
- **Usage:** `summarize --help` for full feature list
- **When to use:** Summarizing web pages, PDFs, videos, or any media before or during ingestion

### qmd

QMD (Query Markup Documents) is a local search engine for markdown files with hybrid BM25/vector search and LLM re-ranking, all on-device.

- **Install:** `npm i -g @tobilu/qmd`
- **Verify:** `qmd --version`
- **Usage:** `qmd --help` for full feature list
- **When to use:** When the wiki grows beyond what `wiki/index.md` can efficiently navigate (~100+ pages)

### agent-browser

Browser automation CLI for AI agents. Fast native Rust CLI. Use for web research and scraping when native web_search, web_fetch, or computer use tools fail.

- **Install:** `npm i -g agent-browser && agent-browser install`
- **Verify:** `agent-browser --version`
- **Usage:** `agent-browser --help` for full feature list
- **When to use:** Web research tasks where built-in tools fail or return incomplete results

### faster-whisper

Local speech-to-text engine for transcribing audio and video files to markdown. Runs entirely on-device — no API key or internet connection required. Used by KOS Capture to transcribe Proton Meet recordings, YouTube videos, and podcast episodes before ingest.

- **Install:** `pip install faster-whisper`
- **Verify:** `python -c "import faster_whisper; print('ok')"`
- **Usage:** handled automatically by KOS Capture; can also be used directly from Python
- **When to use:** generating transcripts from any audio or video file before dropping into `raw/transcripts/`

### yt-dlp

Downloads audio and video from YouTube, podcast RSS feeds, and hundreds of other sources. Used by KOS Capture as the extraction step before faster-whisper transcription.

- **Install:** `pip install yt-dlp`
- **Verify:** `yt-dlp --version`
- **Usage:** `yt-dlp --help` for full feature list
- **When to use:** pulling audio from a YouTube URL or podcast feed before transcription
