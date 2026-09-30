Muc dich:
fpr_inv/ chua module tinh nghich dao fixed-point.

Chuc nang:
z = 1 / b

Phien ban hien tai khong dung DesignWare.
Khong dung DW_lp_piped_fp_recip.
Module duoc viet bang Verilog co ban nen co the simulation va synthesis.

Dinh dang du lieu:
Q32.48 fixed-point
DATA_WIDTH = 80
FRAC_WIDTH = 48

Vi du Q32.48:
1.0   = 80'h0000_0001_0000_0000_0000
2.0   = 80'h0000_0002_0000_0000_0000
0.5   = 80'h0000_0000_8000_0000_0000
0.25  = 80'h0000_0000_4000_0000_0000
-1.0  = 80'hFFFF_FFFF_0000_0000_0000
-0.5  = 80'hFFFF_FFFF_8000_0000_0000

Quy tac tinh toan:
b la so fixed-point Q32.48.

Gia tri thuc:
b_real = b / 2^FRAC_WIDTH

Can tinh:
z_real = 1 / b_real

Gia tri fixed-point dau ra:
z_fixed = 2^(2*FRAC_WIDTH) / b

Voi Q32.48:
z_fixed = 2^96 / b

Chuc nang tung file:

| File              | Chuc nang                                      |
|-------------------|------------------------------------------------|
| fpr_inv.v         | Tinh nghich dao fixed-point z = 1 / b          |
| tb_fpr_inv.v      | Testbench kiem tra chuc nang fpr_inv           |
| list_fpr_inv.f    | Danh sach file RTL dung de compile             |
| run_fpr_inv.sh    | Script chay simulation bang VCS                |
| readme_fpr_inv.md | Mo ta chuc nang va cach hoat dong cua fpr_inv  |

Tin hieu chinh:

| Tin hieu   | Chuc nang                           |
|------------|-------------------------------------|
| clk        | Clock                               |
| rst_n      | Reset muc thap                      |
| in_valid   | Bao input b hop le                  |
| b          | Gia tri dau vao can tinh nghich dao |
| out_valid  | Bao ket qua z hop le                |
| z          | Ket qua z = 1 / b                   |

Cach hoat dong:
1. Khi in_valid = 1, module nhan gia tri b.
2. Module lay tri tuyet doi cua b va luu lai bit dau.
3. Module thuc hien phep chia tuan tu de tinh 2^(2*FRAC_WIDTH) / |b|.
4. Neu b am, ket qua z se am.
5. Khi tinh xong, out_valid = 1 va z co gia tri hop le.
6. Neu b = 0, module tra ve MAX_POS de tranh chia cho 0.

Do tre:
Voi Q32.48:
NUM_WIDTH = 2*FRAC_WIDTH + 1 = 97

Nen moi phep inverse mat khoang 97 chu ky clock.

Cac truong hop da test:

| Test case | Ket qua mong muon |
|-----------|-------------------|
| 1 / 1.0   | 1.0               |
| 1 / 2.0   | 0.5               |
| 1 / 4.0   | 0.25              |
| 1 / 0.5   | 2.0               |
| 1 / -1.0  | -1.0              |
| 1 / -2.0  | -0.5              |
| 1 / 0     | MAX_POS           |

Ket qua test:
FPR_INV FIXED Q32.48 TEST PASS

Luu y:
- Day la fixed-point, khong phai IEEE-754 floating-point.
- Khong dung DesignWare.
- Co the synthesis bang Verilog chuan.
- Toc do cham hon IP reciprocal pipeline cua DesignWare vi dung phep chia tuan tu.
- Phu hop voi huong tu viet IP fixed-point cho Falcon-512.

Vai tro trong Falcon-512:
fpr_inv/ co the dung cho cac khoi can phep nghich dao so thuc trong mien fixed-point, vi du:
FFT / IFFT
LDL tree
Gram matrix
ffSampling

Trang thai:
fpr_inv : PASS
Format  : Q32.48 fixed-point
DW used : no
Status  : ready for higher-level integration
