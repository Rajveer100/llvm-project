//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

// <unordered_map>

// template <class Key, class T, class Hash = hash<Key>, class Pred = equal_to<Key>,
//           class Alloc = allocator<pair<const Key, T>>>
// class unordered_multimap

// void clear() noexcept;

#include <unordered_map>
#include <string>
#include <cassert>

#include "test_macros.h"
#include "min_allocator.h"

int main(int, char**) {
  {
    typedef std::unordered_multimap<int, std::string> C;
    typedef std::pair<int, std::string> P;
    P a[] = {
        P(1, "one"),
        P(2, "two"),
        P(3, "three"),
        P(4, "four"),
        P(1, "four"),
        P(2, "four"),
    };
    C c(a, a + sizeof(a) / sizeof(a[0]));
    ASSERT_NOEXCEPT(c.clear());
    c.clear();
    assert(c.size() == 0);
  }
#if TEST_STD_VER >= 11
  {
    typedef std::unordered_multimap<int,
                                    std::string,
                                    std::hash<int>,
                                    std::equal_to<int>,
                                    min_allocator<std::pair<const int, std::string>>>
        C;
    typedef std::pair<int, std::string> P;
    P a[] = {
        P(1, "one"),
        P(2, "two"),
        P(3, "three"),
        P(4, "four"),
        P(1, "four"),
        P(2, "four"),
    };
    C c(a, a + sizeof(a) / sizeof(a[0]));
    ASSERT_NOEXCEPT(c.clear());
    c.clear();
    assert(c.size() == 0);
  }
#endif

  return 0;
}
