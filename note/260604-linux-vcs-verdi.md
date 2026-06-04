# 26-06-04 - Linux CLI와 VCS/Verdi 실행 환경

Linux CLI는 Verilog/SystemVerilog 실습에서 파일을 관리하고 EDA tool을 실행하기 위한 기본 작업 환경이다.
VCS로 compile/simulation을 수행하고 Verdi로 waveform을 확인하려면 directory 이동, 파일 확인, 권한, pipe/redirection, editor 사용을 먼저 익혀야 한다.

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 주제 | Linux 기본 명령어, 원격 접속, 파일 관리, VCS compile/simulation, Verdi waveform |
| 환경 | RHEL/CentOS 계열 Linux, MobaXterm 원격 접속, Synopsys VCS/Verdi |
| 핵심 흐름 | 접속 -> 작업 directory 이동 -> source 확인 -> compile -> simulation -> waveform 확인 |
| 남길 기준 | 명령어는 외우기보다 현재 위치, 대상 파일, 출력 위치를 먼저 확인하고 실행 |

## 원격 접속과 작업 위치

Linux 실습은 원격 서버에 접속해서 shell에서 명령을 실행하는 흐름으로 보면 된다.

| 항목 | 내용 |
| --- | --- |
| 접속 도구 | MobaXterm |
| Remote host | `10.10.20.251` |
| Port | `20022` |
| Username | 할당받은 `peduXX` 계정 |
| 기본 위치 | `/home/peduxx`, `~`로도 표현 |

작업을 시작하면 먼저 `pwd`로 현재 위치를 확인하고, `ls`로 파일 목록을 본다.
source file, testbench file, simulation output이 어느 directory에 있는지 확인한 뒤 명령을 실행해야 한다.

## 기본 탐색 명령어

| 명령어 | 의미 | 자주 쓰는 형태 |
| --- | --- | --- |
| `pwd` | 현재 작업 directory 출력 | `pwd` |
| `cd` | directory 이동 | `cd ..`, `cd ~`, `cd project` |
| `ls` | 파일 목록 확인 | `ls`, `ls -al` |
| `whoami` | 현재 사용자 확인 | `whoami` |
| `hostname` | 접속한 host 이름 확인 | `hostname` |
| `uname -a` | kernel/OS 정보 확인 | `uname -a` |
| `date` | 현재 시간 확인 | `date` |
| `cat /etc/os-release` | 배포판 정보 확인 | `cat /etc/os-release` |

`ls -al`에서 첫 글자가 `d`이면 directory, `-`이면 일반 파일, `l`이면 symbolic link다.
숨김 파일은 이름이 `.`로 시작하며, shell 설정 파일인 `.bashrc`도 여기에 포함된다.

## 파일과 directory 관리

| 작업 | 명령어 | 의미 |
| --- | --- | --- |
| directory 생성 | `mkdir name` | 새 directory 생성 |
| 중간 경로까지 생성 | `mkdir -p path/to/dir` | 없는 상위 directory까지 함께 생성 |
| 빈 directory 삭제 | `rmdir name` | 내용이 없는 directory 삭제 |
| 파일 삭제 | `rm file` | 파일 삭제 |
| directory 강제 삭제 | `rm -rf dir` | 하위 내용까지 삭제하므로 대상 확인 필요 |
| 빈 파일 생성 | `touch file` | 파일 생성 또는 timestamp 갱신 |
| 복사 | `cp src dst` | 파일 복사 |
| directory 복사 | `cp -r src_dir dst_dir` | directory 전체 복사 |
| 이동/이름 변경 | `mv src dst` | 파일 이동 또는 이름 변경 |

`rm -rf`는 되돌리기 어렵다.
실행 전에 `pwd`와 `ls`로 현재 위치와 삭제 대상을 확인하는 습관이 필요하다.

## 파일 내용 확인

| 명령어 | 의미 |
| --- | --- |
| `cat file` | 파일 전체 출력 |
| `head -n 5 file` | 처음 5줄 출력 |
| `tail -n 10 file` | 마지막 10줄 출력 |
| `less file` | 페이지 단위로 보기, 종료는 `q` |
| `file file` | 파일 종류 확인 |
| `wc -l file` | 줄 수 확인 |
| `du -sh dir` | directory 크기 확인 |

simulation log처럼 긴 파일은 `cat`보다 `less`, `head`, `tail`로 먼저 보는 편이 안전하다.
error가 있는지 빠르게 볼 때는 `grep`과 pipe를 같이 쓴다.

## 검색, pipe, redirection

Linux 명령은 한 명령의 출력을 다음 명령의 입력으로 넘기거나 파일로 저장하면서 조합한다.

| 기능 | 명령어 / 기호 | 의미 |
| --- | --- | --- |
| 문자열 검색 | `grep pattern file` | file 안에서 pattern 검색 |
| 대소문자 무시 | `grep -i pattern file` | 대소문자 구분 없이 검색 |
| 하위 directory 검색 | `grep -r pattern dir` | directory 전체 검색 |
| 파일 찾기 | `find . -name '*.sv'` | 이름 조건으로 파일 검색 |
| 실행 파일 위치 | `which vcs` | PATH에서 실행 파일 위치 확인 |
| pipe | `cmd1 | cmd2` | 앞 명령 출력을 뒤 명령 입력으로 전달 |
| overwrite 저장 | `cmd > file` | 출력 파일 덮어쓰기 |
| append 저장 | `cmd >> file` | 출력 파일 끝에 추가 |
| 정렬 | `sort` | 결과 정렬 |
| 중복 제거 | `uniq` | 연속 중복 제거 |

예를 들어 compile log에서 error만 찾으려면 아래처럼 읽는다.

```shell
grep -i error compile.log
```

여러 파일에서 module 이름을 찾을 때는 아래 흐름이 기본이다.

```shell
find . -name '*.sv' | xargs grep -n 'module_name'
```

## 권한, process, system 상태

| 주제 | 명령어 | 의미 |
| --- | --- | --- |
| 권한 확인 | `ls -l` | 파일 종류, 소유자, 권한 확인 |
| 권한 변경 | `chmod 755 file` | `r=4`, `w=2`, `x=1` 조합으로 권한 부여 |
| 소유자 변경 | `chown user:group file` | 파일 소유자/그룹 변경 |
| process 목록 | `ps -ef`, `ps aux` | 실행 중인 process 확인 |
| 실시간 확인 | `top` | CPU/memory 사용량 확인 |
| process 종료 | `kill PID`, `kill -9 PID` | process 종료 |
| disk 사용량 | `df -h` | filesystem 사용량 확인 |
| memory 사용량 | `free -h` | memory 상태 확인 |
| 명령 기록 | `history` | 이전 실행 명령 확인 |

permission string은 user/group/others 세 묶음으로 읽는다.
예를 들어 `755`는 owner는 `rwx`, group과 others는 `r-x` 권한을 갖는다는 뜻이다.

## vi/vim 기본 조작

vi/vim은 mode를 구분해서 쓰는 editor다.

| 동작 | 키 |
| --- | --- |
| 입력 모드 진입 | `i` |
| 명령 모드 복귀 | `Esc` |
| 저장 | `:w` |
| 종료 | `:q` |
| 저장 후 종료 | `:wq` |
| 저장하지 않고 종료 | `:q!` |
| 한 줄 삭제 | `dd` |
| 복사 / 붙여넣기 | `yy`, `p` |
| 실행 취소 | `u` |
| 이동 | `h`, `j`, `k`, `l` |

설정 파일이나 compile script를 수정할 때는 저장 여부가 중요하다.
잘못 열었거나 수정 내용을 버려야 하면 `:q!`로 종료한다.

## network, 압축, 도움말

| 주제 | 명령어 | 의미 |
| --- | --- | --- |
| IP 확인 | `ip addr` | network interface와 IP 확인 |
| 열린 port 확인 | `ss -tlnp` | listening port 확인 |
| 연결 테스트 | `ping host` | host 응답 확인 |
| HTTP 요청 | `curl URL`, `wget URL` | 파일 다운로드 또는 응답 확인 |
| 원격 접속 | `ssh user@host` | ssh 접속 |
| 파일 전송 | `scp src user@host:path` | 원격 복사 |
| tar 압축 | `tar czvf file.tar.gz dir` | gzip tar archive 생성 |
| tar 해제 | `tar xzvf file.tar.gz` | gzip tar archive 해제 |
| zip 압축 | `zip -r file.zip dir` | zip 생성 |
| zip 해제 | `unzip file.zip` | zip 해제 |
| 도움말 | `man cmd`, `cmd --help`, `info cmd` | 명령어 사용법 확인 |

처음 보는 명령은 바로 실행하기보다 `--help`나 `man`으로 option 의미를 먼저 확인한다.

## VCS compile과 simulation

VCS는 Verilog/SystemVerilog source와 testbench를 compile해 simulation 실행 파일을 만든다.
가장 기본 흐름은 compile 후 `./simv` 실행이다.

```shell
vcs -full64 -sverilog -debug_access+all -kdb -lca \
  -timescale=1ns/1ps \
  -o simv \
  design.sv tb_design.sv
```

| option | 의미 |
| --- | --- |
| `-full64` | 64-bit mode 사용 |
| `-sverilog` | SystemVerilog 문법 활성화 |
| `-debug_access+all` | debug 접근 정보 생성 |
| `-kdb` | Verdi 연동용 debug database 생성 |
| `-lca` | Synopsys 일부 feature 사용 조건 |
| `-timescale=1ns/1ps` | simulation time unit/precision 지정 |
| `-o simv` | 생성할 simulation 실행 파일 이름 지정 |

simulation은 아래처럼 실행한다.

```shell
./simv
```

파형을 남기도록 testbench가 설정되어 있으면 `wave.fsdb` 같은 waveform file이 생성된다.
compile error는 source/testbench 문법 문제이고, simulation fail은 testbench의 기대값 비교나 DUT 동작 문제로 구분해서 봐야 한다.

## Verdi waveform 확인

Verdi는 simulation 결과를 waveform과 source hierarchy로 확인하는 debug tool이다.

```shell
verdi -dbdir ./simv.daidir -ssf wave.fsdb
```

| 항목 | 의미 |
| --- | --- |
| `simv.daidir` | VCS가 만든 debug database directory |
| `wave.fsdb` | simulation waveform file |
| hierarchy | module/testbench 계층 구조 |
| nWave | signal waveform 확인 창 |

VCS compile에서 debug 정보가 충분히 생성되어야 Verdi에서 source와 waveform을 함께 추적하기 쉽다.
MobaXterm 같은 GUI forwarding 환경에서는 Verdi 창이 뜨는지까지 확인해야 한다.

## UVM 실습과의 연결

UVM 실습으로 넘어가면 VCS option에 UVM library 설정이 추가된다.
0605의 UVM compile 명령은 아래처럼 이어진다.

```shell
vcs -full64 -sverilog -debug_access+all -kdb -lca \
  -ntb_opts uvm-1.2 \
  -timescale=1ns/1ps \
  {systemverilog_file}
```

즉 0604의 핵심은 Linux 명령어 자체보다, EDA tool을 실행할 수 있는 shell 작업 능력을 만드는 것이다.

## 주의점

| 오해 | 정리 |
| --- | --- |
| `pwd`, `ls`는 단순 기초 명령이다 | compile 대상과 output 위치를 확인하는 실습의 출발점이다 |
| `rm -rf`는 편한 삭제 명령이다 | 대상 확인 없이 쓰면 source나 결과물을 한 번에 지울 수 있다 |
| `cat`으로 모든 log를 보면 된다 | 긴 log는 `less`, `tail`, `grep`으로 필요한 부분부터 본다 |
| VCS compile과 simulation은 같은 단계다 | compile은 실행 파일 생성, simulation은 생성된 `simv` 실행이다 |
| Verdi는 source viewer만이다 | waveform, hierarchy, source를 연결해 hardware 동작을 추적하는 debug tool이다 |

## 핵심 정리

Linux CLI는 Verilog/SystemVerilog 실습의 작업대다.
현재 위치와 파일을 확인하고, shell 명령으로 source를 찾고, VCS로 compile/simulation을 실행한 뒤, Verdi로 waveform을 확인하는 흐름을 하나로 읽어야 한다.

## 연결 노트

- [[260605-uvm-adder]]
- [[260601-systemverilog-oop]]
