; RUN: llvm-as %s -o %t0.bc
; RUN: llvm-as %S/Inputs/ipa.ll -o %t1.bc
; RUN: llvm-link -disable-lazy-loading %t0.bc %t1.bc -o %t.combined.bc
; RUN: opt -S -analyze -stack-safety-local %t.combined.bc | FileCheck %s --check-prefixes=CHECK,LOCAL
; RUN: opt -S -passes="print<stack-safety-local>" -disable-output %t.combined.bc 2>&1 | FileCheck %s --check-prefixes=CHECK,LOCAL
; RUN: opt -S -analyze -stack-safety %t.combined.bc | FileCheck %s --check-prefixes=CHECK,GLOBAL
; RUN: opt -S -passes="print-stack-safety" -disable-output %t.combined.bc 2>&1 | FileCheck %s --check-prefixes=CHECK,GLOBAL

target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare void @Write1(i8* %p)
declare void @Write4(i8* %p)
declare void @Write4_2(i8* %p, i8* %q)
declare void @Write8(i8* %p)
declare dso_local i8* @WriteAndReturn8(i8* %p)
declare dso_local void @ExternalCall(i8* %p)
declare void @PreemptableWrite1(i8* %p)
declare void @InterposableWrite1(i8* %p)
declare i8* @ReturnDependent(i8* %p)
declare void @Rec2(i8* %p)
declare void @RecursiveNoOffset(i32* %p, i32 %size, i32* %acc)
declare void @RecursiveWithOffset(i32 %size, i32* %acc)

; Basic out-of-bounds.
define void @f1() {
; CHECK-LABEL: @f1 dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[4]: empty-set, @Write8(arg0, [0,1)){{$}}
; GLOBAL-NEXT: x[4]: [0,8), @Write8(arg0, [0,1)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i32, align 4
  %x1 = bitcast i32* %x to i8*
  call void @Write8(i8* %x1)
  ret void
}

; Basic in-bounds.
define void @f2() {
; CHECK-LABEL: @f2 dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[4]: empty-set, @Write1(arg0, [0,1)){{$}}
; GLOBAL-NEXT: x[4]: [0,1), @Write1(arg0, [0,1)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i32, align 4
  %x1 = bitcast i32* %x to i8*
  call void @Write1(i8* %x1)
  ret void
}

; Another basic in-bounds.
define void @f3() {
; CHECK-LABEL: @f3 dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[4]: empty-set, @Write4(arg0, [0,1)){{$}}
; GLOBAL-NEXT: x[4]: [0,4), @Write4(arg0, [0,1)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i32, align 4
  %x1 = bitcast i32* %x to i8*
  call void @Write4(i8* %x1)
  ret void
}

; In-bounds with offset.
define void @f4() {
; CHECK-LABEL: @f4 dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[4]: empty-set, @Write1(arg0, [1,2)){{$}}
; GLOBAL-NEXT: x[4]: [1,2), @Write1(arg0, [1,2)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i32, align 4
  %x1 = bitcast i32* %x to i8*
  %x2 = getelementptr i8, i8* %x1, i64 1
  call void @Write1(i8* %x2)
  ret void
}

; Out-of-bounds with offset.
define void @f5() {
; CHECK-LABEL: @f5 dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: empty-set, @Write4(arg0, [1,2)){{$}}
; GLOBAL-NEXT: [1,5), @Write4(arg0, [1,2)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i32, align 4
  %x1 = bitcast i32* %x to i8*
  %x2 = getelementptr i8, i8* %x1, i64 1
  call void @Write4(i8* %x2)
  ret void
}

; External call.
define void @f6() {
; CHECK-LABEL: @f6 dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[4]: empty-set, @ExternalCall(arg0, [0,1)){{$}}
; GLOBAL-NEXT: x[4]: full-set, @ExternalCall(arg0, [0,1)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i32, align 4
  %x1 = bitcast i32* %x to i8*
  call void @ExternalCall(i8* %x1)
  ret void
}

; Call to dso_preemptable function
define void @PreemptableCall() {
; CHECK-LABEL: @PreemptableCall dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[4]: empty-set, @PreemptableWrite1(arg0, [0,1)){{$}}
; GLOBAL-NEXT: x[4]: full-set, @PreemptableWrite1(arg0, [0,1)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i32, align 4
  %x1 = bitcast i32* %x to i8*
  call void @PreemptableWrite1(i8* %x1)
  ret void
}

; Call to function with interposable linkage
define void @InterposableCall() {
; CHECK-LABEL: @InterposableCall dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[4]: empty-set, @InterposableWrite1(arg0, [0,1)){{$}}
; GLOBAL-NEXT: x[4]: full-set, @InterposableWrite1(arg0, [0,1)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i32, align 4
  %x1 = bitcast i32* %x to i8*
  call void @InterposableWrite1(i8* %x1)
  ret void
}

; Call to function with private linkage
define void @PrivateCall() {
; CHECK-LABEL: @PrivateCall dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[4]: empty-set, @PrivateWrite1(arg0, [0,1)){{$}}
; GLOBAL-NEXT: x[4]: [0,1), @PrivateWrite1(arg0, [0,1)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i32, align 4
  %x1 = bitcast i32* %x to i8*
  call void @PrivateWrite1(i8* %x1)
  ret void
}

define private void @PrivateWrite1(i8* %p) {
; CHECK-LABEL: @PrivateWrite1{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: p[]: [0,1){{$}}
; CHECK-NEXT: allocas uses:
; CHECK-NOT: ]:
entry:
  store i8 0, i8* %p, align 1
  ret void
}

; Caller returns a dependent value.
; FIXME: alloca considered unsafe even if the return value is unused.
define void @f7() {
; CHECK-LABEL: @f7 dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[4]: empty-set, @ReturnDependent(arg0, [0,1)){{$}}
; GLOBAL-NEXT: x[4]: full-set, @ReturnDependent(arg0, [0,1)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i32, align 4
  %x1 = bitcast i32* %x to i8*
  %x2 = call i8* @ReturnDependent(i8* %x1)
  ret void
}

define void @f8left() {
; CHECK-LABEL: @f8left dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[8]: empty-set, @Rec2(arg0, [2,3)){{$}}
; GLOBAL-NEXT: x[8]: [0,4), @Rec2(arg0, [2,3)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i64, align 4
  %x1 = bitcast i64* %x to i8*
  %x2 = getelementptr i8, i8* %x1, i64 2
; 2 + [-2, 2) = [0, 4) => OK
  call void @Rec2(i8* %x2)
  ret void
}

define void @f8right() {
; CHECK-LABEL: @f8right dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[8]: empty-set, @Rec2(arg0, [6,7)){{$}}
; GLOBAL-NEXT: x[8]: [4,8), @Rec2(arg0, [6,7)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i64, align 4
  %x1 = bitcast i64* %x to i8*
  %x2 = getelementptr i8, i8* %x1, i64 6
; 6 + [-2, 2) = [4, 8) => OK
  call void @Rec2(i8* %x2)
  ret void
}

define void @f8oobleft() {
; CHECK-LABEL: @f8oobleft dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[8]: empty-set, @Rec2(arg0, [1,2)){{$}}
; GLOBAL-NEXT: x[8]: [-1,3), @Rec2(arg0, [1,2)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i64, align 4
  %x1 = bitcast i64* %x to i8*
  %x2 = getelementptr i8, i8* %x1, i64 1
; 1 + [-2, 2) = [-1, 3) => NOT OK
  call void @Rec2(i8* %x2)
  ret void
}

define void @f8oobright() {
; CHECK-LABEL: @f8oobright dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[8]: empty-set, @Rec2(arg0, [7,8)){{$}}
; GLOBAL-NEXT: x[8]: [5,9), @Rec2(arg0, [7,8)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i64, align 4
  %x1 = bitcast i64* %x to i8*
  %x2 = getelementptr i8, i8* %x1, i64 7
; 7 + [-2, 2) = [5, 9) => NOT OK
  call void @Rec2(i8* %x2)
  ret void
}

define void @TwoArguments() {
; CHECK-LABEL: @TwoArguments dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[8]: empty-set, @Write4_2(arg1, [0,1)), @Write4_2(arg0, [4,5)){{$}}
; GLOBAL-NEXT: x[8]: [0,8), @Write4_2(arg1, [0,1)), @Write4_2(arg0, [4,5)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i64, align 4
  %x1 = bitcast i64* %x to i8*
  %x2 = getelementptr i8, i8* %x1, i64 4
  call void @Write4_2(i8* %x2, i8* %x1)
  ret void
}

define void @TwoArgumentsOOBOne() {
; CHECK-LABEL: @TwoArgumentsOOBOne dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[8]: empty-set, @Write4_2(arg1, [0,1)), @Write4_2(arg0, [5,6)){{$}}
; GLOBAL-NEXT: x[8]: [0,9), @Write4_2(arg1, [0,1)), @Write4_2(arg0, [5,6)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i64, align 4
  %x1 = bitcast i64* %x to i8*
  %x2 = getelementptr i8, i8* %x1, i64 5
  call void @Write4_2(i8* %x2, i8* %x1)
  ret void
}

define void @TwoArgumentsOOBOther() {
; CHECK-LABEL: @TwoArgumentsOOBOther dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[8]: empty-set, @Write4_2(arg1, [-1,0)), @Write4_2(arg0, [4,5)){{$}}
; GLOBAL-NEXT: x[8]: [-1,8), @Write4_2(arg1, [-1,0)), @Write4_2(arg0, [4,5)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i64, align 4
  %x0 = bitcast i64* %x to i8*
  %x1 = getelementptr i8, i8* %x0, i64 -1
  %x2 = getelementptr i8, i8* %x0, i64 4
  call void @Write4_2(i8* %x2, i8* %x1)
  ret void
}

define void @TwoArgumentsOOBBoth() {
; CHECK-LABEL: @TwoArgumentsOOBBoth dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[8]: empty-set, @Write4_2(arg1, [-1,0)), @Write4_2(arg0, [5,6)){{$}}
; GLOBAL-NEXT: x[8]: [-1,9), @Write4_2(arg1, [-1,0)), @Write4_2(arg0, [5,6)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i64, align 4
  %x0 = bitcast i64* %x to i8*
  %x1 = getelementptr i8, i8* %x0, i64 -1
  %x2 = getelementptr i8, i8* %x0, i64 5
  call void @Write4_2(i8* %x2, i8* %x1)
  ret void
}

define i32 @TestRecursiveNoOffset(i32* %p, i32 %size) {
; CHECK-LABEL: @TestRecursiveNoOffset dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; LOCAL-NEXT: p[]: empty-set, @RecursiveNoOffset(arg0, [0,1)){{$}}
; GLOBAL-NEXT: p[]: full-set, @RecursiveNoOffset(arg0, [0,1)){{$}}
; CHECK-NEXT: size[]: empty-set, @RecursiveNoOffset(arg1, [0,1)){{$}}
; CHECK-NEXT: allocas uses:
; CHECK-NEXT: sum[4]: [0,4), @RecursiveNoOffset(arg2, [0,1)){{$}}
; CHECK-NOT: ]:
entry:
  %sum = alloca i32, align 4
  %0 = bitcast i32* %sum to i8*
  store i32 0, i32* %sum, align 4
  call void @RecursiveNoOffset(i32* %p, i32 %size, i32* %sum)
  %1 = load i32, i32* %sum, align 4
  ret i32 %1
}

define void @TestRecursiveWithOffset(i32 %size) {
; CHECK-LABEL: @TestRecursiveWithOffset dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: size[]: empty-set, @RecursiveWithOffset(arg0, [0,1)){{$}}
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: sum[64]: empty-set, @RecursiveWithOffset(arg1, [0,1)){{$}}
; GLOBAL-NEXT: sum[64]: full-set, @RecursiveWithOffset(arg1, [0,1)){{$}}
; CHECK-NOT: ]:
entry:
  %sum = alloca i32, i64 16, align 4
  call void @RecursiveWithOffset(i32 %size, i32* %sum)
  ret void
}

; FIXME: IPA should detect that access is safe
define void @TestUpdateArg() {
; CHECK-LABEL: @TestUpdateArg dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: allocas uses:
; LOCAL-NEXT: x[16]: empty-set, @WriteAndReturn8(arg0, [0,1)){{$}}
; GLOBAL-NEXT: x[16]: full-set, @WriteAndReturn8(arg0, [0,1)){{$}}
; CHECK-NOT: ]:
entry:
  %x = alloca i8, i64 16, align 4
  %0 = call i8* @WriteAndReturn8(i8* %x)
  ret void
}

; The rest is from Inputs/ipa.ll

; CHECK-LABEL: @Write1{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: p[]: [0,1){{$}}
; CHECK-NEXT: allocas uses:
; CHECK-NOT: ]:

; CHECK-LABEL: @Write4{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: p[]: [0,4){{$}}
; CHECK-NEXT: allocas uses:
; CHECK-NOT: ]:

; CHECK-LABEL: @Write4_2{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: p[]: [0,4){{$}}
; CHECK-NEXT: q[]: [0,4){{$}}
; CHECK-NEXT: allocas uses:
; CHECK-NOT: ]:

; CHECK-LABEL: @Write8{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: p[]: [0,8){{$}}
; CHECK-NEXT: allocas uses:
; CHECK-NOT: ]:

; CHECK-LABEL: @WriteAndReturn8{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: p[]: full-set{{$}}
; CHECK-NEXT: allocas uses:
; CHECK-NOT: ]:

; CHECK-LABEL: @PreemptableWrite1 dso_preemptable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: p[]: [0,1){{$}}
; CHECK-NEXT: allocas uses:
; CHECK-NOT: ]:

; CHECK-LABEL: @InterposableWrite1 interposable{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: p[]: [0,1){{$}}
; CHECK-NEXT: allocas uses:
; CHECK-NOT: ]:

; CHECK-LABEL: @ReturnDependent{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: p[]: full-set{{$}}
; CHECK-NEXT: allocas uses:
; CHECK-NOT: ]:

; CHECK-LABEL: @Rec0{{$}}
; CHECK-NEXT: args uses:
; LOCAL-NEXT: p[]: empty-set, @Write4(arg0, [2,3)){{$}}
; GLOBAL-NEXT: p[]: [2,6), @Write4(arg0, [2,3)){{$}}
; CHECK-NEXT: allocas uses:
; CHECK-NOT: ]:

; CHECK-LABEL: @Rec1{{$}}
; CHECK-NEXT: args uses:
; LOCAL-NEXT: p[]: empty-set, @Rec0(arg0, [1,2)){{$}}
; GLOBAL-NEXT: p[]: [3,7), @Rec0(arg0, [1,2)){{$}}
; CHECK-NEXT: allocas uses:
; CHECK-NOT: ]:

; CHECK-LABEL: @Rec2{{$}}
; CHECK-NEXT: args uses:
; LOCAL-NEXT: p[]: empty-set, @Rec1(arg0, [-5,-4)){{$}}
; GLOBAL-NEXT: p[]: [-2,2), @Rec1(arg0, [-5,-4)){{$}}
; CHECK-NEXT: allocas uses:
; CHECK-NOT: ]:

; CHECK-LABEL: @RecursiveNoOffset{{$}}
; CHECK-NEXT: args uses:
; LOCAL-NEXT: p[]: [0,4), @RecursiveNoOffset(arg0, [4,5)){{$}}
; GLOBAL-NEXT: p[]: full-set, @RecursiveNoOffset(arg0, [4,5)){{$}}
; CHECK-NEXT: size[]: empty-set, @RecursiveNoOffset(arg1, [4294967295,4294967296)){{$}}
; CHECK-NEXT: acc[]: [0,4), @RecursiveNoOffset(arg2, [0,1)){{$}}
; CHECK-NEXT: allocas uses:
; CHECK-NOT: ]:

; CHECK-LABEL: @RecursiveWithOffset{{$}}
; CHECK-NEXT: args uses:
; CHECK-NEXT: size[]: empty-set, @RecursiveWithOffset(arg0, [4294967295,4294967296)){{$}}
; LOCAL-NEXT: acc[]: [0,4), @RecursiveWithOffset(arg1, [4,5)){{$}}
; GLOBAL-NEXT: acc[]: full-set, @RecursiveWithOffset(arg1, [4,5)){{$}}
; CHECK-NEXT: allocas uses:
; CHECK-NOT: ]:
