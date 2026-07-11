# Git과 GitHub - 공유 실습 노트

Git과 GitHub를 직접 따라 하며 익히는 노트이다.
목표는 혼자 작업한 파일을 기록하고, GitHub에 올리고, 협업 중 생기는 기본 충돌을 해결하는 것이다.
PR, code review, CI/CD 등의 심화 내용은 제외되었으며, 2026 시스템 반도체 설계 2기 학생들 관점에서 이해하기 쉽도록 이론보다 실습에 집중해 작성되었다.
더 깊게 Git과 GitHub를 배우고 싶다면 [Git과 GitHub - Basic](git_and_github-basic.md), [Git과 GitHub - Intermediate](git_and_github-intermediate.md), [Git과 GitHub - Advanced](git_and_github-advanced.md) 문서를 참고한다.

목차

- [0. Git을 사용해야 하는 이유](#0-git을-사용해야-하는-이유)
- [1. 목표 및 준비물](#1-목표-및-준비물)
- [2. Git과 GitHub의 역할](#2-git과-github의-역할)
- [3. 실습 1 - Git 저장소 만들기](#3-실습-1---git-저장소-만들기)
- [4. 실습 2 - 첫 파일 만들고 상태 보기](#4-실습-2---첫-파일-만들고-상태-보기)
- [5. 실습 3 - `add`와 `commit`](#5-실습-3---add와-commit)
- [6. 실습 4 - 파일 수정하고 diff 확인하기](#6-실습-4---파일-수정하고-diff-확인하기)
- [7. 실습 5 - 이력 확인하기](#7-실습-5---이력-확인하기)
- [8. 실습 6 - GitHub에 올리기](#8-실습-6---github에-올리기)
- [9. 실습 7 - GitHub에서 바꾼 내용 가져오기](#9-실습-7---github에서-바꾼-내용-가져오기)
- [10. 실습 8 - 충돌 만들어보기](#10-실습-8---충돌-만들어보기)
- [11. 실습 9 - 충돌 해결하기](#11-실습-9---충돌-해결하기)
- [12. 실습 10 - 올리면 안 되는 파일 제외하기](#12-실습-10---올리면-안-되는-파일-제외하기)
- [13. 실습 중 자주 쓰는 명령](#13-실습-중-자주-쓰는-명령)
- [14. 실습 마무리 체크](#14-실습-마무리-체크)
- [15. 기억할 흐름](#15-기억할-흐름)
- [16. VSCode에서 같은 흐름으로 사용하기](#16-vscode에서-같은-흐름으로-사용하기)
- [17. 대화형 AI를 Git 보조 도구로 쓰기](#17-대화형-ai를-git-보조-도구로-쓰기)

## 0. Git을 사용해야 하는 이유

파일 작업을 계속하다 보면 같은 파일의 여러 버전이 생긴다.

```text
report.md
report_final.md
report_final2.md
report_real_final.md
```

이런 방식은 어떤 파일이 최신인지, 어떤 부분이 언제 바뀌었는지, 문제가 생겼을 때 어디로 되돌아가야 하는지 확인하기 어렵다. Git은 파일 변경을 commit 단위로 기록해서 이 문제를 관리한다.

Git을 쓰는 이유:

| 이유 | 설명 |
|---|---|
| 변경 이력 저장 | 파일이 언제, 어떤 이유로 바뀌었는지 기록 |
| 되돌리기 | 문제가 생긴 commit을 찾아 이전 상태로 복구 |
| 작업 단위 관리 | 여러 변경을 의미 있는 commit 단위로 분리 |
| 공유 기준 제공 | GitHub에 같은 commit 기록을 올려 다른 사람과 공유 |
| 충돌 확인 | 여러 사람이 같은 파일을 수정했을 때 겹치는 부분 확인 |

Git 작업은 먼저 내 컴퓨터의 local repository에 commit으로 기록하고, 필요한 시점에 GitHub remote repository로 push하는 흐름으로 진행한다.

```text
파일 수정
-> git add
-> git commit
-> git push
```

Git을 쓰면 작업 폴더의 현재 상태와 기록된 상태를 구분할 수 있고, GitHub를 함께 쓰면 같은 기록을 다른 사람과 공유할 수 있다.

## 1. 목표 및 준비물

이 노트에서 다루는 범위:

- 작업 폴더를 Git 저장소로 만들기
- 파일 수정 후 `status`, `diff`로 확인하기
- `add`로 이번 기록에 넣을 파일 선택하기
- `commit`으로 작업 기록 만들기
- GitHub 원격 저장소에 `push`하기
- GitHub 변경을 `pull`로 가져오기
- 간단한 충돌 직접 해결하기

준비물:

- Git 설치
- GitHub 계정
- 터미널 또는 Git Bash
- 실습용 빈 폴더

실습 폴더 예시:

```sh
mkdir git-practice
cd git-practice
```

## 2. Git과 GitHub의 역할

| 구분 | 역할 |
|---|---|
| Git | 내 컴퓨터에서 파일 변경 기록을 남기는 도구 |
| GitHub | Git 기록을 인터넷 저장소에 올려 공유하는 곳 |

Git이 중심이다. GitHub는 Git 저장소를 올려두는 호스팅 서비스이다.

즉, 내 컴퓨터에서 Git이라는 도구로 작업하고, GitHub라는 인터넷 저장소에 올려서 다른 사람과 공유하는 구조이다.

```text
내 컴퓨터 local
  |
  |  파일 수정
  v
working directory
  |
  |  git add
  v
staging area
  |
  |  git commit
  v
local repository (.git)
  |
  |  git push
  v
GitHub remote repository

GitHub remote repository
  |
  |  git pull
  v
내 컴퓨터 local
```

| 용어 | 의미 | 확인 명령 |
|---|---|---|
| working directory | 내 컴퓨터에서 실제로 파일을 수정하는 폴더 | `pwd`, `ls`, `git status` |
| local repository | 내 컴퓨터의 `.git` 안에 저장된 Git 기록 | `git log --oneline` |
| remote repository | GitHub에 올라간 Git 저장소 | `git remote -v` |
| `origin` | remote repository에 붙인 기본 이름 | `git remote -v` |
| `main` | 내 컴퓨터에서 작업 중인 branch 이름 | `git branch` |
| `origin/main` | 마지막으로 가져온 GitHub `main` branch 상태 | `git branch -vv` |

기본 이동 흐름:

```text
내 컴퓨터 파일 수정
-> git add
-> local repository에 commit
-> git push
-> GitHub remote repository에 업로드
```

GitHub에서 바뀐 내용을 가져오는 흐름:

```text
GitHub remote repository 변경
-> git pull
-> local repository 갱신
-> working directory에 반영
```

작업 산출물로 비유하면 다음과 같다.

| 작업 산출물 | Git |
|---|---|
| 작업 중인 폴더 | working directory |
| 제출 ZIP에 넣을 파일 고르기 | `git add` |
| 제출 ZIP 하나 만들기 | `git commit` |
| Classroom이나 Google Drive에 올리기 | `git push` |

## 3. 실습 1 - Git 저장소 만들기

현재 폴더를 Git 저장소로 만든다.

```sh
git init
```

상태를 확인한다.

```sh
git status
```

확인할 것:

- 현재 branch 이름 표시
- commit할 파일이 없는 초기 상태 안내
- 폴더 안에 숨김 폴더 `.git` 생성

`.git`은 Git 기록이 들어가는 숨김 폴더이다. 이 폴더가 있어야 Git이 현재 폴더를 저장소로 인식한다.

## 4. 실습 2 - 첫 파일 만들고 상태 보기

파일을 하나 만든다.

```sh
printf '# Git Practice\n' > README.md
```

상태를 확인한다.

```sh
git status
```

예상 상태:

```text
Untracked files:
  README.md
```

`untracked`는 Git 기록 대상으로 등록되기 전 파일 상태라는 뜻이다.

## 5. 실습 3 - `add`와 `commit`

이번 기록에 넣을 파일을 선택한다.

```sh
git add README.md
```

상태를 확인한다.

```sh
git status
```

예상 상태:

```text
Changes to be committed:
  new file: README.md
```

commit을 만든다.

```sh
git commit -m "Add practice README"
```

다시 상태를 확인한다.

```sh
git status
```

예상 상태:

```text
nothing to commit, working tree clean
```

`working tree clean`은 현재 작업 폴더가 마지막 commit 상태와 일치한다는 뜻이다.

## 6. 실습 4 - 파일 수정하고 diff 확인하기

파일에 내용을 추가한다.

```sh
printf '\n## Today\n\n- Learn git status, add, commit\n' >> README.md
```

상태를 확인한다.

```sh
git status
```

변경 내용을 확인한다.

```sh
git diff
```

확인할 것:

- `+`로 시작하는 줄이 새로 추가한 내용
- `status`는 바뀐 파일 목록 확인
- `diff`는 실제 바뀐 줄 확인

이번 변경을 commit한다.

```sh
git add README.md
git diff --staged
git commit -m "Update practice note"
```

## 7. 실습 5 - 이력 확인하기

commit 목록을 확인한다.

```sh
git log --oneline
```

조금 더 보기 좋게 확인한다.

```sh
git log --oneline --graph --decorate
```

확인할 것:

- commit hash
- commit message
- 최신 commit이 위에 표시됨

## 8. 실습 6 - GitHub에 올리기

GitHub에서 새 repository를 만든다.

권장:

- repository name: `git-practice`
- public/private는 공유 범위에 맞게 선택
- README 자동 생성 옵션은 끄기

GitHub가 알려주는 remote 주소를 연결한다.

```sh
git remote add origin <GitHub repository URL>
git branch -M main
git push -u origin main
```

예시:

```sh
git remote add origin https://github.com/<username>/git-practice.git
git branch -M main
git push -u origin main
```

GitHub 페이지를 새로고침해서 `README.md`가 올라갔는지 확인한다.

## 9. 실습 7 - GitHub에서 바꾼 내용 가져오기

GitHub 웹 화면에서 `README.md`를 열고 한 줄을 추가한다.

예시:

```text
Edited on GitHub
```

로컬에서 가져온다.

```sh
git pull
```

파일 내용을 확인한다.

```sh
cat README.md
```

확인할 것:

- GitHub에서 추가한 줄이 로컬 파일에 들어왔는지 확인
- `pull`은 GitHub의 commit을 내 컴퓨터로 가져와 현재 branch에 합치는 명령

## 10. 실습 8 - 충돌 만들어보기

충돌은 같은 파일의 같은 부분을 서로 다르게 수정했을 때 생긴다.

먼저 로컬에서 `README.md`의 같은 줄을 수정한다.

```sh
printf '# Git Practice - local edit\n' > README.md
printf '\n## Today\n\n- Local edit\n' >> README.md
git add README.md
git commit -m "Edit README locally"
```

그 다음 GitHub 웹 화면에서도 `README.md`의 같은 부분을 다르게 수정하고 commit한다.

예시:

```text
# Git Practice - github edit
```

로컬에서 push를 시도한다.

```sh
git push
```

push가 거절되면 먼저 GitHub 변경을 가져온다.

```sh
git pull
```

같은 부분을 다르게 수정했다면 충돌이 발생한다.

## 11. 실습 9 - 충돌 해결하기

상태를 확인한다.

```sh
git status
```

충돌난 파일을 연다.

```sh
code README.md
```

또는 터미널에서 확인한다.

```sh
cat README.md
```

충돌 표시는 다음 형태이다.

```text
<<<<<<< HEAD
내 로컬 내용
=======
GitHub에서 가져온 내용
>>>>>>> origin/main
```

해결 방법:

1. 남길 내용을 직접 결정
2. `<<<<<<<`, `=======`, `>>>>>>>` 줄 삭제
3. 파일 저장
4. 해결한 파일을 다시 `add`
5. commit 완료

명령:

```sh
git add README.md
git commit
git push
```

충돌 표시가 남아 있는지 확인한다.

```sh
rg '<<<<<<<|=======|>>>>>>>' README.md
```

정상 결과는 빈 출력이다.

## 12. 실습 10 - 올리면 안 되는 파일 제외하기

실습용 임시 파일을 만든다.

```sh
mkdir build
printf 'temporary result\n' > build/result.txt
printf 'my-password\n' > secret.txt
```

상태를 확인한다.

```sh
git status
```

Git에서 제외할 파일 규칙은 `.gitignore`에 적는다. `.gitignore`는 repository에서 추적할 파일과 제외할 파일을 구분하는 중심 파일이다.

`build/`와 `secret.txt`를 Git에서 제외한다.

```sh
printf 'build/\nsecret.txt\n' > .gitignore
git add .gitignore
git commit -m "Add ignore rules"
```

다시 상태를 확인한다.

```sh
git status
```

GitHub에 올리면 안 되는 것:

- 비밀번호
- API key
- token
- build 결과물
- cache
- log
- 큰 동영상 파일
- 개인 환경 설정 파일

## 13. 실습 중 자주 쓰는 명령

| 하고 싶은 일 | 명령 |
|---|---|
| 현재 상태 확인 | `git status` |
| 수정 내용 확인 | `git diff` |
| commit 후보 확인 | `git diff --staged` |
| 파일 선택 | `git add <파일명>` |
| 기록 생성 | `git commit -m "메시지"` |
| 이력 확인 | `git log --oneline --graph` |
| GitHub에 올리기 | `git push` |
| GitHub에서 가져오기 | `git pull` |
| 원격 주소 확인 | `git remote -v` |

## 14. 실습 마무리 체크

확인 항목:

- GitHub repository에 `README.md`가 올라가 있음
- `git log --oneline`에 commit이 여러 개 있음
- `git status` 결과가 clean 상태임
- `.gitignore`가 있음
- 충돌 표시 제거 완료

상태 확인 명령:

```sh
git status
git log --oneline --graph --decorate
git remote -v
```

## 15. 기억할 흐름

```text
수정
-> status 확인
-> diff 확인
-> add로 파일 선택
-> commit으로 기록 생성
-> push로 GitHub 업로드
```

협업할 때:

```text
작업 전 pull
-> 작업
-> add
-> commit
-> push
-> 충돌 발생 시 직접 정리
```

## 16. VSCode에서 같은 흐름으로 사용하기

VSCode에서도 Git 흐름은 동일하다. 명령어 흐름을 버튼과 입력칸으로 수행한다.

```text
파일 수정
-> Source Control에서 변경 파일 확인
-> 변경 내용(diff) 확인
-> Stage Changes로 add
-> commit message 작성
-> Commit
-> Sync Changes 또는 Push
```

기본 사용 순서:

1. VSCode에서 project folder를 연다.
2. 왼쪽 `Source Control` 아이콘을 클릭한다.
3. `Changes` 목록에서 수정된 파일을 확인한다.
4. 파일을 클릭해서 어떤 내용이 바뀌었는지 diff를 확인한다.
5. commit할 파일만 `+` 버튼으로 stage한다.
6. 위쪽 message 입력칸에 commit message를 적는다.
7. `Commit` 버튼을 눌러 기록을 만든다.
8. `Sync Changes` 또는 `Push`를 눌러 GitHub에 올린다.

주의할 점:

- `Changes` 목록에서 commit할 파일만 직접 고름
- commit할 파일만 stage해야 함
- `Sync Changes`는 보통 `pull`과 `push`를 함께 처리함
- 충돌이 나면 파일 안의 충돌 표시를 직접 정리한 뒤 다시 stage하고 commit함

VSCode 안에서도 터미널을 열 수 있다.

```text
Terminal
-> New Terminal
```

헷갈릴 때는 VSCode 터미널에서 직접 확인한다.

```sh
git status
git diff
git diff --staged
```

## 17. 대화형 AI를 Git 보조 도구로 쓰기

ChatGPT, Gemini 같은 대화형 AI는 Git 사용 중에 막힌 부분을 확인하는 보조 도구로 사용할 수 있다.

도움이 되는 상황:

- `git status` 결과 해석
- `git diff` 결과에서 바뀐 내용 확인
- `git add`, `git commit`, `git push` 순서 확인
- 오류 메시지 원인 확인
- 충돌 표시 읽는 방법 확인
- commit message 문장 다듬기
- `.gitignore`에 넣을 후보 확인

AI에게 질문할 때는 현재 상황을 함께 적는다.

```text
목표: README.md를 수정해서 GitHub에 올리기
상황: git push에서 오류 발생
사용 환경: VSCode 터미널
실행한 명령:
git push

오류 메시지:
...

git status 결과:
...

다음에 확인할 순서를 알려줘.
```

짧게 물어볼 수도 있다.

```text
git status 결과가 아래와 같을 때, 다음에 해야 할 일을 순서대로 알려주세요.

<git status 결과 붙여넣기>
```

```text
아래 git diff에서 실제로 바뀐 내용을 요약하고, commit message 후보를 3개 제안하세요.

<git diff 결과 붙여넣기>
```

```text
Git 충돌 표시가 있는 파일입니다. 어느 부분이 내 변경이고 어느 부분이 상대 변경인지 설명하세요.

<충돌 표시가 포함된 코드 일부 붙여넣기>
```

붙여넣기 전에 제외할 내용:

- 비밀번호
- GitHub token
- API key
- `.env` 내용
- 개인 인증서와 private key
- 제출 전 공개하면 안 되는 과제 답안 전체
- 다른 사람의 개인정보

AI가 제안한 명령어는 실행 전에 의미를 확인한다.

특히 다음 명령어는 바로 실행하지 않고, 무엇을 지우거나 되돌리는지  먼저 확인한다.

```sh
git reset --hard
git clean -fd
git rebase
git filter-branch
git push --force
```

좋은 사용 흐름:

```text
내가 먼저 status 확인
-> AI에게 결과 해석 요청
-> AI가 제안한 명령어 의미 확인
-> 안전한 명령만 직접 실행
-> 실행 후 다시 status 확인
```

AI는 현재 상태를 읽고 다음 확인 순서를 정리하는 보조 도구로 사용하며, 최종 실행 여부는 사용자가 명령어 의미를 확인한 뒤 결정한다.
