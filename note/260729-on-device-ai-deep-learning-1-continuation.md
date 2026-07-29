# 26-07-29 - ON-Device AI를 위한 Deep Learning 1부 마무리

관련 노트:

- [26-07-28 - ON-Device AI를 위한 Deep Learning 1부](260728-on-device-ai-deep-learning-1.md)
- [Machine Learning·Deep Learning 전체 지도](machine-learning-deep-learning-course-map.md)
- [26-07-29 - ON-Device AI를 위한 Deep Learning 2부: CNN](260729-on-device-ai-deep-learning-2-cnn.md)
- [Embedded Linux·Jetson On-Device AI 전체 지도](embedded-linux-jetson-on-device-ai-course-map.md)

> 수업일: `2026-07-29`
>
> 원자료: Google Classroom의 `260707-on-device-ai-deep-learning-1-jpg`
> 47장 및 `260707-on-device-ai-deep-learning-2-jpg` 29장과 SHA-256이
> 같은
> `/Volumes/Work/Safekeep/source-media/korcham/260707-image-extracts/260707-on-device-ai-deep-learning-1-jpg`,
> `/Volumes/Work/Safekeep/source-media/korcham/260707-image-extracts/260707-on-device-ai-deep-learning-2-jpg`
>
> 현재 상태: `2026-07-29` 수업은 전날 내용을 복습한 뒤 Logistic
> Regression, Multinomial Classification, Multi Layer Perceptron,
> backpropagation을 거쳐 MNIST Classification까지 진행했다. 단층
> softmax baseline과 hidden layer model을 비교하고, sigmoid layer를
> 지나치게 깊게 쌓았을 때 나타나는 vanishing gradient를 확인했다.
> 이 지점에서 1부를 마쳤고, 같은 날 이어진 2부 전체 진도는
> [26-07-29 - ON-Device AI를 위한 Deep Learning 2부: CNN](260729-on-device-ai-deep-learning-2-cnn.md)에서
> 정리한다.

## 수업 범위

| 순서 | 실제 진행 내용 |
| :--- | :--- |
| 1 | 지도·비지도·강화학습과 regression·classification 복습 |
| 2 | Perceptron, Linear Regression, MSE, Gradient Descent 복습 |
| 3 | Min-Max scaling과 Keras model 구성·학습 순서 복습 |
| 4 | Logistic Regression, sigmoid, odds·logit |
| 5 | Binary Cross Entropy 식과 label별 cost 항 |
| 6 | 나이·BMI 기반 고혈압 분류 model과 accuracy |
| 7 | Multinomial Classification과 softmax |
| 8 | Categorical Cross Entropy와 one-hot label |
| 9 | XOR 문제와 Multi Layer Perceptron parameter 계산 |
| 10 | chain rule을 이용한 backpropagation |
| 11 | train·validation·test data와 overfitting |
| 12 | Batch·Mini-batch·Stochastic Gradient Descent |
| 13 | MNIST 단층 softmax baseline과 hidden layer 비교 |
| 14 | 깊은 sigmoid network의 vanishing gradient |

## 수업 흐름

```text
Machine Learning 문제 유형
  → Perceptron
  → Linear Regression·MSE
  → Gradient Descent·learning rate
  → Min-Max scaling
  → Keras Sequential model
  → Logistic Regression·sigmoid
  → odds·logit
  → Binary Cross Entropy
  → 고혈압 분류 실습
  → softmax·Categorical Cross Entropy
  → XOR
  → Multi Layer Perceptron
  → backpropagation
  → validation·mini-batch
  → MNIST Classification
  → hidden layer·vanishing gradient
  → CNN convolution
```

## 실습 notebook과 수업 진도 연결

실습 코드는 Google Classroom의 다음 경로에 있다.

```text
상공회의소_KDT_실습자료(딥러닝_CNN)/
  01.DL(CNN)_Examples/
    01_ML_DL_Basic/
```

| Notebook | 수업 연결 | 핵심 확인 |
| :--- | :--- | :--- |
| `EX_01_Perceptron.ipynb` | Perceptron | `W * X`, 합계, bias, step function |
| `EX_02_Optimize_Hypothesis.ipynb` | Linear Regression | NumPy로 MSE와 Gradient Descent 직접 구현 |
| `EX_03_Blood_Pressure_Linear_Regression.ipynb` | 단일 input 회귀 | 나이로 혈압 예측, learning rate 조정 |
| `EX_04_N-variable_M-output_LR_Keras.ipynb` | 다중 input·output | 나이·BMI → 수축기·이완기 혈압, `Dense(2)` |
| `EX_05_Blood_Pressure_Logistic_Regression.ipynb` | Binary Classification | sigmoid, BCE, accuracy |
| `EX_06_Blood_Pressure_Softmax_Classification.ipynb` | Multinomial Classification | one-hot label, softmax, CCE |
| `EX_07_MNIST_Classification.ipynb` | MNIST Classification | `Flatten(784) → Dense(10)` baseline과 hidden layer 비교 |

현재 진도와 직접 연결되는 파일은 `EX_05`, `EX_06`, `EX_07`이다.
CNN 시작 구간은
[26-07-29 - ON-Device AI를 위한 Deep Learning 2부: CNN](260729-on-device-ai-deep-learning-2-cnn.md)의
convolution과 padding 항목으로 이어진다.

## 1부 핵심 복습

### Machine Learning에서 Keras 학습까지

Supervised Learning은 input과 label을 함께 사용하며, 연속값을
예측하는 regression과 class를 판별하는 classification으로 나뉜다.
Perceptron은 각 input에 weight를 곱하고 bias를 더한 뒤 activation
function을 통과시켜 output을 만든다. 학습되는 parameter는 weight와
bias다.

Linear Regression에서는 `H(x) = Wx + b`로 연속값을 예측하고,
예측값과 label의 차이를 MSE로 평가한다. Gradient Descent는 cost의
기울기를 이용해 `W`, `b`를 반복해서 갱신한다. learning rate가 너무
크면 minimum을 지나치며 발산할 수 있고, 너무 작으면 학습이 느려진다.

나이와 혈압처럼 input 값의 범위가 크면 같은 learning rate에서도
parameter 갱신 폭이 커질 수 있다. Min-Max scaling으로 feature를
`0`~`1` 범위로 맞추면 더 안정적인 learning rate를 사용할 수 있다.
학습 후 새 값을 예측할 때도 train data에 적용한 것과 같은
preprocessing을 적용해야 한다.

여러 input과 여러 output을 가진 하나의 `Dense` layer는 output
Perceptron이 여러 개인 구조다. 앞 layer의 output이 다음 layer의
input으로 연결되어야 Multi Layer Perceptron이 된다.

Keras에서는 단순한 직렬 model에 Sequential API를 사용한다.
`compile()`에서 optimizer·loss·metric을 정하고, `fit()`에서
data·label·epoch·batch size를 지정한다. 문자열로 optimizer나 loss를
전달하면 default parameter를 사용하고, learning rate 등을 직접
바꾸려면 instance를 만들어 전달한다.

```text
model 구성
  → compile(optimizer, loss, metrics)
  → fit(data, labels, epochs, batch_size)
  → evaluate 또는 predict
```

### Logistic Regression과 sigmoid

Linear Regression의 출력은 실수 전체 범위이므로 class `1`일 확률을
직접 나타내지 못한다. Logistic Regression은 선형식의 결과인 logit
`z = Wx + b`를 sigmoid에 넣어 `0`~`1` 사이의 확률 `p`로 변환한다.

```text
p = sigmoid(z) = 1 / (1 + e^-z)

p >= 0.5  → class 1
p <  0.5  → class 0
```

`W`는 sigmoid 곡선의 기울기에, `b`는 좌우 위치에 영향을 준다.
sigmoid는 `z = 0`일 때 `p = 0.5`이므로 decision boundary는
`Wx + b = 0`에서 형성된다.

확률 `p`를 odds와 logit으로 바꾸는 관계는 다음과 같다.

```text
odds = p / (1 - p)
logit = log(odds)
p = sigmoid(logit)
```

따라서 model의 선형 출력 `Wx + b`를 logit으로 해석하고, sigmoid를
거친 값을 class `1`일 확률로 해석할 수 있다. 고혈압 분류라면
`p`는 고혈압일 확률이고, spam 분류라면 spam일 확률이다. class
`0`일 확률은 `1 - p`다.

### Binary Cross Entropy

Binary Classification에서는 label `y`가 `0` 또는 `1`이므로 다음
Binary Cross Entropy를 사용한다.

```text
cost = -y*log(p) - (1-y)*log(1-p)
```

label 값에 따라 한 항에는 `0`이 곱해져 사라지고, 정답 class에
해당하는 항만 남는다.

| label `y` | 남는 cost | cost가 작아지는 예측 |
| :--- | :--- | :--- |
| `1` | `-log(p)` | `p`가 `1`에 가까움 |
| `0` | `-log(1-p)` | `p`가 `0`에 가까움 |

이 구조는 정답 class에 높은 확률을 줄수록 cost를 낮추고, 확신을 갖고
틀린 예측에는 큰 cost를 부여한다.

여기서 `log`는 자연로그 `ln`을 뜻한다. 실제 label이 `1`인데 model이
`p = 0.1`처럼 낮은 확률을 출력하면 `-ln(0.1)`이 커지므로 cost가
증가한다. 정답 분포와 예측 분포가 가까워질수록 cost는 작아진다.

나이와 BMI를 input으로 받아 고혈압 여부를 예측하는 실습은 input
feature `2개`, output neuron `1개`로 구성했다. input에는 Min-Max
scaling을 적용하고 output에는 sigmoid를 사용했다. classification은
맞고 틀림을 판정할 수 있으므로 `metrics=["accuracy"]`를 추가했다.
notebook에 저장된 `1000`번째 epoch 결과는 accuracy `0.7778`, loss
`0.4469`다.

```python
model = tf.keras.models.Sequential([
    tf.keras.Input(shape=(2,)),
    tf.keras.layers.Dense(1, activation="sigmoid")
])

model.compile(
    optimizer=tf.keras.optimizers.SGD(learning_rate=0.1),
    loss="binary_crossentropy",
    metrics=["accuracy"]
)

history = model.fit(x_input, labels, epochs=1000)
```

`Dense(1)`의 parameter는 weight `2개`와 bias `1개`를 합한 `3개`다.
새 data를 예측할 때도 notebook의 `predict()`처럼 학습 data에서 구한
`x_min`, `x_max`를 재사용해야 한다.

```python
def predict(x):
    return model.predict((x - x_min) / (x_max - x_min))
```

### Multinomial Classification과 softmax

class가 `3개` 이상이면 각 class와 나머지를 구분하는 decision
boundary가 class 수만큼 필요하다. 각 output에 sigmoid를 독립적으로
적용하는 방식도 class별 확률을 만들 수 있지만, 각 확률이 서로
독립적이어서 합이 `1`이 되지 않는다.

softmax는 각 class의 logit에 지수함수를 적용한 뒤 전체 합으로
나누어, 모든 class 확률의 합을 `1`로 만든다.

```text
softmax(z_i) = exp(z_i) / Σ exp(z_j)
Σ softmax(z_i) = 1
```

지수함수를 적용하면 큰 logit과 작은 logit의 차이가 더 분명해진다.
model에는 odds를 직접 전달하지 않고 class별 logit을 전달하며,
softmax가 지수 계산과 normalization을 수행한다.

input feature가 `2개`이고 class가 `3개`라면 output Perceptron도
`3개`다. 각 Perceptron에는 weight `2개`와 bias `1개`가 있으므로
parameter 수는 다음과 같다.

```text
(input 2 + bias 1) × output 3 = 9 parameters
```

### Categorical Cross Entropy

Multinomial Classification의 label을 one-hot vector로 표현하면 정답
class 위치만 `1`이고 나머지는 `0`이다. Categorical Cross Entropy에서
label이 `0`인 항은 사라지므로 실제 계산에는 정답 class의 항만 남는다.

```text
cost = -Σ y_i * log(p_i)
```

| 실제 class | one-hot label | 남는 항 |
| :--- | :--- | :--- |
| class `0` | `[1, 0, 0]` | `-log(p_0)` |
| class `1` | `[0, 1, 0]` | `-log(p_1)` |
| class `2` | `[0, 0, 1]` | `-log(p_2)` |

실습의 class index는 `0: 정상`, `1: 주의`, `2: 경고`다. input을
Min-Max scaling한 뒤 output `3개`와 softmax activation을 사용했다.
notebook에 저장된 `1000`번째 epoch 결과는 accuracy `0.7222`, loss
`0.7291`이다.

```python
model = tf.keras.models.Sequential([
    tf.keras.Input(shape=(2,)),
    tf.keras.layers.Dense(3, activation="softmax")
])

model.compile(
    optimizer=tf.keras.optimizers.SGD(learning_rate=0.1),
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)

history = model.fit(x_input, labels, epochs=1000)
```

예측 class는 확률 vector에서 가장 큰 값의 index로 고른다. notebook의
`Age=50`, `BMI=25` 예측은 `[0.3584, 0.4427, 0.1990]`에 가까워
`np.argmax()` 결과가 class `1`, 즉 '주의'다.

```python
H_x = predict(tf.constant([[50.0, 25.0]], dtype=tf.float32))
predicted_class = np.argmax(H_x[0])
```

### XOR와 Multi Layer Perceptron

XOR은 두 input이 같으면 `0`, 다르면 `1`을 출력한다.

| `x0` | `x1` | XOR |
| :--- | :--- | :--- |
| `0` | `0` | `0` |
| `0` | `1` | `1` |
| `1` | `0` | `1` |
| `1` | `1` | `0` |

XOR의 네 점은 하나의 직선 decision boundary로 class `0`과 `1`을
분리할 수 없다. Single Layer Perceptron 하나로는 해결할 수 없으며,
여러 Perceptron의 output을 다음 layer의 input으로 연결해야 한다.
input layer와 output layer 사이에 있는 layer를 hidden layer라고
부른다.

```text
input
  → hidden layer: 여러 decision boundary 생성
  → hidden layer: 중간 표현 결합
  → output layer: 최종 class 판정
```

Dense layer의 parameter 수는 `(input 수 + bias 1) × neuron 수`로
계산한다. `3→4→4→1` 구조에서는 trainable layer별 parameter가 다음과
같다.

| 연결 | 계산 | parameter |
| :--- | :--- | :--- |
| input `3` → hidden `4` | `(3 + 1) × 4` | `16` |
| hidden `4` → hidden `4` | `(4 + 1) × 4` | `20` |
| hidden `4` → output `1` | `(4 + 1) × 1` | `5` |
| 합계 | `16 + 20 + 5` | `41` |

layer가 깊어질수록 더 복잡한 decision boundary를 표현할 수 있지만,
각 layer의 parameter가 연결되므로 학습을 위한 효율적인 gradient
계산 방법이 필요하다.

### Backpropagation과 chain rule

Feedforward에서는 input이 각 layer의 weight·bias·activation을 차례로
통과해 예측값을 만들고, 예측값과 label로 loss를 계산한다.
Backpropagation은 loss에서 시작해 계산 경로를 반대로 따라가며 각
parameter가 loss에 미친 영향을 구한다.

```text
input
  → weighted sum + bias
  → activation
  → prediction
  → loss
  → local derivative를 역방향으로 곱함
  → 각 weight·bias의 gradient
```

예를 들어 `G = XW`, `F = G + b`, `L = (F-y)^2`라면 `W`의 gradient는
chain rule로 계산한다.

```text
dL/dW = dL/dF × dF/dG × dG/dW
```

긴 식을 한 번에 미분하는 대신 각 연산의 local derivative를 구해
곱하므로, layer가 여러 개인 model에서도 같은 원리로 gradient를
계산할 수 있다.

### Train·validation·test data

train data는 parameter를 학습하는 데 사용하고, validation data는
학습 중 일반화 성능을 관찰해 overfitting 여부와 hyperparameter를
판단하는 데 사용한다. test data는 최종 model 평가에 사용한다.

| 상태 | train 성능 | validation 성능 | 해석 |
| :--- | :--- | :--- | :--- |
| underfitting | 낮음 | 낮음 | model이 pattern을 충분히 학습하지 못함 |
| 적절한 학습 | 향상 | 함께 향상 | 보지 않은 data에도 일반화 |
| overfitting | 계속 향상 | 정체 또는 하락 | train data에 과도하게 맞춰짐 |

Keras에서는 validation data를 직접 전달하거나 train data 일부를
분리할 수 있다.

```python
model.fit(
    train_data,
    train_labels,
    validation_split=0.3,
    epochs=5
)
```

`validation_split=0.3`이면 주어진 train data의 `70%`로 학습하고
`30%`로 validation 성능을 확인한다.

### Batch·Mini-batch·Stochastic Gradient Descent

parameter를 한 번 갱신할 때 사용하는 sample 수에 따라 학습 방식을
구분한다.

| 방식 | 한 번의 gradient 계산에 쓰는 data | 특징 |
| :--- | :--- | :--- |
| Batch Gradient Descent | 전체 train data | gradient가 안정적이지만 memory와 계산 부담이 큼 |
| Mini-batch Gradient Descent | 일정 크기의 묶음 | 계산 효율과 gradient 변동을 절충 |
| Stochastic Gradient Descent | sample `1개` | 갱신이 잦고 gradient 변동이 큼 |

Keras의 default `batch_size`는 `32`다. MNIST train sample
`60,000개`를 batch `32개`씩 사용하면 한 epoch에서
`60,000 / 32 = 1,875회` parameter를 갱신한다.

## MNIST Classification

MNIST 입력 data는 `28x28` 배열이다. notebook의 기본 실행 구조는
`Flatten`으로 `784개` feature를 만든 뒤 숫자 `0`~`9`의 class
확률을 바로 출력하는 단층 softmax model이다.

```text
28 x 28
  |
  v
Flatten -> 784
  |
  v
Dense(10, softmax)
```

notebook에는 hidden layer `2개`가 선택 실험용 주석으로 남아 있다.
수업에서는 두 줄을 주석 처리한 baseline을 먼저 실행한 뒤, hidden
layer의 주석을 해제해 결과를 비교했다.

```python
model = tf.keras.models.Sequential([
    tf.keras.Input(shape=(28, 28)),
    tf.keras.layers.Flatten(),
    # tf.keras.layers.Dense(256, activation="sigmoid"),
    # tf.keras.layers.Dense(256, activation="sigmoid"),
    tf.keras.layers.Dense(10, activation="softmax")
])

model.compile(
    optimizer="adam",
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"]
)
```

MNIST pixel은 `0`~`255` 범위이므로 `255`로 나누어 `0`~`1`로
정규화한다. train data로 model을 학습하고, 학습에 사용하지 않은 test
data로 loss와 accuracy를 평가한다.

```python
mnist = tf.keras.datasets.mnist
(train_data, train_labels), (test_data, test_labels) = mnist.load_data()

train_data, test_data = train_data / 255.0, test_data / 255.0

history = model.fit(train_data, train_labels, epochs=5)
model.evaluate(test_data, test_labels)   # [loss, accuracy] 반환
```

`Flatten`은 data shape만 바꾸므로 parameter가 없고, `Dense(10)`은
`784 × 10 + bias 10 = 7,850개` parameter를 가진다. notebook에 저장된
baseline 결과는 train accuracy 약 `0.9272`, test 결과
`[loss=0.2670, accuracy=0.9257]`이다.

hidden layer를 활성화한 결과는 현재 notebook output에 저장되어 있지
않지만, 수업 실행에서는 train accuracy가 약 `98%`, test accuracy가
약 `97%`~`98%`로 baseline보다 높아졌다. 이 구조의 parameter 수는
다음과 같다.

| Layer | 계산 | parameter |
| :--- | :--- | :--- |
| `784 → 256` | `(784 + 1) × 256` | `200,960` |
| `256 → 256` | `(256 + 1) × 256` | `65,792` |
| `256 → 10` | `(256 + 1) × 10` | `2,570` |
| 합계 | `200,960 + 65,792 + 2,570` | `269,322` |

layer를 더 많이 쌓는다고 항상 성능이 증가하지는 않는다. layer 수가
늘면 표현력은 커지지만 optimization이 어려워지고, 필요한 epoch와
optimizer 설정도 달라질 수 있다.

| 관찰 | 해석 |
| :--- | :--- |
| layer 추가 후 성능 하락 | epoch 부족, activation 문제, optimization 난이도 증가 가능 |
| epoch 증가 후 성능 회복 | 깊어진 구조에 더 긴 학습이 필요한 경우 |
| layer만 계속 추가 | overfitting 또는 gradient 문제 가능 |

수업에서는 sigmoid hidden layer를 `5개` 이상으로 늘렸을 때 같은
epoch 수에서 오히려 성능이 낮아지는 결과를 확인했다. 일부 구조는
학습을 더 반복하면 train accuracy 약 `99%`, test accuracy 약
`97.9%`까지 회복했지만, 약 `100만개` parameter를 가진 매우 깊은
sigmoid network는 학습이 제대로 진행되지 않았다.

sigmoid의 derivative는 값이 작고, layer를 역방향으로 지날 때마다 이
값이 연속해서 곱해진다. 앞쪽 layer로 전달되는 gradient가 매우
작아지는 현상이 vanishing gradient다. 깊은 model에서는 ReLU 계열
activation, 적절한 initialization, normalization 등을 함께 고려해야
한다.

## 2부 CNN으로 이어짐

1부를 마친 뒤 같은 날 CNN 2부 전체를 진행했다. convolution,
padding·stride·pooling, CNN Classification, ReLU·Dropout·Data
Augmentation, Transfer Learning, MobileNetV2는
[26-07-29 - ON-Device AI를 위한 Deep Learning 2부: CNN](260729-on-device-ai-deep-learning-2-cnn.md)에서
정리한다.

## 1부를 깊게 이해하기 위한 보강 질문

| 단원 | 수업 중심 | 2·3차 회독 질문 |
| :--- | :--- | :--- |
| ML 배경·Perceptron | `weighted sum + bias + activation` | 실제 on-device 문제의 `Task·Performance·Experience`, feature, label을 정의할 수 있는가 |
| Linear Regression | `MSE → gradient descent` | 벡터화된 식, 학습률, scaling, baseline, data leakage를 함께 설명할 수 있는가 |
| Logistic Regression | `sigmoid + BCE` | logit·odds·threshold가 precision·recall에 미치는 영향을 비교할 수 있는가 |
| Softmax | 여러 class의 logit을 확률분포로 변환 | `z - max(z)`가 overflow를 막는 이유와 multi-class·multi-label 차이를 설명할 수 있는가 |
| MLP | `forward → loss → backpropagation → update` | chain rule, initialization, SGD·momentum·Adam, schedule, L1/L2·dropout·BN의 위치를 구분할 수 있는가 |

구현에서는 다음 정확성 항목을 확인한다.

- MSE gradient의 상수 `2`를 생략해도 최적점은 같지만 유효 learning rate가 달라진다.
- softmax는 `exp(z)`를 바로 계산하지 않고 `exp(z - max(z))`로 계산해 큰 logit의 overflow를 피한다.
- 전체 accuracy만 보지 않고 confusion matrix와 class별 precision·recall·F1을 함께 본다.
- random seed, data split, preprocessing, model 설정, metric을 기록해야 실험을 다시 비교할 수 있다.
- Batch Normalization은 training에서 현재 batch 통계를, inference에서 누적한 running 통계를 사용한다.

전체 확장 순서와 통과 기준은
[Machine Learning·Deep Learning 전체 지도](machine-learning-deep-learning-course-map.md)를
따른다.

## 다음에 확인할 것

- padding 계산과 stride 변화에 따른 output shape
- pooling과 convolution의 역할 차이
- CNN 기반 MNIST Classification model 구성
- sigmoid와 ReLU의 gradient 전달 차이
