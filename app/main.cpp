#include "lib/func1/func1.h"

#if __has_include("lib/func1/private_func1.h")
  #ifndef RULES_CC
    #error "This include should not be available"
  #endif
#endif

#include "lib/func2/func2.h"

#include <bits/stdc++.h>

using namespace std;

int main() {
    cout << "Hello World!" << endl;
    func1();
    func2();
    return 0;
}

