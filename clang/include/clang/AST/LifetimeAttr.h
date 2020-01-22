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
#include "llvm/ADT/Optional.h"
#include <set>

namespace clang {

/// An abstract memory location that participates in defining a lifetime
/// contract. A lifetime contract constrains lifetime of a
/// LifetimeContractVariable to be at least as big as the lifetime of other
/// LifetimeContractVariables.
///
/// The memory locations that we can describe are: return values of a function,
/// this pointer, any function parameter, a "drilldown" expression based on
/// function parameters, null etc.
class LifetimeContractVariable {
public:
  static LifetimeContractVariable paramBasedVal(const ParmVarDecl *PVD,
                                                int Deref = 0) {
    return LifetimeContractVariable(PVD, Deref);
  }
  static LifetimeContractVariable thisVal(const RecordDecl *RD) {
    return LifetimeContractVariable(RD);
  }
  static LifetimeContractVariable returnVal() {
    return LifetimeContractVariable(Return);
  }
  static LifetimeContractVariable globalVal() {
    return LifetimeContractVariable(Global);
  }
  static LifetimeContractVariable nullVal() {
    return LifetimeContractVariable(Null);
  }
  static LifetimeContractVariable invalid() {
    return LifetimeContractVariable(Invalid);
  }

  bool operator==(const LifetimeContractVariable &O) const {
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

  bool operator!=(const LifetimeContractVariable &O) const {
    return !(*this == O);
  }

  bool operator<(const LifetimeContractVariable &O) const {
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
  bool isReturnVal() const { return Tag == Return; }
  bool isNull() const { return Tag == Null; }
  bool isInvalid() const { return Tag == Invalid; }
  bool isGlobal() const { return Tag == Global; }

  const ParmVarDecl *asParmVarDecl(const FunctionDecl *FD) const {
    return Tag == Param ? FD->getParamDecl(ParamIdx) : nullptr;
  }

  // Chain of field accesses starting from VD. Types must match.
  void addFieldRef(const FieldDecl *FD) { FDs.push_back(FD); }

  LifetimeContractVariable &deref(int Num = 1) {
    while (Num--)
      FDs.push_back(nullptr);
    return *this;
  }

  std::string dump(const FunctionDecl *FD) const {
    std::string Result;
    switch (Tag) {
    case Null:
      return "null";
    case Global:
      return "global";
    case Invalid:
      return "invalid";
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
    Global,
    Null,
    Invalid,
    This,
    Return,
    Param,
  } Tag;

  LifetimeContractVariable(TagType T) : Tag(T) {}
  LifetimeContractVariable(const RecordDecl *RD) : RD(RD), Tag(This) {}
  LifetimeContractVariable(const ParmVarDecl *PVD, int Deref)
      : ParamIdx(PVD->getFunctionScopeIndex()), Tag(Param) {
    deref(Deref);
  }

  /// Possibly empty list of fields and deref operations on the base.
  /// The First entry is the field on base, next entry is the field inside
  /// there, etc. Null pointers represent a deref operation.
  llvm::SmallVector<const FieldDecl *, 3> FDs;
};

/// A lifetime of a pointee of a specific pointer-like C++ object. This
/// lifetime is represented as a disjunction of different lifetime possibilities
/// (set elements). Each lifetime possibility is specified by naming another
/// object that the pointee can point at.
using ObjectLifetimeSet = std::set<LifetimeContractVariable>;

/// Lifetime constraints for multiple objects. The key of the map is the
/// pointer-like object, the value is the lifetime of the pointee.
/// Can be used to describe all lifetime constraints required by a given
/// function, or all lifetimes inferred at a specific program point etc..
using LifetimeContracts = std::map<LifetimeContractVariable, ObjectLifetimeSet>;

namespace process_lifetime_contracts {
/// Converts an AST of a lifetime contract (that is, the `gtl::lifetime(...)
/// call expression) to a LifetimeContracts object that is used throughout the
/// lifetime analysis.
///
/// If the AST does not describe a valid contract, the source range of the
/// erroneous part is returned.
llvm::Optional<SourceRange> fillContractFromExpr(const Expr *E,
                                                 LifetimeContracts &Fill);
} // namespace process_lifetime_contracts
} // namespace clang

#endif // LLVM_CLANG_AST_LIFETIMEATTR_H
