# Git과 GitHub - Intermediate

이 문서는 Git의 기본 구조를 알고 있는 사람이 branch, remote, merge, conflict, worktree를 복습하기 위한 노트이다. 목적은 commit graph를 기준으로 작업 흐름을 해석하는 데 있다.

## 1. Commit Graph 관점

Git 이력은 directed acyclic graph이다. 각 commit은 parent commit을 가리키고, branch는 commit을 가리키는 이름이다.

```text
A---B---C  main
     \
      D---E  feature
```

위 구조에서 `main`과 `feature`는 branch reference이다. 실제 이력은 commit object의 parent 관계로 구성된다.

## 2. `HEAD`, branch, detached HEAD

| 개념 | 설명 |
|---|---|
| `HEAD` | 현재 작업 기준 위치 |
| branch | 특정 commit을 가리키는 movable reference |
| detached HEAD | branch 없이 commit 자체를 checkout한 상태 |

일반 작업은 branch 위에서 수행한다. detached HEAD 상태에서 commit하면 branch 이름이 그 commit을 가리키지 않기 때문에 나중에 잃어버리기 쉽다.

확인 명령:

```sh
git status
git branch --show-current
git log --oneline --graph --decorate --all
```

## 3. Branch 설계

branch는 작업 흐름을 분리하는 단위이다. commit은 변경 기록 단위이고, branch는 여러 commit을 묶는 작업 흐름 단위이다.

| 기준 | branch 분리 여부 |
|---|---|
| 독립 기능 개발 | 분리 권장 |
| 실험적 변경 | 분리 권장 |
| 긴급 수정 | 별도 branch 권장 |
| 같은 목적의 작은 문서 수정 | 같은 branch 가능 |

branch 이름은 작업 목적을 드러내야 한다.

```text
feature/git-note-split
fix/uart-rx-valid
docs/cortex-m4-source-map
```

## 4. Merge

`merge`는 두 branch의 이력을 합치는 작업이다.

| 유형 | 조건 | 결과 |
|---|---|---|
| fast-forward | 현재 branch가 대상 branch의 조상 | branch pointer만 전진 |
| 3-way merge | 두 branch가 갈라진 뒤 각각 commit 존재 | merge commit 생성 가능 |

예시:

```sh
git switch main
git merge feature/git-note-split
```

merge commit은 두 parent를 가진다. 이력에서 작업이 합쳐진 지점이 보존된다.

## 5. Rebase

`rebase`는 현재 branch의 commit들을 다른 base 위에 다시 적용한다.

```text
before:
A---B---C  main
     \
      D---E  feature

after rebase:
A---B---C  main
         \
          D'---E'  feature
```

`D`와 `E`의 변경을 담은 새 commit `D'`, `E'`가 생성된다. 따라서 이미 공유한 branch를 함부로 rebase하면 협업자가 가진 이력과 충돌한다.

기본 원칙:

- 개인 branch 정리에는 유용
- 공유 branch에는 신중하게 사용
- public history를 바꾸는 작업으로 이해

## 6. Conflict

conflict는 Git이 자동으로 합칠 수 없는 변경이 같은 영역에 발생한 상태이다. 사람이 의도를 결정해야 하는 merge 상황으로 처리한다.

기본 흐름:

```sh
git status
# conflict file 열기
# <<<<<<<, =======, >>>>>>> 표시 정리
git add <resolved-file>
git commit
```

확인해야 할 것:

- 둘 중 하나만 선택하면 되는지
- 양쪽 변경을 조합해야 하는지
- 주변 코드와 테스트가 여전히 맞는지
- conflict marker가 남아 있지 않은지

검색:

```sh
rg '<<<<<<<|=======|>>>>>>>' .
```

## 7. `fetch`와 `pull`

`fetch`는 remote 정보를 가져오고 현재 branch는 유지한다. `pull`은 `fetch` 후 merge 또는 rebase를 수행한다.

| 명령 | working tree 영향 |
|---|---|
| `git fetch` | working tree를 유지한 채 remote 정보만 갱신 |
| `git pull` | 현재 branch에 remote 변경을 합침 |

이력 상태를 먼저 보고 싶다면 `fetch` 후 비교한다.

```sh
git fetch origin
git log --oneline --graph --decorate --all
git diff main..origin/main
```

## 8. Remote Tracking Branch

`origin/main`은 remote의 `main` 상태를 로컬에 기록한 remote tracking branch이다. 마지막 `fetch` 시점에 로컬이 알고 있는 원격 branch 상태를 나타낸다.

```sh
git branch -vv
git remote show origin
```

`main`과 `origin/main`이 다를 수 있다. 이 차이를 이해해야 ahead/behind 상태를 해석할 수 있다.

## 9. Worktree

`git worktree`는 하나의 repository에서 여러 working tree를 동시에 열 수 있게 한다. 같은 repository 이력을 공유하면서 서로 다른 branch를 다른 디렉터리에서 작업할 수 있다.

```sh
git worktree list
git worktree add ../project-feature feature/topic
git worktree remove ../project-feature
```

적합한 경우:

- 긴 작업을 유지한 채 hotfix 확인
- 큰 build tree 재checkout 없이 branch 병렬 작업
- 동일 repository의 여러 branch를 동시에 비교

주의:

- 같은 branch를 두 worktree에서 동시에 checkout할 수 없음
- build output과 editor cache가 worktree별로 섞이지 않게 관리

## 10. Stash

`stash`는 아직 commit하기 애매한 working tree 변경을 임시 저장한다.

```sh
git stash push -m "wip: timer note draft"
git stash list
git stash show -p stash@{0}
git stash pop
```

stash는 영구 이력 관리 수단이 아니다. 장기 보관할 변경은 commit으로 남기는 것이 낫다.

## 11. 되돌리기 전략

| 상황 | 권장 접근 |
|---|---|
| 파일 수정만 취소 | `git restore <path>` |
| staging만 취소 | `git restore --staged <path>` |
| 공유된 commit 취소 | `git revert <commit>` |
| 로컬 branch pointer 재배치 | `git reset` |
| 직전 commit 메시지 수정 | `git commit --amend` |

공유 branch에서 `reset` 후 force push는 협업자의 이력을 깨뜨릴 수 있다. force가 필요하면 `--force-with-lease`를 우선 고려한다.

## 12. 협업 기본 흐름

PR까지 다루지 않는 기본 협업은 다음 수준이면 충분하다.

```text
1. 원격 최신 상태 확인
2. 자기 branch에서 작업
3. 의미 단위 commit
4. push
5. 다른 사람 변경과 충돌 시 fetch/merge 또는 pull로 정리
```

직접 같은 branch에 push하는 팀이라면 commit 전후로 `git status`, `git fetch`, `git log --graph`를 확인하는 습관이 중요하다.

## 13. `.gitignore` 운영

`.gitignore`는 추적하지 않을 파일 패턴을 기록한다.

Git이 이미 추적 중인 파일은 `.gitignore`에 추가해도 자동으로 사라지지 않는다. 이 경우 index에서 제거해야 한다.

```sh
git rm --cached <path>
```

대표 제외 대상:

```gitignore
build/
dist/
*.log
*.tmp
.DS_Store
__pycache__/
node_modules/
```

## 14. Intermediate 체크리스트

- commit graph를 보고 branch 관계를 설명할 수 있음
- `HEAD`, branch, remote tracking branch를 구분할 수 있음
- merge와 rebase의 이력 차이를 설명할 수 있음
- conflict marker를 정리하고 resolved file을 staging할 수 있음
- `fetch`와 `pull`의 차이를 설명할 수 있음
- `worktree`와 `stash`의 용도를 구분할 수 있음
