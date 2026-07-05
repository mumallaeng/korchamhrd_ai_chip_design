영문 버전은 [README.en.md](README.en.md)를 확인하세요.

# classroom-deliverable-share

`kccistc-semiconductor-academy/classroom`에 포함된 Google Classroom / Drive 제출물 운영 도구입니다.

로컬 Google Drive 동기화 폴더에 있는 Classroom 제출물을 검증하고, 제출 폴더 공유와 비공개 댓글용 copybook 생성을 준비합니다.

이 도구는 다음 상황을 위한 것입니다.

- Google Drive / Classroom 제출 폴더를 로컬에 동기화해 관리하는 경우
- 필수 산출물을 파일명, 확장자, 유형 기준으로 검증해야 하는 경우
- 압축 해제된 제출 폴더를 학생에게 다시 Drive로 공유해야 하는 경우
- Classroom 비공개 댓글을 직접 붙여 넣기 위한 workbook이 필요한 경우

로컬에서 운영자가 확인하고 실행하는 workflow를 전제로 합니다.

- `scan`: 명단 기준으로 로컬 제출 폴더 검사
- `normalize-names`: macOS / Windows 간 처리를 위해 한글 중심 파일명 정규화
- `extract-missing-zips`: zip만 제출된 경우 압축 해제 및 mojibake 복구
- `share-drive`: 학생별 제출 폴더 Drive 권한 생성 또는 갱신
- `classroom-build-comment-plan`: 비공개 댓글 붙여넣기용 workbook 생성

이 도구는 Classroom 비공개 댓글을 API로 직접 게시하지 않습니다. 대신 수동 붙여넣기용 workbook을 생성합니다.

## 기능

- 로컬 동기화 경로 기준 Google Drive 폴더 해석
- Google Classroom coursework / submission 매칭
- macOS 한글 NFC 정규화와 zip 파일명 복구
- 누락 산출물, 잘못된 파일명, 잘못된 형식에 대한 그룹화된 검증 메시지
- Drive 권한을 `writer` / `viewer`로 전환

## 빠른 시작

### 1. Google API 활성화

Google Cloud에서 다음 API를 활성화합니다.

- Google Drive API
- Google Classroom API

Desktop app용 OAuth client를 만들고, client secret JSON은 Git 밖에 보관합니다.

### 2. 환경 준비

```bash
./setup.sh
```

### 3. sample config 복사

```bash
cp examples/config.sample.json config.local.json
```

이후 다음 항목을 수정합니다.

- 로컬 Classroom / Drive 동기화 경로
- 명단 workbook 경로와 column
- course / coursework ID
- output directory
- OAuth token / client-secret 경로

`config.local.json`과 token 파일은 커밋하지 않습니다.

### 4. 제출 폴더 스캔

```bash
./run.sh scan --config config.local.json --scope all
```

### 5. Drive 폴더 공유

편집 권한을 부여합니다.

```bash
./run.sh share-drive --config config.local.json --scope all --role writer --apply
```

이후 보기 권한으로 낮출 수 있습니다.

```bash
./run.sh share-drive --config config.local.json --scope all --role viewer --apply
```

### 6. Classroom 댓글 workbook 생성

```bash
./run.sh classroom-build-comment-plan --config config.local.json --scope all
```

생성 파일 예시는 다음과 같습니다.

- `share-plan.csv`
- `validation-report.csv`
- `classroom-comment-plan.csv`
- `classroom-private-comment-copybook.xlsx`
- `classroom-private-comment-copybook-submitters.xlsx`
- `classroom-private-comment-copybook-ready.xlsx`

## 예시 workflow

1. Classroom 제출물을 로컬 Google Drive mirror로 동기화합니다.
2. zip만 제출된 항목이 있으면 압축을 풉니다.
3. cross-platform 처리를 위해 이름을 정규화합니다.
4. `validation-report.csv`를 생성하고 확인합니다.
5. 압축 해제된 폴더를 학생에게 Drive로 공유합니다.
6. workbook을 열고 Classroom 비공개 댓글을 수동으로 붙여 넣습니다.

## 제한사항

- 로컬 디스크에 Google Drive 동기화 root가 있다고 가정합니다.
- Classroom 비공개 댓글은 workbook 초안으로만 준비하며, 여기서 API로 제출하지 않습니다.
- macOS Google Drive mount에서는 파일시스템이 NFC/NFD를 같은 파일로 처리하더라도 Finder나 shell 표시가 decomposed처럼 보일 수 있습니다.

## 개발

테스트 실행:

```bash
./.venv/bin/python -m unittest discover -s tests
```

## License

MIT
