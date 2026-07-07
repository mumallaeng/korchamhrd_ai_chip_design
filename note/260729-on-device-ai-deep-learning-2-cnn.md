# 26-07-29 - ON-Device AI를 위한 Deep Learning 2부: CNN

관련 노트:

- [26-07-28 - ON-Device AI를 위한 Deep Learning 1부](260728-on-device-ai-deep-learning-1.md)
- [26-07-29 - ON-Device AI를 위한 Deep Learning 1부 마무리](260729-on-device-ai-deep-learning-1-continuation.md)
- [Korcham Machine Learning·Deep Learning 고정 범위](machine-learning-deep-learning-course-map.md)

> 수업일: `2026-07-29`
>
> 원자료: Google Classroom의 `260707-on-device-ai-deep-learning-2-jpg`
> 29장과 SHA-256이 같은
> `/Volumes/Work/Safekeep/source-media/korcham/260707-image-extracts/260707-on-device-ai-deep-learning-2-jpg`
>
> 현재 상태: `2026-07-29` 수업에서 CNN 2부 전체 범위를 완료했다.
> convolution·padding·stride·pooling과 MNIST CNN Classification을
> 실습하고, ReLU·Dropout·Batch Normalization·Data Augmentation,
> Transfer Learning, 대표 CNN model과 MobileNetV2까지 진행했다.
> 이어지는 3부는 Windows·WSL·NVIDIA SDK Manager 환경을 확인하던
> 지점에서 마쳤다.

## 실습 notebook 연결

실습 코드는 Google Classroom의 다음 경로에 있다.

```text
상공회의소_KDT_실습자료(딥러닝_CNN)/
  01.DL(CNN)_Examples/
    02_CNN/
```

| Notebook | model 변화 | 확인할 항목 |
| :--- | :--- | :--- |
| `EX_01_1_Conv_MNIST_Classification.ipynb` | Conv `1개`, sigmoid | channel 축, parameter, baseline |
| `EX_02_3_Conv_MNIST_Classification.ipynb` | Conv `3개`, sigmoid | 깊이에 따른 feature map과 accuracy |
| `EX_03_MNIST_ReLU_Dropout.ipynb` | ReLU와 Dropout `0.4` | activation·regularization 효과 |

세 notebook은 같은 MNIST data를 사용한다. `float32` 변환, channel
축 추가, `0`~`1` normalization은 공통 전처리다.

```python
(train_data, train_labels), (test_data, test_labels) = mnist.load_data()

train_data = np.expand_dims(train_data.astype(np.float32), axis=-1) / 255.0
test_data = np.expand_dims(test_data.astype(np.float32), axis=-1) / 255.0
```

## 수업 범위

| 구분 | 내용 |
| :--- | :--- |
| 완료일 | `2026-07-29` |
| 2부 | CNN |
| 1과 | CNN 개요 |
| 2과 | CNN 기본연산 |
| 3과 | CNN 기반 Classification |
| 4과 | CNN 발전 시키기 |

전체 구조는 `image data → convolution으로 feature extraction → classification →
경량 CNN model → on-device target의 size·latency·memory 판단` 순서로 잡는다.


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

CNN은 Hubel과 Wiesel의 고양이 시각 피질 실험(1959~)에서 나온 receptive field 개념과 연결된다. 뉴런들이 시야 전체가 아니라 각자 작은 영역의 자극에 반응하며 복잡한 이미지를 나누어 처리한다는 관찰이다. 전체 pixel을 한 번에 fully-connected로 처리하지 않고, 작은 영역의 pattern을 여러 filter가 나눠 감지한다. 앞쪽 layer는 edge나 texture 같은 저수준 feature에 반응하고, 뒤쪽 layer는 이 feature들을 조합해 object part나 class 구분에 가까운 표현을 만든다.

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

첫 notebook의 실제 model은 다음 구조다.

```python
model = tf.keras.models.Sequential([
    tf.keras.Input(shape=(28, 28, 1)),
    tf.keras.layers.Conv2D(
        filters=32,
        kernel_size=3,
        padding="same",
        activation="sigmoid",
    ),
    tf.keras.layers.MaxPool2D(pool_size=2, strides=2),
    tf.keras.layers.Flatten(),
    tf.keras.layers.Dense(10, activation="softmax")
])
```

MNIST 원본은 `(28, 28)` 2차원 배열이라 Conv2D에 넣으려면 channel 차원을 추가해 `(28, 28, 1)`로 만들어야 한다. NumPy로 준비할 때는 `np.expand_dims(data, axis=-1)`을 사용한다.

학습 parameter 수는 layer별로 계산할 수 있다.

```text
Convolution layer: K_h * K_w * C_in * C_out + C_out (bias)
Dense layer:       입력 수 * 출력 수 + 출력 수 (bias)
```

| Layer 예시 | 계산 | Parameter 수 |
| :--- | :--- | :--- |
| Conv2D `3x3x1`, filter 32개 | `3*3*1*32 + 32` | 320 |
| Conv2D `3x3x64`, filter 64개 | `3*3*64*64 + 64` | 36,928 |
| Dense 6272 -> 10 | `6272*10 + 10` | 62,730 |
| Pooling | 학습 parameter 없음 | 0 |

`model.summary()`의 `Param #` 열이 이 계산과 일치하는지 확인하면 구조 이해를 검증할 수 있다.

### 1 Conv와 3 Conv 비교

단일 convolution layer model은 구조가 단순하고 빠르지만, 복잡한 특징 조합에는 한계가 있다. convolution layer를 여러 개 쌓으면 낮은 수준의 edge에서 높은 수준의 shape까지 점진적으로 특징을 만들 수 있음.

| 구조 | 특징 |
| :--- | :--- |
| 1 Conv | 구조 단순, 학습 빠름 |
| 3 Conv | 더 복잡한 특징 추출 가능, 연산량 증가 |
| Dense만 사용 | 공간 구조를 직접 활용하지 못함 |

notebook에 저장된 `10`번째 epoch와 전체 epoch 중 최고 validation
accuracy는 다음과 같다. 이는 저장된 실행의 결과이며, 실제 수업에서
재실행할 때는 random initialization과 실행 환경에 따라 달라질 수 있다.

| Notebook | Total params | 마지막 `val_accuracy` | 최고 `val_accuracy` |
| :--- | :--- | :--- | :--- |
| 1 Conv sigmoid | `63,050` | `0.9710` | `0.9771` |
| 3 Conv sigmoid | `80,266` | `0.9889` | `0.9906` |
| 3 Conv ReLU·Dropout | `80,266` | `0.9915` | `0.9933` |

3 Conv notebook은 `Conv2D(64) → MaxPool2D` block을 `3회` 반복한다.
ReLU·Dropout notebook은 각 convolution 뒤에 `Dropout(0.4)`를 추가한다.

```text
shallow CNN
Input -> Conv -> Pool -> Dense -> Softmax

deeper CNN
Input
  -> Conv(64, sigmoid) -> Pool
  -> Conv(64, sigmoid) -> Pool
  -> Conv(64, sigmoid) -> Pool
  -> Dense(10, softmax)

ReLU·Dropout CNN
Input
  -> Conv(64, relu) -> Dropout(0.4) -> Pool
  -> Conv(64, relu) -> Dropout(0.4) -> Pool
  -> Conv(64, relu) -> Dropout(0.4) -> Pool
  -> Dense(10, softmax)
```

3 Conv notebook은 각 convolution output을 별도 model의 output으로
연결해 feature map을 확인한다. 저장된 shape은 순서대로
`(1, 28, 28, 64)`, `(1, 14, 14, 64)`, `(1, 7, 7, 64)`다.

## CNN 발전 시키기

### 대표 CNN model 흐름

CNN은 LeNet 이후 AlexNet, VGG, ResNet, Inception, MobileNet 계열로 발전했다. 각 model은 정확도, parameter 수, 연산량, memory footprint 사이의 균형을 다르게 잡는다.

발전의 기준점이 된 것이 ImageNet 대규모 이미지 인식 대회 `ILSVRC`다. 2012년 AlexNet이 top-5 error를 종전 26% 수준에서 16%대로 낮추며 deep learning 기반 방식의 우위를 보였고, 이후 VGG와 GoogLeNet(2014), ResNet(2015, 3.57%)으로 이어지며 layer 수도 8층에서 152층까지 깊어졌다.

| Model | 발표 | 핵심 특징 |
| :--- | :--- | :--- |
| LeNet | 1998 | 초기 CNN 구조, MNIST 분류에서 대표적, sigmoid와 average pooling 사용 |
| AlexNet | 2012 | GPU 2개 병렬 학습, ReLU, Dropout, data augmentation, max pooling |
| VGG | 2014 | 작은 `3x3` convolution을 깊게 쌓는 구조 |
| GoogLeNet(Inception) | 2014 | 여러 kernel 경로를 병렬로 사용 |
| ResNet | 2015 | residual connection으로 깊은 network 학습 안정화 |
| MobileNet | 2017 | depthwise separable convolution 기반 경량화 |
| MobileNetV2 | 2018 | inverted residual block과 linear bottleneck 활용 |

### Sigmoid, ReLU, Dropout, Batch Normalization

MLP 초반 예제에서는 sigmoid activation을 사용했지만, sigmoid는 입력이 0에서 멀어지면 기울기가 0에 가까워진다. backpropagation은 layer마다 기울기를 곱해가며 전파하므로, 깊은 network에서는 0에 가까운 값이 반복해서 곱해져 앞쪽 layer까지 기울기가 도달하지 못하는 vanishing gradient problem이 생긴다. CNN에서는 ReLU 계열 activation을 많이 사용함.

```text
sigmoid(x) = 1 / (1 + e^-x)
ReLU(x) = max(0, x)
ReLU6(x) = min(max(0, x), 6)
```

ReLU는 양수 영역의 기울기가 `1`이라 sigmoid보다 깊은 network의 gradient 전달을 돕고, 지수함수 연산이 없어 계산도 단순하다. 다만 초기화·network 깊이·optimizer에 따라 gradient가 여전히 너무 작거나 커질 수 있으므로 기울기 문제를 완전히 없애지는 않는다. 음수 영역 기울기가 `0`이라 한 번 죽은 neuron이 살아나지 못할 수 있고(이를 보완한 것이 Leaky ReLU), `x=0`에서 미분 불가능한 점은 그 지점의 미분값을 관례로 정해 처리한다.

| 기법 | 목적 |
| :--- | :--- |
| ReLU | gradient 소실 완화, 연산 단순 |
| Leaky ReLU | 음수 영역도 작은 기울기 유지 |
| Dropout | 학습 중 일정 확률로 neuron을 임의로 꺼 overfitting 완화 |
| Batch Normalization | layer 입력 분포 변화 완화, 학습 안정화 |

Dropout은 꺼진 neuron의 입출력 연결이 함께 끊기므로, 남은 neuron들이 특정 neuron에 의존하지 않고 스스로 중요한 특징을 학습하게 만드는 regularization 기법이다.

Batch Normalization은 mini-batch의 activation을 정규화한 뒤 학습 가능한 scale(γ)과 shift(β)를 적용한다. 그 결과 optimization이 안정되고 더 큰 learning rate를 쓰기 쉬워지는 경우가 많다. 이를 `internal covariate shift` 완화로 설명해 왔지만, 실제로는 정규화 방식과 optimization landscape의 변화, batch에서 생기는 noise를 함께 보는 편이 안전하다.

```text
1. batch 평균 μ, 분산 σ² 계산
2. x_norm = (x - μ) / sqrt(σ² + ε)
3. y = γ * x_norm + β   (γ, β는 학습 대상)
```

학습 속도가 빨라지고 regularization 효과도 있어 overfitting 완화에 도움이 된다.

Dropout과 Batch Normalization은 모두 학습과 추론에서 동작이 다르다는 점을 함께 기억해야 한다.

| 기법 | 학습(training) | 추론(inference) |
| :--- | :--- | :--- |
| Dropout | 일정 확률로 neuron을 끔 | 아무것도 끄지 않음, 전체 neuron 사용 |
| Batch Normalization | 현재 batch의 평균·분산으로 정규화 | 학습 중 누적한 이동평균 통계로 정규화 |

Dropout을 추론에서도 켜 두면 출력이 실행마다 달라지고, BN을 batch 통계로 추론하면 batch 크기 1의 실시간 입력에서 통계가 무의미해진다. Keras는 `fit()`과 `predict()`가 이 전환을 자동으로 처리하지만, `model(x, training=True)`처럼 mode를 직접 지정하는 호출이나 framework 간 변환(ONNX export 등)에서는 어느 mode의 그래프가 나가는지 확인해야 한다. 추론용으로 변환된 model에서 dropout layer가 사라지고 BN이 상수 연산으로 접히는(folding) 것은 이 때문이다.

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

대표 pretrained model의 크기·정확도·parameter 수를 비교하면 on-device 선택 기준이 보인다. 아래는 Keras applications 문서의 ImageNet validation 기준 수치다.

| Model | Size | Top-1 accuracy | Parameters |
| :--- | :--- | :--- | :--- |
| Xception | 88MB | 0.790 | 22.9M |
| VGG16 | 528MB | 0.713 | 138.4M |
| ResNet50 | 98MB | 0.749 | 25.6M |
| InceptionV3 | 92MB | 0.779 | 23.9M |
| MobileNet | 16MB | 0.704 | 4.3M |
| MobileNetV2 | 14MB | 0.713 | 3.5M |
| NASNetLarge | 343MB | 0.825 | 88.9M |

VGG16과 MobileNetV2는 Top-1 정확도가 같지만 크기와 parameter 수가 약 40배 차이 난다. embedded target에서 MobileNet 계열을 기본 후보로 두는 이유가 이 표에 요약되어 있다.

MobileNetV2는 embedded/mobile target을 고려한 경량 model이다. 일반적인 residual block이 `wide → narrow → wide` 구조라면, inverted residual block은 `narrow → wide → narrow` 구조를 사용한다. 중간의 expanded channel에서 depthwise convolution을 수행해 spatial feature를 처리하고, 마지막 projection layer에서 channel 수를 줄여 memory 접근량과 multiply-add 연산량을 낮춘다.

```text
Residual block
wide -> narrow -> wide

Inverted residual block
narrow -> wide -> narrow
```

On-device target에서는 정확도만 보면 안 되고 model size, parameter 수, multiply-add 연산량, inference latency, memory 사용량을 함께 봐야 한다.

## CNN 단원에서 병행할 깊이 축

| 단원 | 수업에서 잡을 중심 | 2·3차 회독 질문 |
| :--- | :--- | :--- |
| CNN 개요 | local receptive field와 feature map | receptive field가 layer를 지날수록 커지는 과정을 계산할 수 있는가 |
| CNN 기본연산 | convolution·padding·stride·pooling | output shape, parameter 수, MAC 수, activation memory를 손으로 계산할 수 있는가 |
| CNN classification | feature extractor와 classifier | confusion matrix와 class별 precision·recall·F1로 오류 원인을 찾을 수 있는가 |
| CNN 발전 | residual·depthwise separable convolution·transfer learning | freeze·unfreeze·fine-tuning과 accuracy·size·latency tradeoff를 실험할 수 있는가 |

구현에서는 다음 항목을 확인한다.

- convolution의 한 축 출력 크기는 일반적으로 `floor((M + 2P - D(N - 1) - 1) / S) + 1`이다. 여기서 `D`는 dilation이다.
- `1x1` convolution, residual connection, depthwise와 pointwise convolution의 tensor shape와 연산량 차이를 계산한다.
- Batch Normalization은 training에서 현재 batch 통계를, inference에서 학습 중 누적한 running 통계를 사용한다.
- transfer learning은 backbone을 고정한 baseline, 일부 layer 해제, 작은 learning rate의 fine-tuning을 차례로 비교한다.
- Codeit·Addinedu·기타 자료의 CNN 설명과 실습은 이 CNN 단원을 배우는
  같은 pass에서 병행하고,
  [[domains/data-science/ai/on-device-ai-ml-dl-yolo-curriculum|AI·ML·DL 통합 큰그림]]의
  CNN 개념과 Korcham TODO를 하나의 학습 결과로 갱신한다.
- Object Detection·YOLO는 이어지는 3부 Jetson Orin Nano 직접 수업
  범위에서 배우며, 시계열처럼 1~3부와 겹치지 않는 내용만 그 뒤로 둔다.

## 3부와 이후 심화 연결

이 2부 교재의 직접 범위는 MobileNetV2까지지만, ONNX·TensorRT·Jetson
runtime·Object Detection·YOLO·local LLM은 이어지는 3부 직접 수업 범위다.
pruning·distillation·quantization 심화와 NPU·FPGA hardware 확장은
[[domains/data-science/ai/on-device-ai-ml-dl-yolo-curriculum|On-Device AI ML·DL·YOLO 학습 커리큘럼]]에서
다룬다. 3부가 끝나면 기존 RPS·YOLO model과 Jetson 환경으로 상세 device
profiling과 NPU의 MAC·SRAM·DMA·tiling·data reuse를 먼저 빠르게 학습한다.

## 회독별 통과 기준

| pass | 확인할 결과 |
| :--- | :--- |
| 1차 지도 | input shape, feature extractor, classifier, output과 loss를 구분 |
| 2차 동작 | convolution·padding·stride·pooling의 output shape와 한 위치 연산을 추적 |
| 3차 재구성 | CNN 구조나 device 조건 하나를 바꾸어 정확도·크기·latency 차이를 설명 |

자료를 읽은 사실만으로 pass를 완료하지 않는다. `2026-07-29` 실제 수업에서
CNN 2부 전체 진도를 완료했으며, 위 2차·3차 pass는 수업 완료 뒤 반복 학습과
재구성 실습에서 이어간다.

## 정리

이번 2부는 deep learning model을 firmware나 embedded target에 올리기 전에 필요한 CNN의 model-side 배경이다.

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
