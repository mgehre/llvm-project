//===--- UseAlgorithmCheck.cpp - clang-tidy--------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "UseAlgorithmCheck.h"
#include "clang/AST/ASTContext.h"
#include "clang/ASTMatchers/ASTMatchFinder.h"
#include "clang/Analysis/Analyses/ExprMutationAnalyzer.h"
#include "clang/Frontend/CompilerInstance.h"
#include <algorithm>
#include <string>

using namespace clang::ast_matchers;

namespace clang {
namespace ast_matchers {
/// Matches a Stmt whose parent is a CompoundStmt,
/// and which is directly followed by
/// a Stmt matching the inner matcher.
AST_MATCHER_P(Stmt, nextStmt, internal::Matcher<Stmt>, InnerMatcher) {
  const auto &Parents = Finder->getASTContext().getParents(Node);
  if (Parents.size() != 1)
    return false;

  auto *C = Parents[0].get<CompoundStmt>();
  if (!C)
    return false;

  auto I = std::find(C->body_begin(), C->body_end(), &Node);
  assert(I != C->body_end()); // C is parent of Node.
  if (++I == C->body_end())
    return false; // Node is last statement.

  return InnerMatcher.matches(**I, Finder, Builder);
}
} // namespace ast_matchers

namespace tidy {
namespace readability {

void UseAlgorithmCheck::registerPPCallbacks(const SourceManager &SM,
                                            Preprocessor *PP,
                                            Preprocessor *ModuleExpanderPP) {
  IncludeInserter =
      std::make_unique<utils::IncludeInserter>(SM, getLangOpts(), IncludeStyle);
  PP->addPPCallbacks(IncludeInserter->CreatePPCallbacks());
}

#if 0
void f() {
    // Fixits use C++20 range-based algorithms
    if (!getLangOpts().CPlusPlus2a)
      return;

    auto *RangeInit = dyn_cast<DeclRefExpr>(S->getRangeInit());
    assert(RangeInit);
    // if (!RangeInit)
    //  return; // FIXME: handle more cases

    StringRef RangeInitText = Lexer::getSourceText(
        CharSourceRange::getTokenRange(
            SourceRange(RangeInit->getBeginLoc(), RangeInit->getEndLoc())),
        *Result.SourceManager, getLangOpts());

    std::string Buffer;
    llvm::raw_string_ostream Call(Buffer);
    Call << "return std::any_of(";
    Call << RangeInitText;
    Call << ", ";
    Call << "[](";
    if (!S->getRangeStmt()->isSingleDecl())
      return;
    const VarDecl *D = dyn_cast<VarDecl>(S->getLoopVarStmt()->getSingleDecl());
    if (!D)
      return;
    Call << D->getType().getAsString();
    Call << " ";
    Call << D->getDeclName().getAsString();
    Call << ") ";
    bool BodyIsCompound = isa<CompoundStmt>(S->getBody());
    if (!BodyIsCompound)
      Call << "{\n";

    Call << Lexer::getSourceText(
        CharSourceRange::getTokenRange(S->getBody()->getSourceRange()),
        *Result.SourceManager, getLangOpts());

    /*llvm::errs() << "body " <<  Lexer::getSourceText(
            CharSourceRange::getTokenRange(S->getBody()->getSourceRange()),
            *Result.SourceManager, getLangOpts()) << "\n\n";*/
    Call << "\nreturn false;";

    if (!BodyIsCompound)
      Call << "\n}";
    Call << ")";

    const auto *FinalReturn =
        Result.Nodes.getNodeAs<ReturnStmt>("final_return");
    // Replaces everything but the trailing semicolon on the final return
    Diag << FixItHint::CreateReplacement(
        SourceRange(S->getForLoc(), FinalReturn->getEndLoc()), Call.str());

    if (auto Fix = IncludeInserter->CreateIncludeInsertion(
            Result.SourceManager->getMainFileID(), "algorithm",
            /*IsAngled=*/true)) {
      Diag << *Fix;
    }
  }
#endif

void UseAlgorithmCheck::registerMatchers(MatchFinder *Finder) {
  if (!getLangOpts().CPlusPlus)
    return;

  auto returns = [](bool V) {
    return returnStmt(hasReturnValue(cxxBoolLiteral(equals(V))));
  };

  auto returnsButNotTrue =
      returnStmt(hasReturnValue(unless(cxxBoolLiteral(equals(true)))));
  auto returnsButNotFalse =
      returnStmt(hasReturnValue(unless(cxxBoolLiteral(equals(false)))));

  /* To transform a loop body into a predicate,
   * for(type var : container) {
   *
   * }
   * return true;
   * continue -> return false;
   * end-of-body -> return false;
   */
  Finder->addMatcher(
      cxxForRangeStmt(
          nextStmt(returns(false).bind("final_return")),
          hasBody(allOf(hasDescendant(returns(true)),
                        unless(anyOf(hasDescendant(breakStmt()),
                                     hasDescendant(returnsButNotTrue))))))
          .bind("any_of_loop"),
      this);

  Finder->addMatcher(
      cxxForRangeStmt(
          nextStmt(returns(true).bind("final_return")),
          hasBody(allOf(hasDescendant(returns(false)),
                        unless(anyOf(hasDescendant(breakStmt()),
                                     hasDescendant(returnsButNotFalse))))))
          .bind("all_of_loop"),
      this);
}

static bool isViableLoop(const CXXForRangeStmt &S, ASTContext &Context) {

  ExprMutationAnalyzer Mutations(*S.getBody(), Context);
  if (Mutations.isMutated(S.getLoopVariable()))
    return false;
  const auto Matches =
      match(findAll(declRefExpr().bind("decl_ref")), *S.getBody(), Context);

  return llvm::none_of(Matches, [&Mutations](auto &DeclRef) {
    // TODO: allow modifications of loop-local variables
    return Mutations.isMutated(
        DeclRef.template getNodeAs<DeclRefExpr>("decl_ref")->getDecl());
  });
}

void UseAlgorithmCheck::check(const MatchFinder::MatchResult &Result) {

  if (const auto *S = Result.Nodes.getNodeAs<CXXForRangeStmt>("any_of_loop")) {
    if (!isViableLoop(*S, *Result.Context))
      return;

    auto Diag =
        diag(S->getForLoc(), "Replace loop by std::any_of() from <algorithm>");

  } else if (const auto *S =
                 Result.Nodes.getNodeAs<CXXForRangeStmt>("all_of_loop")) {
    if (!isViableLoop(*S, *Result.Context))
      return;

    auto Diag =
        diag(S->getForLoc(), "Replace loop by std::all_of() from <algorithm>");
  }
}

} // namespace readability
} // namespace tidy
} // namespace clang
