//===--- LifetimeAttrData.h - Classes for lifetime attributes ---*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
//  This file defines classes that are used by lifetime attributes.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_AST_LIFETIMEATTR_H
#define LLVM_CLANG_AST_LIFETIMEATTR_H

#include "clang/AST/Decl.h"
#include "clang/AST/Expr.h"
#include <set>

namespace clang {

/// This represents an abstract memory location that is used in the lifetime
/// contract representation.
struct ContractVariable {
  ContractVariable(const ParmVarDecl *PVD, int Deref = 0) :
    ParamIdx(PVD->getFunctionScopeIndex()), Tag(Param) {
    deref(Deref);
  }

  ContractVariable(const RecordDecl *RD) : RD(RD), Tag(This) {}

  static ContractVariable returnVal() { return ContractVariable(Return); }
  static ContractVariable staticVal() { return ContractVariable(Static); }
  static ContractVariable nullVal() { return ContractVariable(Null); }
  static ContractVariable invalid() { return ContractVariable(Invalid); }

  bool operator==(const ContractVariable &O) const {
    if (Tag != O.Tag)
      return false;
    if (FDs != O.FDs)
      return false;
    if (Tag == Param)
      return ParamIdx == O.ParamIdx;
    if (Tag == This)
      return RD == O.RD;
    return true;
  }

  bool operator!=(const ContractVariable &O) const { return !(*this == O); }

  bool operator<(const ContractVariable &O) const {
    if (Tag != O.Tag)
      return Tag < O.Tag;
    if (FDs.size() != O.FDs.size())
      return FDs.size() < O.FDs.size();
    if (Tag == Param)
      if (ParamIdx != O.ParamIdx)
        return ParamIdx < O.ParamIdx;
    if (Tag == This)
      if (RD != O.RD)
        return std::less<const RecordDecl *>()(RD, O.RD);

    for (auto I = FDs.begin(), J = O.FDs.begin(); I != FDs.end(); ++I, ++J) {
      if (*I != *J)
        return std::less<const FieldDecl *>()(*I, *J);
    }
    return false;
  }

  bool isThisPointer() const { return Tag == This; }

  const ParmVarDecl *asParmVarDecl(const FunctionDecl *FD) const {
    return Tag == Param ? FD->getParamDecl(ParamIdx) : nullptr;
  }

  bool isReturnVal() const { return Tag == Return; }

  // Chain of field accesses starting from VD. Types must match.
  void addFieldRef(const FieldDecl *FD) { FDs.push_back(FD); }

  ContractVariable &deref(int Num = 1) {
    while (Num--)
      FDs.push_back(nullptr);
    return *this;
  }

  std::string dump(const FunctionDecl *FD) const {
    std::string Result;
    switch(Tag) {
      case Null:
        return "Null";
      case Static:
        return "Static";
      case Invalid:
        return "Invalid";
      case This:
        Result = "this";
        break;
      case Return:
        Result = "(return value)";
        break;
      case Param:
        Result = FD->getParamDecl(ParamIdx)->getName();
        break;
    }

    for (unsigned I = 0; I < FDs.size(); ++I) {
      if (FDs[I]) {
        if (I > 0 && !FDs[I - 1])
          Result = "(" + Result + ")";
        Result += "." + std::string(FDs[I]->getName());
      } else
        Result.insert(0, 1, '*');
    }
    return Result;
  }

private:
  union {
    const RecordDecl *RD;
    unsigned ParamIdx;
  };

  enum TagType {
    Static,
    Null,
    Invalid,
    This,
    Return,
    Param,
  } Tag;

  ContractVariable(TagType T) : Tag(T) {}

  /// Possibly empty list of fields and deref operations on the base.
  /// The First entry is the field on base, next entry is the field inside
  /// there, etc. Null pointers represent a deref operation.
  llvm::SmallVector<const FieldDecl *, 3> FDs;
};

using ContractPSet = std::set<ContractVariable>;
} // namespace clang

#endif // LLVM_CLANG_AST_LIFETIMEATTR_H
