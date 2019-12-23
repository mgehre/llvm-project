; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -lower-matrix-intrinsics -matrix-allow-contract -S < %s | FileCheck %s
; RUN: opt -passes='lower-matrix-intrinsics' -matrix-allow-contract -S < %s | FileCheck %s


define <4 x double> @multiply_2x2(<4 x double> %a, <4 x double> %b) {
; CHECK-LABEL: @multiply_2x2(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SPLIT:%.*]] = shufflevector <4 x double> [[A:%.*]], <4 x double> undef, <2 x i32> <i32 0, i32 1>
; CHECK-NEXT:    [[SPLIT1:%.*]] = shufflevector <4 x double> [[A]], <4 x double> undef, <2 x i32> <i32 2, i32 3>
; CHECK-NEXT:    [[SPLIT2:%.*]] = shufflevector <4 x double> [[B:%.*]], <4 x double> undef, <2 x i32> <i32 0, i32 1>
; CHECK-NEXT:    [[SPLIT3:%.*]] = shufflevector <4 x double> [[B]], <4 x double> undef, <2 x i32> <i32 2, i32 3>
; CHECK-NEXT:    [[BLOCK:%.*]] = shufflevector <2 x double> [[SPLIT]], <2 x double> undef, <1 x i32> zeroinitializer
; CHECK-NEXT:    [[TMP0:%.*]] = extractelement <2 x double> [[SPLIT2]], i64 0
; CHECK-NEXT:    [[SPLAT_SPLATINSERT:%.*]] = insertelement <1 x double> undef, double [[TMP0]], i32 0
; CHECK-NEXT:    [[SPLAT_SPLAT:%.*]] = shufflevector <1 x double> [[SPLAT_SPLATINSERT]], <1 x double> undef, <1 x i32> zeroinitializer
; CHECK-NEXT:    [[TMP1:%.*]] = fmul <1 x double> [[BLOCK]], [[SPLAT_SPLAT]]
; CHECK-NEXT:    [[BLOCK4:%.*]] = shufflevector <2 x double> [[SPLIT1]], <2 x double> undef, <1 x i32> zeroinitializer
; CHECK-NEXT:    [[TMP2:%.*]] = extractelement <2 x double> [[SPLIT2]], i64 1
; CHECK-NEXT:    [[SPLAT_SPLATINSERT5:%.*]] = insertelement <1 x double> undef, double [[TMP2]], i32 0
; CHECK-NEXT:    [[SPLAT_SPLAT6:%.*]] = shufflevector <1 x double> [[SPLAT_SPLATINSERT5]], <1 x double> undef, <1 x i32> zeroinitializer
; CHECK-NEXT:    [[TMP3:%.*]] = call <1 x double> @llvm.fmuladd.v1f64(<1 x double> [[BLOCK4]], <1 x double> [[SPLAT_SPLAT6]], <1 x double> [[TMP1]])
; CHECK-NEXT:    [[TMP4:%.*]] = shufflevector <1 x double> [[TMP3]], <1 x double> undef, <2 x i32> <i32 0, i32 undef>
; CHECK-NEXT:    [[TMP5:%.*]] = shufflevector <2 x double> undef, <2 x double> [[TMP4]], <2 x i32> <i32 2, i32 1>
; CHECK-NEXT:    [[BLOCK7:%.*]] = shufflevector <2 x double> [[SPLIT]], <2 x double> undef, <1 x i32> <i32 1>
; CHECK-NEXT:    [[TMP6:%.*]] = extractelement <2 x double> [[SPLIT2]], i64 0
; CHECK-NEXT:    [[SPLAT_SPLATINSERT8:%.*]] = insertelement <1 x double> undef, double [[TMP6]], i32 0
; CHECK-NEXT:    [[SPLAT_SPLAT9:%.*]] = shufflevector <1 x double> [[SPLAT_SPLATINSERT8]], <1 x double> undef, <1 x i32> zeroinitializer
; CHECK-NEXT:    [[TMP7:%.*]] = fmul <1 x double> [[BLOCK7]], [[SPLAT_SPLAT9]]
; CHECK-NEXT:    [[BLOCK10:%.*]] = shufflevector <2 x double> [[SPLIT1]], <2 x double> undef, <1 x i32> <i32 1>
; CHECK-NEXT:    [[TMP8:%.*]] = extractelement <2 x double> [[SPLIT2]], i64 1
; CHECK-NEXT:    [[SPLAT_SPLATINSERT11:%.*]] = insertelement <1 x double> undef, double [[TMP8]], i32 0
; CHECK-NEXT:    [[SPLAT_SPLAT12:%.*]] = shufflevector <1 x double> [[SPLAT_SPLATINSERT11]], <1 x double> undef, <1 x i32> zeroinitializer
; CHECK-NEXT:    [[TMP9:%.*]] = call <1 x double> @llvm.fmuladd.v1f64(<1 x double> [[BLOCK10]], <1 x double> [[SPLAT_SPLAT12]], <1 x double> [[TMP7]])
; CHECK-NEXT:    [[TMP10:%.*]] = shufflevector <1 x double> [[TMP9]], <1 x double> undef, <2 x i32> <i32 0, i32 undef>
; CHECK-NEXT:    [[TMP11:%.*]] = shufflevector <2 x double> [[TMP5]], <2 x double> [[TMP10]], <2 x i32> <i32 0, i32 2>
; CHECK-NEXT:    [[BLOCK13:%.*]] = shufflevector <2 x double> [[SPLIT]], <2 x double> undef, <1 x i32> zeroinitializer
; CHECK-NEXT:    [[TMP12:%.*]] = extractelement <2 x double> [[SPLIT3]], i64 0
; CHECK-NEXT:    [[SPLAT_SPLATINSERT14:%.*]] = insertelement <1 x double> undef, double [[TMP12]], i32 0
; CHECK-NEXT:    [[SPLAT_SPLAT15:%.*]] = shufflevector <1 x double> [[SPLAT_SPLATINSERT14]], <1 x double> undef, <1 x i32> zeroinitializer
; CHECK-NEXT:    [[TMP13:%.*]] = fmul <1 x double> [[BLOCK13]], [[SPLAT_SPLAT15]]
; CHECK-NEXT:    [[BLOCK16:%.*]] = shufflevector <2 x double> [[SPLIT1]], <2 x double> undef, <1 x i32> zeroinitializer
; CHECK-NEXT:    [[TMP14:%.*]] = extractelement <2 x double> [[SPLIT3]], i64 1
; CHECK-NEXT:    [[SPLAT_SPLATINSERT17:%.*]] = insertelement <1 x double> undef, double [[TMP14]], i32 0
; CHECK-NEXT:    [[SPLAT_SPLAT18:%.*]] = shufflevector <1 x double> [[SPLAT_SPLATINSERT17]], <1 x double> undef, <1 x i32> zeroinitializer
; CHECK-NEXT:    [[TMP15:%.*]] = call <1 x double> @llvm.fmuladd.v1f64(<1 x double> [[BLOCK16]], <1 x double> [[SPLAT_SPLAT18]], <1 x double> [[TMP13]])
; CHECK-NEXT:    [[TMP16:%.*]] = shufflevector <1 x double> [[TMP15]], <1 x double> undef, <2 x i32> <i32 0, i32 undef>
; CHECK-NEXT:    [[TMP17:%.*]] = shufflevector <2 x double> undef, <2 x double> [[TMP16]], <2 x i32> <i32 2, i32 1>
; CHECK-NEXT:    [[BLOCK19:%.*]] = shufflevector <2 x double> [[SPLIT]], <2 x double> undef, <1 x i32> <i32 1>
; CHECK-NEXT:    [[TMP18:%.*]] = extractelement <2 x double> [[SPLIT3]], i64 0
; CHECK-NEXT:    [[SPLAT_SPLATINSERT20:%.*]] = insertelement <1 x double> undef, double [[TMP18]], i32 0
; CHECK-NEXT:    [[SPLAT_SPLAT21:%.*]] = shufflevector <1 x double> [[SPLAT_SPLATINSERT20]], <1 x double> undef, <1 x i32> zeroinitializer
; CHECK-NEXT:    [[TMP19:%.*]] = fmul <1 x double> [[BLOCK19]], [[SPLAT_SPLAT21]]
; CHECK-NEXT:    [[BLOCK22:%.*]] = shufflevector <2 x double> [[SPLIT1]], <2 x double> undef, <1 x i32> <i32 1>
; CHECK-NEXT:    [[TMP20:%.*]] = extractelement <2 x double> [[SPLIT3]], i64 1
; CHECK-NEXT:    [[SPLAT_SPLATINSERT23:%.*]] = insertelement <1 x double> undef, double [[TMP20]], i32 0
; CHECK-NEXT:    [[SPLAT_SPLAT24:%.*]] = shufflevector <1 x double> [[SPLAT_SPLATINSERT23]], <1 x double> undef, <1 x i32> zeroinitializer
; CHECK-NEXT:    [[TMP21:%.*]] = call <1 x double> @llvm.fmuladd.v1f64(<1 x double> [[BLOCK22]], <1 x double> [[SPLAT_SPLAT24]], <1 x double> [[TMP19]])
; CHECK-NEXT:    [[TMP22:%.*]] = shufflevector <1 x double> [[TMP21]], <1 x double> undef, <2 x i32> <i32 0, i32 undef>
; CHECK-NEXT:    [[TMP23:%.*]] = shufflevector <2 x double> [[TMP17]], <2 x double> [[TMP22]], <2 x i32> <i32 0, i32 2>
; CHECK-NEXT:    [[TMP24:%.*]] = shufflevector <2 x double> [[TMP11]], <2 x double> [[TMP23]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK-NEXT:    ret <4 x double> [[TMP24]]
;
entry:
  %c = call <4 x double> @llvm.matrix.multiply.v4f64.v4f64.v4f64(<4 x double> %a, <4 x double> %b, i32 2, i32 2, i32 2)
  ret <4 x double> %c
}

declare <4 x double> @llvm.matrix.multiply.v4f64.v4f64.v4f64(<4 x double>, <4 x double>, i32, i32, i32)
