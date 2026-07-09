# 26-07-09 - Python 비교, Generator Expression, Comprehension

관련 노트:

- [260707-python-object-name-binding-container-operations.md](260707-python-object-name-binding-container-operations.md)
- [260708-python-built-in-functions-user-defined-functions.md](260708-python-built-in-functions-user-defined-functions.md)

## 수업 흐름

0709 수업은 Python 실습자료의 8장 `Comprehensions` 범위를 진행했다. 비교 연산과 truth value를 먼저 정리하고, `all`, `any`, generator expression, comprehension이 iterable을 어떤 방식으로 소비하고 새 값을 만드는지 연결해서 확인한다.

| 구분 | 내용 |
| :--- | :--- |
| 진행 범위 | Python 8장 `Comprehensions` |
| 원본 파일 | [Py_Lab_for_VS_Code.py](</Users/mumallaeng/Library/CloudStorage/GoogleDrive-yonnmilk@gmail.com/My Drive/Classroom/대한상공회의소_반도체설계/김은경-C_and_Python/상공회의소_KDT_실습자료(C_Python_M4)/2.Python/Py_Lab_for_VS_Code.py>) |
| 예제 범위 | `[8-1]`부터 `[8-15]`까지 |
| 이전 범위 | 5장 `주요 Built-in 함수`, 6장 `사용자 정의 함수` |
| 다음 범위 | 9장 `제어문, 반복문` 이후 |

## 실습 자료와 진행 범위

| 장 | 예제 | 주제 | 핵심 확인 |
| :--- | :--- | :--- | :--- |
| 8장 | `[8-1]`~`[8-3]` | 비교와 truth 판단 | 비교 연산, membership, identity, `all`, `any` |
| 8장 | `[8-4]`~`[8-10]` | generator expression | lazy iterator 생성, filter 조건, 중첩 `for`, 2차원 tuple flatten |
| 8장 | `[8-11]`~`[8-15]` | comprehension | list/set/dict comprehension, 귤 선별, 다차원 list 생성 주의 |

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


## 정리

8장의 핵심은 비교 결과와 truth value를 이용해 iterator 또는 container 생성 흐름을 제어하는 것이다. generator expression은 값을 필요할 때 생성하고, comprehension은 같은 반복/조건 구조로 list, set, dict 같은 구체적인 container를 만든다. `for` 뒤의 `if`는 필터 조건이고, expression 위치의 `A if condition else B`는 조건에 따라 생성할 값을 고르는 조건식이라는 차이를 구분해야 한다.
