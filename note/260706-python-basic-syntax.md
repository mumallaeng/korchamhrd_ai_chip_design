# 26-07-06 - Python 1장 기본 문법, 입력, 문자열 포맷

관련 노트:

- [kdt-c-python-m4-ai-course-outline.md](kdt-c-python-m4-ai-course-outline.md)
- [260703-c-number-system-conversion.md](260703-c-number-system-conversion.md)

## 수업 흐름

0706 수업은 Python 실습자료의 1장 범위만 진행했다. C언어 수업에서 다뤘던 변수, 입력, 연산, 문자열, 출력 형식을 Python 문법으로 다시 확인하는 단계다. 2장 `Object와 Name Binding`은 다음 수업 범위로 넘긴다.

| 구분 | 내용 |
| :--- | :--- |
| 진행 범위 | Python 1장 기본 문법 |
| 원본 파일 | [Py_Lab_for_VS_Code.py](<Google Drive/My Drive/Classroom/대한상공회의소_반도체설계/담당강사-C_and_Python/상공회의소_KDT_실습자료(C_Python_M4)/2.Python/Py_Lab_for_VS_Code.py>) |
| 예제 범위 | `[1-1]`부터 `[1-24]`까지 |
| 다음 범위 | 2장 `Object와 Name Binding` |

## 실습 자료와 진행 범위

Python 1장은 `print()`, 주석, 들여쓰기, numeric literal, 변수, `type()`, 산술 연산, 문자열 escape, type 생성자, 입력, `split()`, `format()`, f-string을 순서대로 확인한다. 이 날짜의 범위에서는 문법 사용법을 먼저 잡고, object/name binding의 내부 동작은 [260707-python-object-name-binding-container-operations.md](260707-python-object-name-binding-container-operations.md)에서 이어서 정리한다.

| 예제 | 파일 내 주제 | 노트 연결 |
| :--- | :--- | :--- |
| `[1-1]` | Hello Python | `print()` 기본 출력 |
| `[1-2]` | 파이썬의 주석 | 주석과 실행 제외 |
| `[1-3]` | 들여쓰기 | Python block 구조 |
| `[1-4]` | `print` 함수 옵션 | `sep`, `end`, 빈 줄 출력 |
| `[1-5]` | 정수형 `int` 상수 | 큰 정수, `0b`, `0o`, `0x`, `bool` 비교 |
| `[1-6]` | 실수형 `float` 상수 | 소수, 지수 표기 `e`/`E` |
| `[1-7]` | 변수 | 이름 규칙, 재대입, 대소문자 구분 |
| `[1-8]` | 변수의 타입 | 동적 타입 결정, `type()` 확인 |
| `[1-9]` | 기본 산술 연산자 | `**`, `+`, `-`, `*`, `/`, `//`, `%`, 우선순위 |
| `[1-10]` | 자리수 분리 | 몫과 나머지 연산 활용 |
| `[1-11]` | 문자열 상수 | escape sequence, raw string |
| `[1-12]` | 디렉토리 형식 문자열 인쇄 | Windows 경로와 backslash escape |
| `[1-13]` | 타입명 | `int` 이름의 class 성격, `type(int)` |
| `[1-14]` | 데이터 타입 변환 | 전달값 기반 type instance 생성 |
| `[1-15]` | 문자열 정수 연산 | 문자열 연결과 숫자 연산 구분 |
| `[1-16]` | 제품 판매가격 계산 | 문자열 입력값을 numeric type으로 구성 후 계산 |
| `[1-17]` | 키보드 입력과 타입 변환 | `input()`, `int(input())`, `float(input())` |
| `[1-18]` | 두 정수 입력 합 | 입력값을 `int`로 구성 후 연산 |
| `[1-19]` | `split()` 이름 3개 입력 | 공백 기준 문자열 분리와 unpack |
| `[1-20]` | 쉼표 기준 정수 입력 | `split(sep=",")`, 각 항목 type 구성 |
| `[1-21]` | 정수 3개 합계 | 입력, 분리, type 구성, 합산 |
| `[1-22]` | `format()` 메서드 | `{}`, `{0}`, `{a}` replacement field |
| `[1-23]` | format 형식 지정 | 폭, 정렬, 채움, 소수점, `%`, `,` |
| `[1-24]` | f-prefix 출력 | f-string, expression, format specifier |

## 핵심 개념

### `print()` 함수의 사용

공식 Python 문서 기준 `print()`의 기본 형태는 다음과 같다.

```python
print(*objects, sep=' ', end='\n', file=None, flush=False)
```

`print()`는 여러 값을 한 번에 받을 수 있다. 이때 keyword가 아닌 인자들은 출력 대상이 되고, 각 값은 `str()`로 변환되는 방식과 유사하게 문자열로 바뀐 뒤 출력된다.

```python
print("ㅁ1", "ㅁ2", "문자열3")
```

기본값에서는 출력 대상 사이에 공백 한 칸이 들어가고, 마지막에는 줄바꿈이 붙는다.

```text
ㅁ1 ㅁ2 문자열3
```

`sep`는 출력 대상 사이에 넣을 구분 문자열이다. 기본값은 공백 한 칸인 `' '`이다.

```python
print("ㅁ1", "ㅁ2", "문자열3", sep=", ")
```

```text
ㅁ1, ㅁ2, 문자열3
```

`end`는 모든 출력 대상과 `sep` 처리가 끝난 뒤, 줄 끝에 붙일 문자열이다. 기본값은 newline인 `'\n'`이므로 `print()`를 한 번 호출할 때마다 다음 줄로 넘어간다.

```python
print("A", end="")
print("B")
```

```text
AB
```

`sep`와 `end`는 출력 대상이 아니라 keyword argument다. 따라서 여러 값을 출력한 뒤 뒤쪽에 `sep=...`, `end=...` 형태로 지정한다.

| 인자 | 기본값 | 의미 |
| :--- | :--- | :--- |
| `*objects` | 없음 | 출력할 값들 |
| `sep` | `' '` | 여러 출력 대상 사이의 구분 문자열 |
| `end` | `'\n'` | 출력 끝에 붙는 문자열 |
| `file` | `None` | 출력할 text stream, 기본은 `sys.stdout` |
| `flush` | `False` | `True`면 stream을 강제로 flush |

`sep`와 `end`는 문자열이어야 하며, `None`을 주면 기본값을 사용하는 의미로 처리된다. 출력할 값이 없으면 `print()`는 `end`만 출력하므로, 기본 상태에서는 빈 줄 하나를 만든다.

### Numeric 상수와 진법 표기

Python의 numeric type은 크게 `int`, `float`, `complex`로 나뉘고, `bool`은 `int`의 subtype이다. 수업 초반에는 정수형 `int`, 논리형 `bool`, 실수형 `float`의 지수 표기를 먼저 구분해서 보면 된다.

`int`는 정수를 표현하는 type이다. Python의 `int`는 C의 `int`처럼 32bit 또는 64bit 범위로 고정되지 않고, 사용 가능한 memory가 허용하는 범위 안에서 매우 큰 정수도 표현할 수 있다.

```python
10
123456789012345678901234567890
```

정수 literal은 기본적으로 10진수로 해석된다. 다른 진법은 접두사로 구분한다.

| 표기 | 진법 | 예 | 10진수 값 |
| :--- | :--- | :--- | ---: |
| 접두사 없음 | 10진수 | `123` | 123 |
| `0b` 또는 `0B` | 2진수 | `0b1010` | 10 |
| `0o` 또는 `0O` | 8진수 | `0o12` | 10 |
| `0x` 또는 `0X` | 16진수 | `0x0A` | 10 |

16진수에서 `10`부터 `15`까지는 `A`~`F` 또는 `a`~`f`로 표현한다. 숫자 literal 안에는 가독성을 위해 `_`를 넣을 수 있지만, 숫자 사이 또는 허용된 위치에만 사용할 수 있다.

```python
1_000_000
0b_1010
0x_FF
```

Python 3에서는 `0123`처럼 10진수 정수 앞에 의미 없는 `0`을 붙이는 표기는 허용되지 않는다. 8진수를 쓰려면 `0o123`처럼 `0o` 접두사를 사용한다.

`bool`은 참과 거짓을 나타내는 type이며 가능한 값은 `True`, `False` 두 개다. Python에서는 첫 글자를 대문자로 써야 하고, `true`, `false`는 boolean literal이 아니다.

```python
True
False
```

`bool`은 `int`의 subtype이므로 산술 문맥에서는 `True`가 `1`, `False`가 `0`처럼 동작할 수 있다. 다만 의미상 참/거짓 상태를 표현할 때는 숫자 `1`, `0` 대신 `True`, `False`를 쓰는 편이 명확하다.

```python
print(True == 1)    # True
print(False == 0)   # True
```

숫자에서 `E` 또는 `e`는 지수 표기를 의미한다. 이는 정수 literal이 아니라 `float` literal 문법에 해당한다. `1e3`은 `1 * 10^3`을 뜻하므로 `1000.0`으로 해석되고, `1.5e-2`는 `1.5 * 10^-2`를 뜻하므로 `0.015`가 된다.

```python
print(1e3)      # 1000.0
print(1.5e-2)   # 0.015
```

| 표기 | 의미 | 값 |
| :--- | :--- | :--- |
| `1e3` | `1 * 10^3` | `1000.0` |
| `1.0E3` | `1.0 * 10^3` | `1000.0` |
| `1.5e-2` | `1.5 * 10^-2` | `0.015` |

`e`나 `E`는 16진수의 `E` digit와 문맥이 다르다. `0xE`는 16진수 정수 `14`이고, `1e3`은 float 지수 표기다.

### 변수 이름과 식별자 규칙

Python에서 변수 이름은 identifier 또는 name 규칙을 따른다. 변수 이름에는 영문 대문자/소문자, `_`, 숫자, 그리고 유효한 non-ASCII 문자를 사용할 수 있다. 한글도 유효한 문자 범주에 속하므로 변수 이름으로 사용할 수 있다.

```python
name = "kim"
student_count = 30
학생수 = 30
score2 = 100
```

다만 숫자는 첫 글자로 올 수 없다. 숫자로 시작하면 이름이 아니라 numeric literal로 먼저 해석되기 때문에 syntax error가 된다.

```python
score2 = 100   # 가능
2score = 100   # 불가능
```

Python은 대소문자를 엄격하게 구분한다. 따라서 `score`, `Score`, `SCORE`는 서로 다른 이름이다.

```python
score = 10
Score = 20
SCORE = 30
```

Python keyword는 일반 변수 이름으로 사용할 수 없다. 예를 들어 `if`, `for`, `while`, `def`, `class`, `return`, `True`, `False`, `None` 같은 이름은 언어 문법에서 예약된 단어다.

```python
class = 10   # 불가능
if = 1       # 불가능
```

Python 3.10 이후에는 특정 문맥에서만 예약어처럼 동작하는 soft keyword도 있다. 예를 들어 `match`, `case`, `_`는 `match` 문 안에서 특별한 의미를 가질 수 있고, Python 3.12 이후 `type`도 특정 `type` 문맥에서 soft keyword로 동작한다. 일반 변수 이름으로 쓸 수 있는 경우가 있더라도 혼동을 줄이려면 수업 초반에는 피하는 편이 좋다.

| 규칙 | 예 | 가능 여부 |
| :--- | :--- | :--- |
| 영문자로 시작 | `count` | 가능 |
| `_`로 시작 | `_count` | 가능 |
| 한글 사용 | `학생수` | 가능 |
| 숫자 포함 | `score2` | 가능 |
| 숫자로 시작 | `2score` | 불가능 |
| Python keyword 사용 | `for`, `class` | 불가능 |
| 대소문자 차이 | `score`, `Score` | 서로 다른 이름 |

`_`는 underscore 또는 underbar라고 부르며 변수 이름에 사용할 수 있다. Python에서는 단어 사이를 구분할 때 `student_count`처럼 `_`를 쓰는 snake_case 형태를 자주 사용한다.

### 변수의 동적 타입 결정과 `type()`

Python에서는 C처럼 변수 선언 시 type을 고정하지 않는다. 엄밀히 말하면 Python의 변수 이름은 어떤 object를 가리키는 name이고, object가 자신의 type을 가진다. 대입문은 오른쪽 expression을 먼저 평가한 뒤, 그 결과 object를 왼쪽 이름에 binding한다.

```python
a = 10
print(type(a))   # <class 'int'>

a = 3.14
print(type(a))   # <class 'float'>

a = "hello"
print(type(a))   # <class 'str'>
```

위 예시에서 `a`라는 이름은 처음에는 `int` object를 가리키고, 다음에는 `float` object, 마지막에는 `str` object를 가리킨다. 따라서 '우변의 값 type에 따라 변수의 type이 결정된다'는 표현은 실습 단계의 간단한 설명이고, 더 정확히는 변수 이름이 새 object에 다시 binding되며 `type(a)`는 현재 `a`가 가리키는 object의 type을 확인한다.

이 차이가 중요한 이유는 이름 `a`가 타입을 소유하는 것이 아니라 object reference를 소유하기 때문이다. `a = 10` 다음에 `a = "hello"`를 실행하면 정수 object가 문자열 object로 변형되는 것이 아니라, name `a`의 binding 대상이 바뀐다. 같은 object를 여러 이름이 함께 가리키는 경우나, list처럼 mutable object 내부를 수정하는 경우는 2장 name binding 모델에서 다시 다룬다.

| 대입문 | 오른쪽 object | `type(a)` 결과 |
| :--- | :--- | :--- |
| `a = 10` | 정수 object | `<class 'int'>` |
| `a = 3.14` | 실수 object | `<class 'float'>` |
| `a = "hello"` | 문자열 object | `<class 'str'>` |
| `a = True` | 논리 object | `<class 'bool'>` |

`type()`은 built-in 함수다. 객체 type 확인 용도로 사용할 때는 인자 하나만 넣는다.

```python
type(10)
type(3.14)
type("hello")
```

여러 객체의 type을 한 번에 확인하려고 `type(a, b)`처럼 쓰는 것은 올바른 사용이 아니다. 여러 값을 확인하려면 각각 호출하거나 container와 반복을 사용한다.

```python
a = 10
b = "hello"

print(type(a), type(b))
```

공식 문서에는 `type(object)` 한 인자 형태와 `type(name, bases, dict, **kwargs)` 세 인자 형태가 함께 나온다. 한 인자 형태는 object의 type 확인이고, 세 인자 형태는 class를 동적으로 만드는 고급 문법이다. 수업 초반의 type 확인에서는 `type(x)`만 사용한다고 구분해두면 된다.

Python에서 한 번 생성된 이름에 새 type의 값을 다시 대입하면, 그 이름이 가리키는 object가 바뀌므로 `type()` 결과도 바뀐다. 이는 Python의 동적 타이핑 특징이다.

### Python 연산 종류와 우선순위

Python expression은 여러 연산자가 함께 있을 때 우선순위가 높은 연산부터 묶인다. 아래 표는 공식 문서의 operator precedence 표를 수업용으로 세분화했다. 숫자가 작을수록 우선순위가 높다.

| 우선순위 | 연산 종류 | 연산자/형식 | 예 | 메모 |
| :---: | :--- | :--- | :--- | :--- |
| 1 | 괄호 묶음 | `(expression)` | `(a + b) * c` | 우선 계산 강제 |
| 1 | 튜플/표현식 묶음 | `(a, b)` | `(1, 2)` | comma로 tuple 구성 |
| 1 | 리스트 display | `[a, b]` | `[1, 2, 3]` | list 생성 |
| 1 | 딕셔너리 display | `{key: value}` | `{"a": 1}` | dict 생성 |
| 1 | 집합 display | `{a, b}` | `{1, 2}` | set 생성 |
| 2 | 인덱싱 | `x[index]` | `nums[0]` | subscription |
| 2 | 슬라이싱 | `x[start:end]` | `nums[1:3]` | slicing |
| 2 | 함수 호출 | `x(arguments...)` | `print(a)` | call |
| 2 | 속성 접근 | `x.attribute` | `obj.name` | attribute reference |
| 3 | await expression | `await x` | `await coro()` | async 코드 |
| 4 | 거듭제곱 | `**` | `2 ** 3` | 오른쪽 결합 |
| 5 | 단항 plus | `+x` | `+a` | numeric unary |
| 5 | 단항 minus | `-x` | `-a` | 부호 반전 |
| 5 | bitwise NOT | `~x` | `~mask` | 비트 반전 |
| 6 | 곱셈 | `*` | `a * b` | 산술 곱셈 |
| 6 | 행렬 곱셈 | `@` | `A @ B` | matrix multiplication |
| 6 | 나눗셈 | `/` | `a / b` | true division |
| 6 | 몫 나눗셈 | `//` | `a // b` | floor division |
| 6 | 나머지 | `%` | `a % b` | modulo, 문자열 formatting에도 사용 |
| 7 | 덧셈 | `+` | `a + b` | 숫자 덧셈, sequence 연결 |
| 7 | 뺄셈 | `-` | `a - b` | 산술 뺄셈 |
| 8 | 왼쪽 shift | `<<` | `x << 1` | bit shift |
| 8 | 오른쪽 shift | `>>` | `x >> 1` | bit shift |
| 9 | bitwise AND | `&` | `a & b` | 비트 단위 AND |
| 10 | bitwise XOR | `^` | `a ^ b` | 비트 단위 XOR |
| 11 | bitwise OR | `\|` | `a \| b` | 비트 단위 OR |
| 12 | 크기 비교 | `<`, `<=`, `>`, `>=` | `a < b` | comparison |
| 12 | 같음 비교 | `==`, `!=` | `a == b` | value comparison |
| 12 | membership test | `in`, `not in` | `x in data` | 포함 여부 |
| 12 | identity test | `is`, `is not` | `x is None` | object identity |
| 13 | Boolean NOT | `not x` | `not done` | 논리 부정 |
| 14 | Boolean AND | `and` | `a and b` | 둘 다 참 |
| 15 | Boolean OR | `or` | `a or b` | 하나 이상 참 |
| 16 | 조건 expression | `x if condition else y` | `a if ok else b` | 오른쪽 결합 |
| 17 | lambda expression | `lambda` | `lambda x: x + 1` | 익명 함수 |
| 18 | assignment expression | `:=` | `(n := len(data))` | walrus operator |

같은 우선순위에 있는 연산자는 대부분 왼쪽에서 오른쪽으로 묶인다. 예외적으로 `**`와 조건 expression은 오른쪽에서 왼쪽으로 묶인다.

```python
print(2 + 3 * 4)      # 14, 곱셈 먼저
print((2 + 3) * 4)    # 20, 괄호 먼저
print(2 ** 3 ** 2)    # 512, 2 ** (3 ** 2)
print(2 ** -1)        # 0.5, 오른쪽 단항 minus가 먼저 묶임
```

비교 연산, membership test, identity test는 같은 우선순위를 가지며 chaining이 가능하다.

```python
print(1 < 2 < 3)      # True
print(x is not None)
print(item in items)
```

주의할 점은 `=` 대입은 expression 연산자가 아니라 assignment statement라는 점이다. 대입문에서는 오른쪽 expression이 먼저 평가된 뒤 왼쪽 target에 binding된다. 반면 `:=`는 expression 안에서 값을 binding할 수 있는 assignment expression이다.

### Escape sequence

Python 3.14.6 기준으로 문자열 literal 안에서 backslash(`\`)는 escape sequence를 시작하는 문자다. `r` 또는 `R` prefix가 붙은 raw string이 아니라면 `\n`, `\t` 같은 조합은 실제 줄바꿈이나 tab 문자처럼 해석된다.

| Escape sequence | 의미 | 예 | 결과/용도 |
| :--- | :--- | :--- | :--- |
| `\n` | Linefeed, 줄바꿈 | `"A\nB"` | `A` 다음 줄에 `B` |
| `\t` | Horizontal tab | `"A\tB"` | `A`와 `B` 사이 tab |
| `\\` | backslash 문자 | `"C:\\temp"` | 경로 문자열에 `\` 포함 |
| `\'` | single quote | `'It\'s ok'` | 작은따옴표 포함 |
| `\"` | double quote | `"Say \"Hi\""` | 큰따옴표 포함 |
| `\r` | Carriage return | `"A\rB"` | 커서 행 시작 위치 이동 |
| `\b` | Backspace | `"AB\bC"` | 직전 문자 위치로 이동 |
| `\f` | Formfeed | `"A\fB"` | formfeed 제어 문자 |
| `\v` | Vertical tab | `"A\vB"` | vertical tab 제어 문자 |
| `\a` | Bell | `"\a"` | bell 제어 문자 |
| `\ooo` | 8진수 문자 | `"\120"` | `P` |
| `\xhh` | 16진수 문자 | `"\x50"` | `P`, hex digit 2개 필수 |
| `\N{name}` | Unicode 이름 문자 | `"\N{LATIN CAPITAL LETTER P}"` | `P` |
| `\uxxxx` | 16-bit Unicode escape | `"\u1234"` | 해당 Unicode 문자 |
| `\Uxxxxxxxx` | 32-bit Unicode escape | `"\U0001F40D"` | 해당 Unicode 문자 |
| backslash + 줄끝 | 줄 끝 무시 | 문자열 끝에 `\` 배치 | 문자열 안에 줄바꿈 미포함 |

가장 자주 쓰는 것은 `\n`, `\t`, `\\`, `\'`, `\"`다.

```python
print("Hello\nPython")
print("name\tage")
print("C:\\Program Files")
print('It\'s Python')
print("Say \"Hello\"")
```

`print()`에서 `\n`은 문자열 내부의 줄바꿈이다. `print()` 자체도 기본적으로 출력 끝에 newline을 붙이므로, 둘은 구분해서 봐야 한다.

```python
print("A\nB")

print("A", end="")
print("B")
```

첫 번째 예시는 문자열 내부의 `\n` 때문에 줄이 나뉜다. 두 번째 예시는 `print()`의 `end` 값을 빈 문자열로 바꾸었기 때문에 두 출력이 같은 줄에 이어진다.

Windows 경로처럼 backslash가 많이 나오는 문자열은 `\\`를 쓰거나 raw string을 사용할 수 있다.

```python
path1 = "C:\\Users\\student\\test.txt"
path2 = r"C:\Users\student\test.txt"
```

raw string은 backslash를 일반 문자처럼 다룬다. 그래서 정규표현식이나 Windows 경로를 적을 때 편하지만, raw string도 끝이 backslash 하나로 끝나는 형태는 사용할 수 없다.

```python
print(r"\n")     # backslash와 n 두 글자 출력
print("\n")      # 실제 줄바꿈
```

인식되지 않는 escape sequence는 Python 3.14.6 기준으로 문자열 안에 backslash가 남지만 `SyntaxWarning` 대상이다. 이후 Python 버전에서는 `SyntaxError`가 될 예정이므로, 의도한 escape sequence가 아니라면 raw string을 쓰거나 `\\`로 명확히 적는 것이 좋다.

```python
print("\q")      # 경고 대상
print(r"\q")     # raw string, 의도 명확
print("\\q")     # backslash 자체를 escape
```

bytes literal에서는 `\xhh`, `\ooo`, `\n`, `\t` 같은 byte 표현을 사용할 수 있다. 반면 `\N{name}`, `\uxxxx`, `\Uxxxxxxxx`은 문자열 전용 Unicode escape라 bytes literal에서는 인식되는 escape sequence가 아니다.

### 데이터 타입 변환과 생성자

Python에서 `int`, `float`, `str`, `bool`, `list`, `tuple`, `dict`, `set` 같은 이름은 단순한 변환 함수 이름이 아니라 built-in class 이름이다. class object는 호출 가능하므로 함수처럼 `int("123")` 형태로 쓰지만, 정확히는 전달받은 값을 바탕으로 해당 type의 instance를 생성하는 생성자 호출이다.

여기서 중요한 점은 기존 object 자체가 다른 type으로 바뀌는 것이 아니라는 점이다. 예를 들어 문자열 object `"123"`이 내부에서 `int` object로 변신하는 것이 아니라, `"123"`을 해석해서 새로운 `int` instance `123`을 만든다.

```python
a = int("123")
b = float("3.14")
c = str(100)
d = bool(0)
e = list("ABC")

print(type(a))  # <class 'int'>
print(type(b))  # <class 'float'>
print(type(c))  # <class 'str'>
print(type(d))  # <class 'bool'>
print(type(e))  # <class 'list'>
```

공식 문서에서도 `int`는 `class int(number=0, /)`와 `class int(string, /, base=10)` 형태로 설명된다. 따라서 수업에서 편의상 '형 변환 함수'라고 부를 수는 있지만, Python object model 기준으로는 'class 이름을 호출해서 전달받은 값으로 새 instance를 생성하는 것'이다.

```python
s = "123"
n = int(s)

print(s, type(s))  # 123 <class 'str'>
print(n, type(n))  # 123 <class 'int'>
```

위 예시에서 `s`가 가리키는 문자열 object는 그대로 `str`이다. `n`은 `int(s)` 호출 결과로 새로 만들어진 `int` instance를 가리킨다.

변환하려는 type과 같은 type의 값이 이미 전달되면, 값의 의미는 바뀌지 않는다. 예를 들어 `int(10)`은 이미 `int`인 값 `10`을 `int`로 다시 구성하려는 것이므로 출력 결과도 `10`이다. 이 경우 수업 초반에는 '같은 type이면 변환될 내용이 없어서 그대로 나온다'고 이해하면 된다.

```python
print(int(10))          # 10
print(float(3.14))      # 3.14
print(str("Python"))    # Python
```

다만 여기서 '그대로'는 먼저 값 관점에서 이해해야 한다. 기존 object 자체가 항상 같은 object로 재사용된다는 뜻은 아니다. `int`, `float`, `str`, `tuple` 같은 immutable type에서는 같은 object가 재사용될 수 있지만, `list`, `dict`, `set` 같은 mutable container 생성자는 같은 type을 전달받아도 새 container를 만들 수 있다.

```python
nums = [1, 2, 3]
copied = list(nums)

print(nums)             # [1, 2, 3]
print(copied)           # [1, 2, 3]
print(nums is copied)   # False
```

따라서 생성자 호출의 핵심은 '입력값을 해당 type의 instance로 구성'하는 동작이다. 값이 이미 같은 type이면 출력 결과는 같아 보일 수 있지만, object 재사용 여부는 type의 구현과 성격에 따라 달라진다.

| 표현 | 정확한 관점 | 결과 예 |
| :--- | :--- | :--- |
| `int("123")` | 전달값 기반 `int` instance 생성 | `123` |
| `float("3.14")` | 전달값 기반 `float` instance 생성 | `3.14` |
| `str(100)` | 전달값 기반 `str` instance 생성 | `"100"` |
| `bool(0)` | 전달값 기반 `bool` instance 생성 | `False` |
| `list("ABC")` | 전달값 기반 `list` instance 생성 | `["A", "B", "C"]` |
| `tuple([1, 2])` | 전달값 기반 `tuple` instance 생성 | `(1, 2)` |
| `dict([("a", 1)])` | 전달값 기반 `dict` instance 생성 | `{"a": 1}` |
| `set([1, 1, 2])` | 전달값 기반 `set` instance 생성 | `{1, 2}` |

class 이름 자체도 object다. `type(int)`를 확인하면 `int`라는 이름이 function이 아니라 class object임을 확인할 수 있다.

```python
print(type(int))       # <class 'type'>
print(callable(int))   # True
print(isinstance(10, int))
```

`callable(int)`가 `True`인 이유는 class object가 호출 가능하기 때문이다. class를 호출하면 일반적으로 새 instance를 만드는 factory처럼 동작한다.

사용자가 직접 만든 class도 같은 방식으로 동작한다.

```python
class Student:
    pass

s = Student()
print(type(s))         # <class '__main__.Student'>
```

즉, `Student()`가 함수를 호출하는 것처럼 보이지만 실제로는 `Student` class를 호출해 `Student` instance를 생성하는 동작이다. `int("123")`도 같은 관점에서 이해하면 된다.

형 변환처럼 사용하는 생성자는 입력값이 해당 type으로 구성될 수 있을 때만 성공한다.

```python
print(int("123"))      # 123
print(int("FACE", 16)) # 64206

# int("abc")           # ValueError
```

주의할 점은 생성자가 입력 문자열의 의미를 항상 사람의 의도대로 해석하는 것은 아니라는 점이다. 예를 들어 `bool("False")`는 문자열 내용이 `False`라는 뜻이 아니라, 비어 있지 않은 문자열이므로 `True`가 된다.

```python
print(bool(""))        # False
print(bool("False"))   # True
```

`str()`은 전달받은 object의 문자열 버전을 만든다. 숫자, 논리값, container 등 어떤 값을 전달해도 사람이 읽기 좋은 문자열 표현으로 구성하려고 한다.

```python
print(str(10))          # 10
print(str(3.14))        # 3.14
print(str(True))        # True
print(str([1, 2, 3]))   # [1, 2, 3]
```

여기서 '문자열화'는 결과 type이 `str`이 된다는 뜻이다. `print(str(10))`을 실행하면 화면에는 `10`만 보이고 양쪽 따옴표가 출력되지는 않는다. 따옴표는 source code에서 문자열 literal을 표시하기 위한 문법이고, 출력값 자체에 항상 포함되는 문자는 아니다.

```python
s = str(10)

print(s)          # 10
print(type(s))    # <class 'str'>
```

이미 문자열인 값을 `str()`에 전달하면, 공식 문서 기준 문자열 object 자체가 반환된다. 그래서 값도 그대로이고 type도 그대로 `str`이다.

```python
s = "Python"
t = str(s)

print(t)          # Python
print(type(t))    # <class 'str'>
print(s is t)     # True
```

문자열을 개발자가 확인할 때 따옴표까지 보이는 경우는 보통 `repr()` 표현이 사용될 때다. 예를 들어 interactive shell에서 문자열 값을 그대로 평가하거나, list 안에 들어 있는 문자열을 출력하면 `repr()`에 가까운 표현이 보인다.

```python
print(str("Python"))       # Python
print(repr("Python"))      # 'Python'
print(["Python", "Java"])  # ['Python', 'Java']
```

### `input()`, `split()`, 입력값 분리

`input()`은 keyboard에서 한 줄을 입력받아 문자열 `str`로 반환한다. 숫자를 입력하더라도 처음에는 문자열이므로, 산술 연산에 사용하려면 `int()`나 `float()` 생성자로 원하는 numeric type instance를 구성해야 한다.

```python
x = input()
y = int(input())
z = float(input())

print(x, type(x))
print(y, type(y))
print(z, type(z))
```

`split()`은 문자열을 delimiter 기준으로 나누어 list로 반환하는 `str` method다. `sep`을 지정하지 않으면 공백 계열 문자를 기준으로 나누고, 연속된 공백은 하나의 구분처럼 처리된다.

```python
names = "kim lee park"
print(names.split())       # ['kim', 'lee', 'park']
```

실습 파일의 `[1-19]`처럼 왼쪽 변수 개수와 `split()` 결과 항목 수가 맞으면 unpack으로 바로 받을 수 있다.

```python
a, b, c = input().split()
print(a, b, c)
```

쉼표처럼 특정 delimiter를 기준으로 나눌 때는 `sep`을 직접 지정한다. `input().split(sep=",")`와 `input().split(",")`는 같은 의미다.

```python
a, b = input().split(sep=",")
a, b = int(a), int(b)
print(a + b)
```

`sep`을 지정한 경우에는 연속 delimiter가 빈 문자열을 만들 수 있다.

```python
print("1,,2".split(","))   # ['1', '', '2']
print("  1   2  ".split()) # ['1', '2']
```

### `str.format()` 포맷 문자열

`str.format()`은 문자열 안의 replacement field를 `{}`로 표시하고, 뒤의 `.format()` 인자 값을 그 위치에 끼워 넣는다. replacement field 바깥의 문자는 그대로 출력된다.

```python
s1 = "{}, {}".format(10, 20)
print(s1)                  # 10, 20
```

`{}`는 인자를 순서대로 사용한다. `{0}`, `{1}`처럼 위치 번호를 직접 지정하면 같은 값을 여러 번 사용하거나 순서를 바꿀 수 있다.

```python
print("{} {}".format("A", "B"))             # A B
print("{0} + {0} = {1}".format(2, 2 + 2))   # 2 + 2 = 4
```

`{a}`처럼 이름을 쓰면 `.format(a=..., b=...)`의 keyword argument를 참조한다.

```python
print("a = {a}, b = {b}".format(a=10, b=20))
```

format string에서 실제 중괄호 문자 `{` 또는 `}`를 출력하려면 두 번 써서 escape한다.

```python
print("{{{}}}".format(123)) # {123}
```

format specifier는 replacement field 안에서 `:` 뒤에 적는다. 폭, 정렬, 채움 문자, 진법, 소수점 자리, 천 단위 구분, percent 표시 등을 지정할 수 있다.

| 형식 | 의미 | 예 |
| :--- | :--- | :--- |
| `{0:d}` | decimal integer | `100` |
| `{0:x}` | hexadecimal lowercase | `64` |
| `{0:f}` | fixed-point float | `100.000000` |
| `{0:5}` | 폭 5칸 | 오른쪽 정렬 기본 |
| `{0:<5}` | 왼쪽 정렬 | `Hi   ` |
| `{0:>5}` | 오른쪽 정렬 | `   Hi` |
| `{0:_^5}` | `_` 채움, 가운데 정렬 | `_Hi__` |
| `{0:05.1f}` | `0` 채움, 소수 1자리 | `001.2` |
| `{:,}` | 천 단위 comma | `1,234` |
| `{:.2%}` | percent, 소수 2자리 | `24.50%` |

### f-prefix formatted string

f-string은 문자열 literal 앞에 `f` 또는 `F`를 붙인 formatted string literal이다. `{}` 안에 Python expression을 직접 넣을 수 있고, expression은 실행 시점에 평가된다.

```python
name = "mono"
age = 20
f1 = 11.3456

print(f"{name}, {age - 10}")  # mono, 10
print(f"{f1:10.5f}")          # 폭 10, 소수 5자리
```

f-string도 `str.format()`과 비슷하게 `:` 뒤에 format specifier를 쓸 수 있다.

```python
print(f"{age:>5}-{age:0>5}")
print(f"{age:<5}-{age:0^5}")
```

Python 3.8 이후에는 debug specifier인 `=`를 사용할 수 있다. expression과 값이 함께 출력되어 간단한 확인에 유용하다.

```python
age = 20
print(f"{age = }")      # age = 20
print(f"{age + 1 = }")  # age + 1 = 21
```

f-string에서 실제 중괄호 문자를 출력하려면 `{{`, `}}`처럼 두 번 쓴다.

```python
print(f"{{name}} = {name}")  # {name} = mono
```

backtick(`` ` ``)은 Python 3에서 문자열을 만드는 quote 문법이 아니다. Python 문자열은 작은따옴표, 큰따옴표, triple quote를 사용한다. Markdown에서는 코드 표시를 위해 backtick을 쓰지만, Python source code에서 문자열을 만들 때는 `"` 또는 `'`를 사용한다.
