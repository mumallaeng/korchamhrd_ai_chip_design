# 26-07-30 - Jetson 원격 개발 환경과 OpenCV 얼굴 검출 스트리밍

관련 노트:

- [26-07-29 - ON-Device AI를 위한 Deep Learning 2부: CNN](260729-on-device-ai-deep-learning-2-cnn.md)
- [Embedded Linux·Jetson On-Device AI 전체 지도](embedded-linux-jetson-on-device-ai-course-map.md)
- [Machine Learning·Deep Learning 전체 지도](machine-learning-deep-learning-course-map.md)

> 수업일: `2026-07-30`
>
> 현재 상태: Jetson board에 SSH로 접속하고 VS Code Remote-SSH로 개발하는 경로를 확인했다. Colab browser webcam input을 Python/OpenCV로 전달해 Haar cascade 얼굴 검출과 bounding box 표시까지 실행했다.

## 수업 범위

| 구분 | 내용 |
| :--- | :--- |
| Jetson 개발 환경 | SSH 접속, package update, VS Code Remote-SSH |
| 영상 입력 경계 | browser JavaScript webcam frame과 Python 실행 환경 연결 |
| OpenCV 얼굴 검출 | Haar cascade XML, grayscale 변환, `detectMultiScale()` |
| 영상 출력 | bounding box·label·FPS overlay, Base64 인코딩, browser display |
| 실시간성 | frame loop, FPS 계산, 검출·표시 frame 차이에서 생기는 지연 |

## 전체 흐름

```text
browser webcam
  → JavaScript가 frame capture
  → Base64 text로 Python runtime에 전달
  → byte decode·OpenCV BGR image 복원
  → grayscale·Haar cascade face detection
  → bounding box·label·FPS overlay
  → image encode·Base64 변환
  → JavaScript display
```

Colab runtime은 browser가 실행되는 PC와 분리되어 있으므로 webcam hardware를 Python code에서 곧바로 읽을 수 없다. browser의 JavaScript가 webcam frame을 capture하고, Python/OpenCV가 처리할 수 있는 data로 넘겨 주는 경계 code가 필요하다. 이 구조는 이후 Jetson에서 `camera input → inference → overlay → display`를 구성할 때도 그대로 이어진다.

## Jetson 원격 개발 환경

Jetson은 display·keyboard를 계속 연결한 상태보다 network를 통해 접속하는 방식으로 다룬다. host PC에서 SSH로 Jetson Linux shell에 접속하고, VS Code Remote-SSH가 같은 SSH 연결을 사용해 remote file, terminal, build environment를 연다.

```text
host terminal / VS Code
  → SSH
  → Jetson Linux
      → package·runtime·application 실행
```

처음 SSH로 접속할 때 나오는 host key 확인은 접속 대상의 공개키를 local `known_hosts`에 등록하는 절차다. 대상 IP와 host key가 맞는 환경인지 확인한 뒤 한 번 수락하면, 같은 key를 쓰는 다음 접속에서는 다시 묻지 않는다.

```bash
ssh <user>@<jetson-ip>
sudo apt update
sudo apt upgrade
```

`sudo`는 Linux에서 관리자 권한으로 command를 실행한다. package update·upgrade는 Jetson의 package index와 설치 package를 갱신하는 작업이다. 수업에서 필요한 package version이 기본 image와 다를 때에는 notebook 또는 terminal에서 지정 version을 설치하고, Python session을 다시 시작한 뒤 import와 실행 결과를 확인한다.

DHCP network에서는 board가 다시 부팅되거나 다른 network에 연결될 때 IP가 바뀔 수 있다. 원격 접속을 반복하는 board는 DHCP reservation 또는 static IP를 정해 SSH target을 안정화할 수 있다. 현재 접속할 network의 gateway·subnet과 겹치지 않는 주소를 사용해야 한다.

### VS Code Remote-SSH

VS Code에는 `Remote - SSH` extension을 설치한다. 연결 target에는 terminal에서 쓰는 SSH command와 같은 `<user>@<jetson-ip>`를 등록한다. 연결이 성공하면 editor는 host PC에 남고, file access·terminal·build·run은 Jetson에서 실행된다.

```text
VS Code editor
  → Remote-SSH transport
  → Jetson의 source directory·terminal·Python environment
```

이 구분은 중요한 기준이다. VS Code 화면을 Mac 또는 Windows에서 보더라도 `python`, `pip`, CUDA library, camera device는 Jetson remote terminal 기준으로 확인한다.

## Browser frame과 OpenCV image의 경계

browser JavaScript와 Python/OpenCV는 image object를 그대로 공유하지 않는다. frame은 encoding을 거쳐 전달하고, 수신한 쪽이 자기 runtime의 image 형태로 복원한다.

| 단계 | data 형태 | 역할 |
| :--- | :--- | :--- |
| webcam capture | browser video frame | local camera input 획득 |
| 전달 | Base64 text | JavaScript와 Python 사이 전달 가능한 문자열 표현 |
| Python decode | byte buffer | encoded image byte 복원 |
| OpenCV decode | BGR `ndarray` | grayscale·detection·drawing 입력 |
| 결과 전달 | encoded image → Base64 | browser display용 frame 반환 |

Base64는 image analysis를 위한 색 공간이나 압축 algorithm이 아니다. binary data를 text channel로 전달하기 위한 encoding이다. browser에서 받은 Base64 data를 decode한 뒤 `cv2.imdecode()`로 OpenCV image를 만들고, 처리 결과는 `cv2.imencode()`와 Base64 encoding을 거쳐 browser에 돌려준다.

OpenCV의 기본 color channel order는 `BGR`이고, browser canvas와 일반 image 표현은 보통 `RGB` 또는 `RGBA`를 사용한다. 이 순서를 구분하지 않으면 red와 blue가 바뀐 화면이 나온다.

```text
browser RGB/RGBA frame
  → decode
  → OpenCV BGR image
  → grayscale for detection
  → BGR overlay result
  → browser RGB/RGBA display
```

## Haar Cascade 얼굴 검출

Haar cascade는 OpenCV가 제공하는 전통적인 object detection classifier다. 정면 얼굴, 측면 얼굴처럼 찾을 대상에 맞는 XML cascade file을 선택한다. 여기서는 정면 얼굴 cascade를 사용해 webcam frame에서 얼굴 영역을 찾는다.

```python
gray = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2GRAY)
faces = cascade.detectMultiScale(gray)

for x, y, w, h in faces:
    cv2.rectangle(frame_bgr, (x, y), (x + w, y + h), color, thickness)
```

`detectMultiScale()`의 각 결과는 `(x, y, w, h)`다.

| 값 | 의미 |
| :--- | :--- |
| `x`, `y` | bounding box 좌상단 좌표 |
| `w`, `h` | bounding box 너비·높이 |
| `(x + w, y + h)` | OpenCV rectangle의 우하단 좌표 |

Haar cascade는 grayscale image를 input으로 사용한다. 색 자체보다 밝기 변화와 edge-like feature를 이용해 후보 영역을 찾기 때문이다. 얼굴이 여러 개면 결과 list에도 여러 bounding box가 들어오며, 각각을 순회해 사각형과 label을 그린다.

### Overlay와 alpha channel

검출 결과는 원본 frame 위에 직접 그릴 수도 있고, 별도의 RGBA overlay에 그린 뒤 합성할 수도 있다. RGBA는 `R`, `G`, `B`, `A` 네 channel이며 `A`는 투명도를 뜻한다. 여러 얼굴의 bounding box, label, FPS text를 overlay에 모아 두면 원본 image와 표시 요소를 분리해 다룰 수 있다.

| 표시 요소 | 필요한 정보 |
| :--- | :--- |
| bounding box | `(x, y, w, h)`와 line color·thickness |
| label | text, 기준 좌표, font·color |
| FPS | 최근 frame 간 시간 차이 |
| 반투명 영역 | RGBA color와 alpha 값 |

## Frame loop와 FPS

영상 처리의 한 cycle은 frame 하나를 받아 처리한 뒤 결과를 돌려주는 흐름이다.

```text
frame request
  → browser capture
  → OpenCV decode·face detection
  → bounding box·label·FPS draw
  → browser display
  → next frame request
```

FPS는 최근 frame 처리 간격 `dt`로 계산한다.

```text
fps = 1 / dt
```

frame을 request한 뒤 detection 결과를 받아 화면에 표시하는 동안 다음 frame이 camera에서 들어온다. detection은 이전 frame 기준인데 overlay는 더 최근 frame에 그리면 box가 얼굴을 약간 늦게 따라가는 것처럼 보일 수 있다. 이는 logic error가 아니라 `capture → transfer → inference → render` 지연이 누적된 결과다.

## On-Device AI와의 연결

이 실습은 model 자체를 학습하는 CNN 단계 다음에, image input과 inference result가 제품 화면까지 이동하는 경로를 보여 준다.

```text
camera input
  → image representation·preprocessing
  → detection / inference
  → bounding box·label·FPS
  → display 또는 robot control decision
```

Colab webcam 실습에서는 browser JavaScript와 Python runtime 사이에 Base64 전달 경계가 있다. Jetson에서는 camera driver·OpenCV 또는 GStreamer pipeline·AI runtime이 같은 Linux system 안에서 연결된다. 이후 TensorRT engine, Jetson camera input, hardware acceleration을 붙이면 같은 제품 흐름에서 latency와 power를 더 직접적으로 다룰 수 있다.

## 실습 확인 항목

- SSH에서 Jetson user·IP로 접속되는지 확인
- VS Code Remote-SSH가 Jetson의 source directory와 terminal을 여는지 확인
- webcam permission을 허용한 뒤 browser frame이 들어오는지 확인
- BGR/RGB channel order 때문에 색이 뒤바뀌지 않는지 확인
- grayscale image로 cascade input을 만들었는지 확인
- 여러 얼굴에서 `(x, y, w, h)`별 rectangle이 각각 표시되는지 확인
- FPS 계산값과 bounding box 지연을 함께 관찰
