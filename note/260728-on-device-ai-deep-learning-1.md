# 26-07-28 - ON-Device AI를 위한 Deep Learning 1부

관련 노트:

- [Machine Learning·Deep Learning 전체 지도](machine-learning-deep-learning-course-map.md)
- [26-07-29 - ON-Device AI를 위한 Deep Learning 1부 마무리](260729-on-device-ai-deep-learning-1-continuation.md)
- [26-07-29 - ON-Device AI를 위한 Deep Learning 2부: CNN](260729-on-device-ai-deep-learning-2-cnn.md)
- [Embedded Linux·Jetson On-Device AI 전체 지도](embedded-linux-jetson-on-device-ai-course-map.md)

> 학습 시작: `2026-07-28`
>
> 원자료: Google Classroom의
> `260707-on-device-ai-deep-learning-1-jpg` 47장과 SHA-256이 같은
> `/Volumes/Work/Safekeep/source-media/korcham/260707-image-extracts/260707-on-device-ai-deep-learning-1-jpg`
>
> 현재 상태: `2026-07-28` 수업은 MNIST dataset을 불러와 train·test
> data와 label의 shape를 확인한 단계까지 진행했다. model 구성과 학습
> 이후 내용은 [26-07-29 노트](260729-on-device-ai-deep-learning-1-continuation.md)에서
> 이어진다. learner 설명·계산·실습 결과가 없는 단원은 완료 처리하지
> 않는다.

## 수업 범위

| 단원 | 내용 |
| :--- | :--- |
| 1과 | Machine Learning과 Perceptron |
| 2과 | Linear Regression |
| 3과 | Logistic Regression |
| 4과 | Softmax Classification |
| 5과 | Multi Layer Perceptron |

## 수업 흐름

```text
Explicit Programming
  → Machine Learning
  → Deep Learning
  → Perceptron·Regression·Classification
  → Multi Layer Perceptron
```

## 실습 notebook과 수업 흐름

Google Classroom의 `01_ML_DL_Basic` folder에서 이 날짜의 개념과 직접
연결되는 앞부분 notebook은 다음과 같다.

| Notebook | 구현 연결 | 저장된 결과 |
| :--- | :--- | :--- |
| `EX_01_Perceptron.ipynb` | element-wise multiply·bias·step function | `s=42`, `y=1.0` |
| `EX_02_Optimize_Hypothesis.ipynb` | NumPy MSE·Gradient Descent | `W≈2.0`, `B≈0.9974` |
| `EX_03_Blood_Pressure_Linear_Regression.ipynb` | 나이로 혈압 예측 | 나이 `50` → 약 `126.2mmHg` |
| `EX_04_N-variable_M-output_LR_Keras.ipynb` | 나이·BMI로 혈압 두 값 예측 | `Dense(2)`, parameter `6개` |

Perceptron notebook은 vector 연산과 activation을 다음처럼 가장 작은
단위로 보여준다.

```python
X = np.array([1, 2, 3])
W = np.array([4, 5, 6])
B = 10

mul = W * X              # [4, 10, 18]
s = np.sum(mul) + B      # 42
y = np.float32(s > 10)   # 1.0
```

다변수·다출력 notebook은 `Dense(2)`를 `SGD(learning_rate=0.1)`과
MSE로 `1000` epoch 학습한다. 저장된 예측에서 `Age=50`, `BMI=25`는
수축기·이완기 혈압 약 `[125.2, 78.72]`로 출력된다.

## 수업과 On-Device AI 프로젝트의 연결

이 과정은 Machine Learning과 Deep Learning의 기초를 익힌 뒤 CNN을
학습하고, Jetson Nano에서 추론을 실행하는 흐름으로 이어진다. PC에서
학습한 model을 embedded target에 배치할 때는 TensorRT와 같은 추론
최적화 도구를 사용해 실행 성능을 확인한다.

```text
Machine Learning·Deep Learning 기초
  → CNN model 학습
  → 학습된 model 변환·최적화
  → Jetson Nano 배치
  → 실제 입력으로 추론 성능 확인
```

Raspberry Pi에서도 경량 추론을 시도할 수 있지만, GPU가 있는 Jetson
Nano는 CNN 실습과 추론 가속을 확인하기에 더 적합하다. 따라서 이
단원에서 배우는 hypothesis, cost, gradient descent는 단순한 수학
연습이 아니라 이후 CNN model이 학습되는 원리를 이해하기 위한
기초다.

### Jetson SDK Manager 설치 준비

수업 시연에서는 Jetson Orin Nano 개발 환경을 준비하기 위해 SDK
Manager에서 JetPack `6.2.2`와 Jetson Orin Nano module을 선택했다.
구성요소 선택 화면에서는 상단 항목뿐 아니라 `Jetson SDK Components`와
platform service 항목까지 확인해야 한다. 기본 상태에서 일부 하단
항목이 선택되지 않을 수 있으므로 설치를 시작하기 전에 전체 선택
상태를 점검한다.

시스템 드라이브 공간이 부족하면 download directory와 SDK install
directory를 데이터 드라이브로 바꾼다. 수업에서는 먼저 package를
받아두기 위해 download-only 경로를 선택하고, 실제 설치에 사용할
directory도 별도로 확보했다. 두 경로는 목적이 다르므로 같은 화면에서
각각 확인한다.

```text
JetPack 6.2.2 + Jetson Orin Nano module 선택
  → Jetson SDK Components·platform service 확인
  → download directory 지정
  → SDK install directory 지정
  → package download
```

## Machine Learning과 Perceptron

### 규칙 기반 접근과 머신러닝

고전적인 프로그래밍은 사람이 문제 해결 규칙을 직접 작성하는 방식이다. 조건이 명확하고 경우의 수가 적으면 효과적이지만, spam filtering, automatic driving, 객체 분류처럼 입력 상황이 다양하면 rule을 모두 사람이 작성하기 어렵다.

| 접근 | 핵심 | 한계 또는 특징 |
| :--- | :--- | :--- |
| Explicit Programming | 사람이 rule 직접 작성 | 복잡한 상황에서 rule 폭증 |
| Machine Learning | data로 pattern 학습 | feature 설계와 training data 중요 |
| Deep Learning | 다층 신경망으로 feature와 decision boundary 학습 | 많은 data와 연산량 필요 |

역사적으로는 논리·규칙 기반 시스템(1950년대~), 신경망 기반 Machine Learning(1980년대~), Deep Learning(2010년대~) 순으로 접근 방식이 넓어졌고, 포함 관계는 `AI ⊃ Machine Learning ⊃ Deep Learning`이다. 전통적인 Machine Learning에서는 사람이 feature를 설계하는 비중이 큰 편이다. Deep Learning은 여러 layer가 목적에 유용한 representation을 data에서 함께 학습한다. 문제 정의, data 수집·전처리, label과 metric 선택, 오류 분석에는 여전히 사람의 판단이 필요하다.

Machine Learning의 고전적 정의는 Arthur Samuel(1959)의 표현대로 "명시적인 프로그래밍 없이 데이터를 이용해 컴퓨터가 지식이나 pattern을 학습하는 것"이다. 용어로는 기계 관점의 학습을 learning, 사람 관점에서 기계를 학습시키는 행위를 training으로 구분해 부른다.

공학적으로는 Tom Mitchell(1997)의 정의처럼 `Task`, `Performance`, `Experience`로 설명할 수 있다.

| 항목 | 의미 | spam filtering 예시 |
| :--- | :--- | :--- |
| `T` | 해결할 작업 | mail의 spam 여부 분류 |
| `P` | 성능 측정 기준 | classification accuracy |
| `E` | 학습 경험 | spam/normal label이 붙은 mail data |

```text
Experience E가 증가할수록
    |
    v
Task T에 대한 Performance P가 향상
    |
    v
Machine Learning
```

### 학습 문제의 큰 분류

| 구분 | 설명 | 예시 |
| :--- | :--- | :--- |
| Supervised Learning | input과 label을 함께 사용 | 주가 예측, spam 분류 |
| Unsupervised Learning | label 없이 data 구조 탐색 | clustering, 차원 축소 |
| Reinforcement Learning | 보상으로 행동 정책 학습 | 게임 AI, 제어 정책 |

지도학습은 다시 출력 형태에 따라 regression과 classification으로 나눌 수 있다.

| 문제 | 출력 | 예시 |
| :--- | :--- | :--- |
| Regression | 연속값 | 혈압, 가격, 온도 예측 |
| Binary Classification | 두 class 중 하나 | 고혈압 여부, spam 여부 |
| Multinomial Classification | 여러 class 중 하나 | 숫자 0~9 분류 |

### Perceptron 구조

Perceptron은 입력값에 weight를 곱하고 bias를 더한 뒤 activation function을 거쳐 출력을 만드는 가장 기본적인 인공 neuron 모델이다.

```text
x1 ---- w1 --\
x2 ---- w2 ---+--> z = w1*x1 + w2*x2 + ... + b --> activation(z) --> y
x3 ---- w3 --/
```

수식으로는 다음처럼 표현한다.

```text
z = Σ(w_i * x_i) + b
y = activation(z)
```

| 구성 | 의미 |
| :--- | :--- |
| `x_i` | input feature |
| `w_i` | feature별 weight |
| `b` | bias |
| `z` | weighted sum |
| `activation` | 출력 형태를 결정하는 함수 |
| `y` | model output |

간단한 step activation 기반 perceptron은 다음처럼 표현할 수 있음.

```python
def step(x):
    return 1 if x >= 0 else 0

def perceptron(x1, x2):
    w1 = 0.7
    w2 = 0.3
    b = -0.5
    z = w1 * x1 + w2 * x2 + b
    return step(z)
```

## Linear Regression

### Machine Learning 기본 프로세스

문제 유형과 관계없이 Machine Learning 설계는 세 단계로 반복된다.

| 단계 | 내용 |
| :--- | :--- |
| 1. Hypothesis 설정 | 데이터를 가장 잘 표현할 함수 `H(x)`를 수식으로 세움 |
| 2. Cost Function 설정 | `H(x)` 결과와 label의 차이를 평가하는 함수 정의, loss function으로도 부름 |
| 3. Learning Algorithm 적용 | cost가 최소가 되도록 hypothesis의 parameter를 조정 |

hypothesis는 현상을 설명하기 위해 세운 수학적 가정이고, cost는 weight와 bias에 따라 달라지므로 학습은 결국 cost를 낮추는 parameter 탐색이다.

### Hypothesis와 Cost Function

Linear Regression은 입력과 출력 사이의 관계를 1차 함수로 근사하는 regression model이다.

```text
H(x) = W*x + b
```

`H(x)`는 hypothesis, 즉 model이 예측한 값이다. 실제 label `y`와 예측값 `H(x)`의 차이를 cost function으로 측정하고, cost가 작아지는 방향으로 `W`, `b`를 갱신함.

```text
data x,y
   |
   v
H(x) = W*x + b
   |
   v
error = H(x) - y
   |
   v
cost = mean(error^2)
   |
   v
gradient descent로 W,b 갱신
```

가장 흔한 cost function은 평균제곱오차 `MSE`다.

```text
MSE = (1/n) * Σ(H(x_i) - y_i)^2
```

절대 평균 오차처럼 부호가 있는 error를 단순 평균하면 양수/음수가 상쇄될 수 있으므로, 제곱 또는 절댓값을 사용해 error 크기를 평가한다.

### Gradient Descent

Gradient Descent는 cost function의 기울기를 따라 parameter를 조금씩 수정하는 방법이다. 임의의 parameter 값에서 시작해, 해당 지점에서 cost function을 각 parameter로 편미분한 기울기를 구하고, 기울기가 줄어드는 방향으로 이동하는 과정을 최저점에 도달할 때까지 반복한다.

```text
W := W - learning_rate * dCost/dW
b := b - learning_rate * dCost/db
```

MSE cost를 쓰는 Linear Regression이라면 두 편미분은 다음 형태로 정리된다.

```text
dCost/dW = (2/m) * Σ x_i * (W*x_i + b - y_i)
dCost/db = (2/m) * Σ (W*x_i + b - y_i)
```

| 항목 | 설명 |
| :--- | :--- |
| `learning_rate`가 너무 큼 | minimum을 지나쳐 발산 가능 |
| `learning_rate`가 너무 작음 | 학습이 지나치게 느림 |
| local minimum | 구간에 따라 최적점 근처가 아닌 곳에 머물 수 있음 |
| global minimum | 전체 cost가 가장 낮은 지점 |

Gradient Descent가 항상 global minimum을 보장하는 것은 아니다. cost function이 convex function이면 local minimum이 곧 global minimum이라 문제가 없지만, convex가 아니면 local minimum이나 saddle point에 갇힐 수 있다. 그래서 뒤에 나오는 Logistic Regression처럼 hypothesis가 비선형이 되면, cost 곡면이 convex가 되도록 cost function 자체를 바꾸는 선택이 중요해진다.

학습 과정은 cost function의 현재 기울기를 보고 parameter를 반복적으로 갱신하는 과정이다.

```text
cost
 ^
 |             o  start
 |          o
 |       o
 |    o
 |__o________________> W
    minimum
```

### NumPy로 직접 구현한 학습 loop

framework 없이 NumPy만으로 hypothesis, cost, gradient, parameter 갱신을 구현하면 gradient descent의 실제 동작이 그대로 드러난다. 목표 관계는 `y = 2x + 1`이다.

```python
import numpy as np

x_input = np.array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], dtype=np.float32)
labels  = np.array([3, 5, 7, 9, 11, 13, 15, 17, 19, 21], dtype=np.float32)

W, B = np.random.normal(), np.random.normal()

def Hypothesis(x):
    return W * x + B

def Cost():
    return np.mean((Hypothesis(x_input) - labels) ** 2)

def Gradient(x, y):
    return np.mean(x * (x * W + (B - y))), np.mean(W * x - y + B)

epochs = 5000
learning_rate = 0.005

for cnt in range(epochs + 1):
    if cnt % (epochs // 20) == 0:
        print(f"[{cnt}] cost = {Cost():.4g}, W = {W:.4g}, B = {B:.4g}")
    grad_w, grad_b = Gradient(x_input, labels)
    W -= learning_rate * grad_w
    B -= learning_rate * grad_b
```

`Gradient()`는 MSE의 편미분에서 상수 계수를 생략한 형태다. 상수배는 learning rate에 흡수되므로 수렴 방향에는 영향이 없다. 학습 로그는 다음처럼 cost가 줄며 `W -> 2`, `B -> 1`로 수렴하는 모습을 보인다.

```text
[0]    cost = 290.8,     W = -0.4783, B = 0.8653
[250]  cost = 0.2772,    W = 2.103,   B = -0.1373
[500]  cost = 0.1639,    W = 2.126,   B = 0.1254
...
[5000] cost = 1.285e-05, W = 2.001,   B = 0.9923
```

### 입력 정규화와 학습 발산

나이(20~80)나 혈압(110~140)처럼 입력과 출력 값의 크기가 크면, 같은 learning rate에서도 기울기가 커져 cost가 `inf`를 거쳐 `nan`으로 발산하기 쉽다. 이때는 learning rate를 아주 작게 잡고 epoch를 크게 늘리거나, 입력을 정규화해야 한다.

같은 NumPy 구현에 나이·혈압 원본 값을 그대로 넣고 `learning_rate = 0.01`로 학습하면 발산이 실제로 재현된다.

실습에서는 cost가 `10^3`, `10^7`, `10^31`처럼 계속 커진 뒤 `inf`와
`nan`에 도달하는지 확인한다. 이 상태의 `W`, `b`는 이미 유효 범위를
벗어났으므로 learning rate만 낮춰서 loop를 다시 실행하면 안 된다.
`W`, `b`를 다시 초기화한 뒤 학습을 처음부터 시작해야 한다.

learning rate와 epoch는 함께 조정한다.

| 관찰 결과 | 조정 방향 |
| :--- | :--- |
| cost가 커지며 발산 | `W`, `b` 재초기화 후 learning rate 감소 |
| cost가 매우 천천히 감소 | epoch 증가 |
| parameter가 최저점을 지나 진동 | learning rate 감소 |
| cost가 안정적으로 감소하다 일정 값에 수렴 | 현재 data에서 찾은 해로 판단 |

나이 하나만으로 혈압을 예측하는 예제에서는 같은 나이에서도 혈압이
서로 다르므로 cost가 완전히 `0`이 되지 않을 수 있다. 학습의 목표는
모든 점을 정확히 통과하는 직선을 만드는 것이 아니라, 주어진 data의
오차를 가장 작게 만드는 `W`, `b`를 찾는 것이다.

```python
x_input = np.array([25, 25, 25, 35, 35, 35, ..., 65, 73, 73, 73], dtype=np.float32)
labels  = np.array([118, 125, 130, 118, 126, ..., 125.5, 130, 138], dtype=np.float32)
```

```text
[0]  cost = 1.168e+04, W = 0.3765,   B = -0.438
[5]  cost = 1.706e+18, W = 4.93e+07, B = 4.516e+05
[10] cost = 2.84e+32,  W = 4.1e+21,  B = 7.518e+19
[25] cost = inf
[30] cost = nan, W = nan, B = nan
```

발산을 피해 `learning_rate = 0.0005`, `epochs = 200000`으로 낮추면 `W = 0.161`, `B = 118.2` 근처로 수렴하고, 나이 `50`의 예측 혈압은 약 `126.2mmHg`가 나온다. 동작은 하지만 20만 epoch이 필요하다는 점이 정규화가 필요한 이유다. Min-Max scaling을 적용하면 훨씬 적은 epoch로 같은 문제를 학습할 수 있다.

가장 단순한 정규화가 Min-Max scaling이다.

```text
x_scaled = (x - x_min) / (x_max - x_min)   # 0 ~ 1 범위
```

| 주의점 | 이유 |
| :--- | :--- |
| `x_min`, `x_max`는 train data 기준으로 저장 | 예측 시에도 같은 기준으로 변환해야 함 |
| predict 입력도 동일하게 scaling | 학습과 다른 스케일 입력은 엉뚱한 예측을 만듦 |

### 다변수·다출력과 행렬 표현

나이와 BMI 두 입력으로 수축기·이완기 혈압 두 값을 예측하듯 입력과 출력이 여러 개면, hypothesis는 행렬 곱으로 일반화된다.

```text
Y = XW + B

X: (batch, 입력 수)
W: (입력 수, 출력 수)
B: (출력 수,)
Y: (batch, 출력 수)
```

Keras의 `Dense` layer가 정확히 이 구조라서, 입력 N개와 출력 M개가 fully connected로 연결되고 parameter 수는 `N*M + M`이 된다. Keras에서 model을 정의하는 방법은 Sequential API, Functional API, Subclassing(custom model) 세 가지가 있고, 단순한 적층 구조는 Sequential로 충분하다.

출력 수가 늘어나는 것과 layer 수가 늘어나는 것은 서로 다른
개념이다. 나이와 BMI를 입력받아 수축기·이완기 혈압을 함께 예측하려면
같은 출력 layer에 neuron 두 개를 나란히 둔다. neuron 두 개가 서로의
출력을 다시 입력으로 받지 않으므로 이 구조는 여전히 single layer다.
앞 layer의 출력이 다음 layer의 입력으로 연결될 때 multi layer가 된다.

```text
[age, BMI] ─┬─> neuron 1 ─> systolic blood pressure
            └─> neuron 2 ─> diastolic blood pressure
```

이 예제의 tensor shape과 parameter 수는 다음과 같다.

| 대상 | shape 또는 개수 |
| :--- | :--- |
| `X` | `(batch_size, 2)` |
| `W` | `(2, 2)` |
| `B` | `(2,)` |
| `Y` | `(batch_size, 2)` |
| trainable parameter | `2*2 + 2 = 6` |

`batch_size`는 한 번에 처리하는 sample 수이므로 학습할 parameter 수에
포함되지 않는다. Keras model을 선언할 때는 sample마다 들어오는 feature
수인 `2`만 입력 shape으로 지정한다.

### Keras 기반 Linear Regression 형태

Keras에서는 입력 feature를 받아 연속값 하나를 예측하는 선형 회귀를 `Dense(1)` 출력층 하나로 구성한다. `Dense(1)`은 입력 vector와 weight를 곱하고 bias를 더해 scalar output을 만드는 layer이며, loss가 `mse`이면 예측값과 실제값의 제곱 오차 평균을 줄이도록 weight가 갱신된다.

```python
import tensorflow as tf

model = tf.keras.models.Sequential([
    tf.keras.layers.Dense(1, input_shape=(1,))
])

model.compile(
    optimizer=tf.keras.optimizers.SGD(learning_rate=0.01),
    loss="mse"
)

model.fit(x_train, y_train, epochs=1000)
```

혈압 예측 예제처럼 나이, BMI 같은 입력 feature가 여러 개라면 input shape만 feature 수에 맞게 확장한다.

```python
model = tf.keras.models.Sequential([
    tf.keras.layers.Input(shape=(2,)),
    tf.keras.layers.Dense(2)
])

model.summary()
```

여기서 `Dense(2)`의 `2`는 입력 수가 아니라 출력 neuron 수다. 입력 수는
`Input(shape=(2,))`가 정하며, 첫 번째 `2`는 나이와 BMI, 두 번째 `2`는
수축기와 이완기 혈압에 대응한다. model이 입력 shape을 알게 되면
Keras가 `W`와 `B`를 만들고 초기화하며, `model.summary()`에서 출력
shape과 parameter 수를 확인할 수 있다.

### TensorFlow·Keras model 구성 API

TensorFlow와 PyTorch는 대표적인 Deep Learning framework다. 이
수업에서는 TensorFlow를 사용하고, TensorFlow의 low-level 연산을
직접 조합하는 부담을 줄이기 위해 상위 API인 Keras로 model을 구성한다.

| API | 연결 방식 | 적합한 경우 |
| :--- | :--- | :--- |
| Sequential API | layer를 한 방향으로 차례대로 연결 | 단순한 직렬 구조 |
| Functional API | 여러 입력·출력, 분기·병합, skip connection 구성 | 복잡한 연결 구조 |
| Subclassing | Python class로 forward 동작 직접 정의 | 동적이거나 사용자 정의 동작 |

기본 실습은 Sequential API로 충분하다. model의 입력이나 출력이 여러
갈래로 나뉘거나 중간 layer를 건너뛰는 연결이 필요하면 Functional
API를 선택한다.

### Keras model 실행 순서

Sequential model은 layer list를 생성자에 전달하거나, 빈 model을 만든
뒤 `add()`로 layer를 순서대로 쌓을 수 있다.

```python
# 생성할 때 layer list 전달
model = tf.keras.models.Sequential([
    tf.keras.Input(shape=(2,)),
    tf.keras.layers.Dense(2)
])

# 빈 model에 layer 추가
model = tf.keras.models.Sequential()
model.add(tf.keras.Input(shape=(2,)))
model.add(tf.keras.layers.Dense(2))
```

model을 만든 것만으로는 학습 조건이 정해지지 않는다. `compile()`에서
optimizer, loss function, 평가 metric을 연결한 뒤 `fit()`으로
학습하고, `evaluate()`와 `predict()`로 각각 성능 평가와 추론을
수행한다.

```text
model 구성
  → summary(): output shape·parameter 수 확인
  → compile(): optimizer·loss·metrics 설정
  → fit(): train data와 label로 학습
  → evaluate(): data와 label로 loss·metric 평가
  → predict(): 새 input의 model output 계산
```

optimizer와 loss는 문자열 또는 instance로 전달할 수 있다. 문자열을
쓰면 framework의 default parameter가 적용되고, learning rate처럼
세부값을 바꾸려면 instance를 만들어 전달한다.

```python
# default parameter 사용
model.compile(optimizer="sgd", loss="mse")

# parameter 직접 설정
model.compile(
    optimizer=tf.keras.optimizers.SGD(learning_rate=0.005),
    loss=tf.keras.losses.MeanSquaredError()
)
```

`fit()`의 `batch_size` default는 `32`이고 `epochs`는 전체 train
data를 반복해서 사용하는 횟수다. `verbose=0`은 출력 없이 학습하고,
`1`은 progress bar, `2`는 epoch별 결과를 간단히 보여준다.
`shuffle=True`이면 epoch마다 train data 순서를 섞는다.

## Logistic Regression

### Binary Classification

Logistic Regression은 이름에 regression이 들어가지만, 실제로는 binary classification에 많이 쓰인다.

Linear Regression `H(x) = Wx + b`의 출력 범위는 `-∞ ~ ∞`라서 0 또는 1을 예측해야 하는 문제에 맞지 않다. 이상적인 분류기는 threshold를 기준으로 0과 1이 갈리는 step function이지만, step function은 미분값이 0 아니면 무한대라 gradient 기반 학습이 불가능하다. 그래서 step function과 비슷한 모양이면서 전 구간에서 미분 가능한 logistic function을 hypothesis로 쓴다.

model은 logit 값을 만들고, sigmoid function(logistic function의 표준형)을 통과시켜 `0`~`1` 사이 확률로 변환한다.

```text
z = W*x + b
p = sigmoid(z) = 1 / (1 + e^-z)
```

`W`가 크면 곡선의 기울기가 가팔라지고, `b`는 곡선을 좌우로 수평이동시킨다. 학습은 이 두 값을 데이터에 맞게 조정하는 과정이다.

```text
z ---- sigmoid ---- p

p >= 0.5 -> class 1
p <  0.5 -> class 0
```

| 개념 | 의미 |
| :--- | :--- |
| `logit` | sigmoid 입력값, log-odds와 같은 값 |
| `sigmoid` | 실수 입력을 0~1 사이 값으로 변환 |
| `p` | class 1일 확률 |
| threshold | class 결정 기준, 보통 `0.5` |

logit이라는 이름은 odds에서 온다. 확률 `p`의 odds는 `p / (1-p)`로 `0 ~ ∞` 범위이고, 여기에 log를 취한 log-odds(logit)는 `-∞ ~ ∞` 범위가 된다. sigmoid는 이 logit을 다시 확률로 되돌리는 역함수다.

```text
p [0,1] -> odds = p/(1-p) [0,∞] -> logit = log(odds) [-∞,∞]
logit --sigmoid--> p
```

decision boundary는 `p >= 0.5`인데, sigmoid는 입력이 0일 때 정확히 0.5이므로 이 조건은 `Wx + b >= 0`과 같다. 즉 확률 경계는 결국 선형 방정식의 부호로 결정된다.

고혈압 여부처럼 결과가 `정상/고혈압` 두 종류인 문제는 binary classification이다. label을 `0`, `1`로 두고 sigmoid 출력 `p`를 class 1의 확률로 해석한다.

### Cost Function

Linear Regression의 `MSE`를 sigmoid 출력에 그대로 쓰면 cost 곡면이 non-convex가 되어 Gradient Descent가 local minimum에 갇힐 수 있다. Logistic Regression에서는 보통 binary cross entropy를 사용한다. cross entropy는 두 확률분포의 차이를 재는 값이라, "가설의 출력이 확률"인 분류 문제의 cost로 자연스럽다.

```text
cost = - y*log(p) - (1-y)*log(1-p)
```

| 실제값 `y` | 예측 확률 `p`가 커야 하는 쪽 |
| :--- | :--- |
| `1` | `p`가 1에 가까워야 cost 감소 |
| `0` | `p`가 0에 가까워야 cost 감소 |

Keras 구현 형태는 다음과 같음.

```python
model = tf.keras.models.Sequential([
    tf.keras.layers.Dense(1, activation="sigmoid", input_shape=(num_features,))
])

model.compile(
    optimizer="adam",
    loss="binary_crossentropy",
    metrics=["accuracy"]
)
```

수업의 나이·BMI 기반 고혈압 분류 실습에서는 `SGD`,
`binary_crossentropy`, `accuracy`를 사용했다. 입력 feature가 두
개이고 출력 neuron이 하나이므로 `W` 2개와 `b` 1개, 총 3개
parameter가 만들어진다. 나이와 BMI는 먼저 Min-Max scaling하고,
sigmoid 출력이 `0.5` 이상이면 고혈압 class로 판정한다.

```python
model = tf.keras.models.Sequential([
    tf.keras.Input(shape=(2,)),
    tf.keras.layers.Dense(1, activation="sigmoid")
])

model.compile(
    optimizer=tf.keras.optimizers.SGD(),
    loss="binary_crossentropy",
    metrics=["accuracy"]
)
history = model.fit(x_scaled, labels, epochs=1000)
loss, accuracy = model.evaluate(x_scaled, labels)
```

해당 소규모 data에서는 train accuracy가 약 `77.78%`에서 더 이상
오르지 않았다. epoch를 늘려 loss가 조금 더 감소하더라도 accuracy가
같다면 현재 feature와 선형 decision boundary로 구분할 수 있는 한계에
도달한 것으로 해석한다. `history.history["loss"]`와
`history.history["accuracy"]`를 함께 그리면 이 차이를 확인할 수 있다.

위의 `adam` 코드는 비교용 대안이다. SGD는 모든 parameter에 하나의
learning rate를 적용하므로 입력 스케일과 learning rate 선택에
민감하다. Adam(Adaptive Moment Estimation)은 gradient의 이동평균과
gradient 크기의 이동평균을 추적해 parameter마다 유효 learning rate를
조절한다. 원리를 확인하는 예제에는 SGD가 적합하고, 빠르게 동작하는
baseline이 필요할 때는 Adam을 비교할 수 있다.

## Softmax Classification

### Multinomial Classification

Softmax Classification은 3개 이상의 class 중 하나를 고르는 문제에 사용한다. class 수만큼 binary classifier를 두고 sigmoid를 각각 적용할 수도 있지만, 그러면 각 출력이 독립 확률이라 합이 1이 되지 않는다(예: `p0=0.8, p1=0.4, p2=0.6`). 그래서 출력층에서 class별 logit을 한 번에 만들고 softmax로 정규화해 "여러 class 중 하나"라는 배타적 확률 분포로 해석한다.

```text
input features
    |
    v
Dense(num_classes)
    |
    v
softmax
    |
    v
[P(class0), P(class1), P(class2), ...]
```

softmax 출력은 모든 class 확률의 합이 1이 되도록 정규화된다.

```text
softmax(z_i) = exp(z_i) / Σ exp(z_j)
```

class 결정은 가장 높은 확률을 가진 index를 선택한다.

```python
predicted_class = probabilities.argmax()
```

### Softmax Cost Function

Softmax 출력에는 categorical cross entropy를 사용한다. label이 one-hot encoding이면 실제 class 위치만 `1`이고 나머지는 `0`이다.

```text
label = [0, 1, 0]
pred  = [0.1, 0.8, 0.1]
```

Keras 구현 형태는 다음과 같음.

```python
model = tf.keras.models.Sequential([
    tf.keras.layers.Dense(3, activation="softmax", input_shape=(num_features,))
])

model.compile(
    optimizer="adam",
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)
```

수업의 나이·BMI 예제에서는 label을 `정상`, `주의`, `경고` 세 class의
one-hot vector로 만들고, `Dense(3, activation="softmax")`를
사용했다. 입력 2개와 출력 neuron 3개가 fully connected로 연결되므로
parameter 수는 `2*3 + 3 = 9`개다. 수업 실습의 optimizer는 `SGD`,
loss는 `categorical_crossentropy`였으며, 위의 `adam`은 비교 가능한
대안이다.

```text
[age, BMI]
  → Dense(3): class별 logit 3개
  → softmax: 합이 1인 확률 3개
  → argmax: 정상·주의·경고 중 하나 선택
```

## Multi Layer Perceptron

### 단층 Perceptron의 한계

Perceptron은 선형 decision boundary를 만드는 구조라 XOR 같은 비선형 문제를 해결하기 어렵다. Marvin Minsky와 Seymour Papert가 「Perceptrons」(1969)에서 이 한계를 증명했고, MLP가 대안임은 알려져 있었지만 당시에는 MLP를 학습시킬 실용적인 방법이 없어 신경망 연구가 오래 침체되었다(이른바 AI 겨울). 이 한계를 보완하기 위해 hidden layer를 추가한 구조가 `Multi Layer Perceptron`, 즉 `MLP`다.

```text
Input layer -> Hidden layer -> Output layer
```

layer가 늘면 학습할 parameter(weight와 bias) 수가 빠르게 는다. 예를 들어 입력 3, hidden 4-4, 출력 1 구조면 `(3*4+4) + (4*4+4) + (4*1+1) = 41`개다.

### Backpropagation

MLP 침체를 끝낸 것이 backpropagation이다. Rumelhart, Hinton, Williams가 1980년대에 발표한 방법으로, feed forward로 loss를 구한 뒤 output layer에서 input 방향으로 chain rule을 따라 기울기를 전파하며 계산한다.

```text
forward:  x -> hidden -> output -> loss
backward: dLoss/dOutput -> dLoss/dHidden -> dLoss/dW
```

각 weight의 기울기를 수식 전체를 다시 미분해 구하는 대신, 이미 계산된 뒤쪽 layer의 기울기에 국소 미분값을 곱해가며 한 단계씩 얻으므로 연산량이 크게 줄고, 복잡한 신경망도 학습이 가능해진다. 현대 framework의 자동 미분이 이 원리를 구현한 것이다.

가장 작은 계산 그래프로 숫자를 따라가 보면 원리가 분명해진다. `g = w*x`, `f = g + b`, `L = (f - y)^2`에서 `w = 1`, `x = 2`, `b = 1`, 정답 `y = 5`라고 하자.

```text
forward:  g = 1*2 = 2,  f = 2+1 = 3,  L = (3-5)^2 = 4

backward: dL/df = 2(f-y) = 2(3-5) = -4
          df/dg = 1  ->  dL/dg = -4
          dg/dw = x = 2  ->  dL/dw = -4 * 2 = -8

갱신:     w := 1 - 0.01 * (-8) = 1.08
```

각 단계는 자기 연산의 국소 미분(`df/dg = 1`, `dg/dw = x`)만 알면 되고, 앞에서 전달받은 기울기에 그것을 곱해 뒤로 넘긴다. 이 chain rule 반복이 backpropagation의 전부이며, 전체 loss 식을 한 번에 미분한 결과와 정확히 같다.

### Dataset 분리와 Overfitting

학습용 데이터는 역할별로 나눈다. MNIST 기준으로 train 60,000장, test 10,000장이 표준 분할이다.

| 구분 | 용도 |
| :--- | :--- |
| Train data | parameter를 갱신하는 학습에 사용 |
| Validation data | 학습에는 쓰지 않고 overfitting 여부 확인에 사용 |
| Test data | 학습이 끝난 model의 최종 성능 평가에 사용 |

| 상태 | 의미 | 신호 |
| :--- | :--- | :--- |
| Underfitting | 학습 부족 | train/test error 모두 높고 추가 학습으로 개선 |
| Overfitting | train data에 과도하게 맞춤 | train 정확도는 높은데 validation/test 정확도 하락 |

training iteration이 늘수록 train error는 계속 내려가지만 validation error는 어느 지점부터 다시 올라가는데, 그 지점이 overfitting의 시작이다.

실제 학습에서는 validation metric이 좋아질 때만 model이나 weight를
저장하고, 더 이상 개선되지 않으면 학습을 멈추는 callback을 사용할 수
있다. 이미 overfitting된 마지막 weight를 계속 쓰는 대신 validation
성능이 가장 좋았던 시점의 상태를 복원하는 방식이다.

### Batch와 Epoch

기울기를 계산하는 데이터 단위에 따라 학습 방식이 나뉜다.

| 방식 | 기울기 계산 단위 | 특징 |
| :--- | :--- | :--- |
| Batch Gradient Descent | 전체 data의 cost 평균 | 안정적이지만 한 번 갱신 비용이 큼 |
| Mini-batch Gradient Descent | 일정 개수 묶음(batch) | 실무 표준, batch size가 hyperparameter |
| Stochastic Gradient Descent | data 1개 | 갱신이 빠르지만 진동이 큼 |

epoch는 전체 데이터가 학습에 한 번 다 사용된 횟수다. `model.fit(..., epochs=5)`는 전체 train data를 다섯 번 반복 학습한다는 뜻이다.

MNIST train data `60,000`개를 default batch size `32`로 학습하면 한
epoch에 `ceil(60000/32) = 1,875`번의 parameter update가 일어난다.
전체 data를 한 번에 처리하는 batch 방식보다 memory 부담이 작고, sample
하나마다 갱신하는 stochastic 방식보다 연산을 묶어 처리하기 좋다.

층이 여러 개 쌓이면 각 hidden layer가 입력 data의 중간 표현을 만들고, output layer가 최종 class나 값을 예측한다.

```text
x
 |
 v
Dense + activation
 |
 v
Dense + activation
 |
 v
Dense + softmax
```

| 구성 | 역할 |
| :--- | :--- |
| Input layer | 입력 feature 수 결정 |
| Hidden layer | 비선형 특징 조합 학습 |
| Activation | 선형 layer 사이에 비선형성 추가 |
| Output layer | regression/classification 결과 출력 |

### MNIST Classification 준비

MNIST는 손글씨 숫자 `0`~`9`를 분류하는 대표적인 dataset이다. train
data는 `60,000`장, test data는 `10,000`장이며, image 한 장은
`28x28` grayscale pixel로 구성된다. pixel 값은 `0`~`255` 범위다.

```python
mnist = tf.keras.datasets.mnist
(train_data, train_labels), (test_data, test_labels) = mnist.load_data()

# train_data:   (60000, 28, 28)
# train_labels: (60000,)
# test_data:    (10000, 28, 28)
# test_labels:  (10000,)
```

fully connected layer에 넣을 때는 `Flatten`으로 `28x28` image를
`784`개 feature로 펼친다. 숫자 class가 10개이므로 단층 model의 출력
neuron은 10개이고, parameter 수는 `784*10 + 10 = 7,850`개다.

```text
28 x 28 image
  → Flatten
  → 784 features
  → Dense(10)
  → 숫자 0~9의 class별 output
```

이날 수업은 dataset을 불러와 data·label의 type과 shape를 확인하는
단계까지 진행했다. normalization, model 구성, 학습과 평가는
[26-07-29 노트](260729-on-device-ai-deep-learning-1-continuation.md)에서
이어진다.
