# classroom-project-packager

[한국어](README.md) | English

Builds a class project submission folder from one config file, for example `김연우_20260420_stopwatch+watch` or `김연우_20260427_UART_LOOPBACK`.

The submission rules are in [rules.en.md](rules.en.md).

## Output

- submission folder
- copies of slides, video, and source
- completion report `.docx` (from the official template)
- schedule `.xlsx` (from the official template)
- journal `.md`

It does not export PDFs. Export the final PDFs yourself.

## Install

```sh
./setup.sh
```

## Usage

Build the submission folder:

```sh
./run.sh build examples/uart_loopback/config.json
```

Set the output folder:

```sh
./run.sh build examples/uart_loopback/config.json \
  --target-dir ~/Downloads/김연우_20260427_UART_LOOPBACK_test
```

Override a config variable:

```sh
./run.sh build examples/uart_loopback/config.json \
  --var package_name=김연우_20260427_UART_LOOPBACK_test
```

### Inspecting templates

Paragraph and table indexes in a DOCX template:

```sh
./run.sh inspect-docx "/path/to/template.docx"
```

Merged cells and row layout in an XLSX template:

```sh
./run.sh inspect-xlsx "/path/to/template.xlsx"
```

Slide text from the final deck:

```sh
./run.sh outline-pptx "/path/to/final_presentation.pptx"
./run.sh outline-pptx "/path/to/final_presentation.pptx" \
  --output ~/Downloads/final_presentation_outline.md
```

## Config

The config is a JSON file.

| Key | Purpose |
| --- | --- |
| `variables` | name and path variables |
| `target_dir` | output folder |
| `copies` | file copies such as slides and video |
| `directories` | source folder copies |
| `text_files` | text files such as `README.md` |
| `regex_replacements` | path fixes after copying, mostly in `.xpr` |
| `delete_globs` | files to delete, such as `.DS_Store` |
| `report_docx` | completion report |
| `schedule_xlsx` | schedule; `keep_sheets` and `remove_sheets` choose the sheets |
| `journal_md` | journal |

Long content can live in separate files through `paragraph_updates_file`, `tables_file`, `rows_file`, and `source_markdown`.

Reports and schedules can be built two ways:

- copy an existing edited `.docx` or `.xlsx`
- start from the official template and fill given paragraphs, tables, and cells

The [UART example](examples/uart_loopback/config.json) uses the first way. For the second, find the indexes with `inspect-docx` and `inspect-xlsx`, then add `paragraph_updates_file`, `tables_file`, or `rows_file`.

Example files:

- [examples/uart_loopback/config.json](examples/uart_loopback/config.json)
- [examples/uart_loopback/journal.md](examples/uart_loopback/journal.md)
- [examples/uart_loopback/source_bundle_readme.md](examples/uart_loopback/source_bundle_readme.md)
- [examples/uart_loopback/source_bundle_gitignore.txt](examples/uart_loopback/source_bundle_gitignore.txt)

## Templates

- `templates/daily-log/TYPE_MIX_복합_일지_양식.docx`: journal template for mixed-work days

## Notes

- It overwrites only the files and folders the config names.
- It is built around my own submission folder names and templates.
