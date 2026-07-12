# classroom-deliverable-share

[한국어](README.md) | English

Part of `korchamhrd_ai_chip_design/classroom`.

Prepare Google Classroom deliverables from a local Google Drive sync folder.

This project is for teachers or operators who:

- keep a local mirror of Google Drive / Classroom submission folders
- need to validate required artifacts by filename, extension, and type
- want to share extracted deliverable folders back to each student on Drive
- need a copy-paste workbook for Classroom private comments

It is designed for a local, operator-driven workflow:

- `scan`: inspect local submission folders against a roster
- `normalize-names`: normalize Hangul-heavy filenames for safer macOS / Windows handling
- `extract-missing-zips`: extract zip-only submissions with mojibake recovery
- `share-drive`: create or update Drive permissions for each student's folder
- `classroom-build-comment-plan`: build a workbook for private-comment copy/paste

The tool does **not** post Classroom private comments directly. It generates a workbook instead.

## Features

- Google Drive folder resolution by local sync path
- Google Classroom coursework / submission matching
- macOS Hangul NFC normalization and zip filename recovery
- grouped validation messages for missing artifacts, bad filenames, and bad formats
- Drive permission switching between `writer` and `viewer`

## Quick Start

### 1. Enable Google APIs

Enable these APIs in Google Cloud:

- Google Drive API
- Google Classroom API

Create an OAuth client for a desktop app and keep the client secret JSON outside Git.

### 2. Set up the environment

```bash
./setup.sh
```

### 3. Copy the sample config

```bash
cp examples/config.sample.json config.local.json
```

Then edit:

- local Classroom / Drive sync paths
- roster workbook path and columns
- course / coursework IDs
- output directory
- OAuth token / client-secret paths

Do not commit `config.local.json` or token files.

### 4. Scan a deliverable folder

```bash
./run.sh scan --config config.local.json --scope all
```

### 5. Share folders on Drive

Grant edit access:

```bash
./run.sh share-drive --config config.local.json --scope all --role writer --apply
```

Downgrade to view access later:

```bash
./run.sh share-drive --config config.local.json --scope all --role viewer --apply
```

### 6. Build the Classroom comment workbook

```bash
./run.sh classroom-build-comment-plan --config config.local.json --scope all
```

Generated files include:

- `share-plan.csv`
- `validation-report.csv`
- `classroom-comment-plan.csv`
- `classroom-private-comment-copybook.xlsx`
- `classroom-private-comment-copybook-submitters.xlsx`
- `classroom-private-comment-copybook-ready.xlsx`

## Example Workflow

1. Sync Classroom submissions into a local Google Drive mirror.
2. Extract zip-only submissions if needed.
3. Normalize names for safer cross-platform handling.
4. Scan and inspect `validation-report.csv`.
5. Share extracted folders back to each student on Drive.
6. Open the workbook and paste private comments manually into Classroom.

## Limitations

- This tool assumes a local Google Drive sync root exists on disk.
- Classroom private comments are prepared as drafts in a workbook; they are not submitted through the API here.
- Filename normalization on macOS Google Drive mounts may still appear decomposed in Finder or shell listings even when the filesystem treats NFC and NFD as the same file.

## Development

Run tests with:

```bash
./.venv/bin/python -m unittest discover -s tests
```

## License

MIT
