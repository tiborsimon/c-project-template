#include <stdlib.h>
#include <stdio.h>
#include "production.h"

void my_function() {
  int* a = (int*)calloc(1, sizeof(int));
  free(a);
}
