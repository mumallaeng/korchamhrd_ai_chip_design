# Day6 FSM Block Diagram

```mermaid
flowchart LR
    SW[sw[2:0]]
    CLK[clk]
    RST[rst]

    NS[next-state logic]
    SR[state register<br/>negedge clk]
    OD[output decode]
    LED[led[2:0]]

    SW --> NS
    SR --> NS
    NS --> SR
    CLK --> SR
    RST --> SR
    SR --> OD
    OD --> LED
```

검증 기준은 다음과 같이 맞춘다.

- 시뮬레이션/비트스트림 공통 시나리오: `A -> B -> C -> D -> E -> A -> C -> D -> A -> C -> D -> B`
- 명시되지 않은 입력에서는 `next-state logic`이 현재 상태를 그대로 유지
- `rst` 입력은 `state register`를 즉시 `STATE_A`로 초기화
