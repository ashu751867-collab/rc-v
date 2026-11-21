
# P35 Cache Tag Store — Dossier Answers

## U1 Digital Logic

The hit output is true only when access is requested, reset is inactive, the selected cache line is valid, and the stored tag matches the requested tag.

### Truth Table

| Access | Reset | Valid | Tag Equal | Hit |
|---|---|---|---|---|
| 0 | X | X | X | 0 |
| 1 | 1 | X | X | 0 |
| 1 | 0 | 0 | X | 0 |
| 1 | 0 | 1 | 0 | 0 |
| 1 | 0 | 1 | 1 | 1 |

`X` means don't care.

### Boolean Expression

```text
Hit = Access AND NOT Reset AND Valid AND Tag_Equal
```

The circuit uses AND gates, NOT logic, comparators and D flip-flops.

## U2 Digital Components

The P35 circuit uses the following components:

1. **Flip-Flops:** Store valid bits and cache tags.
2. **Multiplexer:** Selects the cache line using the index.
3. **Comparators:** Compare the requested tag with the stored tag.
4. **Logic Gates:** Generate the final hit signal.
5. **Decoder/Selection Logic:** Selects one of four cache lines.
6. **Adder:** Not required for tag lookup.

The address is divided into two main fields:

- Tag = Address bits [7:4]
- Index = Address bits [3:2]

The index selects one of four cache lines. The selected tag is compared with the requested tag. If both tags match and the valid bit is 1, the circuit generates a hit.

## U3 Data Representation

The following are three example test vectors.

| Example | Binary Address | Hexadecimal | Decimal | Tag | Index | Result |
|---|---|---|---|---|---|---|
| A | 0010 1100 | 0x2C | 44 | 0010 | 11 | Miss |
| B | 0010 1100 | 0x2C | 44 | 0010 | 11 | Hit |
| C | 0011 1100 | 0x3C | 60 | 0011 | 11 | Miss |

### Explanation

- **Example A:** The first access to address 0x2C finds an invalid cache line, so it produces a miss. The tag is stored.
- **Example B:** The same address is accessed again. The valid bit is set and the tag matches, so it produces a hit.
- **Example C:** Address 0x3C has the same index but a different tag. Therefore, it produces a miss.

The addresses are unsigned values. Sign extension can cause errors if an address is incorrectly treated as a signed number. Overflow is not normally involved because the tag lookup does not perform arithmetic addition.

## U4 Computer Organisation

The cache tag store works during the **Memory Access Stage** of the instruction cycle.

When a processor executes a load or store instruction, the address is sent to the cache. The index selects a cache line, and the comparator checks whether the stored tag matches the requested tag.

- If the tag matches and the valid bit is 1, it is a cache hit.
- If the tag does not match or the valid bit is 0, it is a cache miss.

Load and store instructions require this operation. Register-only arithmetic instructions normally do not need it.

## U5 Processors

### CISC Processor

A CISC processor may use complex instructions or microcode to perform memory operations. However, its cache still checks the address index, valid bit and tag.

### Stack Machine

A stack machine uses a stack to store operands and addresses. When it performs a memory load or store, the cache still checks the requested address using its tag store.

### GPU

A GPU handles many memory requests from multiple threads. Its cache performs tag comparisons as well, but it is designed to handle many requests simultaneously.

The exact RISC-V versus Mano comparison cannot be completed because `docs/ARCHITECTURE.md` was not supplied.

## U6 Memory and I/O

The P35 cache tag store is part of the **Memory Hierarchy**.

During a memory access, it checks whether the requested data is already present in the cache.

- **Cache Hit:** Data can be supplied from the selected cache line.
- **Cache Miss:** The memory-control logic fetches the required data from the next memory level and updates the cache entry.

The P35 block does not directly control I/O transfers. I/O interfaces and DMA/bus-control logic handle communication with external devices.

## E1 Instruction Trace: CSRRW

The exact CSRRW instruction trace cannot be completed using the supplied files because `docs/ARCHITECTURE.md` and the simulator's `--trace` output were not provided.

CSRRW is a RISC-V Control and Status Register instruction. It reads the old CSR value and writes a register-sourced value into the selected CSR.

To complete this section accurately, the RC-V architecture document and actual simulator trace are required.

## E2 Neighbour Review

### P34 — Bus Arbiter (CPU vs DMA)

Review Comment Link: [Paste your actual P34 review link here]

### P36 — Cache Statistics Counters

Review Comment Link: [Paste your actual P36 review link here]

The actual pull-request review links were not included in the supplied files.

## E3 Where My Block Sits

The P35 Cache Tag Store belongs to the **Memory Hierarchy / Cache Layer** of a computer system. It receives address, access and reset signals from the processor or cache-control logic. Its hit output is used by the cache controller to decide whether data can be supplied from the cache or must be fetched from memory.

## E4 Syllabus Map

The following syllabus topics are related to the P35 Cache Tag Store:

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [x] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [ ] Bus organisation, instruction codes and formats
- [ ] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [ ] Register organisation, stack, addressing modes
- [ ] RISC vs CISC, multicore, GPU
- [x] Memory hierarchy, cache
- [ ] I/O interface, programmed / interrupt-driven I/O, DMA

---

# End of P35 Dossier Answers
