#include <vector>

static_assert(__is_gsl_owner(std::vector<int>), "");
static_assert(__is_gsl_pointer(std::vector<int>::iterator), "");
static_assert(__is_gsl_pointer(std::vector<int>::const_iterator), "");
