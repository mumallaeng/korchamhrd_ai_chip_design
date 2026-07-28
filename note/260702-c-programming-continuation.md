# 26-07-02 - C Lab 조건문 이후 예제 정리

원본 위치:

`Google Drive/My Drive/Classroom/대한상공회의소_반도체설계/담당강사/상공회의소_KDT_실습자료(C_Python_M4)/1.C_Lab/main.c`

이 파일은 C 실습자료의 `[5-1]` 이후 예제를 원본 예제 순서에 맞춰 정리한 기준 노트다. 실제 날짜 노트인 [260702-c-control-flow-arrays-structs.md](260702-c-control-flow-arrays-structs.md)와 [260703-c-number-system-conversion.md](260703-c-number-system-conversion.md)에 옮길 때는 수업에서 실제로 진행한 범위를 기준으로 본문을 선별한다.

## 수업 흐름

| 범위 | 주제 | 핵심 |
| :--- | :--- | :--- |
| `[5-1]`~`[5-11]` | 조건에 따른 실행 | `if`, 복합문, `else`, 비교/논리 연산, `switch`, `break` |
| `[6-1]`~`[6-10]` | 반복하여 처리하기 | `for`, 별찍기, 중첩 loop 탈출, `goto`, 조건 반복, `continue` |
| `[7-1]`~`[7-12]` | 데이터 모아서 다루기 | 배열, 이차원 배열, 문자열 배열, 구조체, 구조체 배열, `typedef` |
| `[8-1]`~`[8-12]` | C문법 조금 더 알아보기 | 진법 format, `while`, `do-while`, 배열 memory, transpose, `union`, endian |
| `[9-1]`~`[9-18]` | 기본 포인터 활용 | pointer, 문자열, 배열 parameter/return, 구조체 pointer |

## 5. 조건에 따른 실행

조건문은 값이나 상태에 따라 실행 경로를 나누는 문법이다. C에서는 조건식 결과가 `0`이면 거짓, `0`이 아니면 참이다.

### 5.1 `if`와 복합문

`[5-1]`은 `if`문의 기본 형식을 확인한다.

```c
if (condition)
{
    statement;
}
```

`[5-2]`의 핵심은 실행문이 한 줄이어도 `{}`를 쓰는 습관이다. C 문법상 한 줄이면 `{}` 없이도 가능하지만, 이후에 문장을 추가할 때 의도와 다르게 조건문 밖으로 빠지는 실수를 줄이기 위해 복합문을 권장한다.

```c
if (n > 0)
{
    printf("positive\n");
}
```

복합문은 여러 문장을 하나의 block으로 묶고, block 내부에서 새 지역 변수를 만들 수 있게 한다.

### 5.2 `if ~ else`, 비교 연산, 주의사항

`[5-3]`은 참/거짓 두 갈래 분기를 다룬다. `if` 조건이 참이면 첫 block이 실행되고, 거짓이면 `else` block이 실행된다.

| 연산자 | 의미 |
| :--- | :--- |
| `==` | 같음 |
| `!=` | 같지 않음 |
| `<` | 작음 |
| `<=` | 작거나 같음 |
| `>` | 큼 |
| `>=` | 크거나 같음 |

`[5-5]`에서 가장 중요한 주의점은 `=`와 `==` 구분이다. `=`는 대입이고 `==`는 비교다. 조건문에서 실수로 `if (a = 10)`처럼 쓰면 `a`에 10을 넣은 뒤 그 결과를 조건으로 판단한다.

`else`는 가장 가까운 짝이 없는 `if`와 연결된다. nested `if`를 사용할 때는 `{}`로 의도를 분명하게 표시해야 한다.

### 5.3 배타 조건과 홀짝 판단

`[5-6]`은 여러 조건 중 한 가지 조건만 충족해야 하는 흐름을 다룬다. 여러 `if`를 독립적으로 쓰면 조건이 둘 이상 동시에 참일 때 여러 block이 실행될 수 있다. 한 번만 선택되어야 한다면 `if ~ else if ~ else` 구조가 적합하다.

`[5-7-1]`, `[5-7-2]`는 홀짝 판단을 함수로 분리한다. 핵심은 `%` 연산으로 2로 나눈 나머지를 확인하는 점이다.

```c
int is_even(int n)
{
    return n % 2 == 0;
}
```

결과를 바로 출력하는 방식보다, 판단 결과를 return해서 호출부에서 사용하는 방식이 재사용성이 좋다.

`n % 2 == 0`은 비교식이므로 참이면 `1`, 거짓이면 `0`처럼 조건값으로 사용할 수 있다. C의 조건 판단은 `0`을 거짓, `0`이 아닌 값을 참으로 처리하므로 `is_even()`의 반환값을 `if (is_even(n))`처럼 바로 사용할 수 있다.

### 5.4 논리 연산자

`[5-8]`, `[5-9]`는 `&&`, `||`, `!`를 이용해 조건을 결합한다.

| 연산자 | 의미 | 예 |
| :--- | :--- | :--- |
| `&&` | AND | 둘 다 참 |
| `||` | OR | 하나 이상 참 |
| `!` | NOT | 참/거짓 반전 |

2 또는 3의 배수를 판단하려면 다음처럼 작성할 수 있다.

```c
if (n % 2 == 0 || n % 3 == 0)
{
    printf("yes\n");
}
```

`&&`와 `||`는 short-circuit evaluation을 수행한다. `&&`는 왼쪽이 거짓이면 오른쪽을 보지 않고, `||`는 왼쪽이 참이면 오른쪽을 보지 않는다.

### 5.5 `switch`와 `break`

`[5-10]`, `[5-11]`은 값 기준 분기인 `switch`문을 다룬다.

```c
switch (menu)
{
case 1:
    printf("coffee\n");
    break;
case 2:
    printf("tea\n");
    break;
default:
    printf("unknown\n");
    break;
}
```

`break`는 자신이 포함된 가장 안쪽의 `for`, `switch`, `while`, `do ~ while`을 탈출한다. `switch`에서 `break`를 빠뜨리면 다음 `case`로 이어지는 fall-through가 발생한다. fall-through가 의도된 코드라면 주석으로 명시하고, 의도가 아니라면 각 `case` 끝에 `break`를 둔다.

## 6. 반복하여 처리하기

반복문은 같은 패턴의 작업을 여러 번 수행할 때 사용한다. C 실습에서는 먼저 `for`문의 구조를 보고, 이후 `while`, `do ~ while`, 무한 반복, `break`, `continue`, `goto`를 비교한다.

### 6.1 `for`문의 구조

`[6-1]`은 0부터 9까지 출력하며 `for`문의 세 부분을 확인한다.

```c
for (initialization; condition; afterthought)
{
    statement;
}
```

| 구성 | 역할 | 예 |
| :--- | :--- | :--- |
| 초기화식 | 반복 변수 초기값 설정 | `i = 0` |
| 조건식 | 반복 계속 여부 판단 | `i < 10` |
| 후실행식 | 반복 1회 후 실행 | `i++` |

`for (i = 0; i < 10; i++)`는 `i`가 0부터 9까지 변하는 10회 반복이다.

### 6.2 편리한 `for` 구문과 짝수 합

`[6-2-1]`부터 `[6-2-4]`는 반복 범위를 다르게 잡는 여러 형태를 다룬다. 시작값, 종료 조건, 증감값을 바꾸면 같은 `for`문으로 다양한 순서를 만들 수 있다.

`[6-3]`은 1부터 입력받은 수까지의 짝수 합을 구한다. 반복문으로 후보 숫자를 만들고, 조건문으로 짝수만 골라 누적한다.

```c
int sum_even(int n)
{
    int i;
    int sum = 0;

    for (i = 1; i <= n; i++)
    {
        if (i % 2 == 0)
        {
            sum += i;
        }
    }

    return sum;
}
```

`for (i = 2; i <= n; i += 2)`처럼 짝수만 순회하도록 반복식을 바꾸는 방법도 가능하다.

### 6.3 별찍기와 중첩 반복

`[6-4]`, `[6-5]`, `[6-6]`은 중첩 `for`문을 이용한 출력 패턴이다. 바깥 loop는 행(row)을 담당하고, 안쪽 loop는 한 행 안의 열(column)을 담당한다.

| 패턴 | loop 기준 |
| :--- | :--- |
| 네모 | 모든 행에서 같은 개수 출력 |
| 왼쪽 직삼각형 | 행 번호가 커질수록 출력 개수 증가 |
| 오른쪽 직삼각형 | 앞쪽 공백 뒤에 별 출력 |
| 왼쪽 역직삼각형 | 행 번호가 커질수록 출력 개수 감소 |
| 오른쪽 역직삼각형 | 공백 증가, 별 감소 |
| 역삼각형 | 양쪽 공백과 홀수 개수 별 조합 |

네모는 행과 열의 반복 횟수가 고정되어 있다.

```c
for (i = 0; i < h; i++)
{
    for (j = 0; j < w; j++)
    {
        printf("*");
    }
    printf("\n");
}
```

삼각형은 `i`와 `j`의 관계를 조건으로 만들거나, 공백 loop와 별 loop를 나눠서 작성한다. 핵심은 화면 모양을 행 단위로 분해하고, 한 행에서 먼저 출력할 공백 수와 별 수를 수식으로 만드는 점이다.

예를 들어 높이가 `h`인 왼쪽 직각삼각형은 `i`번째 행에서 별을 `i + 1`개 출력한다. 오른쪽 직각삼각형은 별 개수는 같지만 앞쪽 공백을 `h - i - 1`개 먼저 출력한다. 역삼각형은 행이 증가할수록 별 개수를 줄이는 방식으로 같은 원리를 뒤집어 적용한다.

### 6.4 `break`, 다중 loop 탈출, `goto`

`[6-7]`은 `for` 안에서 `break`를 사용해 반복을 중단하는 예제다. `break`는 가장 안쪽 반복문만 빠져나간다.

`[6-8]`, `[6-9-1]`부터 `[6-9-3]`은 중첩 loop에서 바깥 loop까지 빠져나가는 방법을 비교한다.

| 방법 | 핵심 | 특징 |
| :--- | :--- | :--- |
| flag 변수 | 탈출 여부를 변수로 기록 | 구조가 명시적 |
| 조건식 보정 | 바깥 loop 조건도 false로 만듦 | 반복 조건과 탈출 조건 결합 |
| `goto` | 함수 내 label로 분기 | 흐름이 강하게 바뀜 |

`goto`는 함수 내 지정 위치(label)로 분기한다. 중첩 loop를 한 번에 탈출할 때는 쓸 수 있지만, 남용하면 흐름 추적이 어려워진다.

```c
goto out;

out:
    printf("exit\n");
```

### 6.5 조건이 될 때까지 반복

`[6-10]`은 조건이 만족될 때까지 반복하는 형태다. 일반적으로는 `while`이나 `do ~ while`을 사용하고, `for (;;)`는 무한 loop를 만든 뒤 내부에서 `break;`로 빠져나가는 형태로 사용할 수 있다.

`while`은 조건을 먼저 검사하므로 조건이 처음부터 거짓이면 body가 한 번도 실행되지 않는다. `do ~ while`은 body를 먼저 실행한 뒤 조건을 검사하므로 최소 한 번은 실행된다. 사용자 입력을 적어도 한 번 받아야 하는 문제에서는 `do ~ while`이 자연스럽고, 종료 조건을 body 중간에서 판단해야 하는 문제에서는 `while (1)` 또는 `for (;;)`와 `break` 조합이 단순할 수 있다.

`continue`는 반복문 전체를 종료하지 않고 현재 반복 회차의 남은 문장만 건너뛴다. `for`문에서는 `continue` 이후 후실행식으로 이동하고, `while`문에서는 조건식 검사로 이동한다. 따라서 누적 계산에서 특정 값만 제외하려면 `continue`를 사용할 수 있지만, 반복 변수 갱신 위치를 잘못 두면 무한 loop가 될 수 있다.

```c
for (;;)
{
    scanf("%d", &n);

    if (n >= 0)
    {
        break;
    }
}
```

`continue`는 현재 반복의 남은 code를 건너뛰고 다음 반복으로 이동한다. `break`가 반복 자체를 끝낸다면, `continue`는 이번 회차만 끝낸다.

## 7. 데이터 모아서 다루기

배열과 구조체는 여러 데이터를 하나의 이름 아래 묶는 방법이다. 배열은 같은 타입 데이터를 index로 관리하고, 구조체는 서로 다른 타입의 데이터를 member 이름으로 관리한다.

### 7.1 배열과 indexing

`[7-1]`은 배열의 기본 indexing을 다룬다.

```c
int a[4] = {10, 20, 30, 40};

a[1] = -20;
printf("%d\n", a[1]);
```

C 배열의 index는 0부터 시작한다. `a[0]`은 첫 번째 요소이고, `a[3]`은 4개짜리 배열의 마지막 요소다.

`char b[] = { 'a', 'b', 'c', 'd' };`는 문자 4개짜리 배열이다. 반면 `char c[] = "ABCD";`는 문자열 literal을 배열에 저장하므로 마지막에 `'\0'`이 자동으로 들어간다.

| 선언 | 실제 저장 | `sizeof` |
| :--- | :--- | :--- |
| `char b[] = { 'a', 'b', 'c', 'd' };` | `a`, `b`, `c`, `d` | `4` |
| `char c[] = "ABCD";` | `A`, `B`, `C`, `D`, `'\0'` | `5` |

`'\0'`은 값이 `0`인 null character다. 숫자 `0`, 문자 `'0'`, 알파벳 `O`와 헷갈리지 않도록 `'\0'`로 표기한다. C 문자열 함수들은 이 값을 문자열의 끝으로 본다.

문자열 배열은 길이 정보를 따로 저장하지 않는다. `%s`, `strlen()`, 문자열 비교 함수는 시작 주소부터 `'\0'`을 만날 때까지 순차적으로 읽는다. 따라서 입력 버퍼 크기보다 긴 문자열이 들어오면 null character를 저장할 자리가 사라지거나 배열 밖을 덮어쓸 수 있으므로, `%20s`처럼 폭 제한을 두는 방식이 안전하다.

### 7.2 배열 순회와 누적

`[7-2]`, `[7-3]`은 배열을 반복문으로 순회한다. 배열 크기만큼 `for`를 돌며 각 요소를 읽거나 쓴다.

```c
int i;
int sum = 0;
int a[10];

for (i = 0; i < 10; i++)
{
    scanf("%d", &a[i]);
}

for (i = 0; i < 10; i++)
{
    sum += a[i];
}
```

배열 요소를 `scanf()`로 입력받을 때는 `&a[i]`처럼 해당 요소의 주소를 넘긴다.

### 7.3 이차원 배열

`[7-4]`, `[7-5]`는 `a[row][col]` 형태의 이차원 배열을 다룬다.

```c
int a[3][4] = {
    {1, 2, 3, 4},
    {5, 6, 7, 8},
    {9, 10, 11, 12}
};
```

C의 이차원 배열은 row-major 방식으로 memory에 배치된다. 즉 한 행의 요소들이 연속으로 저장되고, 다음 행이 이어진다. 행별 합을 구할 때는 바깥 loop가 행, 안쪽 loop가 열을 담당한다.

### 7.4 문자열 배열

`[7-6]`은 여러 문자열을 이차원 `char` 배열에 저장한다.

```c
char s[][7] = { "Hello", "C", "World!" };
```

두 번째 차원 크기 `7`은 가장 긴 문자열인 `"World!"`의 6글자와 마지막 `'\0'`까지 담기 위한 크기다. 문자열을 저장할 때는 화면에 보이는 글자 수보다 null character 공간까지 고려해야 한다.

### 7.5 구조체와 `typedef`

`[7-7]`부터 `[7-12]`는 구조체를 다룬다. 구조체는 서로 다른 타입의 데이터를 하나의 record처럼 묶는다.

```c
typedef struct
{
    int id;
    char name[20];
    double score;
} Student;
```

| 문법 | 의미 |
| :--- | :--- |
| `struct` | member를 가진 사용자 정의 타입 |
| `.` | 구조체 변수의 member 접근 |
| 구조체 대입 | 같은 타입 구조체끼리 전체 복사 |
| 구조체 배열 | 같은 구조체 record 여러 개 관리 |
| `typedef` | 타입 이름에 별칭 부여 |

구조체 member는 `student.score`처럼 `.` 연산자로 접근한다. 구조체 배열은 `students[i].score`처럼 배열 indexing과 member 접근을 함께 사용한다.

## 8. C문법 조금 더 알아보기

### 8.1 진법 format과 반복문 변형

`[8-1]`은 정수를 여러 진법으로 출력하는 format을 다룬다.

| format | 의미 |
| :--- | :--- |
| `%d` | signed decimal |
| `%u` | unsigned decimal |
| `%o` | octal |
| `%x`, `%X` | hexadecimal |

`[8-2-1]`, `[8-2-2]`는 `while`문이다. `while`은 조건이 참인 동안 반복한다. 반복 횟수가 명확하면 `for`, 조건이 만족될 때까지 반복하면 `while`이 자연스럽다.

`[8-3]`은 `do ~ while`이다. 조건 검사를 뒤에서 하므로 body가 최소 1회 실행된다.

```c
do
{
    scanf("%d", &n);
} while (n < 0);
```

### 8.2 배열 memory와 transpose

`[8-4]`, `[8-5]`는 배열의 주소와 memory 구조를 확인한다. `a`, `&a[0]`, `&a`는 주소 값이 같아 보일 수 있지만 타입과 pointer 연산 단위가 다르다.

`[8-6]`은 행과 열의 합을 비교하고, `[8-7]`, `[8-8]`은 transpose를 다룬다.

```c
b[j][i] = a[i][j];
```

transpose는 행과 열을 바꾸는 작업이다. `M x N` 배열을 transpose하면 `N x M` 형태가 된다.

### 8.3 구조체 member, 복사, 공용체, endian

`[8-9]`는 구조체 member의 타입이 각각 독립적으로 정해진다는 점을 확인한다. member 접근 시에는 해당 member의 타입을 기준으로 읽고 쓴다.

`[8-10]`은 문자열 복사와 memory 복사를 비교한다. 문자열은 `'\0'`까지 복사해야 하므로 `strcpy()` 같은 함수가 쓰이고, raw memory는 `memcpy()`처럼 byte 단위 복사가 가능하다.

`[8-11]`은 `union`을 다룬다. 공용체는 여러 member가 같은 memory 공간을 공유한다. 같은 byte를 `int`, `char[]` 등 여러 방식으로 해석할 수 있다.

`[8-12]`는 endian을 확인한다. endian은 여러 byte로 구성된 값을 memory에 어떤 순서로 저장하는지에 대한 규칙이다.

| 방식 | 낮은 주소에 저장되는 byte |
| :--- | :--- |
| little endian | least significant byte |
| big endian | most significant byte |

## 9. 기본 포인터 활용

### 9.1 pointer의 의미

`[9-1]`, `[9-2]`는 pointer가 주소를 저장하는 변수임을 확인한다.

```c
int a = 10;
int *p = &a;

printf("%d\n", *p);
```

`p`는 `a`의 주소를 저장하고, `*p`는 그 주소에 있는 값을 의미한다. pointer 타입은 역참조할 때 몇 byte를 어떤 타입으로 읽을지 결정한다.

| pointer type | 역참조 시 의미 |
| :--- | :--- |
| `char *` | 1 byte 문자/정수 |
| `int *` | `int` 크기 정수 |
| `double *` | `double` 크기 실수 |
| `struct T *` | 구조체 `T` 객체 |

### 9.2 Call by Value와 Call by Address

`[9-3]`은 함수에 값을 넘기는 방식과 주소를 넘기는 방식을 비교한다. C 함수의 parameter 전달은 기본적으로 값 복사다. 원본 변수를 바꾸려면 그 변수의 주소를 넘겨야 한다.

```c
void swap(int *a, int *b)
{
    int t = *a;
    *a = *b;
    *b = t;
}
```

함수 내부에서 `*a`, `*b`를 수정하면 호출자가 가진 실제 변수 값이 바뀐다.

### 9.3 문자열과 pointer

`[9-4]`, `[9-5]`는 `%s`와 문자열의 정체를 다룬다. `%s`는 문자열 시작 주소를 받아 `'\0'`을 만날 때까지 출력한다.

```c
char s[] = "ABCD";
printf("%s\n", s);
```

문자열은 문자 배열과 null character의 조합이다. `s[0]`부터 순서대로 문자를 읽다가 `'\0'`을 만나면 문자열이 끝났다고 판단한다.

### 9.4 pointer 연산과 배열식

`[9-6-1]`은 `*p++`, `*++p`의 차이를 확인한다.

| 표현 | 의미 |
| :--- | :--- |
| `*p++` | 현재 `p`가 가리키는 값을 사용한 뒤 `p` 증가 |
| `*++p` | 먼저 `p`를 증가한 뒤 그 위치의 값 사용 |
| `(*p)++` | `p`가 가리키는 값을 증가 |

`[9-6-2]`, `[9-9]`, `[9-10]`은 배열식과 pointer식의 관계를 다룬다.

```c
a[i] == *(a + i)
```

배열 이름은 많은 식에서 첫 요소의 주소처럼 변환된다. 따라서 함수에 배열을 전달하면 실제 배열 전체가 복사되는 것이 아니라 시작 주소가 전달된다.

### 9.5 함수와 배열

`[9-8]`, `[9-11]`은 배열을 parameter로 받는 함수를 다룬다.

```c
int sum_array(int *a, int n)
{
    int i;
    int sum = 0;

    for (i = 0; i < n; i++)
    {
        sum += a[i];
    }

    return sum;
}
```

함수 parameter에서 `int a[]`와 `int *a`는 같은 의미로 취급된다. 배열 길이는 자동으로 전달되지 않으므로 길이 `n`을 따로 넘겨야 한다.

`[9-12]`는 지역 배열을 return하면 안 된다는 점을 다룬다. 지역 배열은 함수가 끝나면 수명이 끝나므로, 그 주소를 return하면 유효하지 않은 memory를 가리킬 수 있다.

### 9.6 구조체 pointer

`[9-15]`부터 `[9-18]`은 구조체와 pointer를 연결한다.

```c
typedef struct
{
    int id;
    int score;
} Student;

void update(Student *p)
{
    p->score = 100;
}
```

`p->score`는 `(*p).score`의 축약이다. 구조체를 함수에 값으로 넘기면 전체 구조체가 복사되지만, 구조체 pointer를 넘기면 원본 구조체를 수정할 수 있다. 큰 구조체는 pointer로 넘기는 편이 복사 비용도 줄일 수 있다.

## 확장 세부 메모

이 영역은 7장 이후를 날짜 노트로 병합할 때 누락하기 쉬운 세부 설명을 보관한다.

### 유도형 타입

C에서 기본 타입을 조합해 새 의미를 만드는 타입으로 `struct`, `union`, `enum`을 함께 본다.

| 분류 | 한국어 | 역할 | 예 |
| :--- | :--- | :--- | :--- |
| `struct` | 구조체 | 여러 member를 한 묶음으로 저장 | 학생 정보, 좌표 |
| `union` | 공용체 | 여러 member가 같은 memory 공간 공유 | 같은 byte를 여러 타입으로 해석 |
| `enum` | 열거형 | 이름 있는 정수 constant 집합 | 상태, 메뉴, 색상 |

`struct`는 member마다 별도 저장 공간을 가진다.

```c
struct Student
{
    int id;
    double score;
    char grade;
};

struct Student s1;
s1.id = 1;
s1.score = 95.5;
s1.grade = 'A';
```

`union`은 member들이 같은 memory를 공유한다. 한 member에 쓴 뒤 다른 member로 읽으면 같은 bit pattern을 다른 타입으로 해석한다.

```c
union Data
{
    int i;
    float f;
    unsigned char byte[4];
};
```

`enum`은 숫자 대신 의미 있는 이름으로 상태를 표현한다.

```c
enum State
{
    IDLE,
    RUN,
    STOP
};
```

기본적으로 첫 값은 0이고 뒤 값은 1씩 증가한다. 필요하면 값을 직접 지정할 수 있다.

### `typedef` 읽는 법

`typedef`는 기존 타입에 새 이름을 붙인다.

```c
typedef existing_type new_type_name;
```

```c
typedef unsigned int UINT;
UINT count = 10;
```

구조체와 함께 쓰면 `struct Student`를 반복해서 쓰지 않아도 된다.

```c
typedef struct Student
{
    int id;
    double score;
} Student;
```

마지막 `Student`는 변수명이 아니라 새 타입명이다. 이후 `Student s1;`은 `struct Student s1;`과 같은 의미로 읽는다.

### 진법, 표준 library, `while`

8번 단원은 숫자 표현과 표준 library 함수, 반복문 변형을 함께 다룬다.

| 표현 | 의미 |
| :--- | :--- |
| `0b1111` | 2진수 literal, compiler 지원 여부 확인 필요 |
| `017` | 8진수 literal |
| `0xf` | 16진수 literal |
| `%o` | 8진수 출력 |
| `%x`, `%X` | 16진수 출력 |

문자 분류나 변환은 `ctype.h` 계열 함수와 연결된다. 예를 들어 알파벳 여부, 숫자 여부, 대소문자 변환 같은 처리는 ASCII 숫자 계산으로 직접 할 수도 있지만, 표준 함수가 있으면 그 함수를 우선 검토한다.

`while`은 조건이 참인 동안 반복한다.

```c
while (condition)
{
    statement;
}
```

`do ~ while`은 body를 먼저 실행하고 조건을 검사하므로 최소 1회 실행이 필요할 때 사용한다.

```c
do
{
    statement;
} while (condition);
```

### 배열 memory와 pointer type

배열은 memory에서 연속된 공간에 저장된다. `int a[4]`에서 `int`가 4 byte라면 각 원소는 4 byte 간격으로 이어진다.

```c
int a[4] = {10, 20, 30, 40};
```

`&a[0]`와 `&a`는 출력되는 주소값은 같아 보일 수 있지만 타입이 다르다.

| 표현 | 의미 | type |
| :--- | :--- | :--- |
| `a` | 대부분의 식에서 첫 원소 주소처럼 변환 | `int *`처럼 사용 |
| `&a[0]` | 첫 원소의 주소 | `int *` |
| `&a` | 배열 전체의 주소 | `int (*)[4]` |
| `sizeof(a)` | 배열 전체 크기 | `4 * sizeof(int)` |

주소값이 같아도 pointer 연산에서 증가 단위가 달라진다. `&a[0] + 1`은 다음 `int` 원소 주소이고, `&a + 1`은 배열 전체 하나를 건너뛴 주소다.

### 이차원 배열과 transpose

C의 이차원 배열은 row-major order로 저장된다. `a[row][col]`처럼 보이지만 memory에는 한 행이 먼저 연속으로 놓이고 다음 행이 이어진다.

행의 합을 구할 때는 row를 고정하고 col을 이동한다.

```c
for (row = 0; row < ROW; row++)
{
    sum = 0;
    for (col = 0; col < COL; col++)
    {
        sum += a[row][col];
    }
}
```

열의 합을 구할 때는 col을 고정하고 row를 이동한다. 행/열 문제는 안쪽 loop와 바깥 loop가 각각 무엇을 의미하는지 분명히 잡는 것이 핵심이다.

transpose는 행과 열을 바꾸는 작업이다.

```c
t[col][row] = a[row][col];
```

`M x N` 배열을 transpose하면 `N x M` 배열이 된다. 행과 열 수가 다른 배열은 같은 배열 안에서 바로 바꾸기보다 결과 배열을 따로 두는 방식이 안전하다.

### 구조체 member와 복사

구조체 member의 타입은 member 자신의 선언 타입이다.

```c
typedef struct Example
{
    int a;
    char b[10];
} Example;
```

| 표현 | type | 의미 |
| :--- | :--- | :--- |
| `x.a` | `int` | 정수 member |
| `x.b` | `char[10]` | 배열 member |
| `x.b[0]` | `char` | 배열 member의 첫 원소 |

배열 member는 일반 배열처럼 `x.b = "abc";` 형태의 대입이 불가능하다. 문자열 복사는 `strcpy()`나 `memcpy()`를 사용한다.

```c
strcpy(dest, src);
memcpy(dest, src, count);
```

`strcpy()`는 source에서 `'\0'`을 만날 때까지 복사하고, 마지막 null character까지 destination에 넣는다. `memcpy()`는 문자열 종료를 해석하지 않고 지정한 byte 수만큼 그대로 복사한다.

### 공용체와 endian

`union`은 같은 memory를 여러 타입으로 해석할 수 있게 한다.

| 구분 | `struct` | `union` |
| :--- | :--- | :--- |
| 저장 공간 | member별 별도 공간 | 모든 member가 같은 공간 공유 |
| 동시에 유효한 값 | 여러 member 값 보관 | 마지막으로 쓴 해석 중심 |
| 활용 | record 구성 | byte 해석, register view, endian 확인 |

예를 들어 `0x12345678`을 정수로 저장한 뒤 byte 배열 member로 읽으면 현재 system의 endian을 확인할 수 있다. Little endian이면 낮은 주소에 `0x78`이 먼저 놓이고, Big endian이면 낮은 주소에 `0x12`가 먼저 놓인다.

byte 순서를 바꾸는 함수는 공용체를 이용해 정수와 byte 배열 view를 함께 사용할 수 있다.

```c
typedef union
{
    unsigned int data;
    unsigned char byte[4];
} U32;
```

`0x12345678`의 byte 순서를 뒤집으면 `0x78563412` 형태가 된다.

### pointer를 memory를 보는 창으로 이해하기

pointer는 주소를 저장하는 변수다. pointer 변수 자체의 크기는 실행 환경에 따라 32-bit에서는 보통 4 byte, 64-bit에서는 보통 8 byte다. 가리키는 대상 타입은 pointer 변수의 크기보다 `*p`로 읽을 때의 해석 방식과 `p + 1` 이동 단위를 결정한다.

| pointer type | 대상 타입 | `p + 1` 이동 |
| :--- | :--- | :--- |
| `char *p` | `char` | `sizeof(char)` |
| `int *p` | `int` | `sizeof(int)` |
| `double *p` | `double` | `sizeof(double)` |
| `struct Student *p` | `struct Student` | `sizeof(struct Student)` |

수업에서의 망원경/window 비유로 보면, pointer type은 memory를 바라보는 창의 폭이다. 같은 주소라도 `char *`는 1 byte씩 보고, `int *`는 `int` 크기만큼 본다.

### `%s`, `%p`, 문자열 copy

`%s`는 문자열 시작 주소를 받아 `'\0'`을 만날 때까지 출력한다. 따라서 인자는 `char *` 또는 null-terminated `char` 배열의 시작 주소다.

`%p`는 주소를 출력할 때 사용한다. portable하게 출력하려면 `(void *)`로 cast하는 습관이 좋다.

문자열 copy는 pointer를 한 칸씩 이동시키며 null character까지 복사하는 방식으로 이해할 수 있다.

```c
while ((*d++ = *s++) != '\0')
{
}
```

이 식은 source가 가리키는 문자를 destination에 대입하고, 두 pointer를 다음 위치로 이동한다. 대입된 문자가 `'\0'`이면 반복을 끝낸다.

### 배열명과 함수 parameter

배열명은 많은 식에서 첫 원소 주소처럼 쓰이지만, 항상 pointer 변수와 같지는 않다.

| 상황 | 배열명 `a`의 해석 |
| :--- | :--- |
| `a[i]` | 첫 원소 주소 기반 access |
| `a + i` | pointer 산술 |
| `sizeof(a)` | 배열 전체 크기 |
| `&a` | 배열 전체의 주소 |

배열 access 공식은 다음과 같다.

```c
a[i] == *(a + i)
```

함수에 배열을 넘기면 배열 전체가 복사되지 않고 시작 주소가 전달된다. 배열 길이는 자동으로 전달되지 않으므로 size 정보를 함께 넘긴다.

```c
int sum_array(int *a, int size);
```

이차원 배열을 함수에 넘길 때는 열 크기를 알려 주어야 한다.

```c
void print_matrix(int a[][4], int row);
```

### 함수의 배열 return

함수 내부 지역 배열은 함수가 끝나면 수명이 끝나므로 그 주소를 return하면 안 된다.

```c
int *make_array(void)
{
    int a[4] = {1, 2, 3, 4};
    return a; // 잘못된 방식
}
```

배열 결과가 필요할 때는 호출자가 준비한 배열을 parameter로 넘겨 채우는 방식이 안전하다.

```c
void make_array(int *out, int size)
{
    for (int i = 0; i < size; i++)
    {
        out[i] = i;
    }
}
```

`static` 지역 배열을 return하는 방법도 가능하지만, 하나의 공유 저장 공간을 계속 재사용하므로 호출 간 상태 공유를 주의해야 한다.

### 대치법과 pointer 대상

대치법은 서로 같은 의미로 읽을 수 있는 식을 바꿔 생각하는 방법이다.

| 상황 | 대치 |
| :--- | :--- |
| 배열 원소 | `a[i]`와 `*(a + i)` |
| 구조체 pointer | `p->member`와 `(*p).member` |
| 함수 인자 | `x`가 값으로 복사됨 |
| 주소 인자 | `&x`를 넘겨 원본 접근 가능 |

다만 `sizeof(a)`와 `sizeof(p)`, `&a`와 `&p`처럼 배열 자체와 pointer 변수 자체를 다루는 경우에는 단순 대치하면 안 된다.

pointer의 내용을 access하면 결과는 pointer가 가리키는 대상이다. `int *p`에서 `*p`는 `int`이고, `int (*pa)[4]`에서 `*pa`는 `int[4]` 배열이다.

### 구조체 pointer와 함수 전달

구조체 pointer는 구조체 변수의 주소를 저장한다.

```c
typedef struct Student
{
    int id;
    int score;
} Student;

void set_score(Student *p, int score)
{
    p->score = score;
}
```

`->`는 구조체 pointer가 가리키는 구조체의 member에 접근하는 연산자다.

```c
p->score == (*p).score
```

구조체를 함수에 값으로 넘기면 전체 구조체가 복사된다. 구조체 pointer를 넘기면 함수 안에서 원본을 수정할 수 있고, 큰 구조체를 복사하는 비용도 줄일 수 있다.

## 정리된 확인 포인트

- `break`가 가장 안쪽의 `for`, `switch`, `while`, `do ~ while`만 탈출한다는 점
- `continue`가 현재 반복 회차만 건너뛴다는 점
- `goto`가 함수 내 label로 분기한다는 점
- 문자열 literal 배열에는 마지막 `'\0'`이 자동으로 붙는다는 점
- 유도형 타입 `struct`, `union`, `enum`의 차이
- `typedef existing_type new_type_name;` 형식
- 배열 memory가 연속 공간이며 `&a[0]`와 `&a`는 주소값은 같아도 pointer type이 다르다는 점
- 이차원 배열에서 row/col loop 방향
- `union`은 member들이 동일 memory 공간을 공유한다는 점
- endian 변환에서 정수와 byte 배열을 함께 해석하는 흐름
- pointer type에 따라 `p + 1`의 이동 단위가 달라지는 이유
- `%s`는 문자열 시작 주소, `%p`는 주소 출력 format이라는 점
- `while ((*d++ = *s++) != '\0')` 문자열 복사 흐름
- 배열명은 일반 식에서 첫 원소 주소처럼 쓰이고, `sizeof`와 `&`에서는 배열 타입으로 쓰인다는 점
- 배열 access 공식 `a[i] == *(a + i)`
- 함수에 배열을 전달할 때 시작 주소와 size 정보를 함께 넘기는 이유
- 함수에서 지역 배열 주소를 return하면 안 되는 이유
- 구조체 pointer의 `->` 접근과 구조체 함수 전달 방식

## 날짜 노트 반영 기준

| 반영 위치 | 내용 |
| :--- | :--- |
| `260702-c-control-flow-arrays-structs.md` | 조건문, 반복문, 배열, 문자열, 구조체 본문 |
| `260703-c-number-system-conversion.md` | 진법 변환, 8진수/16진수 표현, 포인터 기본, endian, `union` 본문 |
| `260701-c-lab-basics-source-outline.md` | C Lab 1~4장 본문 |
| [260702 Python 실습자료 후속 범위 정리](260702-python-lab-source-outline.md) | Python 실습자료 본문 후보 |
| [260702 M4 ARM Lab 예제 정리](260702-m4-arm-lab-source-outline.md) | M4/ARM 실습자료 본문 후보 |
