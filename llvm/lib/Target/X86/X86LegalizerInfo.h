//===- X86LegalizerInfo.h ------------------------------------------*- C++
//-*-==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
/// \file
/// This file declares the targeting of the Machinelegalizer class for X86.
/// \todo This should be generated by TableGen.
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_X86_X86MACHINELEGALIZER_H
#define LLVM_LIB_TARGET_X86_X86MACHINELEGALIZER_H

#include "llvm/CodeGen/GlobalISel/LegalizerInfo.h"

namespace llvm {

class X86Subtarget;
class X86TargetMachine;

/// This class provides the information for the target register banks.
class X86LegalizerInfo : public LegalizerInfo {
private:
  /// Keep a reference to the X86Subtarget around so that we can
  /// make the right decision when generating code for different targets.
  const X86Subtarget &Subtarget;
  const X86TargetMachine &TM;

public:
  X86LegalizerInfo(const X86Subtarget &STI, const X86TargetMachine &TM);

  bool legalizeIntrinsic(MachineInstr &MI, MachineIRBuilder &MIRBuilder,
                         GISelChangeObserver &Observer) const override;

private:
  void setLegalizerInfo32bit();
  void setLegalizerInfo64bit();
  void setLegalizerInfoSSE1();
  void setLegalizerInfoSSE2();
  void setLegalizerInfoSSE41();
  void setLegalizerInfoAVX();
  void setLegalizerInfoAVX2();
  void setLegalizerInfoAVX512();
  void setLegalizerInfoAVX512DQ();
  void setLegalizerInfoAVX512BW();
};
} // namespace llvm
#endif
