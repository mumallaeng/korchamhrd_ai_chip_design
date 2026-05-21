# 26-05-21 - C 코드가 instruction memory로 들어오기까지

RV32I 회로를 볼 때는 `명령어 형식`만이 아니라 `실제 프로그램이 어떻게 올라오는가`까지 함께 봐야 한다.
핵심은 C 코드를 그대로 CPU가 이해하는 것이 아니라, compiler와 assembler를 거쳐 machine code가 되고, 그 결과를 `.mem` 파일에 넣어 instruction memory가 읽는다는 점이다.

## C 코드가 instruction memory로 들어가는 흐름

실제 흐름은 아래와 같다.

```text
C code
-> compiler / assembler
-> machine code hex
-> instruction_code.mem 또는 instruction_code_2.mem
-> $readmemh(...)
-> instruction memory
-> RV32I CPU 실행
```

즉 CPU는 C를 해석하지 않는다.  
CPU가 실제로 보는 것은 `32비트 machine code word`의 연속뿐이다.

`lecture_RV32I`와 `20260519_rv32i` 모두 instruction memory 안에서 `$readmemh(...)`를 사용하고 있으므로, RTL 자체를 바꾸지 않아도 `.mem` 파일만 바꾸면 다른 프로그램을 실행할 수 있다.

## `sum_counting.c`가 보여 주는 가장 작은 프로그램 흐름

`20260519_rv32i/compile_code/sum_counting.c`는 매우 짧지만, 범용 CPU가 필요한 이유를 잘 보여 준다.

```c
int adder(int a, int b);
void main(void){
    int a=0;
    int sum=0;
    while(a<10){
        a=a+1;
        sum=adder(a,sum);
    }
    return;
}
```

이 코드가 의미하는 동작은 단순하다.

- 지역 변수 `a`, `sum`이 필요하다.
- `while(a < 10)` 비교가 필요하다.
- `a = a + 1` 갱신이 필요하다.
- `adder(a, sum)` 함수 호출과 복귀가 필요하다.

즉 이 정도 작은 C 코드만 올라와도 CPU는 이미 다음을 지원해야 한다.

- `ADDI`, `ADD`
- 비교와 branch
- `JAL`, `JALR`
- stack pointer와 함수 프롤로그/에필로그
- 지역 변수용 load/store

## memory file에서 바로 보이는 포인트

`20260519_rv32i`의 `instruction_code.mem` 첫 줄은 `10000113`이다.  
이 값은 `sp`를 초기화하는 의미로 읽으면 된다.  
운영체제 없이 실행하는 학습용 환경에서는 stack을 자동으로 잡아 주는 주체가 없으므로, 프로그램 시작 시 software가 직접 `sp` 시작 위치를 세팅한다.

그 다음에 나오는 `fe010113` 같은 값은 함수 진입 시 stack frame 공간을 확보하는 패턴으로 이어진다.  
뒤쪽의 `028000ef` 같은 word는 다른 함수로 jump하면서 복귀 주소를 남기는 `jal` 패턴이다.  
마지막 `00008067`은 함수 복귀에 해당하는 `jalr x0, 0(ra)` 패턴으로 읽을 수 있다.

즉 memory file을 그냥 숫자 모음으로 보면 안 되고, 아래 흐름이 계속 보이는지 확인해야 한다.

```text
sp 초기화
-> stack frame 확보
-> 지역 변수 접근
-> 비교와 branch
-> jal로 함수 호출
-> jalr로 복귀
```

`lecture_RV32I`의 `instruction_code.mem`도 구조는 거의 같다.  
차이는 stack 시작 위치가 더 크게 잡혀 있다는 점 정도이고, 기본적인 `main -> adder 호출 -> return` 패턴은 동일하다.

## `buble_sort.c`가 왜 중요한가

`20260519_rv32i/compile_code/buble_sort.c`는 훨씬 더 풍부한 software 패턴을 RV32I에 실어 본 예제다.

```c
void sort(int *pNum, int size);
void swap(int *a, int *b);
void main (void) {
    int Num[6] = {3,5,9,1,7};
    int a = 0; 
    sort(Num,5);
    a = 0x12345678;
    while(1);
}
```

이 예제에서 같이 보게 되는 개념은 다음과 같다.

- 지역 배열 `Num[6]`
- 포인터 인자 전달
- 중첩 `for` loop
- `if` 비교문
- `swap` 함수 호출
- 무한 루프

즉 단순 덧셈 예제에서 보이지 않던 `배열 주소 계산`, `포인터 역참조`, `중첩 branch`, `함수 내부의 또 다른 함수 호출`까지 모두 한 프로그램에 들어온다.

## `instruction_code_2.mem`을 읽을 때 보이는 것

`instruction_code_2.mem`은 bubble sort 프로그램이 machine code로 내려간 결과다.  
처음 부분을 흐름으로 읽으면 아래와 같다.

- `sp` 초기화
- 더 큰 stack frame 확보
- 지역 배열 원소 `3, 5, 9, 1, 7`를 stack 쪽 메모리에 저장
- 배열 시작 주소와 크기를 인자로 준비
- `jal`로 `sort` 호출
- 정렬 이후 상수 `0x12345678` 저장
- `while(1)`에 해당하는 무한 루프 진입

그 안쪽 함수로 들어가면 다시 아래 패턴이 반복된다.

- `sort` 진입 프롤로그
- loop index 저장/갱신
- `pNum[j]`, `pNum[j+1]` 주소 계산
- `lw`로 값 읽기
- 비교 결과에 따라 branch
- 필요하면 `swap` 호출
- 함수 종료 시 저장했던 값 복구 후 `ret`

즉 bubble sort는 software 알고리즘 설명 자체보다, `하나의 RV32I CPU가 함수 호출과 메모리 접근이 있는 실제 프로그램을 실행할 수 있는가`를 확인하는 예제라고 보면 된다.

## instruction memory 주석과 `.mem` 파일을 같이 봐야 하는 이유

학습용 `instruction_mem.sv` 안에는 간단한 ALU 연산, load/store, branch/jump 예제가 주석으로 남아 있다.
하지만 실제 시뮬레이션에서는 `$readmemh`가 더 우선한다.  
즉 주석 예제는 instruction 형식을 설명하는 교재 역할이고, `.mem` 파일은 실제 실행 프로그램 역할이다.

이 둘을 섞어 읽으면 다음처럼 정리할 수 있다.

- 주석 예제는 `이 명령어가 어떤 비트 패턴인지`를 설명한다.
- `.mem` 파일은 `그 비트 패턴들이 실제 프로그램으로 어떻게 연결되는지`를 보여 준다.

## 하드웨어 파형에서 어떤 신호를 보면 되는가

software 프로그램을 하드웨어 신호로 읽을 때는 아래 신호가 핵심이다.

- `instr_addr` 또는 `pc_out`: 지금 어느 instruction 주소를 실행 중인지
- `instr_code`: 현재 명령어 word
- `rf_we`, `waddr`, `wdata`: 어떤 register에 무엇을 쓰는지
- `daddr`, `dwdata`, `drdata`: data memory에 어떤 주소로 접근하는지
- `dwe`, `mem_mode`: load/store 종류와 접근 크기

즉 software에서 보이는 `변수`, `반복문`, `함수 호출`은 파형에서는 결국 `PC 변화`, `register 값 변화`, `memory access`로 번역되어 나타난다.

## 핵심 정리

범용 CPU 공부는 instruction 형식을 외우는 것에서 끝나지 않는다.  
C 코드가 machine code가 되어 `.mem` 파일에 들어오고, 그 결과가 instruction memory를 통해 RTL에 공급될 때 비로소 `이 CPU가 프로그램을 실행한다`는 말이 성립한다.

## 연결 노트

- [[260520-rv32i-memory-writeback]]
- [[260522-calling-convention-stack-frame]]
