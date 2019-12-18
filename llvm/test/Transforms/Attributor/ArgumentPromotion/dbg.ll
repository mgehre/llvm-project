; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --scrub-attributes
; RUN: opt -S -passes=attributor -aa-pipeline='basic-aa' -attributor-disable=false -attributor-max-iterations-verify -attributor-max-iterations=2 < %s | FileCheck %s

declare void @sink(i32)

define internal void @test(i32** %X) !dbg !2 {
; CHECK-LABEL: define {{[^@]+}}@test
; CHECK-SAME: (i32** nocapture nonnull readonly align 8 dereferenceable(8) [[X:%.*]]) !dbg !3
; CHECK-NEXT:    [[TMP1:%.*]] = load i32*, i32** [[X]], align 8
; CHECK-NEXT:    [[TMP2:%.*]] = load i32, i32* [[TMP1]], align 8
; CHECK-NEXT:    call void @sink(i32 [[TMP2]])
; CHECK-NEXT:    ret void
;
  %1 = load i32*, i32** %X, align 8
  %2 = load i32, i32* %1, align 8
  call void @sink(i32 %2)
  ret void
}

%struct.pair = type { i32, i32 }

define internal void @test_byval(%struct.pair* byval %P) {
; CHECK-LABEL: define {{[^@]+}}@test_byval
; CHECK-SAME: (%struct.pair* nocapture nofree readnone byval [[P:%.*]])
; CHECK-NEXT:    ret void
;
  ret void
}

define void @caller(i32** %Y, %struct.pair* %P) {
; CHECK-LABEL: define {{[^@]+}}@caller
; CHECK-SAME: (i32** nocapture readonly [[Y:%.*]], %struct.pair* nocapture nofree readonly [[P:%.*]])
; CHECK-NEXT:    call void @test(i32** nocapture readonly [[Y]]), !dbg !4
; CHECK-NEXT:    call void @test_byval(%struct.pair* nocapture nofree readonly undef), !dbg !5
; CHECK-NEXT:    ret void
;
  call void @test(i32** %Y), !dbg !1

  call void @test_byval(%struct.pair* %P), !dbg !6
  ret void
}


!llvm.module.flags = !{!0}
!llvm.dbg.cu = !{!3}

!0 = !{i32 2, !"Debug Info Version", i32 3}
!1 = !DILocation(line: 8, scope: !2)
!2 = distinct !DISubprogram(name: "test", file: !5, line: 3, isLocal: true, isDefinition: true, virtualIndex: 6, flags: DIFlagPrototyped, isOptimized: false, unit: !3, scopeLine: 3, scope: null)
!3 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, producer: "clang version 3.5.0 ", isOptimized: false, emissionKind: LineTablesOnly, file: !5)
!5 = !DIFile(filename: "test.c", directory: "")
!6 = !DILocation(line: 9, scope: !2)
