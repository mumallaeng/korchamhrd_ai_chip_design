# classroom

[한국어](README.md) | English

Course-facing automation for Korcham HRD on-device AI chip design classroom submissions.

## Tools

- `deliverable-share/`: class-wide Google Classroom and Drive workflow.
  - scan local Drive-synced submissions
  - normalize Korean filenames for safer cross-platform handling
  - validate required deliverables
  - share folders back to students
  - generate Classroom private-comment copybooks

- `project-packager/`: individual project submission pack builder.
  - copy presentation, media, and source bundles
  - generate or update report, schedule, and journal artifacts
  - keep recurring naming and folder conventions consistent

## Local Files

Do not commit local OAuth secrets, Drive tokens, generated class reports, or project-specific private configs. Use `.gitignore` and local config files for those.
