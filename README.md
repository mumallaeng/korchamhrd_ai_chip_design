# kccistc-semiconductor-academy

[한국어](README.md) | [English](README.en.md)

KCCI 반도체 설계 과정 운영 중 반복적으로 사용하는 유틸리티, 템플릿, 산출물 패키징 도구, 수업 운영 자료를 모아두는 저장소입니다.

이 저장소는 과정/수업 운영에 직접 연결되는 자료를 두는 곳입니다. 재사용 가능한 Classroom 자동화, 과제 패키징 도구, 산출물 템플릿, 공유 가능한 수업 운영 자료는 여기에 둡니다. 개인 장비 자동화나 수업과 직접 관련 없는 운영 도구는 `~/git/tool`에 둡니다.

## 구성

- `clear-spreadsheet/`: Google Sheets에서 의도하지 않은 표/테마 배경색이 보이는 `.xlsx` 파일을 정리합니다.
- `classroom/deliverable-share/`: Google Classroom 산출물을 검증하고, Drive 폴더 공유와 비공개 댓글용 copybook 생성을 처리합니다.
- `classroom/project-packager/`: KCCI 과제 제출 폴더를 보고서, 일정표, 일지, 미디어, 소스 번들 규칙에 맞춰 구성합니다.

## 범위

- 과정/수업 운영에 직접 연결되는 자동화와 템플릿은 이 저장소에 둡니다.
- 인증 정보, OAuth 토큰, 로컬 `config.local.json`, 생성된 제출물 리포트, virtualenv는 Git에 커밋하지 않습니다.
- 개인 유틸리티, 세션 관리, STT 보조 도구, 아카이브 도구, 수업과 직접 관련 없는 운영 스크립트는 `~/git/tool`에 둡니다.

## 빠른 시작

각 도구는 자기 디렉터리 안에 setup/run 스크립트를 둡니다.

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
