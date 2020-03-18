; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -instcombine -S | FileCheck %s

declare void @use(float)
declare void @use_vec(<2 x float>)

; -x + y => y - x

define float @fneg_op0(float %x, float %y) {
; CHECK-LABEL: @fneg_op0(
; CHECK-NEXT:    [[ADD:%.*]] = fsub float [[Y:%.*]], [[X:%.*]]
; CHECK-NEXT:    ret float [[ADD]]
;
  %neg = fsub float -0.0, %x
  %add = fadd float %neg, %y
  ret float %add
}

; x + -y => x - y

define float @fneg_op1(float %x, float %y) {
; CHECK-LABEL: @fneg_op1(
; CHECK-NEXT:    [[ADD:%.*]] = fsub float [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    ret float [[ADD]]
;
  %neg = fsub float -0.0, %y
  %add = fadd float %x, %neg
  ret float %add
}

; Z + (-X / Y) --> Z - (X / Y)

define double @fdiv_fneg1(double %x, double %y, double %pz) {
; CHECK-LABEL: @fdiv_fneg1(
; CHECK-NEXT:    [[Z:%.*]] = frem double 4.200000e+01, [[PZ:%.*]]
; CHECK-NEXT:    [[TMP1:%.*]] = fdiv double [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[R:%.*]] = fsub double [[Z]], [[TMP1]]
; CHECK-NEXT:    ret double [[R]]
;
  %z = frem double 42.0, %pz ; thwart complexity-based canonicalization
  %neg = fsub double -0.000000e+00, %x
  %div = fdiv double %neg, %y
  %r = fadd double %z, %div
  ret double %r
}

; Z + (Y / -X) --> Z - (Y / X)

define <2 x double> @fdiv_fneg2(<2 x double> %x, <2 x double> %y, <2 x double> %pz) {
; CHECK-LABEL: @fdiv_fneg2(
; CHECK-NEXT:    [[Z:%.*]] = frem <2 x double> <double 4.200000e+01, double 8.000000e+00>, [[PZ:%.*]]
; CHECK-NEXT:    [[TMP1:%.*]] = fdiv <2 x double> [[Y:%.*]], [[X:%.*]]
; CHECK-NEXT:    [[R:%.*]] = fsub <2 x double> [[Z]], [[TMP1]]
; CHECK-NEXT:    ret <2 x double> [[R]]
;
  %z = frem <2 x double> <double 42.0, double 8.0>, %pz ; thwart complexity-based canonicalization
  %neg = fsub <2 x double> <double -0.0, double -0.0>, %x
  %div = fdiv <2 x double> %y, %neg
  %r = fadd <2 x double> %z, %div
  ret <2 x double> %r
}

; Z + (-X * Y) --> Z - (X * Y)

define double @fmul_fneg1(double %x, double %y, double %pz) {
; CHECK-LABEL: @fmul_fneg1(
; CHECK-NEXT:    [[Z:%.*]] = frem double 4.200000e+01, [[PZ:%.*]]
; CHECK-NEXT:    [[TMP1:%.*]] = fmul double [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[R:%.*]] = fsub double [[Z]], [[TMP1]]
; CHECK-NEXT:    ret double [[R]]
;
  %z = frem double 42.0, %pz ; thwart complexity-based canonicalization
  %neg = fsub double -0.000000e+00, %x
  %mul = fmul double %neg, %y
  %r = fadd double %z, %mul
  ret double %r
}

; Z + (Y * -X) --> Z - (Y * X)

define double @fmul_fneg2(double %x, double %py, double %pz) {
; CHECK-LABEL: @fmul_fneg2(
; CHECK-NEXT:    [[Y:%.*]] = frem double -4.200000e+01, [[PY:%.*]]
; CHECK-NEXT:    [[Z:%.*]] = frem double 4.200000e+01, [[PZ:%.*]]
; CHECK-NEXT:    [[TMP1:%.*]] = fmul double [[Y]], [[X:%.*]]
; CHECK-NEXT:    [[R:%.*]] = fsub double [[Z]], [[TMP1]]
; CHECK-NEXT:    ret double [[R]]
;
  %y = frem double -42.0, %py ; thwart complexity-based canonicalization
  %z = frem double 42.0, %pz ; thwart complexity-based canonicalization
  %neg = fsub double -0.000000e+00, %x
  %mul = fmul double %y, %neg
  %r = fadd double %z, %mul
  ret double %r
}

; (-X / Y) + Z --> Z - (X / Y)

define double @fdiv_fneg1_commute(double %x, double %y, double %pz) {
; CHECK-LABEL: @fdiv_fneg1_commute(
; CHECK-NEXT:    [[Z:%.*]] = frem double 4.200000e+01, [[PZ:%.*]]
; CHECK-NEXT:    [[TMP1:%.*]] = fdiv double [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[R:%.*]] = fsub double [[Z]], [[TMP1]]
; CHECK-NEXT:    ret double [[R]]
;
  %z = frem double 42.0, %pz ; thwart complexity-based canonicalization
  %neg = fsub double -0.000000e+00, %x
  %div = fdiv double %neg, %y
  %r = fadd double %div, %z
  ret double %r
}

; (Y / -X) + Z --> Z - (Y / X)

define <2 x double> @fdiv_fneg2_commute(<2 x double> %x, <2 x double> %y, <2 x double> %pz) {
; CHECK-LABEL: @fdiv_fneg2_commute(
; CHECK-NEXT:    [[Z:%.*]] = frem <2 x double> <double 4.200000e+01, double 8.000000e+00>, [[PZ:%.*]]
; CHECK-NEXT:    [[TMP1:%.*]] = fdiv <2 x double> [[Y:%.*]], [[X:%.*]]
; CHECK-NEXT:    [[R:%.*]] = fsub <2 x double> [[Z]], [[TMP1]]
; CHECK-NEXT:    ret <2 x double> [[R]]
;
  %z = frem <2 x double> <double 42.0, double 8.0>, %pz ; thwart complexity-based canonicalization
  %neg = fsub <2 x double> <double -0.0, double -0.0>, %x
  %div = fdiv <2 x double> %y, %neg
  %r = fadd <2 x double> %div, %z
  ret <2 x double> %r
}

; (-X * Y) + Z --> Z - (X * Y)

define double @fmul_fneg1_commute(double %x, double %y, double %pz) {
; CHECK-LABEL: @fmul_fneg1_commute(
; CHECK-NEXT:    [[Z:%.*]] = frem double 4.200000e+01, [[PZ:%.*]]
; CHECK-NEXT:    [[TMP1:%.*]] = fmul double [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[R:%.*]] = fsub double [[Z]], [[TMP1]]
; CHECK-NEXT:    ret double [[R]]
;
  %z = frem double 42.0, %pz ; thwart complexity-based canonicalization
  %neg = fsub double -0.000000e+00, %x
  %mul = fmul double %neg, %y
  %r = fadd double %mul, %z
  ret double %r
}

; (Y * -X) + Z --> Z - (Y * X)

define double @fmul_fneg2_commute(double %x, double %py, double %pz) {
; CHECK-LABEL: @fmul_fneg2_commute(
; CHECK-NEXT:    [[Y:%.*]] = frem double 4.100000e+01, [[PY:%.*]]
; CHECK-NEXT:    [[Z:%.*]] = frem double 4.200000e+01, [[PZ:%.*]]
; CHECK-NEXT:    [[TMP1:%.*]] = fmul double [[Y]], [[X:%.*]]
; CHECK-NEXT:    [[R:%.*]] = fsub double [[Z]], [[TMP1]]
; CHECK-NEXT:    ret double [[R]]
;
  %y = frem double 41.0, %py ; thwart complexity-based canonicalization
  %z = frem double 42.0, %pz ; thwart complexity-based canonicalization
  %neg = fsub double -0.000000e+00, %x
  %mul = fmul double %y, %neg
  %r = fadd double %mul, %z
  ret double %r
}

; Z + (-X / Y) - extra use means we can't transform to fsub without an extra instruction

define float @fdiv_fneg1_extra_use(float %x, float %y, float %pz) {
; CHECK-LABEL: @fdiv_fneg1_extra_use(
; CHECK-NEXT:    [[Z:%.*]] = frem float 4.200000e+01, [[PZ:%.*]]
; CHECK-NEXT:    [[NEG:%.*]] = fneg float [[X:%.*]]
; CHECK-NEXT:    [[DIV:%.*]] = fdiv float [[NEG]], [[Y:%.*]]
; CHECK-NEXT:    call void @use(float [[DIV]])
; CHECK-NEXT:    [[R:%.*]] = fadd float [[Z]], [[DIV]]
; CHECK-NEXT:    ret float [[R]]
;
  %z = frem float 42.0, %pz ; thwart complexity-based canonicalization
  %neg = fsub float -0.000000e+00, %x
  %div = fdiv float %neg, %y
  call void @use(float %div)
  %r = fadd float %z, %div
  ret float %r
}

; Z + (Y / -X) - extra use means we can't transform to fsub without an extra instruction

define float @fdiv_fneg2_extra_use(float %x, float %py, float %pz) {
; CHECK-LABEL: @fdiv_fneg2_extra_use(
; CHECK-NEXT:    [[Y:%.*]] = frem float -4.200000e+01, [[PY:%.*]]
; CHECK-NEXT:    [[Z:%.*]] = frem float 4.200000e+01, [[PZ:%.*]]
; CHECK-NEXT:    [[NEG:%.*]] = fneg float [[X:%.*]]
; CHECK-NEXT:    [[DIV:%.*]] = fdiv float [[Y]], [[NEG]]
; CHECK-NEXT:    call void @use(float [[DIV]])
; CHECK-NEXT:    [[R:%.*]] = fadd float [[Z]], [[DIV]]
; CHECK-NEXT:    ret float [[R]]
;
  %y = frem float -42.0, %py ; thwart complexity-based canonicalization
  %z = frem float 42.0, %pz ; thwart complexity-based canonicalization
  %neg = fsub float -0.000000e+00, %x
  %div = fdiv float %y, %neg
  call void @use(float %div)
  %r = fadd float %z, %div
  ret float %r
}

; Z + (-X * Y) - extra use means we can't transform to fsub without an extra instruction

define <2 x float> @fmul_fneg1_extra_use(<2 x float> %x, <2 x float> %y, <2 x float> %pz) {
; CHECK-LABEL: @fmul_fneg1_extra_use(
; CHECK-NEXT:    [[Z:%.*]] = frem <2 x float> <float 4.200000e+01, float -1.000000e+00>, [[PZ:%.*]]
; CHECK-NEXT:    [[NEG:%.*]] = fneg <2 x float> [[X:%.*]]
; CHECK-NEXT:    [[MUL:%.*]] = fmul <2 x float> [[NEG]], [[Y:%.*]]
; CHECK-NEXT:    call void @use_vec(<2 x float> [[MUL]])
; CHECK-NEXT:    [[R:%.*]] = fadd <2 x float> [[Z]], [[MUL]]
; CHECK-NEXT:    ret <2 x float> [[R]]
;
  %z = frem <2 x float> <float 42.0, float -1.0>, %pz ; thwart complexity-based canonicalization
  %neg = fsub <2 x float> <float -0.0, float -0.0>, %x
  %mul = fmul <2 x float> %neg, %y
  call void @use_vec(<2 x float> %mul)
  %r = fadd <2 x float> %z, %mul
  ret <2 x float> %r
}

; Z + (Y * -X) - extra use means we can't transform to fsub without an extra instruction

define float @fmul_fneg2_extra_use(float %x, float %py, float %pz) {
; CHECK-LABEL: @fmul_fneg2_extra_use(
; CHECK-NEXT:    [[Y:%.*]] = frem float -4.200000e+01, [[PY:%.*]]
; CHECK-NEXT:    [[Z:%.*]] = frem float 4.200000e+01, [[PZ:%.*]]
; CHECK-NEXT:    [[NEG:%.*]] = fneg float [[X:%.*]]
; CHECK-NEXT:    [[MUL:%.*]] = fmul float [[Y]], [[NEG]]
; CHECK-NEXT:    call void @use(float [[MUL]])
; CHECK-NEXT:    [[R:%.*]] = fadd float [[Z]], [[MUL]]
; CHECK-NEXT:    ret float [[R]]
;
  %y = frem float -42.0, %py ; thwart complexity-based canonicalization
  %z = frem float 42.0, %pz ; thwart complexity-based canonicalization
  %neg = fsub float -0.000000e+00, %x
  %mul = fmul float %y, %neg
  call void @use(float %mul)
  %r = fadd float %z, %mul
  ret float %r
}

; (-X / Y) + Z --> Z - (X / Y)

define float @fdiv_fneg1_extra_use2(float %x, float %y, float %z) {
; CHECK-LABEL: @fdiv_fneg1_extra_use2(
; CHECK-NEXT:    [[NEG:%.*]] = fneg float [[X:%.*]]
; CHECK-NEXT:    call void @use(float [[NEG]])
; CHECK-NEXT:    [[TMP1:%.*]] = fdiv float [[X]], [[Y:%.*]]
; CHECK-NEXT:    [[R:%.*]] = fsub float [[Z:%.*]], [[TMP1]]
; CHECK-NEXT:    ret float [[R]]
;
  %neg = fsub float -0.000000e+00, %x
  call void @use(float %neg)
  %div = fdiv float %neg, %y
  %r = fadd float %div, %z
  ret float %r
}

; (Y / -X) + Z --> Z - (Y / X)

define float @fdiv_fneg2_extra_use2(float %x, float %y, float %z) {
; CHECK-LABEL: @fdiv_fneg2_extra_use2(
; CHECK-NEXT:    [[NEG:%.*]] = fneg float [[X:%.*]]
; CHECK-NEXT:    call void @use(float [[NEG]])
; CHECK-NEXT:    [[TMP1:%.*]] = fdiv float [[Y:%.*]], [[X]]
; CHECK-NEXT:    [[R:%.*]] = fsub float [[Z:%.*]], [[TMP1]]
; CHECK-NEXT:    ret float [[R]]
;
  %neg = fsub float -0.000000e+00, %x
  call void @use(float %neg)
  %div = fdiv float %y, %neg
  %r = fadd float %div, %z
  ret float %r
}

; (-X * Y) + Z --> Z - (X * Y)

define <2 x float> @fmul_fneg1_extra_use2(<2 x float> %x, <2 x float> %y, <2 x float> %z) {
; CHECK-LABEL: @fmul_fneg1_extra_use2(
; CHECK-NEXT:    [[NEG:%.*]] = fneg <2 x float> [[X:%.*]]
; CHECK-NEXT:    call void @use_vec(<2 x float> [[NEG]])
; CHECK-NEXT:    [[TMP1:%.*]] = fmul <2 x float> [[X]], [[Y:%.*]]
; CHECK-NEXT:    [[R:%.*]] = fsub <2 x float> [[Z:%.*]], [[TMP1]]
; CHECK-NEXT:    ret <2 x float> [[R]]
;
  %neg = fsub <2 x float> <float -0.0, float -0.0>, %x
  call void @use_vec(<2 x float> %neg)
  %mul = fmul <2 x float> %neg, %y
  %r = fadd <2 x float> %mul, %z
  ret <2 x float> %r
}

; (Y * -X) + Z --> Z - (Y * X)

define float @fmul_fneg2_extra_use2(float %x, float %py, float %z) {
; CHECK-LABEL: @fmul_fneg2_extra_use2(
; CHECK-NEXT:    [[Y:%.*]] = frem float -4.200000e+01, [[PY:%.*]]
; CHECK-NEXT:    [[NEG:%.*]] = fneg float [[X:%.*]]
; CHECK-NEXT:    call void @use(float [[NEG]])
; CHECK-NEXT:    [[TMP1:%.*]] = fmul float [[Y]], [[X]]
; CHECK-NEXT:    [[R:%.*]] = fsub float [[Z:%.*]], [[TMP1]]
; CHECK-NEXT:    ret float [[R]]
;
  %y = frem float -42.0, %py ; thwart complexity-based canonicalization
  %neg = fsub float -0.000000e+00, %x
  call void @use(float %neg)
  %mul = fmul float %y, %neg
  %r = fadd float %mul, %z
  ret float %r
}

; (-X / Y) + Z --> Z - (X / Y)

define float @fdiv_fneg1_extra_use3(float %x, float %y, float %z) {
; CHECK-LABEL: @fdiv_fneg1_extra_use3(
; CHECK-NEXT:    [[NEG:%.*]] = fneg float [[X:%.*]]
; CHECK-NEXT:    call void @use(float [[NEG]])
; CHECK-NEXT:    [[DIV:%.*]] = fdiv float [[NEG]], [[Y:%.*]]
; CHECK-NEXT:    call void @use(float [[DIV]])
; CHECK-NEXT:    [[R:%.*]] = fadd float [[DIV]], [[Z:%.*]]
; CHECK-NEXT:    ret float [[R]]
;
  %neg = fsub float -0.000000e+00, %x
  call void @use(float %neg)
  %div = fdiv float %neg, %y
  call void @use(float %div)
  %r = fadd float %div, %z
  ret float %r
}

; (Y / -X) + Z --> Z - (Y / X)

define float @fdiv_fneg2_extra_use3(float %x, float %y, float %z) {
; CHECK-LABEL: @fdiv_fneg2_extra_use3(
; CHECK-NEXT:    [[NEG:%.*]] = fneg float [[X:%.*]]
; CHECK-NEXT:    call void @use(float [[NEG]])
; CHECK-NEXT:    [[DIV:%.*]] = fdiv float [[Y:%.*]], [[NEG]]
; CHECK-NEXT:    call void @use(float [[DIV]])
; CHECK-NEXT:    [[R:%.*]] = fadd float [[DIV]], [[Z:%.*]]
; CHECK-NEXT:    ret float [[R]]
;
  %neg = fsub float -0.000000e+00, %x
  call void @use(float %neg)
  %div = fdiv float %y, %neg
  call void @use(float %div)
  %r = fadd float %div, %z
  ret float %r
}

; (-X * Y) + Z --> Z - (X * Y)

define <2 x float> @fmul_fneg1_extra_use3(<2 x float> %x, <2 x float> %y, <2 x float> %z) {
; CHECK-LABEL: @fmul_fneg1_extra_use3(
; CHECK-NEXT:    [[NEG:%.*]] = fneg <2 x float> [[X:%.*]]
; CHECK-NEXT:    call void @use_vec(<2 x float> [[NEG]])
; CHECK-NEXT:    [[MUL:%.*]] = fmul <2 x float> [[NEG]], [[Y:%.*]]
; CHECK-NEXT:    call void @use_vec(<2 x float> [[MUL]])
; CHECK-NEXT:    [[R:%.*]] = fadd <2 x float> [[MUL]], [[Z:%.*]]
; CHECK-NEXT:    ret <2 x float> [[R]]
;
  %neg = fsub <2 x float> <float -0.0, float -0.0>, %x
  call void @use_vec(<2 x float> %neg)
  %mul = fmul <2 x float> %neg, %y
  call void @use_vec(<2 x float> %mul)
  %r = fadd <2 x float> %mul, %z
  ret <2 x float> %r
}

; (Y * -X) + Z --> Z - (Y * X)

define float @fmul_fneg2_extra_use3(float %x, float %py, float %z) {
; CHECK-LABEL: @fmul_fneg2_extra_use3(
; CHECK-NEXT:    [[Y:%.*]] = frem float -4.200000e+01, [[PY:%.*]]
; CHECK-NEXT:    [[NEG:%.*]] = fneg float [[X:%.*]]
; CHECK-NEXT:    call void @use(float [[NEG]])
; CHECK-NEXT:    [[MUL:%.*]] = fmul float [[Y]], [[NEG]]
; CHECK-NEXT:    call void @use(float [[MUL]])
; CHECK-NEXT:    [[R:%.*]] = fadd float [[MUL]], [[Z:%.*]]
; CHECK-NEXT:    ret float [[R]]
;
  %y = frem float -42.0, %py ; thwart complexity-based canonicalization
  %neg = fsub float -0.000000e+00, %x
  call void @use(float %neg)
  %mul = fmul float %y, %neg
  call void @use(float %mul)
  %r = fadd float %mul, %z
  ret float %r
}
