# 26-07-01 - VSCode/GNU C 환경과 C 언어 기초

## 수업 흐름

오늘은 Windows PC에서 C 실습을 진행하기 위한 기본 개발환경을 먼저 맞춘다. 설치 순서는 MSYS2 설치, GNU 컴파일러 설치, Windows `Path` 환경변수 등록, VSCode 설치와 기본 설정, `1.C_LAB` 예제 실행 순서로 진행한다.

이번 환경은 ARM 보드 실습으로 넘어가기 전 PC에서 `make`, `gcc`, VSCode 터미널 사용 흐름을 확인하기 위한 준비 단계이다. 실습 자료 폴더명에는 `00.GCC_Compilre_for_Windows`처럼 오타가 포함되어 있으므로, 실제 파일 탐색에서는 자료 폴더명을 그대로 사용한다.

## 수업 자료 위치

| 항목 | 위치 |
| :--- | :--- |
| PC GNU 컴파일 환경 설치 가이드 | `/Users/mumallaeng/Library/CloudStorage/GoogleDrive-yonnmilk@gmail.com/My Drive/Classroom/대한상공회의소_반도체설계/김-/C_M4_Python_툴_설치가이드/1.PC_GNU컴파일_환경_설치가이드.pdf` |
| MSYS2 설치 파일 | `00.GCC_Compilre_for_Windows/msys2-x86_64-20260322.exe` |
| 설치 명령 복사용 파일 | `00.GCC_Compilre_for_Windows/Tool_설치_복사용.txt` |
| VSCode 설치 파일 | `02.VScode/VSCodeUserSetup-x64-1.99.0.exe` |

## MSYS2 설치

MSYS2는 Windows에서 GNU 계열 개발 도구를 설치하고 관리하기 위한 기반 환경으로 사용한다. 자료 폴더의 `msys2-x86_64-20260322.exe`를 실행하거나, 필요하면 `https://www.msys2.org/`의 Installation 영역에서 같은 버전의 x86_64 설치 파일을 받을 수 있다.

설치 경로는 기본값인 `C:\msys64`를 유지한다. 이후 환경변수와 도구 복사 경로가 모두 이 기본 설치 경로를 기준으로 설명되므로, 임의로 바꾸지 않는 편이 좋다.

## GNU 컴파일러 설치

MSYS2 설치가 끝나면 MSYS2 터미널을 실행하고 패키지 업데이트와 GCC 설치를 진행한다. 자료 폴더의 `Tool_설치_복사용.txt`에 필요한 명령과 환경변수 경로가 들어 있다.

| 단계 | 입력/설정 | 의미 |
| :--- | :--- | :--- |
| 패키지 업데이트 | `pacman -Syu` | MSYS2 패키지 DB와 기본 패키지 업데이트 |
| 설치 확인 | `Y` 입력 | 설치 진행 여부 확인 프롬프트 승인 |
| GCC 설치 | `pacman -S mingw-w64-ucrt-x86_64-gcc` | C/C++ 컴파일러인 MinGW-w64 UCRT toolchain 설치 |
| 실행 도구 복사 | `make.exe`, `rm.exe` | 자료 폴더의 두 파일을 `C:\msys64\ucrt64\bin`에 복사 |

`make.exe`는 `Makefile` 기반 빌드를 실행할 때 필요하고, `rm.exe`는 `make clean` 같은 정리 명령에서 사용된다. 두 파일이 `Path`에 잡히는 `C:\msys64\ucrt64\bin` 아래에 있어야 VSCode 터미널에서도 같은 명령을 사용할 수 있다.

## Windows 환경변수 설정

Windows 검색에서 `환경 변수`를 입력해 `시스템 환경 변수 편집`을 실행한 뒤, 하단의 `환경 변수(N)` 버튼을 연다. `Path`에는 GNU 컴파일러 실행 파일들이 있는 경로를 추가한다.

추가할 경로는 다음과 같다.

```text
C:\msys64\ucrt64\bin
```

이 경로는 `사용자 변수`의 `Path`와 `시스템 변수`의 `Path`에 모두 추가한다. 사용자 변수만 수정하면 현재 사용자 터미널에서는 동작할 수 있지만, 실습 환경에 따라 다른 실행 컨텍스트에서 명령을 못 찾을 수 있으므로 시스템 변수 쪽도 함께 맞춘다.

## VSCode 설치와 기본 설정

VSCode는 `02.VScode` 폴더의 `VSCodeUserSetup-x64-1.99.0.exe`를 실행해 설치한다. 설치 과정에서 가능하면 `바탕 화면에 바로가기 만들기`를 선택해 실행 경로를 확보한다. 바탕화면 아이콘을 만들지 않았다면 Windows 검색에서 `Visual Studio Code`를 찾아 실행한다.

설치 후에는 실습 편의를 위해 아래 설정을 확인한다.

| 설정 | 적용 내용 |
| :--- | :--- |
| `Mouse Wheel Zoom` | Editor와 Terminal 모두 활성화 |
| `Error Squiggles` | C/C++ 설정에서 `disabled`로 설정, 항목이 없으면 무시 |
| `Auto Save` | `File` 메뉴에서 활성화 |

`Auto Save`를 켜면 파일을 명시적으로 저장하지 않아도 수정 내용이 자동 저장된다. 실습 중에는 저장 누락 때문에 이전 코드가 빌드되는 상황을 줄일 수 있다.

## C 실습 예제 실행

다운로드한 실습자료 압축을 해제한 뒤 VSCode에서 `File -> Open Folder`를 선택하고 압축 해제한 실습자료 폴더를 연다. 원본 zip은 나중에 다시 확인할 수 있도록 삭제하지 않고 보관한다.

Explorer에서 `1.C_LAB` 프로젝트를 선택한 뒤, 해당 프로젝트 위에서 우클릭하여 `Open in Integrated Terminal`을 연다. 다른 프로젝트를 실습할 때도 반드시 해당 프로젝트 폴더 기준 터미널을 열어야 한다.

`1.C_LAB/main.c`의 첫 예제는 `#if 0`을 `#if 1`로 바꿔 실행한다. 실습이 끝난 뒤에는 다음 예제 실험을 위해 다시 `#if 0`으로 복원한다.

| 명령 | 역할 | 확인 기준 |
| :--- | :--- | :--- |
| `make` | 프로그램 컴파일 | 정상 컴파일 시 `main.exe` 생성 |
| `make run` | 컴파일된 프로그램 실행 | 터미널에 `Hello C World!` 출력 |
| `make clean` | 빌드 결과 정리 | 생성된 실행 파일과 중간 결과 제거 |

## C 언어 수업 구성

개념 정리는 아래 단원 흐름을 기준으로 이어 간다. 0701 실제 수업 범위는 `4. 나만의 함수 만들기` 완료까지이고, `5. 조건에 따른 실행`은 진입 후 중단되었다. 5번 이후 정리는 [260702-c-programming-continuation.md](260702-c-programming-continuation.md)에 이어서 보관한다.

| 번호 | 제목 | 개념 정리 범위 |
| :--- | :--- | :--- |
| 3. | 계산하기 | 사칙연산자, 복합대입, 증감, cast, `sizeof`, `&` |
| 4. | 나만의 함수 만들기 | 함수의 형식, 함수의 선언, 변수의 유효 범위, macro |
| 5. | 조건에 따른 실행 | `if`문, 비교 연산, 논리 연산, `switch`문 |
| 6. | 반복하여 처리하기 | `for`문, `for` 구문 연습, 이중 `for` 루프, 다중 루프 탈출, `goto`문, 조건될 때까지 반복 |
| 7. | 데이터 모아서 다루기 | 배열, 이차원 배열, 문자열 배열, 구조체, 구조체 멤버 복사, 구조체 배열, `typedef` |
| 8. | C문법 조금 더 알아보기 | 진법 변환, format 지시자, `ctype.h`, `while`, 배열 memory/transpose, 복사 함수, `union`, endian |
| 9. | 기본 포인터 활용 | 함수에 배열 전달, 함수의 배열 리턴, 구조체 포인터, 구조체의 함수 전달 |

## 1. 출력, 변수, ASCII

### C 언어 첫 출력

C 프로그램은 source file을 compiler가 번역해 실행 파일로 만든 뒤 실행된다. `#include <stdio.h>`는 전처리 단계에서 표준 입출력 함수 선언을 현재 source에 가져오도록 지시하고, `main()`은 실행 파일이 시작될 때 호출되는 진입점이다. `printf()`는 format string을 해석해 standard output으로 문자를 내보내는 library 함수다.

```c
#include <stdio.h>

int main(void)
{
    printf("Hello World\n");
    return 0;
}
```

`return 0;`은 운영체제나 실행 환경으로 정상 종료 상태를 돌려주는 표현이다. C 표준에서는 `main()`이 끝까지 도달하면 0을 반환한 것처럼 처리되지만, 실습 초반에는 종료 상태를 명시적으로 적어 두는 편이 흐름을 확인하기 좋다.

`printf()`는 format string 안의 문자와 escape sequence를 해석해서 출력한다. `\n`은 줄바꿈, `\t`는 tab, `\\`는 backslash 자체를 출력할 때 사용한다. `\0`은 화면에 보이는 문자가 아니라 값이 0인 NUL 문자이며, C 문자열의 끝을 표시하는 sentinel 값이다. `%d`, `%f`, `%c`, `%s` 같은 format 지정자는 뒤쪽 argument를 어떤 타입으로 읽어 출력할지 정하므로, 지정자와 argument type이 맞아야 한다.

| 표기 | 의미 | 출력/역할 |
| :--- | :--- | :--- |
| `\n` | newline | 다음 줄로 이동 |
| `\t` | horizontal tab | tab 간격 이동 |
| `\0` | NUL character | 문자열 종료 표지 |
| `\\` | backslash escape | `\` 문자 출력 |

### 변수 선언, 정의, 초기화

변수는 source code에서 특정 object storage를 가리키기 위해 붙이는 이름이다. C에서 type은 그 storage의 크기, bit 해석 방식, 허용되는 연산, `printf()`나 `scanf()`에서 맞춰야 하는 format을 결정한다. 선언은 이름과 type을 compiler에게 알려 주는 행위이고, 정의는 실제 저장 공간을 잡는 행위이며, 초기화는 storage가 만들어지는 시점에 첫 값을 넣는 동작이다.

```c
int count = 10;
double ratio = 3.14;
char grade = 'A';
char *message = "Hello";
```

| 개념 | 예 | 의미 |
| :--- | :--- | :--- |
| 선언/정의 | `int count;` | `int` 값을 담을 storage 생성 |
| 초기화 | `int count = 10;` | 생성과 동시에 첫 값 대입 |
| 대입 | `count = 20;` | 이미 존재하는 변수 값 변경 |
| 문자 | `char grade = 'A';` | 문자 1개 저장 |
| 문자열 | `char *message = "Hello";` | 문자열 시작 위치를 가리키는 pointer |

변수 이름은 숫자로 시작할 수 없고, 공백을 포함할 수 없다. C keyword는 변수 이름으로 쓸 수 없으며, 대소문자를 구분한다. 예를 들어 `count`, `count1`, `_count`는 가능하지만 `1count`, `int`, `my value`는 변수명으로 적합하지 않다.

변수 이름은 값 그 자체가 아니라 값이 저장된 공간에 접근하는 문법적 통로다. `count`를 expression에서 사용하면 현재 저장된 값을 읽고, `&count`를 사용하면 그 storage의 주소를 얻는다. 이후 pointer 단원에서 `int *p = &count;`처럼 주소를 저장하면, `*p`를 통해 같은 storage를 다시 접근할 수 있다.

### 기본 데이터 타입과 format 지정자

C에서 타입은 메모리에 값을 어떤 크기와 해석 방식으로 저장할지 결정한다. 같은 bit pattern도 정수, 실수, 문자 중 무엇으로 보느냐에 따라 의미가 달라질 수 있다.

| 분류 | 대표 타입 | `printf` format | 용도 |
| :--- | :--- | :--- | :--- |
| 정수형 | `int` | `%d` | 정수 출력 |
| 실수형 | `float`, `double` | `%f` | 실수 출력 |
| 문자형 | `char` | `%c` | 문자 1개 출력 |
| 문자열 | `char *` | `%s` | 문자열 출력 |

정수형 데이터 타입은 저장 가능한 범위와 부호 여부에 따라 나뉜다. 기본 흐름에서는 `char`, `short`, `int`, `long`, `long long`처럼 크기가 다른 정수형을 보고, 필요에 따라 `unsigned`를 붙여 음수 없이 0 이상의 범위를 사용한다.

실수형 데이터 타입은 `float`, `double`, `long double` 순서로 더 넓은 표현 범위를 가진다. 일반적인 C 실습에서는 `double`을 기본 실수형처럼 많이 사용하고, `printf()`에서 `%f`로 출력해 값을 확인한다.

### 문자는 결국 숫자다

`char`는 문자 전용 마법 상자가 아니라 작은 정수형 타입이다. ASCII 표는 문자마다 숫자 값을 부여해 두었고, C에서는 문자 literal도 내부적으로 그 숫자 값으로 저장된다.

```c
#include <stdio.h>

int main(void)
{
    char ch = 'A';

    printf("%c\n", ch);
    printf("%d\n", ch);

    return 0;
}
```

위처럼 같은 `char` 값을 `%c`로 출력하면 문자 `A`가 보이고, `%d`로 출력하면 ASCII code 값인 `65`가 보인다. 즉 출력 format에 따라 같은 저장값을 문자로 볼지 숫자로 볼지가 달라진다.

ASCII에서 대문자와 소문자는 32만큼 차이 난다. 예를 들어 `'a'`는 `97`, `'A'`는 `65`이므로, 소문자에서 32를 빼면 대응하는 대문자 값이 된다.

```c
#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>

int main(void)
{
    char a = 'q';
    char b;

    // 변수 a에 저장된 문자를 대문자로 변환하여 b에 대입
    b = a - 32;

    printf("%c\n", b);

    return 0;
}
```

이 예제에서 `a`에는 소문자 `'q'`가 들어 있고, `b = a - 32;`는 ASCII code 기준으로 대문자 `'Q'`에 해당하는 값을 만든다. `printf("%c\n", b);`는 그 숫자를 문자로 해석해서 `Q`를 출력한다.

### ASCII 제어 문자

ASCII 앞부분의 `0x00`부터 `0x1F`까지는 화면에 보이는 일반 글자가 아니라 제어 문자다. 통신이나 터미널 제어에서 시작, 종료, 응답, 경고, 구분 같은 의미를 표현하기 위해 쓰인다.

| 값 | 이름 | 의미 |
| :--- | :--- | :--- |
| `0` | `NUL` | null, 값 0, 문자열 종료 표지 |
| `1` | `SOH` | Start of Heading |
| `2` | `STX` | Start of Text, 전송 시작 |
| `3` | `ETX` | End of Text |
| `4` | `EOT` | End of Transmission |
| `5` | `ENQ` | Enquiry |
| `6` | `ACK` | Acknowledge |
| `7` | `BEL` | Bell |
| `8` | `BS` | Backspace |
| `9` | `HT` | Horizontal Tab |
| `10` | `LF` | Line Feed, `\n` |
| `11` | `VT` | Vertical Tab |
| `12` | `FF` | Form Feed |
| `13` | `CR` | Carriage Return |
| `14` | `SO` | Shift Out |
| `15` | `SI` | Shift In |
| `16` | `DLE` | Data Link Escape |
| `17` | `DC1` | Device Control 1 |
| `18` | `DC2` | Device Control 2 |
| `19` | `DC3` | Device Control 3 |
| `20` | `DC4` | Device Control 4 |
| `21` | `NAK` | Negative Acknowledge |
| `22` | `SYN` | Synchronous Idle |
| `23` | `ETB` | End of Transmission Block |
| `24` | `CAN` | Cancel |
| `25` | `EM` | End of Medium |
| `26` | `SUB` | Substitute |
| `27` | `ESC` | Escape |
| `28` | `FS` | File Separator |
| `29` | `GS` | Group Separator |
| `30` | `RS` | Record Separator |
| `31` | `US` | Unit Separator |

`NULL`과 `NUL`은 구분해서 본다. ASCII의 `NUL`은 값이 0인 제어 문자이고, C 문자열에서는 `'\0'`로 문자열의 끝을 표시한다. C에서 `NULL`은 pointer가 아무 대상도 가리키지 않음을 나타낼 때 쓰는 null pointer constant이다. 둘 다 '없음' 또는 '비어 있음'이라는 감각은 공유하지만, 문자 값 0과 pointer 값 없음은 용도가 다르다.

## 2. `scanf`로 키보드 입력받기

`printf()`가 프로그램에서 화면으로 값을 내보내는 함수라면, `scanf()`는 키보드 입력을 변수에 저장하는 함수다. 입력받을 값의 타입은 format 지정자로 정하고, 값을 저장할 변수의 주소를 함께 넘긴다.

```c
#include <stdio.h>

int main(void)
{
    int age;

    scanf("%d", &age);
    printf("age = %d\n", age);

    return 0;
}
```

일반 변수는 `scanf()`에 넘길 때 변수 이름 앞에 `&`를 붙인다. `scanf()`가 값을 직접 바꿔야 하므로, 변수의 값이 아니라 변수의 저장 위치가 필요하기 때문이다.

| 입력받을 타입 | 예 | 의미 |
| :--- | :--- | :--- |
| `int` | `scanf("%d", &num);` | 정수 입력 |
| `double` | `scanf("%lf", &value);` | double 실수 입력 |
| `char` | `scanf(" %c", &ch);` | 문자 1개 입력 |
| 문자열 배열 | `scanf("%s", name);` | 배열 이름 자체가 시작 주소 |

`char` 입력에서는 format 앞의 공백이 중요할 수 있다. `" %c"`처럼 `%c` 앞에 공백을 넣으면 앞선 입력에서 남은 newline이나 공백을 건너뛰고 실제 문자를 받는다.

### `scanf_s`와 보안 경고

Windows/MSVC 계열 환경에서는 `scanf()` 대신 보안상 더 엄격한 `scanf_s()` 사용을 권장하는 경고가 나올 수 있다. `scanf_s()`는 문자열이나 문자 배열처럼 버퍼 크기가 중요한 입력에서 크기 정보를 추가로 요구한다.

```c
#include <stdio.h>

int main(void)
{
    int age;

    scanf_s("%d", &age);
    printf("age = %d\n", age);

    return 0;
}
```

`scanf()` 경고를 수업 실습용으로 끄려면 파일 맨 위에 다음 매크로를 추가할 수 있다.

```c
#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
```

이 매크로는 `scanf()` 자체를 더 안전하게 바꾸는 것이 아니라, MSVC의 secure 함수 사용 경고를 끄는 설정이다. 실습에서는 `scanf()`와 `scanf_s()`의 차이를 알고, 사용하는 컴파일러와 과제 기준에 맞춰 선택한다.

문자열 입력에서는 `scanf_s()`가 버퍼 크기를 요구한다.

```c
#include <stdio.h>

int main(void)
{
    char name[20];

    scanf_s("%19s", name, (unsigned)sizeof(name));
    printf("name = %s\n", name);

    return 0;
}
```

일반 변수는 `&num`, `&value`, `&ch`처럼 주소를 넘기고, 배열 이름인 `name`은 이미 배열의 시작 주소처럼 동작하므로 `&name`이 아니라 `name`을 넘긴다.

### `gets()`와 공백 포함 문자열

`scanf("%s", name)`은 공백을 만나면 입력을 끊기 때문에, 단어 하나가 아니라 문장 전체를 받기에는 불편하다. `gets()`는 Enter를 누르기 전까지 한 줄 전체를 문자열로 읽으므로, 중간에 공백이 포함된 문자열도 받을 수 있다.

```c
#include <stdio.h>

int main(void)
{
    char sentence[100];

    gets(sentence);
    printf("%s\n", sentence);

    return 0;
}
```

예를 들어 `Hello C World`처럼 공백이 들어간 입력도 `sentence` 배열에 한 줄로 저장된다. 다만 `gets()`는 배열 크기를 확인하지 않고 계속 입력을 받기 때문에 buffer overflow 위험이 크다. C99에서 구식 함수로 취급되었고, C11부터 표준에서 제거된 함수로 본다.

Visual Studio 계열 실습에서는 `gets()` 대신 `gets_s()`를 사용할 수 있다. `gets_s()`는 버퍼 크기를 함께 넘기기 때문에, 배열 크기를 넘는 입력을 막는 방향으로 동작한다.

```c
#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>

int main(void)
{
    char s[51];

    // gets(s);  // C99에서 구식 함수로 규정한 gets()를 제거하며 C11부터 적용됨.
    gets_s(s, sizeof(s));
    // fgets(s, sizeof(s), stdin);

    return 0;
}
```

`#define _CRT_SECURE_NO_WARNINGS`는 MSVC의 secure function 경고를 끄는 설정이고, `gets_s(s, sizeof(s))`는 입력 대상 배열과 배열 크기를 함께 넘기는 함수 호출이다. `sizeof(s)`는 `s` 배열 전체 크기인 51 byte를 의미한다.

표준 C 관점에서는 입력 가능한 크기를 제한할 수 있는 `fgets()`를 쓰는 편이 안전하다.

```c
#include <stdio.h>

int main(void)
{
    char sentence[100];

    fgets(sentence, sizeof(sentence), stdin);
    printf("%s", sentence);

    return 0;
}
```

수업 흐름에서는 `scanf("%s", ...)`가 공백 전까지만 받는다는 점과 `gets()`가 Enter 전까지 한 줄을 받는다는 점을 비교해서 이해한다. 실무나 과제 코드에서는 컴파일러 경고와 안전성 기준에 따라 `gets_s()` 또는 `fgets()` 같은 크기 제한 입력 함수를 우선 검토한다.

### `gets`, `gets_s`, `fgets` 지원 차이

문자열 입력 함수의 지원 여부는 '컴파일러' 하나로만 결정되지 않는다. 실제로는 C 언어 표준 버전, compiler option, header, C runtime library가 함께 영향을 준다. 같은 GCC나 Clang이라도 glibc, musl, macOS libc, MinGW/UCRT 중 무엇과 연결되는지에 따라 결과가 달라질 수 있다.

| 함수 | 표준 버전 관점 | 지원 성격 | 사용 판단 |
| :--- | :--- | :--- | :--- |
| `gets()` | C89/C90, C99까지 존재, C11에서 제거 | 오래된 환경에 남아 있을 수 있으나 위험 함수 | 새 코드에서 사용 금지 |
| `gets_s()` | C11 Annex K bounds-checking interface | 선택 지원 기능, 모든 C11 환경에 없음 | MSVC/지원 runtime에서만 확인 후 사용 |
| `fgets()` | C89/C90부터 계속 표준 | 대부분의 C compiler/runtime에서 지원 | 가장 이식성 높은 한 줄 입력 |

`gets_s()`는 C11에 들어온 Annex K 계열 함수지만, Annex K는 필수 구현 항목이 아니다. 표준 방식으로 확인하려면 `stdio.h`를 include하기 전에 `__STDC_WANT_LIB_EXT1__`를 정의하고, 구현체가 `__STDC_LIB_EXT1__`를 제공하는지 봐야 한다.

```c
#define __STDC_WANT_LIB_EXT1__ 1
#include <stdio.h>
```

다만 Visual Studio의 `gets_s()`는 MSVC secure CRT 흐름으로 제공되는 함수라고 보는 편이 실습에서는 더 실용적이다. 즉 `gets_s()`라는 이름이 같아도, 모든 compiler에서 똑같이 쓸 수 있다고 가정하면 안 된다.

| 환경 | `gets()` | `gets_s()` | `fgets()` | 메모 |
| :--- | :--- | :--- | :--- | :--- |
| MSVC / Visual Studio / UCRT | deprecated 또는 제거 흐름 | secure CRT로 지원 | 지원 | `gets_s()` 권장, `_CRT_SECURE_NO_WARNINGS`는 경고 억제 |
| GCC + glibc | C11 이상 모드에서 선언이 없거나 경고 발생 가능 | 보통 미지원 | 지원 | Linux에서는 `fgets()` 사용이 안전 |
| Clang + macOS libc | SDK/표준 모드에 따라 `gets()` 사용 제한 | 보통 미지원 | 지원 | macOS도 `fgets()` 중심 |
| GCC/Clang + MinGW/UCRT | runtime/header 설정 영향 | UCRT/MinGW header에 따라 가능성 있음 | 지원 | 빌드가 실패하면 `fgets()`로 전환 |
| 임베디드 C library | 구현체마다 다름 | 대체로 미지원 가능성 큼 | 구현체마다 다름 | vendor library 문서 확인 필요 |

`_CRT_SECURE_NO_WARNINGS`는 MSVC 계열의 보안 경고를 끄는 매크로이지, C 표준에서 제거된 함수를 되살리는 기능이 아니다. 함수가 header와 runtime에 없으면 이 매크로를 추가해도 link나 compile 문제가 해결되지 않는다.

## 3. 계산하기

C의 연산자는 값을 계산하거나, 값을 저장하거나, 메모리 위치와 타입 정보를 확인할 때 사용한다. 같은 기호라도 문맥에 따라 의미가 달라질 수 있으므로, 연산자 자체의 기능과 우선순위를 함께 봐야 한다.

### 3.1 사칙연산자

사칙연산은 숫자 값을 계산하는 가장 기본 연산이다. `+`, `-`, `*`는 수학에서 쓰는 의미와 거의 같고, `/`와 `%`는 C에서 특히 타입 영향을 많이 받는다.

| 연산자 | 이름 | 예 | 결과 |
| :--- | :--- | :--- | :--- |
| `+` | 덧셈 | `a + b` | 두 값의 합 |
| `-` | 뺄셈 | `a - b` | 왼쪽 값에서 오른쪽 값 차감 |
| `*` | 곱셈 | `a * b` | 두 값의 곱 |
| `/` | 나눗셈 | `a / b` | 몫 또는 실수 나눗셈 결과 |
| `%` | 나머지 | `a % b` | 정수 나눗셈의 나머지 |

`/`는 피연산자 타입에 따라 결과가 달라진다. `int / int`는 정수 나눗셈이므로 소수점 아래가 버려진다. 실수 결과가 필요하면 둘 중 하나를 `double`이나 `float`로 바꿔서 계산해야 한다.

```c
#include <stdio.h>

int main(void)
{
    int a = 10;
    int b = 3;

    printf("%d\n", a / b);
    printf("%f\n", (double)a / b);
    printf("%d\n", a % b);

    return 0;
}
```

| 식 | 의미 | 결과 감각 |
| :--- | :--- | :--- |
| `10 / 3` | 정수 나눗셈 | `3` |
| `(double)10 / 3` | 실수 나눗셈 | `3.333333` |
| `10 % 3` | 정수 나머지 | `1` |
| `n % 2` | 짝수/홀수 판별 | `0`이면 짝수, `1`이면 홀수 |

`%`는 정수형에만 사용한다. `double`이나 `float` 실수에 `%`를 쓰면 안 된다. 나머지 연산은 반복 순환, 짝수/홀수 판별, 배열 index 순환 같은 곳에서 자주 쓰인다.

### 기본 연산자 우선순위

연산자 우선순위는 여러 연산자가 한 식에 섞였을 때 어떤 연산을 먼저 할지 정하는 규칙이다. 헷갈리면 괄호를 쓰는 것이 가장 안전하다.

| 우선순위 | 연산자 | 결합 방향 | 예 |
| :--- | :--- | :--- | :--- |
| 높음 | `()`, 함수 호출 | 왼쪽 -> 오른쪽 | `(a + b) * c`, `printf()` |
|  | `++`, `--`, unary `+`, unary `-`, `(type)`, `sizeof`, `&` | 오른쪽 -> 왼쪽 | `++i`, `(double)a`, `sizeof(int)`, `&num` |
|  | `*`, `/`, `%` | 왼쪽 -> 오른쪽 | `a * b / c`, `a % b` |
|  | `+`, `-` | 왼쪽 -> 오른쪽 | `a + b - c` |
| 낮음 | `=`, `+=`, `-=`, `*=`, `/=`, `%=` | 오른쪽 -> 왼쪽 | `a += 3`, `a = b = 0` |

예를 들어 `2 + 3 * 4`는 곱셈이 덧셈보다 먼저 계산되어 `14`가 된다. `(2 + 3) * 4`처럼 괄호를 쓰면 덧셈이 먼저 계산되어 `20`이 된다.

### 3.2 복합대입, 증감, cast

#### 복합 대입 연산자

복합 대입 연산자는 현재 변수 값에 연산을 적용한 뒤 다시 같은 변수에 저장한다. `a += 3`은 기본적으로 `a = a + 3`과 같은 의미다.

| 연산자 | 풀어 쓴 형태 | 의미 |
| :--- | :--- | :--- |
| `a += b` | `a = a + b` | 더한 값을 다시 저장 |
| `a -= b` | `a = a - b` | 뺀 값을 다시 저장 |
| `a *= b` | `a = a * b` | 곱한 값을 다시 저장 |
| `a /= b` | `a = a / b` | 나눈 값을 다시 저장 |
| `a %= b` | `a = a % b` | 나머지를 다시 저장 |

```c
int count = 10;

count += 5;  // 15
count -= 3;  // 12
count *= 2;  // 24
count /= 4;  // 6
count %= 4;  // 2
```

복합 대입 연산자는 누적 합, counter 갱신, 반복문 안의 상태 갱신에서 자주 쓰인다. 오른쪽 값을 계산한 뒤 왼쪽 변수에 다시 저장한다는 감각으로 읽으면 된다.

#### 증감 연산자

증감 연산자는 변수 값을 1 증가시키거나 1 감소시킨다. 단독 문장으로 쓰면 전위형과 후위형 결과가 같지만, 다른 식 안에서 쓰면 값이 사용되는 시점이 달라진다.

| 연산자 | 이름 | 의미 | 식 안에서의 차이 |
| :--- | :--- | :--- | :--- |
| `++i` | 전위 증가 | 먼저 1 증가 | 증가된 값 사용 |
| `i++` | 후위 증가 | 나중에 1 증가 | 기존 값 사용 후 증가 |
| `--i` | 전위 감소 | 먼저 1 감소 | 감소된 값 사용 |
| `i--` | 후위 감소 | 나중에 1 감소 | 기존 값 사용 후 감소 |

```c
#include <stdio.h>

int main(void)
{
    int i = 5;
    int a;
    int b;

    a = ++i;  // i가 6이 된 뒤 a에 6 저장
    b = i++;  // b에 6 저장 후 i가 7로 증가

    printf("i=%d, a=%d, b=%d\n", i, a, b);
    return 0;
}
```

초기 학습에서는 `i++`나 `++i`를 복잡한 식 안에 섞기보다, 한 줄에서 하나의 상태 변화만 보이게 쓰는 편이 실수를 줄인다.

#### cast 연산

cast는 값을 다른 타입으로 해석하도록 명시하는 연산이다. 문법은 `(타입)값` 형태다. 정수끼리 나누면 정수 결과가 나오므로, 실수 나눗셈이 필요할 때 cast를 자주 사용한다.

```c
int a = 10;
int b = 3;
double result;

result = (double)a / b;
```

| 식 | 의미 | 주의점 |
| :--- | :--- | :--- |
| `(double)a` | `a`를 `double`로 변환 | 실수 계산 유도 |
| `(int)3.14` | 실수를 정수로 변환 | 소수부 버림 |
| `(char)65` | 숫자를 문자 타입으로 변환 | ASCII 기준 `A` |

cast는 컴파일러에게 '이 타입으로 보겠다'고 알려 주는 장치다. 다만 작은 타입으로 변환하면 값 손실이 생길 수 있고, 실수를 정수로 바꾸면 소수부가 버려진다.

### 3.3 `sizeof`, `&`

#### `sizeof` 연산

`sizeof`는 타입이나 객체가 메모리에서 차지하는 byte 크기를 구하는 연산자다. 결과 타입은 `size_t`이며, 출력할 때는 보통 `%zu`를 사용한다.

```c
#include <stdio.h>

int main(void)
{
    int num = 10;
    char s[51];

    printf("%zu\n", sizeof(int));
    printf("%zu\n", sizeof(num));
    printf("%zu\n", sizeof(s));

    return 0;
}
```

| 식 | 의미 |
| :--- | :--- |
| `sizeof(int)` | `int` 타입 크기 |
| `sizeof(num)` | 변수 `num`이 차지하는 크기 |
| `sizeof(s)` | 배열 `s` 전체 크기 |
| `sizeof(s[0])` | 배열 원소 1개의 크기 |

`char s[51]`에서 `sizeof(s)`는 문자열 길이가 아니라 배열 전체 크기다. `s`에 `"abc"`만 들어 있어도 배열은 51 byte 공간을 가진다. 그래서 `gets_s(s, sizeof(s))`나 `fgets(s, sizeof(s), stdin)`처럼 입력 가능한 최대 크기를 넘겨 줄 때 유용하다.

#### `&` address-of 연산

`&`는 변수의 주소를 구하는 연산자다. `scanf()`에서 일반 변수 앞에 `&`를 붙이는 이유는 입력받은 값을 저장할 메모리 위치를 함수에 알려 주기 위해서다.

```c
#include <stdio.h>

int main(void)
{
    int num;

    scanf("%d", &num);
    printf("num = %d\n", num);
    printf("address = %p\n", (void *)&num);

    return 0;
}
```

| 표현 | 의미 | 사용 위치 |
| :--- | :--- | :--- |
| `num` | 변수에 저장된 값 | `printf("%d", num)` |
| `&num` | 변수 `num`의 주소 | `scanf("%d", &num)` |
| `s` | 배열 시작 주소처럼 사용 | `scanf("%s", s)` |
| `sizeof(s)` | 배열 전체 byte 크기 | `gets_s(s, sizeof(s))` |

주소 출력에는 `%p`를 사용하고, 인자는 `(void *)&num`처럼 맞춰 주는 것이 좋다. 이후 pointer를 배우면 `&`로 얻은 주소를 pointer 변수에 저장하고, 그 주소를 통해 원래 변수에 접근하는 흐름으로 이어진다.

## 4. 나만의 함수 만들기

함수는 호출 가능한 code block에 이름, parameter type, return type을 붙인 단위다. C 프로그램은 `main()` 함수에서 시작하지만, 계산이나 출력처럼 책임이 분리되는 작업은 별도 함수로 만들 수 있다. 함수를 호출하면 호출 지점의 실행을 잠시 멈추고 함수 body로 이동하며, parameter storage가 만들어지고 argument 값이 그 parameter에 복사된다.

### 4.1 함수의 형식

함수는 크게 parameter, operation, return으로 구성된다. parameter는 함수가 외부에서 받는 입력 이름이고, operation은 함수 내부에서 수행하는 동작이며, return은 함수가 호출한 쪽으로 돌려주는 값이다. C의 일반 parameter 전달은 값 복사이므로, 함수 안에서 parameter 값을 바꿔도 호출한 쪽의 원본 변수는 바뀌지 않는다. 원본을 바꾸려면 주소를 parameter로 전달하고 pointer로 역참조해야 한다.

| 구성 | 의미 | 코드 위치 |
| :--- | :--- | :--- |
| parameter | 입력값을 받는 자리 | `(int a, int b)` |
| operation | 함수 내부 동작 | `{ ... }` 안의 code |
| return | 결과 출력 | `return result;` |

함수의 기본 형태는 다음과 같다.

```c
return_type function_name(parameter_list)
{
    code
}
```

각 부분은 타입과 이름을 기준으로 읽는다. `return_type`은 함수가 돌려줄 값의 data type이고, `function_name`은 함수를 호출할 때 쓰는 identifier다. `parameter_list`는 함수가 받을 argument의 type과 이름을 적는 자리다.

| 부분 | 의미 | 예 |
| :--- | :--- | :--- |
| `return_type` | 반환값의 data type | `int`, `double`, `void` |
| `function_name` | 함수 이름 identifier | `add`, `printHello` |
| `parameter_list` | 받을 argument의 type과 parameter 이름 | `int a, int b` |
| `code` | 실제 기능 구현 | 계산, 출력, 조건 처리 |

예를 들어 두 정수를 받아 합계를 돌려주는 함수는 다음처럼 쓴다.

```c
int add(int a, int b)
{
    int result;

    result = a + b;
    return result;
}
```

이 함수에서 `int`는 return type, `add`는 함수명, `(int a, int b)`는 parameter list다. `a`와 `b`는 함수가 받을 입력이고, `result = a + b;`는 operation이며, `return result;`는 계산 결과를 출력값처럼 호출한 쪽으로 돌려준다.

함수를 호출할 때 실제로 넘기는 값은 argument라고 부른다. 함수 정의의 `int a`, `int b`는 parameter이고, `add(10, 20)`에서 `10`, `20`은 argument다.

### 4.2 함수의 선언

함수는 사용하기 전에 compiler가 함수의 형태를 알고 있어야 한다. 함수 정의가 `main()`보다 아래에 있으면, `main()`에서 함수를 호출하는 시점에는 return type과 parameter list를 아직 모르는 상태가 된다. 이때 함수 prototype을 위쪽에 미리 선언한다.

함수 선언은 함수의 이름, return type, 받을 argument의 type을 미리 알려 주는 문장이다. 실제 operation code는 없고, 끝에 semicolon을 붙인다.

```c
int add(int a, int b);
```

| 구분 | 형태 | 역할 |
| :--- | :--- | :--- |
| 함수 선언 | `int add(int a, int b);` | 함수 형식 사전 알림 |
| 함수 정의 | `int add(int a, int b) { ... }` | 실제 기능 구현 |
| 함수 호출 | `add(10, 20)` | argument 전달 후 실행 |

prototype의 parameter 이름은 생략할 수 있다. 즉 `int add(int, int);`처럼 type만 적어도 compiler는 함수 호출 검사를 할 수 있다. 다만 수업 초반에는 `int add(int a, int b);`처럼 이름까지 같이 적는 편이 읽기 쉽다.

```c
#include <stdio.h>

int add(int a, int b);

int main(void)
{
    int result;

    result = add(10, 20);
    printf("%d\n", result);

    return 0;
}

int add(int a, int b)
{
    return a + b;
}
```

위 코드에서 `int add(int a, int b);`는 함수 미리 선언이고, 아래쪽의 `int add(int a, int b) { ... }`는 함수 정의다. `main()`은 선언을 보고 `add()`가 정수 두 개를 받아 정수를 돌려주는 함수라는 사실을 먼저 알고 호출할 수 있다.

### 4.3 변수의 유효 범위

scope는 이름이 유효한 범위다. 변수는 선언된 위치에 따라 사용할 수 있는 영역이 달라진다. 함수 안에서 선언한 변수는 지역변수이고, 함수 밖에서 선언한 변수는 전역변수다.

| 종류 | 선언 위치 | 유효 범위 | 특징 |
| :--- | :--- | :--- | :--- |
| 지역변수 | 함수나 block 내부 | 선언된 block 내부 | 함수 실행 중 사용 |
| 전역변수 | 함수 밖 | 파일 전체 기준 | 여러 함수에서 접근 가능 |
| parameter | 함수 parameter list | 함수 내부 | 호출 시 argument 값 복사 |

```c
#include <stdio.h>

int value = 100;

void printValue(void)
{
    int value = 10;

    printf("%d\n", value);
}
```

위 코드처럼 전역변수와 지역변수가 같은 이름을 가지면, 지역 scope 안에서는 지역변수가 우선한다. 즉 `printValue()` 안의 `value`는 전역변수 `value = 100`이 아니라 지역변수 `value = 10`을 뜻한다. 이처럼 같은 이름의 전역변수가 지역변수에 의해 가려지는 현상을 은닉 또는 shadowing으로 본다.

전역변수는 여러 함수에서 공유할 수 있어 편하지만, 값이 바뀌는 지점을 추적하기 어려워질 수 있다. 기본 실습에서는 필요한 값은 parameter로 넘기고, 결과는 return으로 받는 흐름을 먼저 익히는 것이 좋다.

### 4.4 macro와 preprocessor

preprocessor는 C compiler가 본격적으로 compile하기 전에 사전 작업을 수행하는 단계다. header file을 포함하고, macro를 치환하고, 조건부 compile 영역을 고르는 일을 먼저 처리한다.

| 지시문 | 이름 | 역할 |
| :--- | :--- | :--- |
| `#include` | include | header file 내용 포함 |
| `#define` | define | 앞 단어를 뒤 내용으로 치환 |
| `#if` | conditional compile | 조건이 참인 영역 선택 |
| `#else` | alternative branch | 조건이 거짓일 때 선택 |
| `#elif` | else if branch | 추가 조건 검사 |
| `#endif` | conditional end | 조건부 compile 종료 |
| `#pragma` | compiler directive | compiler별 특수 지시 |

`#define`은 앞 단어를 뒤 내용으로 바꾸는 macro 정의다. compiler가 C 문장을 의미 분석하기 전에 text 기반으로 치환되므로, type check가 되는 변수나 함수와는 성격이 다르다.

```c
#define MAX_COUNT 100
#define PI 3.141592

int count = MAX_COUNT;
double radius = 3.0;
double area = radius * radius * PI;
```

위 코드에서 `MAX_COUNT`는 preprocessing 단계에서 `100`으로 바뀌고, `PI`는 `3.141592`로 바뀐다. 값에 이름을 붙여 코드 의미를 분명하게 만들 때 자주 쓴다.

macro는 함수처럼 parameter를 받는 형태로도 만들 수 있다.

```c
#define SQUARE(x) ((x) * (x))

int result = SQUARE(5);
```

function-like macro는 실제 함수 호출이 아니라 code 치환이다. 그래서 `#define SQUARE(x) x * x`처럼 괄호를 생략하면 `SQUARE(1 + 2)`가 `1 + 2 * 1 + 2`처럼 의도와 다르게 계산될 수 있다. macro에서는 인자와 전체 식을 괄호로 감싸는 습관이 중요하다.

조건부 compile은 platform이나 설정에 따라 다른 code를 선택할 때 사용한다.

```c
#if DEBUG
    printf("debug mode\n");
#else
    printf("release mode\n");
#endif
```

전처리 지시문은 C 문장과 달리 `#`로 시작하며, compile 전에 먼저 처리된다. `#pragma`는 compiler별 기능을 제어하는 지시문이므로 이식성이 필요한 code에서는 사용 가능 여부를 확인해야 한다.

## 다음 수업 연결

0701 수업에서는 `4. 나만의 함수 만들기`까지 완료했다. `5. 조건에 따른 실행`은 `if`문 흐름으로 진입했지만 수업 중간에 멈춘 상태라, 0702 선행 메모로 분리해 둔다.

| 항목 | 위치 |
| :--- | :--- |
| 5번 이후 정리 | [260702-c-programming-continuation.md](260702-c-programming-continuation.md) |

## 확인할 것

- `C:\msys64\ucrt64\bin`이 사용자 `Path`와 시스템 `Path`에 모두 들어갔는지 확인
- VSCode 터미널에서 `make` 명령이 인식되는지 확인
- `1.C_LAB` 폴더 기준 터미널에서 `make`, `make run`, `make clean` 순서가 동작하는지 확인
- `main.c` 예제 전환 후 `#if` 값을 원래 상태로 되돌렸는지 확인
- `printf()` format과 실제 출력 형태를 함께 확인
- `char`를 `%c`, `%d`로 각각 출력해 문자와 숫자 해석 차이 확인
- ASCII 대소문자 차이 `32`와 `'\0'`, `NULL`의 차이 구분
- `scanf()`에서 일반 변수에 `&`를 붙이는 이유 확인
- `scanf_s()` 권장 이유와 `_CRT_SECURE_NO_WARNINGS`의 역할 구분
- `scanf("%s", ...)`와 `gets()`의 공백 처리 차이 확인
- `gets()`의 buffer overflow 위험과 `gets_s()`, `fgets()` 대체 흐름 확인
- `gets_s()`는 C11 Annex K 선택 지원이며, compiler/runtime별로 사용 가능성이 다름
- 이식성 기준 문자열 입력은 `fgets()` 우선 검토
- `/`와 `%`의 차이, 정수 나눗셈과 실수 나눗셈 차이 확인
- 복합 대입, 전위/후위 증감 연산자의 값 사용 시점 확인
- cast, `sizeof`, `&` address-of 연산의 용도 구분
- 함수 형식을 parameter 입력, operation 동작, return 출력 흐름으로 구분
- `return_type function_name(parameter_list)`에서 return type, 함수명, parameter list 역할 확인
- 함수 선언과 함수 정의의 차이, prototype을 미리 쓰는 이유 확인
- 지역변수, 전역변수, parameter의 scope 차이 확인
- 같은 이름의 지역변수가 전역변수를 은닉하는 상황 확인
- `#define` macro 치환과 `#include`, `#if`, `#else`, `#elif`, `#endif`, `#pragma` 역할 구분
- `5. 조건에 따른 실행` 이후 정리는 [260702-c-programming-continuation.md](260702-c-programming-continuation.md)에서 관리
