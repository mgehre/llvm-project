// NOT RUN: %clang_cc1 -fsyntax-only -Wlifetime -Wlifetime-dump-contracts -verify %s

namespace gsl {
struct null_t {
  template <typename T>
  operator T() const;
} null;

struct global_t {
  template <typename T>
  operator T() const;
} global;

struct invalid_t {
  template <typename T>
  operator T() const;
} invalid;

struct return_t {
  template <typename T>
  operator T() const;
} Return;

template<typename T> T &&declval();

template<typename T>
struct PointerTraits {
  using DerefType = decltype(*declval<T>());
};

struct PSet {
  template<typename... T>
  PSet(const T&...);
};

template <typename T>
auto deref(const T &t) -> typename PointerTraits<T>::DerefType;

template <typename T>
bool lifetime(const T &lhs, const PSet &rhs);
} // namespace gsl

void basic(int *a, int *b) [[gsl::pre(gsl::lifetime(b, {a}))]];
// expected-warning@-1 {{Pre { b -> { a }; }}}

void specials(int *a, int *b, int *c)
    [[gsl::pre(gsl::lifetime(a, {gsl::null}))]]
    [[gsl::pre(gsl::lifetime(b, {gsl::global}))]]
    [[gsl::pre(gsl::lifetime(c, {gsl::invalid}))]];
// expected-warning@-4 {{Pre { a -> { null }; b -> { global }; c -> { invalid }; }}}

void variadic(int *a, int *b, int *c)
    [[gsl::pre(gsl::lifetime(b, {a, c}))]];
// expected-warning@-2 {{Pre { b -> { a c }; }}}

void variadic_special(int *a, int *b, int *c)
    [[gsl::pre(gsl::lifetime(b, {a, gsl::null}))]];
// expected-warning@-2 {{Pre { b -> { null a }; }}}

void multiple_annotations(int *a, int *b, int *c)
    [[gsl::pre(gsl::lifetime(b, {a}))]]
    [[gsl::pre(gsl::lifetime(c, {a}))]];
// expected-warning@-3 {{Pre { b -> { a }; c -> { a }; }}}

void multiple_annotations_chained(int *a, int *b, int *c)
    [[gsl::pre(gsl::lifetime(b, {a}))]]
    [[gsl::pre(gsl::lifetime(c, {b}))]];
// expected-warning@-3 {{Pre { b -> { a }; c -> { a }; }}}

void deref_ptr(int *a, int *b, int **c)
    [[gsl::pre(gsl::lifetime(gsl::deref(c), {a}))]];
// expected-warning@-2 {{Pre { *c -> { a }; }}}

void deref_ptr_pointee(int *a, int *b, int **c)
    [[gsl::pre(gsl::lifetime(a, {gsl::deref(c)}))]];
// expected-warning@-2 {{Pre { a -> { *c }; }}}

void deref_ref(int *a, int *b, int *&c)
    [[gsl::pre(gsl::lifetime(gsl::deref(c), {a}))]];
// expected-warning@-2 {{Pre { *c -> { a }; }}}

void deref_ref_pointee(int *a, int *b, int *&c)
    [[gsl::pre(gsl::lifetime(a, {gsl::deref(c)}))]];
// expected-warning@-2 {{Pre { a -> { *c }; }}}

struct [[gsl::Owner(void)]] X {
  void f(X **out)
      [[gsl::post(gsl::lifetime(gsl::deref(out), {this}))]];
  // expected-warning@-2 {{Pre { }  Post { *out -> { this }; }}}
  X *operator+(const X& other)
      [[gsl::post(gsl::lifetime(gsl::Return, {other}))]];
  // expected-warning@-2 {{Pre { }  Post { (return value) -> { other }; }}}
};

template <typename It, typename T>
It find(It begin, It end, const T &val)
    [[gsl::pre(gsl::lifetime(end, {begin}))]]
    [[gsl::post(gsl::lifetime(gsl::Return, {begin}))]];
// expected-warning@-3 {{Pre { end -> { begin }; }  Post { (return value) -> { begin }; }}}

int *find_nontemp(int *begin, int *end, const int &val)
    [[gsl::pre(gsl::lifetime(end, {begin}))]]
    [[gsl::post(gsl::lifetime(gsl::Return, {begin}))]];
// expected-warning@-3 {{Pre { end -> { begin }; }  Post { (return value) -> { begin }; }}}

struct [[gsl::Owner(int)]] MyOwner {
  int *begin()
      [[gsl::post(lifetime(gsl::Return, {this}))]];
  // expected-warning@-2 {{Pre { }  Post { (return value) -> { this }; }}}
  int *end()
      [[gsl::post(lifetime(gsl::Return, {this}))]];
  // expected-warning@-2 {{Pre { }  Post { (return value) -> { this }; }}}
};

void testGslWarning() {
  int *res = find(MyOwner{}.begin(), MyOwner{}.end(), 5);
  // expected-warning@-1 {{object backing the pointer will be destroyed at the end of the full-expression}}
  (void)res;
  int *res2 = find_nontemp(MyOwner{}.begin(), MyOwner{}.end(), 5);
  // expected-warning@-1 {{object backing the pointer will be destroyed at the end of the full-expression}}
  (void)res2;
  X x;
  // TODO: this should work without X annotated as owner.
  X *xp = x + X{};
  // expected-warning@-1 {{object backing the pointer will be destroyed at the end of the full-expression}}
  (void)xp;
}

// Warnings/errors

void unsupported_contract(int *a, int *b) [[gsl::pre(gsl::lifetime(b, {a++}))]];
// expected-warning@-1 {{this pre/postcondition is not supported}}

void type_error(int *a, int *b) [[gsl::pre(gsl::lifetime(b, {**a}))]];
// expected-error@-1 {{indirection requires pointer operand ('int' invalid)}}
