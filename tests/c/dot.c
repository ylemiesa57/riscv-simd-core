// Minimal C kernel for reference documentation (not built by default).
#include <stdint.h>

int32_t dot4(const int32_t *a, const int32_t *b) {
  int32_t acc = 0;
  for (int i = 0; i < 4; i++) acc += a[i] * b[i];
  return acc;
}

int main(void) {
  int32_t a[4] = {1, 2, 3, 4};
  int32_t b[4] = {2, 4, 6, 8};
  return dot4(a, b);
}
