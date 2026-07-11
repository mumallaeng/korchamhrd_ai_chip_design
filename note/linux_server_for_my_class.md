# Linux 서버를 왜 사용하는가 - 공유 보충 노트

이 문서는 Linux 서버와 명령어 환경을 왜 사용하는지 설명하기 위한 공유 보충 노트이다. 핵심은 서버에서 반복 가능한 작업을 안정적으로 실행하기 위해 CLI가 기본 도구로 쓰인다는 점이다.

## 1. 서버란 무엇인가

서버는 다른 컴퓨터나 사용자에게 기능을 제공하는 컴퓨터 또는 프로그램이다.

| 구분 | 예시 |
|---|---|
| 파일 서버 | 여러 사람이 파일을 저장하고 가져감 |
| 웹 서버 | 브라우저 요청에 웹 페이지 응답 |
| 데이터베이스 서버 | 데이터를 저장하고 검색 |
| 라이선스 서버 | EDA tool 사용 권한 관리 |
| 계산 서버 | compile, simulation, synthesis 같은 무거운 작업 수행 |

여기서 말하는 Linux 서버는 보통 여러 사용자가 원격으로 접속해서 파일을 만들고, tool을 실행하고, 결과를 확인하는 공용 작업 컴퓨터에 가깝다.

## 2. 운영체제란 무엇인가

운영체제는 하드웨어와 프로그램 사이에서 자원을 관리하는 기본 시스템 소프트웨어이다.

kernel은 운영체제의 핵심 부분으로, process scheduling, memory 관리, device 접근처럼 하드웨어 자원을 직접 제어한다.

shell 또는 command interpreter는 사용자가 입력한 `cd`, `ls`, `make` 같은 명령어를 해석하고 필요한 program 실행을 운영체제에 요청한다.

운영체제가 관리하는 것:

- CPU 사용 시간
- memory
- file system
- process
- user와 permission
- network
- device

사용자는 editor, compiler, simulator 같은 프로그램을 실행하지만, 실제로는 운영체제가 process를 만들고 파일을 열고 memory와 CPU 시간을 배정한다.

## 3. 운영체제의 종류

| 계열 | 대표 예 |
|---|---|
| Windows | Windows 10/11, Windows Server |
| macOS | macOS |
| Linux | Ubuntu, Debian, Fedora, RHEL, CentOS, Rocky Linux |
| Unix 계열 | UNIX, BSD, Solaris, AIX, HP-UX |
| Embedded OS | FreeRTOS, Zephyr, embedded Linux |

반도체 EDA 환경에서는 Linux 계열 서버를 자주 사용한다.

## 4. Linux와 Unix

Unix는 오래된 다중 사용자, 다중 작업 운영체제 계열이다. Linux는 Unix 계열의 철학과 인터페이스를 따르는 오픈소스 운영체제 kernel이다.

Linux는 엄밀히 말하면 kernel이고, 실제 사용자는 Linux kernel과 GNU tool, shell, package manager 등을 묶은 Linux distribution을 사용한다.

예시:

- Ubuntu
- Debian
- RHEL
- CentOS
- Rocky Linux

EDA 환경에서는 보통 RHEL/CentOS 계열 Linux 환경을 많이 본다.

## 5. GUI가 있는데 왜 명령어를 쓰는가

GUI는 사람이 직접 보고 클릭하기 좋다. CLI는 반복 작업, 원격 작업, 자동화 작업에 강하다.

| GUI | CLI |
|---|---|
| 눈으로 확인하기 쉬움 | 명령을 기록하고 재사용하기 쉬움 |
| 한 번씩 클릭하는 작업에 편함 | 수백 번 반복할 작업에 편함 |
| 화면 환경 필요 | SSH만 있으면 원격 실행 가능 |
| 자동화가 어려운 경우 많음 | script로 자동화하기 좋음 |
| 결과 재현이 어려울 수 있음 | 같은 명령을 다시 실행 가능 |

예를 들어 Verilog simulation에서는 아래처럼 명령 하나로 compile과 simulation을 실행하면 기록과 재현이 쉽다.

```sh
vcs -full64 -sverilog -debug_access+all -o simv design.sv tb_design.sv
./simv
```

명령어는 작업을 정확히 반복하고 공유하기 위해 사용한다.

## 6. 서버에서 CLI가 중요한 이유

서버는 보통 모니터 앞에 앉아서 직접 사용하는 컴퓨터가 아니다. 여러 사람이 SSH로 접속해서 동시에 사용한다.

CLI가 중요한 이유:

- 느린 원격 접속에서도 사용 가능
- 작업 명령을 그대로 복사해서 재현 가능
- log 파일로 결과를 남기기 쉬움
- shell script로 자동 실행 가능
- 여러 simulation을 batch로 돌리기 쉬움
- GUI가 없는 서버에서도 실행 가능

원격 서버에서는 먼저 현재 위치와 파일을 확인하는 습관이 중요하다.

```sh
pwd
ls -al
whoami
hostname
```

## 7. Linux 서버를 주로 쓰는 이유

Windows Server도 서버 운영체제이다. 웹 서비스, 사내 인증, 파일 공유, 데이터베이스 같은 용도로 사용된다.

서버 점유율은 집계 기준에 따라 달라진다. 공개 웹사이트, cloud server, 사내 server, 매출 기준, workload 기준을 각각 따로 보아야 한다. 웹사이트 운영체제 통계에서는 Unix/Linux 계열 비중이 매우 크고 Windows 비중은 상대적으로 작게 관측된다. 이 통계는 웹사이트 기준 예시이다. 인터넷 서버와 개발 서버 문화는 Linux/Unix 계열 중심으로 발전했다.

반도체 설계와 검증 환경에서도 Linux 서버가 주류이다.

주요 이유:

| 이유 | 설명 |
|---|---|
| EDA tool 생태계 | Synopsys, Cadence, Siemens EDA tool은 Linux 환경을 기본 지원하는 경우가 많음 |
| open source 확장성 | Linux는 open source 기반이라 distribution, package, kernel option, driver, script 환경을 필요에 맞게 조합하기 쉬움 |
| batch 작업 | compile, simulation, regression을 shell script로 반복 실행하기 쉬움 |
| 원격 다중 사용자 | SSH 접속, permission, process 관리가 서버 작업에 적합 |
| automation | Makefile, shell, Python, Tcl과 연결하기 좋음 |
| HPC/compute farm | 많은 simulation job을 여러 서버에 나눠 돌리기 좋음 |
| license server 연동 | 공용 EDA license를 서버에서 관리하기 쉬움 |
| 보안 운영 | 계정 권한, SSH, firewall, package update, log monitoring을 세밀하게 설정하고 자동화하기 좋음 |

정리하면 Linux 서버를 주로 쓰는 이유는 서버 자동화, open source 생태계, EDA tool 지원, 다중 사용자 batch 작업 문화가 Linux 중심으로 발전했기 때문이다. 보안은 운영체제 이름보다 설정과 관리 수준에 따라 달라진다.

## 8. 반도체 설계와 검증에서 Linux를 쓰는 방식

반도체 설계/검증 흐름에서는 많은 파일과 tool이 연결된다.

예시 흐름:

```text
RTL 작성
-> testbench 작성
-> compile
-> simulation
-> waveform 확인
-> log 분석
-> 수정 후 반복
```

Linux 서버에서는 이 흐름을 명령어로 실행한다.

예시:

```sh
vcs -full64 -sverilog -debug_access+all -kdb -o simv rtl/*.sv tb/*.sv
./simv -l sim.log
verdi -dbdir ./simv.daidir -ssf wave.fsdb
```

자주 사용하는 도구:

| 도구 | 역할 |
|---|---|
| shell | 명령 실행 환경 |
| editor | source 수정 |
| Makefile | compile/simulation 명령 자동화 |
| VCS/Xcelium/Questa | HDL simulation |
| Verdi/SimVision/Questa GUI | waveform debug |
| grep/rg/find | log와 source 검색 |
| Python/Tcl | 자동화 script |

GUI tool도 사용한다. 다만 GUI는 waveform 확인이나 project 설정처럼 사람이 직접 봐야 하는 작업에 사용하고, compile/simulation/regression은 CLI로 실행하는 경우가 많다.

## 9. Linux 서버를 사용할 때의 기본 흐름

```text
1. SSH로 서버 접속
2. 작업 directory 이동
3. source file 확인
4. compile 명령 실행
5. simulation 실행
6. log에서 error 확인
7. waveform이 필요하면 GUI tool 실행
8. source 수정 후 반복
```

명령 예시:

```sh
ssh user@server
pwd
ls
cd lecture/project
make
grep -i error compile.log
./simv
```

## 10. 기억할 문장

- 서버는 여러 사용자가 원격으로 접속해 작업을 실행하는 공용 작업 환경이다.
- 운영체제는 CPU, memory, file, process, device를 관리한다.
- Linux는 반도체 EDA tool과 자동화 작업에서 주류 환경이다.
- CLI는 반복 가능성과 자동화 때문에 서버 작업의 기본 도구로 쓰인다.
- Windows Server도 서버 운영체제지만, 반도체 설계/검증 tool chain은 Linux 중심인 경우가 많다.
- GUI는 확인과 debug에 유용하고, CLI는 실행과 반복 작업에 유용하다.
