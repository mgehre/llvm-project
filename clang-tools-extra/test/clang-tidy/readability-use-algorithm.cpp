// RUN: %check_clang_tidy %s readability-use-algorithm %t

bool good_any_of() {
  int v[] = {1, 2, 3};
  // CHECK-MESSAGES: :[[@LINE+1]]:3: warning: Replace loop by std::any_of() from <algorithm> [readability-use-algorithm]
  for (int i : v)
    if (i)
      return true;
  return false;
}

bool good_any_of2() {
  int v[] = {1, 2, 3};
  for (int &i : v) {
    // CHECK-MESSAGES: :[[@LINE-1]]:3: warning: Replace loop by std::any_of()
    if (i)
      return true;
  }
  return false;
}

bool good_any_of3() {
  int v[] = {1, 2, 3};
  for (int i : v) {
    // CHECK-MESSAGES: :[[@LINE-1]]:3: warning: Replace loop by std::any_of()
    if (i) {
      return true;
    }
  }
  return false;
}

bool good_any_of4() {
  int v[] = {1, 2, 3};
  for (int i : v) {
    // CHECK-MESSAGES: :[[@LINE-1]]:3: warning: Replace loop by std::any_of()
    int k = i / 2;
    if (k)
      return true;
  }
  return false;
}

bool good_any_of5() {
  int v[] = {1, 2, 3};
  for (int i : v) {
    // CHECK-MESSAGES: :[[@LINE-1]]:3: warning: Replace loop by std::any_of()
    if (i == 3)
      continue;
    if (i)
      return true;
  }

  return false;
}

bool good_any_of_use_external(int comp) {
  int v[] = {1, 2, 3};
  for (int i : v) {
    // CHECK-MESSAGES: :[[@LINE-1]]:3: warning: Replace loop by std::any_of()
    if (i == comp)
      return true;
  }

  return false;
}

bool bad_any_of1() {
  int v[] = {1, 2, 3};
  for (int i : v) {
    if (i)
      return false; // bad constant
  }
  return false;
}

bool bad_any_of2() {
  int v[] = {1, 2, 3};
  for (int i : v)
    if (i)
      return true;

  return true; // bad return
}

bool bad_any_of3() {
  int v[] = {1, 2, 3};
  for (int i : v)
    if (i)
      return true;
    else
      return i / 2; // bad return

  return false;
}

bool bad_any_of_control_flow1() {
  int v[] = {1, 2, 3};
  for (int i : v) {
    break; // bad control flow
    if (i)
      return true;
  }

  return false;
}

bool bad_any_of4() {
  return false; // wrong order

  int v[] = {1, 2, 3};
  for (int i : v) {
    if (i)
      return true;
  }
}

bool bad_any_of5() {
  int v[] = {1, 2, 3};
  int j = 0;
  for (int i : v) {
    j++; // modifications
    if (i)
      return true;
  }
  return false;
}

bool bad_any_of6() {
  int v[] = {1, 2, 3};
  for (int i : v) {
    if (i)
      return true;
  }
  int j = 0; // Statements between loop and return
  j++;
  return false;
}

bool bad_any_of7() {
  int v[] = {1, 2, 3};
  for (int i : v) {
    i; // No 'return true' in body.
  }
  return false;
}

bool good_all_of() {
  int v[] = {1, 2, 3};
  // CHECK-MESSAGES: :[[@LINE+1]]:3: warning: Replace loop by std::all_of() from <algorithm> [readability-use-algorithm]
  for (int i : v)
    if (i)
      return false;
  return true;
}
