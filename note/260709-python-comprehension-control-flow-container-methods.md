# 26-07-09 - Python Comprehension, 제어문, Container 메서드

관련 노트:

- [260707-python-object-name-binding-container-operations.md](260707-python-object-name-binding-container-operations.md)
- [260708-python-built-in-functions-user-defined-functions.md](260708-python-built-in-functions-user-defined-functions.md)

## 수업 흐름

0709 수업은 Python 실습자료의 8장 `Comprehensions`, 9장 `제어문, 반복문`, 10장 `주요 Container 메서드`까지 진행했다. 비교 연산과 truth value에서 시작해 generator expression과 comprehension을 정리하고, 그 흐름을 `if`/`for`/`while` 제어문과 `list`/`set` method 사용으로 확장한다.

| 구분 | 내용 |
| :--- | :--- |
| 진행 범위 | Python 8장 `Comprehensions`, 9장 `제어문, 반복문`, 10장 `주요 Container 메서드` |
| 원본 파일 | [Py_Lab_for_VS_Code.py](</Users/mumallaeng/Library/CloudStorage/GoogleDrive-yonnmilk@gmail.com/My Drive/Classroom/대한상공회의소_반도체설계/김은경-C_and_Python/상공회의소_KDT_실습자료(C_Python_M4)/2.Python/Py_Lab_for_VS_Code.py>) |
| 예제 범위 | `[8-1]`부터 `[10-15]`까지 |
| 이전 범위 | 5장 `주요 Built-in 함수`, 6장 `사용자 정의 함수` |
| 다음 범위 | 11장 `Exception, Module, Package` 이후 |

## 실습 자료와 진행 범위

| 장 | 예제 | 주제 | 핵심 확인 |
| :--- | :--- | :--- | :--- |
| 8장 | `[8-1]`~`[8-3]` | 비교와 truth 판단 | 비교 연산, membership, identity, `all`, `any` |
| 8장 | `[8-4]`~`[8-10]` | generator expression | lazy iterator 생성, filter 조건, 중첩 `for`, 2차원 tuple flatten |
| 8장 | `[8-11]`~`[8-15]` | comprehension | list/set/dict comprehension, 귤 선별, 다차원 list 생성 주의 |
| 9장 | `[9-1]`~`[9-5]` | 조건 분기 | `if`/`elif`/`else`, `pass`, 조건 우선순위 |
| 9장 | `[9-6]`~`[9-13]` | `for` 반복 | target binding, unpack, `enumerate()`, `dict.items()`, 누적/검색 |
| 9장 | `[9-15]`~`[9-20]` | 이중 반복과 반복 제어 | 별 찍기, 2차원 tuple, `break`, `continue`, `for else` |
| 9장 | `[9-25]` | `while` 반복 | 조건 만족까지 입력 반복, `while else` |
| 10장 | `[10-1]`~`[10-11]` | mutable sequence method | `append`, `insert`, `extend`, `remove`, `pop`, `reverse`, `sort` |
| 10장 | `[10-12]`~`[10-15]` | `set` 연산과 method | 집합 연산, 명단 비교, 차집합 활용 |

## 8. 비교, Generator Expression, Comprehension

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

필터 `if`는 여러 개 붙일 수 있다. 여러 `if`는 왼쪽부터 순서대로 검사되며, 앞 조건을 통과한 item만 다음 조건으로 넘어간다.

```python
t = (1, -3, 7, -2, 8, 9)

result = (x for x in t if x > 0 if x % 3 != 0)

print(*result)  # 1 7 8
```

위 코드는 다음처럼 하나의 `if` 안에서 `and`로 묶은 형태와 결과가 같다.

```python
result = (x for x in t if x > 0 and x % 3 != 0)
```

다만 조건을 여러 `if`로 나누면 앞 조건이 뒤 조건의 안전장치 역할을 할 수 있다.

```python
words = ['apple', '', 'avocado', 'banana']
result = (x for x in words if x if x[0] == 'a')

print(*result)  # apple avocado
```

여기서 첫 번째 `if x`가 빈 문자열을 먼저 제거하므로, 두 번째 조건에서 `x[0]`을 접근해도 빈 문자열 때문에 `IndexError`가 나지 않는다.

generator expression이나 comprehension에서 `for` 뒤에 붙는 `if`는 일반 `if` 문이 아니라 필터 조건이다. 조건을 만족하지 않는 item은 expression 평가 단계까지 가지 않고 제외된다.

```python
y = input().split()
y = ('*' + x[1:] for x in y if x[0] == 'a')

print(*y)
```

이 구조는 아래 흐름으로 읽는다.

```text
1. y에서 x를 하나씩 꺼냄
2. x[0] == 'a' 조건을 먼저 확인
3. 조건을 통과한 x만 '*'+x[1:]로 변환
4. 조건을 통과하지 못한 x는 결과에서 제외
```

따라서 `for` 뒤의 필터 `if`에는 `else`를 붙일 수 없다. `else`까지 필요한 경우는 필터가 아니라 조건식으로 값을 선택해야 한다.

| 목적 | 형태 | 결과 |
| :--- | :--- | :--- |
| 조건에 맞는 item만 남김 | `(expr for x in iterable if condition)` | 조건 실패 item 제외 |
| 모든 item을 유지하고 값만 다르게 생성 | `(expr1 if condition else expr2 for x in iterable)` | 조건에 따라 생성값 선택 |

예를 들어 `a`로 시작하는 단어만 남기려면 필터 `if`를 사용한다.

```python
words = ['apple', 'banana', 'avocado']
result = ('*' + x[1:] for x in words if x[0] == 'a')

print(*result)  # *pple *vocado
```

반대로 모든 단어를 출력하되, `a`로 시작하는 단어만 앞 글자를 `*`로 바꾸려면 조건식을 앞쪽 expression 자리에 둔다.

```python
words = ['apple', 'banana', 'avocado']
result = ('*' + x[1:] if x[0] == 'a' else x for x in words)

print(*result)  # *pple banana *vocado
```

핵심은 `if`의 위치다. `for` 뒤의 `if`는 필터이고, expression 자리에 있는 `A if condition else B`는 조건에 따라 생성할 값을 고르는 조건식이다.

여러 `for`를 연속해서 쓰면 앞쪽 `for`가 한 번 진행될 때마다 뒤쪽 `for`가 전체 item을 돈다.

```python
s1, s2 = "abc", "1234"
result = (x + y for x in s1 for y in s2)
print(*result)
```

일반 `for` 문으로 쓰면 아래 흐름과 같다.

```python
s1, s2 = "abc", "1234"

for x in s1:
    for y in s2:
        print(x + y)
```

구구단처럼 원래 이중 `for` 문으로 쓰던 출력 흐름도 generator expression으로 표현할 수 있다.

```python
for i in range(2, 10):
    for j in range(1, 10):
        print(f"{i} * {j} = {i * j}")
```

한 줄 generator expression으로 만들면 다음과 같다.

```python
g = (f"{i} * {j} = {i * j}" for i in range(2, 10) for j in range(1, 10))

print(*g, sep="\n")
```

별찍기처럼 바깥 반복이 행을 만들고 안쪽 반복이 한 행의 내용을 만드는 구조도 같은 방식으로 읽을 수 있다.

```python
for i in range(1, 6):
    line = ""
    for j in range(i):
        line += "*"
    print(line)
```

한 줄로 만들면 각 행 문자열을 generator가 하나씩 만든다.

```python
stars = ("*" * i for i in range(1, 6))

print(*stars, sep="\n")
```

안쪽 반복 자체를 드러내고 싶으면 `join()`과 generator expression을 한 번 더 사용할 수 있다.

```python
stars = ("".join("*" for j in range(i)) for i in range(1, 6))

print(*stars, sep="\n")
```

정리하면 이중 `for` 문으로 만들던 `행과 열`, `단과 곱하는 수`, `그룹과 item` 같은 구조는 generator expression의 여러 `for`로 옮길 수 있다. 다만 너무 길어져 읽기 어려우면 일반 `for` 문으로 쓰는 편이 낫다.

generator expression의 `for target in iterable`에서 `target`은 일반 `for` 문과 같은 target binding 규칙을 사용한다. 따라서 tuple/list unpack, starred target, `enumerate()`, `dict.items()` unpack도 사용할 수 있다.

```python
scores = {"kim": 90, "lee": 80, "park": 95}

messages = (f"{name}: {score}" for name, score in scores.items())

print(*messages, sep="\n")
```

일반 `for` 문으로 쓰면 다음과 같다.

```python
scores = {"kim": 90, "lee": 80, "park": 95}

for name, score in scores.items():
    print(f"{name}: {score}")
```

`scores.items()`가 `(key, value)` pair를 하나씩 만들고, `for name, score`가 그 pair를 unpack한다. 반대로 `for name in scores`처럼 `dict`를 그대로 반복하면 key만 나온다.

```python
scores = {"kim": 90, "lee": 80, "park": 95}

only_names = (name for name in scores)

print(*only_names)  # kim lee park
```

정리하면 일반 `for` 문에서 쓰는 target unpack 방식은 generator expression의 `for` 절에서도 사용할 수 있다. 실전에서는 '일반 `for` 문의 header 부분은 거의 그대로 쓸 수 있고, block 안의 statement는 넣을 수 없다'고 생각하면 쉽다.

즉 아래처럼 일반 `for` 문에서 `:` 앞에 쓰는 반복 대상과 target 구조는 generator expression 안에서도 자연스럽게 사용할 수 있다.

```python
for a, b in pairs:
    ...

for i, x in enumerate(seq):
    ...

for k, v in d.items():
    ...
```

위 구조들은 각각 generator expression에서 다음처럼 쓸 수 있다.

```python
(a + b for a, b in pairs)
(f"{i}: {x}" for i, x in enumerate(seq))
(f"{k}: {v}" for k, v in d.items())
```

다만 generator expression은 `expression`이므로 일반 `for` block의 모든 statement를 그대로 넣을 수 있는 것은 아니다. 안 되는 항목을 제외하면 `for` 절 자체는 일반 `for`처럼 읽어도 된다.

| 일반 `for` 문 기능 | Generator expression 적용 |
| :--- | :--- |
| `for a, b in pairs` | 가능 |
| `for a, b, *rest in rows` | 가능 |
| `for i, x in enumerate(seq)` | 가능 |
| `for k, v in d.items()` | 가능 |
| `if`로 필터링 | `for ... if condition` 형태로 가능 |
| `break`, `continue` | 불가, statement라서 expression 안에 배치 불가 |
| `return`, `yield` | 불가, 함수 body statement |
| 여러 줄 statement body | 불가, 생성값은 하나의 expression |
| 여러 동작을 순서대로 실행 | 불가, `expr1; expr2` 같은 statement 나열 불가 |
| `print()`, `append()` 같은 부수효과 중심 코드 | 문법상 가능하지만 generator expression 용도와는 맞지 않음 |

`for`가 여러 개 있을 때 `if` 필터는 꼭 맨 마지막에만 둘 필요가 없다. 각 `for` 뒤에 `if`를 붙일 수 있고, 위치에 따라 필터링되는 대상이 달라진다.

```python
letters = ["A", "B", "X"]
numbers = ["1", "2", "3"]

result = (a + n for a in letters if a != "X" for n in numbers if n != "2")

print(*result)  # A1 A3 B1 B3
```

일반 `for` 문으로 펼치면 다음과 같다.

```python
letters = ["A", "B", "X"]
numbers = ["1", "2", "3"]

for a in letters:
    if a != "X":
        for n in numbers:
            if n != "2":
                print(a + n)
```

| Generator expression 형태 | 일반 `for` 문 대응 | 의미 |
| :--- | :--- | :--- |
| `(a + n for a in letters if a != "X" for n in numbers)` | `for a` 뒤에서 `a` 검사 | 바깥 item 필터 |
| `(a + n for a in letters for n in numbers if n != "2")` | `for n` 뒤에서 `n` 검사 | 안쪽 item 필터 |
| `(a + n for a in letters if a != "X" for n in numbers if n != "2")` | 바깥 `if`와 안쪽 `if` 모두 적용 | 바깥/안쪽 item 모두 필터 |

즉 generator expression은 왼쪽에서 오른쪽으로 읽으면 된다.

```python
(expr for a in A if cond_a for b in B if cond_b)
```

위 구조는 아래와 같은 실행 흐름이다.

```python
for a in A:
    if cond_a:
        for b in B:
            if cond_b:
                expr
```

첫 번째 `if cond_a`를 통과하지 못하면 안쪽 `for b in B` 자체가 실행되지 않는다. 따라서 중간 `if`는 단순히 최종 결과만 거르는 것이 아니라, 뒤쪽 반복을 실행할지 여부도 결정한다.

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

결과만 보면 comprehension은 generator expression을 `list()`, `set()`, `dict()` 생성자에 넘긴 것과 비슷하게 보일 수 있다.

```python
nums = [1, 2, 2, 3]

a = [x * x for x in nums]
b = list(x * x for x in nums)

print(a)  # [1, 4, 4, 9]
print(b)  # [1, 4, 4, 9]
```

`set`도 결과 기준으로는 비슷하다.

```python
a = {x * x for x in nums}
b = set(x * x for x in nums)

print(a)  # {1, 4, 9}
print(b)  # {1, 4, 9}
```

`dict`는 expression 자리에 `key: value` 형태가 와야 한다. 생성자에 넘길 때는 `(key, value)` pair를 만드는 iterable이 필요하다.

```python
words = ["apple", "banana", "kiwi"]

a = {word: len(word) for word in words}
b = dict((word, len(word)) for word in words)

print(a)
print(b)
```

하지만 생성 과정은 다르다.

| 표현 | 생성 과정 | 중간 object | 쓰기 좋은 경우 |
| :--- | :--- | :--- | :--- |
| `[expr for x in xs]` | list를 직접 만들며 item 추가 | 별도 generator 없음 | 최종 list 필요 |
| `list(expr for x in xs)` | generator 생성 후 `list()`가 소비 | generator object 있음 | generator를 넘기는 흐름 확인 |
| `{expr for x in xs}` | set을 직접 만들며 item 추가 | 별도 generator 없음 | 최종 set 필요 |
| `set(expr for x in xs)` | generator 생성 후 `set()`이 소비 | generator object 있음 | generator pipeline에서 set 생성 |
| `{k: v for x in xs}` | dict를 직접 만들며 key/value 추가 | 별도 generator 없음 | 최종 dict 필요 |
| `dict((k, v) for x in xs)` | pair generator 생성 후 `dict()`가 소비 | generator object 있음 | pair iterable에서 dict 생성 |

따라서 최종 결과 container가 필요하면 comprehension이 더 직접적이다. 반대로 최종 container가 필요 없고 바로 소비할 값만 필요하면 generator expression이 memory를 아낄 수 있다.

```python
total = sum(x * x for x in nums)
has_big = any(x > 100 for x in nums)
all_positive = all(x > 0 for x in nums)
```

위 세 예제는 list를 만들지 않고 item을 하나씩 생성해 `sum`, `any`, `all`이 바로 소비한다. 이 경우 `sum([x * x for x in nums])`처럼 list를 먼저 만드는 방식은 불필요한 container를 추가로 만드는 셈이다.

`tuple`은 특히 주의해야 한다. 괄호 `()`는 tuple comprehension이 아니라 generator expression을 만든다.

```python
g = (x * x for x in nums)
t = tuple(x * x for x in nums)

print(type(g))  # <class 'generator'>
print(t)        # (1, 4, 4, 9)
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

각 item이 여러 값을 가진 구조라면 `for` 문 안에서 바로 여러 name으로 받을 수 있다. `dict`는 그대로 반복하면 key만 나오지만, `items()`를 사용하면 `(key, value)` pair가 나오므로 `for k, v in ...` 형태로 unpack할 수 있다.

```python
scores = {"kim": 90, "lee": 80, "park": 95}

for name in scores:
    print(name)         # key만 순회

for name, score in scores.items():
    print(name, score)  # key와 value를 동시에 사용
```

위 코드는 `scores.items()`가 `("kim", 90)` 같은 2-item tuple을 하나씩 내보내고, `for name, score`가 그 tuple을 unpack하는 구조다.

unpack한 값 중 사용하지 않는 값은 관례적으로 `_`에 받을 수 있다. `_`는 특별한 폐기 문법이 아니라 일반 name이지만, Python 코드에서는 '이 값은 사용하지 않음'이라는 의도를 나타낼 때 자주 쓴다.

```python
pairs = [("kim", 90), ("lee", 80), ("park", 95)]

for name, _ in pairs:
    print(name)

for _, score in pairs:
    print(score)
```

`enumerate()`에서도 index가 필요 없거나 item이 필요 없으면 `_`로 의도를 표시할 수 있다.

```python
names = ["kim", "lee", "park"]

for _, name in enumerate(names):
    print(name)
```

다만 `_`도 실제로는 name binding이 일어나므로 마지막으로 받은 값이 남을 수 있다. 따라서 '사용하지 않는 값'이라는 코드 작성 관례로 이해하는 편이 정확하다.

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

## 복습 메모

2차원 정수 입력을 처리할 때는 먼저 문자열 list를 만들고 나중에 정수로 바꾸는 방식보다, 각 줄을 읽는 순간 정수 list로 바꾸는 방식이 더 직접적이다.

```python
n = int(input())
l = [input().split() for _ in range(n)]
l = [list(map(int, x)) for x in l]

print(*l, sep="\n")
```

위 코드는 아래처럼 한 단계로 줄일 수 있다.

```python
n = int(input())
l = [list(map(int, input().split())) for _ in range(n)]

print(*l, sep="\n")
```

일반 `for` 문으로 풀면 다음 구조다.

```python
n = int(input())
l = []

for _ in range(n):
    row = list(map(int, input().split()))
    l.append(row)

print(*l, sep="\n")
```

여기서 `_`는 반복 횟수만 필요하고 실제 index 값은 사용하지 않는다는 뜻의 관례적 name이다.

반대로 아래 형태는 의도대로 동작하지 않는다.

```python
n = [s * 2 for s in int(x) if s >= 10 for x in input().split()]
```

comprehension의 `for` 절은 왼쪽에서 오른쪽으로 읽힌다. 따라서 위 코드는 `x`를 아직 만들기 전에 `int(x)`를 사용하려고 하며, `int(x)`는 정수 하나라서 `for s in int(x)`처럼 반복할 수도 없다.

원하는 흐름은 `input().split()`에서 `x`를 먼저 꺼내고, 그 다음 `int(x)`로 정수 `s`를 만드는 것이다.

```python
n = [s * 2 for s in (int(x) for x in input().split()) if s >= 10]
```

다만 이 정도로 중첩 generator expression이 들어가면 읽기가 어려워질 수 있다. 단순히 정수 변환 후 필터링할 목적이라면 `map()`을 함께 쓰는 편이 더 읽기 쉽다.

```python
n = [s * 2 for s in map(int, input().split()) if s >= 10]
```

정리하면 comprehension과 generator expression은 일반 `for` 문을 한 줄로 옮길 수 있는 강력한 문법이지만, `for` 절의 순서와 target binding 순서를 그대로 따라간다. 헷갈릴 때는 먼저 일반 `for` 문으로 풀어 쓰고, 그 다음 한 줄 표현으로 줄이는 방식으로 복습한다.

## 정리

8장의 핵심은 비교 결과와 truth value를 이용해 iterator 또는 container 생성 흐름을 제어하는 것이다. generator expression은 값을 필요할 때 생성하고, comprehension은 같은 반복/조건 구조로 `list`, `set`, `dict` 같은 구체적인 container를 만든다. `for` 뒤의 `if`는 필터 조건이고, expression 위치의 `A if condition else B`는 조건에 따라 생성할 값을 고르는 조건식이라는 차이를 구분해야 한다.

9장의 핵심은 조건 분기와 반복문이 name binding, unpack, `break`/`continue`, `else`와 어떻게 연결되는지 이해하는 것이다. Python의 `if`, `for`, `while` block은 별도 namespace를 만들지 않으므로 반복 target이나 block 내부 대입이 같은 scope에 남는다는 점도 함께 주의한다.

10장의 핵심은 mutable container method의 side effect와 새 object를 만드는 expression/function을 구분하는 것이다. `list.sort()`, `list.reverse()`처럼 원본을 직접 바꾸는 method와 `sorted()`, slicing처럼 새 object를 만드는 표현을 섞어 쓰면 binding 결과가 달라질 수 있다. `set`은 순서 기반 접근이 아니라 membership, 중복 제거, 집합 연산 중심으로 사용한다.
