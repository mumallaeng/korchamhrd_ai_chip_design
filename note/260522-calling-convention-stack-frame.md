# 26-05-22 - calling convention, stack frame, 함수 호출을 hardware로 읽기

핵심은 ABI 표를 암기하는 것이 아니라, 실제 machine code와 파형에서 `함수 호출이 어떻게 보이는가`를 잡는 것이다.
`lecture_RV32I`와 `20260519_rv32i`의 memory file에는 이미 `main`, `adder`, `sort`, `swap` 같은 함수 흐름이 들어 있으므로, calling convention과 stack frame을 추상 이론이 아니라 실제 실행 흔적으로 읽을 수 있다.

## calling convention을 실행 흐름으로 이해하는 법

calling convention은 `누가 어떤 register를 인자로 쓰고`, `누가 어떤 값을 저장/복구해야 하며`, `함수가 끝난 뒤 어디로 돌아가는가`를 정하는 약속이다.  
CPU 하드웨어는 그 약속을 이해해서 특별대우하는 것이 아니라, 그 규약에 맞춰 생성된 instruction을 그대로 실행한다.

즉 software와 hardware의 관계를 이렇게 보면 된다.

- compiler는 calling convention에 맞춰 machine code를 만든다.
- instruction memory는 그 machine code를 공급한다.
- CPU는 `jal`, `jalr`, `lw`, `sw`, `addi` 같은 instruction을 순서대로 실행한다.
- 그 결과 software 입장에서는 함수 호출과 복귀가 정상 동작한 것처럼 보인다.

## 먼저 기억할 register

전체 ABI 표를 다 외우기보다, 현재 예제를 읽는 데 꼭 필요한 것부터 잡으면 된다.

- `x0`: 항상 `0`
- `x1 (ra)`: return address
- `x2 (sp)`: stack pointer
- `x8 (s0/fp)`: frame pointer로 자주 쓰임
- `x10 ~ x17 (a0 ~ a7)`: 함수 인자와 return value
- `t` 계열 register: 임시 계산용

이 정도만 알아도 `main -> adder`, `sort -> swap` 흐름을 읽는 데 충분하다.

## memory file에서 stack frame이 보이는 패턴

memory file 숫자가 함수 프롤로그와 에필로그로 어떻게 보이는지가 핵심이다.

### stack pointer 초기화

프로그램 시작 직후의 첫 instruction은 `sp` 시작 위치를 잡는 역할을 한다.

- `lecture_RV32I`의 `instruction_code.mem`은 `40000113`으로 시작한다.
- `20260519_rv32i`의 `instruction_code.mem`과 `instruction_code_2.mem`은 `10000113`으로 시작한다.

운영체제 없이 실행하는 학습용 환경에서는 OS가 stack을 자동 준비해 주지 않으므로, 프로그램 시작 코드가 직접 `sp`를 적당한 data memory 영역으로 옮겨 놓는다.

### frame 확보

그 다음 바로 보이는 값이 `fe010113` 또는 `fd010113` 같은 instruction이다.  
이 패턴은 `addi sp, sp, -imm` 계열로 읽으면 된다.  
즉 함수 진입 시 stack을 아래로 내리면서 지역 변수와 저장 register를 놓을 frame 공간을 확보하는 것이다.

### 저장과 복구

프롤로그에서는 `ra`, `s0` 같은 값을 stack에 저장하는 `sw` 패턴이 이어진다.  
함수 끝에서는 반대로 `lw`로 다시 읽어 온 뒤 `sp`를 원래대로 복구하고 `jalr`로 돌아간다.

즉 machine code를 큰 흐름으로 읽으면 아래 순서를 계속 확인하게 된다.

```text
sp 초기화
-> 함수 진입
-> sp 감소
-> ra / s0 저장
-> 지역 변수 사용
-> ra / s0 복구
-> sp 증가
-> jalr 로 복귀
```

`00008067`이 반복해서 보이는 이유도 여기에 있다.  
이 값은 함수 복귀 패턴인 `ret`에 해당한다.

## `sum_counting.c`에서 stack과 함수 호출 읽기

`sum_counting.c`는 짧은 코드지만 stack frame과 함수 호출의 최소 형태를 잘 보여 준다.

```c
int adder(int a, int b);
void main(void){
    int a=0;
    int sum=0;
    while(a<10){
        a=a+1;
        sum=adder(a,sum);
    }
}
```

이 코드에서 하드웨어로 번역되면 다음 일이 일어난다.

- 지역 변수 `a`, `sum`을 stack frame 안쪽 offset에 둔다.
- loop마다 값을 `lw`로 읽고, `addi`와 `add`로 계산하고, 다시 `sw`로 저장한다.
- `adder(a, sum)` 호출 직전에는 인자값을 인자 register 쪽으로 옮기거나 stack에서 준비한다.
- `jal`로 `adder`에 들어간다.
- `adder`는 결과를 계산한 뒤 `a0` 쪽 return value로 넘기고 `jalr`로 복귀한다.

즉 `while + 지역 변수 + 함수 호출`만 있어도 CPU는 branch, stack, call/return, register 전달을 전부 써야 한다.

## `buble_sort.c`에서 더 명확하게 보이는 것

`buble_sort.c`는 함수 호출 규약이 왜 필요한지를 더 잘 보여 준다.

```c
void sort(int *pNum, int size);
void swap(int *a, int *b);
```

이 예제는 다음 이유로 더 복잡하다.

- `main`이 `sort`를 호출한다.
- `sort` 안에서 `swap`을 다시 호출한다.
- 지역 배열 `Num[6]`가 stack에 놓인다.
- `i`, `j`, `temp` 같은 지역 변수도 별도 stack slot이 필요하다.
- 포인터와 배열 주소 계산이 계속 일어난다.

즉 `sort`는 단순 계산 함수가 아니라, `중첩 함수 호출 + 지역 배열 + 반복문 + 조건문`이 결합된 전형적인 software 예제다.

## 배열과 포인터가 machine code에서 보이는 방식

bubble sort를 C 코드만 보면 `pNum[j]`, `pNum[j+1]`처럼 간단해 보이지만, RTL 관점에서는 꽤 많은 단계가 필요하다.

대체로 아래 순서로 읽으면 된다.

1. base pointer 또는 frame pointer에서 배열 시작 주소를 찾는다.
2. index를 `4`배 해서 word offset을 만든다.
3. base 주소와 offset을 더해 element 주소를 만든다.
4. `lw`로 값을 읽는다.
5. 비교 결과에 따라 branch한다.
6. 필요하면 `swap`에 포인터 두 개를 인자로 넘긴다.
7. `swap`은 그 포인터 주소를 다시 `lw/sw`로 역참조해서 값을 바꾼다.

즉 배열과 포인터는 추상 개념이 아니라, 하드웨어 수준에서는 결국 `주소 계산 + 메모리 접근`의 반복이다.

## branch, jump, return이 control-flow를 만든다

software의 `if`, `for`, `while`은 결국 special hardware loop가 아니라 branch와 jump의 조합이다.

- `if`: 비교 후 조건 branch
- `for`: 초기화 후 조건 검사, 본문 실행, 증가, 뒤로 branch
- `while`: 조건 검사 후 branch, 본문 끝에서 다시 뒤로 jump
- 함수 호출: `jal`
- 함수 복귀: `jalr`

따라서 파형에서 `pc_out`을 보면 straight line으로만 증가하지 않고, loop back edge와 call target, return target으로 이동하는 순간이 보여야 한다.

## 하드웨어 파형에서 확인할 신호

프로그램 실행을 파형으로 읽을 때는 아래 신호가 핵심이다.

- `pc_out` 또는 `instr_addr`: 지금 함수 안의 어느 위치를 실행 중인지
- `instr_code`: 현재 instruction이 branch인지, load/store인지, `jal/jalr`인지
- `alu_result`: 주소 계산이나 비교 전에 나온 중간 결과
- `rf_we`, `waddr`, `wdata`: 함수 인자와 return value가 어느 register로 가는지
- `daddr`, `dwdata`, `drdata`: stack slot과 배열 원소 접근이 어디서 일어나는지
- `mem_mode`, `dwe`: `lw/sw` 중심 접근이 언제 발생하는지

즉 software에서 말하는 `지역 변수`, `배열`, `포인터`, `함수 호출`은 파형에서 각각 `stack 주소`, `주소 계산`, `load/store`, `PC 변화`로 나타난다.

## 핵심 정리

RV32I CPU가 범용 CPU처럼 보이기 시작하는 지점은 ALU 연산이 아니라 함수 호출과 stack frame을 감당하는 순간이다.  
`sum_counting.c`와 `buble_sort.c`가 돌아간다는 말은, 이 코어가 단순 연산기에서 한 단계 올라가 software 실행 흐름을 따라갈 수 있는 구조를 갖추었다는 뜻이다.

## 연결 노트

- [[260521-c-to-instruction-memory]]
- [[260519-rv32i-datapath]]
