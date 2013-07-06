#include <stdlib.h>
#include <stdio.h>
#include <malloc.h>
#include <errno.h>
#define NEW(t, n) ((t*)malloc(sizeof(t)*(n)))
#define START_LEN 500

typedef unsigned int val_t;

int d(int a, int b) {
  int ret = a - b;
  ret = ret < 0 ? -ret : ret;
  return ret;
}

int calcdiff(val_t color1, val_t color2) {
  int r1, g1, b1, a1;
  r1 = color1 >> 24;
  g1 = (color1 >> 16) & 0xFF;
  b1 = (color1 >> 8) & 0xFF;
  a1 = color1 & 0xFF;
  
  int r2, g2, b2, a2;
  r2 = color2 >> 24;
  g2 = (color2 >> 16) & 0xFF;
  b2 = (color2 >> 8) & 0xFF;
  a2 = color2 & 0xFF;
  
  return d(r1, r2) + d(g1, g2) + d(b1, b2);
}

int main(int argc, char** argv) {
  char buffer[1024];
  unsigned long long difference = 0;
  while (!feof(stdin)) {
    fgets(buffer, 1024, stdin);
    errno = 0;
    unsigned long long result = strtoull(buffer, NULL, 16);
    if (errno != EINVAL && errno != ERANGE) {
      difference += result;
    }
    fgets(buffer, 1024, stdin);
    fgets(buffer, 1024, stdin);
    fgets(buffer, 1024, stdin);
    fgets(buffer, 1024, stdin);
    fgets(buffer, 1024, stdin);
    fgets(buffer, 1024, stdin);
    //append_array(pic1, color1);
    //append_array(pic2, color2);
  }
  printf("%llu\n", difference);
  /*
  int i = 0;
  for (; i < 10; i++) {
    val_t cur = get_array(myarray, i);
    printf("%d %d #%x\n", i, cur, cur);
  }
  */
}

