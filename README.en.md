# kccistc-semiconductor-academy

[한국어](README.md) | English

Utilities, templates, and operating materials built while running the KCCI semiconductor academy course workflow.

This repository is intentionally course-facing. Keep reusable classroom automation, assignment packaging helpers, deliverable templates, and shared materials here. Keep personal machine automation and unrelated operator tools in `~/git/tool`.

## Layout

- `clear-spreadsheet/`: clean `.xlsx` files whose Google Sheets view shows unintended table or theme background colors.
- `classroom/deliverable-share/`: validate Google Classroom deliverables, share Drive folders, and generate private-comment copybooks.
- `classroom/project-packager/`: build project submission folders from stable KCCI report, schedule, journal, media, and source-bundle patterns.

## Boundaries

- Course/classroom-specific automation belongs here.
- Credentials, OAuth tokens, local `config.local.json`, generated submission reports, and virtualenvs stay out of Git.
- Personal utilities, session management, STT helpers, archive tooling, and non-course operator scripts stay in `~/git/tool`.

## Quick Start

Each tool keeps its own setup and run script.

```sh
cd clear-spreadsheet
./setup.sh
./run.sh /path/to/workbook.xlsx
```

```sh
cd classroom/deliverable-share
./setup.sh
./run.sh scan --config config.local.json --scope all
```

```sh
cd classroom/project-packager
./setup.sh
./run.sh build examples/uart_loopback/config.json
```
