# Git과 GitHub - Advanced

이 문서는 Git을 내부 구조와 운영 관점에서 복습하기 위한 노트이다. 대상은 Git 명령을 이미 사용하는 개발자이며, 목표는 문제가 생겼을 때 Git repository의 상태를 해석하고 복구 방향을 결정하는 것이다.

## 1. Git Object Database

Git의 repository는 `.git/objects` 아래의 object database를 중심으로 동작한다. Git object는 내용으로 hash를 계산하고, 그 hash가 object 이름이 된다.

| object | 포함 내용 |
|---|---|
| blob | 파일 내용 |
| tree | 파일명, mode, blob/tree hash |
| commit | tree hash, parent hash, author, committer, message |
| annotated tag | tag 대상, tagger, message |

기본 확인 명령:

```sh
git cat-file -t <hash>
git cat-file -p <hash>
git ls-tree <commit>
```

Git의 무결성은 object id에 의존한다. 내용이 바뀌면 hash가 바뀌므로 기존 object를 몰래 수정하는 방식은 Git 모델과 맞지 않는다.

## 2. Commit 내부

commit object는 tree object를 가리킨다. tree object가 project snapshot의 file/directory 구조를 표현한다. 또한 commit object는 parent commit을 가리켜 이력을 구성한다.

```text
commit
  tree <tree-hash>
  parent <parent-commit-hash>
  author ...
  committer ...
  message
```

merge commit은 parent가 둘 이상이다. rebase는 새 parent를 기준으로 새 commit object를 생성한다.

## 3. Index

index는 staging area의 실제 자료구조이다. working tree와 repository 사이에서 다음 commit이 될 파일 상태를 보관한다.

확인 명령:

```sh
git ls-files --stage
git diff
git diff --cached
```

conflict가 발생하면 index에는 같은 path에 대해 stage 1, 2, 3 entry가 생길 수 있다.

| stage | 의미 |
|---|---|
| 1 | merge base |
| 2 | ours |
| 3 | theirs |

## 4. Reference

branch, tag, remote tracking branch는 대부분 object를 가리키는 reference이다.

| 경로 | 의미 |
|---|---|
| `.git/HEAD` | 현재 HEAD 위치 |
| `.git/refs/heads/*` | local branch |
| `.git/refs/remotes/*` | remote tracking branch |
| `.git/refs/tags/*` | tag |

packed refs가 사용되면 일부 ref는 `.git/packed-refs`에 저장된다. 내부 직접 수정은 피하고 `git update-ref`, `git branch`, `git tag` 같은 명령을 사용한다.

## 5. Reflog

reflog는 local reference 이동 기록이다. branch가 어디를 가리켰는지의 로컬 기록이므로 복구에 중요하다.

```sh
git reflog
git reflog show main
```

예시:

```sh
git switch main
git reset --hard HEAD~1
git reflog
git reset --hard <reflog에 남은 이전 commit>
```

주의할 점:

- reflog는 로컬 기록이다.
- remote에 자동 공유되지 않는다.
- 만료 정책에 따라 사라질 수 있다.

## 6. Packfile과 GC

Git은 loose object를 packfile로 압축할 수 있다.

```sh
git count-objects -vH
git gc
git verify-pack -v .git/objects/pack/*.idx
```

대용량 binary를 commit하면 packfile이 커지고 clone, fetch, push 비용이 증가한다. 이미 이력에 들어간 대용량 파일은 단순 삭제 commit으로 repository 크기 문제가 해결되지 않는다.

## 7. History Rewrite

history rewrite는 기존 commit graph를 새 commit graph로 바꾸는 작업이다.

| 도구 | 용도 |
|---|---|
| `git commit --amend` | 직전 commit 수정 |
| `git rebase -i` | 여러 commit 재정렬, squash, edit |
| `git filter-repo` | 이력 전체에서 파일, 경로, author 등 재작성 |

공유 이력을 rewrite하면 다른 사람의 clone과 충돌한다. 필요한 경우 작업 공지, branch freeze, backup, force push 정책이 필요하다.

force push는 `--force-with-lease`를 우선 사용한다.

```sh
git push --force-with-lease
```

## 8. Revert와 Reset의 운영 차이

`revert`는 기존 commit을 취소하는 새 commit을 만든다. 이력이 보존되므로 공유 branch에 적합하다.

`reset`은 현재 branch reference를 다른 commit으로 이동한다. local 정리에는 강력하지만 공유 branch에서는 위험하다.

| 상황 | 적합한 명령 |
|---|---|
| 배포된 commit 취소 | `git revert` |
| 로컬 WIP 정리 | `git reset` 가능 |
| 민감 정보 제거 | `filter-repo` 등 history rewrite 필요 |
| 단순 파일 되돌림 | `git restore` |

## 9. Merge Strategy와 Rebase Strategy

팀에서 이력 정책을 정해야 한다.

| 전략 | 장점 | 단점 |
|---|---|---|
| merge commit 유지 | branch 통합 지점 보존 | 로그가 복잡해질 수 있음 |
| rebase 후 fast-forward | 선형 이력 | 실제 병합 맥락이 흐려질 수 있음 |
| squash merge | 기능 단위 이력 단순화 | 세부 commit 손실 |

정답은 팀의 리뷰 방식과 release 방식에 따라 달라진다. 중요한 것은 repository마다 같은 정책을 일관되게 적용하는 것이다.

## 10. Refspec

refspec은 remote와 local ref를 어떻게 매핑할지 정하는 규칙이다.

```text
+refs/heads/*:refs/remotes/origin/*
```

일반 사용자는 자주 수정하지 않지만, mirror, partial fetch, 특정 namespace 운영에서는 refspec 이해가 필요하다.

확인:

```sh
git config --get-all remote.origin.fetch
```

## 11. Submodule과 Subtree

외부 repository를 포함하는 방식은 여러 가지가 있다.

| 방식 | 특징 |
|---|---|
| submodule | 특정 external repository commit을 pointer로 기록 |
| subtree | 외부 코드를 현재 repository 이력 안에 병합 |
| package manager | 언어별 dependency manager 사용 |

submodule은 정확한 commit 고정에는 좋지만 사용자가 `git submodule update --init --recursive`를 알아야 한다. 단순 수업 자료나 제출물에는 과한 경우가 많다.

## 12. Sparse Checkout과 Partial Clone

대형 monorepo에서는 전체 파일을 checkout하지 않는 전략이 필요할 수 있다.

```sh
git sparse-checkout init --cone
git sparse-checkout set path/to/module
```

partial clone은 object 전송을 줄인다.

```sh
git clone --filter=blob:none <url>
```

일반 repository에서는 복잡도 증가가 더 클 수 있으므로 필요할 때만 사용한다.

## 13. Bisect

`git bisect`는 어느 commit에서 문제가 시작됐는지 이분 탐색한다.

```sh
git bisect start
git bisect bad
git bisect good <known-good-commit>
# 테스트 후
git bisect good
git bisect bad
git bisect reset
```

테스트 명령이 자동화되어 있으면 `git bisect run`을 사용할 수 있다.

```sh
git bisect run ./test.sh
```

## 14. Hook

Git hook은 특정 Git 이벤트에 맞춰 실행되는 스크립트이다.

| hook | 용도 |
|---|---|
| `pre-commit` | format, lint, secret scan |
| `commit-msg` | commit message 규칙 검사 |
| `pre-push` | test, build, large file 검사 |
| server-side hook | 중앙 저장소 정책 강제 |

hook은 local hook과 server-side hook을 구분해야 한다. local hook은 clone할 때 자동 공유되지 않는다.

## 15. 보안과 민감 정보

secret이 commit에 들어가면 history 정리와 credential rotation이 필요하다. 이미 remote로 push됐다면 다음 조치가 필요하다.

1. secret 폐기 또는 회전
2. history rewrite 여부 판단
3. remote와 fork 이력 정리
4. 재발 방지 hook 또는 secret scanning 도입

GitHub의 private repository도 secret 저장소가 아니다. 접근 권한이 있는 사람과 automation token이 모두 위험 범위에 포함된다.

## 16. GitHub의 역할

GitHub는 Git hosting, collaboration, automation platform이다.

| 기능 | Git 자체 여부 |
|---|---|
| commit, branch, merge | Git |
| remote repository hosting | GitHub 제공 |
| issue, project, pull request UI | GitHub 제공 |
| Actions CI/CD | GitHub 제공 |
| release page, package registry | GitHub 제공 |

GitHub 없이도 Git은 사용할 수 있다. GitHub는 Git repository를 중심으로 협업과 운영 기능을 제공한다.

## 17. Advanced 체크리스트

- commit, tree, blob, tag object를 구분할 수 있음
- index stage 구조를 conflict와 연결할 수 있음
- reflog를 이용해 local branch 이동을 복구할 수 있음
- packfile과 repository 크기 문제를 설명할 수 있음
- history rewrite와 force push의 위험을 설명할 수 있음
- bisect, hook, refspec의 용도를 판단할 수 있음
