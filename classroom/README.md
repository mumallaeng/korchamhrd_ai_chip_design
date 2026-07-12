영문 버전은 [README.en.md](README.en.md)를 확인하세요.

# classroom

Korcham HRD 온디바이스 AI 반도체 설계 과정의 수업 제출물 운영에 사용하는 자동화와 산출물 패키징 도구를 모아두는 영역입니다.

## 도구

- `deliverable-share/`: 반 전체 Google Classroom / Drive 제출물 공유 workflow입니다.
  - 로컬 Drive 동기화 제출물 스캔
  - macOS/Windows 간 한글 파일명 문제를 줄이기 위한 이름 정규화
  - 필수 산출물 검증
  - 학생별 제출 폴더 Drive 공유
  - Classroom 비공개 댓글용 copybook 생성

- `project-packager/`: 개인 project 제출 폴더 구성 도구입니다.
  - 발표자료, 미디어, 소스 번들 복사
  - 완료보고서, 일정표, 일지 산출물 생성 또는 갱신
  - 반복되는 제출 폴더명과 파일명 규칙 유지

## 로컬 파일

로컬 OAuth secret, Drive token, 생성된 class report, project별 private config는 커밋하지 않습니다. 이런 파일은 `.gitignore`와 local config 파일로 관리합니다.
