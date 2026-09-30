#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "inner.h"

#define LOGN 9
#define N    (1u << LOGN)

/*
 * Nếu chạy chương trình từ folder:
 *   hardware_controller_falcon/keygen_soft/
 *
 * thì output sẽ đi tới:
 *   ../falcon512_sign_hw/vectors/input_key/
 */
#define OUT_KEY_DIR "../falcon512_sign_hw/vectors/input_key/"

static int
write_poly_memh(const char *filename, const int8_t *p)
{
    FILE *fp = fopen(filename, "w");
    if (fp == NULL) {
        perror(filename);
        return -1;
    }

    for (unsigned i = 0; i < N; i++) {
        /*
         * Ghi dạng 8-bit two's complement.
         * Ví dụ:
         *   5  -> 05
         *   -1 -> FF
         *   -4 -> FC
         *
         * Dùng được với Verilog $readmemh().
         */
        fprintf(fp, "%02X\n", (unsigned)((uint8_t)p[i]));
    }

    fclose(fp);
    return 0;
}

static int
write_poly_dec(const char *filename, const int8_t *p)
{
    FILE *fp = fopen(filename, "w");
    if (fp == NULL) {
        perror(filename);
        return -1;
    }

    for (unsigned i = 0; i < N; i++) {
        fprintf(fp, "%d\n", (int)p[i]);
    }

    fclose(fp);
    return 0;
}

static int
write_combined_csv(
    const char *filename,
    const int8_t *f,
    const int8_t *g,
    const int8_t *F,
    const int8_t *G
)
{
    FILE *fp = fopen(filename, "w");
    if (fp == NULL) {
        perror(filename);
        return -1;
    }

    fprintf(fp, "index,f_small,g_small,F_big,G_big\n");

    for (unsigned i = 0; i < N; i++) {
        fprintf(fp, "%u,%d,%d,%d,%d\n",
            i,
            (int)f[i],
            (int)g[i],
            (int)F[i],
            (int)G[i]
        );
    }

    fclose(fp);
    return 0;
}

int
main(void)
{
    inner_shake256_context rng;

    int8_t f[N];
    int8_t g[N];
    int8_t F[N];
    int8_t G[N];

    /*
     * h là public key, không bắt buộc cho hardware sign.
     * Nhưng lấy ra vẫn hữu ích nếu sau này muốn verify/debug.
     */
    uint16_t h[N];

    /*
     * Temp buffer cho Falcon-512 keygen.
     * FALCON_KEYGEN_TEMP_9 = 14336 bytes.
     * Dùng union để bảo đảm alignment 64-bit.
     */
    union {
        uint64_t align;
        uint8_t buf[FALCON_KEYGEN_TEMP_9];
    } tmp;

    /*
     * Seed cố định để mỗi lần chạy sinh cùng một bộ key.
     * Dùng để debug RTL dễ hơn.
     *
     * Khi dùng thật, thay seed này bằng RNG thật.
     */
    static const uint8_t seed[48] = {
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05,
        0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B,
        0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11,
        0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
        0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D,
        0x1E, 0x1F, 0x20, 0x21, 0x22, 0x23,
        0x24, 0x25, 0x26, 0x27, 0x28, 0x29,
        0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F
    };

    inner_shake256_init(&rng);
    inner_shake256_inject(&rng, seed, sizeof seed);
    inner_shake256_flip(&rng);

    /*
     * Falcon dùng floating-point.
     * set_fpu_cw(2) là cách reference code dùng để cố định precision.
     */
    unsigned oldcw = set_fpu_cw(2);

    /*
     * Hàm quan trọng nhất:
     *
     * LOGN = 9 -> Falcon-512
     *
     * Không được truyền G = NULL,
     * vì hardware của bạn muốn nhận đủ f, g, F, G.
     */
    Zf(keygen)(&rng, f, g, F, G, h, LOGN, tmp.buf);

    set_fpu_cw(oldcw);

    /*
     * Xuất file .memh cho Verilog.
     */
    if (write_poly_memh(OUT_KEY_DIR "f_small.memh", f) != 0) return 1;
    if (write_poly_memh(OUT_KEY_DIR "g_small.memh", g) != 0) return 1;
    if (write_poly_memh(OUT_KEY_DIR "F_big.memh",   F) != 0) return 1;
    if (write_poly_memh(OUT_KEY_DIR "G_big.memh",   G) != 0) return 1;

    /*
     * Xuất thêm file decimal để đọc bằng mắt/debug.
     */
    if (write_poly_dec(OUT_KEY_DIR "f_small.txt", f) != 0) return 1;
    if (write_poly_dec(OUT_KEY_DIR "g_small.txt", g) != 0) return 1;
    if (write_poly_dec(OUT_KEY_DIR "F_big.txt",   F) != 0) return 1;
    if (write_poly_dec(OUT_KEY_DIR "G_big.txt",   G) != 0) return 1;

    /*
     * Xuất thêm CSV tổng hợp.
     */
    if (write_combined_csv(OUT_KEY_DIR "fgFG.csv", f, g, F, G) != 0) return 1;

    printf("Generated Falcon-512 f,g,F,G successfully.\n");
    printf("Output files:\n");
    printf("  %sf_small.memh\n", OUT_KEY_DIR);
    printf("  %sg_small.memh\n", OUT_KEY_DIR);
    printf("  %sF_big.memh\n",   OUT_KEY_DIR);
    printf("  %sG_big.memh\n",   OUT_KEY_DIR);
    printf("  %sfgFG.csv\n",     OUT_KEY_DIR);

    return 0;
}