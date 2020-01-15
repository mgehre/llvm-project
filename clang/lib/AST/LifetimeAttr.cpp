//===--- SemaType.cpp - Semantic Analysis for Types -----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "clang/AST/LifetimeAttr.h"
#include "clang/AST/Expr.h"
#include "clang/AST/ExprCXX.h"
#include "clang/Basic/SourceLocation.h"

namespace clang {
namespace process_lifetime_contracts {
// Easier access the attribute's representation.

const Expr *ignoreReturnValues(const Expr *E) {
  const Expr *Original;
  do {
    Original = E;
    E = E->IgnoreImplicit();
    if (const auto *CE = dyn_cast<CXXConstructExpr>(E)) {
      const auto *Ctor = CE->getConstructor();
      if (Ctor->getParent()->getName() == "PSet")
        return CE;
      E = CE->getArg(0);
    }
    if (const auto *MCE = dyn_cast<CXXMemberCallExpr>(E)) {
      if (llvm::isa_and_nonnull<CXXConversionDecl>(MCE->getDirectCallee()))
        E = MCE->getImplicitObjectArgument();
    }
  } while (E != Original);
  return E;
}

// This function can either collect the PSets of the symbols based on a lookup
// table or just the symbols into a pset if the lookup table is nullptr.
ContractPSet collectPSet(const Expr *E, const PointsToMap *Lookup,
                         SourceRange *FailRange) {
  if (const auto *TE = dyn_cast<CXXThisExpr>(E))
    return ContractPSet{
        ContractVariable(TE->getType()->getPointeeCXXRecordDecl())};
  if (const auto *DRE = dyn_cast<DeclRefExpr>(E)) {
    const auto *VD = dyn_cast<VarDecl>(DRE->getDecl());
    if (!VD) {
      *FailRange = DRE->getSourceRange();
      return ContractPSet{};
    }
    StringRef Name = VD->getName();
    if (Name == "Null")
      return ContractPSet{ContractVariable::nullVal()};
    else if (Name == "Static")
      return ContractPSet{ContractVariable::staticVal()};
    else if (Name == "Invalid")
      return ContractPSet{ContractVariable::invalid()};
    else if (Name == "Return") // TODO: function name, but overloads?
      return ContractPSet{ContractVariable::returnVal()};
    else {
      const auto *PVD = dyn_cast<ParmVarDecl>(VD);
      if (!PVD) {
        *FailRange = DRE->getSourceRange();
        return ContractPSet{};
      }
      if (Lookup) {
        auto it = Lookup->find(ContractVariable(PVD));
        if (it != Lookup->end())
          return it->second;
      }
      return ContractPSet{ContractVariable{PVD}};
    }
    *FailRange = DRE->getSourceRange();
    return ContractPSet{};
  }
  if (const auto *CE = dyn_cast<CallExpr>(E)) {
    const FunctionDecl *FD = CE->getDirectCallee();
    if (!FD || !FD->getIdentifier() || FD->getName() != "deref") {
      *FailRange = CE->getSourceRange();
      return ContractPSet{};
    }
    ContractPSet Result =
        collectPSet(ignoreReturnValues(CE->getArg(0)), Lookup, FailRange);
    auto VarsCopy = Result;
    Result.clear();
    for (auto Var : VarsCopy)
      Result.insert(Var.deref());
    return Result;
  }
  auto processArgs = [&](ArrayRef<const Expr *> Args) {
    ContractPSet Result;
    for (const auto *Arg : Args) {
      ContractPSet Elem =
          collectPSet(ignoreReturnValues(Arg), Lookup, FailRange);
      if (Elem.empty())
        return Elem;
      Result.insert(Elem.begin(), Elem.end());
    }
    return Result;
  };
  if (const auto *CE = dyn_cast<CXXConstructExpr>(E))
    return processArgs({CE->getArgs(), CE->getNumArgs()});
  if (const auto *IE = dyn_cast<InitListExpr>(E))
    return processArgs(IE->inits());
  *FailRange = E->getSourceRange();
  return ContractPSet{};
}

// This function and the callees are have the sole purpose of matching the
// AST that describes the contracts. We are only interested in identifier names
// of function calls and variables. The AST, however, has a lot of other
// information such as casts, termporary objects and so on. They do not have
// any semantic meaning for contracts so much of the code is just skipping
// these unwanted nodes. The rest is collecting the identifiers and their
// hierarchy.
// Also, the code might be rewritten a more simple way in the future
// piggybacking this work: https://reviews.llvm.org/rL365355
SourceRange fillContractFromExpr(const Expr *E, PointsToMap &Fill) {
  const auto *CE = dyn_cast<CallExpr>(E);
  if (!CE)
    return E->getSourceRange();
  do {
    if (const auto *ULE = dyn_cast<UnresolvedLookupExpr>(CE->getCallee())) {
      if (ULE->getName().isIdentifier() &&
          ULE->getName().getAsIdentifierInfo()->getName() == "lifetime")
        break;
    }
    const FunctionDecl *FD = CE->getDirectCallee();
    if (!FD || !FD->getIdentifier() || FD->getName() != "lifetime")
      return E->getSourceRange();
  } while (false);

  const Expr *LHS = ignoreReturnValues(CE->getArg(0));
  if (!LHS)
    return CE->getArg(0)->getSourceRange();
  const Expr *RHS = ignoreReturnValues(CE->getArg(1));
  if (!RHS)
    return CE->getArg(1)->getSourceRange();

  SourceRange ErrorRange;
  ContractPSet LhsPSet = collectPSet(LHS, nullptr, &ErrorRange);
  if (LhsPSet.size() != 1)
    return LHS->getSourceRange();
  if (ErrorRange.isValid())
    return ErrorRange;

  ContractVariable VD = *LhsPSet.begin();
  ContractPSet RhsPSet = collectPSet(RHS, &Fill, &ErrorRange);
  if (ErrorRange.isValid())
    return ErrorRange;
  Fill[VD] = RhsPSet;
  return SourceRange();
}
} // namespace process_lifetime_contracts
} // namespace clang
