// RUN: %clang_cc1 -fsyntax-only -Wlifetime -Wlifetime-dump-contracts -verify %s

namespace gsl {
struct null_t {
  template <typename T>
  operator T() const;
} Null;
struct static_t {
  template <typename T>
  operator T() const;
} Static;
struct invalid_t {
  template <typename T>
  operator T() const;
} Invalid;

struct return_t {
  template <typename T>
  operator T() const;
} Return;

template <typename T>
struct PointerTraits {
  static auto deref(const T &t) -> decltype(*t);
};

template <typename T>
struct PointerTraits<T *> {
  static const T &deref(const T *t);
};

template <typename T>
struct PointerTraits<T &> {
  static const T &deref(const T &t);
};

struct PSet {
  PSet(...);
};

template <typename T>
auto deref(const T &t) -> decltype(PointerTraits<T>::deref(t));

template <typename T>
bool lifetime(const T &lhs, const PSet &rhs);
} // namespace gsl

using namespace gsl;

void basic(int *a, int *b) [[gsl::pre(lifetime(b, {a}))]];
// expected-warning@-1 {{Pre { b -> { a }; }}}

void specials(int *a, int *b, int *c)
    [[gsl::pre(lifetime(a, {Null}))]]
    [[gsl::pre(lifetime(b, {Static}))]]
    [[gsl::pre(lifetime(c, {Invalid}))]];
// expected-warning@-4 {{Pre { a -> { Null }; b -> { Static }; c -> { Invalid }; }}}

void variadic(int *a, int *b, int *c)
    [[gsl::pre(lifetime(b, {a, c}))]];
// expected-warning@-2 {{Pre { b -> { a c }; }}}

void variadic_special(int *a, int *b, int *c)
    [[gsl::pre(lifetime(b, {a, Null}))]];
// expected-warning@-2 {{Pre { b -> { Null a }; }}}

void multiple_annotations(int *a, int *b, int *c)
    [[gsl::pre(lifetime(b, {a}))]]
    [[gsl::pre(lifetime(c, {a}))]];
// expected-warning@-3 {{Pre { b -> { a }; c -> { a }; }}}

void multiple_annotations_chained(int *a, int *b, int *c)
    [[gsl::pre(lifetime(b, {a}))]]
    [[gsl::pre(lifetime(c, {b}))]];
// expected-warning@-3 {{Pre { b -> { a }; c -> { a }; }}}

void deref_ptr(int *a, int *b, int **c)
    [[gsl::pre(lifetime(deref(c), {a}))]];
// expected-warning@-2 {{Pre { *c -> { a }; }}}

void deref_ptr_pointee(int *a, int *b, int **c)
    [[gsl::pre(lifetime(a, {deref(c)}))]];
// expected-warning@-2 {{Pre { a -> { *c }; }}}

void deref_ref(int *a, int *b, int *&c)
    [[gsl::pre(lifetime(deref(c), {a}))]];
// expected-warning@-2 {{Pre { *c -> { a }; }}}

void deref_ref_pointee(int *a, int *b, int *&c)
    [[gsl::pre(lifetime(a, {deref(c)}))]];
// expected-warning@-2 {{Pre { a -> { *c }; }}}

struct X {
  void f(X **out)
      [[gsl::post(lifetime(deref(out), this))]];
  // expected-warning@-2 {{Pre { }  Post { *out -> { this }; }}}
};

template <typename It, typename T>
It find(It begin, It end, const T &val)
    [[gsl::pre(lifetime(end, {begin}))]]
    [[gsl::post(lifetime(Return, {begin}))]];
// expected-warning@-3 {{Pre { end -> { begin }; }  Post { (return value) -> { begin }; }}}

int *find_nontemp(int *begin, int *end, const int &val)
    [[gsl::pre(lifetime(end, {begin}))]]
    [[gsl::post(lifetime(Return, {begin}))]];
// expected-warning@-3 {{Pre { end -> { begin }; }  Post { (return value) -> { begin }; }}}

struct [[gsl::Owner(int)]] MyOwner {
  int *begin()
      [[gsl::post(lifetime(Return, {this}))]];
  // expected-warning@-2 {{Pre { }  Post { (return value) -> { this }; }}}
  int *end()
      [[gsl::post(lifetime(Return, {this}))]];
  // expected-warning@-2 {{Pre { }  Post { (return value) -> { this }; }}}
};

void testGslWarning() {
  int *res = find(MyOwner{}.begin(), MyOwner{}.end(), 5);
  // expected-warning@-1 {{object backing the pointer will be destroyed at the end of the full-expression}}
  (void)res;
  int *res2 = find_nontemp(MyOwner{}.begin(), MyOwner{}.end(), 5);
  // expected-warning@-1 {{object backing the pointer will be destroyed at the end of the full-expression}}
  (void)res2;
}
