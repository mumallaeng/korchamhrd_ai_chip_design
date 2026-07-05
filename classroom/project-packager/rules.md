영문 버전은 [rules.en.md](rules.en.md)를 확인하세요.

# Classroom Project Packaging Rules

## 내용 기준

- 최종 발표자료가 가장 우선하는 기준입니다.
- 완료보고서, 일정표, 일지는 모두 최종 발표자료와 일치해야 합니다.
- 발표자료가 바뀌면 완료보고서, 일정표, 일지도 해당 최종본 기준으로 다시 생성하거나 수정합니다.

## 참고 스타일

- 학생 본인의 이전 project 폴더를 style reference로 사용합니다.
- 다른 학생의 폴더를 문장이나 style source로 사용하지 않습니다.
- 다른 학생의 폴더는 layout 확인 용도로만 읽을 수 있으며, 내용 차용에는 사용하지 않습니다.

## 출력 정책

- 최종 PDF export는 사용자가 직접 수행하는 단계입니다.
- 자동화는 `.docx`, `.xlsx`, `.md`처럼 편집 가능한 source를 작성합니다.
- 생성된 PDF를 editable master로 취급하지 않습니다.

## 일지 정책

- 과제가 명시적으로 `개발일지`를 요구하지 않는 한 기본 표현은 `일지`입니다.
- 일정표와 일지는 날짜와 작업 theme가 서로 맞아야 합니다.
- 일정표에서 해당 날짜를 이론 학습으로 기록했다면, 일지에서 무관한 구현 작업을 쓴 것으로 처리하지 않습니다.

## 보고서 정책

- 완료보고서는 공식 template를 따릅니다.
- 보고서는 최종 발표자료의 흐름을 설명해야 하며, 무관한 기술 요약으로 바꾸지 않습니다.
- 발표자료가 "이전 project의 한계"에서 시작한다면 보고서도 그 framing을 유지합니다.

## 소스코드 정책

- source code는 수업에서 다룬 version과 가깝게 유지합니다.
- debugging과 cleanup은 허용하지만, 수업에서 다룬 범위와 지나치게 달라지지 않게 합니다.
- Vivado project라면 복사된 source bundle을 `.xpr`에서 바로 열 수 있어야 합니다.
- 복사된 `.xpr` 파일은 bundle을 self-contained하게 만드는 데 필요한 만큼만 patch합니다.

## 안전 정책

- 다른 학생의 폴더는 절대 수정하지 않습니다.
- folder layout 비교가 필요할 때만 read-only inspection을 허용합니다.
- config가 명시적으로 다르게 지정하지 않는 한 생성 output은 의도한 target package folder 안에만 둡니다.

## 이름 규칙

- 다음과 같은 제출 파일명 style을 유지합니다.
  - `{학생명}_{YYYYMMDD}_{프로젝트명}_발표자료.pptx`
  - `{학생명}_{YYYYMMDD}_{프로젝트명}_동영상.mp4`
  - `{학생명}_{YYYYMMDD}_{프로젝트명}_완료보고서.docx`
  - `{학생명}_{YYYYMMDD}_{프로젝트명}_일정표.xlsx`
  - `{학생명}_{YYYYMMDD}_{프로젝트명}_일지.md`
  - `{학생명}_{YYYYMMDD}_{프로젝트명}_소스코드/`

## 운영 checklist

생성 전:

- 학생 본인의 이전 project folder reference 확인
- 공식 template path 확인
- 최종 발표자료 deck path 확인
- 실제 source-code project path 확인
- 일지 이름을 `일지`로 쓸지 `개발일지`로 쓸지 확인

마무리 전:

- 완료보고서가 최종 발표자료를 반영하는지 확인
- 일정표가 같은 흐름을 반영하는지 확인
- 일지 날짜와 일정표 날짜가 맞는지 확인
- source bundle이 `.xpr`에서 열리는지 확인
- PDF export가 자동으로 수행되지 않았는지 확인
