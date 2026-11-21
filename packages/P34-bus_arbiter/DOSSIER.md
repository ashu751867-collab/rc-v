# P34 Bus arbiter (CPU vs DMA) - dossier

## U1 Digital logic 
My block is purely combinational. One input, dma_req, decides who controls the bus. This is the truth table for the control signals:
|dma_req|grant| stall|addr, wdata, we|be|
| :---: | :---: | :---: | :---: | :---: |
| 0 | 0 | 0 | CPU values | cpu_be |
| 1 | 1 | 1 | DMA values | 1111 |

Simplified expressions:
grant = dma_req and stall = dma_req
For each bit of addr, wdata and we: out = (dma_req · dma_bit) + (¬dma_req · cpu_bit), which is a 2-to-1 multiplexer
For each bit of be: be = dma_req + cpu_be_bit, because when dma_req is 1 the output is 1
I needed no flip-flops. The circuit uses only multiplexers, a constant F input and wires. No extra gates were needed, since each multiplexer already contains the AND and OR logic.

## U2 Digital components
My Digital circuit (the 4-bit version) uses only multiplexers, one constant and wires. There are four 2-to-1 multiplexers, one for each output that has to choose between the CPU and the DMA: addr, wdata, we and be.
Select input: the dma_req input is wired to the select pin of all four multiplexers. When it is 0, each multiplexer passes its input 0, the CPU signal. When it is 1, it passes input 1, the DMA signal.
Data inputs: for addr, wdata and we, input 0 comes from cpu_addr, cpu_wdata and cpu_we, and input 1 from dma_addr, dma_wdata and dma_we.
be multiplexer: input 0 is cpu_be and input 1 is a constant F (binary 1111), because a DMA transfer enables all four bytes.
grant and stall: these are wired straight to dma_req, with no component in between.
The circuit has no adders, decoders, registers or memory, because the block only selects between two sets of signals.

## U3 Data representation
I picked three test vectors from my 4-bit Digital test. All values are 4-bit patterns.
Vector 1 (L44), DMA wins: dma_req = 1, cpu_addr = 0, dma_addr = 3, dma_wdata = D, dma_we = 1, cpu_be = D.
Output: addr = 3, wdata = D, we = 1, be = F, grant = stall = 1.
Vector 2 (L46), CPU wins: dma_req = 0, cpu_addr = 5, cpu_we = 1, cpu_be = F, dma_addr = E.
Output: addr = 5, we = 1, be = F, grant = stall = 0.
Vector 3 (L47), CPU wins: dma_req = 0, cpu_addr = D, cpu_wdata = 5, cpu_we = 0, cpu_be = 6.
Output: addr = D, wdata = 5, we = 0, be = 6.
|Hex|Binary|Unsigned|Signed (4-bit)|
|:---:|:---:|:---:|:---:|
|3|0011|3|3||
|5|0101|5|5
|6|0110|6|6|
|D|1101|13|-3|
|F|1111|15|-1|

My block does no arithmetic, so it can't overflow. It copies bit patterns without changing them. The signed column only matters if someone reads D as a number, but an address and a byte-enable mask are not signed values. Where it could go wrong is width. My Digital circuit is 4 bits, while the Verilog is 32 bits for addresses and data, so the constant F for be is 4'hF in Verilog, which is still 4 bits. A wrong width on the constant would give the wrong byte enables. In Vector 1 the be output is F (1111) even though cpu_be was D (1101), because DMA overrides it.

## U4 Computer organisation
My block works in the memory step of the instruction cycle. In RC-V this is the step where lw and sw instructions reach memory. The CPU puts out an address, write data, a write-enable and byte enables, and my arbiter decides whether those, or the DMA's, go to memory.
The instructions that need it are the ones that touch memory: lw (load a word) and sw (store a word). My own program used both in its copy loop, and every one of those accesses passed through my block while the DMA was idle. Instructions that only use registers, such as AND or addi, don't need it.
The block also matters when the DMA controller wants the bus. It then takes over the memory step, and the CPU is stalled until the DMA is done. The block does no work in fetch, decode, execute or write-back, and it doesn't handle interrupts. Fetch reads ROM directly.

## U5 Processors
My arbiter is a purely combinational block that decides which of two masters gets the memory bus. Other kinds of processor would do this job in different ways.
CISC (for example x86): a CISC processor has complex instructions that do several memory accesses in one instruction, such as add with a memory operand. It also has more internal bus users, such as a prefetch unit. It therefore needs a more complex arbiter, often with several priority levels and a microcoded sequence, instead of a single dma_req select.
Stack machine: operands live on a stack, and nearly every instruction touches memory to push or pop. This puts much more traffic on the bus, so arbitration happens more often. The arbiter itself could be the same two-way selector, but it would be busier.
GPU: a GPU has many lanes that all want memory at once. It uses wide buses, many requesters and often a queue or a round-robin or priority arbiter, with caches to reduce contention. A simple "DMA always wins" rule would not be enough.
In RISC-V, memory is accessed only by lw and sw, so there are few requests, and a two-input selector like mine is enough.

## U6 Memory and I/O
My block sits between the memory and its two masters, the CPU and the DMA controller. Memory has only one set of address, data and write-enable lines, so only one master can use them at a time. When dma_req is 0, my block passes the CPU's addr, wdata, we and be to memory. When dma_req is 1, it passes the DMA's values instead and sets grant and stall to 1, so the DMA gets the bus and the CPU waits. This is called cycle stealing.
Every lw and sw of my program goes through this block while the DMA is idle. In an I/O transfer, the DMA controller (P48) asks for the bus, my arbiter gives it, and the DMA moves data between a device and memory without the CPU doing each transfer. The byte enable be is set to 1111 for a DMA write, so a whole word is written.

## E1 Instruction trace: AND
RC-V is single-cycle, so this all happens in one clock. Say x6 = 0xF0F0F0F0 and x7 = 0x0FF0FF00. The instruction encodes to 0x007372B3 (opcode 0110011, funct3 111, funct7 0000000, rd = 5, rs1 = 6, rs2 = 7).
1-Fetch: the PC (P14) gives the address to the ROM (P30), which returns the instruction. P03 computes PC+4.
2-Decode: the field splitter (P17) extracts rd, rs1, rs2, funct3 and funct7. The class decoder (P21) sees opcode 0110011, the OP class. The hardwired control (P22) produces control word 0x4000, which means only regwrite is set: input B comes from rs2, there's no memory access, and the result comes from the ALU. P24 selects between P22 and P23. The register-file read ports (P13) read x6 and x7.
3-Execute: the operand selector (P26) sends x6 and x7 to the ALU. ALU control (P10) sees funct3 = 111 and funct7 = 0 and selects AND. The logic unit (P04) computes 0xF0F0F0F0 AND 0x0FF0FF00 = 0x00F0F000, and the result selector (P08) outputs it.
4-Memory: the ALU result also arrives at my arbiter (P34) as an address, but memread and memwrite are 0, so no memory access happens.
5-Write back: the write-back selector (P25) picks the ALU result (wbsel = 0). The write decoder (P11) enables x5 and the register file (P12) stores 0x00F0F000.
6-Next PC: P16 sees no branch or jump, so P15 selects PC+4.

## E2 Neighbour review
P33 and P35 had not submitted any pull request by 18/11/2026, so I could not review them yet.

## E3 Where my block sits
My block is in the memory and bus layer of the computer, in the memory step of the instruction cycle. It is fed by the CPU side of the datapath: the ALU supplies the address and the store aligner (P27) supplies the write data, together with the write-enable and byte-enable signals. The DMA controller supplies the second set of inputs, which is the other bus master. My output goes to the address decoder (P31), which sends the access on to RAM (P29) or to the I/O bus (P33)

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 6).

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [ ] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA # P34 Bus arbiter (CPU vs DMA) - dossier
