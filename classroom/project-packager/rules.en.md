# Classroom Project Packaging Rules

[한국어](rules.md) | English

## Content Source of Truth

- The final presentation deck is the primary source of truth.
- The completion report, schedule, and journal must all match the final presentation.
- If the presentation changed, regenerate or rewrite the report/schedule/journal from that final version.

## Reference Style

- Use the student's own prior project folder as the style reference.
- Do not use other students' folders as the writing/style source.
- Other students' folders may be read for layout awareness only, not for content borrowing.

## Output Policy

- Final PDF export is a manual user step.
- Automation should write editable sources such as `.docx`, `.xlsx`, `.md`.
- Do not treat generated PDF as the editable master.

## Journal Policy

- Default wording is `일지`, not `개발일지`, unless the assignment explicitly requires `개발일지`.
- Schedule and journal must agree on dates and activity themes.
- If the schedule says the day was about theory, the journal should not describe unrelated implementation work.

## Report Policy

- The report should follow the official template.
- The report should describe the final presentation story, not an unrelated technical summary.
- If the presentation starts from "previous project limitation", the report should also carry that framing.

## Source Code Policy

- Keep source code close to the class version.
- Debugging and cleanup are allowed, but do not drift far from what was taught in class.
- If the project uses Vivado, keep the copied source bundle directly openable from `.xpr`.
- Patch copied `.xpr` files only as much as needed to make the copied bundle self-contained.

## Safety Policy

- Never edit other students' folders.
- Read-only inspection is allowed when needed for folder layout comparison.
- Generated outputs should stay inside the intended target package folder unless the config explicitly says otherwise.

## Naming Policy

- Preserve submission naming style such as:
  - `{학생명}_{YYYYMMDD}_{프로젝트명}_발표자료.pptx`
  - `{학생명}_{YYYYMMDD}_{프로젝트명}_동영상.mp4`
  - `{학생명}_{YYYYMMDD}_{프로젝트명}_완료보고서.docx`
  - `{학생명}_{YYYYMMDD}_{프로젝트명}_일정표.xlsx`
  - `{학생명}_{YYYYMMDD}_{프로젝트명}_일지.md`
  - `{학생명}_{YYYYMMDD}_{프로젝트명}_소스코드/`

## Operating Checklist

Before building:

- confirm the student's own prior project folder reference
- confirm the official template paths
- confirm the final presentation deck path
- confirm the real source-code project path
- confirm whether the journal should be called `일지` or `개발일지`

Before finishing:

- verify the report reflects the final presentation
- verify the schedule reflects the same story
- verify the journal dates and schedule dates agree
- verify the source bundle opens from `.xpr`
- verify no PDF export step was silently automated
