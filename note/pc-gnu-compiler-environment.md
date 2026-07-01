# PC GNU 컴파일 환경 설치 가이드

원본 위치: `Google Drive/My Drive/Classroom/대한상공회의소_반도체설계/김-/C_M4_Python_툴_설치가이드/1.PC_GNU컴파일_환경_설치가이드.pdf`

관련 날짜 노트: [260701-vscode-gnu-c-basics.md](260701-vscode-gnu-c-basics.md)

## 핵심 용도

Windows PC에서 C 실습을 진행하기 위한 `MSYS2`, `GCC`, `make`, `rm`, `VSCode` 기반 개발 환경 구성 자료다. 이후 `1.C_LAB` 예제에서 `make`, `make run`, `make clean` 흐름으로 컴파일과 실행을 확인한다.

## 설치 흐름

| 단계 | 내용 | 확인 포인트 |
|---|---|---|
| `MSYS2` 설치 | 설치 파일 실행 후 기본 경로 사용 | 기본 위치 `C:\msys64` 유지 |
| 패키지 업데이트 | `MSYS2` 터미널에서 패키지 데이터 갱신 | 명령 입력 시 하이픈 문자 오입력 주의 |
| `GCC` 설치 | `mingw-w64-ucrt-x86_64-gcc` 설치 | `ucrt64` 쪽 `gcc` 사용 |
| 유틸리티 복사 | `make.exe`, `rm.exe`를 `ucrt64\bin`에 배치 | `make` 실습 명령이 바로 동작해야 함 |
| 환경변수 설정 | Windows 사용자/시스템 `Path`에 `ucrt64\bin` 추가 | 새 터미널에서 `gcc`, `make` 인식 |
| `VSCode` 설치 | 에디터 설치 후 실습 폴더 열기 | `1.C_LAB` 작업 폴더 기준 |
| `VSCode` 설정 | 마우스 휠 확대, 에러 밑줄, 자동 저장 설정 | 수업 중 실습 편의성 목적 |

## 명령과 경로

| 항목 | 값 |
|---|---|
| 패키지 업데이트 | `pacman -Syu` |
| GCC 설치 | `pacman -S mingw-w64-ucrt-x86_64-gcc` |
| 주요 경로 | `C:\msys64\ucrt64\bin` |
| 실습 빌드 | `make` |
| 실습 실행 | `make run` |
| 실습 정리 | `make clean` |

## 수업 연결

- PC용 C 실습은 보드 다운로드가 아니라 로컬 컴파일/실행 확인에 초점이 있다.
- `Path` 설정이 틀리면 `gcc`, `make`, `rm` 명령 인식 문제가 먼저 발생한다.
- `VSCode` 설정은 문법보다 실습 속도와 화면 가독성을 위한 준비 작업이다.
- `make clean` 후 다시 `make`를 실행해 빌드 산출물이 재생성되는지 확인한다.
