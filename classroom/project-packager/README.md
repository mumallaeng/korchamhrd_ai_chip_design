# classroom-project-packager

Config-driven helper for building classroom project submission folders like:

- `김연우_20260420_stopwatch+watch`
- `김연우_20260427_UART_LOOPBACK`

This tool is meant for recurring FPGA / Verilog class submissions where the folder layout is stable but the project-specific content changes.

## What It Generates

- target submission folder
- copied presentation/video/source bundle
- completion report `.docx` from the official template
- schedule `.xlsx` from the official template
- journal `.md`

It intentionally does **not** export final `.pdf` files.

PDF export is a manual user step.

## Why This Exists

The recurring task pattern is:

1. follow a known folder layout from the student's own prior project
2. keep source code Vivado-openable
3. align report/schedule/journal with the final presentation deck
4. preserve naming conventions
5. avoid redoing the same packaging work by hand

This tool turns that into a repeatable workflow.

## Rules

Read [rules.md](rules.md) before using the tool.

Those rules are part of the workflow, not optional notes.

## Templates

- `templates/daily-log/TYPE_MIX_복합_일지_양식.docx`: mixed work-type daily-log DOCX template.

## Setup

```sh
cd ~/git/kccistc-semiconductor-academy/classroom/project-packager
./setup.sh
```

## Usage

### Build a package

```sh
./run.sh build examples/uart_loopback/config.json
```

Override only the output folder:

```sh
./run.sh build examples/uart_loopback/config.json \
  --target-dir ~/Downloads/김연우_20260427_UART_LOOPBACK_test
```

Override variables used inside the config:

```sh
./run.sh build examples/uart_loopback/config.json \
  --var package_name=김연우_20260427_UART_LOOPBACK_test
```

### Inspect a DOCX template

This is useful when preparing paragraph/table index mappings for the official report template.

```sh
./run.sh inspect-docx "/path/to/template.docx"
```

### Inspect an XLSX template

This helps when understanding merged ranges, row layout, and schedule cells.

```sh
./run.sh inspect-xlsx "/path/to/template.xlsx"
```

### Extract slide text from a PPTX

This is useful because the final presentation is the source of truth for report/schedule/journal content.

```sh
./run.sh outline-pptx "/path/to/final_presentation.pptx"
```

Write the extracted outline to a markdown file:

```sh
./run.sh outline-pptx "/path/to/final_presentation.pptx" \
  --output ~/Downloads/final_presentation_outline.md
```

## Config Structure

The main config file is JSON.

Typical sections:

- `variables`: reusable naming/path variables
- `target_dir`: final output folder
- `copies`: presentation/video/file copies
- `directories`: source bundle copies
- `text_files`: generated text files such as `README.md`
- `regex_replacements`: post-copy path cleanup, especially for `.xpr`
- `delete_globs`: cleanup like `.DS_Store`
- `report_docx`: completion report generation
- `schedule_xlsx`: schedule generation
- `journal_md`: journal generation

Useful `schedule_xlsx` options:

- `keep_sheets`: keep only the named sheets and delete the rest
- `remove_sheets`: delete only the named sheets

This is useful when the source workbook contains unrelated practice or template sheets that should not remain in the final submission.

Large content blocks can live in separate files and be referenced from the config:

- `paragraph_updates_file`
- `tables_file`
- `rows_file`
- `source_markdown`

This keeps the main config short and makes edits safer.

In practice there are two useful modes:

- copy-forward mode: reuse the current editable `.docx` / `.xlsx` masters as sources
- template-update mode: start from the official template and fill specific paragraph/table/cell indices

The UART example below uses copy-forward mode for the report and schedule, because those editable masters already reflect the final presentation.

## Example

See:

- [examples/uart_loopback/config.json](examples/uart_loopback/config.json)
- [examples/uart_loopback/journal.md](examples/uart_loopback/journal.md)
- [examples/uart_loopback/source_bundle_readme.md](examples/uart_loopback/source_bundle_readme.md)
- [examples/uart_loopback/source_bundle_gitignore.txt](examples/uart_loopback/source_bundle_gitignore.txt)

When you want to move a future project to template-update mode, first inspect the official template files:

```sh
./run.sh inspect-docx "/path/to/official-report-template.docx"
./run.sh inspect-xlsx "/path/to/schedule-template.xlsx"
```

Then add `paragraph_updates_file`, `tables_file`, or `rows_file` to the config once the index mapping is known.

## Notes

- The tool only overwrites files and directories that the config explicitly manages.
- It does not try to generate PDF output.
- It assumes the report and schedule templates are stable and controlled by the user.
- It is designed for the user's own project folders and naming conventions, not class-wide generic submissions.
