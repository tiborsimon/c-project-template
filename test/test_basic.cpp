#include <CppUTest/TestHarness.h>
#include <CppUTest/MemoryLeakDetectorMallocMacros.h>
#include <iostream>

#include "production.h"

TEST_GROUP(FirstTestGroup) {
};

TEST(FirstTestGroup, FirstTest) {
  my_function();
  CHECK(true);
}

TEST(FirstTestGroup, SecondTest) {
  STRCMP_EQUAL("hello", "hello");
}


