# 26-07-08 - Python Built-in 함수와 사용자 정의 함수

관련 노트:

- [260706-python-basic-syntax.md](260706-python-basic-syntax.md)
- [260707-python-object-name-binding-container-operations.md](260707-python-object-name-binding-container-operations.md)

## 수업 흐름

0708 수업은 Python 실습자료의 5장 `주요 Built-in 함수`부터 6장 `사용자 정의 함수`까지 진행했다. 5장에서는 built-in 함수가 object와 iterable을 어떻게 받아 처리하는지 확인하고, 6장에서는 `def` 문으로 function object를 만들고 parameter, argument, return, namespace를 다루는 방식을 확인한다.

| 구분 | 내용 |
| :--- | :--- |
| 진행 범위 | Python 5장 `주요 Built-in 함수`, 6장 `사용자 정의 함수` |
| 원본 파일 | [Py_Lab_for_VS_Code.py](</Users/mumallaeng/Library/CloudStorage/GoogleDrive-yonnmilk@gmail.com/My Drive/Classroom/대한상공회의소_반도체설계/김은경-C_and_Python/상공회의소_KDT_실습자료(C_Python_M4)/2.Python/Py_Lab_for_VS_Code.py>) |
| 예제 범위 | `[5-1]`부터 `[6-15]`까지 |
| 이전 범위 | 2장 `Object Name Binding`, 3장 `Container`, 4장 `Container 구조 및 연산` |
| 다음 범위 | 8장 `Comprehensions` |

## 실습 자료와 진행 범위

| 장 | 예제 | 주제 | 핵심 확인 |
| :--- | :--- | :--- | :--- |
| 5장 | `[5-1]`~`[5-2]` | numeric built-in | `abs`, `pow`, `divmod`, `max`, `min`, `round` |
| 5장 | `[5-3]` | dynamic execution | `eval`, `exec` 차이와 주의점 |
| 5장 | `[5-4]`~`[5-5]` | container built-in과 sequence method | `len`, `sum`, `sorted`, `index`, `count` |
| 5장 | `[5-6]`~`[5-7]` | tuple lookup과 dict lookup | index 기반 조회와 key 기반 조회 비교 |
| 5장 | `[5-8]`~`[5-16]` | iterator 생성 함수 | `map`, `filter`, `zip`, `enumerate`, iterator 1회 소비 |
| 5장 | `[5-17]`~`[5-20]` | 입력 처리와 정렬 | `max`, `index`, `set`, `sorted(reverse=True)` |
| 6장 | `[6-1]`~`[6-6]` | 함수 정의, 호출, return | function object, return 종료, tuple return |
| 6장 | `[6-7]`~`[6-10]` | namespace와 argument 전달 | local/global namespace, mutable/immutable object 전달 |
| 6장 | `[6-11]`~`[6-15]` | parameter 종류 | positional-or-keyword, default, keyword-only |

## 5. 주요 Built-in 함수

### Built-in 함수의 위치

`built-in function`은 Python 실행 환경이 기본으로 제공하는 함수다. `print`, `len`, `sum`, `max`, `map` 같은 이름은 보통 따로 import하지 않아도 사용할 수 있다. 이름 탐색 관점에서는 local namespace와 global namespace에서 찾지 못하면 built-in namespace까지 올라가 이름을 찾는다.

```python
print(len([1, 2, 3]))
print(abs(-10))
```

함수 이름이 짧게 되어 있는 경우가 많다. 일부는 약어이고, 일부는 영어 단어 자체를 그대로 쓴 이름이다.

| 이름 | 풀어 읽기 | 성격 |
| :--- | :--- | :--- |
| `abs` | absolute value | 절댓값 약어 |
| `pow` | power | 거듭제곱 의미 |
| `divmod` | divide and modulo | 몫과 나머지 계산을 합친 이름 |
| `len` | length | 길이 약어 |
| `min` | minimum | 최솟값 약어 |
| `max` | maximum | 최댓값 약어 |
| `eval` | evaluate | expression 평가 약어 |
| `exec` | execute | statement 실행 약어 |
| `filter` | filter | 조건을 통과한 item만 거르는 의미 |
| `iter` | iterator 또는 iterate | iterator 생성 관련 약어 |
| `repr` | representation | 개발자용 표현 문자열 약어 |
| `str` | string | 문자열 type 이름 약어 |
| `dict` | dictionary | mapping type 이름 약어 |
| `enumerate` | enumerate | 번호를 매기며 나열한다는 단어 |
| `zip` | zip together | 여러 iterable을 맞물려 묶는 의미 |

다만 built-in 이름도 일반 name이므로, 같은 이름을 global 또는 local namespace에 binding하면 built-in 이름을 가릴 수 있다.

```python
list = [1, 2, 3]

# 이후 list("abc") 같은 호출이 깨질 수 있음
```

학습용 실습에서는 이런 shadowing을 관찰할 수 있지만, 실제 코드에서는 built-in 이름을 변수명으로 쓰지 않는 편이 안전하다.

### Numeric built-in

`[5-1]`, `[5-2]`에서는 숫자 처리에 자주 쓰는 built-in 함수를 확인한다.

| 함수 | 이름 의미 | 기본 형태 | 반환 | 핵심 |
| :--- | :--- | :--- | :--- | :--- |
| `abs(x)` | absolute value | `abs(-3.8)` | 절댓값 | 숫자 type별 `__abs__` 동작과 연결 |
| `pow(x, y)` | power | `pow(20, 3)` | `x ** y` | 거듭제곱 |
| `pow(x, y, z)` | power with modulo | `pow(4, 2, 3)` | `(x ** y) % z` | modular exponentiation |
| `divmod(a, b)` | divide and modulo | `divmod(10, 3)` | `(a // b, a % b)` | 몫과 나머지를 tuple로 반환 |
| `max(...)` | maximum | `max(1, 3.4, 5.7)` | 최댓값 | 여러 인자 또는 iterable |
| `min(...)` | minimum | `min([10, 20, -2])` | 최솟값 | 여러 인자 또는 iterable |
| `round(x)` | round | `round(3.73)` | 반올림 결과 | 정수 자리 반올림 |
| `round(x, ndigits)` | round to digits | `round(3.745, 1)` | 지정 자리 반올림 | `ndigits` 음수 가능 |

```python
a, b = divmod(10, 3)
print(a, b)          # 3 1
print(divmod(10, 3)) # (3, 1)
```

`pow(x, y, z)`의 세 번째 인자 `z`는 modulus, 즉 나머지를 구할 기준값이다. 따라서 결과는 `(x ** y) % z`와 같다.

```python
print(pow(4, 2, 3))      # (4 ** 2) % 3 == 16 % 3 == 1
print(pow(2, 10, 7))     # (2 ** 10) % 7 == 1024 % 7 == 2
```

이 계산을 modular exponentiation이라고 부른다. 뜻은 `거듭제곱을 한 뒤 특정 값으로 나눈 나머지를 구하는 계산`이다. 다만 실제 구현 관점에서는 `x ** y`라는 매우 큰 값을 먼저 전부 만든 뒤 마지막에 `% z`를 적용하는 방식이 아니라, 거듭제곱을 계산하는 중간중간 나머지를 유지하면서 진행한다.

```text
(a * b) % m == ((a % m) * (b % m)) % m
```

이 성질 덕분에 중간 값이 지나치게 커지지 않는다. 예를 들어 `pow(123456789, 987654321, 1000000007)`은 실제로는 엄청나게 큰 거듭제곱의 나머지를 구하는 문제지만, Python은 modular exponentiation 방식으로 계산하므로 현실적인 시간과 메모리 안에서 처리할 수 있다. 암호, 해시, 난수, 알고리즘 문제에서 자주 쓰이는 형태다.

'modulo 공간'은 어떤 수 `m`으로 나눈 나머지만 구분하는 계산 체계다. 예를 들어 `mod 7`에서는 모든 정수를 `0`부터 `6`까지의 대표값으로 본다.

```text
8  % 7 = 1
15 % 7 = 1
22 % 7 = 1

1, 8, 15, 22는 mod 7 관점에서 같은 나머지 1을 가짐
```

따라서 `pow(a, b, m)`은 큰 거듭제곱 자체를 구하려는 목적보다, `a ** b`가 modulo 공간에서 어떤 대표값을 가지는지 구하려는 목적에 가깝다. 즉 '거듭제곱 전체 값'이 필요한 것이 아니라 '거듭제곱 결과의 나머지 대표값'이 필요한 상황에서 사용한다.

| 사용 상황 | 필요한 값 | 예 |
| :--- | :--- | :--- |
| 마지막 자리 확인 | 큰 거듭제곱의 일부 자리만 확인 | `pow(123456789, 987654321, 1000)` |
| 알고리즘 문제 | 매우 큰 경우의 수를 특정 수로 나눈 나머지 | `pow(2, n, 1000000007)` |
| 해시 계산 | 큰 수식을 일정 범위의 대표값으로 압축 | rolling hash의 `base ** k % mod` |
| 암호 알고리즘 | modulo 공간에서 정의된 거듭제곱 연산 | RSA의 `cipher = pow(message, e, n)` |
| 순환 구조 | 값이 일정 범위를 넘어가면 다시 처음으로 순환 | index를 `i % length`로 정리 |

예를 들어 어떤 값의 마지막 세 자리만 필요하면 전체 거듭제곱을 만들 필요가 없다. `% 1000`의 결과는 항상 `0`부터 `999` 사이이므로, `pow(a, b, 1000)`은 `a ** b`의 마지막 세 자리와 같은 값을 준다.

```python
print(pow(7, 5, 1000))  # 7 ** 5 == 16807, 마지막 세 자리 807
```

암호 알고리즘에서는 modulo 연산이 단순히 크기를 줄이는 보조 기능이 아니라, 계산 자체가 modulo 공간 위에서 정의된다. RSA의 기본 형태는 아래처럼 거듭제곱 뒤 modulo를 취하는 구조를 가진다.

```python
cipher = pow(message, e, n)
plain = pow(cipher, d, n)
```

즉 `pow(x, y, z)`는 `x ** y`를 보기 좋게 줄이는 함수라기보다, 큰 거듭제곱을 modulo 공간의 대표값으로 계산하는 함수다.

`round()`는 단순히 항상 `.5`를 위로 올리는 방식으로 외우면 틀릴 수 있다. Python의 `round()`는 정확히 중간인 경우 가까운 짝수 쪽으로 가는 tie-to-even 규칙을 따른다.

```python
print(round(3.5))   # 4
print(round(4.5))   # 4
print(round(-3.5))  # -4
print(round(-4.5))  # -4
```

실수는 binary floating-point로 저장되므로, `round(3.745, 1)` 같은 값은 사람이 보는 십진수와 내부 표현이 정확히 일치하지 않을 수 있다. 금액 계산처럼 십진 정확도가 중요한 영역에서는 `decimal.Decimal` 같은 별도 type을 고려해야 한다.

### `eval()`과 `exec()`

`[5-3]`에서는 문자열을 Python 코드로 해석하는 `eval()`을 다룬다.

```python
print(eval("1 + 2"))
print(eval("'good ' + 'morning'"))
print(eval("max(1, 2, 3)"))
```

`eval()`은 expression을 평가해 object 하나를 반환한다. 여기서 expression은 평가 결과가 하나의 object로 나오는 코드 조각이다.

| 함수 | 이름 의미 | 입력 코드 성격 | 반환 | 예 |
| :--- | :--- | :--- | :--- | :--- |
| `eval()` | evaluate | expression | 평가 결과 object | `eval("1 + 2")` |
| `exec()` | execute | statement 묶음 | `None` | `exec("a = 10")` |

```python
s = "[10, 20, -5]"
l = eval(s)
print(min(l))
```

`eval()`과 `exec()`는 현재 namespace의 name을 사용할 수 있고, 별도의 `globals`, `locals` mapping도 받을 수 있다. 외부 입력 문자열을 그대로 넣으면 임의 코드 실행이 되므로 실제 서비스 코드에서는 매우 위험하다.

`ast.literal_eval()`은 `eval()`에서 기능 몇 개만 끈 보안 옵션이라기보다, Python literal 또는 container display만 해석하는 별도 함수로 보는 편이 정확하다. 공식 문서 기준으로 `ast.literal_eval()`이 허용하는 구조는 string, bytes, number, tuple, list, dict, set, boolean, `None`, `Ellipsis` 같은 literal data다. 반대로 name lookup, 함수 호출, 연산자 계산, indexing처럼 Python 실행 규칙이 필요한 expression은 허용하지 않는다.

| 구분 | `eval()` | `ast.literal_eval()` |
| :--- | :--- | :--- |
| 목적 | Python expression 평가 | literal data 해석 |
| namespace 사용 | 현재 namespace 또는 전달한 `globals`, `locals` 사용 | namespace 사용 없음 |
| name lookup | 가능 | 불가능 |
| 함수 호출 | 가능 | 불가능 |
| 연산자 계산 | 가능 | 불가능 |
| indexing/subscription | 가능 | 불가능 |
| list/dict literal 해석 | 가능 | 가능 |
| 외부 입력 처리 | 임의 코드 실행 위험 | 코드 실행은 하지 않지만 큰 입력에 대한 자원 사용 위험 존재 |

```python
import ast

x = 10

print(eval("x + 1"))              # 11
print(ast.literal_eval("x + 1"))  # ValueError
```

`eval()`은 현재 namespace에서 `x`를 찾고 `+` 연산을 수행한다. `ast.literal_eval()`은 `x + 1`을 literal data로 보지 않으므로 거부한다.

```python
import ast

s = "[1, 2, {'a': 3}]"

print(eval(s))              # [1, 2, {'a': 3}]
print(ast.literal_eval(s))  # [1, 2, {'a': 3}]
```

이 경우는 문자열이 순수한 list/dict literal이므로 둘 다 같은 결과를 낸다. 하지만 아래처럼 함수 호출이 포함되면 차이가 생긴다.

```python
import ast

print(eval("len([1, 2, 3])"))              # 3
print(ast.literal_eval("len([1, 2, 3])"))  # ValueError
```

따라서 문자열이 `[1, 2, 3]`, `{'a': 1}`처럼 data literal 형태일 때 object로 복원하려는 목적이면 `eval()`보다 `ast.literal_eval()`을 우선 검토한다. 다만 공식 문서도 `ast.literal_eval()`을 무조건 안전한 함수로 보지는 않는다. 임의 코드 실행은 하지 않지만, 아주 크거나 복잡한 입력은 memory exhaustion, C stack exhaustion, 과도한 CPU 사용 문제를 만들 수 있으므로 신뢰하지 않는 입력에는 크기 제한과 예외 처리가 필요하다.

관련 공식 문서:

- Python 3.14.6 `eval()`: <https://docs.python.org/3/library/functions.html#eval>
- Python 3.14.6 `exec()`: <https://docs.python.org/3/library/functions.html#exec>
- Python 3.14.6 `ast.literal_eval()`: <https://docs.python.org/3/library/ast.html#ast.literal_eval>

### Container 관련 built-in

`[5-4]`는 container에 적용되는 `len`, `min`, `max`, `sum`, `sorted`를 비교한다.

```python
t1 = (1, 4, 2, 3)
t2 = ((1, 2, 3), (1, 3), (0,))
l1 = [1, 4, 2, 3]
l2 = ("kim", "ko", "han")
```

| 함수 | 이름 의미 | 대상 | 반환 | 주의 |
| :--- | :--- | :--- | :--- | :--- |
| `len(x)` | length | sized object | item 개수 | 중첩 container는 바깥 item 수만 계산 |
| `min(x)` | minimum | iterable | 최솟값 | item끼리 비교 가능해야 함 |
| `max(x)` | maximum | iterable | 최댓값 | tuple/string은 lexicographic 비교 |
| `sum(x)` | summation | numeric iterable | 합계 | 문자열 합치기에는 부적합 |
| `sum(x, start)` | summation from start | numeric iterable + 시작값 | `start`부터 누적 | tuple flatten 예제 가능 |
| `sorted(x)` | sorted result | iterable | 새 `list` | 원본 container type과 무관하게 list 반환 |
| `sorted(x, reverse=True)` | sorted in reverse order | iterable | 역순 정렬 list | 원본은 보통 유지 |

`sorted()`는 정렬된 list를 새로 만든다.

```python
x1 = sorted((1, 4, 2, 3))
print(type(x1), x1)  # <class 'list'> [1, 2, 3, 4]
```

`sum(t2, ())`처럼 tuple을 시작값으로 주면 tuple들을 이어 붙이는 결과를 만들 수 있다. 다만 큰 데이터에서 sequence 덧셈 반복은 매번 새 sequence를 만들 수 있어 비효율적이다.

```python
t2 = ((1, 2, 3), (1, 3), (0,))
print(sum(t2, ()))  # (1, 2, 3, 1, 3, 0)
```

### Sequence method: `index()`와 `count()`

`[5-5]`는 sequence type의 공통 method인 `index`, `count`를 확인한다.

| Method | 이름 의미 | 의미 | 예 |
| :--- | :--- | :--- | :--- |
| `seq.index(x)` | index 위치 | `x`가 처음 나오는 index 반환 | `t.index(3)` |
| `seq.index(x, start)` | index 위치 | `start`부터 검색 | `t.index(3, 2)` |
| `seq.index(x, start, stop)` | index 위치 | `[start, stop)` 범위 검색 | `t.index(3, 3, 5)` |
| `seq.count(x)` | count 개수 | `x` 출현 횟수 | `t.count(3)` |

```python
t = (1, 2, 3, 4, 5, 1, 2, 3)

print(t.index(3))       # 2
print(t.index(3, 3, 5)) # ValueError
print(t.count(3))       # 2
```

`index()`는 찾지 못하면 `ValueError`를 발생시킨다. 값이 없을 수도 있는 입력이라면 `in`으로 먼저 확인하거나 예외 처리를 해야 한다.

### Lookup 구조: tuple index와 dict key

`[5-6]`, `[5-7]`은 과일 이름으로 가격을 찾는 두 방식을 비교한다.

```python
f = ("apple", "banana", "mango", "pineapple", "orange")
p = (1000, 800, 2000, 5200, 400)

f_input = input()
f_index = f.index(f_input)
print(p[f_index])
```

tuple 두 개를 나란히 두는 방식은 `f.index()`로 위치를 찾고 같은 index의 가격을 읽는다. data가 작을 때는 이해하기 쉽지만, 이름과 가격의 관계가 두 container에 분산된다.

```python
d = {
    "apple": 1000,
    "banana": 800,
    "mango": 2000,
    "pineapple": 5200,
    "orange": 400,
}

f_input = input()
print(d[f_input])
```

dict는 key에서 value로 바로 mapping한다. fruit name이 key이고 price가 value이므로, 의미와 자료구조가 더 직접적으로 맞는다.

| 방식 | 조회 기준 | 장점 | 주의 |
| :--- | :--- | :--- | :--- |
| tuple 2개 | `index` 위치 | 순서 관계 확인에 좋음 | 없는 값이면 `ValueError` |
| dict | key | lookup 의도 명확 | 없는 key면 `KeyError` |

### `map()`

`[5-8]`, `[5-9]`, `[5-14]`는 `map()`을 다룬다. `map`은 각 item을 어떤 function에 'mapping'한다는 의미다. `map(function, iterable, ...)`은 iterable에서 값을 꺼내 function에 적용하는 iterator를 만든다.

```python
f = (3.14, -5.625, 100.4, 25.8)
m = map(round, f)

print(type(m)) # <class 'map'>
print(*m)
```

`map` object는 list가 아니라 iterator다. 필요할 때 하나씩 값을 계산하고, 한 번 소비하면 다시 처음으로 돌아가지 않는다.

```python
t = map(int, input().split())
print(sum(t))
print(sum(t))  # 이미 소비되어 보통 0
```

여러 iterable을 넘기면 각 iterable에서 같은 위치의 값을 꺼내 function에 전달한다. 가장 짧은 iterable이 끝나면 멈춘다.

```python
v = (10, 4, 2, -10)
e = (2, 3, 4, 2)

m = map(pow, v, e)
print(*m)  # 100 64 16 100
```

입력값을 모두 정수로 바꿔 합산하는 패턴은 다음처럼 이어진다.

```python
print(sum(map(int, input().split())))
```

이 한 줄은 다음 단계를 압축한 것이다.

```text
input()으로 문자열 한 줄 입력
    ↓
split()으로 문자열 list 생성
    ↓
map(int, ...)으로 각 문자열을 integer instance로 생성하는 iterator 생성
    ↓
sum()이 iterator를 소비하며 합산
```

### `filter()`

`filter()`는 iterable에서 조건을 통과한 item만 남기는 iterator를 만든다. 기본 형태는 `filter(function, iterable)`이고, 각 item에 대해 `function(item)`을 호출한 결과가 truthy인 item만 통과시킨다.

```python
nums = [0, 1, 2, 3, 4, 5, 6]

def is_even(n):
    return n % 2 == 0

result = filter(is_even, nums)

print(type(result))  # <class 'filter'>
print(list(result))  # [0, 2, 4, 6]
```

`lambda`를 사용하면 짧은 조건 함수를 바로 전달할 수 있다.

```python
nums = [1, 2, 3, 4, 5]

result = filter(lambda x: x >= 3, nums)

print(list(result))  # [3, 4, 5]
```

첫 번째 인자로 `None`을 전달하면 별도의 조건 함수를 호출하지 않고 item 자체의 truth value로 거른다.

```python
values = [0, 1, "", "python", [], [1, 2], None, True, False]

result = filter(None, values)

print(list(result))  # [1, 'python', [1, 2], True]
```

`filter` object도 `map` object처럼 list가 아니라 iterator다. 한 번 소비하면 다시 처음부터 사용할 수 없다.

```python
nums = [1, 2, 3, 4]

f = filter(lambda x: x > 2, nums)

print(list(f))  # [3, 4]
print(list(f))  # []
```

같은 조건 걸러내기는 list comprehension으로도 자주 작성한다.

```python
nums = [1, 2, 3, 4]

result = [x for x in nums if x > 2]

print(result)  # [3, 4]
```

| 방식 | 반환 | 평가 방식 | 쓰기 좋은 경우 |
| :--- | :--- | :--- | :--- |
| `filter(function, iterable)` | `filter` iterator | 필요할 때 하나씩 조건 검사 | iterator pipeline 유지 |
| `filter(None, iterable)` | `filter` iterator | item 자체의 truth value 사용 | falsy 값 제거 |
| `[x for x in iterable if condition]` | `list` | list를 즉시 생성 | 결과를 여러 번 사용 |

핵심은 `filter`가 '조건 함수로 걸러낸다'는 점이다. 반면 list comprehension은 '조건을 만족하는 item으로 새 list를 만든다'는 형태가 코드에 직접 드러난다.

### `zip()`과 `dict(zip(...))`

`[5-10]`, `[5-11]`은 여러 iterable을 같은 index끼리 묶는 `zip()`을 다룬다. `zip`은 zipper처럼 여러 줄의 data를 같은 위치끼리 맞물려 묶는다는 의미로 이해하면 된다.

```python
r = (52, 255, 39, 132)
g = (19, 63, 227, 197)
b = (0, 68, 255, 187)

img = list(zip(r, g, b))
print(img)
```

결과는 RGB channel을 pixel tuple로 묶은 list가 된다.

```text
[(52, 19, 0), (255, 63, 68), (39, 227, 255), (132, 197, 187)]
```

`dict(zip(keys, values))`는 key iterable과 value iterable을 묶어 mapping을 만든다. `dict`는 `dictionary`의 약어이고, key로 value를 찾는 mapping type이다.

```python
f = ("apple", "orange", "banana", "mango")
p = (100, 80, 120, 90)

tag = dict(zip(f, p))
print(tag)
```

`zip()`도 iterator를 반환한다. 출력하거나 list/dict로 변환하면 소비된다.

### `enumerate()`

`[5-12]`, `[5-13]`은 iterable의 item과 index를 함께 얻는 `enumerate()`를 다룬다. `enumerate`는 '하나씩 번호를 매겨 나열하다'라는 뜻이므로, item에 순번을 붙이는 함수 이름으로 보면 된다.

```python
t = ("kim", "lee", "park")

print(*enumerate(t))
print(*enumerate(t, 10))
```

`enumerate(t)`는 `(index, item)` pair를 생성한다. `start`를 지정하면 시작 번호를 바꿀 수 있다.

| 표현 | 생성되는 pair |
| :--- | :--- |
| `enumerate(t)` | `(0, "kim")`, `(1, "lee")`, `(2, "park")` |
| `enumerate(t, 10)` | `(10, "kim")`, `(11, "lee")`, `(12, "park")` |

`enumerate(t)`는 학습 관점에서 `zip(range(len(t)), t)`처럼 이해할 수 있다. 두 표현이 같은 object를 만드는 것은 아니지만, 위 예제처럼 생성되는 pair의 값은 같다.

```python
t = ("kim", "lee", "park")

x1 = zip(range(len(t)), t)
x2 = enumerate(t)
x3 = enumerate(t, 10)

print(type(x1))  # <class 'zip'>
print(type(x2))  # <class 'enumerate'>

print(*x1)  # (0, 'kim') (1, 'lee') (2, 'park')
print(*x2)  # (0, 'kim') (1, 'lee') (2, 'park')
print(*x3)  # (10, 'kim') (11, 'lee') (12, 'park')
```

`start` 값을 지정한 `enumerate(t, start)`는 개념적으로 `zip(range(start, start + len(t)), t)`처럼 index 시작값을 바꿔 item과 묶는 형태다. 그래서 `enumerate()`는 `range`와 `zip`을 직접 조합하지 않고, 'index 생성 + item 묶기'를 한 번에 표현하는 전용 built-in으로 볼 수 있다.

fruit에 일련번호를 붙여 dict로 만들 때는 다음처럼 쓴다.

```python
f = ("apple", "orange", "banana", "mango")
tag = dict(enumerate(f, start=1))
print(tag)
```

### Iterator는 한 번 흐르는 object

`[5-15]`, `[5-16]`의 핵심은 `map`, `filter`, `zip`, `enumerate`가 결과를 한 번에 모두 담은 container가 아니라 iterator라는 점이다.

```python
x = map(int, [3.14, -5.25, -128])
y = map(abs, x)

print("[1]", *x)
print("[2]", *y)
```

위 구조에서 `y`는 `x`에서 값을 꺼내 `abs()`를 적용한다. 그런데 먼저 `*x`로 `x`를 모두 소비하면, `y`가 사용할 원소가 남지 않는다.

```text
x: map(int, source)
    ↓
y: map(abs, x)
    ↓
둘 다 같은 흐름 위에 연결된 iterator pipeline
```

iterator를 여러 번 사용해야 한다면 `list()`나 `tuple()`로 materialize한다.

```python
values = list(map(int, input().split()))

print(max(values))
print(values.index(max(values)) + 1)
```

### 최대값, 중복 제거, 정렬

`[5-17]`부터 `[5-20]`은 입력값을 container로 만든 뒤 built-in 함수와 method를 연결하는 예제다.

최대값과 위치를 모두 구하려면 iterator를 바로 소비하지 말고 list로 보관하는 편이 안전하다.

```python
val = list(map(int, input().split()))

max_val = max(val)
max_pos = val.index(max_val) + 1

print(max_val)
print(max_pos)
```

중복 제거는 `set()`으로 처리한다.

```python
n_name = set(input().split())
print(len(n_name))
```

`set`은 중복 제거에는 좋지만 순서 보장이 필요한 결과에는 맞지 않는다. 순서를 유지해야 하면 별도의 처리 방식을 써야 한다.

정렬은 `sorted()`를 사용한다.

```python
n = list(map(int, input().split()))
print(sorted(n))
print(sorted(n, reverse=True))
```

`sorted()`는 새 list를 반환한다. 원본 list 자체를 바꾸고 싶으면 `list.sort()` method를 사용한다.

## 6. 사용자 정의 함수

### `def` 문과 function object

`[6-1]`은 함수 정의와 호출을 확인한다. `def` 문은 function object를 만들고, 함수 이름을 그 object에 binding한다.

```python
def func2():
    print("func2")

func2()
```

함수 body는 정의 시점에 실행되지 않고, 함수 object가 호출될 때 실행된다.

```text
def 문 실행
    ↓
function object 생성
    ↓
function name binding
    ↓
호출식 func2() 실행 시 body 실행
```

한 줄 함수 정의도 가능하지만, body가 늘어날 가능성과 debug 편의성을 생각하면 일반 block 형태가 낫다.

```python
def func1():
    print("func1")
```

### `return`

`[6-1]`, `[6-2]`, `[6-4]`, `[6-5]`는 `return`을 다룬다.

`return`은 함수를 즉시 종료하고 호출한 위치로 값을 돌려준다.

```python
def func4():
    print("func4-1")
    return
    print("func4-2")
```

`return` 뒤의 코드는 실행되지 않는다. `return`만 쓰거나 `return` 없이 함수 끝에 도달하면 반환값은 `None`이다.

```python
def f():
    print("hello")

print(f())  # None
```

값을 반환하는 함수는 호출식 자체가 반환값 object로 평가된다.

```python
def func(a):
    print(a)
    return a + 1

x = func(20)
print(x)
```

`return` 식이 여러 개처럼 보이면 tuple packing이 일어난다.

```python
def calc(a, b):
    return a + b, a - b, a * b, a // b

result = calc(10, 3)
print(result)       # (13, 7, 30, 3)
```

따라서 여러 값을 반환한다는 표현은 실제로는 하나의 tuple object를 반환한다고 이해하면 정확하다.

### Parameter와 argument

`[6-3]`에서는 parameter와 argument를 구분한다.

| 용어 | 위치 | 의미 |
| :--- | :--- | :--- |
| parameter | 함수 정의부 | 함수 내부에서 사용할 local name |
| argument | 함수 호출부 | parameter에 binding할 실제 object |

한글 용어는 자료마다 조금씩 섞여 쓰이므로, 이 노트에서는 아래 기준으로 읽는다.

| 영어 용어 | 권장 한글 | 위치 | Python 예시 | 메모 |
| :--- | :--- | :--- | :--- | :--- |
| parameter | 매개변수 | 함수 정의부 | `def add(a, b):`의 `a`, `b` | 함수가 받을 local name |
| formal parameter | 형식 매개변수 | 함수 정의부 | `a`, `b` | C/C++ 교재에서 자주 쓰는 표현 |
| argument | 인수, 전달인자 | 함수 호출부 | `add(10, 20)`의 `10`, `20` | 매개변수에 전달되는 실제 object |
| actual argument | 실제 인수 | 함수 호출부 | `10`, `20` | formal parameter와 대비되는 표현 |
| positional argument | 위치 인수 | 함수 호출부 | `add(10, 20)` | 위치 순서로 parameter에 binding |
| keyword argument | 키워드 인수 | 함수 호출부 | `add(a=10, b=20)` | parameter 이름으로 binding |
| 인자 | 문맥 의존 | 정의부 또는 호출부 | 자료마다 다름 | parameter/argument 양쪽에 섞여 쓰이는 경우 많음 |

따라서 엄밀하게 구분할 때는 `parameter`를 `매개변수`, `argument`를 `인수` 또는 `전달인자`로 읽는 편이 안전하다. `인자`라는 단어는 한국어 자료에서 매우 자주 쓰이지만, 어떤 자료에서는 parameter를 뜻하고 다른 자료에서는 argument를 뜻하기 때문에 문맥을 확인해야 한다.

| 언어/문맥 | `parameter` 쪽 표현 | `argument` 쪽 표현 | 주의 |
| :--- | :--- | :--- | :--- |
| Python 공식 문서 | parameter | argument | parameter kind와 argument kind를 명확히 구분 |
| Python 한국어 학습 자료 | 매개변수, 파라미터 | 인수, 인자, 전달인자 | `인자`가 argument 의미로 많이 사용 |
| C/C++ 교재 | 형식 매개변수, 매개변수 | 실인수, 실제 인수 | formal parameter와 actual argument 대비 |
| Java/C# 계열 | parameter | argument | Python과 큰 흐름 유사 |
| SystemVerilog/HDL | parameter는 module compile-time 설정값 의미도 강함 | task/function argument, actual 값 | `parameter`가 함수 매개변수보다 module parameter 의미로 자주 등장 |
| Shell/CLI | parameter, option, flag 혼용 | command-line argument | `argv` 항목 전체를 argument로 보는 경우 많음 |

예를 들어 아래 코드에서 `a`, `b`는 function object가 호출될 때 local namespace에 생기는 parameter name이고, `10`, `20`은 호출 시 전달되는 argument object다.

```python
def func2(a, b):
    c = a + b
    print("func2", a, b, c)

func2(30, 40)
func2("kim", "lew")
func2([1, 2, 3], [4, 5, 6])
```

`func2(a=30, b=40)`처럼 호출하면 `a=30`, `b=40`은 keyword argument다. 여기서 `a`, `b`는 여전히 parameter 이름이고, `30`, `40`이 parameter에 binding되는 argument object다.

같은 `+` 연산도 argument object의 type에 따라 다르게 동작한다. 숫자면 덧셈이고, 문자열/list면 연결이다.

```python
func2("kim", 10)  # TypeError
```

문자열과 정수처럼 서로 맞지 않는 type에는 같은 연산자를 적용할 수 없다.

### 예제: 문자열 복제기

`[6-6]`은 문자열과 반복 횟수를 받아 새 문자열을 반환한다.

```python
def string_repeat(s, n):
    x = s * n
    return x

y = string_repeat("kim", 2)
print(y)
print(string_repeat("hello", 3))
```

`s * n`은 sequence 반복 연산이다. `s`가 문자열이고 `n`이 정수이면 같은 문자열을 `n`번 이어 붙인 새 문자열 object가 만들어진다.

### Local namespace와 assignment

`[6-7]`은 함수 내부에서 전역 변수처럼 보이는 이름에 값을 대입하려 할 때 생기는 문제를 보여 준다.

```python
cnt = 0

def func():
    cnt += 1

func()
```

함수 body 안에 `cnt += 1` 같은 assignment가 있으면, Python은 `cnt`를 local name으로 판단한다. 그런데 `cnt += 1`은 기존 `cnt` 값을 먼저 읽은 뒤 새 값을 다시 binding해야 한다. local namespace에는 아직 `cnt`가 없으므로 `UnboundLocalError`가 발생한다.

```text
cnt += 1
    ↓
cnt = cnt + 1 과 유사한 read-then-write
    ↓
assignment가 있으므로 cnt는 local name으로 분석
    ↓
local cnt를 읽으려 하지만 아직 binding 없음
    ↓
UnboundLocalError
```

### `global`

`[6-8]`은 함수 내부 assignment target을 global namespace에 연결하는 `global`을 다룬다.

```python
def f2():
    global a
    global b
    a = 10
    b = 20
    c = 30 + d
    print(a, b, c)

a, c, d = 1, 3, 5
print(a)
f2()
print(a, b, c)
```

`global a`는 이 함수 내부에서 `a`에 대한 assignment가 local namespace가 아니라 module global namespace를 대상으로 한다는 선언이다. `b`도 `global b`가 있으므로 함수 호출 뒤 global namespace에 새로 생길 수 있다. 반면 `c = 30 + d`의 `c`는 local name이고, 오른쪽의 `d`는 local에 없으므로 global namespace에서 읽는다.

| 이름 | 함수 내부 동작 | 결과 |
| :--- | :--- | :--- |
| `a` | `global a` 이후 assignment | global `a` 변경 |
| `b` | `global b` 이후 assignment | global `b` 생성/변경 |
| `c` | 함수 내부 assignment | local `c` |
| `d` | 읽기만 수행 | local에 없으면 global에서 검색 |

`global`은 가능한 적게 쓰는 편이 좋다. 함수는 입력 argument를 받고 return value를 돌려주는 형태가 재사용과 테스트에 유리하다.

### Immutable argument와 mutable argument

`[6-9-1]`, `[6-9-2]`는 argument 전달을 확인한다. Python은 object 자체를 복사해서 parameter에 넣는 것이 아니라, argument object에 대한 reference를 parameter name에 binding한다.

immutable object 예제는 다음과 같다.

```python
def f1(a):
    a = 100
    print(a)

a = 10
f1(a)
print(a)
```

함수 안의 `a = 100`은 local name `a`를 새 `int` object에 다시 binding한다. 호출한 쪽의 global `a`가 가리키던 `10` object는 바뀌지 않는다.

mutable object 예제는 다음과 같다.

```python
def f2(x):
    x[0] = 100
    x.append(200)
    print(x)

b = [1, 2, 3, 4]
f2(b)
print(b)
```

`x`와 `b`는 같은 list object를 가리킨다. 함수 안에서 `x[0] = 100`, `x.append(200)`처럼 list object 내부 상태를 바꾸면 호출한 쪽에서도 같은 변경이 보인다.

| 함수 내부 동작 | 의미 | caller 쪽 영향 |
| :--- | :--- | :--- |
| `a = 100` | local name 재binding | caller name 영향 없음 |
| `x = [100]` | local name 재binding | caller list 영향 없음 |
| `x[0] = 100` | 같은 list object 내부 item 변경 | caller list 변경 |
| `x.append(200)` | 같은 list object method 호출 | caller list 변경 |

핵심은 immutable/mutable이라는 단어보다, 함수 내부에서 name을 다시 binding하는지 object 내부 상태를 mutate하는지다.

### `locals()`와 `globals()`

`[6-10]`에서는 namespace를 직접 확인한다.

```python
import pprint as pp

msg = "happy"

def func(a, b):
    c = a + b
    pp.pprint(locals())
    return c

print(dir(__builtins__))
pp.pprint(globals())
print(func(10, 20))
```

| 함수/표현 | 의미 |
| :--- | :--- |
| `locals()` | 현재 local namespace mapping 확인 |
| `globals()` | 현재 module global namespace mapping 확인 |
| `dir(__builtins__)` | built-in namespace에서 제공하는 이름 확인 |

함수 안에서 `locals()`를 보면 parameter `a`, `b`와 local variable `c`가 보인다. module level에서 `globals()`를 보면 현재 파일의 global name들이 보인다.

### Positional-or-keyword parameter

`[6-11]`의 기본 함수 parameter는 positional argument로도, keyword argument로도 받을 수 있다.

```python
def func(a, b):
    print("%d, %d" % (a, b))

func(10, 20)
func(a=10, b=20)
func(b=10, a=20)
func(10, b=20)
```

| 호출 | 해석 |
| :--- | :--- |
| `func(10, 20)` | `a=10`, `b=20` |
| `func(a=10, b=20)` | keyword로 직접 binding |
| `func(b=10, a=20)` | keyword 이름 기준 binding |
| `func(10, b=20)` | `a`는 positional, `b`는 keyword |

keyword argument 뒤에 positional argument를 둘 수 없고, 같은 parameter에 두 번 값을 줄 수도 없다.

```python
func(a=10, 20)  # SyntaxError
func(20, a=10)  # TypeError
```

### Default parameter

`[6-12]`, `[6-13]`은 default parameter를 다룬다.

```python
def func(a, b, c=300, d=400):
    print("%d, %d, %d, %d" % (a, b, c, d))

func(10, 20)
func(10, 20, 30)
func(a=10, b=20, d=40)
```

default가 있는 parameter는 호출 시 argument를 생략할 수 있다. 생략되면 함수 정의 시 지정한 default object가 사용된다.

| 정의 | 가능 여부 | 이유 |
| :--- | :--- | :--- |
| `def f(a, b, c=300, d=400)` | 가능 | non-default 뒤에 default 배치 |
| `def f(a, b=200, c)` | 불가 | default parameter 뒤에 non-default parameter |

default parameter의 default value는 함수 호출 때마다 새로 평가되는 것이 아니라 function object가 만들어질 때 평가된다. mutable default를 쓰면 호출 사이에 같은 object가 공유될 수 있으므로 주의한다.

```python
def append_item(x, bucket=[]):
    bucket.append(x)
    return bucket
```

이런 구조는 학습용으로는 mutable default의 위험을 확인할 수 있지만, 실제 코드에서는 보통 `None`을 default로 두고 함수 안에서 새 list를 만든다.

### Keyword-only parameter

`[6-14]`, `[6-15]`는 `*` 뒤의 parameter가 keyword-only가 되는 규칙을 확인한다.

```python
def func(*, a, b=200, c):
    print("%d, %d, %d" % (a, b, c))

func(a=10, b=20, c=30)
func(c=30, b=20, a=10)
func(a=10, c=30)
```

`*` 뒤에 있는 `a`, `b`, `c`는 positional argument로 받을 수 없다.

```python
func(10, 20, 30)  # TypeError
```

positional-or-keyword parameter와 keyword-only parameter를 섞을 수도 있다.

```python
def func(a, b=200, *, c, d=400, e):
    print("%d, %d, %d, %d, %d" % (a, b, c, d, e))

func(10, 20, c=30, d=40, e=50)
func(10, e=50, c=30)
func(e=50, c=30, a=10)
```

| Parameter 종류 | 예 | Argument 전달 |
| :--- | :--- | :--- |
| positional-or-keyword | `a` | positional 또는 keyword |
| default positional-or-keyword | `b=200` | 생략 가능, positional 또는 keyword |
| keyword-only | `c`, `e` | keyword로만 전달 |
| default keyword-only | `d=400` | 생략 가능, keyword로만 전달 |

Keyword-only parameter는 호출부의 의미를 명확히 하고, argument 순서 착각으로 인한 버그를 줄이는 데 유용하다.

## 정리

5장의 핵심은 built-in 함수가 단순 편의 함수가 아니라 iterable, iterator, mapping, sequence method와 연결되어 Python다운 data 처리 흐름을 만든다는 점이다. 특히 `map`, `filter`, `zip`, `enumerate`는 결과 container가 아니라 iterator이므로 한 번 소비하면 다시 사용할 수 없다는 점을 기억해야 한다.

6장의 핵심은 함수 정의가 function object 생성과 name binding이라는 점이다. parameter는 호출 시 argument object에 binding되는 local name이고, 함수 내부 assignment는 local namespace를 만든다. mutable object를 전달했을 때는 name 재binding과 object mutation을 구분해야 한다.
