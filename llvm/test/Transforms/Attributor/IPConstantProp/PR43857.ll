; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --scrub-attributes
; RUN: opt -S -passes=attributor -attributor-disable=false -attributor-max-iterations-verify -attributor-max-iterations=1 < %s | FileCheck %s

%struct.wobble = type { i32 }
%struct.zot = type { %struct.wobble, %struct.wobble, %struct.wobble }

declare dso_local fastcc float @bar(%struct.wobble* noalias, <8 x i32>) unnamed_addr

define %struct.zot @widget(<8 x i32> %arg) local_unnamed_addr {
; CHECK-LABEL: define {{[^@]+}}@widget
; CHECK-SAME: (<8 x i32> [[ARG:%.*]]) local_unnamed_addr
; CHECK-NEXT:  bb:
; CHECK-NEXT:    ret [[STRUCT_ZOT:%.*]] undef
;
bb:
  ret %struct.zot undef
}

define void @baz(<8 x i32> %arg) local_unnamed_addr {
; CHECK-LABEL: define {{[^@]+}}@baz
; CHECK-SAME: (<8 x i32> [[ARG:%.*]]) local_unnamed_addr
; CHECK-NEXT:  bb:
; CHECK-NEXT:    ret void
;
bb:
  %tmp = call %struct.zot @widget(<8 x i32> %arg)
  %tmp1 = extractvalue %struct.zot %tmp, 0, 0
  ret void
}
