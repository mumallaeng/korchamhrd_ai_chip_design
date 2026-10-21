# classroom-deliverable-share

한국어 | [English](README.en.md)

로컬 Google Drive 동기화 폴더에 있는 Classroom 제출물을 검사하고, 학생별 폴더를 Drive로 공유하고, 비공개 댓글용 copybook을 만듭니다.

## 명령

- `scan`: 명단 기준으로 제출 폴더 검사
- `normalize-names`: 한글 파일명 정규화(macOS·Windows)
- `extract-missing-zips`: zip만 제출된 경우 압축 해제, 깨진 파일명 복구
- `share-drive`: 학생별 제출 폴더 Drive 권한 생성·변경
- `classroom-build-comment-plan`: 비공개 댓글 붙여넣기용 workbook 생성

비공개 댓글은 API로 게시하지 않고, workbook을 보며 Classroom에 직접 붙여 넣습니다.

## 준비

1. Google Cloud에서 Google Drive API와 Google Classroom API를 켜고, Desktop app용 OAuth client를 만듭니다.
2. 환경을 설치합니다.

   ```bash
   ./setup.sh
   ```

3. 설정 파일을 복사합니다.

   ```bash
   cp examples/config.sample.json config.local.json
   ```

   `config.local.json`에서 다음 값을 채웁니다.

   - Classroom·Drive 동기화 경로
   - 명단 workbook 경로와 열
   - course·coursework ID
   - 출력 폴더
   - OAuth token·client secret 경로

## 사용

제출 폴더 검사:

```bash
./run.sh scan --config config.local.json --scope all
```

Drive 폴더 공유(편집 권한):

```bash
./run.sh share-drive --config config.local.json --scope all --role writer --apply
```

보기 권한으로 변경:

```bash
./run.sh share-drive --config config.local.json --scope all --role viewer --apply
```

비공개 댓글 workbook 생성:

```bash
./run.sh classroom-build-comment-plan --config config.local.json --scope all
```

출력 파일:

- `share-plan.csv`
- `validation-report.csv`
- `classroom-comment-plan.csv`
- `classroom-private-comment-copybook.xlsx`
- `classroom-private-comment-copybook-submitters.xlsx`
- `classroom-private-comment-copybook-ready.xlsx`

## 작업 순서

1. Classroom 제출물을 로컬 Google Drive 폴더로 동기화
2. zip만 제출된 항목 압축 해제
3. 파일명 정규화
4. `validation-report.csv` 확인
5. 학생별 폴더 Drive 공유
6. workbook을 보며 비공개 댓글 붙여 넣기

## 참고

- 로컬 디스크에 Google Drive 동기화 폴더가 있어야 합니다.
- macOS Google Drive에서는 같은 파일이라도 Finder나 shell에서 한글 자모가 분리되어 보일 수 있습니다.

## 테스트

```bash
./.venv/bin/python -m unittest discover -s tests
```

## License

MIT
