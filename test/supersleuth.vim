Given (tabs only):
  void f() {
  	hi
  }
Execute:
  SuperSleuth
Then:
  Assert &tabstop == 2
  Assert &expandtab == 0
  Assert &shiftwidth == 0

Given (consistent 1-space indent):
  void f() {
   hi
   hi
  }
Execute:
  SuperSleuth
Then:
  Assert &tabstop == 1
  Assert &expandtab == 1
  Assert &shiftwidth == 0

Given (consistent 4-space indent):
  void f() {
      hi
      if()
  }
Execute:
  SuperSleuth
Then:
  Assert &tabstop == 4
  Assert &expandtab == 1
  Assert &shiftwidth == 0

Given (consistent spaces then tabs):
  void f() {
    yo
    yo
  	hi
  }
Execute:
  SuperSleuth
Then:
  Assert &tabstop == 8
  Assert &expandtab == 0
  Assert &shiftwidth == 2

Given (inconsistent spaces only):
  void f() {
    yo
     hi
  }
Execute:
  " random values to see if they change
  set tabstop=3 noexpandtab shiftwidth=7
  SuperSleuth
Then:
  Assert &tabstop == 3
  Assert &expandtab == 0
  Assert &shiftwidth == 7
