영문 버전은 [README.en.md](README.en.md)를 확인하세요.

# classroom-project-packager

설정 파일을 기준으로 다음과 같은 수업 project 제출 폴더를 구성하는 도구입니다.

- `김연우_20260420_stopwatch+watch`
- `김연우_20260427_UART_LOOPBACK`

폴더 구조는 반복되지만 project별 내용이 바뀌는 FPGA / Verilog 수업 제출물에 맞춰 사용합니다.

## 생성 항목

- 제출 대상 폴더
- 발표자료, 영상, source bundle 복사본
- 공식 template 기반 완료보고서 `.docx`
- 공식 template 기반 일정표 `.xlsx`
- 일지 `.md`

최종 `.pdf` export는 의도적으로 자동화하지 않습니다.

PDF export는 사용자가 직접 수행하는 단계입니다.

## 목적

반복되는 작업 흐름은 다음과 같습니다.

1. 학생 본인의 이전 project 폴더 구조를 따른다.
2. source code를 Vivado에서 바로 열 수 있게 유지한다.
3. 완료보고서, 일정표, 일지를 최종 발표자료와 맞춘다.
4. 파일명과 폴더명 규칙을 유지한다.
5. 같은 패키징 작업을 매번 손으로 반복하지 않는다.

이 도구는 위 작업을 반복 가능한 workflow로 만듭니다.

## 규칙

도구를 사용하기 전에 [rules.md](rules.md)를 읽습니다.

해당 규칙은 선택적 메모가 아니라 workflow의 일부입니다.

## 템플릿

- `templates/daily-log/TYPE_MIX_복합_일지_양식.docx`: 복합 작업 유형 일지 DOCX template.

## 설정

```sh
cd ~/git/korchamhrd_ai_chip_design/classroom/project-packager
./setup.sh
```

## 사용법

### package 생성

```sh
./run.sh build examples/uart_loopback/config.json
```

출력 폴더만 override:

```sh
./run.sh build examples/uart_loopback/config.json \
  --target-dir ~/Downloads/김연우_20260427_UART_LOOPBACK_test
```

config 내부 변수 override:

```sh
./run.sh build examples/uart_loopback/config.json \
  --var package_name=김연우_20260427_UART_LOOPBACK_test
```

### DOCX template 검사

공식 보고서 template의 paragraph/table index mapping을 준비할 때 사용합니다.

```sh
./run.sh inspect-docx "/path/to/template.docx"
```

### XLSX template 검사

merged range, row layout, schedule cell 구조를 파악할 때 사용합니다.

```sh
./run.sh inspect-xlsx "/path/to/template.xlsx"
```

### PPTX slide text 추출

최종 발표자료가 완료보고서, 일정표, 일지 내용의 기준이므로 slide text를 먼저 뽑아 확인할 때 사용합니다.

```sh
./run.sh outline-pptx "/path/to/final_presentation.pptx"
```

추출한 outline을 markdown 파일로 저장:

```sh
./run.sh outline-pptx "/path/to/final_presentation.pptx" \
  --output ~/Downloads/final_presentation_outline.md
```

## Config 구조

main config 파일은 JSON입니다.

주요 section:

- `variables`: 재사용할 이름/경로 변수
- `target_dir`: 최종 출력 폴더
- `copies`: 발표자료, 영상, 파일 복사
- `directories`: source bundle 디렉터리 복사
- `text_files`: `README.md` 같은 text 파일 생성
- `regex_replacements`: 복사 후 path cleanup, 특히 `.xpr`
- `delete_globs`: `.DS_Store` 같은 cleanup 대상
- `report_docx`: 완료보고서 생성
- `schedule_xlsx`: 일정표 생성
- `journal_md`: 일지 생성

유용한 `schedule_xlsx` option:

- `keep_sheets`: 지정 sheet만 남기고 나머지 삭제
- `remove_sheets`: 지정 sheet만 삭제

source workbook에 최종 제출물에 남기면 안 되는 실습용/template sheet가 있을 때 사용합니다.

큰 content block은 별도 파일에 두고 config에서 참조할 수 있습니다.

- `paragraph_updates_file`
- `tables_file`
- `rows_file`
- `source_markdown`

이렇게 하면 main config가 짧아지고 수정 범위가 안전해집니다.

실무적으로는 두 가지 mode가 유용합니다.

- copy-forward mode: 현재 편집 가능한 `.docx` / `.xlsx` master를 source로 재사용
- template-update mode: 공식 template에서 시작해 특정 paragraph/table/cell index를 채움

아래 UART 예시는 완료보고서와 일정표에 copy-forward mode를 사용합니다. 해당 editable master가 이미 최종 발표자료 내용을 반영하고 있기 때문입니다.

## 예시

참고:

- [examples/uart_loopback/config.json](examples/uart_loopback/config.json)
- [examples/uart_loopback/journal.md](examples/uart_loopback/journal.md)
- [examples/uart_loopback/source_bundle_readme.md](examples/uart_loopback/source_bundle_readme.md)
- [examples/uart_loopback/source_bundle_gitignore.txt](examples/uart_loopback/source_bundle_gitignore.txt)

향후 project를 template-update mode로 옮기려면 먼저 공식 template 파일을 검사합니다.

```sh
./run.sh inspect-docx "/path/to/official-report-template.docx"
./run.sh inspect-xlsx "/path/to/schedule-template.xlsx"
```

index mapping이 확인되면 config에 `paragraph_updates_file`, `tables_file`, `rows_file` 등을 추가합니다.

## 주의사항

- 이 도구는 config가 명시적으로 관리하는 파일과 디렉터리만 덮어씁니다.
- PDF output은 생성하지 않습니다.
- 완료보고서와 일정표 template이 안정적이고 사용자가 관리한다고 가정합니다.
- 반 전체의 generic 제출물이 아니라, 사용자 본인의 project 폴더와 naming convention에 맞게 설계되어 있습니다.
