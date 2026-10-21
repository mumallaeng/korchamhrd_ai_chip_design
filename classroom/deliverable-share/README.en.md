# classroom-deliverable-share

[한국어](README.md) | English

Checks Classroom submissions in a local Google Drive sync folder, shares each student's folder on Drive, and builds copybooks for private comments.

## Commands

- `scan`: check submission folders against the roster
- `normalize-names`: normalize Korean filenames (macOS and Windows)
- `extract-missing-zips`: unpack zip-only submissions and repair garbled names
- `share-drive`: create or change Drive permissions per student folder
- `classroom-build-comment-plan`: build a workbook for pasting private comments

Private comments are not posted through the API; you paste them into Classroom from the workbook.

## Setup

1. In Google Cloud, enable the Google Drive API and Google Classroom API, and create an OAuth client for a desktop app.
2. Install the environment.

   ```bash
   ./setup.sh
   ```

3. Copy the config.

   ```bash
   cp examples/config.sample.json config.local.json
   ```

   Fill in these values in `config.local.json`:

   - Classroom and Drive sync paths
   - roster workbook path and columns
   - course and coursework IDs
   - output folder
   - OAuth token and client secret paths

## Usage

Check submission folders:

```bash
./run.sh scan --config config.local.json --scope all
```

Share Drive folders with edit access:

```bash
./run.sh share-drive --config config.local.json --scope all --role writer --apply
```

Switch to view access:

```bash
./run.sh share-drive --config config.local.json --scope all --role viewer --apply
```

Build the private-comment workbook:

```bash
./run.sh classroom-build-comment-plan --config config.local.json --scope all
```

Output files:

- `share-plan.csv`
- `validation-report.csv`
- `classroom-comment-plan.csv`
- `classroom-private-comment-copybook.xlsx`
- `classroom-private-comment-copybook-submitters.xlsx`
- `classroom-private-comment-copybook-ready.xlsx`

## Workflow

1. Sync Classroom submissions to the local Google Drive folder
2. Unpack zip-only submissions
3. Normalize filenames
4. Review `validation-report.csv`
5. Share each student's folder on Drive
6. Paste private comments from the workbook

## Notes

- A Google Drive sync folder must exist on the local disk.
- On macOS Google Drive, Korean names can look decomposed in Finder or the shell even when they are the same file.

## Tests

```bash
./.venv/bin/python -m unittest discover -s tests
```

## License

MIT
