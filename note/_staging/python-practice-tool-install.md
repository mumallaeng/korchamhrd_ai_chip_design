# Python 실습툴 설치 가이드

원본 위치: `/Users/mumallaeng/Library/CloudStorage/GoogleDrive-yonnmilk@gmail.com/My Drive/Classroom/대한상공회의소_반도체설계/김-/C_M4_Python_툴_설치가이드/3.파이썬_실습툴_설치가이드.pdf`

## 핵심 용도

Python 기초 실습을 위해 `Python IDLE`과 `VSCode` 실행 환경을 준비하는 절차다. `IDLE`은 빠른 단일 파일 실행, `VSCode`는 확장 기능과 디버거 기반 실습에 사용한다.

## Python IDLE 흐름

| 단계 | 내용 | 확인 포인트 |
|---|---|---|
| 기존 버전 확인 | PC에 설치된 Python 버전 확인 | Python 3.x 여부 |
| 설치 파일 다운로드 | `https://www.python.org`의 Downloads 메뉴 사용 | Windows용 최신 설치 파일 |
| 설치 실행 | `python-3.xxx-amd64.exe` 실행 | `Add Python to PATH` 계열 옵션 확인 |
| `IDLE` 실행 | Windows 검색에서 `IDLE` 실행 | `IDLE Shell` 창 표시 |
| 파일 열기 | `File -> Open`으로 실습 파일 열기 | 예: `Py_Lab_IDLE.py` |
| 실행 | `F5` 또는 실행 메뉴 사용 | `print("Hello Python")` 결과 확인 |

## VSCode 흐름

| 단계 | 내용 | 확인 포인트 |
|---|---|---|
| 설치 | `VSCodeUserSetup-x64-1.xxxx.exe` 실행 | 바탕화면 아이콘 생성 가능 |
| 확장 설치 | `Python`, `Pylance`, `Python Debugger` 설치 | Microsoft 제공 확장 중심 |
| 설정 변경 | `CTRL + ,`에서 설정 검색 | `mouse wheel zoom` 활성화 |
| 파일 열기 | `File -> Open File`로 실습 파일 열기 | 예: `Py_Lab_for_VS_Code.py` |
| 실행 | Python 디버거 또는 Run 기능 사용 | 터미널 출력 확인 |

## 수업 연결

- Python 설치는 `IDLE`만 보는 것이 아니라 `PATH`와 편집기 실행까지 확인해야 한다.
- `IDLE`은 단순 실행 확인용, `VSCode`는 이후 디버깅과 파일 단위 실습용으로 나눠 이해한다.
- `CTRL + /` 주석 전환은 실습 중 코드 블록을 켜고 끄는 데 자주 쓰인다.
- VSCode에서 실행 환경을 고를 때 Python 인터프리터와 디버거 확장이 정상 설치되어 있어야 한다.
