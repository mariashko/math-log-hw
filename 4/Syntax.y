-- Synt.y -*- mode: haskell -*-
{
module Syntax where
import Lexer
}

%name syntDeduct DeductionProof
%name syntExpr Expr
%tokentype { Token }
%monad { Either String } { (>>=) } { return }

%token
var { TVariable $$ }
predicat { TPredicatSymb $$ }
'|' { TBinOr }
'&' { TBinAnd }
'!' { TNot }
'->' { TImplic }
'(' { TLeftParen }
')' { TRightParen }
'\n' { TEOLN }
',' { TComma }
'|-' { TTurnstile }
apostr { TApostrophe }
'0' { TZero }
'*' { TMultiply }
'+' { TPlus }
'=' { TEquality }
foralls { TQuantifierAll }
exists { TQuantifierExists }

%left '|-'
%left ','
%right '->'
%left '|'
%left '&'
%right '!'
%left '='
%left '+'
%left '*'
%right exists
%right forall
%left apostr
%%

DeductionProof:
'|-' Expr '\n' ProofList { DeductionProof $2 [] $4 }
| AssumptionList '|-' Expr '\n' ProofList { DeductionProof $3 $1 $5 }

AssumptionList:
AssumptionListRev { reverse $1 }

AssumptionListRev:
Expr { [$1] }
| AssumptionListRev ',' Expr { $3 : $1 }

ProofList:
ProofListRev{ reverse $1 }

ProofListRev:
Expr '\n' { [$1] }
| ProofListRev Expr '\n' { $2 : $1 }

Expr:
'(' Expr ')' { $2 }
| Expr '->' Expr { BinOp Impl $1 $3 }
| Expr '|' Expr { BinOp Or $1 $3 }
| Expr '&' Expr { BinOp And $1 $3 }
| '!' Expr { UnOp UnNot $2 }
| foralls var Expr { Quantifier Forall $2 $3 }
| exists var Expr { Quantifier Exists $2 $3 }
| Term '=' Term { Equals $1 $3 }
| predicat TermList { PredicateSymb $1 $2 }
| predicat { PredicateSymb $1 [] }

TermList:
'(' TermListRev ')' { reverse $2 }

TermListRev:
Term { [$1] }
| TermListRev ',' Term { $3 : $1 }

Term:
AtomTerm { $1 }
| Term '+'Term { BinFunction Plus $1 $3 }
| Term '*' Term { BinFunction Mul $1 $3 }

AtomTerm:
var { Variable $1 }
| var TermList { MultiFunction $1 $2 }
| '0' { ZeroTerm }
| '(' Term ')' { $2 }
| AtomTerm apostr { Apostrophe $1 }

{
happyError rest = Left $ "syntax error" ++ show rest

data DeductionProof =
    DeductionProof{
      statement :: Expr,
      assumption :: [Expr],
      proof :: [Expr]
    }
    deriving (Ord, Eq)

showExprList :: String -> [Expr] -> String
showExprList _ [] = ""
showExprList _ (x:[]) = show x
showExprList c (x:xs) = (show x) ++ c ++ showExprList c xs

             
instance Show DeductionProof where
    show x = (showExprList "," (assumption x)) ++ "|-" ++ (show (statement x)) ++ "\n" ++ (showExprList "\n" (proof x)) ++ "\n"

data BinOpType = Or | And | Impl
               deriving (Ord, Eq)

instance Show BinOpType where
  show x = case x of
    Or -> "|"
    And -> "&"
    Impl -> "->"

data UnOpType = UnNot
              deriving (Ord, Eq)

instance Show UnOpType where
  show x = "!"
data BinFunType = Plus | Mul
  deriving (Eq, Ord, Show)
data Term = BinFunction BinFunType Term Term
          | MultiFunction String [Term]
          | ZeroTerm
          | Apostrophe Term
          | Variable String
  deriving (Eq, Ord, Show)
data QuType = Forall | Exists
  deriving (Eq, Ord, Show)

data Expr = Equals Term Term
          | PredicateSymb String [Term]
          | Quantifier QuType String Expr 
          | BinOp BinOpType Expr Expr
          | UnOp UnOpType Expr
  deriving (Eq, Ord, Show)
{-
instance Show Expr where
  show x = case x of
    Statement s -> s
    BinOp t a b -> "(" ++ (show a) ++ (show t) ++ (show b) ++ ")"
    UnOp t a -> "("++(show t) ++ (show a) ++ ")" -}
}