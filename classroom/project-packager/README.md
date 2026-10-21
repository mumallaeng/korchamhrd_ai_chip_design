# classroom-project-packager

한국어 | [English](README.en.md)

설정 파일 하나로 수업 프로젝트 제출 폴더를 만듭니다. 예: `김연우_20260420_stopwatch+watch`, `김연우_20260427_UART_LOOPBACK`

제출 규칙은 [rules.md](rules.md)에 있습니다.

## 만드는 것

- 제출 폴더
- 발표자료·영상·소스 복사본
- 완료보고서 `.docx`(공식 양식 기반)
- 일정표 `.xlsx`(공식 양식 기반)
- 일지 `.md`

PDF 변환은 하지 않습니다. 최종 PDF는 직접 내보냅니다.

## 설치

```sh
./setup.sh
```

## 사용

제출 폴더 생성:

```sh
./run.sh build examples/uart_loopback/config.json
```

출력 폴더 지정:

```sh
./run.sh build examples/uart_loopback/config.json \
  --target-dir ~/Downloads/김연우_20260427_UART_LOOPBACK_test
```

config 변수 덮어쓰기:

```sh
./run.sh build examples/uart_loopback/config.json \
  --var package_name=김연우_20260427_UART_LOOPBACK_test
```

### 양식 확인

DOCX 양식의 문단·표 번호 확인:

```sh
./run.sh inspect-docx "/path/to/template.docx"
```

XLSX 양식의 병합 셀·행 구조 확인:

```sh
./run.sh inspect-xlsx "/path/to/template.xlsx"
```

발표자료 슬라이드 텍스트 추출:

```sh
./run.sh outline-pptx "/path/to/final_presentation.pptx"
./run.sh outline-pptx "/path/to/final_presentation.pptx" \
  --output ~/Downloads/final_presentation_outline.md
```

## Config

config는 JSON 파일입니다.

| 항목 | 내용 |
| --- | --- |
| `variables` | 이름·경로 변수 |
| `target_dir` | 출력 폴더 |
| `copies` | 발표자료·영상 등 파일 복사 |
| `directories` | 소스 폴더 복사 |
| `text_files` | `README.md` 같은 텍스트 파일 생성 |
| `regex_replacements` | 복사 후 경로 수정(주로 `.xpr`) |
| `delete_globs` | `.DS_Store` 같은 파일 삭제 |
| `report_docx` | 완료보고서 생성 |
| `schedule_xlsx` | 일정표 생성. `keep_sheets`·`remove_sheets`로 남길 시트 지정 |
| `journal_md` | 일지 생성 |

긴 내용은 `paragraph_updates_file`, `tables_file`, `rows_file`, `source_markdown`으로 별도 파일에 둘 수 있습니다.

보고서·일정표는 두 방식으로 만들 수 있습니다.

- 기존 `.docx`·`.xlsx` 편집본을 그대로 복사해 사용
- 공식 양식에서 시작해 지정한 문단·표·셀을 채움

[UART 예시](examples/uart_loopback/config.json)는 첫 번째 방식을 씁니다. 두 번째 방식은 `inspect-docx`·`inspect-xlsx`로 번호를 확인한 뒤 `paragraph_updates_file`·`tables_file`·`rows_file`을 추가합니다.

예시 파일:

- [examples/uart_loopback/config.json](examples/uart_loopback/config.json)
- [examples/uart_loopback/journal.md](examples/uart_loopback/journal.md)
- [examples/uart_loopback/source_bundle_readme.md](examples/uart_loopback/source_bundle_readme.md)
- [examples/uart_loopback/source_bundle_gitignore.txt](examples/uart_loopback/source_bundle_gitignore.txt)

## 템플릿

- `templates/daily-log/TYPE_MIX_복합_일지_양식.docx`: 복합 작업일 일지 양식

## 참고

- config에 적힌 파일과 폴더만 덮어씁니다.
- 제 제출 폴더 이름과 양식에 맞춰 만든 도구입니다.
