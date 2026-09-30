Muc dich:
rng_primitive/ chua cac module tao du lieu ngau nhien dang primitive.

Phien ban hien tai dung LFSR de tao byte gia ngau nhien.
Module nay dung de test simulation va kiem tra luong dieu khien.

Luu y:
Day chua phai RNG bao mat dung cho Falcon thuc te.
Khi hoan thien Falcon, can thay bang SHAKE-based DRBG, CSPRNG hoac TRNG.

Chuc nang chinh:
- Tao random byte 8-bit
- Gom nhieu byte thanh chuoi random bits
- Ho tro tao UniformBits(k)
- Ho tro tao chuoi 320-bit de test salt/random trong Falcon

Dinh dang du lieu:
MAX_BITS  = 320
LEN_WIDTH = 9

Vi:
320 bit la kich thuoc co the dung de test salt/random.
LEN_WIDTH = 9 vi can bieu dien do dai tu 0 den 320 bit.

Chuc nang tung file:

| File                    | Chuc nang                                      |
|-------------------------|------------------------------------------------|
| random_byte.v           | Tao byte gia ngau nhien 8-bit bang LFSR        |
| uniform_bits.v          | Gom random byte thanh chuoi random bits        |
| rng_wrapper.v           | Wrapper ket noi random_byte va uniform_bits    |
| tb_rng_prim.v           | Testbench kiem tra rng_primitive/              |
| list_rng_prim.f         | Danh sach file RTL dung de compile             |
| run_rng_prim.sh         | Script chay simulation bang VCS                |
| readme_rng_primitive.md | Mo ta chuc nang va cach hoat dong cua RNG      |

Tin hieu chinh cua random_byte:

| Tin hieu    | Chuc nang                                  |
|-------------|--------------------------------------------|
| clk         | Clock                                      |
| rst_n       | Reset muc thap                             |
| req         | Yeu cau tao 1 random byte                  |
| seed_en     | Cho phep nap seed moi                      |
| seed        | Gia tri seed 32-bit                        |
| out_valid   | Bao random_byte hop le                     |
| random_byte | Byte gia ngau nhien dau ra                 |

Tin hieu chinh cua uniform_bits:

| Tin hieu    | Chuc nang                                  |
|-------------|--------------------------------------------|
| clk         | Clock                                      |
| rst_n       | Reset muc thap                             |
| start       | Bat dau tao chuoi random bits              |
| bit_len     | So bit can tao                             |
| byte_req    | Yeu cau 1 random byte                      |
| byte_valid  | Bao byte_in hop le                         |
| byte_in     | Byte dau vao tu random_byte                |
| busy        | Module dang hoat dong                      |
| out_valid   | Bao random_bits hop le                     |
| random_bits | Chuoi random bits dau ra                   |

Tin hieu chinh cua rng_wrapper:

| Tin hieu   | Chuc nang                                  |
|------------|--------------------------------------------|
| clk        | Clock                                      |
| rst_n      | Reset muc thap                             |
| req        | Yeu cau tao random bits                    |
| bit_len    | So bit can tao                             |
| seed_en    | Cho phep nap seed moi                      |
| seed       | Gia tri seed 32-bit                        |
| busy       | Module dang hoat dong                      |
| out_valid  | Bao random_out hop le                      |
| random_out | Chuoi random bits dau ra                   |

Cach hoat dong:

1. random_byte:
   - Su dung LFSR 32-bit de tao byte gia ngau nhien.
   - Khi req = 1, LFSR cap nhat trang thai moi.
   - Byte dau ra lay tu 8 bit thap cua trang thai LFSR moi.
   - out_valid = 1 khi random_byte hop le.

2. uniform_bits:
   - Nhan yeu cau start va bit_len.
   - Tinh so byte can lay:
     total_bytes = (bit_len + 7) >> 3
   - Gui byte_req de yeu cau random byte.
   - Moi byte nhan duoc se duoc ghep vao random_bits.
   - Neu bit_len khong chia het cho 8, module se mask bo cac bit du.
   - out_valid = 1 khi random_bits hop le.

3. rng_wrapper:
   - Ket noi random_byte voi uniform_bits.
   - Ben ngoai chi can dua req va bit_len.
   - Wrapper tu dong yeu cau random byte va gom thanh chuoi random bits.

Cac truong hop da test:

random_byte:
| Test case              | Ket qua mong muon             |
|------------------------|-------------------------------|
| Nap seed moi           | LFSR nhan seed                |
| Tao random byte lan 1  | out_valid = 1 va byte dung    |
| Tao random byte lan 2  | out_valid = 1 va byte dung    |
| Tao random byte lan 3  | out_valid = 1 va byte dung    |
| Tao random byte lan 4  | out_valid = 1 va byte dung    |

uniform_bits:
| Test case       | Ket qua mong muon                   |
|-----------------|-------------------------------------|
| UniformBits(0)  | 0                                   |
| UniformBits(1)  | Tao 1 bit hop le                    |
| UniformBits(8)  | Tao 1 byte hop le                   |
| UniformBits(9)  | Tao 9 bit va mask dung              |
| UniformBits(16) | Tao 16 bit hop le                   |

rng_wrapper:
| Test case         | Ket qua mong muon                   |
|-------------------|-------------------------------------|
| UniformBits(1)    | Tao 1 bit random                    |
| UniformBits(8)    | Tao 8 bit random                    |
| UniformBits(16)   | Tao 16 bit random                   |
| UniformBits(72)   | Tao 72 bit random                   |
| UniformBits(320)  | Tao 320 bit random                  |

Ket qua test:
RNG PRIMITIVE TEST PASS

Luu y:
- rng_primitive/ hien tai chi dung LFSR gia ngau nhien.
- LFSR khong du an toan cho ung dung mat ma thuc te.
- Khong dung DesignWare.
- Co the simulation va synthesis bang Verilog chuan.
- Phu hop de test luong dieu khien va ket noi phan cung.
- Khi lam Falcon hoan chinh, can thay random_byte bang khoi RNG bao mat hon.

Vai tro trong Falcon-512:
rng_primitive/ co the dung de test cac khoi can random bits, vi du:
- Tao salt
- BaseSampler
- SamplerZ
- ffSampling
- Test luong ky Falcon

Trang thai:
random_byte  : PASS
uniform_bits : PASS
rng_wrapper  : PASS
Format       : random bits / random byte
MAX_BITS     : 320
DW used      : no
Status       : ready for higher-level integration
