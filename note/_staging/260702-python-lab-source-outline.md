# Python 실습자료 후속 범위 대기 메모

원본 위치:

`/Users/mumallaeng/Library/CloudStorage/GoogleDrive-yonnmilk@gmail.com/My Drive/Classroom/대한상공회의소_반도체설계/김은경/상공회의소_KDT_실습자료(C_Python_M4)/2.Python/Py_Lab_for_VS_Code.py`

Python 실습자료는 `Py_Lab_for_VS_Code.py`에 예제 block을 순서대로 모아 둔 구조다. 1장부터 6장까지는 날짜별 본노트로 옮겼으므로, 이 staging 파일에는 아직 본노트로 확정하지 않은 범위만 남긴다. 보조 모듈은 `my_module.py`, `your_module.py`, `my_package/` 아래에 있으며, 11장 import/package 예제와 연결된다.

## 수업 흐름

| 범위 | 주제 | 핵심 |
| :--- | :--- | :--- |
| `[A-1]`~`[A-2]` | 성능 비교 | 직접 loop와 `sum(range())` 비교 |
| `[8-1]`~`[8-15]` | 비교, generator, comprehension | 비교 연산, `all`, `any`, generator expression, comprehension |
| `[9-1]`~`[9-25]` | 조건문과 반복문 | `if`, `elif`, `pass`, `for`, 별찍기, `break`, `continue`, `while` |
| `[10-1]`~`[10-15]` | list/set/dict 실습 | list method, 자리 배치, set 연산, 문자별 횟수 |
| `[11-13]`~`[11-21]` | 예외와 import | `try/except`, `else`, `finally`, module import, package import |
| `[12-1]`~`[12-17]` | class | class/instance, 생성자, 소멸자, special method, 상속, overriding |

## A. 같은 합계도 구현 방식에 따라 다르다

`[A-1]`, `[A-2]`는 0부터 천만까지의 합을 구하는 두 방식을 비교한다. 직접 `for` loop를 돌며 `tot += i`를 수행하는 방식과 `sum(range())`를 사용하는 방식이다.

```python
tot = 0
for i in range(10000001):
    tot += i
```

```python
tot = sum(range(10000001))
```

Python에서는 같은 결과를 내는 code라도 built-in 함수와 iterator를 적절히 쓰면 더 간결하고 빠를 수 있다. `datetime.datetime.now()`로 시작/종료 시각을 기록해 실행 시간을 비교하는 구조도 함께 확인한다.

차이가 나는 핵심 이유는 Python code가 반복문을 직접 돌 때마다 interpreter 비용을 계속 내기 때문이다. Interpreter는 명령 줄 또는 bytecode를 실행하면서 매 반복마다 object 조회, type 확인, 산술 연산, name binding, loop 제어를 처리한다. 반면 compiler 기반 언어는 사용자 code를 기계어 또는 더 낮은 수준의 code로 번역한 뒤 실행하므로, 반복문 전체에 대한 최적화를 적용하기 유리하다.

`for i in range(10000001): tot += i`는 반복마다 Python level에서 `i`를 꺼내고, `tot + i`를 계산하고, 결과를 다시 `tot`에 binding한다. 이 과정이 천만 번 반복되므로 interpreter overhead가 크게 누적된다.

`sum(range(10000001))`은 Python built-in 함수인 `sum()`을 사용한다. CPython에서 built-in 함수의 핵심 동작은 C로 구현되어 있으므로, 반복과 누적의 많은 부분이 Python bytecode 한 줄씩이 아니라 C code 내부에서 처리된다. 그래서 같은 합계를 구하더라도 직접 Python loop를 작성하는 것보다 빠른 경우가 많다.

| 방식 | 처리 위치 | 속도 차이 원인 |
| :--- | :--- | :--- |
| `for` + `tot += i` | Python level 반복 | 매 반복마다 interpreter overhead 발생 |
| `sum(range(...))` | built-in 함수 내부 | C 구현 경로 사용, Python 반복 overhead 감소 |

`range()`는 천만 개의 값을 담은 list를 먼저 만드는 것이 아니라, 필요한 값을 순서대로 만들어 주는 iterable object다. 따라서 `sum(range(...))`은 memory 측면에서도 큰 list를 직접 만드는 방식보다 효율적이다.

## 8. 비교, generator, comprehension

### 8.1 비교와 포함 관계

`[8-1]`은 수치 비교, 문자열 비교, membership, identity 비교를 한 번에 다룬다.

| 표현 | 의미 |
| :--- | :--- |
| `a == b` | 값 비교 |
| `x in container` | 포함 여부 |
| `a is b` | 같은 object identity 여부 |
| `a is not b` | 다른 object identity 여부 |

`==`는 값의 같음을 비교하고, `is`는 같은 object인지 비교한다. 작은 정수나 interned 문자열에서 우연히 `is`가 참처럼 보일 수 있지만, 값 비교에는 `==`를 사용해야 한다.

### 8.2 `all`, `any`, generator expression

`[8-3]`은 `all()`과 `any()`를 다룬다. `all()`은 모든 item이 truthy일 때 참이고, `any()`는 하나라도 truthy이면 참이다.

`[8-4]`, `[8-5]`는 generator expression이다.

```python
squares = (x * x for x in t if x > 0)
```

generator는 값을 한 번에 모두 만들지 않고 필요할 때 하나씩 만든다. `print(*gen)`처럼 한 번 펼치면 그 iterator는 소비된다.

### 8.3 `lambda`, `map`, comprehension

`[8-7-1]`, `[8-7-2]`는 같은 제곱 list를 `lambda + map`과 generator/list comprehension으로 만드는 방법을 비교한다.

```python
l = list(map(lambda x: x * x, t))
l = [x * x for x in t]
```

`[8-11]`은 list/set/dict comprehension을 다룬다. comprehension은 반복과 조건을 식 안에 넣어 새 container를 만드는 표현이다.

`[8-14]`, `[8-15]`는 다차원 list 생성에서 `[[0] * 3] * 4`와 `[[0 for j in range(3)] for i in range(4)]`의 차이를 다룬다. 앞의 방식은 내부 list를 공유할 수 있으므로 한 행을 바꾸면 여러 행이 같이 바뀐다.

## 9. 조건문과 반복문

### 9.1 `if`, `elif`, `pass`

`[9-1]`부터 `[9-8]`은 조건문을 다룬다. Python도 조건식이 truthy/falsy로 평가된다. 빈 block은 허용되지 않으므로 아직 구현하지 않을 block에는 `pass`를 둔다.

```python
if condition:
    pass
else:
    print("else")
```

`elif`는 여러 조건 중 하나만 선택될 때 사용한다. 여러 개의 독립적인 `if`와 달리, 앞 조건이 참이면 뒤 조건은 검사하지 않는다.

### 9.2 `for`, target unpack, 이중 loop

`[9-9]`부터 `[9-17]`은 iterable을 순회하는 `for`문이다.

```python
for i, x in enumerate('ABCD'):
    print(i, x)
```

Python의 `for`는 index 기반 반복이라기보다 iterable에서 item을 하나씩 꺼내 target에 binding하는 구조다. target unpack을 사용하면 tuple/list item을 바로 여러 변수로 나눠 받을 수 있다.

별찍기 `[9-15-1]`부터 `[9-15-5]`는 C의 중첩 loop와 같은 사고방식으로 접근한다. 행을 기준으로 공백 개수와 출력 문자 개수를 계산한다.

### 9.3 `break`, `continue`, `while`

`[9-18]`은 `break`, `continue`의 동작을 다룬다.

```python
for i in range(10):
    if i > 7:
        break
    if not i % 3:
        continue
    print(i)
```

`break`는 가장 가까운 반복문을 종료하고, `continue`는 현재 회차의 남은 code를 건너뛰고 다음 회차로 넘어간다.

`[9-21]`은 `for ~ else`를 이용한 소수 판별이다. 반복문에서 `break`가 발생하지 않고 정상 종료되면 `else`가 실행된다.

`[9-23-1]`부터 `[9-25]`는 `while` 구조다. 특정 조건이 만족될 때까지 입력을 반복하거나, `while True`와 내부 `break`로 무한 loop를 제어할 수 있다.

## 10. list, set, dict 실습

`[10-1]`은 list method를 확인한다.

| method | 의미 |
| :--- | :--- |
| `append` | 끝에 item 추가 |
| `insert` | 특정 위치에 item 삽입 |
| `extend` | iterable item들을 이어 붙임 |
| `remove` | 값으로 item 제거 |

`[10-11]`부터 `[10-13]`은 set 연산을 다룬다. 교집합, 합집합, 차집합으로 학생 명단 문제를 해결할 수 있다.

`[10-15]`는 문자별 횟수 세기다. dict를 사용해 문자를 key로, 등장 횟수를 value로 관리한다.

```python
count = {}
for ch in text:
    count[ch] = count.get(ch, 0) + 1
```

## 11. 예외와 import

### 11.1 예외 처리

`[11-13]`부터 `[11-17-2]`는 `try ~ except`를 다룬다.

```python
try:
    n = int(input())
except ValueError as e:
    print(e)
else:
    print("success")
finally:
    print("done")
```

| 구문 | 실행 시점 |
| :--- | :--- |
| `try` | 예외 발생 가능 code |
| `except` | 지정 예외 발생 시 |
| `else` | 예외 없이 성공 시 |
| `finally` | 성공/실패와 무관하게 항상 |

광범위한 `except Exception:`은 모든 오류를 감출 수 있으므로, 학습 목적이 아니라면 가능한 구체적인 예외를 잡는 편이 좋다.

### 11.2 module과 package

`[11-18]`부터 `[11-21]`은 module import와 package import를 다룬다.

| 파일 | 역할 |
| :--- | :--- |
| `my_module.py` | `add`, `sub` 같은 module import 대상 |
| `your_module.py` | alias import 대상 |
| `my_package/my_module.py` | package 안 module import 대상 |
| `my_package/files/my_module2.py` | `sys.path` 조정 후 import 대상 |

`import module`은 module 이름을 통해 접근하고, `from module import name`은 특정 name을 현재 namespace로 가져온다. 두 방식은 namespace 충돌 가능성과 호출 형태가 다르다.

## 12. Class

### 12.1 함수형 계산기에서 class 구조로

`[12-1]`부터 `[12-3]`은 함수로 작성한 계산기를 class 기반 구조로 옮기며 class의 필요성을 보여 준다. class는 데이터와 동작을 함께 묶는 방법이다.

```python
class Calculator:
    def __init__(self):
        self.total = 0

    def add(self, value):
        self.total += value
```

`self`는 method를 호출한 instance 자신을 가리키는 parameter다.

### 12.2 instance 변수, 생성자, 소멸자

`[12-4]`부터 `[12-10]`은 class variable, instance variable, `__init__`, `__del__`을 다룬다. `__init__`은 instance 생성 직후 초기화에 사용하고, instance별 상태는 `self.name` 형태로 저장한다.

임대 수량 관리 예제는 class variable을 통해 전체 instance 수를 추적하는 흐름과 연결된다.

### 12.3 special method, 상속, class/static method

`[12-11]`, `[12-12]`는 special method를 이용해 연산자와 built-in 함수 동작을 class에 맞게 정의하는 예제다.

`[12-13]`부터 `[12-16]`은 상속과 overriding을 다룬다. child class는 parent class의 기능을 물려받고, 필요한 method를 새로 정의해 동작을 바꿀 수 있다.

`[12-17]`은 class method와 static method를 다룬다.

| method 종류 | 첫 parameter | 용도 |
| :--- | :--- | :--- |
| instance method | `self` | instance 상태 사용 |
| class method | `cls` | class 상태 사용 |
| static method | 없음 | class namespace에 묶인 일반 함수 |

## 날짜 노트 반영 기준

| 상황 | 처리 |
| :--- | :--- |
| Python 기초 수업 시작 | 이 staging의 1~2장 중심 병합 |
| container/iterator 수업 | 3~5장 중심 병합 |
| 조건문/반복문 수업 | 8~10장 중심 병합 |
| 예외/import/class 수업 | 11~12장 중심 병합 |
| module 실습 | 보조 파일 표와 함께 연결 |
