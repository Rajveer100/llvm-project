//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

// UNSUPPORTED: c++03, c++11

// <propagate_const>

// template <class U> propagate_const& propagate_const::operator=(propagate_const<U>&&);

#include <experimental/propagate_const>
#include <cassert>
#include <utility>

#include "test_macros.h"
#include "propagate_const_helpers.h"

using std::experimental::propagate_const;

int main(int, char**) {

  typedef propagate_const<X> P;

  P p1(1);
  P p2(2);

  p2=std::move(p1);

  assert(*p2==1);

  return 0;
}
