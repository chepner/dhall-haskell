{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module Regression where

import qualified Control.Exception
import qualified Data.Map
import qualified Dhall
import qualified Dhall.Core
import qualified Dhall.Parser
import qualified Test.Tasty
import qualified Test.Tasty.HUnit
import qualified Util

import Test.Tasty (TestTree)
import Test.Tasty.HUnit ((@?=))

regressionTests :: TestTree
regressionTests =
    Test.Tasty.testGroup "regression tests"
        [ issue96
        , issue126
        , parsing0
        , unnamedFields
        , trailingSpaceAfterStringLiterals
        ]

data Foo = Foo Integer Bool | Bar Bool Bool Bool | Baz Integer Integer
    deriving (Show, Dhall.Generic, Dhall.Interpret, Dhall.Inject)

unnamedFields :: TestTree
unnamedFields = Test.Tasty.HUnit.testCase "Unnamed Fields" (do
    let ty = Dhall.auto @Foo
    Test.Tasty.HUnit.assertEqual "Good type" (Dhall.expected ty) (Dhall.Core.Union (
            Data.Map.fromList [
                ("Bar",Dhall.Core.Record (Data.Map.fromList [
                    ("_1",Dhall.Core.Bool),("_2",Dhall.Core.Bool),("_3",Dhall.Core.Bool)]))
                , ("Baz",Dhall.Core.Record (Data.Map.fromList [
                    ("_1",Dhall.Core.Integer),("_2",Dhall.Core.Integer)]))
                ,("Foo",Dhall.Core.Record (Data.Map.fromList [
                    ("_1",Dhall.Core.Integer),("_2",Dhall.Core.Bool)]))]))

    let inj = Dhall.inject @Foo
    Test.Tasty.HUnit.assertEqual "Good Inject" (Dhall.declared inj) (Dhall.expected ty)

    let tu_ty = Dhall.auto @(Integer, Bool)
    Test.Tasty.HUnit.assertEqual "Auto Tuple" (Dhall.expected tu_ty) (Dhall.Core.Record (
            Data.Map.fromList [ ("_1",Dhall.Core.Integer),("_2",Dhall.Core.Bool) ]))

    let tu_in = Dhall.inject @(Integer, Bool)
    Test.Tasty.HUnit.assertEqual "Inj. Tuple" (Dhall.declared tu_in) (Dhall.expected tu_ty)

    return () )

issue96 :: TestTree
issue96 = Test.Tasty.HUnit.testCase "Issue #96" (do
    -- Verify that parsing should not fail
    _ <- Util.code "\"bar'baz\""
    return () )

issue126 :: TestTree
issue126 = Test.Tasty.HUnit.testCase "Issue #126" (do
    e <- Util.code
        "''\n\
        \  foo\n\
        \  bar\n\
        \''"
    Util.normalize' e @?= "\"foo\\nbar\\n\"" )

parsing0 :: TestTree
parsing0 = Test.Tasty.HUnit.testCase "Parsing regression #0" (do
    -- Verify that parsing should not fail
    --
    -- In 267093f8cddf1c2f909f2d997c31fd0a7cb2440a I broke the parser when left
    -- factoring the grammer by failing to handle the source tested by this
    -- regression test.  The root of the problem was that the parser was trying
    -- to parse `List ./Node` as `Field List "/Node"` instead of
    -- `App List (Embed (Path (File Homeless "./Node") Code))`.  The latter is
    -- the correct parse because `/Node` is not a valid field label, but the
    -- mistaken parser was committed to the incorrect parse and never attempted
    -- the correct parse.
    case Dhall.Parser.exprFromText mempty "List ./Node" of
        Left  e -> Control.Exception.throwIO e
        Right _ -> return () )

trailingSpaceAfterStringLiterals :: TestTree
trailingSpaceAfterStringLiterals =
    Test.Tasty.HUnit.testCase "Trailing space after string literals" (do
        -- Verify that string literals parse correctly with trailing space
        -- (Yes, I did get this wrong at some point)
        _ <- Util.code "(''ABC'' ++ \"DEF\" )"
        return () )
