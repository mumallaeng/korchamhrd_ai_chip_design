# Git과 GitHub - Basic

이 문서는 Git을 처음 복습할 때 필요한 구조와 명령을 정리한다. 설명 대상은 프로그래밍과 파일 시스템 개념을 알고 있고, Git의 기본 모델을 기술 용어 중심으로 다시 정리하려는 학습자이다.

## 1. Git의 위치

Git은 프로젝트의 변경 이력을 commit graph로 저장하고 추적하는 분산 버전 관리 시스템이다.

GitHub는 Git 저장소를 원격에 호스팅하고 협업 기능을 제공하는 서비스이다. Git 자체가 버전 관리의 중심이고, GitHub는 그 저장소를 온라인에 올려 공유하고 리뷰하고 관리하기 쉽게 만드는 플랫폼이다.

## 2. 역사적 배경

Git은 Linux kernel 개발을 위해 Linus Torvalds가 2005년에 만들었다. 당시 Linux kernel은 많은 개발자가 동시에 패치를 주고받는 대규모 프로젝트였고, 각 개발자가 로컬에서 전체 이력을 다루는 분산 구조가 필요했다.

Git의 핵심 요구는 다음과 같다.

| 요구 | 의미 |
|---|---|
| 분산성 | 각 개발자가 전체 저장소 이력을 로컬에 보유 |
| 속도 | 대부분의 조회, diff, commit 작업을 로컬에서 수행 |
| 무결성 | 객체 이름을 hash로 계산하여 내용 변조 감지 |
| branch 비용 절감 | 여러 작업 흐름을 가볍게 분리 |

## 3. Version Control System

Version Control System(VCS)은 파일의 변경 이력을 저장하고 관리하는 시스템이다. source code, 문서, 설정 파일처럼 시간이 지나며 계속 바뀌는 파일을 대상으로 한다.

VCS가 기록하는 정보는 다음과 같다.

| 기록 대상 | 의미 |
|---|---|
| file content | 특정 시점의 파일 내용 |
| change set | 어떤 줄과 파일이 바뀌었는지에 대한 변경 묶음 |
| author | 변경을 만든 사람 |
| timestamp | 변경이 기록된 시간 |
| message | 변경 이유를 설명하는 기록 |
| revision 또는 commit id | 특정 변경 지점을 식별하는 이름 |

VCS를 사용하면 다음 작업이 가능하다.

- 특정 시점으로 복구
- 두 시점의 차이 비교
- 여러 작업 흐름 분리
- 여러 사람이 만든 변경 통합
- 변경 이유와 작성자 추적

VCS는 이력 저장 방식에 따라 크게 나눌 수 있다.

| 구분 | 특징 |
|---|---|
| Local VCS | 한 컴퓨터 안에서만 이력 저장 |
| Centralized VCS | 중앙 서버가 기준 이력을 보유 |
| Distributed VCS | 각 로컬 저장소가 전체 이력을 보유 |

Centralized VCS는 중앙 서버가 기준 저장소 역할을 한다. 사용자는 서버에서 파일을 가져오고, 변경을 서버에 commit한다.

```text
Developer A
Developer B  ->  Central Server
Developer C
```

대표 예시는 `CVS`와 `SVN`이다.

| 도구 | 성격 | 특징 |
|---|---|---|
| CVS | 오래된 centralized VCS | 파일 단위 이력 관리 중심, 초기 오픈소스 프로젝트에서 많이 사용 |
| SVN(Subversion) | centralized VCS | CVS의 불편한 점을 개선한 도구, repository 전체 revision 번호 사용 |

Distributed VCS는 각 개발자의 로컬 저장소가 전체 이력을 가진다. commit, log, diff, branch 같은 작업을 로컬에서 수행하고, 필요할 때 remote와 동기화한다.

```text
Developer A local repo  <->  Remote repo
Developer B local repo  <->  Remote repo
Developer C local repo  <->  Remote repo
```

대표 예시는 `Git`과 `Mercurial`이다.

| 도구 | 성격 | 특징 |
|---|---|---|
| Git | distributed VCS | 빠른 local commit, branch, merge, content-addressed object model |
| Mercurial | distributed VCS | Git과 비슷한 분산형 모델, 단순한 명령 체계를 지향 |

Git은 분산형이다. `commit`은 로컬 저장소에 기록되고, `push`를 해야 원격 저장소로 공유된다.

## 4. Repository와 `.git`

Git repository의 실체는 `.git` 디렉터리이다. 작업 파일은 working tree에 보이고, Git의 이력과 참조 정보는 `.git` 안에 저장된다.

| 구성 | 역할 |
|---|---|
| working tree | 사용자가 편집하는 실제 파일 |
| `.git` | commit, branch, tag, config, object 저장 |
| repository | `.git`을 포함한 Git 관리 단위 |

`git init`을 실행하면 현재 디렉터리에 `.git`이 생긴다. `git clone`으로 받은 폴더에도 `.git`이 들어 있다. `.git`이 사라지면 그 폴더는 Git 이력을 모르는 일반 디렉터리가 된다.

`.git` 내부에는 Git repository의 실제 데이터와 설정이 들어 있다.

```text
.git/
├── objects/   # commit, tree, blob, tag object 저장
├── refs/      # commit을 가리키는 reference 저장
│   ├── heads/    # local branch pointer
│   ├── tags/     # tag pointer
│   └── remotes/  # remote tracking branch pointer
├── hooks/     # pre-commit, pre-push 같은 자동화 script
├── logs/      # reflog 기록
│   ├── HEAD
│   └── refs/
├── config     # repository local 설정
├── HEAD       # 현재 checkout 위치
└── index      # staging area 상태
```

주요 항목:

| 항목 | 역할 |
|---|---|
| `objects/` | Git object database. file content는 `blob`, directory 구조는 `tree`, 이력 지점은 `commit` object로 저장 |
| `refs/` | branch와 tag 이름이 어떤 commit을 가리키는지 저장 |
| `refs/heads/` | local branch 이름과 commit pointer 저장. 예: `refs/heads/main` |
| `refs/tags/` | tag 이름과 commit 또는 tag object pointer 저장 |
| `refs/remotes/` | remote tracking branch 저장. 예: `refs/remotes/origin/main` |
| `hooks/` | commit, push 등 특정 동작 전후에 실행할 script 저장 |
| `logs/` | branch와 `HEAD`가 이동한 기록인 reflog 저장 |
| `config` | 해당 repository에만 적용되는 user, remote, branch 설정 저장 |
| `HEAD` | 현재 작업 기준 branch 또는 commit을 가리킴 |
| `index` | `git add`로 준비한 다음 commit 후보 상태 저장 |

명령어와 `.git` 내부 항목의 연결:

| 명령 | 연결되는 내부 항목 | 의미 |
|---|---|---|
| `git add <path>` | `.git/index` | 다음 commit 후보 상태 갱신 |
| `git commit` | `.git/objects/`, `.git/refs/heads/*`, `.git/logs/` | 새 commit object 생성, 현재 branch pointer 이동, reflog 기록 |
| `git branch <name>` | `.git/refs/heads/<name>` | 새 local branch pointer 생성 |
| `git tag <name>` | `.git/refs/tags/<name>` | 특정 commit을 가리키는 tag pointer 생성 |
| `git fetch origin` | `.git/refs/remotes/origin/*`, `.git/objects/` | remote branch 상태와 필요한 object 가져오기 |
| `git switch <branch>` | `.git/HEAD`, `.git/index`, working tree | 현재 작업 기준 branch 변경 |
| `git remote add origin <url>` | `.git/config` | remote repository 이름과 URL 저장 |
| `git reflog` | `.git/logs/HEAD`, `.git/logs/refs/heads/*` | `HEAD`와 branch 이동 기록 조회 |

일반 작업에서는 `git add`, `git commit`, `git branch`, `git remote` 같은 Git 명령으로 `.git` 내부 상태를 수정한다.

## 5. Git의 세 영역

Git의 기본 흐름은 working tree, index, repository 세 영역으로 이해한다.

| 영역 | 설명 |
|---|---|
| working tree | 파일을 수정하는 작업 공간 |
| index 또는 staging area | 다음 commit에 들어갈 변경을 준비하는 영역 |
| repository | commit이 저장되는 이력 영역 |

기본 흐름은 다음과 같다.

```text
working tree 수정
-> git add
-> index에 staging
-> git commit
-> repository에 commit 저장
```

`git add`는 현재 파일 상태를 다음 commit 후보로 index에 기록하는 명령이다.

## 6. Snapshot 모델

Git의 기본 모델은 snapshot이다. commit은 특정 시점의 프로젝트 tree 상태를 가리킨다.

Git은 내부적으로 content-addressed object database를 사용한다. 같은 내용은 같은 hash를 갖고, commit은 tree와 parent commit을 가리킨다.

| 객체 | 역할 |
|---|---|
| blob | 파일 내용 |
| tree | 디렉터리 구조와 파일명 |
| commit | tree, parent, author, message 기록 |
| tag | 특정 commit에 붙인 이름 |

Basic 단계에서는 객체 내부 명령을 세부 암기 대상으로 두지 않는다. commit은 hash 기반 객체 그래프의 일부라는 점은 기억한다.

## 7. 기본 명령 흐름

| 명령 | 용도 |
|---|---|
| `git status` | working tree와 index 상태 확인 |
| `git diff` | staging 전 working tree 변경 확인 |
| `git diff --staged` | staging된 변경 확인 |
| `git add <path>` | 다음 commit에 포함할 변경 선택 |
| `git commit` | index 상태를 commit으로 저장 |
| `git log --oneline --graph` | commit 이력 확인 |

가장 안전한 기본 루틴은 다음과 같다.

```sh
git status
git diff
git add <path>
git diff --staged
git commit -m "의미 있는 변경 설명"
```

## 8. Commit 단위

commit은 의미 있는 변경 단위이다. 나중에 읽을 수 있는 변경 기록으로 남는다.

좋은 commit은 다음 조건을 가진다.

| 기준 | 설명 |
|---|---|
| 한 가지 목적 | 한 commit에 한 작업만 포함 |
| 재현 가능 | 이 commit만 봐도 변경 이유를 추적 가능 |
| 리뷰 가능 | diff를 읽을 수 있는 크기로 유지 |
| 되돌리기 가능 | 문제가 생겼을 때 해당 commit만 되돌리기 쉬움 |

예시:

```text
docs(note): split Git note by difficulty
fix(timer): correct counter reset condition
refactor(gpio): isolate register access helpers
```

## 9. Branch 기본

branch는 commit을 가리키는 이름이다. Git의 branch는 commit graph 위의 가벼운 pointer이다.

| 개념 | 설명 |
|---|---|
| `HEAD` | 현재 checkout된 commit 또는 branch |
| branch | 특정 commit을 가리키는 이름 |
| checkout/switch | working tree를 특정 branch 상태로 전환 |

기본 명령:

```sh
git branch
git switch -c feature/topic
git switch main
```

## 10. Remote와 GitHub

remote는 로컬 저장소가 알고 있는 다른 Git 저장소 주소이다. GitHub는 remote 저장소를 제공하는 대표적인 호스팅 서비스이다.

| 명령 | 의미 |
|---|---|
| `git remote -v` | 등록된 remote 확인 |
| `git push` | 로컬 commit을 remote로 전송 |
| `git fetch` | remote의 commit과 branch 정보를 가져옴 |
| `git pull` | `fetch` 후 현재 branch에 병합 또는 rebase |

GitHub는 Git hosting platform이다. Git commit graph를 remote repository로 보관하고, 그 위에 branch, issue, review, release 등의 협업 기능을 제공한다.

## 11. Git에 올리면 안 되는 것

Git은 source history에 강한 도구이다. Git에는 source, 문서, 설정처럼 이력 추적이 필요한 파일을 넣는다.

| 제외 대상 | 이유 |
|---|---|
| 비밀번호, token, key | 유출되면 commit 삭제 후에도 이력에 남을 수 있음 |
| build output | 재생성 가능하고 diff 품질을 떨어뜨림 |
| cache, log | 실행 환경에서 다시 생성되는 파일 |
| 대용량 binary | clone과 push 비용 증가 |
| 개인 환경 설정 | 다른 환경에서 깨질 가능성 |

제외 규칙은 `.gitignore`에 작성한다.

## 12. 복구 기본

복구 명령은 위험도가 다르다. 어떤 영역을 되돌리는지 먼저 구분한다.

| 명령 | 기본 의미 |
|---|---|
| `git restore <path>` | working tree 변경 취소 |
| `git restore --staged <path>` | index에서 staging 해제 |
| `git revert <commit>` | 기존 commit을 취소하는 새 commit 생성 |
| `git reset` | branch pointer 또는 index 상태 이동 |

공유된 commit은 `reset`보다 `revert`가 안전하다. `reset --hard`는 working tree 변경까지 지울 수 있으므로 사용 전 대상과 범위를 확인해야 한다.

## 13. Basic 체크리스트

- Git과 GitHub의 역할을 구분할 수 있음
- `.git`이 repository의 실체라는 점을 설명할 수 있음
- working tree, index, repository 흐름을 설명할 수 있음
- `status`, `diff`, `add`, `commit`, `log`를 기본 루틴으로 사용할 수 있음
- commit 단위를 의미 기준으로 나눌 수 있음
- GitHub를 Git hosting platform으로 설명할 수 있음
