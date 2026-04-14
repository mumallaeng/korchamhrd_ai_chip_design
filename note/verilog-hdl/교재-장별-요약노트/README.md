# Verilog HDL 교재 장별 요약 노트

## 목적

이 폴더는 `Verilog HDL 설계 - Vivado와 FPGA를 이용한 설계 실습` 교재를 책 없이도 학습할 수 있도록 장별로 재구성한 요약 노트다.

책 전문을 직접 읽고 옮긴 문서가 아니라, 공개적으로 확인 가능한 세부 목차와 신뢰 가능한 보조 자료를 바탕으로 다시 쓴 요약 노트다.

현재 산출물은 다음을 합쳐 만든 목차 기반 요약 구조다.

- 로컬 노트 [[교재 정보]]
- 공개 목차 정보
- 현재 수강 중인 Verilog HDL 강의 노트와 과제 결과
- 공개적으로 접근 가능한 보조 자료

## 작성 원칙

- 각 장은 교재 세부 목차를 먼저 고정한 뒤 그 목차에 맞춰 핵심 내용을 요약했다.
- 책 내용을 그대로 재현하지 않고, 공개 자료로 확인 가능한 범위 안에서 이해 중심으로 다시 썼다.
- 신뢰도는 `공식 문서 > 대학/교육 자료 > 검증된 기술 블로그` 순서로 두었다.
- 내용이 겹치는 부분은 중복 암기 대신 `조합/순차`, `RTL/testbench`, `보드/툴 흐름`, `상태/시간` 축으로 묶어 설명했다.

## 공통 공개 보조 자료

- 교재 소개 및 세부 목차:
  - 한빛 공식 도서 페이지: https://www.hanbit.co.kr/store/books/look.php?p_code=B7241537082
  - Google Books: https://books.google.com/books/about/Verilog_HDL_%EC%84%A4%EA%B3%84_Vivado%EC%99%80_FPGA%EB%A5%BC_%EC%9D%B4.html?id=ph7HEAAAQBAJ
  - KBOOKSTORE 상세 목차: https://kbookstore.com/product/verilog-hdl-9791156646617/
- Basys3 Reference Manual:
  - Digilent PDF: https://digilent.com/reference/_media/reference/programmable-logic/basys-3/basys3_rm.pdf
- Vivado 흐름:
  - AMD UG892 Design Flows Overview: https://docs.amd.com/r/2024.2-English/ug892-vivado-design-flows-overview/
  - AMD Design Entry & Implementation Overview: https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/vivado/implementation.html
- Verilog 연습:
  - HDLBits Main: https://hdlbits.01xz.net/wiki/Main_Page
  - HDLBits Problem Sets: https://hdlbits.01xz.net/wiki/Problem_sets
- 문법 보조:
  - VerilogPro always block: https://www.verilogpro.com/verilog-always-block/
  - VerilogPro module: https://www.verilogpro.com/verilog-module-for-design-and-testbench/
  - VerilogPro case/casez/casex: https://www.verilogpro.com/verilog-case-casez-casex/
  - VerilogPro generate: https://www.verilogpro.com/verilog-generate-configurable-rtl/

## 현재 강의와의 연결

- Day1-Day6 강의 노트: `[[verilog-hdl_수업메모_00]]` ~ `[[verilog-hdl_수업메모_06]]`
- 복습 노트: `[[verilog-hdl_복습노트_01_설계흐름]]`, `[[verilog-hdl_복습노트_02_wire-reg-4state]]`, `[[verilog-hdl_복습노트_03_basys3-xdc-constraints]]`
- 학습 패키지: `[[study-system/source-packet]]`, `[[study-system/study-progress]]`, `[[study-system/review-register]]`
