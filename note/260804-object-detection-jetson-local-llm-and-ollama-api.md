# 26-08-04 - Object Detection·Jetson local LLM·Ollama API

관련 노트:

- [26-08-03 - ONNX·TensorRT 배포와 RPS camera preprocessing](260803-on-device-ai-tensorrt-deployment-and-rps-camera-preprocessing.md)
- [26-07-30 - Jetson 원격 개발 환경과 OpenCV 얼굴 검출 스트리밍](260730-jetson-remote-development-and-opencv-face-detection.md)
- [Machine Learning·Deep Learning 전체 지도](machine-learning-deep-learning-course-map.md)

> 수업일: `2026-08-04`
>
> 현재 상태: RPS classification model을 camera input에서 안정적으로 실행하기 위한 hand localization·preprocessing을 다뤘고, multiple object를 다루는 object detection의 annotation·metric·R-CNN·YOLO 구조, Jetson local LLM의 실행 환경을 연결했다.

## 수업 범위

| 구분 | 내용 |
| :--- | :--- |
| classification 복습 | MobileNetV2 transfer learning, train·test split, checkpoint |
| on-device deployment | LiteRT, ONNX, TensorRT engine, Jetson GPU inference |
| RPS camera input | hand bounding box, crop, square canvas, color·shape 변환 |
| augmentation | rotation·shift·brightness 변화에 대한 training data 확장 |
| object detection 평가 | IoU, TP·FP·FN, precision·recall, AP·mAP, NMS |
| detector 발전 | R-CNN, Fast R-CNN, shared feature map, RoI Pooling |
| YOLO 활용 | Ultralytics API, class name mapping, remote display |
| local LLM | prompt·context, Docker·swap, Ollama model·Python API |

## 제품 전체 흐름

```text
camera frame
  → hand detector로 손 위치 찾기
  → hand crop·square canvas·RGB preprocessing
  → TensorRT engine inference
  → class probability
  → argmax·class mapping
  → display 또는 robot control decision
```

RPS model은 image 전체에 손이 일정한 크기와 배경으로 배치된 data를 사용해 학습했다. 실제 camera frame을 그대로 넣으면 배경, 손 위치, 손 크기, color order가 학습 data와 달라져 accuracy가 떨어질 수 있다. application 앞단에서 input distribution을 training data와 가깝게 맞추는 작업이 필요하다.

## MobileNetV2 model과 on-device runtime 복습

MobileNetV2는 ImageNet feature를 이미 학습한 backbone이다. 기존 classification head를 제외하고 현재 RPS class용 head를 붙여 transfer learning을 진행한다.

```text
`224 × 224 × 3` input
  → MobileNetV2 backbone
  → GlobalAveragePooling2D
  → Dense·Dropout classification head
  → `rock` / `paper` / `scissors`
```

`compile()`에서 optimizer·loss·metric을 정하고, `fit()`에서 train data로 학습한다. validation metric이 가장 좋을 때 `ModelCheckpoint`로 best model을 저장하면 Colab session이 끝난 뒤에도 같은 model을 다시 load해 deployment할 수 있다.

target에 따라 model format과 runtime이 달라진다.

| target | model·runtime | 주된 목적 |
| :--- | :--- | :--- |
| PC·Colab | Keras model + TensorFlow | 학습·debug |
| CPU 중심 embedded Linux board | LiteRT model + LiteRT runtime | 작은 package·CPU inference |
| Jetson Orin Nano | ONNX → TensorRT engine | NVIDIA GPU inference optimization |

Jetson TensorRT path는 다음과 같다.

```text
Keras/TensorFlow model
  → ONNX export
  → ONNX simplifier로 graph 정리
  → Jetson에서 `trtexec` engine build
  → serialized `.engine` load·deserialize
  → execution context에서 inference
```

TensorRT engine은 target GPU와 TensorRT version에 맞춰 Jetson에서 build한다. FP16 engine은 model size와 latency를 줄이는 실용적인 선택지다. INT8은 calibration과 accuracy 검증이 필요하므로, 먼저 FP32·FP16 결과를 비교한 뒤 적용한다.

## Hand localization과 RPS preprocessing

`cvzone`의 `HandDetector`는 camera frame에서 손의 landmark와 bounding box를 찾는다. RPS classifier에는 손 영역만 필요하므로, detector가 그린 visualization 전체를 쓰지 않고 bounding box `(x, y, w, h)`를 이용해 crop한다.

```text
OpenCV BGR frame
  → HandDetector.findHands()
  → hand bounding box
  → margin을 둔 crop
  → white square canvas 중앙 배치
  → RGB 변환·`224 × 224` resize
  → `float32`·batch dimension
  → TensorRT inference
```

손 box를 그대로 자르면 frame 경계에 닿거나 손이 너무 타이트하게 잘릴 수 있다. margin을 추가하되 crop 좌표를 image 범위 안으로 clamp해야 한다. hand crop의 aspect ratio를 유지한 채 흰색 square canvas 중앙에 배치하면 손 모양이 찌그러지지 않고 학습 image의 배경·구성에 가까워진다.

OpenCV camera image는 `BGR` channel order다. MobileNetV2 training data가 `RGB` 기준이면 `BGR → RGB` 변환을 한 뒤 model input으로 넣는다. 마지막에는 output probability의 `argmax` index를 class-name dictionary로 바꿔 사람이 읽는 label을 표시한다.

### Data augmentation의 역할

hand crop·canvas preprocessing은 inference 순간의 input을 정리한다. data augmentation은 training 단계에서 model이 조명·회전·위치 변화에 견디도록 만드는 방법이다.

| augmentation | 다루는 실제 변화 |
| :--- | :--- |
| horizontal flip | 좌우 방향 변화 |
| rotation | 손의 회전 |
| width·height shift | frame 내 위치 이동 |
| brightness range | 조명 변화 |
| zoom range | 손과 camera 거리 변화 |

Keras `ImageDataGenerator` 또는 preprocessing layer는 training batch를 만들 때마다 random transform을 적용한다. validation·test·실제 inference input에는 random augmentation을 넣지 않는다. augmentation을 적용하면 training이 느려질 수 있지만, clean dataset만 학습한 model이 실제 camera 환경에서 흔들리는 문제를 줄일 수 있다.

## Object Detection과 classification의 차이

single-object classification은 image 전체에 하나의 class label을 붙인다. object detection은 image 안에 여러 object가 있을 수 있고, 각 object의 class와 bounding box를 함께 예측한다. segmentation은 bounding box보다 세밀하게 pixel 단위 영역을 예측한다.

```text
classification: image → class
localization:   image → class + box 한 개
detection:      image → class + box 여러 개
segmentation:   image → object mask
```

대표적인 detection dataset annotation format은 Pascal VOC의 XML, COCO의 JSON, YOLO의 image별 text file이다. YOLO line은 `class_id x_center y_center width height` 순서이며, 좌표와 크기를 image width·height로 나눈 normalized ratio로 저장한다.

## IoU·Precision·Recall·AP·mAP

prediction box와 ground-truth box의 겹침 정도는 IoU(Intersection over Union)로 계산한다.

```text
IoU = intersection area / union area
```

class가 맞고 IoU가 threshold 이상이면 TP(True Positive)다. object가 없는데 있다고 예측하면 FP(False Positive), object가 있는데 찾지 못하면 FN(False Negative)다. background 영역의 TN은 매우 많아 detection metric의 중심으로 사용하지 않는다.

```text
precision = TP / (TP + FP)
recall    = TP / (TP + FN)
```

confidence를 낮추면 더 많은 box를 남겨 recall은 높아질 수 있지만 FP가 늘어 precision은 낮아질 수 있다. prediction을 confidence 내림차순으로 추가하면서 precision-recall curve를 만들고, curve의 면적이 class별 AP(Average Precision)다. mAP는 모든 class AP의 평균이다.

`mAP@0.5`는 IoU `0.5`에서의 AP 평균이다. COCO style mAP는 여러 IoU threshold를 평균낸 값이다. mAP를 비교할 때는 dataset, IoU threshold, class set을 함께 확인한다.

### NMS

같은 object 주변에는 유사한 prediction box가 여러 개 나올 수 있다. NMS(Non-Maximum Suppression)는 confidence threshold보다 낮은 box를 먼저 제거하고, 남은 box를 confidence 내림차순으로 보면서 높은 IoU로 겹치는 낮은 confidence box를 제거한다.

```text
candidate boxes
  → low-confidence box 제거
  → confidence 내림차순 정렬
  → 가장 높은 box 선택
  → 선택 box와 많이 겹치는 box 제거
  → 남은 box 반복
```

NMS는 여러 object를 하나로 합치는 기능이 아니다. 같은 object를 중복 검출한 box를 하나의 대표 box로 줄이는 post-processing이다.

## R-CNN과 Fast R-CNN

R-CNN은 selective search로 image마다 약 2,000개의 region proposal을 만들고, proposal 하나씩 resize해 CNN을 실행한다. CNN inference를 proposal 수만큼 반복하므로 매우 느리다.

```text
image
  → selective search로 region proposal 약 2,000개
  → proposal마다 CNN feature extraction
  → classification + bounding-box regression
  → NMS
```

Fast R-CNN은 image 전체에 CNN backbone을 한 번만 실행해 shared feature map을 만든다. selective search proposal은 shared feature map에서 필요한 영역의 feature를 가져오므로 CNN의 중복 실행을 없앤다.

```text
image
  → CNN backbone 한 번 실행
  → shared feature map
  + selective search proposal
  → RoI Pooling
  → fixed-size feature
  → fully connected detection head
```

RoI Pooling은 크기가 서로 다른 proposal 영역을 고정된 feature shape로 변환한다. detection head는 일정한 shape input을 받아 class score와 bounding-box regression을 계산할 수 있다. Fast R-CNN은 CNN 반복을 줄였지만 selective search가 별도 algorithm으로 남아 병목이 된다. Faster R-CNN은 RPN(Region Proposal Network)으로 proposal 생성까지 network 안에 통합해 이 병목을 줄인다.

## YOLO11n 객체 탐지 배포 흐름

객체 분류용 가위바위보 dataset은 image 전체에 class 하나를 붙인다. 객체 탐지 model을 학습하려면 image마다 class와 bounding box 위치를 함께 담은 annotation이 필요하다.

Ultralytics YOLO는 학습과 inference를 간단한 API로 묶은 도구다. 수업에서는 on-device target의 자원 제약을 고려해 `YOLO11n`의 `n`(nano) model을 사용한다. nano model은 연산량과 model 크기를 줄여 deployment에 유리하지만, 더 큰 model보다 정확도인 mAP가 낮아질 수 있다.

```text
annotation이 포함된 detection dataset
  → pretrained YOLO11n model
  → 원하는 class에 맞춘 fine-tuning
  → validation 결과에서 best checkpoint 선택
  → ONNX export
  → TensorRT engine 변환
  → Jetson camera inference
```

학습은 GPU가 있는 PC 또는 Colab에서 수행한다. target에서는 학습을 반복하지 않고 변환된 TensorRT engine으로 inference를 수행한다.

camera frame은 model 입력 규격에 맞춰 BGR에서 RGB로 바꾸고, input size로 resize하며, normalization을 적용한다. inference 결과의 candidate box는 NMS를 거쳐 최종 detection으로 정리한다. TensorRT model 내부의 NMS 출력은 device와 engine 조합에 따라 handling이 까다로울 수 있으므로, 수업 실습에서는 inference 뒤 application code 또는 OpenCV에서 NMS를 수행하는 방식을 사용한다.

### YOLO와 NMS의 역할

YOLO는 image에서 class score와 bounding box 후보를 한 번의 forward pass로 예측하는 one-stage detector다. NMS는 이 후보들 가운데 같은 object를 중복으로 가리키는 box를 줄이는 후처리다. 따라서 NMS는 model을 새로 학습하는 단계가 아니라 inference 결과를 화면과 제어 logic에 사용 가능한 detection으로 정리하는 단계다.

### NMS 결과를 화면에 표시하는 순서

NMS는 남길 box 자체보다 candidate 배열에서의 index 목록을 반환하는 형태로 구현할 수 있다. 이 index로 좌상단·우하단 좌표, class ID, score를 다시 찾아 rectangle과 label을 그린다. NMS에서 IoU를 직접 계산할 때 두 box의 합집합 넓이가 `0`이 되는 예외를 막기 위해 분모에 작은 `epsilon`을 더할 수 있다.

```text
model output
  → confidence threshold를 넘는 candidate box·class·score 저장
  → NMS가 남길 candidate index 반환
  → index별 box 좌표와 class·score 조회
  → frame에 rectangle과 label 표시
```

inference latency는 engine이 model 계산에 쓴 시간이다. camera capture, image preprocessing, NMS, drawing, display까지 포함한 frame time은 별도로 측정한다. 화면 반응이 기대보다 느릴 때는 inference latency만 보고 판단하지 않고 이 전체 경로를 함께 확인한다.

## Ultralytics YOLO의 간편 inference 경로

직접 TensorRT binding, image preprocessing, output parsing, NMS를 구현하면 각 단계의 동작을 세밀하게 제어할 수 있다. Ultralytics YOLO API는 image 또는 camera frame과 `conf`, `iou`, `imgsz` 같은 설정을 받으면 이 전처리와 후처리를 묶어 수행하고 detection result를 반환한다.

```text
camera frame + confidence threshold + IoU threshold
  → YOLO API의 preprocessing·inference·NMS
  → box·class ID·score result
  → class ID를 names mapping으로 변환
  → plot 또는 application 화면 표시
```

RPS detection class가 `0`, `1`, `2`로 출력될 때 `names` mapping을 `scissors`, `rock`, `paper`처럼 지정하면 화면에는 숫자 대신 의미 있는 class name을 표시할 수 있다. 간편 API는 빠른 prototype에 유리하고, custom TensorRT path는 memory binding과 output·NMS 구현을 직접 학습하거나 세밀하게 최적화할 때 사용한다.

### Remote display와 실제 frame rate

Jetson의 inference 자체가 충분히 빨라도 원격 desktop으로 큰 image를 전송해 표시하면 network 전송과 drawing 때문에 화면이 느려 보일 수 있다. project demonstration에서는 Jetson에 monitor를 직접 연결해 output을 표시하는 편이 더 안정적이다. camera input size와 display size를 키우면 pixel 수가 증가하므로 preprocessing, inference, display 비용이 함께 달라진다.

## Jetson local LLM 실행 환경

LLM은 학습 과정에서 얻은 지식을 parameter에 담고, 현재 요청에 포함된 prompt와 context를 바탕으로 다음 token을 확률적으로 생성한다. model 내부에 사용자별 대화를 영구히 저장하는 memory가 있는 구조가 아니다. 대화를 이어 가는 application은 이전 user message와 assistant response를 새 요청에 포함해 context를 유지한다.

```text
이전 대화 history + 새 user request
  → context window 안의 prompt 구성
  → LLM inference
  → response
  → history에 response 추가
```

context window에는 한계가 있다. 대화가 길어지면 이전 내용을 모두 넣을 수 없으므로 오래된 message를 제외하거나 summary로 압축한다. 이 때문에 필요한 hardware, camera, input size, library version, 원하는 output language·format 같은 조건은 현재 요청에 다시 명확히 적는 편이 안전하다.

### Prompt와 coding assistant mode

좋은 prompt는 수행할 일, 현재 환경, 제약 조건, 원하는 산출물 형식을 함께 제공한다. 예를 들어 camera code를 요청할 때 `USB webcam`인지 `CSI camera`인지, target이 Jetson인지 PC인지, 사용할 language와 output resolution이 무엇인지 구체적으로 적는다. 이름만 비슷한 device라도 interface와 code path가 다를 수 있다.

VS Code의 `Ask` mode는 질의응답과 code example 제시에 적합하다. `Agent` mode는 workspace file을 생성·수정하고 command 실행까지 수행할 수 있으므로 write scope와 요구사항을 더 명확하게 확인해야 한다.

### Docker

Docker container는 application code, dependency, library version, configuration을 함께 묶어 개발·test·deployment 환경을 재현한다. VM처럼 guest OS 전체를 별도로 실행하는 방식이 아니라 host OS kernel을 공유하므로 일반적으로 더 가볍다. Jetson project에서 CUDA, TensorRT, OpenCV, Python package version이 달라 발생하는 실행 차이를 줄이는 데 유용하다.

### Swap memory 확보

Jetson Orin Nano의 `8 GiB` unified memory는 CPU와 GPU가 함께 사용한다. 양자화한 local LLM model을 load한 뒤에도 context, KV cache, tokenizer와 runtime의 working memory가 더 필요하다. model file 크기만 보고 memory를 계산하면 부족해질 수 있으므로, `16 GiB` 이상 swap을 보조 공간으로 확보한다.

swap은 SSD 일부를 memory의 보조 공간으로 쓰는 영역이다. RAM보다 느리므로 GPU memory 사용량이 큰 model을 빠르게 만드는 수단은 아니다. 필요한 model 크기와 context length를 먼저 줄이고, swap은 out-of-memory 종료를 줄이는 안정성 보조 수단으로 사용한다.

```sh
sudo swapoff -a
sudo fallocate -l 16G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

`swapon` 뒤에는 `free -h` 또는 `htop`으로 swap total을 확인한다. 기존 `3.7 GiB` swap에 `16 GiB` file을 추가했다면 total은 약 `19.7 GiB`로 표시될 수 있다.

재부팅 뒤에도 `/swapfile`을 자동 활성화하려면 `/etc/fstab` 마지막 줄에 다음 entry를 둔다.

```text
/swapfile none swap sw 0 0
```

`/etc/fstab`은 system mount 설정 파일이므로 `sudoedit /etc/fstab`처럼 관리자 권한으로 수정한다. 파일 저장 뒤에는 entry 오타가 없는지 확인하고 재부팅한 뒤 `swapon --show`로 활성 상태를 검증한다.

### Ollama·GGUF 기반 local LLM runtime

LLM은 YOLO model처럼 weight만 있다고 실행되지 않는다. target hardware에서 weight를 load하고 token generation을 수행하는 runtime이 필요하다. Ollama는 Jetson 같은 edge device에서 local LLM을 설치·model download·실행하기 쉽게 묶은 runtime이다.

GGUF는 `llama.cpp` 계열 runtime에서 널리 쓰는 model file format이다. quantization으로 weight의 bit width를 줄인 GGUF model은 memory와 storage 요구량을 낮춰 local deployment에 적합하다. Ollama는 Gemma, Qwen, Llama 같은 model variant를 받아 실행하며, 선택한 tag가 quantization과 parameter 규모를 함께 결정한다.

```sh
ollama pull <model:tag>  # model 내려받기
ollama list              # 설치된 model 확인
ollama run <model:tag>   # local chat 실행
```

`pull` 없이 `run`을 먼저 실행해도 model이 없으면 내려받은 뒤 실행할 수 있다. model name과 tag를 정확히 지정해야 원하는 parameter 규모·quantization variant가 선택된다. model download는 수 GiB일 수 있으므로 class 환경처럼 여러 사람이 동시에 내려받을 때는 network 대기 시간이 길어질 수 있다.

### Browser 기반 local LLM UI

terminal chat 대신 Jetson에서 Ollama server를 실행하고, Docker로 Web UI를 구성하면 host PC browser에서 Jetson의 local model에 접속해 chat할 수 있다. 이 구조에서 browser는 UI만 제공하고, model inference는 Jetson에서 수행한다.

```text
host PC browser
  → Jetson의 Web UI container
  → Ollama server
  → quantized local LLM inference on Jetson
```

Web UI container는 Ollama API address와 port 설정을 정확히 받아야 한다. host PC, Docker container, Jetson host는 network namespace가 다를 수 있으므로 단순히 `localhost`만 지정하면 연결 대상이 달라질 수 있다.

### Model 선택·관리 기준

Jetson에서 local LLM을 고를 때는 parameter 수, quantization, model file 크기, context length, text·vision 지원 여부를 함께 본다. `4B`는 약 40억 parameter 규모를 뜻하고, `4-bit` 또는 `Q4_K_M`은 weight를 표현하는 quantization 방식이다. 이름이 비슷해도 서로 다른 축이다.

```text
model parameter 수 증가
  → 일반적으로 표현력 증가 가능
  → memory·latency 증가

quantization bit 수 감소
  → model file·memory 감소
  → 정확도·출력 품질 저하 가능
```

`ollama list`로 local에 내려받은 model을 확인하고, 필요하지 않은 model은 `ollama rm <model:tag>`로 제거해 storage를 관리한다. Web UI에서도 model search, download, selection, removal을 할 수 있다. model tag는 parameter 규모와 quantization variant를 포함할 수 있으므로 `pull`·`run`·API 요청에서 정확한 전체 tag를 사용한다.

일부 reasoning model은 답변 전에 내부 reasoning trace를 출력할 수 있다. interactive UI에서는 이 출력을 숨기거나 보이게 설정할 수 있다. application API에서는 reasoning 출력이 최종 response token 예산을 잠식하지 않도록 model option을 확인하고, 사용자가 필요한 최종 답변만 화면에 표시한다.

### Ollama Python API

terminal 또는 Web UI가 아닌 application에서는 Ollama Python package의 API로 local model을 호출한다. project dependency가 system Python과 섞이지 않도록 virtual environment 안에서 package를 설치한다.

```python
from ollama import chat, generate

one_shot = generate(
    model='<model:tag>',
    prompt='질문',
    stream=False,
)
print(one_shot.response)

history = [
    {'role': 'user', 'content': '질문'},
]
reply = chat(
    model='<model:tag>',
    messages=history,
    stream=False,
)
print(reply.message.content)
```

`generate()`는 하나의 prompt에 답하는 one-shot generation에 적합하다. `chat()`은 `role`과 `content`를 가진 message dictionary 목록을 받아 multi-turn 대화를 구성한다. model 자체가 대화를 영구 저장하는 것은 아니므로 application이 이전 history를 유지해 다음 `chat()` 요청에 다시 보낸다.

```python
history = [
    {'role': 'system', 'content': '응답 방식과 역할을 지정하는 지시'},
    {'role': 'user', 'content': '현재 질문'},
    {'role': 'assistant', 'content': '이전 모델 응답'},
    {'role': 'user', 'content': '다음 질문'},
]
```

`system` message는 model의 역할, 말투, output constraint 같은 전체 지시를 둔다. `user`는 사용자의 현재 요청이고, `assistant`는 이전 model response다. application은 새 user request와 새 assistant response를 history에 순서대로 append해 context를 구성한다. local LLM은 별도 tool integration이 없으면 internet search를 수행하지 않고, model weight와 요청에서 제공한 context만 사용한다.

`stream=True`이면 token 또는 response chunk가 순서대로 전달된다. terminal chat이나 typing effect에는 유용하지만, 단순한 실습에서 최종 답을 한 번에 받아 처리하려면 `stream=False`를 사용한다. `GenerateResponse`의 `.response`에는 생성 text가 있고, 전체 object에는 model name, duration, token count 같은 metadata가 포함된다. duration metadata의 단위는 보통 nanosecond이므로 `ms`·`s`로 환산할 때 단위를 확인한다.

`chat(..., stream=True)`의 반환값은 complete response 하나가 아니라 chunk iterator다. loop 안에서 각 `chunk.message.content`를 꺼내 즉시 출력한다. Python `print()`는 buffering할 수 있으므로 terminal에 token이 즉시 보이게 하려면 `end=''`와 `flush=True`를 함께 사용한다. 마지막 chunk에는 total duration, token count 같은 완료 metadata가 들어갈 수 있으므로 UI text는 chunk의 content만 사용하고, 성능 기록은 마지막 metadata에서 분리해 저장한다.

```python
stream = chat(model='<model:tag>', messages=history, stream=True)
for chunk in stream:
    print(chunk.message.content, end='', flush=True)
```

`stream=False`는 inference가 끝날 때까지 caller를 기다리게 한다. 이 동안 application이 멈춘 것처럼 보일 수 있다. robot·camera loop처럼 다른 작업을 계속 처리해야 하는 application에서는 streaming loop 또는 worker thread·async task로 LLM inference를 분리한다.

Ollama API는 model list·show·pull·delete·create·push 같은 관리 operation도 제공한다. application의 정상 실행 경로는 보통 model을 미리 준비한 뒤 `chat()` 또는 `generate()`로 inference만 수행하고, download·delete는 setup 또는 maintenance 단계에서 분리한다.

## 실습 확인 항목

- training preprocessing과 camera preprocessing의 color order·size·normalization 일치 확인
- hand box margin과 frame boundary 처리 확인
- TensorRT engine input binding의 shape·dtype 확인
- camera frame마다 engine 생성·deserialize를 반복하지 않는지 확인
- confidence threshold와 NMS IoU threshold의 역할 분리
- precision·recall·AP·mAP에서 TP·FP·FN의 기준 구분
- R-CNN의 proposal별 CNN 반복과 Fast R-CNN의 shared feature map 차이 설명
- classification dataset과 detection annotation의 차이 설명
- `YOLO11n.pt → ONNX → TensorRT engine` 변환 순서 확인
- NMS가 반환한 index로 box·class·score를 다시 조회하는 흐름 확인
- inference latency와 end-to-end frame time 분리 측정
- YOLO API의 class ID와 `names` mapping 연결
- local LLM request에 task·environment·constraint·output format 포함
- Docker container가 code·dependency·version을 함께 고정하는 이유 설명
- swap과 RAM의 역할·속도 차이 구분
- `swapoff → fallocate → chmod 600 → mkswap → swapon` 설정 순서 확인
- `/etc/fstab`의 `/swapfile none swap sw 0 0` entry 역할 설명
- `ollama pull`·`list`·`run`의 목적 구분
- `4B parameter`와 `4-bit quantization`의 의미 구분
- `generate()` one-shot과 `chat()` history 기반 호출 구분
- `stream=True` chunk 수신과 `stream=False` 완성 response 수신 구분
- `system`·`user`·`assistant` message role과 history append 흐름 설명
- streaming loop에서 `chunk.message.content`와 완료 metadata 분리
