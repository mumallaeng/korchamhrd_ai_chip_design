# 26-07-10 - Python Exception, Module, Package, Class

관련 노트:

- [260706-python-basic-syntax.md](260706-python-basic-syntax.md)
- [260707-python-object-name-binding-container-operations.md](260707-python-object-name-binding-container-operations.md)
- [260708-python-built-in-functions-user-defined-functions.md](260708-python-built-in-functions-user-defined-functions.md)
- [260709-python-comprehension-control-flow-container-methods.md](260709-python-comprehension-control-flow-container-methods.md)

## 수업 흐름

0710 수업은 Python 전체 마무리 범위로 두고, 전날까지 정리한 1장부터 10장 이후의 후속 내용을 이어서 정리한다. 현재 초안은 11장 `Exception, Module, Package`와 12장 `사용자 Class 생성`을 중심으로 구성하고, 수업 중 실제 진행 범위에 맞춰 내용을 추가하거나 순서를 조정한다.

| 구분 | 내용 |
| :--- | :--- |
| 진행 범위 | Python 전체 마무리, 11장 `Exception, Module, Package`, 12장 `사용자 Class 생성` |
| 이전 범위 | 8장 `Comprehensions`, 9장 `제어문, 반복문`, 10장 `주요 Container 메서드` |
| 작성 상태 | 수업 중 실제 진행 범위에 맞춰 계속 보완 |

## 실습 자료와 진행 범위

| 장 | 주제 | 핵심 확인 |
| :--- | :--- | :--- |
| 11장 | Exception, Module, Package | `try`/`except`, `else`, `finally`, module/package import 구조 |
| 12장 | 사용자 Class 생성 | class/instance namespace, `__init__`, special method, 상속, class/static method |
| Python 전체 | 후반부 정리 | 기존 1장부터 10장 내용과 연결하며 보완 |

## 11. Exception, Module, Package

11장은 runtime error를 처리하는 exception 문법과, 코드를 여러 파일로 분리해서 사용하는 module/package 구조를 다룬다.

exception은 프로그램 실행 흐름에서 오류나 예외 상황이 발생했음을 나타내는 object다. exception이 처리되지 않으면 현재 실행 흐름은 중단되고 traceback이 출력된다. Python에서 제공하는 built-in exception의 종류와 계층 구조는 공식 문서의 [Built-in Exceptions](https://docs.python.org/3/library/exceptions.html)에서 확인할 수 있다.

| 구분 | 예시 | 의미 |
| :--- | :--- | :--- |
| name lookup 오류 | `NameError` | 정의되지 않은 name 참조 |
| type/value 오류 | `TypeError`, `ValueError` | 연산 대상 type 불일치, 값 형식 부적합 |
| index/key 오류 | `IndexError`, `KeyError` | sequence index 범위 초과, mapping key 없음 |
| syntax 계열 오류 | `SyntaxError`, `IndentationError` | 실행 전 parsing/compile 단계에서 발견되는 문법 문제 |
| base 계열 | `BaseException`, `Exception` | 대부분의 일반 exception이 따르는 상위 class |

수업에서 다루는 `try`/`except`는 주로 실행 중 발생한 exception을 잡아 프로그램이 바로 종료되지 않게 처리하는 문법이다. 단, 모든 exception을 무조건 숨기는 것이 목적은 아니며, 어떤 오류를 어떤 범위에서 처리할지 명확히 정해야 한다.

### `try`와 `except`

`try` block에서 오류가 발생하면 Python은 맞는 `except` block으로 이동한다. 오류가 발생하지 않으면 `except`는 실행되지 않는다.

```python
try:
    a = b
except NameError:
    print("NameError")
```

`except`에는 처리할 exception class를 지정할 수 있다. 예를 들어 `except TypeError:`는 `TypeError` 계열 exception만 처리하고, `except ValueError:`는 `ValueError` 계열 exception만 처리한다. 발생한 exception의 type이 지정한 class와 맞지 않으면 그 `except` block은 실행되지 않는다.

오류 종류를 정확히 모를 때는 대부분의 일반 error object가 따르는 상위 class인 `Exception`으로 받을 수 있다. `Exception`은 일반 프로그램 오류를 넓게 잡을 때 사용하는 기준이고, `KeyboardInterrupt`, `SystemExit` 같은 `BaseException` 직계 계열까지 모두 잡는 것은 보통 피한다.

```python
try:
    a = int("3.14")
except Exception as e:
    print(type(e).__name__, e)
```

`as e`는 발생한 error object에 `e`라는 alias를 붙이는 문법이다. `e`를 통해 exception message나 type 정보를 확인할 수 있고, `type(e).__name__`으로 오류 이름을 확인할 수 있다.

```python
try:
    value = int("3.14")
except TypeError as e:
    print("type error:", e)
except ValueError as e:
    print("value error:", e)
except Exception as e:
    print("other error:", type(e).__name__, e)
```

여러 `except`를 쓸 때는 구체적인 exception을 먼저 쓰고, 넓은 `Exception`은 마지막에 두는 것이 안전하다. `except Exception`을 먼저 쓰면 뒤의 `except TypeError`, `except ValueError` 같은 구체적인 block까지 도달하지 못한다.

### `else`, `finally`, 여러 `except`

`try` statement는 최소한 `try` block과 exception을 처리할 `except` block을 포함해야 한다. `else`와 `finally`는 선택적으로 붙일 수 있다. 오류가 발생했을 때 실행할 코드는 `except`, 오류가 발생하지 않았을 때만 실행할 코드는 `else`, 오류 발생 여부와 관계없이 항상 실행할 정리 코드는 `finally`에 둔다.

| 구문 | 실행 조건 |
| :--- | :--- |
| `except` | 지정한 오류 발생 |
| `else` | 오류 없이 `try` 완료 |
| `finally` | 오류 여부와 무관하게 항상 실행 |

| 구성 | 필수 여부 | 용도 |
| :--- | :--- | :--- |
| `try` | 필수 | exception 발생 가능성이 있는 코드 |
| `except` | 일반적인 exception 처리 구조에서 필수 | 발생한 exception 처리 |
| `else` | 선택 | exception이 없을 때만 실행할 후속 코드 |
| `finally` | 선택 | 성공/실패와 관계없이 수행할 정리 코드 |

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

module은 하나의 파일 형태로 작성되는 Python code 단위이며, 일반적으로 `module_name.py` 형태로 저장된다. 함수, class, 상수, 실행 코드 일부를 한 파일에 모두 넣지 않고 여러 파일로 나누어 관리할 때 사용한다.

Python에는 직접 작성한 module 외에도 Python 자체가 제공하는 built-in module과 standard library module이 있다. 엄밀히 말하면 `sys`처럼 interpreter에 built-in으로 포함된 module과, `os`, `pickle`, `glob`처럼 Python 배포판에 함께 제공되는 standard library module은 구분된다. 수업에서는 넓게 묶어 '내장/표준 모듈'처럼 부를 수 있다.

package는 module들을 모아 둔 directory 단위다. 관련 module들을 하나의 namespace 아래에 묶어서 관리할 때 사용한다. 외부에서 설치해 사용하는 package도 많으며, 데이터 수집, 데이터 처리, machine learning/deep learning, 이미지 처리, 시각화, 웹 개발, 자연어 처리처럼 특정 목적에 맞게 만들어진 공개 package들이 대표적이다.

| 구분 | 형태 | 용도 | 예시 |
| :--- | :--- | :--- | :--- |
| module | 하나의 `.py` 파일 | 함수, class, 실행 code 일부 분리 | `my_module.py`, `math`, `sys` |
| package | module을 모아 둔 directory | 관련 module 묶음과 namespace 구성 | `my_package/`, `numpy`, `pandas` |
| import | module/package name을 현재 namespace에 binding | 다른 파일의 code 사용 | `import math`, `import numpy as np` |

Python에서 자주 쓰는 built-in/standard library module 예시는 다음과 같다.

| module | 주요 용도 |
| :--- | :--- |
| `sys` | interpreter 실행 환경, command-line argument, module search path 확인 |
| `pprint` | 복잡한 container를 읽기 좋게 출력 |
| `os` | 운영체제 경로, 환경 변수, process 관련 기능 |
| `pickle` | Python object 직렬화/역직렬화 |
| `shelve` | key-value 형태의 간단한 object 저장 |
| `glob` | wildcard pattern 기반 파일 경로 검색 |
| `itertools` | iterator 조합, 반복 패턴 생성 |
| `copy` | shallow copy, deep copy |

외부 package는 보통 `pip` 같은 package manager로 설치한 뒤 사용한다. package 이름과 import 이름이 다를 수 있으므로 공식 문서의 설치명과 import명을 같이 확인한다.

| 분야 | package/module 예시 | 주요 용도 |
| :--- | :--- | :--- |
| 데이터 수집 | `beautifulsoup4`(`bs4`), `selenium` | HTML parsing, browser 자동화 |
| 데이터 처리 | `numpy`, `pandas` | 수치 배열 연산, table/dataframe 처리 |
| ML/DL | `scikit-learn`(`sklearn`), `tensorflow`, `keras` | machine learning, deep learning model 구성 |
| 이미지 처리 | `Pillow`(`PIL`), `opencv-python`(`cv2`) | image file 처리, computer vision |
| 시각화/그래프 | `matplotlib`, `seaborn`, `bokeh` | graph plotting, 통계 시각화, interactive visualization |
| HTTP/웹페이지 | `requests`, `django` | HTTP client, web framework |
| 자연어 처리 | `NLTK`, `TextBlob` | tokenizing, tagging, sentiment 등 NLP 기초 처리 |

`import` statement는 module object를 현재 namespace에 binding한다. 기본 형태는 다음과 같다.

```python
import module_name [as alias] [, module_name2 [as alias2]] ...
```

실제 코드에서는 아래처럼 쓴다.

```python
import os
import sys as system
import math, random as rd
```

`as`를 사용하면 원래 module name 대신 현재 namespace에서 사용할 대체 name을 binding한다. 예를 들어 `import numpy as np`는 `numpy` module object를 `np`라는 name에 binding하는 것이다.

module 안의 특정 name만 현재 namespace로 직접 가져올 때는 `from ... import ...` 형태를 사용한다.

```python
from module_name import name [, name2 ...]
from module_name import name as alias
from module_name import *
```

예를 들어 `math` module 전체를 가져오면 `math.sqrt()`처럼 module name을 붙여 접근한다.

```python
import math
print(math.sqrt(16))
```

반면 `from math import sqrt`는 `sqrt` function object 자체를 현재 namespace에 binding하므로 바로 `sqrt()`로 호출할 수 있다.

```python
from math import sqrt
print(sqrt(16))
```

정확히는 `import`와 `from ... import ...` 모두 현재 namespace에 name을 binding한다. module 최상위에서 실행하면 module의 global namespace에 들어가고, function 안에서 실행하면 그 function의 local namespace에 들어간다. 차이는 '파일 정보'와 '주소 정보'가 따로 저장되는 것이 아니라, 어떤 object를 어떤 name으로 binding하느냐에 있다.

| 구문 | 현재 namespace에 binding되는 name | binding 대상 | 접근 방식 |
| :--- | :--- | :--- | :--- |
| `import math` | `math` | `math` module object | `math.sqrt(16)` |
| `import math as m` | `m` | `math` module object | `m.sqrt(16)` |
| `from math import sqrt` | `sqrt` | `math` module의 `sqrt` function object | `sqrt(16)` |
| `from math import sqrt as root` | `root` | `math` module의 `sqrt` function object | `root(16)` |
| `from math import *` | module이 공개한 여러 name | 각 name이 가리키는 object | `sqrt(16)`, `pi` |

`import math`를 하면 `math`라는 name은 module object를 가리킨다. 이 module object 안에는 `sqrt`, `pi`, `__file__`, `__dict__` 같은 attribute가 있고, `math.sqrt`는 module object의 namespace에서 `sqrt`라는 attribute를 찾는 표현이다.

`from math import sqrt`도 내부적으로는 `math` module을 import한 뒤, 그 module 안의 `sqrt` attribute가 가리키는 function object를 현재 namespace의 `sqrt` name에 직접 binding한다. 따라서 `sqrt()`처럼 module name 없이 호출할 수 있다. Python에서 name은 object에 대한 reference를 binding하는 것이므로, 이를 실제 memory address 정보로 이해하기보다는 '현재 namespace의 name이 어떤 object를 가리키는가'로 이해하는 편이 정확하다.

`from module import *`는 module이 공개한 여러 name을 현재 namespace로 한 번에 가져온다. 간단한 실습에서는 편할 수 있지만, 어떤 name이 어디서 왔는지 흐려지고 기존 name을 덮어쓸 수 있으므로 일반 code에서는 필요한 name만 명시하는 편이 좋다.

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

### instance data와 method 공유 구조

Python 공식 문서 기준으로 instance object에서 접근할 수 있는 attribute는 크게 data attribute와 method로 나뉜다. data attribute는 미리 선언하지 않아도 `self.name = value`처럼 처음 대입될 때 instance namespace에 생긴다. 따라서 class 하나에서 여러 instance를 만들면 method code는 class 쪽에서 공유하고, 상태 data는 instance별로 따로 저장할 수 있다.

```python
class Counter:
    def __init__(self):
        self.count = 0

    def inc(self):
        self.count += 1

a = Counter()
b = Counter()

a.inc()
a.inc()
b.inc()

print(a.__dict__)  # {'count': 2}
print(b.__dict__)  # {'count': 1}
```

위 코드에서 `count`는 `a`와 `b`의 instance namespace에 각각 저장된다. 반면 `inc` function object는 `Counter` class namespace에 하나만 존재한다. `a.inc()`를 호출하면 Python은 class에 있는 function object와 instance object `a`를 묶어 bound method object를 만들고, 호출 시 `a`를 첫 번째 argument로 넣는다.

```python
print(Counter.__dict__['inc'] is a.inc.__func__)  # True
print(a.inc.__self__ is a)                        # True
print(b.inc.__self__ is b)                        # True

Counter.inc(a)
Counter.inc(b)
```

따라서 `a.inc()`는 개념적으로 `Counter.inc(a)`와 같은 방식으로 동작한다. 함수 code는 공유되지만 `self`가 가리키는 instance가 다르기 때문에 각 instance의 독립적인 변수만 갱신된다.

| 구분 | 저장 위치 | 공유 여부 | 의미 |
| :--- | :--- | :--- | :--- |
| method function object | class namespace | instance들이 공유 | 동작 code 재사용 |
| instance data attribute | instance namespace | instance별 분리 | 독립 상태 저장 |
| bound method object | attribute reference 시 생성 | function과 instance를 묶은 호출 wrapper | `self` 자동 전달 |
| `self` | 호출 시 첫 번째 argument | 호출한 instance마다 다름 | 갱신 대상 결정 |

함수만 사용하면 상태를 global 변수나 별도 parameter/return 값으로 관리해야 하므로 독립적인 상태 여러 개를 다루기 번거롭다. class를 사용하면 같은 method code를 재사용하면서도 instance마다 별도 변수를 갖게 되어 서로 독립적으로 동작하는 object를 여러 개 만들 수 있다.

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

여기서 method namespace라고 부르는 것은 method object 자체가 별도 data 저장소가 된다는 뜻이 아니라, method/function이 호출될 때 만들어지는 local namespace를 의미한다. `def f1(self, x): ...` 안의 parameter `self`, `x`와 local name `y`는 그 호출의 local namespace에 binding된다.

### attribute lookup과 assignment

`.`은 attribute reference로, 왼쪽 object를 기준으로 어떤 namespace에서 name을 찾을지 지정한다. 따라서 `self.b`, `obj.b`, `CLS.a`는 그냥 `b`, `a`를 찾는 것이 아니라 각각 `self`, `obj`, `CLS`를 출발점으로 attribute를 찾는 표현이다.

읽기와 쓰기는 동작이 다르다.

| 형태 | 동작 | 실패 시 |
| :--- | :--- | :--- |
| `name` 읽기 | 현재 local namespace부터 enclosing/global/built-in 방향으로 name resolution | `NameError` |
| `obj.attr` 읽기 | instance namespace 확인 후 class namespace와 base class 방향으로 attribute lookup | `AttributeError` |
| `CLS.attr` 읽기 | class namespace 확인 후 base class 방향으로 attribute lookup | `AttributeError` |
| `name = value` | 현재 scope 규칙에 맞는 namespace에 생성 또는 갱신 | 대입 자체는 새 name 생성 가능 |
| `obj.attr = value` | `obj`가 지정한 namespace에 attribute 생성 또는 갱신 | 일반적으로 class namespace 검색 없이 instance 쪽 갱신 |
| `CLS.attr = value` | `CLS` class namespace에 attribute 생성 또는 갱신 | base class의 namespace를 직접 갱신하지 않음 |

```python
class Sample:
    value = 10

    def update(self):
        local_value = 1          # method 호출의 local namespace
        print(self.value)        # instance에서 찾고, 없으면 class에서 찾음
        self.value = 20          # instance namespace에 생성/갱신
        Sample.value = 30        # class namespace에 갱신

s1 = Sample()
s2 = Sample()

print(s1.value, s2.value)        # 10 10, class attribute 읽기
s1.value = 100                   # s1 instance namespace에만 생성
print(s1.value, s2.value)        # 100 10
print(Sample.value)              # 10
```

`self.a += x`처럼 augmented assignment를 쓰면 읽기와 쓰기가 모두 일어난다. 먼저 `self.a`를 읽을 때 instance namespace에서 찾고, 없으면 class namespace까지 탐색한다. 그 다음 계산 결과를 다시 `self.a`에 대입할 때는 instance namespace에 attribute를 생성하거나 갱신한다.

```python
class Acc:
    a = 10

    def add(self, x):
        self.a += x

obj = Acc()
obj.add(5)

print(Acc.a)    # 10, class variable 유지
print(obj.a)    # 15, instance variable 생성
```

따라서 읽기는 `instance -> class -> base class` 방향으로 탐색할 수 있지만, 쓰기는 표현식의 target이 지정한 namespace를 갱신한다고 보는 편이 정확하다. `obj.attr`이 없으면 attribute 읽기에서는 `AttributeError`가 발생하고, `attr`처럼 bare name을 찾지 못하면 `NameError`가 발생한다.

### `__new__`, `__init__`, class 문서 문자열

class를 호출하면 instance 생성 과정이 시작된다. Python data model 기준으로 class object는 callable이고, 호출되면 보통 새 instance를 만드는 factory처럼 동작한다. 이때 생성 단계와 초기화 단계가 나뉜다.

| 단계 | special method | 역할 | 일반적인 재정의 상황 |
| :--- | :--- | :--- | :--- |
| instance 생성 | `__new__(cls, ...)` | 새 instance object 생성 후 반환 | immutable type subclass, 생성 자체 제어 |
| instance 초기화 | `__init__(self, ...)` | 생성된 instance의 attribute 초기화 | 대부분의 초기값 설정 |

`__new__()`는 class가 호출될 때 새 instance를 실제로 만드는 method다. 보통 직접 재정의하지 않고 `object.__new__()`의 기본 동작을 사용한다. `__new__()`가 해당 class의 instance를 반환하면 그 다음 `__init__()`이 호출되어 초기화가 진행된다. 반대로 `__new__()`가 해당 class의 instance를 반환하지 않으면 `__init__()`은 호출되지 않는다.

초기값을 가진 instance를 만들려면 일반적으로 `__init__()`을 재정의하면 충분하다. `__init__()`은 instance가 이미 생성된 뒤 호출되므로, `self.name = value`처럼 instance namespace에 data attribute를 설정하는 데 사용한다. `__init__()`은 instance를 반환하는 함수가 아니며, `None`이 아닌 값을 반환하면 오류가 발생한다.

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

위 코드에서 `Mart_Calc(10)`을 실행하면 개념적으로 다음 순서가 진행된다.

```text
1. `Mart_Calc.__new__(Mart_Calc, 10)` 계열의 생성 단계
2. 새 instance 반환
3. `Mart_Calc.__init__(instance, 10)` 호출
4. `self.s = 10`으로 instance namespace 초기화
5. 초기화된 instance가 호출자에게 반환
```

첫 번째 parameter 이름 `self`는 Python 문법상의 keyword가 아니라 관례다. 다만 instance method 호출 시 instance가 첫 번째 argument로 자동 전달되므로, 일반적으로 `self`라는 이름을 사용한다.

class 안의 첫 문자열은 class 설명으로 저장되며 `__doc__`으로 확인할 수 있다. class 변수로 전체 instance 개수를 관리할 수도 있다.

```python
class Mart_Calc:
    "Mart Self Calculator"
    cnt = 0

    def __init__(self, x):
        self.s = x
        Mart_Calc.cnt += 1
```

```python
print(Mart_Calc.__doc__)  # Mart Self Calculator
```

class body 바로 다음 줄의 문자열 literal은 class docstring이 된다. 이 문자열은 `help(Mart_Calc)`나 `Mart_Calc.__doc__`에서 확인할 수 있다.

### `del` statement와 `__del__`

사용하지 않는 instance name은 `del` statement로 현재 namespace에서 binding을 제거할 수 있다. `del`은 함수가 아니므로 `del(obj)`가 아니라 `del obj`처럼 쓴다.

```python
usr = Mart_Calc(10)
del usr
```

`del usr`는 `usr`라는 name binding을 namespace에서 삭제한다. 이 동작은 object를 직접 강제로 파괴한다기보다, 해당 name이 object를 더 이상 참조하지 않게 만드는 것이다. 같은 object를 가리키는 다른 reference가 남아 있으면 object는 계속 살아 있다.

```python
a = Mart_Calc(10)
b = a

del a          # a name만 제거, b가 여전히 instance를 참조
print(b.s)     # 10
```

모든 reference가 사라지면 object는 소멸 대상이 되고, 그 시점에 `__del__()` finalizer가 호출될 수 있다. 다만 `__del__()`은 실행 시점과 실행 여부를 일반적인 자원 정리 코드처럼 강하게 기대하기 어렵다. 파일, 네트워크, lock 같은 외부 자원은 가능하면 `with` statement나 명시적 `close()` 계열 method로 정리하는 편이 안전하다.

instance 소멸 시 동작을 넣으려면 `__del__()`을 정의할 수 있다. 수업 예제에서는 계산기를 반납할 때 class 변수 `cnt`를 줄이는 흐름으로 사용한다.

```python
class Mart_Calc:
    cnt = 0

    def __init__(self, x):
        self.s = x
        Mart_Calc.cnt += 1

    def __del__(self):
        Mart_Calc.cnt -= 1
```

정리하면 `del`은 namespace에서 name binding을 제거하는 statement이고, `__del__()`은 object가 실제로 소멸될 때 호출될 수 있는 finalizer다. `del`을 사용하는 목적은 더 이상 쓰지 않는 name/reference를 제거하여 object가 garbage collection 대상이 될 수 있게 하는 것이다. namespace에 남은 name이 많아 lookup이 조금 복잡해지는 것보다, 불필요한 reference가 남아 object와 그 내부 data가 계속 유지되는 문제를 막는 의미가 더 크다.

### Special method와 operator overloading

Python에서 `__name__`처럼 앞뒤에 double underscore가 붙은 이름은 special name 또는 dunder name으로 부른다. 이 이름들은 Python data model에서 미리 약속된 의미를 갖는다.

| 구분 | 이름 형태 | 역할 | 예시 |
| :--- | :--- | :--- | :--- |
| special attribute | `__name__`, `__doc__`, `__dict__`, `__class__` | system이 정의한 특수 목적 attribute | class 설명, object namespace, object의 class 확인 |
| special method | `__init__()`, `__add__()`, `__len__()`, `__getitem__()` | 연산자, built-in 함수, object protocol과 연결되는 method | 초기화, `+`, `len()`, indexing |

special attribute는 읽기 전용인 것도 있고 writable인 것도 있다. 예를 들어 `obj.__class__`는 object가 속한 class를 나타내는 special attribute이고, `obj.__dict__`는 writable attribute를 저장하는 namespace mapping이다. 반면 모든 object가 `__dict__`를 갖는 것은 아니며, 일부 special attribute는 직접 수정하지 않는 것이 원칙이다.

Python의 special attribute와 special method는 Python 공식 문서의 [Data model](https://docs.python.org/3/reference/datamodel.html)에서 object model, class, module, operator protocol 기준으로 정리되어 있다. 수업에서 확인한 대표 항목은 다음처럼 나눠서 볼 수 있다.

| 이름 | 구분 | 확인 예시 | 의미 |
| :--- | :--- | :--- | :--- |
| `__doc__` | special attribute | `CLS.__doc__` | class/function/module의 docstring |
| `__dict__` | special attribute | `obj.__dict__` | writable attribute 저장 namespace mapping |
| `__builtins__` | module global name | `globals()["__builtins__"]` | built-in namespace 접근 기준 |
| `__name__` | special attribute | `__name__`, `func.__name__` | module/function/class name |
| `__package__` | module attribute | `__package__` | package context, relative import 기준 |
| `__class__` | special attribute | `obj.__class__` | object가 속한 class |

`__builtins__`는 module global namespace에 들어오는 built-in 접근용 name이다. built-in name resolution에서 마지막으로 찾는 namespace와 연결되지만, 일반 application code에서 직접 수정하는 대상으로 보지는 않는다.

object를 문자열로 표현하거나 built-in 함수와 연결하는 special method는 다음과 같다.

| special method | 연결 표현 | 용도 |
| :--- | :--- | :--- |
| `__repr__(self)` | `repr(obj)` | debugging용 공식 표현 |
| `__str__(self)` | `str(obj)`, `print(obj)` | 사람이 읽기 좋은 문자열 표현 |
| `__format__(self, format_spec)` | `format(obj, spec)`, f-string, `str.format()` | format spec에 따른 문자열 표현 |
| `__hash__(self)` | `hash(obj)` | `set`, `frozenset`, `dict` key에서 사용하는 hash value |
| `__dir__(self)` | `dir(obj)` | object에서 확인 가능한 name 목록 |

container, subscription, iterator protocol과 연결되는 special method는 다음과 같다.

| special method | 연결 표현 | 용도 |
| :--- | :--- | :--- |
| `__len__(self)` | `len(obj)` | 길이 반환, `0`이면 truth value 판단에도 영향 |
| `__getitem__(self, key)` | `obj[key]` | index/key/slice 접근 |
| `__setitem__(self, key, value)` | `obj[key] = value` | mutable container의 item 대입 |
| `__delitem__(self, key)` | `del obj[key]` | mutable container의 item 삭제 |
| `__iter__(self)` | `iter(obj)`, `for x in obj` | iterator object 반환 |
| `__next__(self)` | `next(iterator)` | iterator의 다음 item 반환 |
| `__reversed__(self)` | `reversed(obj)` | 역방향 iterator 반환 |
| `__contains__(self, item)` | `item in obj` | membership test 직접 구현 |

`__iter__()`는 iterable object가 iterator를 제공할 때 쓰이고, `__next__()`는 실제 iterator object가 다음 값을 제공할 때 쓰인다. 따라서 직접 container class를 만들 때는 보통 `__iter__()`가 iterator를 반환하고, 그 iterator object가 `__next__()`를 가진다고 이해하면 된다.

special method는 표준 연산자나 일부 built-in 함수의 overloading을 위해 약속된 method다. 사용자가 임의로 `__add__()`라는 이름을 정한 것이 아니라, Python이 `+` 연산을 처리할 때 그 이름을 찾도록 data model에서 정해 둔 것이다.

Python의 표준 연산자와 일부 built-in 함수는 class에 정의된 special method와 연결된다. Python 인터프리터는 `+` 기호를 보면 문법적으로 binary addition expression으로 해석하고, 실제 덧셈 동작은 operand type에 맞는 special method lookup을 통해 처리한다. 즉 `a + b`는 `type(a)` 쪽의 `__add__()` 계열 동작과 연결된다.

```python
a, b = 3, 5
print(a + b)
print(int.__add__(a, b))
print(a.__add__(b))
```

`+` 하나가 숫자 덧셈, 문자열 연결, list 연결처럼 다르게 동작하는 이유도 operand의 type이 다르고, 각 type이 제공하는 `__add__()` 구현이 다르기 때문이다.

```python
print((3).__add__(5))             # 8
print("py".__add__("thon"))       # python
print([1, 2].__add__([3, 4]))     # [1, 2, 3, 4]
```

| 표현 | 연결되는 special method | 의미 |
| :--- | :--- | :--- |
| `a + b` | `type(a).__add__(a, b)` 계열 | 덧셈 또는 sequence 결합 |
| `a - b` | `type(a).__sub__(a, b)` 계열 | 뺄셈 |
| `a * b` | `type(a).__mul__(a, b)` 계열 | 곱셈 또는 sequence 반복 |
| `a % b` | `type(a).__mod__(a, b)` 계열 | 나머지 |
| `a / b` | `type(a).__truediv__(a, b)` 계열 | true division |
| `a // b` | `type(a).__floordiv__(a, b)` 계열 | floor division |
| `a < b` | `type(a).__lt__(a, b)` 계열 | less-than 비교 |
| `a <= b` | `type(a).__le__(a, b)` 계열 | less-than-or-equal 비교 |
| `a == b` | `type(a).__eq__(a, b)` 계열 | equality 비교 |
| `a != b` | `type(a).__ne__(a, b)` 계열 | inequality 비교 |
| `a > b` | `type(a).__gt__(a, b)` 계열 | greater-than 비교 |
| `a >= b` | `type(a).__ge__(a, b)` 계열 | greater-than-or-equal 비교 |
| `abs(a)` | `type(a).__abs__(a)` 계열 | 절댓값 또는 사용자 정의 단항 연산 |
| `divmod(a, b)` | `type(a).__divmod__(a, b)` 계열 | `//`와 `%` 결과를 함께 반환 |
| `round(a)` | `type(a).__round__(a)` 계열 | 반올림 |
| `round(a, n)` | `type(a).__round__(a, n)` 계열 | `n` 자리 기준 반올림 |
| `len(a)` | `type(a).__len__(a)` 계열 | 길이 계산 |
| `a[i]` | `type(a).__getitem__(a, i)` 계열 | indexing/subscription |

이처럼 연산자나 built-in 함수에 대응하는 special method를 class에서 재정의하면, 해당 class의 instance에 대해 연산자와 built-in 함수 매칭이 가능해진다. 예를 들어 `usr1 + 30`을 실행하면 Python은 `+`에 대응하는 special method인 `__add__()`를 찾아 호출하고, 그 method body가 실제 연산 동작을 수행한다. 같은 연산자 표기가 사용자 정의 object에 맞는 동작을 하도록 만드는 것을 operator overloading이라고 한다.

비교 연산자는 rich comparison method라고 부른다. `__lt__`, `__le__`, `__eq__`, `__ne__`, `__gt__`, `__ge__`는 서로 자동으로 의미가 추론되는 관계가 아니므로, 필요한 비교 기준을 명시적으로 구현해야 한다. 특히 `__eq__()`를 직접 정의하고 object를 `dict` key나 `set` item으로 쓰려면 `__hash__()`와의 일관성도 함께 고려해야 한다.

직접 만든 class에서도 `__add__()`, `__gt__()`, `__abs__()` 같은 special method를 재정의하면 아래처럼 `+`, `>`, `abs()`의 동작을 정할 수 있다.

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

class를 이용해 새로운 child class를 만들 때 상속받을 parent class를 지정할 수 있다. `class Child(Parent):` 형태로 선언하면 child class는 parent class의 method와 attribute를 사용할 수 있다. 이것이 상속의 기본 개념이다.

상속은 parent class의 자산을 child class에서 재사용하는 구조다. child instance에서 attribute나 method를 찾을 때 먼저 자기 instance namespace를 확인하고, 없으면 child class namespace를 확인한 뒤, parent class namespace 방향으로 올라가며 찾는다. 따라서 child가 직접 갖고 있지 않은 method나 class attribute라도 parent에 정의되어 있으면 사용할 수 있다.

| 구분 | 탐색 대상 | 의미 |
| :--- | :--- | :--- |
| instance namespace | `child_obj.__dict__` | instance별 data 우선 확인 |
| child class namespace | `Child.__dict__` | child가 직접 정의한 method/attribute 확인 |
| parent class namespace | `Parent.__dict__` | 상속받은 method/attribute 확인 |
| 더 상위 class | MRO 순서 | `object`까지 이어지는 탐색 |

```python
class Parent_CLS:
    a = 10

    def f(self, x):
        print("P_CLS:", x)

class Child_CLS(Parent_CLS):
    def __init__(self):
        print("C_CLS")

child = Child_CLS()
print(child.a)      # instance와 Child_CLS에 없으므로 Parent_CLS.a 사용
child.f(100)        # Parent_CLS.f를 method로 사용
```

parent class의 초기화자를 호출하려면 `super()`를 사용한다. `super()`는 현재 class의 MRO 기준으로 다음 class의 method를 찾아 호출할 수 있게 해 주는 proxy다. 단일 상속에서는 실질적으로 parent class의 method를 호출하는 것처럼 동작하므로, `super().__init__(x)`로 parent의 초기화자를 호출해 parent가 담당하는 instance 초기화 코드를 재사용할 수 있다.

```python
class New_Calc(Mart_Calc):
    def __init__(self, x):
        super().__init__(x)

    def sub(self, x):
        self.s -= x
```

`New_Calc`의 `sub()`처럼 child class에서 새로 추가한 method는 child class의 고유 자산이다. 이 method는 parent class인 `Mart_Calc`의 instance에서는 사용할 수 없고, `New_Calc` instance에서만 사용할 수 있다. child instance는 상속받은 parent 자산과 child class에서 추가한 고유 자산을 모두 사용할 수 있으므로, 기존 기능을 유지하면서 기능을 확장할 때 상속을 사용할 수 있다.

| class | 사용 가능한 자산 | 예시 |
| :--- | :--- | :--- |
| parent class | parent가 직접 정의한 method/attribute | `Mart_Calc.add()` |
| child class | parent에서 상속받은 자산 + child가 추가한 고유 자산 | `New_Calc.add()`, `New_Calc.sub()` |

child class에서 parent와 같은 이름의 method나 class variable을 다시 정의하면 overriding이 발생한다. Overriding은 parent로부터 상속받은 자산을 child class의 자산으로 바꾸는 개념이다. child class는 parent class를 상속받았지만, 같은 이름의 method나 class variable을 child namespace에 다시 정의하면 parent 쪽에 있던 동일 이름의 자산은 attribute lookup 과정에서 뒤로 밀리고 child 쪽 정의가 먼저 사용된다.

즉, overriding은 parent의 method나 class variable과 동일한 이름을 child class에서 재정의하여, 상속받은 기본 동작을 무시하고 child class에 맞는 다른 동작으로 변경하는 방식이다.

```python
class New_Calc(Mart_Calc):
    s = 20

    def add(self, x):
        print("add")
```

위 예제에서 `New_Calc.add()`는 parent의 `Mart_Calc.add()`와 같은 이름으로 다시 정의된 method다. `New_Calc` instance에서 `add()`를 호출하면 `New_Calc` namespace의 `add()`가 먼저 발견되므로 parent의 `add()`가 아니라 child에서 재정의한 동작이 실행된다. `s = 20`도 같은 이름의 class variable을 child class namespace에 새로 둔 것이므로, `New_Calc.s`는 parent의 `Mart_Calc.s`가 아니라 child의 `s`를 우선 사용한다.

Name 탐색은 해당 class의 namespace에서 시작해 MRO 순서대로 parent class namespace를 따라 올라간다. MRO는 `Method Resolution Order`의 약자로, Python이 상속 관계에서 method와 attribute를 어떤 class 순서로 찾을지 정한 순서다. Instance를 통해 method를 호출할 때는 먼저 instance namespace를 확인하고, 없으면 instance가 속한 class namespace에서 찾으며, 거기에도 없으면 MRO 순서대로 parent class 방향을 탐색한다. 그래서 child class가 같은 name을 갖고 있으면 parent class의 같은 name보다 먼저 선택된다.

| 구분 | 의미 |
| :--- | :--- |
| MRO | 상속 구조에서 method/attribute를 찾는 class namespace 탐색 순서 |
| 단일 상속 | 보통 `Child -> Parent -> object` 순서 |
| 다중 상속 | class 선언의 base class 순서와 중복 class 제거 규칙을 반영한 탐색 순서 |
| 확인 방법 | `ClassName.mro()`, `ClassName.__mro__` |
| `super()`와의 관계 | 현재 class 다음 MRO 위치의 method를 찾아 cooperative call 구성 |

상속 탐색 순서는 `mro()`로 확인할 수 있다.

```python
print(New_Calc.mro())
```

다중 상속에서는 class 선언의 parent 순서와 MRO에 따라 name을 찾는다. 단순히 모든 parent를 무작정 왼쪽부터 깊게 훑는 것이 아니라, 중복 class를 한 번만 방문하고 parent 선언 순서를 보존하는 방식으로 탐색 순서를 linearize한다.

```python
class Son(Father, Mother):
    pass
```

단순한 구조에서는 `Son -> Father -> Mother -> object`처럼 보일 수 있지만, `Father`와 `Mother`가 같은 조상 class를 공유하는 diamond 구조에서는 Python이 C3 linearization 규칙에 따라 일관된 MRO를 계산한다. 실제 순서는 `Son.mro()` 또는 `Son.__mro__`로 확인하는 것이 가장 정확하다.

```python
class A:
    pass

class B(A):
    pass

class C(A):
    pass

class D(B, C):
    pass

print(D.mro())
# [D, B, C, A, object] 형태
```

### class method와 static method

`classmethod`와 `staticmethod`는 class namespace에 정의해 두고 class 또는 instance를 통해 호출할 수 있는 method 형태다. 둘 다 특정 class와 관련된 utility 성격의 기능을 묶을 때 사용할 수 있지만, 자동으로 전달되는 첫 번째 argument가 다르다.

| 구분 | decorator | 자동 전달 인자 | 호출 형태 | 주 용도 |
| :--- | :--- | :--- | :--- | :--- |
| instance method | 없음 | instance object, 관례상 `self` | `obj.method()` | instance 상태 접근/변경 |
| class method | `@classmethod` | 호출한 class object, 관례상 `cls` | `ClassName.method()`, `obj.method()` | class 상태 접근, 대체 생성자, 상속 고려 utility |
| static method | `@staticmethod` | 없음 | `ClassName.method()`, `obj.method()` | class에 묶어 둔 일반 utility function |

class body 안에서 `def`로 만든 일반 function은 instance를 통해 접근될 때 bound method가 되고, instance가 첫 번째 argument `self`로 전달된다. `@classmethod`와 `@staticmethod`는 이 binding 방식을 바꾸는 decorator다. `@classmethod`는 function을 class method object로 감싸서, 접근할 때 instance가 아니라 class를 첫 번째 argument로 binding한다. `@staticmethod`는 function을 static method object로 감싸서, 접근하더라도 `self`나 `cls`를 binding하지 않고 원래 function처럼 호출되게 한다.

| 접근 표현 | instance method | class method | static method |
| :--- | :--- | :--- | :--- |
| `ClassName.method` | function 성격, 직접 호출 시 `self` 직접 전달 필요 | class가 binding된 method | 원래 function 성격 |
| `instance.method` | instance가 `self`로 binding된 method | instance의 class가 `cls`로 binding된 method | 원래 function 성격 |
| 자동 전달 값 | `self` | `cls` | 없음 |

`@classmethod`는 class 또는 instance로 호출해도 class object가 첫 번째 argument로 전달된다. 관례적으로 첫 번째 parameter 이름은 `cls`를 사용한다. instance로 호출한 경우에도 instance 자체가 전달되는 것이 아니라, 그 instance의 class가 `cls`로 전달된다. child class에서 class method를 호출하면 parent가 아니라 실제 호출한 child class object가 `cls`가 될 수 있으므로, 상속 구조에서 class별 동작을 유지하기 좋다.

```python
class My_CLS:
    s = 0

    @classmethod
    def c_method(cls):
        print("c_method:", cls.s)

class Child_CLS(My_CLS):
    s = 100

My_CLS.c_method()       # cls = My_CLS, 출력 0
Child_CLS.c_method()    # cls = Child_CLS, 출력 100
Child_CLS().c_method()  # cls = Child_CLS, 출력 100
```

class method가 특히 자주 쓰이는 경우는 대체 생성자다. 문자열, tuple, dict 같은 다른 형태의 입력을 받아 instance를 만들어야 할 때 `cls(...)`를 반환하면, parent class뿐 아니라 child class에서도 같은 생성 로직을 재사용할 수 있다.

```python
class User:
    def __init__(self, name, age):
        self.name = name
        self.age = age

    @classmethod
    def from_csv(cls, line):
        name, age = line.split(",")
        return cls(name, int(age))

class Admin(User):
    pass

u = User.from_csv("kim,20")
a = Admin.from_csv("lee,30")

print(type(u).__name__)  # User
print(type(a).__name__)  # Admin
```

위 코드에서 `from_csv()` 내부가 `User(name, age)`로 고정되어 있으면 `Admin.from_csv()`를 호출해도 `User` instance가 만들어진다. 반면 `cls(name, age)`를 사용하면 호출한 class가 `cls`로 들어오므로 `Admin.from_csv()`는 `Admin` instance를 만들 수 있다.

`@staticmethod`는 instance나 class를 자동으로 전달받지 않는다. `self`도 `cls`도 암시적으로 들어오지 않고, 함수에 명시한 인자만 전달된다. 그래서 class나 instance 상태를 직접 쓸 필요는 없지만, 의미상 그 class에 묶어 두는 편이 좋은 helper function을 만들 때 사용한다. static method에서 class variable을 class name으로 직접 참조할 수는 있지만, 상속 구조까지 고려해 class별 상태를 다뤄야 한다면 `staticmethod`보다 `classmethod`가 더 자연스럽다.

```python
class Tool:
    count = 0

    @classmethod
    def show_count(cls):
        print(cls.count)

    @staticmethod
    def add(a, b):
        return a + b

tool = Tool()

Tool.show_count()     # cls = Tool
tool.show_count()     # cls = tool.__class__

print(Tool.add(3, 4))
print(tool.add(3, 4))
```

선택 기준은 다음처럼 잡을 수 있다.

| 필요한 동작 | 적합한 method |
| :--- | :--- |
| instance별 data 읽기/수정 | instance method |
| class variable 읽기/수정 | class method |
| 상속을 고려한 생성자/factory | class method |
| class와 관련 있지만 `self`, `cls`가 필요 없는 계산 | static method |
| class 이름을 직접 박아 넣지 않고 child class까지 유지 | class method |
| 단순 helper를 namespace상 class 안에 모아두기 | static method |
