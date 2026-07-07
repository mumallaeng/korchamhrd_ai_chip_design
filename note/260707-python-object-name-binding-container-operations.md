# 26-07-07 - Python Object Name Binding, Container 구조 및 연산

관련 노트:

- [260706-python-basic-syntax.md](260706-python-basic-syntax.md)
- [kdt-c-python-m4-ai-course-outline.md](kdt-c-python-m4-ai-course-outline.md)

## 수업 흐름

0707 수업은 Python 실습자료의 2장 `Object Name Binding`, 3장 `Container`, 4장 `Container 구조 및 연산`을 중심으로 진행됐다. 0706에 다룬 1장 기본 문법에 이어, Python의 변수 대입을 '값 저장'이 아니라 'name과 object의 binding'으로 이해하고, 여러 object를 묶어 다루는 container의 구조와 연산까지 확인했다.

| 구분 | 내용 |
| :--- | :--- |
| 진행 범위 | Python 2장 `Object Name Binding`, 3장 `Container`, 4장 `Container 구조 및 연산` |
| 원본 파일 | [Py_Lab_for_VS_Code.py](</Users/mumallaeng/Library/CloudStorage/GoogleDrive-yonnmilk@gmail.com/My Drive/Classroom/대한상공회의소_반도체설계/김은경-C_and_Python/상공회의소_KDT_실습자료(C_Python_M4)/2.Python/Py_Lab_for_VS_Code.py>) |
| 예제 범위 | `[2-1]`부터 4장 container 구조와 연산 예제까지 |
| 다음 범위 | 5장 `주요 Built-in 함수` 이후 |

## 실습 자료와 진행 범위

| 장 | 주제 | 수업 포인트 |
| :--- | :--- | :--- |
| 2장 | `Object Name Binding` | object, class, instance, `id()`, `type()`, `isinstance()`, name binding 실행 순서, namespace mapping, shadowing |
| 3장 | `Container` | `str`, `tuple`, `list`, `set`, `dict`, `range`, item 접근, pack/unpack, lookup table |
| 4장 | `Container 구조 및 연산` | container slot의 reference 저장, sequence `+`/`*`, multiple binding, slicing, shallow/deep copy |

## 2. Object Name Binding

실습 파일 기준 `[2-1] Object, Class, Instance`부터 `[2-11] Namespace의 name 제거`까지 다룬다. 핵심은 Python에서 값을 변수 공간에 직접 복사해 넣는다는 이해보다, name이 object를 가리키도록 binding된다는 이해에 있다.

### Object, Class, Instance

수업에서는 object를 현실의 현상이나 대상을 프로그램에서 처리하기 위해 표현한 것으로 설명했다. Python의 모든 데이터는 object로 표현된다. 공식 문서 기준 object는 `identity`, `type`, `value`를 가진다. 숫자 `10`, 문자열 `"Python"`, class 이름 `int`, 사용자가 만드는 function과 class까지 모두 object다.

| 구성 요소 | 의미 | 확인 방법 |
| :--- | :--- | :--- |
| `identity` | object 고유 식별값 | `id(obj)` |
| `type` | object가 속한 type/class | `type(obj)` |
| `value` | object가 나타내는 값 | 출력, 연산, method 등 |

`class`는 object의 특징을 추상화한 틀이다. 수업에서는 object를 만들기 위한 문서나 설계도에 가깝게 설명했다. 어떤 값이 어떤 연산을 지원하는지, 어떤 method를 가지는지, 어떤 형태의 값을 가질 수 있는지를 class가 정한다. class를 바탕으로 다른 class인 child class를 만들 수 있고, 실제 object인 instance도 생성할 수 있다.

`instance`는 class를 이용해 만든 실체다. 예를 들어 `10`은 `int` class로 만든 `int` instance다. instance는 class를 바탕으로 만들어진 결과물이므로, 일반적으로 다른 instance나 class를 생성하는 template 역할을 하지는 않는다.

| 용어 | 의미 | Python 예 |
| :--- | :--- | :--- |
| object | Python이 다루는 실제 대상 | `10`, `"hello"`, `int`, `[1, 2]` |
| class/type | object 특징을 요약한 abstraction template | `int`, `str`, `list`, `type` |
| instance | class를 이용해 만든 실체 | `10`은 `int`의 instance |
| attribute | object가 가진 이름 붙은 요소 | `str.upper`, `list.append` |
| method | object/class에 연결된 callable attribute | `"hi".upper()` |

`int`는 class object이고, `int(10)`이나 literal `10`은 `int` class의 instance다. 즉 `int`는 값을 담은 정수 자체가 아니라, 정수 object를 만들고 정수 연산을 정의하는 class다.

```python
print(int, type(int))   # <class 'int'> <class 'type'>

x = int(10)
print(x, type(x))       # 10 <class 'int'>

y = int("20")
print(y, type(y))       # 20 <class 'int'>

print(10, type(10))     # 10 <class 'int'>
```

관계를 한 줄씩 풀면 다음과 같다.

| 표현 | 의미 |
| :--- | :--- |
| `10` | `int` class의 instance |
| `type(10)` | `10` object의 type 확인, 결과는 `int` |
| `int` | 정수 object를 만드는 built-in class object |
| `type(int)` | `int` class object의 type 확인, 결과는 `type` |
| `type` | class object를 만드는 class, metaclass 역할 |

```python
print(type(10) is int)       # True
print(isinstance(10, int))   # True

print(type(int) is type)     # True
print(isinstance(int, type)) # True
print(isinstance(int, int))  # False
```

`type(int)`가 `<class 'type'>`인 이유는 `int` 자체도 object이며, class object의 type이 `type`이기 때문이다. Python에서는 class도 object로 취급되므로, class 자체도 다른 name에 binding하거나 argument로 전달할 수 있다.

`isinstance(a, B)`는 앞의 object `a`가 뒤의 class/type `B`에 해당하는 instance인지 확인하는 함수다. 따라서 `isinstance(10, int)`는 `10`이 `int` instance인지 확인하므로 `True`이고, `isinstance(int, type)`은 `int`라는 class object가 `type`의 instance인지 확인하므로 `True`다. 반면 `isinstance(int, int)`는 `int` class object 자체가 정수 instance인지 확인하는 식이라 `False`다.

| 표현 | 질문 | 결과 |
| :--- | :--- | :--- |
| `isinstance(10, int)` | `10`은 `int` instance인가 | `True` |
| `isinstance(int, type)` | `int` class object는 `type` instance인가 | `True` |
| `isinstance(int, int)` | `int` class object 자체가 정수 instance인가 | `False` |

```python
cls = int
value = cls("123")

print(value, type(value))    # 123 <class 'int'>
```

`int("123")`은 `int` class object를 호출해 문자열 `"123"`으로부터 `int` instance를 만드는 동작이다.

### Object 관련 built-in 함수

object를 관찰할 때 자주 쓰는 built-in 함수는 `dir()`, `id()`, `isinstance()`다.

| 함수/연산 | 의미 | 예 |
| :--- | :--- | :--- |
| `dir(obj)` | object가 가진 attribute 이름 확인 | `dir(int)`, `dir(3)` |
| `id(obj)` | object identity 정수 확인 | `id(3)` |
| `isinstance(obj, classinfo)` | 특정 class/type의 instance 여부 확인 | `isinstance(3, int)` |
| `is` | 두 name이 같은 object를 가리키는지 확인 | `a is b` |
| `is not` | 두 name이 다른 object를 가리키는지 확인 | `a is not b` |

```python
print(dir(int))
print(dir(3))
print(id(int), id(3))
print(isinstance(3, int))     # True
print(isinstance(int, type))  # True
```

`is`는 값 비교가 아니라 identity 비교다. 값 비교는 `==`, object 동일성 비교는 `is`로 구분한다.

```python
a = 3
print(a == 3)       # True, value comparison
print(a is 3)       # identity comparison
```

작은 정수나 문자열 literal은 구현 최적화 때문에 같은 object처럼 보일 수 있다. 따라서 일반 값 비교에는 `is`가 아니라 `==`를 사용한다. `is`는 보통 `None` 비교처럼 identity가 의도인 경우에 사용한다.

```python
if value is None:
    print("no value")
```

실제 코드에서 literal과 `is`를 직접 비교하면 `SyntaxWarning`이 나올 수 있다. 수업 예제의 `a is 3`은 identity 비교 개념을 관찰하기 위한 예제로 보고, 일반 코드에서는 `a == 3`을 사용한다.

### Referencing과 method 호출

Python의 연산은 object가 가진 method와 연결된다. 예를 들어 `3 + 4`는 내부적으로 `int.__add__` 계열 동작과 연결된다.

```python
print(int.__add__(3, 4))

x = int(3)
print(x.__add__(4))
print((3).__add__(4))
```

문자열 method도 class를 통해 호출할 수 있고, instance를 통해 호출할 수도 있다.

```python
print(str.upper("Hello"))

x = str("Hello")
print(x.upper())
print("Hello".upper())
```

일반적으로는 instance method 형태인 `x.upper()`를 사용한다. `str.upper("Hello")`는 class의 function object에 instance를 직접 넘겨 호출하는 형태로 이해하면 된다.

method 호출은 attribute lookup과 function 호출이 합쳐진 형태다. `"Hello".upper()`를 실행하면 먼저 `"Hello"` object에서 `upper`라는 attribute를 찾고, 해당 method에 receiver object인 `"Hello"`가 연결된 bound method가 만들어진다. 그 다음 `()`가 붙으면서 bound method가 호출된다.

```text
"Hello".upper()
      |
      v
str object에서 attribute name "upper" lookup
      |
      v
str class의 upper function 발견
      |
      v
"Hello"를 self처럼 묶은 bound method 구성
      |
      v
bound method 호출
```

따라서 다음 두 표현은 학습용으로 같은 의미로 비교할 수 있다.

```python
"Hello".upper()
str.upper("Hello")
```

실제 사용에서는 첫 번째 형태가 더 자연스럽다. 두 번째 형태는 method가 class namespace에 있는 function이고, instance가 첫 번째 argument로 전달된다는 구조를 확인하기 위한 예제다.

### 연산자와 built-in 함수 overloading

같은 연산자라도 operand type에 따라 다른 special method가 동작한다. 그래서 `+`는 숫자에서는 덧셈이고, 문자열에서는 연결이다.

```python
a = 1 + 2
b = "x" + "y"
c = 3.4 - 2.5

print(a, b, c, sep="\n")
```

위 코드는 개념적으로 type별 special method 호출과 연결된다.

```python
a = int.__add__(1, 2)
b = str.__add__("x", "y")
c = float.__sub__(3.4, 2.5)

print(a, b, c, sep="\n")
```

`abs()`와 `round()` 같은 built-in 함수도 object type이 제공하는 special method와 연결될 수 있다.

```python
print(abs(-10))
print(abs(-3.8))
print(round(1234, -2))
print(round(10.434, 1))
```

### Name binding

Python에서 name은 object를 가리킨다. 변수명은 값을 담는 상자라기보다, 현재 namespace 안에서 object를 가리키는 이름표에 가깝다.

대입문은 오른쪽 expression을 먼저 평가한 뒤, 왼쪽 target name을 현재 namespace에 binding한다.

```text
a = 2020

1. 오른쪽 expression `2020` 평가
2. `int` object 확보
3. 현재 namespace에서 name `a` entry 생성 또는 갱신
4. `a` entry가 해당 object reference를 가리킴
```

수업 이해용으로 namespace를 name 칸과 reference 칸으로 나눠 그리면 다음과 같다. 실제 Python 문서에서는 namespace를 'name에서 object로 가는 mapping'이라고 설명하며, 아래 표는 그 mapping을 name entry와 object reference로 분리해 표현한 학습 모델이다.

```text
Global namespace

name      reference
----      ----------------
"a"  ---> int object 2020
"b"  ---> int object 2020
```

| 구분 | 의미 |
| :--- | :--- |
| name | source code에서 사용하는 식별자 문자열, 예: `a`, `b`, `print` |
| reference | name이 가리키는 object 연결 |
| object | type, identity, value를 가진 실제 대상 |
| binding | name entry를 특정 object reference에 연결하는 동작 |
| rebinding | 이미 존재하는 name entry가 다른 object를 가리키도록 갱신하는 동작 |

```python
a = 2020
b = 2020

print(id(2020), id(a), id(b))
```

위 코드에서 `a`와 `b`는 각각 독립적인 상자가 아니라, `2020`이라는 값을 가진 object를 가리키는 name이다. 같은 object를 가리키는지 여부는 구현과 실행 환경의 최적화에 영향을 받을 수 있으므로, 학습 포인트는 'name이 object에 binding된다'는 구조다.

binding은 단순 대입에서만 일어나지 않는다. 함수 parameter, `for` target, import name, `def`로 만든 함수 이름, `class`로 만든 class 이름도 모두 namespace에 name을 binding하는 사례다.

| 코드 형태 | binding 대상 |
| :--- | :--- |
| `a = 10` | name `a`를 `int` object에 binding |
| `for x in values:` | 반복마다 name `x`를 다음 item object에 binding |
| `def f(): ...` | name `f`를 function object에 binding |
| `class C: ...` | name `C`를 class object에 binding |
| `import math` | name `math`를 module object에 binding |
| `def f(x): ...` 호출 | parameter name `x`를 argument object에 binding |

### Expression, Statement, Assignment

Python에서 expression은 평가되면 하나의 object를 결과로 만드는 문법 단위다. `10`, `"hello"`, `a + 1`, `len(data)`, `[x * 2 for x in values]`는 모두 평가 결과 object를 가진다. expression이 하나의 object로 evaluate되면 그 object reference를 name에 binding할 수 있다.

```python
result = a + 1
```

위 코드는 오른쪽 expression `a + 1`을 먼저 평가해 결과 object를 만들고, 왼쪽 name `result`를 그 object에 binding한다.

statement는 interpreter가 실행할 수 있는 최소 코드 단위다. assignment statement, `if` statement, `for` statement, `def` statement, `class` statement처럼 프로그램의 실행 흐름이나 namespace binding을 만든다. statement는 실행되지만, 더 큰 expression 안에 값처럼 끼워 넣을 수 있는 것은 아니다.

| 구분 | 의미 | 예 |
| :--- | :--- | :--- |
| expression | 평가 결과 object 생성 | `a + 1`, `len(data)`, `"hi"` |
| statement | 실행 가능한 최소 코드 단위 | `x = 10`, `if x: ...`, `def f(): ...` |
| assignment statement | target에 object reference binding | `x = value` |
| assignment expression | expression 안에서 name binding 후 값 반환 | `(n := len(data))` |

assignment 관련 문법은 다음처럼 구분한다.

| 종류 | 기호/형태 | 예 | 동작 |
| :--- | :--- | :--- | :--- |
| simple assignment | `=` | `x = 10` | 오른쪽 expression 평가 후 target binding |
| chained assignment | `=` 여러 개 | `a = b = 10` | 같은 결과 object를 여러 target에 binding |
| unpacking assignment | `=` + target list | `a, b = values` | iterable item을 target별 binding |
| starred assignment | `*target` | `first, *mid, last = values` | 남는 item들을 list로 모아 binding |
| attribute assignment | `.` + `=` | `obj.name = value` | object attribute 쓰기 |
| item assignment | `[]` + `=` | `items[0] = value` | container item slot 쓰기 |
| slice assignment | `[:]` + `=` | `items[1:3] = values` | mutable sequence 구간 교체 |
| annotated assignment | `:` 또는 `: T =` | `x: int = 10` | type annotation 기록, 값이 있으면 binding |
| augmented assignment | `op=` | `x += 1` | target read 후 연산, 결과 저장 |
| assignment expression | `:=` | `(n := len(data))` | expression 내부 name binding, Python 3.8 추가 |

`:=`는 walrus operator라고도 부른다. Python 3.8부터 추가되었고, statement가 아니라 expression이다. 따라서 조건식이나 comprehension 일부처럼 expression이 들어갈 수 있는 위치에서 name을 binding하면서 그 값을 바로 사용할 수 있다.

```python
data = [1, 2, 3]

if (n := len(data)) > 0:
    print(n)
```

위 예제에서 `len(data)` expression이 먼저 평가되어 `3` object가 만들어지고, name `n`이 그 object에 binding된다. 그 다음 assignment expression 전체의 결과도 `3`이므로 `3 > 0` 비교에 사용된다.

assignment expression의 target은 일반 assignment처럼 아무 target이나 받을 수 있는 것이 아니라 단일 name이다. 예를 들어 `n := ...`은 가능하지만, `obj.attr := ...`, `items[0] := ...`, `a, b := ...` 같은 형태는 assignment expression target으로 사용할 수 없다.

### Namespace와 재binding

namespace는 name과 object binding을 저장하는 mapping이다. module top-level에서 만든 name은 global namespace에 들어간다. `globals()`는 현재 global namespace를 dictionary 형태로 보여준다.

```text
namespace
    = name -> object reference mapping
```

주요 namespace는 다음처럼 구분할 수 있다.

| namespace | 생성 시점 | 대표 예 |
| :--- | :--- | :--- |
| built-in namespace | Python interpreter 시작 시 준비 | `print`, `len`, `int`, `str` |
| global namespace | module 실행 시 생성 | module top-level의 `a`, `func`, `ClassName` |
| local namespace | function 호출 시 생성 | parameter, function 내부 local name |
| class namespace | class body 실행 시 생성 | class attribute, method name |

`namespace`와 `scope`는 구분해서 봐야 한다.

| 구분 | 의미 |
| :--- | :--- |
| namespace | name과 object reference를 저장하는 mapping |
| scope | 특정 코드 위치에서 어떤 namespace들을 어떤 순서로 검색할지 정하는 규칙 |

즉 namespace는 실제 binding이 들어 있는 저장소이고, scope는 name lookup 때 어떤 저장소를 볼 수 있는지 정하는 범위다. function을 호출하면 local namespace가 새로 만들어지고, function 내부 코드는 그 local namespace를 가장 먼저 검색하는 scope 안에서 실행된다.

#### Built-in, global, local namespace 확인

module top-level에서 실행되는 code는 global namespace를 사용한다. `globals()`는 이 global namespace를 dictionary처럼 보여준다. 실제로 `a = 10`을 실행하면 `globals()` 안에 key `'a'`가 생기고, 그 value가 `10` object를 가리킨다.

```python
a = 10
print(globals()["a"])   # 10
```

function을 호출하면 호출마다 local namespace가 새로 생긴다. parameter도 이 local namespace에 binding된다.

```python
x = "global"

def f(a):
    y = "local"
    print(locals())
    print(globals()["x"])

f(10)
```

개념적으로는 다음처럼 나뉜다.

```text
built-in namespace
  "print" ---> built-in function print
  "len"   ---> built-in function len
  "int"   ---> class object int

global namespace
  "x"     ---> str object "global"
  "f"     ---> function object f

local namespace for f(10)
  "a"     ---> int object 10
  "y"     ---> str object "local"
```

`locals()`는 현재 local namespace를 확인하는 용도에 가깝다. function 내부에서 `locals()` 결과를 직접 수정해도 실제 local variable binding을 안정적으로 바꾸는 방법으로 쓰지 않는다. 반면 module top-level에서 `globals()`는 실제 global namespace mapping이므로 `globals()["name"] = object` 같은 조작이 가능하지만, 수업 code에서는 일반 대입문이 더 명확하다.

```python
globals()["z"] = 30
print(z)            # 30
```

`builtins` module을 import하면 built-in namespace에 있는 object를 직접 확인할 수 있다.

```python
import builtins

print(builtins.print)
print(builtins.int)
```

global namespace에 같은 name을 만들면 built-in name이 사라지는 것이 아니라, 현재 scope의 lookup에서 global name이 먼저 발견될 뿐이다.

```python
len = 10

# len([1, 2, 3])    # TypeError, 현재 len은 function이 아니라 int object

del len
print(len([1, 2, 3]))
```

```python
a = 10
print(id(a))

a = a + 1
b = 10

print(a, b)
print(id(a))
print(id(b))
print(globals())
```

`a = a + 1`은 기존 `int` object `10` 자체를 바꾸는 것이 아니다. 실행 순서는 다음과 같다.

```text
a = a + 1

1. 오른쪽의 name `a` lookup
2. `a`가 가리키던 int object `10` 확인
3. `10 + 1` 연산으로 새 int object `11` 생성
4. 왼쪽 target name `a`를 새 object `11`에 rebinding
5. 기존 object `10`은 다른 name이 가리키지 않으면 더 이상 접근 불가
```

```text
대입 전

name      reference
----      ---------
"a"  ---> int object 10
"b"  ---> int object 10

대입 후: a = a + 1

name      reference
----      ---------
"a"  ---> int object 11
"b"  ---> int object 10
```

`int`는 immutable object라 value가 제자리에서 바뀌지 않는다. name `a`가 다른 object를 가리키도록 바뀌는 것이 핵심이다.

object가 더 이상 어떤 name이나 container slot에서도 참조되지 않으면 이후 메모리 정리 대상이 된다. CPython에서는 reference count가 `0`이 되면 즉시 해제되는 경우가 많지만, 이는 구현 세부사항이다. Python 언어를 이해할 때는 'name binding이 끊기면 그 name으로는 더 이상 object에 접근할 수 없다' 정도가 핵심이다.

### Augmented assignment

`+=`, `-=`, `*=` 같은 augmented assignment는 기존 값과 오른쪽 값을 이용해 결과를 만든 뒤 다시 binding하는 형태로 이해할 수 있다. `int`처럼 immutable type에서는 object identity가 바뀔 수 있다.

augmented assignment의 기호는 일반 이항 연산자 뒤에 `=`를 붙인 형태다. target을 먼저 읽고, 오른쪽 expression을 평가한 뒤, 해당 연산 결과를 다시 target에 저장한다.

| 기호 | 대응 연산 | 예 | 주 용도 |
| :--- | :--- | :--- | :--- |
| `+=` | `+` | `x += y` | 덧셈, sequence 확장 가능 |
| `-=` | `-` | `x -= y` | 뺄셈 |
| `*=` | `*` | `x *= y` | 곱셈, sequence 반복 가능 |
| `@=` | `@` | `x @= y` | 행렬 곱셈 |
| `/=` | `/` | `x /= y` | true division |
| `//=` | `//` | `x //= y` | floor division |
| `%=` | `%` | `x %= y` | 나머지 |
| `**=` | `**` | `x **= y` | 거듭제곱 |
| `<<=` | `<<` | `x <<= y` | 왼쪽 bit shift |
| `>>=` | `>>` | `x >>= y` | 오른쪽 bit shift |
| `&=` | `&` | `x &= y` | bitwise AND |
| `^=` | `^` | `x ^= y` | bitwise XOR |
| `\|=` | `\|` | `x \|= y` | bitwise OR, set union update |

```python
a = 20
b = 4

print(id(a), a)
a += 1
print(id(a), a)
a -= b
print(id(a), a)
a *= b + 2
print(id(a), a)
```

단, mutable container에서는 augmented assignment가 내부 상태를 제자리에서 바꾸는 동작과 연결될 수 있다. `[2-7]` 예제에서는 `int` 기준으로 name 재binding과 `id()` 변화를 관찰했다.

### Name resolution과 built-in name shadowing

Python은 name을 사용할 때 현재 scope에서 접근 가능한 namespace를 순서대로 찾는다. 이 규칙은 보통 LEGB로 설명한다.

| 순서 | 의미 | 예 |
| :--- | :--- | :--- |
| Local | 현재 function의 local namespace | function 내부 parameter, local 변수 |
| Enclosing | 바깥 function의 local namespace | nested function에서 바깥 함수 변수 |
| Global | 현재 module의 global namespace | module top-level name |
| Built-in | Python built-in namespace | `print`, `len`, `int` |

같은 name이 여러 namespace에 있으면 더 안쪽 namespace의 name이 우선한다. 그래서 `id`, `int` 같은 built-in 이름을 직접 대입하면 현재 namespace의 name이 built-in name을 가려버린다.

name resolution은 기본적으로 '값을 읽을 때' 일어나는 lookup 규칙이다. 예를 들어 expression에서 `x`를 사용하면 Python은 현재 코드 위치의 scope 규칙에 따라 `x`가 어느 namespace에 binding되어 있는지 찾는다.

```text
read: name `x`를 평가할 때

1. 현재 function의 local namespace 검색
2. 바깥 function의 enclosing local namespace 검색
   - nested function이면 가까운 바깥 함수부터 차례대로 확인
3. 현재 module의 global namespace 검색
4. Python built-in namespace 검색
5. 끝까지 없으면 NameError
```

예를 들어 function 내부에서 `print(x)`를 실행하면 먼저 그 function의 local namespace에서 `x`를 찾고, 없으면 바깥 function의 local namespace, module global namespace, built-in namespace 순서로 올라간다. 어느 namespace에서도 `x` binding을 찾지 못하면 `NameError`가 발생한다.

```python
x = "global"

def outer():
    x = "enclosing"

    def inner():
        print(x)        # enclosing x 읽기

    inner()
```

위 예제의 `inner()`에는 local `x`가 없으므로 바로 바깥 function인 `outer()`의 local namespace에서 `x`를 찾는다. 만약 `outer()`에도 `x`가 없으면 global `x`를 찾고, global에도 없으면 built-in namespace까지 내려간다.

반면 assignment는 위 read lookup처럼 상위 namespace를 찾아가서 값을 바꾸는 동작이 아니다. `x = 20` 같은 bare name assignment는 정해진 namespace에 name을 새로 binding하거나 기존 binding을 갱신한다.

```text
write: bare name `x = value`를 실행할 때

module top-level:
1. 오른쪽 expression 평가
2. 현재 module의 global namespace에 `x` binding 생성 또는 갱신

function 내부, 별도 선언 없음:
1. compile 단계에서 `x`를 local name으로 분류
2. 실행 시 오른쪽 expression 평가
3. 현재 function의 local namespace에 `x` binding 생성 또는 갱신

function 내부, `global x` 선언 있음:
1. `x`를 module global name으로 분류
2. 실행 시 오른쪽 expression 평가
3. global namespace에 `x` binding 생성 또는 갱신

nested function 내부, `nonlocal x` 선언 있음:
1. 가장 가까운 enclosing function namespace의 `x`를 대상으로 선택
2. 실행 시 오른쪽 expression 평가
3. 해당 enclosing local namespace의 `x` binding 갱신
```

따라서 function 내부에서 `x = 20`을 쓰면 Python이 global namespace에 있는 `x`를 찾아서 고치는 것이 아니라, 그 function의 local namespace에 `x`를 binding한다. 바깥 namespace의 name을 쓰기 대상으로 삼으려면 `global`이나 `nonlocal` 선언이 필요하다.

`global` 선언은 module global namespace를 쓰기 대상으로 지정한다. `nonlocal` 선언은 바깥 function의 local namespace를 쓰기 대상으로 지정한다. `nonlocal` 대상 name은 enclosing function 어딘가에 이미 binding되어 있어야 하며, 없으면 compile 단계에서 `SyntaxError`가 난다.

```python
x = 10

def write_local():
    x = 20          # local x 생성, global x 유지

def write_global():
    global x
    x = 30          # global x 갱신
```

이 차이 때문에 function 내부에서 같은 name에 대입이 있으면 그 name은 기본적으로 local name으로 취급된다.

```python
x = 10

def bad():
    print(x)
    x = 20

# bad()  # UnboundLocalError
```

위 code에서 `print(x)`가 먼저 나오지만, Python은 function body를 compile할 때 `x = 20` 대입을 보고 `x`를 local name으로 분류한다. 따라서 `print(x)`는 global `x`를 읽는 것이 아니라 아직 binding되지 않은 local `x`를 읽으려 하며, 이때 `UnboundLocalError`가 발생한다.

```text
global namespace
  "x" ---> int object 10

bad() local namespace
  "x" ---> 아직 binding 전

print(x)
  Local에서 x 발견 대상으로 분류됨
  하지만 아직 object reference 없음
  UnboundLocalError
```

function 안에서 global name을 다시 binding하려면 `global` 선언이 필요하다.

```python
x = 10

def change_global():
    global x
    x = 20

change_global()
print(x)        # 20
```

nested function에서 바깥 function의 local name을 다시 binding하려면 `nonlocal`을 사용한다.

```python
def outer():
    x = 10

    def inner():
        nonlocal x
        x = 20

    inner()
    print(x)    # 20
```

`global`과 `nonlocal`은 object를 바꾸는 문법이 아니라, assignment target name을 어느 namespace에 binding할지 정하는 선언이다.

augmented assignment인 `x += 1`은 read와 write가 함께 들어 있는 문장이다. 먼저 `x`의 현재 값을 읽고, `+ 1` 결과를 만든 뒤, 다시 `x`에 저장한다. 그래서 function 내부에서 `x += 1`만 있어도 `x`는 local assignment target으로 분류되며, local `x`가 아직 binding되지 않았다면 read 단계에서 `UnboundLocalError`가 난다.

```python
x = 10

def bad_inc():
    x += 1          # local x read 후 write로 분류, read 시점에 unbound

# bad_inc()        # UnboundLocalError
```

주의할 점은 attribute assignment와 item assignment는 bare name assignment와 다르다는 점이다. `obj.attr = value`는 name `obj`를 먼저 read lookup으로 찾은 뒤, 그 object의 attribute를 변경한다. `items[0] = value`도 name `items`를 먼저 찾은 뒤, 그 container object의 item slot을 변경한다. 즉 name 자체를 다른 object에 rebinding하는 것이 아니라, name이 가리키는 object 내부 상태를 바꾸는 동작이다.

```python
items = [1, 2, 3]

def mutate():
    items[0] = 100      # global name items를 read한 뒤 list 내부 item 변경

mutate()
print(items)            # [100, 2, 3]
```

위 코드에서 `items[0] = 100`은 `items = ...`처럼 bare name을 대입하는 문장이 아니므로 `items`를 local name으로 새로 분류하지 않는다. 먼저 LEGB 규칙으로 `items` object를 찾고, 찾은 list object의 0번 slot을 바꾼다.

```python
x = id(10)
print(x)

id, int = 10, 20
print(id, int)

# print(id(10))  # TypeError, 현재 id는 함수가 아니라 int object
```

이런 현상을 shadowing이라고 부른다. 수업 예제에서는 `del id`, `del int`로 현재 namespace의 binding을 제거하면, 다시 built-in `id`, `int`를 찾을 수 있음을 확인했다.

```python
del id
del int
print(id(10))
```

그래서 built-in 함수나 type 이름인 `id`, `int`, `str`, `list`, `dict`, `float` 등을 변수 이름으로 쓰지 않는 편이 좋다.

위 예제에서 `del id`는 built-in `id` 함수를 삭제하는 것이 아니다. 현재 namespace에 만든 name `id`의 binding만 제거한다. 그 결과 name lookup이 다시 built-in namespace까지 내려가며 원래 `id()` 함수를 찾는다.

### Keyword와 NameError

Python keyword는 name으로 binding할 수 없다. 이 점이 built-in 함수명과 다르다. `print`, `len`, `int`, `str` 같은 built-in 이름은 권장되지 않을 뿐 일반 name으로 binding 자체는 가능하다. 반면 `if`, `for`, `lambda`, `yield`, `nonlocal` 같은 keyword는 Python 문법의 일부라 변수명, 함수명, class명으로 사용할 수 없다.

```python
import keyword
print(keyword.kwlist)
```

Python 3.14.6 기준 `keyword.kwlist`에는 35개 keyword가 들어 있다.

| 분류 | Keyword | 역할 |
| :--- | :--- | :--- |
| 상수 literal | `False` | boolean false object |
| 상수 literal | `None` | 값 없음 object |
| 상수 literal | `True` | boolean true object |
| 논리 연산 | `and` | 논리 AND, short-circuit |
| 논리 연산 | `or` | 논리 OR, short-circuit |
| 논리 연산 | `not` | 논리 부정 |
| 비교/포함 | `in` | membership test, `for` item source |
| 비교/동일성 | `is` | identity comparison |
| 조건 분기 | `if` | 조건문 시작 |
| 조건 분기 | `elif` | 추가 조건 branch |
| 조건 분기 | `else` | 나머지 branch |
| 반복 제어 | `for` | iterable 순회 |
| 반복 제어 | `while` | 조건 반복 |
| 반복 제어 | `break` | 가장 안쪽 loop 탈출 |
| 반복 제어 | `continue` | 현재 반복 회차 건너뛰기 |
| 반복 제어 | `pass` | 빈 statement 자리 채움 |
| 함수/값 반환 | `def` | function object 생성과 name binding |
| 함수/값 반환 | `return` | 함수 종료와 반환값 전달 |
| 함수/값 반환 | `yield` | generator에서 값 산출, 실행 상태 보존 |
| 함수/값 반환 | `lambda` | anonymous function expression |
| class | `class` | class object 생성과 name binding |
| namespace | `global` | assignment target을 global namespace로 지정 |
| namespace | `nonlocal` | assignment target을 enclosing namespace로 지정 |
| import | `import` | module object 가져오기와 name binding |
| import | `from` | module 내부 name import |
| import | `as` | import 또는 exception alias 지정 |
| exception | `try` | 예외 처리 block 시작 |
| exception | `except` | exception handler |
| exception | `finally` | 예외 여부와 무관한 마무리 block |
| exception | `raise` | exception 발생 |
| exception/debug | `assert` | 조건 검증, 실패 시 `AssertionError` |
| context manager | `with` | context manager 진입/정리 |
| async | `async` | coroutine function 또는 async context/loop |
| async | `await` | awaitable 완료 대기 |
| 삭제 | `del` | name binding, attribute, item 제거 |

keyword는 parser가 문법 구조로 먼저 인식하므로 다음처럼 name으로 사용할 수 없다.

```python
# if = 10        # SyntaxError
# lambda = 20    # SyntaxError
# nonlocal = 30  # SyntaxError
```

반면 built-in name은 일반 namespace lookup 대상이다. 그래서 대입은 가능하지만, 현재 namespace에서 built-in을 shadowing하므로 함수 호출이 깨질 수 있다.

```python
print = 10

# print("hello")     # TypeError, 현재 print는 int object

del print
print("hello")
```

Python에는 keyword와 별도로 soft keyword가 있다. soft keyword는 특정 문법 위치에서만 특별한 의미를 가지고, 일반 위치에서는 name으로 사용할 수 있다. Python 3.14.6 기준 `keyword.softkwlist`에는 다음 값이 들어 있다.

| Soft keyword | 주 사용 문맥 |
| :--- | :--- |
| `_` | pattern matching wildcard |
| `case` | `match` statement의 case clause |
| `match` | structural pattern matching |
| `type` | type alias statement 문맥 |

soft keyword는 완전한 예약어와 다르지만, 혼동을 줄이려면 수업 코드에서는 일반 변수명으로 피하는 편이 좋다.

아직 binding되지 않은 name을 사용하면 `NameError`가 발생한다. 또한 `a += 1`은 기존 `a` 값을 먼저 읽어야 하므로, `a`가 아직 binding되지 않았다면 오류가 난다.

```python
# x = y     # NameError
# a += 1    # NameError
```

`del`은 namespace에서 name binding을 제거한다. object 자체를 직접 지우는 명령이라기보다, name이 object를 가리키는 연결을 끊는 동작으로 이해하면 된다. 연결이 끊긴 object가 더 이상 접근 가능하지 않으면 이후 garbage collection 대상이 될 수 있다.

## 3. Container

수업에서 다루는 iterable type은 크게 `Container`, `Range`, `Iterator`로 나눠 볼 수 있다. 여기서 iterable은 `for`문이나 `iter()`에 넘겼을 때 item을 순서대로 꺼낼 수 있는 object다. container는 item reference들을 실제로 보관하는 object이고, iterator는 다음 item을 하나씩 꺼내는 상태를 가진 object다.

```text
Iterable Type
├─ Container
│  ├─ Sequence, 연속형
│  │  ├─ Immutable sequence
│  │  │  ├─ str
│  │  │  ├─ tuple
│  │  │  └─ bytes
│  │  └─ Mutable sequence
│  │     ├─ list
│  │     └─ bytearray
│  ├─ Set, 집합형
│  │  ├─ Mutable set
│  │  │  └─ set
│  │  └─ Immutable set
│  │     └─ frozenset
│  └─ Mapping, 매핑형
│     └─ dict
├─ Range
│  └─ range
└─ Iterator
   ├─ map object
   ├─ filter object
   ├─ zip object
   ├─ enumerate object
   ├─ generator object
   └─ file iterator 등
```

`str`은 문자들을 순서대로 담는 container이며, 연속형(sequence)이면서 수정 불가형(immutable) container다. 따라서 index와 slicing으로 문자를 읽을 수는 있지만, 특정 위치의 문자를 대입으로 바꿀 수는 없다. `range`는 Python 공식 관점에서는 immutable sequence 성격도 가지지만, 수업 분류에서는 규칙적 정수열을 표현하는 특수 iterable로 따로 빼서 보는 편이 이해하기 쉽다. `iterator`는 container처럼 item을 모두 저장하지 않고, 다음 item을 꺼내기 위한 진행 상태를 가진다. 한 번 소비하면 같은 iterator에서 이미 꺼낸 item은 다시 나오지 않는다.

| 큰 분류 | 세부 분류 | type | display/literal | 생성자 | 빈 값 | item 한 개 | mutable | 개별 접근 | 접근 방법 | 특징 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| Container | Immutable sequence | `str` | `"abc"`, `'abc'` | `str(obj)` | `""`, `str()` | `"a"` | 불가 | 가능 | `s[i]`, `s[a:b]` | 문자 container |
| Container | Immutable sequence | `tuple` | `(1, 2)`, `1, 2` | `tuple(iterable)` | `()`, `tuple()` | `(10,)` | 불가 | 가능 | `t[i]`, `t[a:b]` | comma 핵심 |
| Container | Immutable sequence | `bytes` | `b"ABC"` | `bytes(iterable)` | `b""`, `bytes()` | `b"A"` | 불가 | 가능 | `b[i]`, `b[a:b]` | item은 `int` |
| Container | Mutable sequence | `list` | `[1, 2]` | `list(iterable)` | `[]`, `list()` | `[10]` | 가능 | 가능 | `L[i]`, `L[a:b]` | item/slice 대입 가능 |
| Container | Mutable sequence | `bytearray` | 별도 literal 없음 | `bytearray(iterable)` | `bytearray()` | `bytearray([65])` | 가능 | 가능 | `ba[i]`, `ba[a:b]` | 수정 가능한 byte열 |
| Container | Mutable set | `set` | `{1, 2}` | `set(iterable)` | `set()` | `{10}` | 가능 | 불가 | `for x in s`, `x in s` | 순서 보장 불가, 중복 제거/집합 연산 |
| Container | Immutable set | `frozenset` | 별도 literal 없음 | `frozenset(iterable)` | `frozenset()` | `frozenset([10])` | 불가 | 불가 | `for x in fs`, `x in fs` | hashable 가능 |
| Container | Mapping | `dict` | `{"a": 1}` | `dict(pairs)`, `dict(a=1)` | `{}`, `dict()` | `{"a": 1}` | 가능 | 가능 | `d[key]`, `d.get(key)` | key unique, mutable key 불가 |
| Range | Range object | `range` | 별도 literal 없음 | `range(start, stop, step)` | 없음 | `range(1)` | 불가 | 가능 | `r[i]`, `r[a:b]` | 정수 규칙 저장 |
| Iterator | Iterator object | `map`, `filter`, `zip`, `enumerate` | 별도 literal 없음 | 각 함수 호출 | 없음 | 없음 | 진행 상태 변경 | 순차 접근 | `next(it)`, `for x in it` | 소비 후 되돌림 없음 |
| Iterator | Generator object | generator | `(expr for x in it)` | generator function 호출 | 없음 | 없음 | 진행 상태 변경 | 순차 접근 | `next(gen)`, `for x in gen` | 실행 frame 보존 |

Python container는 여러 object를 한 object 안에 모아서 다루는 구조다. 중요한 점은 container가 item object 자체를 직접 담는 것이 아니라, 각 item object의 identity/reference를 slot에 저장한다는 점이다.

예를 들어 다음 code에서 `L`은 list object를 가리키고, list object 내부 slot들은 각각 `int` object를 가리킨다.

```python
L = [10, 20, 30]
```

```text
namespace

name      reference
----      ----------------
"L"  ---> list object
          slot 0 ---> int object 10
          slot 1 ---> int object 20
          slot 2 ---> int object 30
```

따라서 `L[0]`은 list의 slot 0에 저장된 reference를 따라가 `int object 10`을 얻는 동작이다. `L[0] = 99`는 `10` object를 바꾸는 것이 아니라, slot 0의 reference를 `99` object로 바꾸는 동작이다.

```text
L[0] = 99

list object
  slot 0 ---> int object 99
  slot 1 ---> int object 20
  slot 2 ---> int object 30
```

여기서 mutable 여부는 container object의 slot 구성 또는 내부 상태를 바꿀 수 있는지를 뜻한다. `tuple`이 immutable이라는 말은 tuple의 slot reference를 바꿀 수 없다는 의미이지, tuple 안에 들어 있는 모든 object가 자동으로 immutable이 된다는 뜻은 아니다.

문자열 `str`도 같은 기준에서 immutable sequence다. `s[0]`처럼 읽거나 `s[1:3]`처럼 slicing으로 새 문자열을 만들 수는 있지만, `s[0] = "A"`처럼 기존 문자열 object의 slot을 바꾸는 동작은 허용되지 않는다. 문자열을 바꾸는 것처럼 보이는 코드는 보통 새 문자열 object를 만들고 name을 다시 binding하는 동작이다.

```python
s = "hello"

print(s[0])       # h
print(s[1:4])     # ell

# s[0] = "H"      # TypeError

s = "H" + s[1:]   # 새 str object 생성 후 name s rebinding
```

```python
t = ([1, 2], 3)

t[0].append(99)
print(t)            # ([1, 2, 99], 3)

# t[0] = [10, 20]   # TypeError, tuple slot 자체는 변경 불가
```

위 예제에서 tuple의 slot 0은 계속 같은 list object를 가리킨다. 바뀐 것은 tuple slot이 아니라, slot 0이 가리키던 list object의 내부 상태다.

container 생성은 위 비교표처럼 literal/display 표기 또는 class 생성자 호출로 수행할 수 있다. 수업에서 말한 `tuple()`, `list[]`, `set{}`, `dict{:}`는 생성자 호출과 literal 표기를 구분해서 봐야 한다. 여기서 `tuple()`, `list()`, `set()`, `dict()` 같은 이름은 변환 함수처럼 사용하지만, 정확히는 class를 호출해 새 instance를 구성하는 생성자다. 주의할 점은 `{}`가 빈 set이 아니라 빈 dict라는 점이다. 빈 set은 반드시 `set()`으로 만들고, item 한 개짜리 tuple은 `(10,)`처럼 comma를 포함해 적는다.

```python
t = (10, 20, 30)
L = [10, 20, 30]
s = {10, 20, 30}
d = {"a": 1, "b": 2}
single = (10,)
empty_tuple = ()
empty_list = []
empty_set = set()
empty_dict = {}

t2 = tuple([10, 20])
L2 = list("ABC")
s2 = set([1, 1, 2])
d2 = dict([("a", 1), ("b", 2)])
b = bytes([65, 66, 67])
ba = bytearray([65, 66, 67])
fs = frozenset([1, 1, 2])
```

`set`은 중복 item을 하나만 남긴다. 순서를 보장하지 않으므로, 순서 기반 처리나 index 접근이 필요한 데이터에는 맞지 않는다. 보통 중복 제거, membership test, 합집합/교집합/차집합 같은 집합 연산처럼 순서가 핵심이 아닌 특수 용도에 사용한다. `dict` literal은 `key: value` 형태를 요구하고, `dict()` 생성자는 key-value pair들의 iterable 또는 keyword argument를 받을 수 있다.

```python
print(set([1, 1, 2]))          # {1, 2}
print(dict([("a", 1)]))        # {'a': 1}
print(dict(a=1, b=2))          # {'a': 1, 'b': 2}
print(bytes([65, 66, 67]))     # b'ABC'
print(bytearray(b"ABC"))       # bytearray(b'ABC')
print(frozenset([1, 1, 2]))    # frozenset({1, 2})
```

`set`의 item과 `dict`의 key는 unique해야 하며 hashable이어야 한다. `set`에 같은 item을 여러 번 넣으면 하나만 남고, `dict`에 같은 key를 다시 쓰면 기존 value가 새 value로 갱신된다. hashable object는 실행 중 hash 값이 안정적으로 유지되고, equality 비교와 함께 hash table lookup에 사용할 수 있는 object다. `int`, `str`, `tuple`은 보통 hashable이지만, `list`, `dict`, `set`처럼 내부 상태가 바뀔 수 있는 mutable object는 hashable하지 않으므로 `set` item이나 `dict` key로 사용할 수 없다.

```python
print({1, 1, 2})              # {1, 2}
print({"a": 1, "a": 2})       # {'a': 2}
print(hash("apple"))
print(hash((1, 2)))

# print({[1, 2]})              # TypeError
# print({[1, 2]: "value"})     # TypeError
# print(hash([1, 2]))          # TypeError
```

`dict` lookup은 key의 hash 값을 이용해 후보 위치를 좁히고, equality 비교로 실제 key를 확인하는 방식으로 이해할 수 있다. 그래서 key로 사용할 object는 hash table 안에서 위치가 흔들리지 않아야 한다.

```text
d["apple"]

1. key object "apple"의 hash 계산
2. hash table에서 후보 위치 탐색
3. 후보 key와 equality 비교
4. 대응 value reference 반환
```

`range`는 전체 정수를 list로 미리 저장하지 않고, 시작값, 끝값, step 정보를 가진 sequence object다. index 접근이나 slicing은 가능하지만, 각 값을 모두 담은 list와는 다르다.

```python
r = range(1, 10, 2)

print(r[0])         # 1
print(r[2])         # 5
print(list(r))      # [1, 3, 5, 7, 9]
```

`bytes`와 `bytearray`는 둘 다 byte sequence다. item을 하나 꺼내면 길이 1짜리 `bytes`가 아니라 `0`부터 `255` 사이의 `int`가 나온다. `bytes`는 immutable이라 item 대입이 불가능하고, `bytearray`는 mutable이라 byte 값을 직접 바꿀 수 있다.

```python
b = b"ABC"
ba = bytearray(b"ABC")

print(b[0])         # 65
# b[0] = 97         # TypeError

ba[0] = 97
print(ba)           # bytearray(b'aBC')
```

`frozenset`은 변경 불가 집합이다. `add()`, `remove()`처럼 내부 상태를 바꾸는 method는 없지만, set 연산 결과로 새 set-like object를 만들 수 있다. item들이 모두 hashable이면 `frozenset` 자체도 hashable이 될 수 있어서 `dict` key나 다른 `set`의 item으로 사용할 수 있다.

```python
fs = frozenset([1, 2, 3])
print(hash(fs))

d = {fs: "immutable set key"}
print(d[fs])
```

iterator는 container와 다르게 현재 소비 위치를 가진다. `map`, `filter`, `zip`, `enumerate`, generator expression은 모두 iterator 성격을 가진다. `list()`로 감싸면 남은 item을 모두 꺼내 list로 materialize한다.

```python
it = map(int, ["1", "2", "3"])

print(next(it))     # 1
print(list(it))     # [2, 3]
print(list(it))     # []
```

### Item 접근과 수정

item 접근에는 subscription 기호인 대괄호 `[]`를 사용한다. subscription은 object 뒤에 `[...]`를 붙여 내부 item이나 부분 구간을 요청하는 문법이다. sequence에서는 index나 slice를 넣고, mapping에서는 key를 넣는다.

| 구분 | 대상 | 문법 | 읽기/쓰기 | 결과와 조건 |
| :--- | :--- | :--- | :--- | :--- |
| index 접근 | sequence | `seq[index]` | 읽기 | index 위치 item 반환, 범위 초과 시 `IndexError` |
| slice 접근 | sequence | `seq[start:stop]`, `seq[start:stop:step]` | 읽기 | `stop` 미포함 구간으로 새 sequence 생성 |
| index 대입 | mutable sequence | `seq[index] = value` | 쓰기 | 해당 slot reference 교체 |
| slice 대입 | mutable sequence | `seq[start:stop] = values` | 쓰기 | 구간 교체, 길이 변화 가능 |
| key 접근 | mapping | `mapping[key]` | 읽기 | key 대응 value 반환, key 없으면 `KeyError` |
| key 대입 | mutable mapping | `dict[key] = value` | 쓰기/추가 | 기존 key 갱신 또는 새 key-value 추가 |
| membership | set, frozenset, sequence, mapping | `x in obj` | 읽기 | item 또는 key 포함 여부 확인 |
| item 추가 | mutable set | `s.add(value)` | 추가 | hashable item 추가, 중복이면 변화 없음 |

`[]`를 쓴다고 모두 숫자 index라는 뜻은 아니다. `L[0]`의 `0`은 sequence index이고, `d["a"]`의 `"a"`는 dict key다. `set`과 `frozenset`은 개별 위치 개념이 없으므로 subscription으로 item을 꺼낼 수 없다.

`str`, `tuple`, `list`는 sequence type이므로 index로 item에 접근한다. index는 `0`부터 시작하고, `-1`은 마지막 item을 의미한다. 범위를 벗어나면 `IndexError`가 발생한다.

```python
L = [10, 20, 30]
print(L[0])
print(L[-1])
```

sequence type은 공통적으로 item 접근, slicing, membership, 연결/반복, 길이와 검색 연산을 제공한다. 단, `range`처럼 규칙 기반 sequence는 index와 slicing은 지원하지만 `+`, `*` 연결/반복은 지원하지 않는 등 type별 제한이 있을 수 있다.

| 연산/메서드 | 구분 | 예 | 결과 | 조건/주의 |
| :--- | :--- | :--- | :--- | :--- |
| `x in s` | membership | `2 in [1, 2]` | `True` | item 포함 여부 |
| `x not in s` | membership 부정 | `3 not in [1, 2]` | `True` | item 미포함 여부 |
| `s + t` | 연결 | `[1, 2] + [3]` | `[1, 2, 3]` | 같은 sequence 계열 중심, `range` 제한 |
| `s * n`, `n * s` | 반복 | `"ha" * 3` | `"hahaha"` | 반복된 새 sequence |
| `s[i]` | index 접근 | `s[0]` | 첫 item | 범위 초과 시 `IndexError` |
| `s[i:j]` | slicing | `L[1:4]` | `i`부터 `j` 직전 | `stop` 미포함 |
| `s[i:j:k]` | extended slicing | `L[::-1]` | step 적용 slice | `k=0` 불가 |
| `len(s)` | 길이 | `len([1, 2])` | `2` | item 개수 |
| `min(s)` | 최솟값 | `min([3, 1])` | `1` | item 비교 가능 필요 |
| `max(s)` | 최댓값 | `max([3, 1])` | `3` | item 비교 가능 필요 |
| `s.count(x)` | 개수 검색 | `[1, 1, 2].count(1)` | `2` | 같은 item 개수 |
| `s.index(x[, start[, stop]])` | 위치 검색 | `[3, 4].index(4)` | `1` | 없으면 `ValueError` |

`dict`는 index가 아니라 key로 item에 접근한다.

```python
d = {"a": 1, "b": 2}
print(d["a"])
```

`set`은 저장 순서가 고정되지 않으므로 index 기반 개별 접근이 불가능하다. 따라서 순서가 의미 있는 데이터는 `list`나 `tuple`을 사용하고, `set`은 중복 제거와 집합 연산처럼 순서가 필요 없는 경우에 사용한다.

mutable container인 `list`, `dict`, `set`은 item 추가/삭제가 가능하다. `list`와 `dict`는 특정 item 수정이 가능하고, `set`은 index 접근이 없어서 특정 위치 item 대입은 불가능하지만 `add()`와 제거 연산으로 구성 자체는 바꿀 수 있다.

mutable sequence는 sequence 공통 연산에 더해 index/slice 대입, 삭제, 제자리 확장/반복, method 기반 수정을 지원한다. `list`가 대표적이고, `bytearray`도 mutable sequence지만 item 값은 `0`부터 `255` 사이 정수로 제한된다.

| 연산/메서드 | 구분 | 예 | 결과 | 조건/주의 |
| :--- | :--- | :--- | :--- | :--- |
| `s[i] = x` | index 대입 | `L[0] = 9` | 특정 slot 교체 | mutable sequence 전용 |
| `del s[i]` | index 삭제 | `del L[0]` | 특정 item 제거 | 길이 감소 |
| `s[i:j] = t` | slice 대입 | `L[1:3] = [8, 9]` | 구간 교체 | `t`는 iterable |
| `del s[i:j]` | slice 삭제 | `del L[1:3]` | 구간 제거 | `s[i:j] = []`와 유사 |
| `s[i:j:k] = t` | step slice 대입 | `L[::2] = [7, 8, 9]` | 선택 위치 교체 | `k != 1`이면 길이 일치 필요 |
| `del s[i:j:k]` | step slice 삭제 | `del L[::2]` | step 위치 제거 | 선택 item 삭제 |
| `s += t` | 제자리 확장 | `L += [3]` | 기존 sequence 확장 가능 | `extend()`와 유사 |
| `s *= n` | 제자리 반복 | `L *= 2` | 기존 sequence 반복 갱신 | `n <= 0`이면 clear 성격 |
| `s.append(x)` | 끝에 추가 | `L.append(3)` | 마지막에 item 추가 | `s[len(s):] = [x]`와 유사 |
| `s.clear()` | 모두 삭제 | `L.clear()` | 빈 sequence | `del s[:]`와 유사 |
| `s.copy()` | shallow copy | `L.copy()` | 새 outer sequence | `s[:]`와 유사 |
| `s.extend(t)` | iterable 확장 | `L.extend([3, 4])` | 여러 item 추가 | `s[len(s):] = t`와 유사 |
| `s.insert(i, x)` | 위치 삽입 | `L.insert(0, 9)` | index 앞 삽입 | 길이 증가 |
| `s.pop([i])` | 꺼내기/삭제 | `L.pop()` | item 반환 후 제거 | 기본 마지막 item |
| `s.remove(x)` | 값 삭제 | `L.remove(3)` | 첫 번째 matching item 제거 | 없으면 `ValueError` |
| `s.reverse()` | 순서 반전 | `L.reverse()` | 제자리 역순 | 반환값 `None` |
| `list.sort()` | 정렬 | `L.sort()` | 제자리 정렬 | `list` 전용 method |

sequence slicing은 `start`, `stop`, `step` 규칙으로 새 sequence를 만든다. `stop` 위치는 포함하지 않는다.

```python
L = [0, 1, 2, 3, 4, 5]

print(L[1:4])       # [1, 2, 3]
print(L[:3])        # [0, 1, 2]
print(L[::2])       # [0, 2, 4]
print(L[::-1])      # [5, 4, 3, 2, 1, 0]
```

`step`이 양수이면 index가 오른쪽으로 증가하고, `step`이 음수이면 index가 왼쪽으로 감소한다. `start`와 `stop`을 생략했을 때의 기본 방향도 `step` 부호에 따라 달라진다.

| slicing | 실제 index 흐름 | 결과 | 핵심 |
| :--- | :--- | :--- | :--- |
| `L[1:4]` | `1 -> 2 -> 3` | `[1, 2, 3]` | `stop=4` 미포함 |
| `L[:3]` | `0 -> 1 -> 2` | `[0, 1, 2]` | 앞쪽 `start` 생략 시 처음부터 |
| `L[::2]` | `0 -> 2 -> 4` | `[0, 2, 4]` | 두 칸씩 증가 |
| `L[::-1]` | `5 -> 4 -> 3 -> 2 -> 1 -> 0` | `[5, 4, 3, 2, 1, 0]` | 음수 step, 뒤에서 앞으로 끝까지 |
| `L[5:0:-1]` | `5 -> 4 -> 3 -> 2 -> 1` | `[5, 4, 3, 2, 1]` | `stop=0` 미포함 |
| `L[5::-1]` | `5 -> 4 -> 3 -> 2 -> 1 -> 0` | `[5, 4, 3, 2, 1, 0]` | `stop` 생략으로 처음까지 포함 |

따라서 `L[::-1]`은 `L[5:0:-1]`과 같지 않다. `L[5:0:-1]`은 `stop`으로 지정한 index `0`을 포함하지 않으므로 `0`이 빠진다. 전체 역순을 명시적으로 쓰고 싶다면 `L[5::-1]`처럼 `stop`을 비워 두는 쪽이 맞다.

list slicing으로 만들어진 새 list는 outer container만 새로 생긴다. item object reference는 그대로 복사되므로 shallow copy 성격을 가진다.

### Pack, Unpack, 다중 Container

comma로 나열된 여러 값은 tuple로 pack될 수 있고, 왼쪽 target 개수와 오른쪽 iterable item 개수가 맞으면 unpack이 가능하다. `()`, `[]`, `{}` 같은 container display를 쓰지 않고 값만 comma로 나열하면 기본적으로 tuple pack으로 해석된다. 즉, pack의 기본 형태는 tuple pack이다.

```python
t = 1, 2, 3
a, b, c = t

print(type(t))      # <class 'tuple'>
```

위 코드의 `1, 2, 3`은 괄호가 없지만 tuple object를 만든다. Python에서 tuple을 만드는 핵심은 괄호 자체보다 comma이며, 그 tuple의 각 slot이 가리키는 object를 왼쪽 name에 차례대로 binding한다.

```text
t = 1, 2, 3

name "t" ---> tuple object
              slot 0 ---> int object 1
              slot 1 ---> int object 2
              slot 2 ---> int object 3

a, b, c = t

name "a" ---> int object 1
name "b" ---> int object 2
name "c" ---> int object 3
```

같은 원리로 Python에서는 임시 변수 없이 두 name이 가리키는 object를 바꿀 수 있다. `a, b = b, a`에서 우변 `b, a`가 먼저 tuple로 pack되고, 그 tuple이 왼쪽 `a, b`에 unpack되면서 두 name이 새 object reference로 동시에 rebinding된다.

```python
a = 10
b = 20

a, b = b, a

print(a, b)        # 20 10
```

```text
1. 우변 평가
   b, a  --->  (20, 10) tuple pack

2. 좌변 대입
   a, b  <---  (20, 10) tuple unpack

3. rebinding 결과
   name "a" ---> int object 20
   name "b" ---> int object 10
```

unpack은 우변 object가 iterable이면 가능하다. `tuple`, `list`, `str`, `range`, `dict`, `set`, iterator처럼 item을 차례로 꺼낼 수 있는 object는 모두 unpack 대상이 될 수 있다. 다만 우변 item 개수와 좌변 target 개수가 맞지 않으면 `ValueError`가 발생한다. 일부만 받고 나머지를 묶고 싶을 때는 starred target을 사용할 수 있다.

```python
a, b = [10, 20]          # list unpack
c, d = (30, 40)          # tuple unpack
e, f = "AB"              # str unpack
g, h = range(2)          # range unpack

print(a, b, c, d, e, f, g, h)
```

`dict`를 그대로 unpack하면 value가 아니라 key들만 unpack된다. `dict` 자체를 순회할 때 기본 iterable 대상이 key이기 때문이다. key-value pair를 unpack하려면 `dict.items()`를 사용한다. iterator는 unpack 과정에서 item을 꺼내므로, 한 번 소비된 item은 같은 iterator에서 다시 나오지 않는다.

```python
d = {"x": 1, "y": 2}
k1, k2 = d

print(k1, k2)       # x y

for key, value in d.items():
    print(key, value)
```

```python
a, *rest = [1, 2, 3, 4]
print(a, rest)          # 1 [2, 3, 4]
```

starred target은 고정 target을 먼저 채운 뒤 남는 item을 `list`로 모아 받는다. 예를 들어 왼쪽에 `first`와 `last`가 고정 target으로 있고 가운데에 `*b`가 있으면, 앞쪽 1개와 뒤쪽 1개를 제외한 나머지가 `b`에 들어간다.

```python
input_val = "park kim lee moon lew kang song".split()
first, *b, last = input_val

print(first, last)      # park song
print(b)                # ['kim', 'lee', 'moon', 'lew', 'kang']
```

위 대입은 개념적으로 다음 slicing과 같다.

```python
first = input_val[0]
b = input_val[1:-1]
last = input_val[-1]
```

중요한 점은 `b`가 단일 object 하나를 받지 않는다는 데 있다. `b`에는 남은 item들의 reference를 담은 새 list object가 binding된다.

```text
input_val = ["park", "kim", "lee", "moon", "lew", "kang", "song"]
first, *b, last = input_val

first ---> "park"
b     ---> ["kim", "lee", "moon", "lew", "kang"]
last  ---> "song"
```

같은 `*`라도 위치에 따라 의미가 다르다. 함수 호출의 `print(*nums)`는 container를 풀어서 argument로 전달하는 unpacking이고, 대입문의 `first, *b, last = input_val`은 오른쪽 iterable을 풀어 대입하면서 남는 값을 `b`에 모으는 starred target이다.

| 사용 위치 | 예 | 의미 |
| :--- | :--- | :--- |
| 산술 연산 | `3 * 4` | 곱셈 |
| sequence 연산 | `"ha" * 3`, `[0] * 5` | 반복한 새 sequence 생성 |
| 함수 호출 | `print(*nums)` | iterable item을 argument로 풀어서 전달 |
| 함수 정의 | `def f(*args):` | 남는 positional argument를 tuple로 모음 |
| 대입문 왼쪽 | `first, *b, last = values` | 고정 target 외 남는 item을 list로 모음 |

container 안에는 다른 container도 item으로 들어갈 수 있다. 다만 `set`의 item과 `dict`의 key는 unique해야 하며 hashable이어야 하므로, `list`, `set`, `dict` 같은 mutable object는 `set` item이나 `dict` key로 사용할 수 없다.

```python
nested = [[1, 2], [3, 4]]
print(nested[0][1])
```

### `dict` view와 lookup table

`dict.keys()`, `dict.values()`, `dict.items()`는 각각 key, value, key-value tuple 쌍을 보여주는 view object를 반환한다. view object도 iterable 성격을 가진다.

```python
d = {"a": 1, "b": 2}

print(d.keys())
print(d.values())
print(d.items())
```

dict view는 단순 snapshot list가 아니라 원래 dict를 바라보는 view다. dict가 바뀌면 view로 보이는 내용도 함께 바뀐다.

```python
d = {"a": 1}
keys = d.keys()

print(keys)         # dict_keys(['a'])

d["b"] = 2
print(keys)         # dict_keys(['a', 'b'])
```

규칙적인 index가 아니라 의미 있는 code로 값을 찾고 싶을 때 `dict`를 lookup table처럼 사용할 수 있다.

```python
fruit_price = {
    "apple": 100,
    "orange": 80,
    "banana": 120,
}

print(fruit_price["orange"])
```

`dict` lookup은 branch를 줄이는 데 사용할 수 있다. key가 없을 가능성이 있으면 `in`, `get()`, `try-except KeyError` 중 하나로 처리한다.

```python
fruit = input()

if fruit in fruit_price:
    print(fruit_price[fruit])
else:
    print("unknown")

print(fruit_price.get(fruit, "unknown"))
```

`True`는 `1`, `False`는 `0`과 값 비교에서 같으므로 단순 boolean lookup은 tuple로도 구성할 수 있다. 규칙이 복잡하거나 key가 숫자 규칙이 아닐 때는 `dict` lookup이 더 적합하다.

```python
result = ("lose", "win")
print(result[score >= 60])
```

## 4. Container 구조 및 연산

container의 slot에는 item object의 identity가 저장된다. 그래서 같은 object를 여러 name이나 여러 slot이 함께 가리킬 수 있다. 이를 multiple binding으로 설명할 수 있다.

```python
a = [1, 2]
b = a

b.append(3)
print(a)        # [1, 2, 3]
```

위 예시에서 `a`와 `b`는 같은 list object를 가리킨다. mutable object를 공유하면 한쪽에서 수정한 내용이 다른 name으로도 보인다.

```text
대입 직후

name "a" ---> list object [1, 2]
name "b" ---/

b.append(3) 이후

name "a" ---> list object [1, 2, 3]
name "b" ---/
```

`b.append(3)`은 name `b`를 다른 list에 rebinding하는 동작이 아니다. `b`가 가리키는 list object 내부 상태를 바꾸는 method 호출이다. 같은 object를 가리키는 `a`로도 변경 결과가 보이는 이유가 여기에 있다.

sequence와 nested sequence는 둘 다 sequence지만, item이 어떤 object를 가리키는지에 따라 수정 영향 범위가 달라진다.

| 구분 | 예 | item 구조 | 접근 방식 | 수정 영향 | 주의점 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| single sequence | `[0, 1, 2]` | outer slot이 값 object reference 저장 | `L[i]` | 해당 slot 교체 또는 item object 수정 | item이 immutable이면 alias 위험 작음 |
| nested sequence | `[[0, 1], [2, 3]]` | outer slot이 inner sequence reference 저장 | `L[i][j]` | inner object 공유 시 여러 경로에 영향 | shallow copy와 반복 생성 주의 |
| single sequence copy | `B = A[:]` | 새 outer sequence | `B[i]` | immutable item 중심이면 독립처럼 동작 | item reference는 복사 |
| nested sequence copy | `B = A[:]` | 새 outer sequence, 같은 inner reference | `B[i][j]` | inner 수정 시 `A`와 `B`에 함께 반영 | deep copy 또는 comprehension 필요 |

`+`와 `*`는 sequence type에서 container를 새로 구성하는 데 사용된다. single sequence에서는 새 sequence가 만들어진다는 점이 핵심이고, nested sequence에서는 outer container와 inner container의 reference 공유 여부가 핵심이다.

| 구분 | 예 | 결과 object | 내부 reference | 주의점 |
| :--- | :--- | :--- | :--- | :--- |
| sequence `+` | `[1, 2] + [3, 4]` | 새 list `[1, 2, 3, 4]` | 기존 item reference 복사 | 원본 sequence 자체 변경 없음 |
| sequence `*` | `[0] * 3` | 새 list `[0, 0, 0]` | 같은 item reference 반복 | immutable item이면 보통 문제 적음 |
| nested sequence `+` | `[[0]] + [[1]]` | 새 outer list `[[0], [1]]` | inner list reference 공유 | inner list 수정 시 원본에도 영향 가능 |
| nested sequence `*` | `[[0] * 3] * 2` | 새 outer list `[[0, 0, 0], [0, 0, 0]]` | 같은 inner list reference 반복 | 한 행 수정 시 여러 행이 같이 변경 |
| mutable sequence `+=` | `L += [3]` | 기존 list `L`이 `[1, 2, 3]` | 기존 object 제자리 변경 가능 | `L = L + [3]`과 identity 동작 다를 수 있음 |
| immutable sequence `+=` | `t += (3,)` | 새 tuple `(1, 2, 3)` | 새 object로 rebinding | 기존 tuple 변경 불가 |

```python
print("Hi" + "Python")
print((1, 2) + (3, 4))
print([0] * 3)
```

sequence의 `+`는 양쪽 sequence를 이어 붙인 새 sequence object를 만든다. 기존 sequence object 자체를 수정하는 연산이 아니다.

```python
a = [1, 2]
b = [3, 4]
c = a + b

print(a)        # [1, 2]
print(b)        # [3, 4]
print(c)        # [1, 2, 3, 4]
```

개념적으로는 새 outer list를 만들고, 기존 item object reference를 새 list slot으로 복사한다.

```text
a ---> list [1, 2]
b ---> list [3, 4]

c = a + b

c ---> new list
       slot 0 ---> int object 1
       slot 1 ---> int object 2
       slot 2 ---> int object 3
       slot 3 ---> int object 4
```

nested sequence에 `+`를 사용해도 outer list만 새로 생긴다. inner list object는 새로 복사되지 않고 reference가 새 outer list slot으로 복사된다.

```python
left = [[0]]
right = [[1]]
combined = left + right

combined[0][0] = 99

print(left)         # [[99]]
print(combined)     # [[99], [1]]
```

위 예제에서 `combined`는 새 outer list지만, `combined[0]`과 `left[0]`은 같은 inner list object를 가리킨다.

`list += iterable`은 `list = list + iterable`과 항상 같은 비용/동작으로 보면 안 된다. mutable list에서는 내부적으로 `extend()`와 비슷하게 기존 list object를 제자리에서 늘릴 수 있다. 반면 tuple은 immutable이므로 `+=` 결과가 새 tuple object로 rebinding된다.

```python
L = [1, 2]
old_id = id(L)
L += [3]
print(L, id(L) == old_id)      # [1, 2, 3] True 가능

t = (1, 2)
old_id = id(t)
t += (3,)
print(t, id(t) == old_id)      # (1, 2, 3) False
```

`*`는 반복된 sequence를 만들지만, 다중 list를 만들 때는 같은 내부 list가 반복 참조되는 문제가 생길 수 있다.

```python
bad = [[0] * 3] * 2
bad[0][0] = 1
print(bad)      # [[1, 0, 0], [1, 0, 0]]
```

이 문제는 outer list의 두 slot이 서로 다른 inner list를 가진 것이 아니라, 같은 inner list object를 함께 가리키기 때문에 발생한다.

```text
bad = [[0] * 3] * 2

bad
  slot 0 ---\
             ---> inner list [0, 0, 0]
  slot 1 ---/

bad[0][0] = 1

bad
  slot 0 ---\
             ---> inner list [1, 0, 0]
  slot 1 ---/
```

2레벨 이하 container가 mutable이면 multiple binding 문제를 특히 주의해야 한다. 각 내부 list를 독립적으로 만들려면 comprehension을 사용한다.

```python
good = [[0] * 3 for _ in range(2)]
good[0][0] = 1
print(good)     # [[1, 0, 0], [0, 0, 0]]
```

`good`에서는 comprehension이 반복마다 새 inner list object를 만들기 때문에 outer list의 각 slot이 서로 다른 list를 가리킨다.

### Slicing과 copy

sequence type은 slicing으로 일부 구간을 새 container로 만들 수 있다.

| 연산/메서드 | 구분 | 예 | 결과 object | copy 깊이 |
| :--- | :--- | :--- | :--- | :--- |
| `s[i:j]` | slicing operator | `nums[1:4]` | 새 sequence | shallow |
| `s[i:j:k]` | extended slicing operator | `nums[::2]` | 새 sequence | shallow |
| `s[:]` | 전체 slicing copy | `nums[:]` | 새 sequence | shallow |
| `list.copy()` | list method | `nums.copy()` | 새 list | shallow |
| `copy.copy(obj)` | copy module function | `copy.copy(nums)` | 새 outer object | shallow |
| `copy.deepcopy(obj)` | copy module function | `copy.deepcopy(matrix)` | 내부 object까지 새로 복제 | deep |
| `B = A` | assignment | `B = A` | 새 object 없음 | reference 공유 |

```python
nums = [0, 1, 2, 3, 4]
print(nums[1:4])
print(nums[:3])
print(nums[::2])
```

`list.copy()`, `copy.copy()`, slicing은 보통 shallow copy 관점에서 이해한다. 내부에 mutable object가 들어 있는 다중 container는 내부 object까지 독립 복제하려면 `copy.deepcopy()`가 필요하다.

```python
import copy

L1 = [[1, 2], [3, 4]]
L2 = L1.copy()
L3 = copy.deepcopy(L1)
```

| 연산/메서드 | 복사 방식 | 새 outer container | 내부 mutable item |
| :--- | :--- | :--- | :--- |
| `B = A` | reference 공유 | 공유 | 공유 |
| `A[:]`, `A.copy()`, `copy.copy(A)` | shallow copy | 새로 생성 | 공유 |
| `copy.deepcopy(A)` | deep copy | 새로 생성 | 내부 item도 재귀적으로 복사 |

shallow copy는 outer container만 새로 만들고, 내부 slot의 reference는 그대로 복사한다. 내부 item이 `int`, `str`, `tuple`처럼 immutable이면 문제가 잘 드러나지 않지만, 내부 item이 `list`, `dict`, `set`처럼 mutable이면 한쪽에서 내부 object를 바꾼 결과가 다른 container에서도 보일 수 있다.

```python
L1 = [[1, 2], [3, 4]]
L2 = L1.copy()

L2[0].append(99)
print(L1)       # [[1, 2, 99], [3, 4]]
print(L2)       # [[1, 2, 99], [3, 4]]
```

위 예제에서 `L1`과 `L2`는 서로 다른 outer list지만, `L1[0]`과 `L2[0]`은 같은 inner list object를 가리킨다.

`in`, `not in`은 iterable 안에 item이 존재하는지 확인하는 membership 연산이다.

```python
print(3 in [1, 2, 3])
print("a" not in "Python")
```
