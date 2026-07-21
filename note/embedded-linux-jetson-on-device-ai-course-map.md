# Korcham AI 3부: Embedded Linux·Jetson On-Device AI 전체 지도

관련 노트:

- [KDT C/Python/M4/AI 과정 LMS 목차](kdt-c-python-m4-ai-course-outline.md)
- [07-30 - Jetson 원격 개발·OpenCV 얼굴 검출](260730-jetson-remote-development-and-opencv-face-detection.md)
- [08-03 - ONNX·TensorRT 배포와 RPS camera preprocessing](260803-on-device-ai-tensorrt-deployment-and-rps-camera-preprocessing.md)
- [08-04 - Object Detection·Jetson local LLM·Ollama API](260804-object-detection-jetson-local-llm-and-ollama-api.md)
- [Jetson Orin Nano Developer Kit 장비 기록](jetson-orin-nano-developer-kit.md)
- [Machine Learning·Deep Learning 전체 지도](machine-learning-deep-learning-course-map.md)
- [CODEXPERT 과목 지도](../../../references/codexpert/curriculum-map.md)

## 과정의 위치와 범위

이 과정은 Korcham AI 수업의 3부다. 1부 ML/DL과 2부 CNN에서 학습한 model을
`Jetson Orin Nano`라는 Linux hardware platform에서 camera input, inference
runtime, application 기능과 연결한다. Target board에서 model을 실행하고
latency·memory·device I/O를 함께 다룬다.

LMS의 상위 표기는 `E-2 온-디바이스 AI`와 `Raspberry Pi On-Device AI`다.
현재 상세 선행 자료와 보유 장비 기록은 `Jetson Orin Nano`, TensorRT, YOLO,
Ollama 범위를 담고 있다. 따라서 이 지도는 1~2부 뒤에 이어지는 3부 직접
수업 범위의 preview이며, 날짜별 실제 수업 진행·실습 결과와 구분한다.

## 자료 상태

현재 Jetson 본문은 `_staging`의 선행·대기 메모이며, Jetson 장비 기록도 향후 AI 실습 장비 정보다. 이 파일은 준비된 과목 범위와 실습 흐름을 정리한 지도다. 실제 JetPack version, installed TensorRT API, camera device path, engine benchmark는 실습 시점의 board 상태를 기준으로 별도 확인한다.

```text
webcam input
  → OpenCV preprocessing
  → CNN classification 또는 object detection
  → ONNX export
  → TensorRT engine build
  → Jetson GPU inference
  → application result·display·robot/control decision

별도 축
Jetson Linux → local LLM runtime → Ollama API → Open WebUI 또는 application
```

## Jetson board와 software stack

Jetson Orin Nano Developer Kit은 hardware platform이다. 수업에서 주로 작성·설정하는 대상은 그 위 Linux에서 실행되는 application, AI runtime, container, device API다.

| 층 | Jetson 범위에서 맡는 역할 | 대표 요소 |
| :--- | :--- | :--- |
| hardware platform | CPU·GPU·memory·camera·network·40-pin I/O 제공 | Jetson Orin Nano module, CSI camera, USB camera, Ethernet |
| boot·OS | board를 부팅하고 process·memory·file·network 관리 | JetPack, Linux for Tegra, Linux kernel |
| kernel driver | camera·GPU·UART·I2C·SPI·GPIO device 제어 | V4L2, NVIDIA driver, I2C/SPI/UART/GPIO driver |
| AI runtime·SDK | model을 GPU에서 실행·최적화 | CUDA, TensorRT, OpenCV |
| application | camera frame 처리, prediction 사용, API·UI·robot logic | C++/Python application, ROS2 node, WebUI |

보유 Jetson Orin Nano 8GB module은 6-core Arm Cortex-A78AE CPU, Ampere GPU와 Tensor Cores, 8GB LPDDR5 unified memory를 갖는다. 수업의 TensorRT baseline은 이미 탑재된 Jetson GPU를 software runtime으로 활용하는 방식이다.

## Cortex-M4 firmware와 Jetson Linux의 연결

UART·I2C·SPI·GPIO의 전기적 signal과 protocol은 같은 hardware 지식 위에 있다. CPU가 peripheral에 접근하는 software layer가 달라진다.

| Peripheral | STM32 Cortex-M4 | Jetson Embedded Linux |
| :--- | :--- | :--- |
| GPIO | `GPIOx->MODER/ODR/IDR` MMIO 직접 access | kernel GPIO driver + libgpiod |
| UART | `USARTx->BRR/CR/SR/DR` | `/dev/ttyTHS*` + terminal/termios API |
| I2C | START·ADDR·ACK·`SR1/SR2/DR` 직접 처리 | `/dev/i2c-*` + I2C device API |
| SPI | `SPIx->CR/SR/DR` 직접 처리 | `/dev/spidev*` + Linux SPI API |
| interrupt | NVIC·ISR·event flag | kernel driver가 IRQ 처리, application은 file/API event를 사용 |

```text
STM32 bare-metal
application/driver C → MMIO register → peripheral hardware

Jetson Linux
application → SDK·system call·device file → kernel driver → peripheral hardware
```

Jetson application은 user space에서 실행된다. Linux kernel과 driver가 hardware access·interrupt·DMA 같은 낮은 계층을 맡고, application은 정해진 API·device file을 통해 기능을 요청한다.

## 실제 수업 흐름

| 과 | 주제 | 만드는 것 |
| :---: | :--- | :--- |
| 1 | Webcam을 이용한 CNN 활용 | webcam frame을 읽고 CNN input·classification 결과로 연결 |
| 2 | TensorRT RPS Classification | MobileNetV2 기반 rock-paper-scissors model을 Jetson TensorRT로 실행 |
| 3 | RPS Classification 개선 | hand ROI, data augmentation, accuracy·robustness 개선 |
| 4 | Object Detection 주요 개념 | classification·localization·detection·segmentation, IoU·AP·mAP·NMS·YOLO |
| 5 | Object Detection 구현 | dataset·annotation·YOLO training/export·Jetson webcam inference |
| 6 | Jetson local LLM 환경 | JetPack/Linux, container, storage·swap, local model 실행 준비 |
| 7 | Ollama API 활용 | Ollama model·Open WebUI·REST/Python API application 연결 |

## Vision input: webcam frame을 model input으로 바꾸기

```text
camera / webcam
  → VideoCapture
  → frame read
  → BGR/RGB color conversion
  → resize·crop·normalization
  → model input tensor
  → inference
  → class probability 또는 bounding box
  → 화면 overlay·application decision
```

camera code의 중요한 부분은 model 호출 한 줄만이 아니다. training 때 사용한 input shape, color order, pixel scale, normalization을 runtime frame에도 똑같이 적용해야 한다.

| 항목 | training/model 쪽 계약 | Jetson application에서 확인할 것 |
| :--- | :--- | :--- |
| input size | 예: `224×224×3` | frame resize/crop 결과 |
| color order | RGB 또는 BGR | OpenCV conversion 여부 |
| value scale | `0~1`, `-1~1`, raw `0~255` | training preprocessing과 동일 여부 |
| batch shape | 예: `(1, H, W, C)` | batch dimension 추가 여부 |
| output meaning | class probability·box·class score | argmax·threshold·NMS 기준 |

## RPS Classification: model training에서 Jetson inference까지

RPS는 `rock`, `paper`, `scissors` 세 class를 구분하는 image classification 실습이다. 작은 dataset에서도 pretrained MobileNetV2 backbone을 재사용하는 transfer learning 흐름을 경험한다.

```text
RPS images
  → train/test split·augmentation
  → MobileNetV2 pretrained backbone
  → new classification head
  → validation·best model save
  → ONNX export
  → TensorRT engine
  → webcam classification on Jetson
```

| 구성 | 역할 |
| :--- | :--- |
| MobileNetV2 backbone | ImageNet에서 학습된 visual feature 재사용 |
| `include_top=False` | 기존 ImageNet classifier head 제거 |
| Global Average Pooling | feature map을 channel별 대표값으로 축약 |
| `Dense(3, softmax)` | RPS 세 class probability output |
| frozen backbone | 작은 dataset에서 pretrained feature 보존 |
| augmentation | lighting·position·background 변화에 대한 robustness 보강 |

RPS 개선에서는 손 영역을 먼저 crop하거나 background·조명·거리 variation을 training data에 추가한다. model만 바꾸기보다 input distribution과 dataset 품질을 함께 바꾸는 과정이다.

## ONNX와 TensorRT: model을 target runtime으로 옮기기

```text
Keras/TensorFlow 또는 PyTorch model
  → ONNX export
  → optional graph simplification
  → TensorRT build on target Jetson
  → `.engine`
  → TensorRT runtime inference
```

| 산출물 | 역할 |
| :--- | :--- |
| saved model / weights | framework가 읽는 학습 model |
| `.onnx` | framework 사이에서 graph를 교환하는 model format |
| simplified ONNX | 불필요한 graph를 정리한 변환 입력 |
| `.engine` | Jetson GPU·TensorRT version에 맞게 최적화된 inference artifact |

TensorRT는 training framework가 아니다. 학습된 model graph를 target GPU에 맞춰 kernel selection, layer/tensor fusion, memory planning, precision 선택으로 최적화해 inference를 실행하는 runtime/SDK다.

| precision | 장점 | 주의점 |
| :--- | :--- | :--- |
| FP32 | 기준 정확도·호환성 | model size·latency 증가 가능 |
| FP16 | Jetson GPU에서 일반적인 latency·memory 절감 선택 | accuracy 비교 필요 |
| INT8 | 더 큰 size·latency 절감 가능 | calibration과 accuracy 검증 필요 |

TensorRT engine은 GPU architecture, TensorRT/CUDA/JetPack version, input shape와 supported operator에 의존한다. engine file은 실제 inference target Jetson에서 build하는 것을 기준으로 둔다.

### TensorRT runtime 객체 흐름

```text
engine file
  → `trt.Logger`
  → `trt.Runtime`
  → `ICudaEngine`
  → `IExecutionContext`
  → input/output buffer 주소 등록
  → CUDA stream
  → asynchronous execute
  → stream synchronize
  → output postprocess
```

| 객체 | 역할 |
| :--- | :--- |
| `Logger` | TensorRT diagnostic output 기준 |
| `Runtime` | serialized engine을 실행 가능한 engine으로 deserialize |
| `ICudaEngine` | 최적화된 network graph·weight·I/O contract |
| `IExecutionContext` | input shape, activation과 실행 중 state |
| I/O buffer | host/device 또는 unified memory의 input·output storage |
| CUDA stream | copy·kernel 실행 순서를 관리하는 asynchronous queue |

성능은 average latency만 보지 않는다. throughput, p99/worst-case latency, host-to-device·device-to-host copy, GPU compute time, memory 사용량을 함께 확인한다. camera application은 frame capture·preprocessing·postprocessing 시간까지 포함해 end-to-end latency로 판단한다.

## Object detection: class 외에 위치를 함께 예측하기

| task | output |
| :--- | :--- |
| Classification | image 전체의 class probability |
| Localization | object 하나의 class + bounding box |
| Detection | object 여러 개의 class + box + score |
| Segmentation | pixel 또는 object mask |

YOLO annotation 한 줄은 하나의 object를 class와 normalized bounding box로 표현한다.

```text
class_id center_x center_y width height
```

| 지표·단계 | 의미 |
| :--- | :--- |
| IoU | prediction box와 ground-truth box의 overlap 비율 |
| precision / recall | false positive·false negative를 포함한 detection 품질 |
| AP | class 하나의 precision-recall curve 면적 |
| mAP | class별 AP의 평균 |
| NMS | 겹친 중복 box를 score 기준으로 제거 |

```text
webcam frame
  → YOLO inference
  → candidate boxes·class scores
  → confidence threshold
  → NMS
  → remaining boxes·labels overlay
```

Object detection은 model의 raw output을 곧바로 화면에 쓰지 않는다. box coordinate conversion, score threshold, NMS, class label mapping이 함께 있어야 제품 기능이 된다.

## Local LLM: vision pipeline과 별도의 application 축

vision inference가 camera frame을 CNN/YOLO model에 넣는 흐름이라면, local LLM은 text prompt와 model context를 local runtime에 넣는 흐름이다.

```text
Jetson Linux / JetPack
  → Docker 또는 Python environment
  → Ollama service
  → quantized local LLM model
  → Open WebUI 또는 REST API
  → chat·embedding·RAG·product application
```

| 요소 | 역할 |
| :--- | :--- |
| JetPack/Linux | board OS와 NVIDIA runtime 기반 |
| Docker | application dependency와 service isolation |
| swap | memory pressure가 큰 model load의 보조 virtual memory |
| Ollama | local LLM model download·serve·API runtime |
| Open WebUI | browser 기반 local chat interface |
| API | application이 chat/generate/embedding을 호출하는 interface |

Jetson Orin Nano 8GB는 CPU와 GPU가 unified memory를 공유한다. local LLM에서는 parameter 수, quantization bit, context length, model load time, token generation rate, swap pressure를 함께 관리한다. 작은 quantized model부터 기준 성능을 잡고 확장하는 방식이 안정적이다.

## 코드·언어 선택의 경계

현재 선행 자료의 model training·camera 예제·TensorRT wrapper·Ollama API는 Python 중심이다. 이는 model experiment와 SDK 탐색을 빠르게 하기 위한 선택이다.

| 범위 | Python이 편한 지점 | C++로 확장하기 좋은 지점 |
| :--- | :--- | :--- |
| model training | TensorFlow/Keras, dataset experiment | training 자체는 Python ecosystem 비중 큼 |
| camera vision | OpenCV prototype, model 검증 | OpenCV C++ production loop |
| TensorRT | engine build·quick wrapper | TensorRT C++ API, deterministic integration |
| device I/O | small script·validation | UART/I2C/SPI/GPIO C++ service |
| application integration | API proof of concept | ROS2 C++ node, robot/control application |

C++는 Jetson product application의 자연스러운 확장 경로다. 다만 현재 수업 범위에서 C++ implementation이 이미 필수 산출물이라고 단정하지 않고, Python 예제로 먼저 model/runtime contract를 확인한 뒤 필요한 component를 C++로 옮긴다.

## Jetson 수업에서 하지 않는 hardware 설계

| 이 과정에서 하는 일 | 별도 FPGA/RTL 과정에서 하는 일 |
| :--- | :--- |
| existing Jetson GPU를 TensorRT software로 사용 | CNN/NPU MAC·buffer·controller를 RTL로 구현 |
| Linux·runtime·camera·application integration | Vivado synthesis·bitstream·AXI custom IP |
| model accuracy·latency·memory 측정 | RTL simulation·waveform·FPGA hardware validation |

Jetson·TensorRT 작업은 on-device AI deployment와 embedded AI system integration에 해당한다. FPGA CNN/NPU custom IP는 accelerator hardware design에 해당하며, 두 범위는 같은 model을 다른 실행 target에서 다루는 연결 관계다.

## 현재 학습 source 지도

| 범위 | 먼저 볼 자료 | 확인할 것 |
| :--- | :--- | :--- |
| 상위 과정 위치 | [KDT LMS 목차](kdt-c-python-m4-ai-course-outline.md) | `E-2` on-device AI 표기 |
| Jetson 수업 노트 | [07-30](260730-jetson-remote-development-and-opencv-face-detection.md), [08-03](260803-on-device-ai-tensorrt-deployment-and-rps-camera-preprocessing.md), [08-04](260804-object-detection-jetson-local-llm-and-ollama-api.md) | webcam·TensorRT·YOLO·local LLM·Ollama 순서 |
| board hardware | [Jetson Orin Nano Developer Kit](jetson-orin-nano-developer-kit.md) | CPU/GPU/memory/I/O·camera·40-pin header |
| model-side 선행 | [Machine Learning·Deep Learning 전체 지도](machine-learning-deep-learning-course-map.md) | CNN·transfer learning·input/output contract |
| software/hardware boundary | [Embedded software stack and HW/SW co-design](../../../domains/semiconductor/ai-npu-system-integration/embedded-software-stack-firmware-and-hw-sw-co-design.md) | application·runtime·OS·driver·hardware layer |

같은 개념의 보유 자료는 해당 3부 단원을 배우는 pass에서 병행한다.

| 3부 단원 | 병행 자료 | 함께 확인할 내용 |
| :--- | :--- | :--- |
| Webcam·RPS | Korcham MobileNetV2 notebook·board script, DUDL CNN, Addinedu ML·OpenCV | transfer learning, ROI·augmentation, preprocessing parity |
| ONNX·TensorRT | Work Build On-Device AI, NVIDIA 문서; Raspberry Pi 배포 archive는 TFLite backend 비교에만 사용 | graph export·compile·validate·profile, runtime·target 경계; TFLite 결과를 TensorRT의 직접 근거로 사용하지 않음 |
| Object Detection·YOLO | Korcham YOLO11n, Addinedu YOLOv8, Ultralytics·COCOeval 문서 | label·box·IoU·NMS·AP/mAP, version별 output·loss·export |
| local LLM·Ollama | Jetson 수업 자료와 local-runtime 문서 | container·memory·context·tokens/s·REST/Python API |

통합 학습 근거가 해당 개념을 충족하면 3부 Korcham TODO를 함께 체크하며,
출처별로 같은 실습을 다시 완료하지 않는다. 3부 직후에는 수업 model과 board를
그대로 사용해 상세 device profiling과 NPU data movement를 최우선으로 확장한다.

## 실행·debug 순서

```text
1. Jetson boot·network·storage·JetPack 상태
2. camera device를 Linux/OpenCV에서 frame으로 읽는지
3. preprocessing 결과의 shape·color·normalization이 training과 같은지
4. framework model 기준 output이 맞는지
5. ONNX conversion과 TensorRT engine build가 되는지
6. TensorRT output·postprocess가 framework와 같은지
7. end-to-end latency·memory·temperature·stability를 측정하는지
```

이 순서는 model·runtime·camera·board 문제를 한꺼번에 섞지 않고, 하위 platform부터 application 결과까지 분리해 확인하는 기준이다.

## 이후 회독의 기준

| pass | 목표 | 확인 가능한 상태 |
| :--- | :--- | :--- |
| 1차 지도 pass | Jetson board·Linux·runtime·application 계층 구분 | TensorRT와 CUDA·Linux·application 역할 설명 |
| 2차 동작 pass | camera→preprocess→engine→output trace | input/output shape·engine·latency 측정 경로 확인 |
| 3차 재구성 pass | 작은 vision 또는 local LLM application 변경 | model·camera·runtime·I/O 중 한 축을 바꿔 debug |

Jetson을 다시 볼 때는 `board/OS → camera/device → preprocessing → model/runtime → postprocess → application latency` 순서로 읽는다. 이 순서가 Cortex-M4 firmware와 FPGA accelerator를 하나의 system으로 연결할 때도 유지된다.
