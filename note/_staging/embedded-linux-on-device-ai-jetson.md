# Embedded Linux 기반 Jetson On-Device AI 구현 대기 메모

## 수업 범위

이 대기 메모는 `Jetson Orin Nano` 보드에서 on-device AI application을 실행하는 application-side 실습을 정리한다. 이전 `Deep Learning` 노트가 model 구조와 학습 배경을 다룬다면, 이 노트는 webcam frame 수집, OpenCV 전처리, TensorRT 변환, object detection, local LLM, Ollama API를 Jetson 환경에서 연결하는 부분을 다룬다.

| 구분 | 내용 |
| :--- | :--- |
| 1과 | Webcam을 이용한 CNN 활용 |
| 2과 | TensorRT를 이용한 RPS Classification |
| 3과 | RPS Classification 개선 |
| 4과 | Object Detection의 주요 개념 |
| 5과 | Object Detection 구현 |
| 6과 | Jetson을 이용한 local LLM 환경 구축 |
| 7과 | Ollama API 활용 |

전체 pipeline은 다음 단계로 나뉜다.

```text
Webcam input
    ↓
OpenCV preprocessing
    ↓
CNN classification 또는 object detection
    ↓
ONNX export
    ↓
TensorRT engine 생성
    ↓
Jetson GPU inference
    ↓
local LLM / Ollama API application
```

## Webcam을 이용한 CNN 활용

### Colab webcam stream 구조

Colab 환경은 browser에서 실행되므로 local PC webcam을 바로 Python에서 여는 구조가 아니다. JavaScript로 webcam stream을 얻고, Python 쪽에서 frame을 받아 OpenCV 처리를 수행한다.

```text
Local PC webcam
    ↓
Browser JavaScript
    ↓
Colab output cell
    ↓
Python frame decode
    ↓
OpenCV image processing
    ↓
bounding box overlay
```

Colab 예제의 핵심 함수는 다음 두 가지다.

| 함수 | 역할 |
| :--- | :--- |
| `video_stream()` | JavaScript webcam stream 초기화, output cell에 video 표시 |
| `video_frame(label, bbox)` | 현재 frame을 가져오고 이전 bounding box overlay 반영 |

흐름은 다음처럼 반복된다.

```python
video_stream()
label_html = "Capturing..."
bbox = ""
start_time = time.time()

while True:
    js_reply = video_frame(label_html, bbox)
    if not js_reply:
        break

    cur_time = time.time()
    fps = 1 / (cur_time - start_time)
    start_time = cur_time

    bbox = processImage(js_reply, fps)
```

### Face Detection 처리

OpenCV의 Haar cascade를 사용해 얼굴 영역을 검출한다. JavaScript object로 들어온 frame을 OpenCV image로 바꾼 뒤, gray image로 변환하고 `detectMultiScale()`로 얼굴 좌표를 얻는 방식이다.

```text
JavaScript frame
    ↓
image bytes decode
    ↓
BGR image
    ↓
gray image
    ↓
face_cascade.detectMultiScale()
    ↓
rectangle + FPS overlay
    ↓
base64 bbox return
```

주요 처리 코드는 다음 형태로 이해하면 된다.

```python
def processImage(js_reply, fps):
    img = js_to_image(js_reply["img"])
    bbox_array = np.zeros([240, 320, 4], dtype=np.uint8)

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray)

    for (x, y, w, h) in faces:
        cv2.rectangle(bbox_array, (x, y), (x + w, y + h), (255, 0, 0), 2)

    cv2.putText(
        bbox_array,
        f"FPS: {fps:.1f}",
        (20, 50),
        cv2.FONT_HERSHEY_PLAIN,
        2,
        (255, 255, 255),
        2,
    )

    bbox_array[:, :, 3] = (bbox_array.max(axis=2) > 0) * 255
    return bbox_to_bytes(bbox_array)
```

Colab stream 방식은 browser와 notebook 사이를 거치므로 FPS가 낮아질 수 있다. 보드에서 직접 webcam을 연결하면 이 과정을 단순화할 수 있음.

### Jetson 보드 webcam 사용

Jetson에서는 OpenCV의 `VideoCapture`로 camera를 직접 열 수 있다.

```python
cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 320)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 240)

while True:
    ret, frame = cap.read()
    if not ret:
        break

    result = processImage(frame)
    cv2.imshow("camera", result)

    if cv2.waitKey(1) == 27:
        break

cap.release()
cv2.destroyAllWindows()
```

처리 흐름은 다음과 같음.

```text
USB webcam
    ↓
cv2.VideoCapture(0)
    ↓
frame read
    ↓
processImage(frame)
    ↓
cv2.imshow()
```

## TensorRT를 이용한 RPS Classification

### RPS 분류 목표

`RPS`는 Rock, Paper, Scissors 분류 문제다. webcam frame에서 손 모양을 분류하기 위해 `MobileNetV2`를 기반 model로 사용하고, RPS dataset으로 fine-tuning한 뒤 Jetson에서 TensorRT engine으로 실행한다.

```text
RPS image dataset
    ↓
MobileNetV2 transfer learning
    ↓
Keras model 저장
    ↓
ONNX 변환
    ↓
TensorRT engine 생성
    ↓
Jetson webcam inference
```

### MobileNetV2 Fine-Tuning

`MobileNetV2`는 ImageNet으로 pretrained된 model을 가져오고, RPS class에 맞는 classification head를 붙인다.

```python
base_model = tf.keras.applications.MobileNetV2(
    input_shape=(224, 224, 3),
    include_top=False,
    weights="imagenet"
)

model = tf.keras.models.Sequential([
    tf.keras.layers.Input(shape=(224, 224, 3)),
    tf.keras.layers.Lambda(tf.keras.applications.mobilenet_v2.preprocess_input),
    base_model,
    tf.keras.layers.GlobalAveragePooling2D(),
    tf.keras.layers.Dense(128, activation="relu"),
    tf.keras.layers.Dropout(0.2),
    tf.keras.layers.Dense(3, activation="softmax")
])
```

| 구성 | 의미 |
| :--- | :--- |
| `include_top=False` | ImageNet용 최종 classification layer 제외 |
| `weights="imagenet"` | pretrained weight 사용 |
| `preprocess_input` | MobileNetV2 입력 정규화 |
| `GlobalAveragePooling2D` | feature map을 channel별 대표값으로 축약 |
| `Dense(3, softmax)` | Rock/Paper/Scissors class 확률 출력 |

모델 저장은 Keras format으로 진행한다.

```python
model.save("RPS_MobileNetV2.keras")
```

### ONNX와 TensorRT 변환

Keras model을 Jetson에서 빠르게 실행하려면 TensorRT engine으로 바꾸는 절차가 필요하다. 중간 교환 format으로 `ONNX`를 사용한다.

| 단계 | 산출물 |
| :--- | :--- |
| Keras 저장 | `RPS_MobileNetV2.keras` |
| ONNX 변환 | `RPS_MobileNetV2.onnx` |
| ONNX graph 단순화 | `RPS_MobileNetV2.sim.onnx` |
| TensorRT build | `RPS_MobileNetV2.engine` |

변환 흐름은 다음과 같음.

```text
TensorFlow/Keras model
    ↓
tf2onnx
    ↓
ONNX model
    ↓
onnxsim
    ↓
simplified ONNX
    ↓
trtexec on Jetson
    ↓
TensorRT engine
```

`ONNX`는 서로 다른 framework 사이에서 model을 교환하기 위한 format이다. TensorRT 변환 시 `opset`을 기준으로 연산자를 해석하고, Jetson GPU에서 실행 가능한 kernel로 최적화함.

Jetson에서 TensorRT engine을 만들 때는 보통 다음 명령 흐름을 사용한다.

```sh
trtexec \
  --onnx=RPS_MobileNetV2.sim.onnx \
  --saveEngine=RPS_MobileNetV2.engine
```

TensorRT engine은 target GPU와 TensorRT version에 의존성이 크므로, 가능하면 실제 실행할 Jetson에서 생성하는 편이 안정적이다.

### TensorRT Inference 구조

Python에서 TensorRT engine을 사용할 때는 logger, runtime, engine, execution context, input/output buffer, CUDA stream이 필요하다.

```text
engine file
    ↓
TensorRT Runtime deserialize
    ↓
ExecutionContext
    ↓
input host/device buffer
    ↓
execute_async_v2()
    ↓
output host/device buffer
```

RPS 활용 코드는 webcam frame을 `224x224`로 resize하고, model input에 맞춰 정규화한 뒤 TensorRT engine에 넣는다.

```text
frame
    ↓
crop/resize
    ↓
preprocess
    ↓
TensorRT inference
    ↓
softmax output
    ↓
argmax class
```

## RPS Classification 개선

### 손 영역 분리

단순히 전체 webcam frame을 model에 넣으면 배경, 조명, 손 위치의 영향이 커진다. 이를 줄이기 위해 손 영역만 검출해 classification에 넣는다.

```text
webcam frame
    ↓
hand detector
    ↓
hand bounding box crop
    ↓
background 영향 감소
    ↓
RPS classification
```

`cvzone.HandTrackingModule`의 `HandDetector`를 사용하면 손 위치를 찾고, 해당 영역만 잘라 model 입력으로 사용할 수 있다.

```python
from cvzone.HandTrackingModule import HandDetector

detector = HandDetector(maxHands=1)

def processImage(frame):
    hands, img = detector.findHands(frame)
    if hands:
        x, y, w, h = hands[0]["bbox"]
        hand = frame[y:y + h, x:x + w]
        # resize, preprocessing, classification
```

손만 따로 떼고 배경을 단색에 가깝게 만들면 다음 문제가 줄어든다.

| 문제 | 개선 방향 |
| :--- | :--- |
| 배경이 class 판단에 섞임 | hand crop 적용 |
| 손 위치/크기 변화 큼 | bounding box 기준 resize |
| 조명과 색 차이 | augmentation 및 preprocessing |

### Data Augmentation

Data Augmentation은 training data를 회전, 확대, 이동, 좌우 반전 등으로 변형해 model이 다양한 입력 상황에 적응하도록 돕는 방법이다.

```text
original image
    ├─ rotation
    ├─ width/height shift
    ├─ zoom
    ├─ horizontal flip
    └─ brightness variation
```

Keras에서는 `ImageDataGenerator`나 preprocessing layer를 사용해 augmentation을 적용할 수 있다.

```python
datagen = tf.keras.preprocessing.image.ImageDataGenerator(
    rotation_range=20,
    width_shift_range=0.1,
    height_shift_range=0.1,
    zoom_range=0.1,
    horizontal_flip=True
)
```

augmentation이 적용된 model도 최종적으로는 같은 흐름으로 `Keras → ONNX → TensorRT engine`으로 변환하고, Jetson에서 webcam inference에 사용한다.

## Object Detection의 주요 개념

### Classification, Localization, Detection, Segmentation

Object Detection은 한 장면 안에 있는 여러 object에 대해 class와 위치를 함께 찾는 작업이다.

| 작업 | 출력 |
| :--- | :--- |
| Classification | image 전체의 class |
| Localization | 단일 object의 위치와 class |
| Object Detection | 여러 object의 bounding box와 class |
| Instance Segmentation | object별 pixel mask |

```text
Classification
  image -> cat

Localization
  image -> cat + one box

Object Detection
  image -> cat box + dog box + duck box

Instance Segmentation
  image -> object masks
```

### Dataset과 Annotation

Object detection dataset은 image와 bounding box annotation을 함께 가진다.

| Dataset | 특징 |
| :--- | :--- |
| PASCAL VOC | 20개 class, XML annotation |
| COCO | 80개 class, 대규모 object detection/segmentation dataset |
| YOLO format | class id와 normalized bbox 좌표를 text로 저장 |

PASCAL VOC XML 구조는 다음처럼 `filename`, `object`, `name`, bounding box 정보를 포함한다.

```xml
<annotation>
  <filename>2012_000003.jpg</filename>
  <object>
    <name>person</name>
    <bndbox>
      <xmin>...</xmin>
      <ymin>...</ymin>
      <xmax>...</xmax>
      <ymax>...</ymax>
    </bndbox>
  </object>
</annotation>
```

YOLO format은 한 줄에 `class x_center y_center width height`를 저장한다.

```text
0 0.512 0.438 0.241 0.366
```

### IOU, AP, mAP

`IOU`는 predicted box와 ground-truth box가 얼마나 겹치는지 나타내는 지표다.

```text
IOU = intersection area / union area
```

```text
ground truth box:  A
predicted box:     B

intersection = A와 B가 겹친 영역
union        = A 또는 B에 속한 전체 영역
```

Object detection에서는 confidence threshold와 IOU threshold에 따라 true positive, false positive, false negative가 달라진다.

| 구분 | 계산/정의 | 의미 |
| :--- | :--- | :--- |
| TP | positive 예측, 실제 positive | object를 맞게 검출 |
| FP | positive 예측, 실제 negative | 없는 object를 검출하거나 잘못된 box/class |
| FN | negative 예측, 실제 positive | 실제 object를 놓침 |
| TN | negative 예측, 실제 negative | detection 평가에서는 경우가 너무 많아 보통 직접 사용하지 않음 |
| Precision | `TP / (TP + FP)` | 검출 결과 중 정답 비율 |
| Recall | `TP / (TP + FN)` | 실제 object 중 찾아낸 비율 |
| AP | class 하나의 precision-recall curve 면적 또는 평균 precision | class별 detection 품질 |
| mAP | 여러 class AP의 평균 | 전체 detector 품질 |

예를 들어 실제 dog가 `3`마리이고 detector가 dog `4`개를 예측했지만 그중 `2`개만 정답이면 다음처럼 계산한다.

```text
Precision = 2 / 4
Recall    = 2 / 3
```

Precision은 예측 결과의 정확도를 보고, Recall은 실제 object를 얼마나 놓치지 않았는지 본다. 두 값은 confidence threshold를 조절할 때 반비례 경향이 생기기 쉽기 때문에, 한 값만으로 detector를 평가하면 부족하다.

AP 계산은 confidence score와 누적 TP/FP를 기준으로 한다.

```text
1. detection 결과를 confidence score 내림차순으로 정렬
2. 각 detection을 IOU threshold와 class 기준으로 TP 또는 FP로 판정
3. 위에서부터 누적 TP, 누적 FP 계산
4. 각 지점의 Precision, Recall 계산
5. Precision-Recall curve 구성
6. curve의 면적 또는 보간된 precision 평균으로 AP 계산
7. class별 AP를 평균내 mAP 계산
```

| AP 계산 방식 | 계산 기준 | 특징 |
| :--- | :--- | :--- |
| 11-point interpolation | Recall `0.0`, `0.1`, ..., `1.0` 지점의 precision 평균 | 각 recall 지점 뒤쪽의 최대 precision 사용 |
| all-point interpolation | 실제 detection으로 생긴 모든 recall 지점 사용 | 더 촘촘한 precision-recall curve 반영 |

수업 자료의 예시처럼 detection을 confidence 순서로 누적하면 Recall은 ground-truth 총 개수를 분모로 하므로 뒤로 갈수록 증가하고, Precision은 FP가 섞이는 위치에 따라 오르내린다. 따라서 AP는 단일 threshold의 precision/recall이 아니라 threshold 변화 전체에서의 detector 동작을 요약한 값으로 보는 편이 맞다.

### R-CNN 계열

R-CNN은 deep learning을 object detection에 적용한 초기 구조다. region proposal을 만든 뒤 각 region을 CNN에 넣어 feature를 추출하고, class와 box를 예측한다.

```text
R-CNN
input image
    ↓
region proposals
    ↓
region crop/resize
    ↓
CNN feature extraction
    ↓
SVM classification
    ↓
bbox regression
```

Fast R-CNN은 image 전체를 CNN에 먼저 통과시키고, feature map에서 region별 feature를 뽑아 속도를 개선한다. Faster R-CNN은 selective search 병목을 줄이기 위해 RPN을 추가한다.

```text
Faster R-CNN
image
  ↓
CNN backbone
  ↓
RPN
  ↓
region proposals
  ↓
classification + bbox regression
```

| Model | 개선점 |
| :--- | :--- |
| R-CNN | region별 CNN 적용 |
| Fast R-CNN | feature map 공유 |
| Faster R-CNN | RPN으로 proposal 생성 |
| SSD | 여러 scale feature map에서 dense detection |
| YOLO | image를 한 번에 처리하는 single-stage detector |

### NMS와 YOLO detection 구조

Object detector는 하나의 object 주변에 여러 bounding box 후보를 낼 수 있다. 이때 confidence score와 IOU를 기준으로 중복 box를 제거하는 후처리가 `NMS`다.

```text
raw predicted boxes
    ↓
confidence threshold로 낮은 score 제거
    ↓
confidence score 내림차순 정렬
    ↓
score가 높은 box부터 선택
    ↓
선택된 box와 IOU가 threshold 이상인 나머지 box 제거
    ↓
final detection boxes
```

| 단계 | 기준 | 목적 |
| :--- | :--- | :--- |
| Score filtering | confidence score threshold | 너무 낮은 확률의 box 제거 |
| Sorting | confidence score 내림차순 | 가장 믿을 만한 box 우선 처리 |
| IOU suppression | IOU threshold | 같은 object를 가리키는 중복 box 제거 |
| Final output | class, score, bbox | 화면 표시와 후속 처리 입력 |

YOLO는 `You Only Look Once`의 약자처럼 image를 한 번에 처리하는 single-stage detector다. grid cell별로 bounding box와 class score를 예측하고, 이후 NMS를 거쳐 최종 검출 결과를 만든다.

| YOLO 출력 요소 | 의미 |
| :--- | :--- |
| `x`, `y` | bounding box 중심 좌표 |
| `w`, `h` | bounding box 너비와 높이 |
| `confidence` | box가 object를 포함할 가능성과 box 품질 반영 |
| class probability | 각 class일 가능성 |

초기 YOLO 계열 설명에서는 confidence를 다음처럼 해석한다.

```text
confidence = Pr(object) * IOU(pred, truth)
```

object가 없으면 `Pr(object)`가 낮아지고, object가 있어도 predicted box와 ground truth가 잘 맞지 않으면 IOU가 낮아진다. 그래서 confidence는 단순한 class probability가 아니라 box 존재 여부와 위치 품질을 함께 반영하는 값으로 이해해야 한다.

## Object Detection 구현

### 도구와 구현 방향

Object detection 구현에는 여러 도구를 사용할 수 있다.

| 도구 | 특징 |
| :--- | :--- |
| TensorFlow Object Detection API | TensorFlow 기반 detection pipeline |
| Ultralytics YOLO | YOLO 학습, 추론, export API 제공 |
| TensorRT | Jetson GPU inference 최적화 |

Jetson 실습에서는 `Ultralytics YOLO`를 사용해 RPS dataset으로 model을 학습하고, ONNX/TensorRT engine으로 변환해 webcam inference에 적용한다.

```text
RPS dataset
    ↓
labeling
    ↓
YOLO training
    ↓
best.pt
    ↓
ONNX export
    ↓
TensorRT engine
    ↓
webcam detection
```

### Dataset 제작

Object detection dataset은 image와 label file의 pairing이 중요하다.

```text
dataset/
  images/
    train/
    val/
  labels/
    train/
    val/
  data.yaml
```

`data.yaml`에는 dataset 경로와 class 이름을 정의한다.

```yaml
path: ./dataset
train: images/train
val: images/val
names:
  0: rock
  1: paper
  2: scissors
```

label file은 image와 같은 stem을 가지며, 한 object당 한 줄을 사용한다.

```text
class_id x_center y_center width height
```

### YOLO 학습과 Jetson 활용

Ultralytics YOLO 학습은 pretrained checkpoint를 불러온 뒤 `data.yaml`에 정의된 dataset과 class label을 기준으로 fine-tuning하는 방식이다.

```python
from ultralytics import YOLO

model = YOLO("yolo11n.pt")
model.train(
    data="data.yaml",
    epochs=100,
    imgsz=640,
    name="rps_yolo11n"
)
```

학습된 model을 Jetson에서 사용하려면 ONNX 또는 TensorRT engine으로 export한다.

```python
model = YOLO("runs/detect/rps_yolo11n/weights/best.pt")
model.export(format="onnx")
model.export(format="engine")
```

ONNX는 framework 사이에서 model graph를 옮기기 위한 중간 표현이고, TensorRT engine은 특정 GPU와 precision 설정에 맞춰 최적화된 실행 계획에 가깝다. Jetson에서는 같은 model이라도 PyTorch 원본 추론보다 TensorRT engine 추론이 더 낮은 latency를 낼 수 있지만, engine은 생성한 장치와 TensorRT 버전에 종속될 수 있다.

TensorRT engine을 Jetson에서 직접 생성하는 이유는 Jetson의 JetPack, CUDA, TensorRT version, GPU architecture에 맞게 최적화되기 때문이다.

webcam 추론 구조는 다음과 같음.

```python
from ultralytics import YOLO
import cv2

model = YOLO("best.engine")
cap = cv2.VideoCapture(0)

while True:
    ret, frame = cap.read()
    if not ret:
        break

    results = model(frame)
    annotated = results[0].plot()
    cv2.imshow("YOLO", annotated)

    if cv2.waitKey(1) == 27:
        break
```

class name, confidence, bounding box 좌표를 출력하려면 `results[0]` 내부의 box 정보를 읽어 처리한다.

```python
for box in results[0].boxes:
    cls = int(box.cls[0])
    conf = float(box.conf[0])
    xyxy = box.xyxy[0].tolist()
```

## Jetson을 이용한 local LLM 환경 구축

### Copilot 활용 실습

Jetson에서 camera capture 같은 간단한 Python 코드를 작성할 때 Copilot Chat을 코드 생성 보조 도구로 사용할 수 있다.

실습 prompt 예시는 다음과 같음.

```text
기본 비디오 입력으로부터 프레임 한 장을 기본 세팅으로 저장하는 간단한 캡처 코드를 부탁해
```

결과로 생성된 코드는 `cv2.VideoCapture(0)`, `cap.read()`, `cv2.imwrite()` 같은 흐름을 가질 수 있다.

```python
import cv2

cap = cv2.VideoCapture(0)
ret, frame = cap.read()

if ret:
    cv2.imwrite("capture.jpg", frame)

cap.release()
```

chat agent나 model을 바꾸면 생성 코드 스타일, error handling, 설명량이 달라질 수 있으므로 결과 코드는 직접 실행해 확인해야 함.

### Jetson 환경과 container

Jetson은 `L4T`, `JetPack`, CUDA, cuDNN, TensorRT version 조합에 민감하다. 일반 x86 Linux와 달리 ARM64와 NVIDIA Jetson 전용 driver/runtime을 함께 고려해야 함.

| 요소 | 의미 |
| :--- | :--- |
| `L4T` | Linux for Tegra, Jetson용 Linux 기반 |
| `JetPack` | CUDA, cuDNN, TensorRT, multimedia stack 포함 SDK |
| `jetson-containers` | Jetson에 맞춘 container image와 실행 helper |
| CUDA runtime | GPU 연산 실행 |
| TensorRT | inference 최적화 runtime |

환경을 안정적으로 유지하려면 system Python에 직접 여러 package를 섞는 것보다 project별 virtual environment 또는 container를 쓰는 편이 좋다.

```text
system environment
    ↓
project venv 또는 container
    ↓
필요 package 설치
    ↓
project별 dependency 격리
```

## Ollama API 활용

### Ollama 설치와 model 실행

Ollama는 local machine에서 LLM을 내려받아 실행할 수 있는 runtime이다. Jetson에서는 지원 model 크기와 memory, GPU 활용 가능 여부를 함께 봐야 한다.

기본 명령 흐름은 다음과 같음.

```sh
curl -fsSL https://ollama.com/install.sh | sh
ollama pull gemma3:4b
ollama list
ollama run gemma3:4b
```

| 명령 | 의미 |
| :--- | :--- |
| `ollama pull <model>` | model 다운로드 |
| `ollama list` | local model 목록 확인 |
| `ollama run <model>` | terminal에서 model 실행 |
| `ollama show <model>` | model 세부 정보 확인 |
| `ollama delete <model>` | local model 삭제 |

Ollama service는 기본적으로 `http://127.0.0.1:11434`를 사용한다.

### Open WebUI 연결

Open WebUI는 browser에서 ChatGPT와 유사한 UI로 local Ollama model을 사용할 수 있게 해준다.

Docker 실행 예시는 다음과 같이 이해할 수 있다.

```sh
docker run -d \
  --network=host \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  -v open-webui:/app/backend/data \
  --name open-webui \
  ghcr.io/open-webui/open-webui:main
```

| 옵션 | 의미 |
| :--- | :--- |
| `--network=host` | container가 host network 사용 |
| `OLLAMA_BASE_URL` | Open WebUI가 연결할 Ollama backend 주소 |
| `-v open-webui:/app/backend/data` | WebUI data 보존 |
| `:11434` | Ollama service port |

### Python Ollama API

Python에서는 `ollama` module을 설치해 API를 사용할 수 있다.

```sh
pip install ollama
```

대표 API는 다음과 같음.

| API | 용도 |
| :--- | :--- |
| `ollama.chat()` | 대화형 message 기반 생성 |
| `ollama.generate()` | prompt 기반 text 생성 |
| `ollama.embeddings()` | embedding 생성 |
| `ollama.list()` | model 목록 조회 |
| `ollama.show()` | model 상세 정보 |
| `ollama.pull()` | model 다운로드 |
| `ollama.delete()` | model 삭제 |

`generate()` 예시는 다음과 같다.

```python
import ollama

response = ollama.generate(
    model="gemma3:4b",
    prompt="왜 하늘은 파란색이야?"
)

print(response["response"])
print(response.model_dump())
```

response에는 생성된 text뿐 아니라 model 이름, 생성 시각, 종료 이유, prompt token 수, evaluation token 수, duration 같은 실행 정보가 포함된다.

streaming chat은 token이 생성되는 대로 받아 출력하는 방식이다.

```python
import json
import ollama

stream = ollama.chat(
    model="gemma3:4b",
    messages=[
        {
            "role": "user",
            "content": "인공지능의 미래에 대해 에세이를 써줘."
        }
    ],
    stream=True,
)

last_chunk = None
for chunk in stream:
    print(chunk["message"]["content"], end="", flush=True)
    last_chunk = chunk
else:
    print("\n[Stream Ended]")

print(json.dumps(last_chunk.model_dump(), indent=4, ensure_ascii=False))
```

stream 중간 chunk는 `done=False` 상태이고, 마지막 chunk에는 `done=True`, `done_reason`, `total_duration`, `eval_count`, `eval_duration` 같은 평가 정보가 들어간다.

## 정리

이번 범위는 model을 훈련하는 것에서 끝나지 않고 Jetson에서 실제 입력 장치와 runtime을 연결하는 과정까지 다룬다.

```text
webcam frame
    ↓
OpenCV preprocessing
    ↓
classification 또는 detection model
    ↓
ONNX / TensorRT 변환
    ↓
Jetson GPU inference
    ↓
local LLM / Ollama API application
```

핵심은 세 가지다.

| 축 | 기억할 점 |
| :--- | :--- |
| Vision input | webcam frame을 OpenCV로 읽고 전처리 |
| Inference optimization | ONNX와 TensorRT로 Jetson 실행 최적화 |
| Local AI application | Ollama/Open WebUI/API로 local LLM 활용 |

On-device AI에서는 정확도뿐 아니라 FPS, model size, TensorRT 호환성, JetPack version, memory 사용량, camera 입력 지연까지 함께 확인해야 한다.
