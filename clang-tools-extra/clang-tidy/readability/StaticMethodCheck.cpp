//===--- StaticMethodCheck.cpp - clang-tidy -------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "StaticMethodCheck.h"
#include "clang/AST/ASTContext.h"
#include "clang/AST/DeclCXX.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/ASTMatchers/ASTMatchFinder.h"
#include "clang/Basic/SourceLocation.h"

using namespace clang::ast_matchers;

namespace clang {
namespace tidy {
namespace readability {

class FindUsageOfThis : public RecursiveASTVisitor<FindUsageOfThis> {
public:
  FindUsageOfThis() {}
  bool Used = false;

  bool VisitCXXThisExpr(const CXXThisExpr *E) {
    Used = true;
    return false; // Stop traversal.
  }
};

void StaticMethodCheck::registerMatchers(MatchFinder *Finder) {
  Finder->addMatcher(
      cxxMethodDecl(unless(isExpansionInSystemHeader()), isDefinition())
          .bind("x"),
      this);
}

/// \brief Obtain the original source code text from a SourceRange.
static StringRef getStringFromRange(SourceManager &SourceMgr,
                                    const LangOptions &LangOpts,
                                    SourceRange Range) {
  if (SourceMgr.getFileID(Range.getBegin()) !=
      SourceMgr.getFileID(Range.getEnd()))
    return {};

  return Lexer::getSourceText(CharSourceRange(Range, true), SourceMgr,
                              LangOpts);
}

static SourceRange getLocationOfConst(const TypeSourceInfo *TSI,
                                      SourceManager &SourceMgr,
                                      const LangOptions &LangOpts) {
  if (!TSI)
    return {};
  FunctionTypeLoc FTL =
      TSI->getTypeLoc().IgnoreParens().getAs<FunctionTypeLoc>();
  if (!FTL)
    return {};

  auto Range = SourceRange{FTL.getRParenLoc().getLocWithOffset(1),
                           FTL.getLocalRangeEnd()};
  // Inside Range, there might be other keywords and trailing return types.
  // Find the exact position of "const".
  StringRef Text = getStringFromRange(SourceMgr, LangOpts, Range);
  auto Offset = Text.find("const");
  if (Offset == StringRef::npos)
    return {};

  SourceLocation Start = Range.getBegin().getLocWithOffset(Offset);
  return {Start, Start.getLocWithOffset(strlen("const") - 1)};
}

// Returns `true` if `Range` is inside a macro definition.
static bool insideMacroDefinition(const MatchFinder::MatchResult &Result,
                                  SourceRange Range) {
  return !clang::Lexer::makeFileCharRange(
              clang::CharSourceRange::getCharRange(Range),
              *Result.SourceManager, Result.Context->getLangOpts())
              .isValid();
}

void StaticMethodCheck::check(const MatchFinder::MatchResult &Result) {
  const auto *Definition = Result.Nodes.getNodeAs<CXXMethodDecl>("x");
  if (!Definition->isUserProvided())
    return;
  if (Definition->isStatic())
    return; // Nothing we can improve.
  if (Definition->isVirtual())
    return;
  if (Definition->getParent()->hasAnyDependentBases())
    return; // Method might become virtual depending on template base class.
  if (Definition->hasTrivialBody())
    return;
  if (Definition->isOverloadedOperator())
    return;
  if (Definition->getTemplateSpecializationKind() != TSK_Undeclared)
    return;
  if (Definition->getTemplatedKind() != FunctionDecl::TK_NonTemplate)
    return; // We might not see all specializations.
  if (isa<CXXConstructorDecl>(Definition) ||
      isa<CXXDestructorDecl>(Definition) || isa<CXXConversionDecl>(Definition))
    return;
  if (Definition->isDependentContext())
    return;
  if (Definition->getParent()->isLambda())
    return;

  if (insideMacroDefinition(
          Result,
          Definition->getTypeSourceInfo()->getTypeLoc().getSourceRange()))
    return;

  const CXXMethodDecl* Declaration = Definition->getCanonicalDecl();

  if (Declaration != Definition &&
      insideMacroDefinition(
          Result,
          Declaration->getTypeSourceInfo()->getTypeLoc().getSourceRange()))
    return;

  FindUsageOfThis UsageOfThis;
  // TraverseStmt does not modify its argument.
  UsageOfThis.TraverseStmt(const_cast<Stmt *>(Definition->getBody()));

  if (UsageOfThis.Used)
    return;

  // TODO: For out-of-line declarations, don't modify the source if the header
  // is excluded by the -header-filter option.
  DiagnosticBuilder Diag = diag(Definition->getLocation(), "method %0 can be made static")
              << Definition;

  if (Definition->isConst()) {
    // Make sure that we either remove 'const' on both declaration and
    // definition or emit no fix-it at all.
    SourceRange DefConst = getLocationOfConst(Definition->getTypeSourceInfo(),
                                       *Result.SourceManager,
                                       Result.Context->getLangOpts());

    if (DefConst.isInvalid())
      return;

    if (Declaration != Definition) {
      SourceRange DeclConst = getLocationOfConst(Declaration->getTypeSourceInfo(),
                                          *Result.SourceManager,
                                          Result.Context->getLangOpts());

      if (DeclConst.isInvalid())
        return;
      Diag << FixItHint::CreateRemoval(DeclConst);
    }

    // Remove existing 'const' from both declaration and definition.
    Diag << FixItHint::CreateRemoval(DefConst);
  }
  Diag << FixItHint::CreateInsertion(Declaration->getBeginLoc(), "static ");
}

} // namespace readability
} // namespace tidy
} // namespace clang
