# On-Device AI를 위한 Deep Learning 필수지식 대기 메모

## 수업 범위

이 대기 메모는 `On-Device AI를 위한 Deep Learning`의 model-side 배경을 정리한다. 전통적인 규칙 기반 접근과 머신러닝의 차이, perceptron과 regression/classification, CNN 구조, on-device target에서 필요한 경량화 관점을 연결한다.

| 구분 | 내용 |
| :--- | :--- |
| 1부 | 머신러닝/딥러닝 배경 |
| 1과 | Machine Learning과 Perceptron |
| 2과 | Linear Regression |
| 3과 | Logistic Regression |
| 4과 | Softmax Classification |
| 5과 | Multi Layer Perceptron |
| 2부 | CNN |
| 1과 | CNN 개요 |
| 2과 | CNN 기본연산 |
| 3과 | CNN 기반 Classification |
| 4과 | CNN 발전 시키기 |

전체 구조는 `규칙 기반 시스템 → Machine Learning → Deep Learning → CNN 기반 feature extraction/classification → on-device target에 맞는 경량 model 선택` 순서로 잡는다.

```text
Explicit Programming
  사람이 직접 rule 작성
        |
        v
Machine Learning
  data로 rule 또는 pattern 학습
        |
        v
Deep Learning
  feature extraction과 optimization을 model이 함께 학습
        |
        v
CNN
  image-like data의 공간적 특징을 convolution으로 추출
        |
        v
On-Device AI
  정확도, model size, 연산량, memory 제약을 함께 고려
```

## Machine Learning과 Perceptron

### 규칙 기반 접근과 머신러닝

고전적인 프로그래밍은 사람이 문제 해결 규칙을 직접 작성하는 방식이다. 조건이 명확하고 경우의 수가 적으면 효과적이지만, spam filtering, automatic driving, 객체 분류처럼 입력 상황이 다양하면 rule을 모두 사람이 작성하기 어렵다.

| 접근 | 핵심 | 한계 또는 특징 |
| :--- | :--- | :--- |
| Explicit Programming | 사람이 rule 직접 작성 | 복잡한 상황에서 rule 폭증 |
| Machine Learning | data로 pattern 학습 | feature 설계와 training data 중요 |
| Deep Learning | 다층 신경망으로 feature와 decision boundary 학습 | 많은 data와 연산량 필요 |

Machine Learning은 Tom Mitchell의 정의처럼 `Task`, `Performance`, `Experience`로 설명할 수 있다.

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

Gradient Descent는 cost function의 기울기를 따라 parameter를 조금씩 수정하는 방법이다.

```text
W := W - learning_rate * dCost/dW
b := b - learning_rate * dCost/db
```

| 항목 | 설명 |
| :--- | :--- |
| `learning_rate`가 너무 큼 | minimum을 지나쳐 발산 가능 |
| `learning_rate`가 너무 작음 | 학습이 지나치게 느림 |
| local minimum | 구간에 따라 최적점 근처가 아닌 곳에 머물 수 있음 |
| global minimum | 전체 cost가 가장 낮은 지점 |

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

```text
[age, BMI] -> Dense(1) -> predicted blood pressure
```

## Logistic Regression

### Binary Classification

Logistic Regression은 이름에 regression이 들어가지만, 실제로는 binary classification에 많이 쓰인다. model은 logit 값을 만들고, sigmoid function을 통과시켜 `0`~`1` 사이 확률로 변환한다.

```text
z = W*x + b
p = sigmoid(z) = 1 / (1 + e^-z)
```

```text
z ---- sigmoid ---- p

p >= 0.5 -> class 1
p <  0.5 -> class 0
```

| 개념 | 의미 |
| :--- | :--- |
| `logit` | sigmoid 입력값 |
| `sigmoid` | 실수 입력을 0~1 사이 값으로 변환 |
| `p` | class 1일 확률 |
| threshold | class 결정 기준, 보통 `0.5` |

고혈압 여부처럼 결과가 `정상/고혈압` 두 종류인 문제는 binary classification이다. label을 `0`, `1`로 두고 sigmoid 출력 `p`를 class 1의 확률로 해석한다.

### Cost Function

Linear Regression의 `MSE`를 sigmoid 출력에 그대로 쓰면 cost 곡선이 복잡해져 학습이 어려울 수 있다. Logistic Regression에서는 보통 binary cross entropy를 사용한다.

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

## Softmax Classification

### Multinomial Classification

Softmax Classification은 3개 이상의 class 중 하나를 고르는 문제에 사용한다. 여러 binary classifier를 각각 만드는 대신, 출력층에서 class별 score를 한 번에 만들고 softmax로 확률처럼 해석한다.

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

혈압 분류 예제에서는 `정상`, `주의`, `고혈압`처럼 여러 class를 나눌 수 있고, model 출력은 class별 확률로 해석한다.

## Multi Layer Perceptron

### 단층 Perceptron의 한계

Perceptron은 선형 decision boundary를 만드는 구조라 XOR 같은 비선형 문제를 해결하기 어렵다. 이 한계를 보완하기 위해 hidden layer를 추가한 구조가 `Multi Layer Perceptron`, 즉 `MLP`다.

```text
Input layer -> Hidden layer -> Output layer
```

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

### MNIST Classification

MNIST는 손글씨 숫자 `0`~`9`를 분류하는 대표적인 예제다. 입력 data는 `28x28` 배열이고, MLP에 넣기 위해 `Flatten`으로 784개 feature로 펼친다.

```text
28 x 28
  |
  v
Flatten -> 784
  |
  v
Dense(256, activation)
  |
  v
Dense(256, activation)
  |
  v
Dense(10, softmax)
```

Keras 예제 구조는 다음과 같이 정리할 수 있음.

```python
model = tf.keras.models.Sequential([
    tf.keras.Input(shape=(28, 28)),
    tf.keras.layers.Flatten(),
    tf.keras.layers.Dense(256, activation="sigmoid"),
    tf.keras.layers.Dense(256, activation="sigmoid"),
    tf.keras.layers.Dense(10, activation="softmax")
])

model.compile(
    optimizer="adam",
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"]
)
```

layer를 더 많이 쌓는다고 항상 성능이 증가하는 것은 아니다. layer 수가 늘면 표현력은 커지지만, 학습이 어려워지거나 epoch 수와 optimizer 설정을 다시 맞춰야 할 수 있음.

| 관찰 | 해석 |
| :--- | :--- |
| layer 추가 후 성능 하락 | epoch 부족, activation 문제, 최적화 난이도 증가 가능 |
| epoch 증가 후 성능 회복 | 더 깊은 구조에 더 긴 학습 필요 가능 |
| layer만 계속 추가 | overfitting 또는 gradient 문제 가능 |

## CNN 개요

### CNN이 필요한 이유

Fully connected layer는 입력 feature를 1차원 vector로 다루므로, 공간적으로 가까운 pixel 사이의 관계를 직접 보존하기 어렵다. 반면 CNN은 작은 filter를 이동시키며 지역적 특징을 추출한다.

```text
2D data
  |
  v
local filter로 주변 관계 추출
  |
  v
feature map 생성
  |
  v
classification
```

CNN은 동물 시각 피질 연구에서 나온 receptive field 개념과 연결된다. 전체 pixel을 한 번에 fully-connected로 처리하지 않고, 작은 영역의 pattern을 여러 filter가 나눠 감지한다. 앞쪽 layer는 edge나 texture 같은 저수준 feature에 반응하고, 뒤쪽 layer는 이 feature들을 조합해 object part나 class 구분에 가까운 표현을 만든다.

### 색 공간과 data 구조

pixel data는 좌우/상하 주변 값과 강한 관계를 가진다.

| 표현 | 구성 |
| :--- | :--- |
| Grayscale | 밝기값 하나, 보통 `0`~`255` |
| RGB | Red, Green, Blue 3개 channel |
| HSV | Hue, Saturation, Value |

RGB 입력은 보통 다음처럼 생각한다.

```text
height x width x channel

예: 224 x 224 x 3
```

## CNN 기본연산

### Convolution

Convolution은 작은 filter, 또는 kernel을 입력 위에서 이동시키며 곱셈과 덧셈을 반복하는 연산이다. filter가 특정 edge, corner, texture 같은 pattern에 반응하면 feature map에 큰 값이 나온다.

```text
input patch        filter          output

a b c              f1 f2 f3        sum(input * filter)
d e f      *       f4 f5 f6   ->   one value
g h i              f7 f8 f9
```

2차원 입력에서 `3x3` filter를 적용하는 흐름은 다음처럼 볼 수 있음.

```text
[3x3 filter]가 왼쪽 위부터 오른쪽 아래로 이동
    |
    v
각 위치마다 dot product
    |
    v
feature map 생성
```

Convolution에서 중요한 점은 입력 channel 수와 filter channel 수가 맞아야 한다는 것이다. RGB image처럼 입력이 `H x W x 3`이면, filter도 spatial size는 작더라도 depth는 `3`이어야 한다.

| 구성 | Shape 예시 | 의미 |
| :--- | :--- | :--- |
| 입력 image | `5 x 5 x 3` | height, width, input channel |
| filter 1개 | `2 x 2 x 3` | spatial kernel `2 x 2`, 입력 channel 전체를 함께 사용 |
| output feature map 1개 | `4 x 4 x 1` | filter 1개가 만든 activation map |

filter가 여러 개이면 filter마다 feature map이 하나씩 만들어진다. 따라서 output channel 수는 filter 개수와 같다.

| 입력 | Filter 구성 | Output |
| :--- | :--- | :--- |
| `5 x 5 x 3` | `2 x 2 x 3` filter `1`개 | `4 x 4 x 1` |
| `5 x 5 x 3` | `2 x 2 x 3` filter `6`개 | `4 x 4 x 6` |
| `H x W x C_in` | `K_h x K_w x C_in` filter `C_out`개 | `H_out x W_out x C_out` |

즉 convolution layer의 learnable parameter는 filter weight이고, 각 filter는 입력의 전체 channel을 보면서 특정 pattern을 감지한다. 앞 layer에서는 edge, corner, texture처럼 단순한 pattern이 나오고, 뒤 layer에서는 이 feature map들을 다시 조합해 더 큰 구조를 표현한다.

### Padding과 Stride

| 용어 | 설정 예시 | 의미 | Output 영향 |
| :--- | :--- | :--- | :--- |
| Padding | `valid` | padding 없음 | spatial size 감소 |
| Padding | `same` | zero padding을 추가해 가장자리 포함 | stride `1` 기준 입력 spatial size 유지 |
| Stride | `1` | 각 차원에서 한 칸씩 sliding | 가장 촘촘한 sampling |
| Stride | `2` | 각 차원에서 두 칸씩 sliding | output spatial size 감소 |
| Kernel size | `3 x 3`, `5 x 5` | filter의 receptive field 크기 | 클수록 한 번에 보는 주변 영역 증가 |
| Feature map | `H_out x W_out x C_out` | convolution 결과 | filter 개수만큼 channel 생성 |

output 크기 계산은 다음과 같다.

```text
H_out = floor((H + 2*P_h - K_h) / S_h) + 1
W_out = floor((W + 2*P_w - K_w) / S_w) + 1

output shape = H_out x W_out x C_out
```

예를 들어 `input=5`, `kernel=3`, `padding=0`, `stride=1`이면 output은 `3`이다.

```text
(5 + 0 - 3) / 1 + 1 = 3
```

### Pooling

Pooling은 feature map 크기를 줄이면서 중요한 정보를 남기는 연산이다.

| Pooling | 계산 | 특징 |
| :--- | :--- | :--- |
| Max Pooling | window 내부 최댓값 선택 | 가장 강한 activation 보존 |
| Average Pooling | window 내부 평균값 선택 | 전체 반응을 부드럽게 요약 |
| 공통점 | 학습 parameter 없음 | convolution보다 계산 부담 작음 |

```text
2x2 max pooling

1 3      3
2 0  ->  max
```

Pooling을 사용하면 연산량을 줄이고, 작은 위치 변화에 덜 민감한 특징을 만들 수 있다. 다만 window 크기와 stride 선택에 따라 일부 위치 정보가 사라진다. 예를 들어 `2 x 2`, `stride=2` max pooling은 feature map을 절반 크기로 줄이면서 각 영역의 최댓값만 남긴다. 큰 값이 class 판단에 중요한 activation이라면 유리하지만, 정확한 위치나 작은 detail이 필요한 task에서는 손실이 될 수 있다.

## CNN 기반 Classification

### 기본 CNN 구조

CNN 기반 classification은 보통 `Convolution → Activation → Pooling → Flatten → Dense → Softmax` 순서로 구성한다.

```text
Input
  |
  v
Conv2D + ReLU
  |
  v
MaxPooling2D
  |
  v
Conv2D + ReLU
  |
  v
Flatten
  |
  v
Dense
  |
  v
Softmax
```

Keras에서는 다음처럼 구성할 수 있음.

```python
model = tf.keras.models.Sequential([
    tf.keras.Input(shape=(28, 28, 1)),
    tf.keras.layers.Conv2D(32, kernel_size=(3, 3), activation="relu"),
    tf.keras.layers.MaxPooling2D(pool_size=(2, 2)),
    tf.keras.layers.Flatten(),
    tf.keras.layers.Dense(128, activation="relu"),
    tf.keras.layers.Dense(10, activation="softmax")
])
```

### 1 Conv와 3 Conv 비교

단일 convolution layer model은 구조가 단순하고 빠르지만, 복잡한 특징 조합에는 한계가 있다. convolution layer를 여러 개 쌓으면 낮은 수준의 edge에서 높은 수준의 shape까지 점진적으로 특징을 만들 수 있음.

| 구조 | 특징 |
| :--- | :--- |
| 1 Conv | 구조 단순, 학습 빠름 |
| 3 Conv | 더 복잡한 특징 추출 가능, 연산량 증가 |
| Dense만 사용 | 공간 구조를 직접 활용하지 못함 |

```text
shallow CNN
Input -> Conv -> Pool -> Dense -> Softmax

deeper CNN
Input -> Conv -> Conv -> Pool -> Conv -> Pool -> Dense -> Softmax
```

## CNN 발전 시키기

### 대표 CNN model 흐름

CNN은 LeNet 이후 AlexNet, VGG, ResNet, Inception, MobileNet 계열로 발전했다. 각 model은 정확도, parameter 수, 연산량, memory footprint 사이의 균형을 다르게 잡는다.

| Model | 핵심 특징 |
| :--- | :--- |
| LeNet | 초기 CNN 구조, MNIST 분류에서 대표적 |
| AlexNet | GPU 활용, ReLU, Dropout 등으로 성능 향상 |
| VGG | 작은 `3x3` convolution을 깊게 쌓는 구조 |
| ResNet | residual connection으로 깊은 network 학습 안정화 |
| Inception | 여러 kernel 경로를 병렬로 사용 |
| MobileNet | depthwise separable convolution 기반 경량화 |
| MobileNetV2 | inverted residual block과 linear bottleneck 활용 |

### Sigmoid, ReLU, Dropout, Batch Normalization

MLP 초반 예제에서는 sigmoid activation을 사용했지만, 깊은 network에서는 sigmoid가 gradient를 작게 만들어 학습을 어렵게 할 수 있다. CNN에서는 ReLU 계열 activation을 많이 사용함.

```text
sigmoid(x) = 1 / (1 + e^-x)
ReLU(x) = max(0, x)
ReLU6(x) = min(max(0, x), 6)
```

| 기법 | 목적 |
| :--- | :--- |
| ReLU | gradient 소실 완화, 연산 단순 |
| Leaky ReLU | 음수 영역도 작은 기울기 유지 |
| Dropout | 일부 neuron을 임의로 꺼 overfitting 완화 |
| Batch Normalization | layer 입력 분포 변화 완화, 학습 안정화 |

### Transfer Learning과 Keras Applications

이미 학습된 model을 가져와 새로운 문제에 맞게 활용하는 방법을 transfer learning이라고 한다. 보통 ImageNet 등 큰 dataset으로 학습된 backbone을 feature extractor로 사용하고, 현재 dataset의 class 수에 맞는 classification head를 새로 붙여 학습한다. Keras는 `tf.keras.applications`로 여러 pretrained CNN model을 제공한다.

MobileNetV2를 사용하는 예시는 다음과 같음.

```python
base_model = tf.keras.applications.MobileNetV2(
    input_shape=(224, 224, 3),
    include_top=False,
    weights="imagenet"
)
```

| Argument | 의미 |
| :--- | :--- |
| `include_top` | 최상단 fully-connected classification layer 포함 여부 |
| `weights` | `None`, `imagenet`, 또는 weight file path |
| `input_tensor` | 입력에 사용할 Keras tensor |
| `input_shape` | 입력 shape, channel은 보통 3 |
| `classes` | 최종 class 수, top 포함 시 사용 |
| `classifier_activation` | 최종 classification activation |

MobileNetV2는 embedded/mobile target을 고려한 경량 model이다. 일반적인 residual block이 `wide → narrow → wide` 구조라면, inverted residual block은 `narrow → wide → narrow` 구조를 사용한다. 중간의 expanded channel에서 depthwise convolution을 수행해 spatial feature를 처리하고, 마지막 projection layer에서 channel 수를 줄여 memory 접근량과 multiply-add 연산량을 낮춘다.

```text
Residual block
wide -> narrow -> wide

Inverted residual block
narrow -> wide -> narrow
```

On-device target에서는 정확도만 보면 안 되고 model size, parameter 수, multiply-add 연산량, inference latency, memory 사용량을 함께 봐야 한다.

## 정리

이번 범위는 deep learning model을 firmware나 embedded target에 올리기 전에 필요한 model-side 배경이다.

```text
Machine Learning
    ↓
Regression / Classification
    ↓
Perceptron
    ↓
MLP
    ↓
CNN
    ↓
경량 CNN model
    ↓
On-Device AI 적용
```

핵심은 문제 유형에 맞는 output 구조와 cost function을 맞추는 점이다.

| 문제 | Output | Activation | Loss |
| :--- | :--- | :--- | :--- |
| Regression | 연속값 | linear | `mse` |
| Binary Classification | 0~1 확률 | `sigmoid` | `binary_crossentropy` |
| Multinomial Classification | class별 확률 | `softmax` | `categorical_crossentropy` 또는 `sparse_categorical_crossentropy` |

CNN 파트에서는 convolution과 pooling으로 공간적 특징을 뽑고, Dense/Softmax로 classification을 수행한다. On-device AI에서는 MobileNet 계열처럼 parameter 수, activation memory, 연산량, latency를 줄인 구조가 중요하다.
