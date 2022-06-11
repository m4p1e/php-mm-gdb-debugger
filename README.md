It's a simple GDB script for debugging and analyzing the layout of php heap memory, hope u enjoy it :)

Supported commands:

1. `gdb> print_mm_page_info $somewhere_in_heap`
```
gdb> print_mm_page_info vio
[*]page_offset: 0x83000
[*]page_num: 131
[*]chunk_adr: 0x7ffff5400000
[*]page_status: SRUN[first page of a bin used for "small" allocation]
[*]bin_num: 17
[*]bin_size: 0x180
[*]bin_elements: 32
[*]bin_pages: 3
  -> page_0_adr: 0x7ffff5483000
  -> page_1_adr: 0x7ffff5484000
  -> page_2_adr: 0x7ffff5485000
[*]current_local_page_offset: 0
```

2.`print_mm_main_chunk_info $start_page_offset  $range`
```
gdb> print_mm_main_chunk_info 130 16
[-]page_130_adr (0x7ffff5482000): [LRUN], [P1], 
[-]page_131_adr (0x7ffff5483000): [SRUN], [0x180]
  ->[-]page_132_adr (0x7ffff5484000): [SMALL], [N1], [0x180]
  ->[-]page_133_adr (0x7ffff5485000): [SMALL], [N2], [0x180]
[-]page_134_adr (0x7ffff5486000): [SRUN], [0x100]
[-]page_135_adr (0x7ffff5487000): [SRUN], [0x8]
[-]page_136_adr (0x7ffff5488000): [SRUN], [0x800]
  ->[-]page_137_adr (0x7ffff5489000): [SMALL], [N1], [0x800]
  ->[-]page_138_adr (0x7ffff548a000): [SMALL], [N2], [0x800]
  ->[-]page_139_adr (0x7ffff548b000): [SMALL], [N3], [0x800]
[-]page_140_adr (0x7ffff548c000): [SRUN], [0x200]
[-]page_141_adr (0x7ffff548d000): [SRUN], [0xa0]
[-]page_142_adr (0x7ffff548e000): [SRUN], [0x40]
[-]page_143_adr (0x7ffff548f000): [LRUN], [P8], [USED], [LARGE]
  ->[-]page_144_adr (0x7ffff5490000): [USED], [LARGE]
  ->[-]page_145_adr (0x7ffff5491000): [USED], [LARGE]
```
