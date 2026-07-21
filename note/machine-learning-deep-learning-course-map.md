# Korcham ON-Device AI 1~3부 고정 범위

> 이 파일은 Korcham AI 수업의 `1부 ML/DL → 2부 CNN → 3부 Jetson Orin
> Nano` 직접 범위와 실제 학습일을 기록하는 activity map이다.
>
> 전체 ML·DL 큰그림은
> [[domains/data-science/ai/on-device-ai-ml-dl-yolo-curriculum|On-Device AI ML·DL·YOLO 통합 학습 커리큘럼]]에서
> 관리한다. 그 안에서 Codeit·Addinedu·Udemy·기타 보유 자료는 같은 개념을
> 배우는 pass에서 병행하되, 이 activity map에는 Korcham 직접 범위와 실제
> 진도를 남긴다.

## 관련 학습 노트

- [[activities/korcham/notes/kdt-c-python-m4-ai-course-outline|KDT C/Python/M4/AI 과정 LMS 목차]]
- [[activities/korcham/notes/260728-on-device-ai-deep-learning-1|07-28: Perceptron부터 MNIST data 준비]]
- [[activities/korcham/notes/260729-on-device-ai-deep-learning-1-continuation|07-29: MNIST model 구성부터]]
- [[activities/korcham/notes/260729-on-device-ai-deep-learning-2-cnn|07-29: 2부 CNN 완료]]
- [[activities/korcham/notes/embedded-linux-jetson-on-device-ai-course-map|3부: Embedded Linux·Jetson On-Device AI 범위]]

## 원자료

Google Classroom:

- `Google Drive/My Drive/Classroom/대한상공회의소_반도체설계/codexpert-ON_Device_AI/260707-on-device-ai-deep-learning-1-jpg`
- `Google Drive/My Drive/Classroom/대한상공회의소_반도체설계/codexpert-ON_Device_AI/260707-on-device-ai-deep-learning-2-jpg`

Work 보존본:

- `/Volumes/Work/Safekeep/source-media/korcham/260707-image-extracts/260707-on-device-ai-deep-learning-1-jpg`
- `/Volumes/Work/Safekeep/source-media/korcham/260707-image-extracts/260707-on-device-ai-deep-learning-2-jpg`

Korcham 실습 notebook:

- `Google Drive/My Drive/Classroom/대한상공회의소_반도체설계/기호민-ON_Device_AI_Deep_Learning_AND_Embedded_Linux_Jetson_Orin_Nano/상공회의소_KDT_실습자료(딥러닝_CNN)/01.DL(CNN)_Examples`

1~2부 Deep Learning 교재와 직접 연결되는 notebook은 `01_ML_DL_Basic`의
`7`개와 `02_CNN`의 `3`개다. 저장된 output은 수업 source evidence이며
그 output을 본 사실만으로는 학습 완료 evidence가 아니다. 같은 개념을 다른
보유 자료와 병행해 실제 설명·계산·code trace·실습 근거를 만들었다면 해당
Korcham 단원 TODO를 갱신하며, Korcham notebook만 완료용으로 반복하지 않는다.

두 묶음은 사진 `76`장이다. 첫 묶음은 `47`장, 두 번째 묶음은 `29`장이다.
교재 `5쪽`은 두 번 촬영되었고, 중복 촬영을 제외한 본문은 `5~77쪽`으로
이어진다.

## 1~2부 교재 직접 범위

| 부 | 단원 | 교재 쪽 | Classroom image |
| :--- | :--- | :---: | :--- |
| 1부 | Machine Learning과 Perceptron | 5~8 | `IMG_3371`~`IMG_3375` |
| 1부 | Linear Regression | 9~22 | `IMG_3376`~`IMG_3389` |
| 1부 | Logistic Regression | 23~31 | `IMG_3390`~`IMG_3398` |
| 1부 | Softmax Classification | 32~38 | `IMG_3399`~`IMG_3405` |
| 1부 | Multi Layer Perceptron | 39~48 | `IMG_3406`~`IMG_3415` |
| 2부 | CNN 구분 | 49 | `IMG_3416` |
| 2부 | CNN 개요 | 50~53 | `IMG_3417`~`IMG_3420` |
| 2부 | CNN 기본연산 | 54~60 | `IMG_3421`~`IMG_3427` |
| 2부 | CNN 기반 Classification | 61~68 | `IMG_3428`~`IMG_3435` |
| 2부 | CNN 발전 시키기 | 69~77 | `IMG_3436`~`IMG_3444` |

## 3부 Jetson Orin Nano 직접 범위

3부는 별도 개인 확장이 아니라 같은 Korcham AI 수업의 application·deployment
구간이다.

| 과 | 단원 | 직접 수업 산출물 |
| :---: | :--- | :--- |
| 1 | Webcam을 이용한 CNN 활용 | camera frame→preprocess→CNN output |
| 2 | TensorRT를 이용한 RPS Classification | MobileNetV2→ONNX→TensorRT→Jetson inference |
| 3 | RPS Classification 개선 | hand ROI·augmentation·robustness 비교 |
| 4 | Object Detection의 주요 개념 | box·IoU·AP·mAP·NMS·YOLO |
| 5 | Object Detection 구현 | RPS dataset·YOLO training/export·Jetson webcam inference |
| 6 | Jetson을 이용한 local LLM 환경 구축 | JetPack/Linux·container·storage·local model |
| 7 | Ollama API 활용 | Ollama·Open WebUI·REST/Python API |

```text
AI·ML·DL 배경
  → Perceptron
  → Linear Regression
  → Logistic Regression
  → Softmax Classification
  → Multi Layer Perceptron
  → CNN 개요
  → Convolution·Padding·Stride·Pooling
  → CNN Classification
  → CNN 발전과 MobileNetV2
  → Webcam·RPS transfer learning
  → ONNX·TensorRT·Jetson inference
  → RPS 개선
  → Object Detection·YOLO
  → Jetson local LLM·Ollama API
```

## 현재 학습 기록

- 학습 시작: `2026-07-28`
- `2026-07-28`: Perceptron부터 MNIST data 준비까지
- `2026-07-29`: 1부 MNIST model 구성부터 마무리하고 2부 CNN 전체 완료
- `2026-07-29`: 3부 Windows·WSL·NVIDIA SDK Manager 환경 확인 중 종료

자료를 정리한 사실은 단원 완료가 아니다. 통합 curriculum에서 실제 설명·계산·
code trace·실습 근거가 생기면 그 근거가 충족하는 Korcham 단원의 학습 상태와
TODO를 함께 갱신한다. 출처별로 별도 완료 근거를 만들지 않는다.

## 범위 경계

Korcham AI 직접 범위는 `Perceptron → regression·classification → MLP →
CNN·MobileNetV2 → Jetson webcam·RPS·TensorRT → Object Detection·YOLO →
local LLM·Ollama`까지다.

- Codeit·Addinedu·Udemy·기타 보유 자료에서 같은 개념을 설명하는 부분은
  해당 Korcham 단원을 배우는 같은 pass에서 병행한다.
- Addinedu YOLOv8과 Work 배포 자료는 3부의 OpenCV·YOLO·runtime·profiling을
  함께 이해하는 자료이며, 출처만 구분한다.
- 전통 ML 폭·시계열처럼 1~3부와 겹치지 않는 내용은 수업 뒤에 진행한다.
- 3부가 끝나면 수업에서 만든 RPS·YOLO model과 Jetson 환경을 그대로 사용해
  상세 device profiling과 NPU의 MAC·SRAM·DMA·tiling·data reuse를 최우선
  fast lane으로 진행한다.

통합 학습 순서와 출처 경계는
[[domains/data-science/ai/on-device-ai-ml-dl-yolo-curriculum|On-Device AI ML·DL·YOLO 통합 학습 커리큘럼]]을 기준으로 한다.
