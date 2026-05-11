# CAPTURE.md

> How to get raw material into your KOS vault. This document covers the Field Notes
> scanning workflow — from physical page to ingested wiki entry.

---

## Overview

KOS accepts two kinds of Field Notes input:

- **Typed transcripts** — you type the content of a page directly into a `.md` file
  under `raw/`
- **Scanned PDFs** — you scan the page with your phone and upload the PDF; the LLM
  reads your handwriting directly

Scanned PDFs are recommended. The Proton Drive built-in scanner applies edge
detection, contrast correction, and perspective correction before creating the PDF,
giving the LLM cleaner input than a raw photo. Because scanning happens inside
Proton Drive, the workflow is device-agnostic — Android, iPhone, or any device with
the Proton Drive app works identically.

---

## Scanning Workflow

### Step 1: Scan in Proton Drive

1. Open the **Proton Drive** app on your phone
2. Navigate to your Field Notes folder: `/Photos/Field-Notes/FR-vol-XXX/` (or the
   appropriate volume folder)
3. Tap the **+** button → **Scan document**
4. Follow these capture guidelines:
   - Lay your Field Notes flat — good lighting, no shadows
   - Shoot straight down, not at an angle
   - Scan one page at a time for best results
5. Proton Drive auto-detects edges and corrects perspective
6. Save the scan — it uploads directly to Proton Drive as a PDF

### Step 2: Name the file

The filename tells the LLM how many physical layers the scan contains. Rename the
file in Proton Drive using this convention:

| Suffix | When to use |
|--------|-------------|
| `page-XXX.pdf` | Bare page — no stickies, nothing obscuring the page |
| `page-XXX-sticky.pdf` | Sticky note sitting on top of the page — scan shows the sticky front and whatever page text is visible around it |
| `page-XXX-under.pdf` | Sticky peeled back (not removed) — reveals the page text hidden beneath it |
| `page-XXX-flip.pdf` | Back of the sticky only — captured while peeled back |

**Example.** A page with a sticky note that has writing on both sides requires three
scans:

```
page-007-sticky.pdf    ← sticky front visible, partial page text
page-007-under.pdf     ← page text beneath the sticky (sticky peeled back, not removed)
page-007-flip.pdf      ← back of the sticky only
```

The LLM merges all three into one source page: `wiki/sources/FR-vol-001-page-007.md`.

**Naming tips.** If you prefer dates or descriptions over sequential page numbers,
both work:

```
page-2026-05-05-sticky.pdf
page-orchestration-notes.pdf
```

Keep names lowercase and hyphen-separated — no spaces.

### Step 3: Rclone syncs to Ubuntu

Rclone automatically syncs your Proton Drive to your local machine every 5 minutes.
Files land at:

```
~/Documents/ProtonDrive/Photos/Field-Notes/FR-vol-001/page-007-sticky.pdf
```

#### Rclone Setup (one-time)

**Install the latest Rclone.** Do not use `apt` — the version in the Ubuntu repos is
outdated and may not support Proton Drive. Use the official install script:

```bash
sudo -v ; curl https://rclone.org/install.sh | sudo bash

# Verify — must be 1.63 or higher
rclone --version
```

**Install fuse** (required for mounting):

```bash
sudo apt install fuse3 -y
```

**Configure Proton Drive:**

```bash
rclone config
```

Walk through the prompts:

- Press `n` → new remote
- Name it `proton`
- Select `Proton Drive` from the storage list
- Enter your Proton email and password
- If prompted `Use auto config?` → type `y` → a browser window opens → log in and
  authorize
- If you have 2FA, the flow handles it

**Create the local sync folder:**

```bash
mkdir -p ~/Documents/ProtonDrive/Photos/Field-Notes
```

**Test the connection:**

```bash
rclone ls proton:
```

**Dry run first** (safety check — confirms nothing gets deleted accidentally):

```bash
rclone sync proton:Photos/Field-Notes \
  ~/Documents/ProtonDrive/Photos/Field-Notes \
  --dry-run
```

If the output looks correct, run live:

```bash
rclone sync proton:Photos/Field-Notes \
  ~/Documents/ProtonDrive/Photos/Field-Notes
```

#### Automate with systemd (runs every 5 minutes)

Create the service file:

```bash
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/proton-sync.service
```

Paste:

```ini
[Unit]
Description=Rclone sync Proton Drive Field Notes
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/rclone sync proton:Photos/Field-Notes \
  /home/%u/Documents/ProtonDrive/Photos/Field-Notes \
  --verbose

[Install]
WantedBy=default.target
```

Save: `Ctrl+O` → Enter → `Ctrl+X`

Create the timer file:

```bash
nano ~/.config/systemd/user/proton-sync.timer
```

Paste:

```ini
[Unit]
Description=Sync Proton Drive Field Notes every 5 minutes

[Timer]
OnBootSec=2m
OnUnitActiveSec=5m
Unit=proton-sync.service

[Install]
WantedBy=timers.target
```

Save: `Ctrl+O` → Enter → `Ctrl+X`

Enable and start:

```bash
systemctl --user enable proton-sync.timer
systemctl --user start proton-sync.timer

# Confirm it is running
systemctl --user status proton-sync.timer
```

### Step 4: Move files into `raw/`

Once synced, move the PDFs into the correct memo book folder under `raw/`:

```bash
mv ~/Documents/ProtonDrive/Photos/Field-Notes/FR-vol-001/*.pdf \
   /path/to/your/vault/raw/Field-Research/FR-vol-001/
```

If you want to skip this step, configure Rclone to sync directly into `raw/` instead
of an intermediate folder — both approaches work.

### Step 5: Run `/kos-ingest`

Open your AI agent, navigate to your vault, and run:

```
/kos-ingest
```

The LLM will:

1. Detect the filename suffixes and determine capture mode
2. Collect companion scans (`-sticky`, `-under`, `-flip`) into one composite source
3. Read your handwriting directly from the scanned PDF
4. Extract dates, entities, concepts, questions, and bit.ly slugs
5. Create wiki pages per `SCHEMA.md`

---

## Full Flow at a Glance

```
📸 Scan in Proton Drive app
        ↓
  Name the file with the correct suffix
  (page-XXX, page-XXX-sticky, page-XXX-under, page-XXX-flip)
        ↓
  Proton Drive uploads automatically
        ↓
  Rclone syncs to Ubuntu every 5 minutes
  ~/Documents/ProtonDrive/Photos/Field-Notes/
        ↓
  Move PDFs into raw/Field-Research/FR-vol-XXX/
        ↓
  Run /kos-ingest
        ↓
  LLM merges companion scans, reads handwriting,
  extracts structure, creates wiki pages
        ↓
  Browse results in Obsidian
```

---

## File Format Notes

**PDF is required.** Proton Drive's built-in scanner outputs PDF — use it as-is.
Do not convert to JPEG or PNG before uploading.

**HEIC** is not supported by KOS. If you are uploading raw photos rather than
Proton Drive scans, convert them to JPEG first. Proton Drive scans avoid this issue
entirely since they output PDF directly.

**One page per scan.** Two-page spreads reduce transcription accuracy. Scan each
Field Notes page individually.

---

## Troubleshooting

**Rclone version below 1.63** — Proton Drive support was added in v1.63. Never use
`sudo apt install rclone`. Always use the official install script above.

**Files not syncing** — check the timer status:

```bash
systemctl --user status proton-sync.timer
```

Run Rclone manually to diagnose:

```bash
rclone sync proton:Photos/Field-Notes \
  ~/Documents/ProtonDrive/Photos/Field-Notes \
  --verbose
```

**LLM misreads handwriting** — scan quality is the primary variable. Ensure good
lighting, no shadows, and the page lying flat. The Proton Drive scanner will
outperform a raw photo every time.

**`-sticky` scanned but forgot to scan `-under`** — `/kos-lint` will flag this as
an orphaned companion after 24 hours. Just scan the page without the sticky, name it
correctly, and upload it. The LLM merges on the next `/kos-ingest` run.

**Proton Drive scan option not visible** — ensure the Proton Drive app is updated to
the latest version. The scan feature is available on both Android and iOS.

---

*Part of [KOS](https://github.com/k0d3x8its/kos) — the Layer 1 toolkit for
[Kodex OS](https://github.com/k0d3x8its/kodex-os).*
