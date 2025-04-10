// RUN: %clang_cc1 -triple x86_64-pc-linux-gnu -fsyntax-only -Wno-unused -verify=addr64,expected %s
// RUN: %clang_cc1 -triple i386-pc-linux-gnu   -fsyntax-only -Wno-unused -verify=addr32,expected %s
// RUN: %clang_cc1 -triple avr-pc-linux-gnu    -fsyntax-only -Wno-unused -verify=addr16,expected %s

struct S {
  long long a;
  char b;
  long long c;
  short d;
};

struct S s[]; // expected-warning {{tentative array definition}} expected-note {{declared here}} addr16-note {{declared here}}

void f1(void) {
  ++s[3].a;
  ++s[7073650413200313099].b;
  // addr16-warning@-1 {{array index 7073650413200313099 refers past the last possible element for an array in 16-bit address space containing 152-bit (19-byte) elements (max possible 3449 elements)}}
  // addr32-warning@-2 {{array index 7073650413200313099 refers past the last possible element for an array in 32-bit address space containing 192-bit (24-byte) elements (max possible 178956970 elements)}}
  // addr64-warning@-3 {{array index 7073650413200313099 refers past the last possible element for an array in 64-bit address space containing 256-bit (32-byte) elements (max possible 576460752303423488 elements)}}
  ++s[7073650].c;
  // addr16-warning@-1 {{array index 7073650 refers past the last possible element for an array in 16-bit address space containing 152-bit (19-byte) elements (max possible 3449 elements)}}
}

long long ll[]; // expected-warning {{tentative array definition}} expected-note {{declared here}} addr16-note {{declared here}} addr32-note {{declared here}}

void f2(void) {
  ++ll[3];
  ++ll[2705843009213693952];
  // addr16-warning@-1 {{array index 2705843009213693952 refers past the last possible element for an array in 16-bit address space containing 64-bit (8-byte) elements (max possible 8192 elements)}}
  // addr32-warning@-2 {{array index 2705843009213693952 refers past the last possible element for an array in 32-bit address space containing 64-bit (8-byte) elements (max possible 536870912 elements)}}
  // addr64-warning@-3 {{array index 2705843009213693952 refers past the last possible element for an array in 64-bit address space containing 64-bit (8-byte) elements (max possible 2305843009213693952 elements)}}
  ++ll[847073650];
  // addr16-warning@-1 {{array index 847073650 refers past the last possible element for an array in 16-bit address space containing 64-bit (8-byte) elements (max possible 8192 elements)}}
  // addr32-warning@-2 {{array index 847073650 refers past the last possible element for an array in 32-bit address space containing 64-bit (8-byte) elements (max possible 536870912 elements)}}
}

void f3(struct S p[]) { // expected-note {{declared here}} addr16-note {{declared here}}
  ++p[3].a;
  ++p[7073650413200313099].b;
  // addr16-warning@-1 {{array index 7073650413200313099 refers past the last possible element for an array in 16-bit address space containing 152-bit (19-byte) elements (max possible 3449 elements)}}
  // addr32-warning@-2 {{array index 7073650413200313099 refers past the last possible element for an array in 32-bit address space containing 192-bit (24-byte) elements (max possible 178956970 elements)}}
  // addr64-warning@-3 {{array index 7073650413200313099 refers past the last possible element for an array in 64-bit address space containing 256-bit (32-byte) elements (max possible 576460752303423488 elements)}}
  ++p[7073650].c;
  // addr16-warning@-1 {{array index 7073650 refers past the last possible element for an array in 16-bit address space containing 152-bit (19-byte) elements (max possible 3449 elements)}}
}

void f4(struct S *p) { // expected-note {{declared here}} addr16-note {{declared here}}
  p += 3;
  p += 7073650413200313099;
  // addr16-warning@-1 {{the pointer incremented by 7073650413200313099 refers past the last possible element for an array in 16-bit address space containing 152-bit (19-byte) elements (max possible 3449 elements)}}
  // addr32-warning@-2 {{the pointer incremented by 7073650413200313099 refers past the last possible element for an array in 32-bit address space containing 192-bit (24-byte) elements (max possible 178956970 elements)}}
  // addr64-warning@-3 {{the pointer incremented by 7073650413200313099 refers past the last possible element for an array in 64-bit address space containing 256-bit (32-byte) elements (max possible 576460752303423488 elements)}}
  p += 7073650;
  // addr16-warning@-1 {{the pointer incremented by 7073650 refers past the last possible element for an array in 16-bit address space containing 152-bit (19-byte) elements (max possible 3449 elements)}}
}

struct BQ {
  struct S bigblock[3276];
};

struct BQ bq[]; // expected-warning {{tentative array definition}} addr16-note {{declared here}}

void f5(void) {
  ++bq[0].bigblock[0].a;
  ++bq[1].bigblock[0].a;
  // addr16-warning@-1 {{array index 1 refers past the last possible element for an array in 16-bit address space containing 497952-bit (62244-byte) elements (max possible 1 element)}}
}

void f6(void) {
  int ints[] = {1, 3, 5, 7, 8, 6, 4, 5, 9};
  int const n_ints = sizeof(ints) / sizeof(int);
  unsigned long long const N = 3;

  int *middle = &ints[0] + n_ints / 2;
  // Should NOT produce a warning.
  *(middle + 5 - N) = 22;
}

void pr50741(void) {
  (void *)0 + 0xdead000000000000UL;
  // no array-bounds warning, and no crash
}

void func() {
  func + 0xdead000000000000UL; // no crash
}

struct {
  int _;
  char tail[];  // addr16-note {{declared here}} addr32-note {{declared here}}
} fam;

struct {
  int _;
  char tail[0];  // addr16-note {{declared here}} addr32-note {{declared here}}
} fam0;

struct {
  int _;
  char tail[1];  // addr16-note {{declared here}} addr32-note {{declared here}}
} fam1;

void fam_ily() {
  ++fam.tail[7073650413200313099];
  // addr16-warning@-1 {{array index 7073650413200313099 refers past the last possible element for an array in 16-bit address space containing 8-bit (1-byte) elements (max possible 65536 elements)}}
  // addr32-warning@-2 {{array index 7073650413200313099 refers past the last possible element for an array in 32-bit address space containing 8-bit (1-byte) elements (max possible 4294967296 elements)}}
  // No warning for addr64 because the array index is inbound in that case.
  ++fam0.tail[7073650413200313099];
  // addr16-warning@-1 {{array index 7073650413200313099 refers past the last possible element for an array in 16-bit address space containing 8-bit (1-byte) elements (max possible 65536 elements)}}
  // addr32-warning@-2 {{array index 7073650413200313099 refers past the last possible element for an array in 32-bit address space containing 8-bit (1-byte) elements (max possible 4294967296 elements)}}
  // No warning for addr64 because the array index is inbound in that case.
  ++fam1.tail[7073650413200313099];
  // addr16-warning@-1 {{array index 7073650413200313099 refers past the last possible element for an array in 16-bit address space containing 8-bit (1-byte) elements (max possible 65536 elements)}}
  // addr32-warning@-2 {{array index 7073650413200313099 refers past the last possible element for an array in 32-bit address space containing 8-bit (1-byte) elements (max possible 4294967296 elements)}}
  // No warning for addr64 because the array index is inbound in that case.
}
