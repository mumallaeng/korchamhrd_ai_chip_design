# 26-07-08 - Python 5장 이후 임시 메모

0707 본 노트에는 2장 `Object Name Binding`, 3장 `Container`, 4장 `Container 구조 및 연산`을 반영했다. 아래 내용은 0708 이후 수업 범위가 확정될 때 이어서 반영하기 위한 대기 메모다. 현재 대기 범위는 5장, 6장과 8장부터 12장까지다.

## 5. 주요 Built-in 함수

Iterable 관련 built-in 함수는 container와 iterator를 다룰 때 자주 사용된다.

| 함수 | 입력 | 결과/역할 |
| :--- | :--- | :--- |
| `len()` | sized object | item 개수 |
| `sum()` | numeric iterable | 합계 |
| `max()` | iterable 또는 여러 인자 | 최댓값 |
| `min()` | iterable 또는 여러 인자 | 최솟값 |
| `sorted()` | iterable | 정렬된 새 `list` |
| `all()` | iterable | 모두 참인지 확인 |
| `any()` | iterable | 하나라도 참인지 확인 |
| `map()` | function, iterable들 | iterator 반환 |
| `filter()` | function, iterable | 조건 True item iterator |
| `zip()` | iterable들 | tuple 묶음 iterator |
| `enumerate()` | iterable | 번호와 item tuple iterator |

`map`, `filter`, `zip`, `enumerate`는 iterator를 반환한다. iterator는 값을 생성하는 장치처럼 동작하며, `next()`나 `sum()`, `list()` 같은 소비 동작을 거치면 item을 꺼내고 소진될 수 있다.

```python
x = map(int, ["1", "2", "3"])
print(sum(x))       # 6
print(sum(x))       # 0, 이미 소진됨
```

iterator는 iterable의 한 종류라 `sum()` 등에는 사용할 수 있지만, `len()`이나 index 접근은 일반적으로 사용할 수 없다. 내용 확인이 필요하면 `list()`나 `tuple()`로 변환한다.

이 차이는 container와 iterator의 책임이 다르기 때문에 생긴다. `list`와 `tuple`은 item을 실제로 보관하므로 길이와 index 접근이 가능하지만, `map` object는 다음 item을 계산해 내는 상태만 가진다. 한 번 소비한 iterator를 다시 쓰려면 원본 iterable에서 iterator를 새로 만들거나, 처음 결과를 `list()`로 materialize해야 한다.

```python
m = map(round, [1.2, 3.8, 4.1])
print(list(m))
```

`zip()`은 여러 iterable을 같은 위치끼리 묶는다. Python 3.10 이후에는 `strict=True`를 사용할 수 있고, 길이가 다르면 `ValueError`가 발생한다.

```python
names = ["apple", "orange"]
prices = [100, 80]
print(dict(zip(names, prices)))
```

`enumerate()`는 item에 순서 번호를 붙인다. 시작 번호는 `start`로 지정할 수 있다.

```python
for i, name in enumerate(["apple", "orange"], start=1):
    print(i, name)
```

## 6. 사용자 정의 함수와 Parameter

함수는 `def 함수명(parameter list):` 형태로 정의한다. `def`를 만나면 Python은 function object를 만들고, 함수 이름을 현재 namespace에 binding한다. 함수 본문은 호출될 때 실행된다.

```python
def add(a, b):
    return a + b

result = add(10, 20)
```

함수는 함수 block이 끝나거나 `return`을 만나면 종료된다. `return` 뒤 expression은 호출한 위치로 전달된다. return 식이 여러 개이면 tuple로 pack되어 반환된다.

```python
def calc(a, b):
    return a + b, a - b

x = calc(10, 3)
print(x)        # (13, 7)
```

parameter는 함수 내부의 local name이고, 호출할 때 전달된 argument object에 binding된다. 함수 호출 시 local namespace가 생성되고, 함수가 끝나면 local namespace가 제거된다.

```python
def func(x):
    print(locals())
    return x + 1
```

함수 밖의 global name은 읽을 수 있지만, 함수 안에서 같은 이름에 대입하면 local name binding으로 처리된다. global name에 쓰기 동작을 하려면 `global` 선언이 필요하다.

```python
count = 0

def inc():
    global count
    count += 1
```

mutable object를 argument로 전달하면 함수 안에서 그 object의 내부 상태를 바꿀 수 있다. immutable object는 내부 value를 제자리에서 바꿀 수 없으므로 새 object binding으로 이어진다. 이를 수업에서는 call by assignment 관점으로 이해할 수 있다.

```python
def append_item(items):
    items.append(10)

data = []
append_item(data)
print(data)     # [10]
```

함수 parameter 종류는 크게 위치-키워드 parameter, 기본값이 있는 parameter, keyword-only parameter, 가변 parameter로 구분한다. 이번 흐름에서는 자주 쓰는 `pPK`, `pPKd`, `pK`, `pKd`를 먼저 구분한다.

| 약어 | 의미 | 예 |
| :--- | :--- | :--- |
| `pPK` | positional or keyword parameter | `def f(a): ...` |
| `pPKd` | default가 있는 positional or keyword parameter | `def f(a=10): ...` |
| `pK` | keyword-only parameter | `def f(*, a): ...` |
| `pKd` | default가 있는 keyword-only parameter | `def f(*, a=10): ...` |
| `*args` | 가변 위치 argument | 본 과정에서는 비중 낮음 |
| `**kwargs` | 가변 keyword argument | 본 과정에서는 비중 낮음 |

keyword argument는 `키워드=값` 형식으로 전달하고 순서와 무관하게 해당 parameter에 대응된다.

## 8. Comprehensions

8장은 비교/논리 연산과 generator expression, comprehension을 함께 다룬다. 핵심은 iterable에서 item을 하나씩 꺼내 target에 binding하고, expression과 optional `if` filter를 거쳐 새 iterator 또는 container를 구성하는 방식이다.

### 비교 연산자와 조건식

비교 연산자는 결과로 `True` 또는 `False`를 만든다. 값 비교, identity 비교, membership 비교를 구분한다.

| 구분 | 연산자 | 의미 |
| :--- | :--- | :--- |
| 크기 비교 | `<`, `>`, `<=`, `>=` | 대소 관계 확인 |
| 값 비교 | `==`, `!=` | value 기준 같음/다름 |
| identity 비교 | `is`, `is not` | 같은 object 여부 확인 |
| membership 비교 | `in`, `not in` | item 포함 여부 확인 |
| 조건식 | `x if c else y` | `c`가 참이면 `x`, 거짓이면 `y` |

범위 비교는 `a < b < c`처럼 연결해서 쓸 수 있다. 이때 각 비교가 순서대로 평가되며 전체 결과는 boolean이다.

```python
a, b, c = 10, 20, 30
print(a < b < c)
print(a == b, a != b)

items = [1, 2, 3]
print(2 in items, 4 not in items)

result = "YES" if a < b else "NO"
print(result)
```

### 논리 연산자와 truth value

`not`, `and`, `or`는 truth value를 기준으로 판단한다.

| 연산 | 동작 |
| :--- | :--- |
| `not x` | `x`가 거짓이면 `True`, 참이면 `False` |
| `x and y` | `x`가 거짓이면 `x`, 참이면 `y` |
| `x or y` | `x`가 참이면 `x`, 거짓이면 `y` |

Python에서 `0`, `0.0`, `False`, `None`, 빈 container인 `()`, `[]`, `{}`, `""`는 거짓으로 판단된다. 그 외 대부분의 값은 참으로 판단된다.

3 또는 7의 배수 판별 예제는 나머지 연산과 논리 연산을 함께 사용하는 문제다. `n % 3 == 0 or n % 7 == 0`에서 왼쪽 조건이 참이면 `or`의 short-circuit 때문에 오른쪽 조건은 평가하지 않아도 전체 결과가 참이다.

```python
n = int(input())
print(n % 3 == 0 or n % 7 == 0)
```

### `all()`과 `any()`

`all()`과 `any()`는 iterable을 받아 item들의 truth value를 판단한다.

| 함수 | 동작 | 빈 iterable 결과 |
| :--- | :--- | :--- |
| `all(it)` | 모든 item이 참이면 `True`, 하나라도 거짓이면 `False` | `True` |
| `any(it)` | 하나라도 참이면 `True`, 모두 거짓이면 `False` | `False` |

두 함수 모두 short-circuit 성격이 있다. `all()`은 처음 거짓 item을 만나면 바로 `False`를 반환하고, `any()`는 처음 참 item을 만나면 바로 `True`를 반환한다.

```python
print(all([True, 1, -1, 1.0, "str"]))
print(all([True, None, 1]))
print(any([None, True, 0]))
print(any([False, None, 0, 0.0, ""]))
```

### Generator expression

generator expression은 iterator를 만드는 expression이다. 괄호 `()`로 감싸며, 실제 item을 미리 모두 저장하지 않고 필요할 때 순서대로 생성한다.

```python
t = (1, -3, 7, -2, 8)

g = (x * x for x in t)
print(type(g))
print(*g)
print(*g)       # 이미 소진됨
```

generator expression은 다음 형태를 가진다.

```python
(expression for target in iterable)
```

`if`를 붙이면 조건을 만족하는 item만 생성할 수 있다.

```python
t = (1, -3, 7, -2, 8, 9)

positive = (x for x in t if x > 0)
square = (x * x for x in t if x > 0 and x % 3)

print(*positive)
print(*square)
```

여러 `for`를 연속해서 쓰면 앞쪽 `for`가 한 번 진행될 때마다 뒤쪽 `for`가 전체 item을 돈다.

```python
s1, s2 = "abc", "1234"
result = (x + y for x in s1 for y in s2)
print(*result)
```

다차원 container를 펼칠 때도 같은 구조를 사용할 수 있다.

```python
m = ((11, 2, 33, 4), (5, 6), (90, 10, 11, 12))
flat = tuple(y for x in m for y in x)

print(flat)
print(min(flat), max(flat), sum(flat))
```

### Comprehension

comprehension은 generator expression의 구조를 이용해 `list`, `set`, `dict` 같은 container를 바로 만드는 문법이다.

| 구분 | 형태 |
| :--- | :--- |
| list comprehension | `[expression for target in iterable if condition]` |
| set comprehension | `{expression for target in iterable if condition}` |
| dict comprehension | `{key: value for target in iterable if condition}` |

```python
L = [x for x in range(5)]
S = {x * x for x in [1, 2, 3, 3, 4]}

t = (("a", 90), ("b", 80), ("c", 95))
d1 = {x[0]: x[1] for x in t if x[1] > 85}
d2 = {k: v for k, v in t if v > 85}
```

귤 판매 예제는 입력받은 값 중 `10` 이상인 값만 선별해 list로 만드는 문제다. `map(int, input().split())`는 정수 iterator를 만들고, comprehension은 그 iterator에서 item을 하나씩 꺼내 `if x >= 10` 조건을 통과한 값만 새 list에 저장한다.

```python
n = int(input())
box = [x for x in map(int, input().split()) if x >= 10]

print(len(box))
print(*box)
```

선별한 값을 다시 2배로 만드는 예제는 filter와 mapping 성격이 동시에 들어간 comprehension이다.

```python
box = [x * 2 for x in map(int, input().split()) if x >= 10]
```

다차원 list를 `*`로 만들면 내부 mutable list가 공유되어 multiple binding 문제가 생길 수 있다.

```python
bad = [[0] * 3] * 4
bad[0][0] = 1
print(bad)
```

내부 list를 독립적으로 만들려면 comprehension을 사용한다.

```python
good = [[0 for j in range(3)] for i in range(4)]
good[0][0] = 1
print(good)
```

## 9. 제어문, 반복문

9장은 `if`, `for`, `while`을 중심으로 조건 분기와 반복 흐름을 정리한다. Python에서는 block을 중괄호가 아니라 들여쓰기로 구성하므로, 들여쓰기 범위가 실행 범위를 결정한다.

### `if`, `else`, `elif`

`if`는 조건식이 참일 때만 block을 실행한다. 문장이 간단하면 `:` 뒤에 한 문장을 이어 쓸 수 있지만, 일반적으로는 줄을 바꾸고 들여쓰기 block을 구성하는 편이 읽기 좋다.

```python
if condition:
    statement
```

`else`는 조건이 거짓일 때 실행된다.

```python
if condition:
    statement1
else:
    statement2
```

여러 조건 중 하나만 선택하려면 `elif`를 사용한다. 독립된 `if` 여러 개는 참인 조건을 모두 실행할 수 있지만, `if`/`elif`/`else` 구조는 가장 먼저 참이 된 branch 하나만 실행한다.

```python
if score >= 90:
    grade = "A"
elif score >= 80:
    grade = "B"
elif score >= 70:
    grade = "C"
elif score >= 60:
    grade = "D"
else:
    grade = "F"
```

block을 비워두면 문법 오류가 발생한다. 의도적으로 비워두려면 `pass`를 사용한다.

```python
if condition:
    pass
else:
    print("run")
```

### 조건문 활용 예제

2, 3, 5의 배수 판별 예제는 조건의 우선순위를 명확히 잡는 연습이다. 공통 배수 조건이 있으면 더 구체적인 조건을 먼저 검사해야 의도한 결과를 얻기 쉽다.

성적 기준 예제는 범위 밖 입력을 먼저 걸러낸 뒤 점수 구간을 검사한다. `100` 초과와 `0` 미만을 가장 먼저 검사해야 잘못된 점수가 `A`나 `F`로 분류되지 않는다.

```python
def grade(score):
    if score > 100 or score < 0:
        return "ERROR"
    if score >= 90:
        return "A"
    if score >= 80:
        return "B"
    if score >= 70:
        return "C"
    if score >= 60:
        return "D"
    return "F"
```

주차 요금 예제는 구간별 기본요금과 초과요금, 최대 요금 제한을 함께 처리한다. 30분 초과 시 초과 시간이 1분이라도 있으면 10분 단위 요금이 붙는 구조이므로 올림 계산이 필요하다.

```python
time = int(input())

if time < 10:
    fee = 0
elif time <= 30:
    fee = 500
else:
    extra_units = (time - 30 + 9) // 10
    fee = 500 + extra_units * 300
    if fee > 50000:
        fee = 50000

print(fee)
```

### `for`와 target unpack

`for`는 iterable의 item을 순서대로 target에 binding하고, item이 소진될 때까지 block을 반복한다.

```python
for target in iterable:
    statement
```

index가 필요하면 `range(len(seq))`를 쓸 수 있지만, item만 필요하면 직접 item을 받는 방식이 더 단순하다.

```python
names = ("kim", "lee", "park")

for name in names:
    print(name)
```

`for` target은 unpack도 가능하다.

```python
pairs = ((1, 2), ("A", "B"), ["hello", 100])

for a, b in pairs:
    print(a, b)
```

일부 item만 받고 나머지를 list로 묶으려면 starred target을 사용한다.

```python
for a, b, *rest in ([1, 2, 3, 4], ("kim", "lee", "park")):
    print(a, b, rest)
```

index와 item을 동시에 받으려면 `enumerate()`를 사용한다.

```python
for i, x in enumerate("ABCD"):
    print(i, x)
```

### `for` 활용 예제

`my_sum()` 예제는 `sum()` 없이 직접 반복하며 누적하는 문제다. 반복마다 `total` name이 가리키는 정수 object에서 새 합계 정수 object가 만들어지고, `total`이 그 결과에 다시 binding된다.

```python
def my_sum(values):
    total = 0
    for x in values:
        total += x
    return total
```

특정 이름이 들어 있는 모든 위치를 찾는 예제는 index와 item을 함께 확인하는 문제다.

```python
t = ("kim", "lee", "park", "kim", "song", "lee")
s = input()

for i, name in enumerate(t):
    if name == s:
        print(i)
```

귤 판매 시즌2는 comprehension으로 만든 코드를 순수한 `for` loop로 재작성하는 연습이다. 빈 list를 만든 뒤 조건에 맞는 item을 발견할 때마다 `append()`하는 형태가 기본 구조다.

```python
n = int(input())
values = map(int, input().split())
box = []

for x in values:
    if x >= 10:
        box.append(x)

print(len(box))
print(*box)
```

### 이중 `for`와 별 찍기

이중 `for`는 바깥 반복이 한 번 돌 때마다 안쪽 반복이 전체를 돈다. 별 찍기 문제에서는 `print("*", end="")`로 한 줄에 이어 출력하고, 안쪽 반복이 끝난 뒤 `print()`로 줄을 바꾼다.

```python
for i in range(5):
    for j in range(5):
        print("*", end="")
    print()
```

왼쪽 직각삼각형, 오른쪽 직각삼각형, 역삼각형 등은 각 행에서 출력할 공백 수와 별 수를 행 번호 기준으로 계산하는 문제다.

2차원 tuple 출력은 index보다 item 중심으로 순회하면 더 단순하다.

```python
t = ((1, 2, 3), (4, 5), (6, 7, 8, 9))

for row in t:
    for x in row:
        print(x, end=" ")
```

행과 열을 바꿔 출력하는 문제는 column index를 바깥 반복으로 두고, row를 안쪽 반복으로 순회한다.

```python
t = ((1, 2, 3, 4), (5, 6, 7, 8), (9, 10, 11, 12))

for col in range(len(t[0])):
    for row in range(len(t)):
        print(t[row][col], end=" ")
    print()
```

### `break`, `continue`, `for else`

`break`는 현재 반복문을 즉시 탈출한다. `continue`는 남은 block 실행을 건너뛰고 다음 반복으로 이동한다.

```python
for i in range(10):
    if i > 7:
        break
    if i % 3 == 0:
        continue
    print(i)
```

comprehension은 전체 iterable을 끝까지 평가하는 구조라, 중간에 특정 개수를 채우면 멈춰야 하는 문제에는 `for`와 `break`가 더 적합할 수 있다. 예를 들어 최대 10개까지만 담는 바구니 문제는 `break` 조건이 필요하다.

```python
m, n = map(int, input().split())
box = []

if m > n or m < 0 or n < 0:
    print("Error")
else:
    for x in range(m, n + 1):
        if x % 3 == 0 and x % 5 == 0:
            box.append(x)
            if len(box) == 10:
                break
    print(len(box))
    print(*box)
```

`for else`에서 `else`는 반복이 `break` 없이 정상 종료되었을 때 실행된다. 소수 판별에서는 약수를 찾아 `break`가 발생하면 합성수, 끝까지 `break`가 없으면 소수로 판단할 수 있다.

```python
def prime(n):
    if n < 2:
        print("not prime", n)
        return

    for i in range(2, n):
        if n % i == 0:
            print("not prime", n)
            break
    else:
        print("prime", n)
```

### `while`

`while`은 조건식이 참인 동안 block을 반복한다.

```python
while condition:
    statement
```

무한 루프는 `while True:`로 만들 수 있고, 내부 조건에서 `break`로 종료한다.

```python
while True:
    ch = input()
    if ch == "X":
        break
    print("ERROR")

print("EXIT")
```

`while`에서도 `break`, `continue`, `else`를 사용할 수 있다. 조건이 될 때까지 입력을 반복해서 받는 문제는 `while True`와 `break`의 전형적인 사용 예다.

`while ... else`의 `else`는 조건이 거짓이 되어 자연 종료될 때 실행되고, `break`로 빠져나가면 실행되지 않는다. 이 구조는 '끝까지 찾지 못한 경우'를 표현할 때 쓸 수 있지만, 수업 문제에서는 `for ... else`가 더 자주 보인다.

### 반복문 block의 namespace 주의

Python에서 `for`, `if` 들여쓰기 block은 별도의 namespace를 만들지 않는다. 따라서 반복문의 target name이나 block 안에서 대입한 name은 같은 scope의 name으로 남는다.

```python
i = 200

for i in [1, 2, 3]:
    pass

print(i)        # 3
```

이 점 때문에 반복문에서 사용하는 name이 바깥 name을 덮어쓰지 않도록 주의해야 한다.

## 10. 주요 Container 메서드

10장은 `list`와 `set`의 주요 method, 그리고 container를 활용한 실습 문제를 다룬다. 핵심은 mutable container가 원본을 직접 바꾸는 method와 새 object를 만들어 반환하는 연산을 구분하는 점이다.

### Mutable sequence 연산

`list`는 mutable sequence이므로 item 대입, slicing 대입, 삭제, 추가, 정렬, 뒤집기 등을 지원한다.

| 연산/메서드 | 의미 |
| :--- | :--- |
| `s[m] = x` | index `m` item 변경 |
| `s[m:n:k] = t` | slicing 구간을 iterable `t` item으로 대체 |
| `del s[m]` | index `m` item 제거 |
| `del s[m:n:k]` | slicing 구간 제거 |
| `s.clear()` | 전체 item 제거 |
| `s.copy()` | shallow copy 생성 |
| `s += t`, `s.extend(t)` | iterable `t`를 뒤에 연결 |
| `s *= n` | 현재 list 내용을 `n`번 반복해 확장 |
| `s.append(x)` | 끝에 item 하나 추가 |
| `s.insert(m, x)` | index `m` 위치에 삽입 |
| `s[::-1]` | 뒤집힌 새 list 생성 |
| `s.reverse()` | 원본 순서 직접 뒤집기 |
| `s.pop(m)` | item 반환 후 제거, 생략 시 마지막 item |
| `s.remove(x)` | 첫 번째 동일 item 제거 |
| `s.sort(reverse=..., key=...)` | 원본 직접 정렬 |

`reverse()`, `sort()`는 원본을 직접 바꾸고 반환값은 보통 사용하지 않는다. 반대로 slicing `s[::-1]`이나 `sorted(s)`는 새 object를 만든다.

이 구분을 놓치면 `a = a.sort()`처럼 작성했을 때 `a`가 정렬된 list가 아니라 `None`에 binding되는 실수가 생긴다. 원본을 바꾸는 method는 side effect가 목적이고, 새 object를 반환하는 함수나 expression은 반환값을 받아서 사용한다.

### `list` method와 삽입 문제

list method 예제에서는 `append()`, `insert()`, `extend()`, `remove()`, `pop()`, `reverse()`, `sort()`의 동작을 확인한다. `append()`는 item 하나를 그대로 추가하고, `extend()`는 iterable의 item들을 펼쳐서 추가한다는 점을 구분한다.

오름차순 list에 새 값을 넣는 문제는 정렬 함수 없이 알맞은 위치를 찾아 `insert()`하는 문제다. 앞에서부터 순회하며 처음으로 `m <= x`가 되는 위치에 넣으면 기존 정렬 순서가 유지된다. 끝까지 그런 위치가 없으면 새 값이 가장 크므로 `append()`한다.

```python
a = [1, 4, 7, 10]

while True:
    m = int(input())
    if m == 0:
        break

    for i, x in enumerate(a):
        if m <= x:
            a.insert(i, m)
            break
    else:
        a.append(m)

    print(a)
```

### `set` 연산자와 method

`set`은 중복 없는 hashable item들의 모음이다. 순서 기반 index 접근은 없고, 집합 연산과 membership 판단에 적합하다.

| 연산/메서드 | 의미 |
| :--- | :--- |
| `x in s` | item 포함 여부 |
| `s.union(t)`, `s | t` | 합집합 |
| `s.intersection(t)`, `s & t` | 교집합 |
| `s.difference(t)`, `s - t` | 차집합 |
| `s.symmetric_difference(t)`, `s ^ t` | 대칭 차집합 |
| `s.isdisjoint(t)` | 공통 item 없음 확인 |
| `s.issubset(t)`, `s <= t` | 부분집합 확인 |
| `s.issuperset(t)`, `s >= t` | 상위집합 확인 |
| `s.add(x)` | item 추가 |
| `s.remove(x)` | item 제거, 없으면 `KeyError` |
| `s.discard(x)` | item 제거, 없어도 오류 없음 |
| `s.pop()` | 임의 item 제거 후 반환 |
| `s.clear()` | 전체 제거 |
| `s.copy()` | shallow copy |

교실과 경비실에서 모두 빵을 받은 학생 수를 구하는 문제는 두 명단의 교집합 크기를 구하면 된다.

```python
x = ("kim", "lee", "park", "lew")
y = ("min", "park", "kong", "lew")

num = len(set(x) & set(y))
print(num)
```

복귀하지 않은 학생 번호를 찾는 문제는 전체 번호 집합에서 복귀 번호 집합을 빼고 정렬해서 출력한다.

```python
K = int(input())

for _ in range(K):
    N, M = (int(y) for y in input().split())
    returned = {int(y) for y in input().split()}
    missing = sorted(set(range(1, N + 1)) - returned)
    print(*missing)
```

## 11. Exception, Module, Package

11장은 runtime error를 처리하는 exception 문법과, 코드를 여러 파일로 분리해서 사용하는 module/package 구조를 다룬다.

### `try`와 `except`

`try` block에서 오류가 발생하면 Python은 맞는 `except` block으로 이동한다. 오류가 발생하지 않으면 `except`는 실행되지 않는다.

```python
try:
    a = b
except NameError:
    print("NameError")
```

`except`에 적은 오류 이름이 실제 오류와 맞지 않으면 처리되지 않는다. 오류 종류를 모를 때는 상위 exception인 `Exception`으로 받을 수 있다.

```python
try:
    a = int("3.14")
except Exception as e:
    print(type(e).__name__, e)
```

`e`는 error object이고, `type(e).__name__`으로 오류 이름을 확인할 수 있다.

### `else`, `finally`, 여러 `except`

`try`에는 `else`와 `finally`를 붙일 수 있다.

| 구문 | 실행 조건 |
| :--- | :--- |
| `except` | 지정한 오류 발생 |
| `else` | 오류 없이 `try` 완료 |
| `finally` | 오류 여부와 무관하게 항상 실행 |

`finally`는 `except`나 `else`에서 `return`이 있더라도 먼저 실행된다. file open 후 close 같은 정리 동작을 넣기에 적합하다.

```python
try:
    value = int(input())
except ValueError as e:
    print(type(e).__name__, e)
else:
    print(value)
finally:
    print("done")
```

여러 오류를 각각 다르게 처리하려면 `except TypeError`, `except NameError`, `except IndexError`처럼 나눌 수 있다. 오류를 의도적으로 무시할 때는 `pass`를 사용할 수 있지만, 실제 코드에서는 무시 이유가 분명해야 한다.

### Module과 Package

module은 하나의 `.py` 파일이다. 함수, class, 실행 코드 일부를 여러 파일로 나누어 관리할 때 사용한다. package는 module을 모아 둔 directory다.

예를 들어 `my_module.py`에 `add()`, `sub()`가 있고 `your_module.py`에 `mul()`, `div()`가 있으면 다른 파일에서 `import`로 사용할 수 있다.

```python
import my_module
print(my_module.add(3, 4))

import my_module as mm
print(mm.sub(3, 4))
```

`from module import name`은 module 안의 특정 name을 현재 namespace로 가져온다.

```python
from my_module import add, sub
print(add(3, 4), sub(3, 4))
```

두 방식은 namespace에 저장되는 것이 다르다.

| 방식 | 현재 namespace에 생기는 name | 호출 형태 |
| :--- | :--- | :--- |
| `import my_module as mm` | module object binding | `mm.add(3, 4)` |
| `from my_module import add` | 함수 object binding | `add(3, 4)` |

package 안의 module은 `package.module` 경로로 import한다.

```python
import my_package.my_module as mm
print(mm.add(3, 4))

from my_package.my_module import add, sub
print(add(3, 4), sub(3, 4))
```

원하는 folder에 있는 module을 임시로 import해야 할 때는 `sys.path`가 list라는 점을 이용해 경로를 추가할 수 있다. 사용 후에는 `pop()` 등으로 임시 경로를 제거한다.

```python
import sys

sys.path.append(r"./my_package/files")
import my_module2 as mm2
sys.path.pop()
```

## 12. 사용자 Class 생성

12장은 직접 class를 만들어 object를 모델링하는 방법을 다룬다. 함수와 global 변수만으로 상태를 관리하면 여러 사용자가 독립적으로 같은 기능을 쓰기 어렵기 때문에, class를 사용해 instance별 상태를 분리한다.

### class와 instance의 필요성

마트 셀프 계산기 예제에서 누적 금액 `s`를 global 변수 하나로 두면 계산기 하나만 운용하는 구조가 된다. 여러 사용자가 독립적으로 쓰려면 사용자별 상태가 필요하고, class는 이 상태와 동작을 묶는 template 역할을 한다.

```python
class Mart_Calc:
    s = 0

    def add(self, x):
        self.s += x
```

`Mart_Calc`는 class object이고, `usr1 = Mart_Calc()`는 instance를 생성한다. `usr1.add(10)`처럼 instance로 method를 호출하면 Python은 instance를 첫 번째 argument인 `self`에 전달한다.

```python
usr1 = Mart_Calc()
usr2 = Mart_Calc()

usr1.add(10)
usr2.add(100)
```

각 instance는 자신의 namespace를 가질 수 있으므로, `usr1.s`와 `usr2.s`를 독립적으로 관리할 수 있다.

### class 변수, instance 변수, local 변수

class, instance, method는 각각 namespace를 가진다.

| 변수 종류 | 위치 | 접근 |
| :--- | :--- | :--- |
| class 변수 | class namespace | `CLS.a` |
| instance 변수 | instance namespace | `self.b`, `obj.b` |
| local 변수 | method/function local namespace | parameter, function 내부 name |

```python
class CLS:
    a = 10

    def f1(self, x):
        y = x + 1
        self.b = y
        CLS.a += y
```

`self.b`는 현재 instance의 namespace에 저장된다. 반면 `CLS.a`는 class namespace에 저장된다. `.`은 특정 namespace에서 name을 찾으라는 의미로 이해할 수 있다.

`self.a += x`는 먼저 우변의 `self.a`를 찾고, 없으면 class namespace까지 탐색한 뒤, 최종 대입은 instance namespace에 수행될 수 있다. 이 때문에 읽기와 쓰기의 namespace 동작을 구분해야 한다.

### `__init__`, `__del__`, class 문서 문자열

instance 생성 시 초기 상태를 넣으려면 `__init__()`을 재정의한다.

```python
class Mart_Calc:
    def __init__(self, x):
        self.s = x

    def add(self, x):
        self.s += x
        return self.s

usr = Mart_Calc(10)
print(usr.add(30))
```

`__init__()`은 instance 생성 직후 한 번 자동 실행된다. 첫 번째 parameter 이름은 관례적으로 `self`를 사용한다.

class 안의 첫 문자열은 class 설명으로 저장되며 `__doc__`으로 확인할 수 있다. class 변수로 전체 instance 개수를 관리할 수도 있다.

```python
class Mart_Calc:
    "Mart Self Calculator"
    cnt = 0

    def __init__(self, x):
        self.s = x
        Mart_Calc.cnt += 1
```

instance 소멸 시 동작을 넣으려면 `__del__()`을 정의할 수 있다. 수업 예제에서는 계산기를 반납할 때 class 변수 `cnt`를 줄이는 흐름으로 사용한다.

```python
def __del__(self):
    Mart_Calc.cnt -= 1
```

### Special method와 operator overloading

Python의 표준 연산자와 일부 built-in 함수는 class에 정의된 special method와 연결된다. 예를 들어 `a + b`는 type에 맞는 `__add__()` 호출과 연결된다.

```python
a, b = 3, 5
print(a + b)
print(int.__add__(a, b))
print(a.__add__(b))
```

직접 만든 class에서도 special method를 재정의하면 연산자와 built-in 함수의 동작을 정할 수 있다.

```python
class CLS:
    def __init__(self, x):
        self.s = x

    def __add__(self, x):
        return self.s + x

    def __gt__(self, other):
        return self.s > other.s

    def __abs__(self):
        return -self.s

usr1 = CLS(10)
usr2 = CLS(-100)

print(usr1 + 30)
print(usr1 > usr2)
print(abs(usr2))
```

special method 이름은 `__add__`, `__str__`, `__len__`처럼 앞뒤에 double underscore가 붙는다.

### 상속, `super()`, overriding, MRO

child class는 parent class를 상속받아 parent의 method와 attribute를 사용할 수 있다.

```python
class Parent_CLS:
    a = 10

    def f(self, x):
        print("P_CLS:", x)

class Child_CLS(Parent_CLS):
    def __init__(self):
        print("C_CLS")
```

parent class의 초기화자를 호출하려면 `super()`를 사용한다.

```python
class New_Calc(Mart_Calc):
    def __init__(self, x):
        super().__init__(x)

    def sub(self, x):
        self.s -= x
```

child class에서 parent와 같은 이름의 method나 class variable을 다시 정의하면 overriding이 발생한다. 이 경우 같은 이름을 찾을 때 child의 namespace가 우선된다.

```python
class New_Calc(Mart_Calc):
    s = 20

    def add(self, x):
        print("add")
```

상속 탐색 순서는 `mro()`로 확인할 수 있다.

```python
print(New_Calc.mro())
```

다중 상속에서는 class 선언의 parent 순서와 MRO에 따라 name을 찾는다.

```python
class Son(Father, Mother):
    pass
```

위 구조에서는 `Son -> Father -> Mother -> object` 순서로 탐색한다.

### class method와 static method

`@classmethod`는 class 또는 instance로 호출해도 class object가 첫 번째 argument로 전달된다. 관례적으로 첫 번째 parameter 이름은 `cls`를 사용한다.

```python
class My_CLS:
    s = 0

    @classmethod
    def c_method(cls):
        print("c_method:", cls.s)
```

`@staticmethod`는 instance나 class를 자동으로 전달받지 않는다. class와 관련된 utility function처럼 사용할 수 있다.

```python
class My_CLS:
    s = 0

    @staticmethod
    def s_method():
        print("s_method:", My_CLS.s)
```

두 method 모두 `ClassName.method()`와 `instance.method()` 형태로 호출할 수 있지만, 자동 전달되는 값이 다르다.
