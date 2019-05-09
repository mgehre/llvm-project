.. title:: clang-tidy - readability-static-method

readability-static-method
=========================

Finds non-static member functions that can be made ``static``
because the functions don't use ``this``.

After applying modifications as suggested by the check, runnnig the check again
might find more opportunities to mark member functions ``static``.

After making a member function ``static``, you might want to run the check
`readability-static-accessed-through-instance` to replace calls like
``Instance.method()`` by ``Class::method()``.
