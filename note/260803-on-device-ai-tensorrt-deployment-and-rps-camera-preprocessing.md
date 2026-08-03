# 26-08-03 - ONNX·TensorRT 배포와 RPS camera preprocessing

관련 노트:

- [26-07-30 - Jetson 원격 개발 환경과 OpenCV 얼굴 검출 스트리밍](260730-jetson-remote-development-and-opencv-face-detection.md)
- [Embedded Linux·Jetson On-Device AI 전체 지도](embedded-linux-jetson-on-device-ai-course-map.md)
- [Machine Learning·Deep Learning 전체 지도](machine-learning-deep-learning-course-map.md)

> 수업일: `2026-08-03`
>
> 현재 상태: transfer learning으로 만든 Keras image classification model을 저장하고, target device의 runtime에 맞는 inference model로 변환하는 흐름을 다뤘다. Jetson에서는 TensorRT engine을 통해 GPU로 inference를 실행하는 경로를 사용한다.

## 수업 범위

| 구분 | 내용 |
| :--- | :--- |
| 학습 data | train·test 분할, `224 × 224 × 3` RGB image input |
| Keras model | MobileNetV2 transfer learning, functional API, classification head |
| 학습 관리 | `compile()`·`fit()`, validation metric, ModelCheckpoint |
| model 보존 | Colab runtime model을 Google Drive에 저장·다시 load |
| 경량 runtime | LiteRT용 model conversion과 CPU inference |
| Jetson deployment | Keras/TensorFlow model → ONNX → TensorRT engine → GPU inference |
| inference 안정화 | TensorRT binding·precision 확인, data augmentation 재학습 |

## 전체 흐름

```text
image dataset
  → train / validation / test split
  → MobileNetV2 backbone + classification head 학습
  → best validation model 저장
  → target device용 model conversion
      ├─ LiteRT model → lightweight runtime → CPU inference
      └─ ONNX model → optional simplification → TensorRT engine → Jetson GPU inference
```

학습 framework와 target의 inference runtime은 역할이 다르다. Keras/TensorFlow는 model을 구성하고 학습하기에 편한 환경이고, LiteRT와 TensorRT는 학습이 끝난 model을 target device에서 빠르고 가볍게 실행하는 runtime이다.

## Transfer Learning classification model

이번 model은 ImageNet으로 미리 학습된 MobileNetV2를 feature extractor로 사용하고, 수업 data의 class 수에 맞는 classification head를 뒤에 붙이는 구조다.

```text
`224 × 224 × 3` image
  → MobileNetV2 backbone
  → GlobalAveragePooling2D
  → Dense(128) + activation
  → Dropout
  → Dense(3) + Softmax
```

### MobileNetV2 backbone과 fine-tuning

처음에는 MobileNetV2 backbone의 `trainable`을 `False`로 두고, 새로 붙인 classification head만 학습한다. 이미 배운 image feature를 재사용하므로 data가 많지 않은 과제에서도 빠르게 baseline을 확인할 수 있다.

결과가 부족할 때에는 backbone의 일부 layer를 풀어 낮은 learning rate로 추가 학습하는 fine-tuning을 진행한다. 처음부터 전체 backbone을 학습하면 parameter update 범위가 커지고, 작은 data에 과하게 맞춰질 가능성이 커진다.

### Functional API와 Sequential API

Sequential API는 앞 layer의 output이 다음 layer의 input으로 직선으로 이어지는 model을 구성한다. Functional API는 `Input` tensor와 `Output` tensor를 명시해 branch, skip connection, 여러 input·output을 포함한 graph 구조까지 표현한다.

MobileNetV2 backbone에 별도의 classification head를 연결하는 구조는 Functional API로 자연스럽게 나타낼 수 있다.

### Global Average Pooling

MobileNetV2의 마지막 feature map은 channel마다 공간 방향 값들을 가진다. `GlobalAveragePooling2D`는 channel 하나의 모든 spatial value를 평균 내어 feature 하나로 만든다.

```text
`7 × 7 × 1280` feature map
  → channel별 spatial average
  → `1280` feature vector
```

Flatten으로 모든 spatial value를 그대로 펼치는 방식보다 classification head의 parameter 수를 줄일 수 있다. 이후 Dense layer가 class를 구분하는 feature 조합을 학습하고, 마지막 `Softmax`가 세 class의 score를 probability 형태로 만든다.

### Preprocessing 위치

MobileNetV2에 맞는 normalization은 input pipeline에서 별도 code로 둘 수도 있고, model 안의 preprocessing layer로 포함할 수도 있다. model 내부에 포함하면 training과 inference가 같은 transform을 사용하므로 target에서 preprocessing을 빠뜨릴 위험이 줄어든다.

## 학습 결과의 보존

`compile()`은 optimizer, loss function, metric을 정해 model을 학습 가능한 상태로 만든다. `fit()`은 train data로 parameter를 update하고 validation data로 각 epoch의 일반화 성능을 확인한다.

`ModelCheckpoint`는 지정한 validation metric이 가장 좋을 때의 model을 저장한다. 매 epoch의 model을 전부 저장하지 않고 best model만 남길 수 있으며, 학습이 길거나 Colab runtime이 끊길 수 있는 환경에서 특히 중요하다.

```text
training runtime
  → validation metric 비교
  → best checkpoint 저장
  → Google Drive의 durable path
  → target device로 복사·load
```

Colab runtime의 local storage는 session이 종료되면 사라질 수 있다. model file은 Drive 같은 durable storage에 저장하고, 이후 `load_model()` 또는 target runtime의 load API에 같은 path를 전달해 다시 사용한다.

## Target별 inference runtime

| target | model 형태 | 실행 runtime | 주된 연산 자원 | 특징 |
| :--- | :--- | :--- | :--- | :--- |
| 개발 PC·Colab | Keras saved model | TensorFlow/Keras | CPU 또는 GPU | 학습·debug에 편리한 전체 framework |
| Raspberry Pi 등 경량 board | LiteRT model | LiteRT interpreter | 주로 CPU | package와 model이 작고 inference 중심 |
| Jetson Orin Nano | TensorRT engine | TensorRT | NVIDIA GPU | GPU target optimization과 낮은 inference latency |

### LiteRT

LiteRT는 inference에 필요한 runtime만 사용하도록 model을 변환해 resource가 제한된 device에서 실행하는 경로다. Keras model을 LiteRT model로 변환하면 file과 runtime 의존성을 줄일 수 있다.

기본 LiteRT interpreter는 CPU로 실행한다. GPU delegate 등을 별도로 구성할 수 있지만, 단순히 LiteRT format으로 바꾸는 것만으로 Jetson GPU가 자동 사용되지는 않는다.

## Jetson TensorRT deployment

Jetson board에는 NVIDIA GPU가 있고, TensorRT는 NVIDIA가 제공하는 inference SDK다. TensorRT는 network graph를 target GPU에 맞게 engine으로 build하고, layer fusion·precision 선택·memory planning 같은 inference optimization을 적용한다.

```text
Keras / TensorFlow model
  → ONNX export
  → ONNX graph 확인·optional simplification
  → TensorRT engine build
  → Jetson GPU inference
```

### ONNX의 역할

ONNX는 Open Neural Network Exchange의 약자로, framework와 runtime 사이에서 model graph를 전달하는 공용 format이다. TensorFlow/Keras와 PyTorch의 model 구조를 다른 runtime으로 넘길 때 중간 표현으로 사용한다.

모든 model이 어떤 version에서든 자동으로 변환되는 것은 아니다. 사용한 layer, ONNX opset, TensorRT가 지원하는 operator를 함께 확인해야 한다. 변환이 성공해도 Keras output과 TensorRT output을 같은 test input으로 비교해 correctness를 확인한다.

### ONNX simplification

framework model을 ONNX로 export하면 graph에 `Identity`, 불필요한 constant, 별도 `Pad` node처럼 inference 결과에 영향을 주지 않거나 합칠 수 있는 node가 남을 수 있다. ONNX simplifier는 이런 graph를 정리해 engine builder가 다루기 쉬운 형태로 만든다.

단순화는 항상 이득을 보장하지 않는다. model에 따라 graph 크기와 engine build 결과가 거의 같을 수 있고, 일부 operator 조합에서는 변환 문제가 생길 수 있다. 따라서 original ONNX와 simplified ONNX를 둘 다 test input으로 검증한 뒤, output·latency·engine build 성공 여부가 좋은 쪽을 선택한다.

### ONNX file 확인과 target conversion

이미 학습해 저장한 Keras model은 Google Drive 같은 저장 위치에서 다시 가져와 사용한다. 학습을 처음부터 반복할 필요 없이, best checkpoint를 load한 뒤 ONNX file로 export하는 흐름이다.

```text
saved `.keras` model
  → ONNX export
  → Netron으로 input·output·operator graph 확인
  → Jetson에서 TensorRT engine build
```

Netron은 ONNX file의 input shape, output tensor, layer graph를 눈으로 확인하는 viewer다. ONNX conversion이 끝났다는 사실만으로 target 실행까지 보장되지는 않는다. TensorRT가 지원하지 않는 operator, dynamic shape, input layout 문제를 engine build 전에 확인하는 용도로 사용한다.

TensorRT engine은 Jetson target에서 build한다. Colab에서 model을 학습하고 ONNX file을 만들 수는 있어도, Jetson Orin GPU와 설치된 TensorRT version에 맞춘 engine은 target board에서 만드는 것이 기준이다.

### `trtexec` engine build와 precision

`trtexec`는 ONNX file을 TensorRT engine으로 build하고, builder가 고른 kernel과 inference 성능을 확인하는 command-line tool이다. `trtexec`가 설치된 directory를 shell `PATH`에 넣으면 어느 working directory에서도 실행할 수 있다.

```sh
trtexec --onnx=<model.onnx> --saveEngine=<model_fp32.engine> --noTF32
trtexec --onnx=<model.onnx> --saveEngine=<model_fp16.engine> --fp16
```

TensorRT 10.3에서는 `--fp32` option이 없다. precision option을 생략하면 FP32 path가 기준이며, `--noTF32`는 TF32 Tensor Core 사용을 끈 비교용 FP32 build에 사용한다. `--fp16`은 FP16 tactic을 허용해 engine size와 latency를 줄이는 일반적인 Jetson inference 선택지다.

INT8은 더 작은 data type으로 연산·weight를 표현하는 quantization 경로다. input distribution을 대표하는 calibration과 output accuracy 검증이 필요하다. 이번 실습은 안정적으로 실행되는 FP32·FP16 engine 비교를 먼저 진행한다.

### TensorRT가 engine에서 하는 일

TensorRT는 ONNX graph를 그대로 한 layer씩 실행하지 않는다. 인접한 operation을 fuse하고, 불필요한 node를 제거하며, target GPU에 맞는 memory layout과 kernel tactic을 고른다.

```text
separate Pad → Convolution
  → compatible pattern을 하나의 optimized execution path로 정리
```

이 optimization은 CNN을 새 hardware로 구현하는 과정이 아니다. 이미 있는 Orin GPU에서 같은 model graph를 더 효율적으로 실행하도록 runtime engine을 만드는 software deployment 단계다.

### `trtexec` 성능 출력 읽기

engine build가 끝나면 `trtexec`는 throughput과 latency를 출력한다. host는 CPU, device는 GPU를 뜻한다.

| 항목 | 의미 |
| :--- | :--- |
| host-to-device latency | CPU memory의 input을 GPU execution path로 전달하는 시간 |
| GPU compute time | engine layer가 GPU에서 실제 연산하는 시간 |
| device-to-host latency | GPU output을 CPU 쪽으로 돌려주는 시간 |
| end-to-end latency | input 전달·GPU compute·output 반환을 포함한 한 inference 시간 |
| throughput | 단위 시간당 처리한 inference 수 |

### Jetson의 CPU·GPU memory

Jetson Orin Nano는 desktop GPU처럼 별도의 VRAM을 가진 구조가 아니다. CPU와 GPU가 system memory를 공유하는 unified-memory platform이다. TensorRT를 사용하면 GPU compute를 활용하지만, camera frame·preprocessing buffer·model activation이 같은 memory bandwidth를 사용하므로 input size, batch size, copy 횟수도 latency에 영향을 준다.

### TensorRT execution input·output

TensorRT engine을 실행하기 전에는 engine이 요구하는 input·output binding의 name, shape, data type을 확인한다. application이 camera image를 받았더라도, engine input shape에 맞춰 batch dimension을 포함한 tensor로 reshape하고, training 때와 같은 preprocessing을 적용해야 한다.

```text
camera image
  → resize·normalization
  → engine input shape로 reshape
  → TensorRT execution
  → output tensor 읽기
  → class score·label 결정
```

engine 내부가 `FP16`으로 optimized됐더라도 input·output binding이 항상 `FP16`인 것은 아니다. 수업 engine은 외부 binding이 `FP32`였으므로 application은 engine metadata가 요구하는 `float32` format을 유지한다. precision을 추측해 input type을 바꾸지 않고, build한 engine의 binding information을 기준으로 처리한다.

Jetson의 unified memory는 CPU와 GPU가 같은 physical memory를 공유할 수 있게 한다. mapped buffer 또는 zero-copy path를 실제로 설정한 경우에는 host-to-device copy를 줄일 수 있다. 모든 TensorRT 실행이 자동으로 zero-copy가 되는 것은 아니므로, allocator·buffer mapping·synchronization 설정과 latency를 함께 확인한다.

### TensorRT inference wrapper의 구성

TensorRT engine file은 바로 inference에 쓰는 Python object가 아니라 serialized binary다. runtime이 engine binary를 deserialize하고 execution context를 만든 뒤, context에 input·output tensor address를 지정해야 inference를 실행할 수 있다.

```text
`.engine` binary
  → TensorRT runtime으로 deserialize
  → execution context 생성
  → input·output tensor name·shape·dtype 조회
  → 필요한 host/device buffer 할당
  → tensor address를 context에 연결
  → CUDA stream에서 asynchronous inference
  → completion synchronization 후 output 반환
```

수업의 `TRTInferenceEngine` wrapper는 이 초기화 과정을 생성자에 묶고, 사용자는 engine file로 instance를 만든 뒤 `infer(input_tensor)`만 호출하도록 감싼 구조다. 같은 model을 frame마다 실행할 때 engine open·buffer allocation을 반복하지 않는 것이 핵심이다.

realtime camera application은 보통 `batch=1`로 frame 한 장씩 처리한다. input frame은 OpenCV의 `BGR` 순서로 들어오므로, model이 `RGB` data로 학습됐다면 `BGR → RGB`, resize, normalization, `float32` conversion, batch dimension 추가를 같은 순서로 적용한다. output probability vector에서는 `argmax`로 가장 큰 score의 class index를 찾고, class-name mapping으로 `rock`·`paper`·`scissors` label을 표시한다.

CUDA execution은 asynchronous로 enqueue할 수 있다. CPU는 GPU 작업이 끝났는지 synchronization 전까지 다른 일을 할 수 있지만, output을 읽기 전에는 완료를 보장해야 한다. 짧은 단일-frame 실습에서는 바로 synchronize해도 되지만, camera capture·preprocessing·display와 겹치게 구성하면 CPU idle 시간을 줄일 수 있다.

## Data Augmentation과 실제 환경 성능

RPS image classification model은 학습 data에 없던 조명 변화·회전·위치 이동에서 paper와 scissors를 혼동할 수 있다. training accuracy가 높아도 실제 camera input의 분포가 다르면 accuracy가 떨어진다.

data augmentation은 training input을 무작위로 변형해 model이 이런 변화에 덜 민감하게 만드는 방법이다. original data를 영구적으로 늘리는 작업이 아니라, epoch마다 generator 또는 augmentation layer가 변형된 training sample을 만들어 주는 방식으로 사용할 수 있다.

| augmentation | 재현하려는 실제 변화 |
| :--- | :--- |
| horizontal flip | 좌우 방향 변화 |
| rotation | 손·물체의 회전 |
| width·height shift | frame 안의 위치 이동 |
| brightness range | 조명 밝기 변화 |
| zoom range | camera와 대상 거리 변화 |

augmentation은 training data에 적용하고 validation·test·실제 inference input에는 적용하지 않는다. 변형을 넣은 뒤에는 같은 validation/test 기준으로 기존 model과 재학습 model을 비교한다. TensorRT가 inference latency를 줄여도 training data에 없던 모습 자체를 정확히 분류해 주지는 않으므로, accuracy 문제는 data coverage와 model 학습 단계에서 먼저 해결한다.

## Object Detection data format과 metric

classification은 image 한 장에 어떤 class가 있는지를 맞추는 문제다. object detection은 class와 함께 대상 위치의 bounding box까지 맞춘다. 따라서 detection dataset에는 image file 외에 object의 class와 box 좌표를 저장하는 annotation이 필요하다.

| format | annotation 형태 | 좌표 기준 |
| :--- | :--- | :--- |
| YOLO | image마다 text file 한 개, `class_id x_center y_center width height` | image width·height로 나눈 normalized 값 |
| COCO | dataset 전체 JSON의 `images`·`annotations`·`categories` | 보통 pixel 기준 `[x, y, width, height]` |

YOLO의 `x_center`, `y_center`, `width`, `height`는 모두 `0`부터 `1` 사이의 normalized ratio다. 예를 들어 box의 pixel 좌표가 `(x, y, w, h)`이고 image size가 `(W, H)`라면 다음처럼 바꾼다.

```text
x_center = (x + w / 2) / W
y_center = (y + h / 2) / H
width    = w / W
height   = h / H
```

object detection은 class만 맞아도 충분하지 않다. predicted box와 ground-truth box의 겹침 정도를 IoU로 계산하고, class confidence·IoU threshold를 함께 사용해 AP와 mAP를 평가한다. 따라서 classification accuracy를 detection model의 평가 지표로 그대로 사용하지 않는다.

### Confidence·NMS·Precision-Recall curve

한 object 주변에 여러 predicted box가 생길 수 있다. confidence가 높은 box부터 남기고, 같은 class의 box가 IoU threshold 이상으로 겹치면 낮은 confidence box를 제거하는 post-processing이 NMS(Non-Maximum Suppression)다.

confidence threshold를 낮추면 더 많은 prediction을 남기므로 recall은 보통 유지되거나 증가한다. 반면 false positive도 함께 늘 수 있어 precision은 내려갈 수 있다. confidence 순서대로 prediction을 하나씩 추가하며 precision-recall curve를 만들고, 그 curve 아래 면적이 AP(Average Precision)다. class별 AP의 평균이 mAP다.

```text
prediction을 confidence 내림차순 정렬
  → ground truth와 IoU 비교
  → 조건을 만족하면 TP, 아니면 FP
  → 각 순위의 precision·recall 계산
  → precision-recall curve의 AP 계산
```

IoU threshold는 'box 위치를 맞췄다'고 판정하는 기준이다. `mAP@0.5`는 IoU `0.5` 기준의 AP 평균이고, COCO style mAP는 여러 IoU threshold에서의 AP를 평균 낸다. 따라서 결과를 비교할 때는 mAP 값뿐 아니라 사용한 IoU threshold와 dataset을 함께 확인한다.

### R-CNN에서 Fast R-CNN으로

R-CNN은 selective search가 만든 약 2,000개의 region proposal을 각각 CNN에 넣어 feature를 추출했다. proposal 수만큼 CNN을 반복 실행하므로 연산이 매우 크다.

Fast R-CNN은 image 전체를 CNN backbone에 한 번 넣어 feature map을 만든다. selective search로 proposal을 얻는 단계는 남아 있지만, 각 proposal은 original image가 아니라 공유 feature map에서 잘라 쓴다.

```text
image
  ├─ CNN backbone 한 번 실행 → shared feature map
  └─ selective search → region proposals
       → RoI Pooling으로 proposal feature를 같은 shape로 변환
       → fully connected head
       → class score + bounding-box regression
```

RoI Pooling은 크기가 제각각인 proposal 영역을 고정된 feature size로 바꿔 detection head가 batch 형태로 처리하게 한다. Fast R-CNN은 CNN 중복 실행을 제거해 R-CNN보다 빨라졌지만, selective search가 여전히 병목으로 남는다. 다음 단계인 Faster R-CNN은 proposal 생성 자체를 RPN으로 network 안에 넣어 이 병목을 줄인다.

## Camera RPS application과 preprocessing

MobileNetV2 RPS example은 OpenCV가 camera frame을 받고, model input에 맞게 image를 정리한 뒤 TensorRT 또는 framework runtime으로 classification하는 application이다.

```text
camera frame
  → hand area crop
  → aspect ratio 유지 resize
  → white background canvas 중앙 배치
  → model input shape로 변환
  → rock / paper / scissors class probability
```

학습 image가 흰 배경 중앙의 손 모양처럼 일정한 구성을 가졌다면, 실제 camera frame도 같은 분포에 가깝게 만들어야 한다. 배경이 복잡하거나 손의 위치·크기가 크게 달라지면 model이 손 모양보다 배경·위치 차이에 반응해 accuracy가 떨어질 수 있다. 이는 model 자체의 오류보다 training data와 deployment input의 distribution 차이에서 생기는 문제다.

이미지의 가로세로 비율을 무시하고 강제로 resize하면 손 모양이 찌그러질 수 있다. 짧은 쪽을 맞춰 resize한 뒤, 남는 영역을 흰 canvas로 채우고 slicing으로 중앙에 배치하면 학습 data 형식과 input size를 함께 맞출 수 있다.

Transfer learning에서는 모든 model을 처음부터 학습하지 않는다. MobileNetV2처럼 이미 일반 image feature를 학습한 backbone을 가져오고, 현재 RPS class에 맞는 head를 학습해 재사용한다. 이 선택은 작은 수업 data에서 빠르게 application baseline을 만드는 데 적합하다.

## 계층 연결

```text
application
  └─ camera frame을 받고 classification 결과를 robot·display logic에 사용

AI runtime / SDK
  └─ LiteRT interpreter 또는 TensorRT engine으로 inference 실행

OS·driver
  └─ Linux camera·display·GPU driver와 memory buffer를 제공

hardware platform
  └─ Jetson Orin Nano의 CPU·GPU·shared memory·camera/display I/O
```

이날의 핵심은 model을 GPU 회로로 새로 설계하는 작업이 아니다. 이미 있는 Jetson GPU hardware 위에서, 학습한 model graph를 TensorRT가 실행하기 좋은 engine으로 변환하고 application이 그 engine을 호출하는 software stack을 구성하는 작업이다. FPGA에서 CNN/NPU custom IP를 RTL로 구현하는 학습은 같은 inference 연산을 별도 hardware architecture로 설계하는 축에 놓인다.

## 실습 확인 항목

- train·validation·test data가 서로 섞이지 않게 분할됐는지 확인
- MobileNetV2 backbone과 새 classification head의 학습 범위를 구분
- preprocessing이 training과 inference에서 같은 방식으로 적용되는지 확인
- best checkpoint가 durable storage에 저장됐는지 확인
- Keras model과 ONNX/TensorRT 결과를 같은 input으로 비교
- TensorRT engine build 시 unsupported operator와 shape error 확인
- Jetson에서 CPU-only inference와 TensorRT GPU inference의 latency를 비교

## Jetson 원격 실습 점검

| 증상 | 확인 순서 | 처리 기준 |
| :--- | :--- | :--- |
| `trtexec`를 찾지 못함 | `command -v trtexec` | TensorRT `bin` directory를 shell `PATH`에 추가 |
| ONNX file open 실패 | `pwd`, `find . -iname '*.onnx'` | 실제 ONNX file path를 `--onnx`에 전달 |
| X11 display 인증 실패 | Mac XQuartz 실행, 새 `ssh -Y` session에서 `xclock` 확인 | 기존 session의 수동 `DISPLAY` 설정을 쓰지 않고 SSH가 만든 display·cookie 사용 |
| `VideoCapture(0)` 실패 | `ls -l /dev/video*`, camera 종류 확인 | USB camera의 V4L2 device 번호 또는 CSI camera의 GStreamer capture path 사용 |
| `np.fp16` attribute error | dtype 이름 확인 | NumPy의 `np.float16` 사용 |

RPS example은 camera input·OpenCV preprocessing·model inference·GUI display가 한 process 안에 연결된다. 따라서 model 문제로 단정하기 전에 camera device, X11 display, input tensor dtype, model file path를 각각 확인한다.
