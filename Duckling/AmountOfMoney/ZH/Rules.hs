-- Copyright (c) 2016-present, Facebook, Inc.
-- All rights reserved.
--
-- This source code is licensed under the BSD-style license found in the
-- LICENSE file in the root directory of this source tree.


{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module Duckling.AmountOfMoney.ZH.Rules
  ( rules
  ) where

import Data.Maybe
import Data.String
import Prelude
import qualified Data.Text as Text

import Duckling.AmountOfMoney.Helpers
import Duckling.AmountOfMoney.Types (Currency (..), AmountOfMoneyData (..))
import Duckling.Dimensions.Types
import Duckling.Numeral.Helpers (isNatural, isPositive, oneOf)
import Duckling.Numeral.Types (NumeralData (..))
import Duckling.Regex.Types
import Duckling.Types
import qualified Duckling.AmountOfMoney.Types as TAmountOfMoney
import qualified Duckling.Numeral.Types as TNumeral
import qualified Duckling.Numeral.ZH.Rules as NRules
import qualified Data.HashMap.Strict as HashMap


ruleCNY :: Rule
ruleCNY = Rule
  { name = "cny"
  , pattern =
    [ regex "人民币|人民幣"
    ]
  , prod = \_ -> Just . Token AmountOfMoney $ currencyOnly CNY
  }

ruleCNYPrefix :: Rule
ruleCNYPrefix = Rule
  { name = "cny prefix"
  , pattern =
    [ regex "人民币|人民幣"
    , Predicate isPositive
    ]
  , prod = \case
      (_:Token Numeral NumeralData{TNumeral.value = v}:_) ->
        Just . Token AmountOfMoney . withValue v $ currencyOnly CNY
      _ -> Nothing
  }

ruleCent :: Rule
ruleCent = Rule
  { name = "cent"
  , pattern =
    [ regex "分"
    ]
  , prod = \_ -> Just . Token AmountOfMoney $ currencyOnly Cent
}

ruleDime :: Rule
ruleDime = Rule
  { name = "dime"
  , pattern =
    [ Predicate isPositive
    , regex "角|毛"
    ]
  , prod = \case
      (Token Numeral NumeralData{TNumeral.value = v}:_) ->
        Just . Token AmountOfMoney $
        withCents (v * 10) $ currencyOnly Cent
      _ -> Nothing
  }

ruleYuan :: Rule
ruleYuan = Rule
  { name = "yuan"
  , pattern =
    [ regex "元|圆|块"
    ]
  , prod = \_ -> Just . Token AmountOfMoney $ currencyOnly Yuan
  }

ruleDollar :: Rule
ruleDollar = Rule
  { name = "dollar"
  , pattern =
    [ regex "美元|美圆|美刀"
    ]
  , prod = \_ -> Just . Token AmountOfMoney $ currencyOnly Dollar
  }

rulePrecision :: Rule
rulePrecision = Rule
  { name = "exactly <amount-of-money>"
  , pattern =
    [ regex "(刚好|恰好)"
    , Predicate isSimpleAmountOfMoney
    ]
  , prod = \case
      (_:token:_) -> Just token
      _ -> Nothing
  }

ruleIntersectDimesAndCents :: Rule
ruleIntersectDimesAndCents = Rule
  { name = "intersect (X dimes and X cents)"
  , pattern =
    [ Predicate $ and . sequence [isSimpleAmountOfMoney, isDime]
    , Predicate $ and . sequence [isSimpleAmountOfMoney, isCent]
    ]
  , prod = \case
      (Token AmountOfMoney AmountOfMoneyData{TAmountOfMoney.value = Just d}:
       Token AmountOfMoney AmountOfMoneyData{TAmountOfMoney.value = Just c}:
       _) ->
         Just . Token AmountOfMoney $ withCents (c + d) $ currencyOnly Cent
      _ -> Nothing
  }

ruleIntersectDollarsAndDimesCents :: Rule
ruleIntersectDollarsAndDimesCents = Rule
  { name = "intersect (X dollars and X dimes/cents)"
  , pattern =
    [ Predicate $ and . sequence [isSimpleAmountOfMoney, isWithoutCents]
    , Predicate $ and . sequence [isSimpleAmountOfMoney, isCents]
    ]
  , prod = \case
      (Token AmountOfMoney fd:
       Token AmountOfMoney AmountOfMoneyData{TAmountOfMoney.value = Just c}:
       _) -> Just . Token AmountOfMoney $ withCents c fd
      _ -> Nothing
  }

ruleIntersect :: Rule
ruleIntersect = Rule
  { name = "intersect (implicit 0 delimited cents)"
  , pattern =
    [ Predicate $ and . sequence [isSimpleAmountOfMoney, isWithoutCents]
    , regex "0|零|〇"
    , oneOf [1..9]
    ]
  , prod = \case
      (Token AmountOfMoney fd:_:
       Token Numeral NumeralData{TNumeral.value = c}:
       _) -> Just . Token AmountOfMoney $ withCents c fd
      _ -> Nothing
  }

ruleIntersect2 :: Rule
ruleIntersect2 = Rule
  { name = "intersect (implicit unitless cents)"
  , pattern =
    [ Predicate $ and . sequence [isSimpleAmountOfMoney, isDime]
    , Predicate isNatural
    ]
  , prod = \case
      (Token AmountOfMoney AmountOfMoneyData{TAmountOfMoney.value = Just v}:
       Token Numeral NumeralData{TNumeral.value = c}:
       _) -> Just . Token AmountOfMoney $ withCents (v + c) $ currencyOnly Cent
      _ -> Nothing
  }

ruleIntersect3 :: Rule
ruleIntersect3 = Rule
  { name = "intersect (implicit unitless dimes)"
  , pattern =
    [ Predicate $ and . sequence [isSimpleAmountOfMoney, isWithoutCents]
    , Predicate isNatural
    ]
  , prod = \case
      (Token AmountOfMoney fd:
       Token Numeral NumeralData{TNumeral.value = d}:
       _) -> Just . Token AmountOfMoney $ withCents (d * 10) fd
      _ -> Nothing
  }

ruleIntervalNumeralDash :: Rule
ruleIntervalNumeralDash = Rule
  { name = "<numeral> - <amount-of-money>"
  , pattern =
    [ Predicate isPositive
    , regex "-|~|,|，|、|到"
    , Predicate isSimpleAmountOfMoney
    ]
  , prod = \case
      (Token Numeral NumeralData{TNumeral.value = from, TNumeral.grain = gr1}:
       _:
       Token AmountOfMoney AmountOfMoneyData{TAmountOfMoney.value = Just to,
                  TAmountOfMoney.currency = c, TAmountOfMoney.grain = gr2}:
       _) | from < to ->
         case (gr1, gr2) of
           (Nothing, Just g2) -> Just . Token AmountOfMoney . withInterval ((10 ** fromIntegral g2) * from, to) $ currencyOnly c
           _ -> Just . Token AmountOfMoney . withInterval (from, to) $ currencyOnly c
      _ -> Nothing
  }

ruleIntervalNumeralDash2 :: Rule
ruleIntervalNumeralDash2 = Rule
  { name = "<number><number><CN number unit><money unit>"
  , pattern =
    [ regex $ "(" ++ NRules.digitZHRegex ++ ")(" ++ NRules.digitZHRegex ++ ")(" ++ NRules.suffixZHRegex ++ ")"
    , Predicate isCurrencyOnly
    ]
  , prod = \case
      (Token RegexMatch (GroupMatch (dFrom:dTo:unit:_)):
       Token AmountOfMoney AmountOfMoneyData{TAmountOfMoney.currency = c}:
       _) -> do
        vFrom <- HashMap.lookup dFrom NRules.integerMap
        vTo <- HashMap.lookup dTo NRules.integerMap
        vUnit <- HashMap.lookup unit NRules.suffixUnitValueMap
        let from = vUnit * fromIntegral vFrom
            to = vUnit * fromIntegral vTo
        case from < to of
          True -> Just . Token AmountOfMoney . withInterval (from, to) $ currencyOnly c
          False -> Nothing
      _ -> Nothing
  }

ruleIntervalDash :: Rule
ruleIntervalDash = Rule
  { name = "<amount-of-money> - <amount-of-money>"
  , pattern =
    [ Predicate isSimpleAmountOfMoney
    , regex "-|~|,|，|、|到"
    , Predicate isSimpleAmountOfMoney
    ]
  , prod = \case
      (Token AmountOfMoney AmountOfMoneyData{TAmountOfMoney.value = Just from,
                  TAmountOfMoney.currency = c1, TAmountOfMoney.grain = gr1}:
       _:
       Token AmountOfMoney AmountOfMoneyData{TAmountOfMoney.value = Just to,
                  TAmountOfMoney.currency = c2, TAmountOfMoney.grain = gr2}:
       _) | from < to && c1 == c2 ->
        Just . Token AmountOfMoney . withInterval (from, to) $ currencyOnly c1
      _ -> Nothing
  }

ruleIntervalBound :: Rule
ruleIntervalBound = Rule
  { name = "under/less/lower/no more than <amount-of-money> (最多|不到|小于|至少|最少|大于)"
  , pattern =
    [ regex "(最多|不到|小于|至少|最少|最小|大于)"
    , Predicate isSimpleAmountOfMoney
    ]
  , prod = \case
      (Token RegexMatch (GroupMatch (match:_)):
       Token AmountOfMoney AmountOfMoneyData{TAmountOfMoney.value = Just to,
                  TAmountOfMoney.currency = c}:
       _) -> case match of
        "最多" -> Just . Token AmountOfMoney . withMax to $ currencyOnly c
        "不到" -> Just . Token AmountOfMoney . withMax to $ currencyOnly c
        "小于" -> Just . Token AmountOfMoney . withMax to $ currencyOnly c
        "最少" -> Just . Token AmountOfMoney . withMin to $ currencyOnly c
        "最小" -> Just . Token AmountOfMoney . withMin to $ currencyOnly c
        "至少" -> Just . Token AmountOfMoney . withMin to $ currencyOnly c
        "大于" -> Just . Token AmountOfMoney . withMin to $ currencyOnly c
        _ -> Nothing
      _ -> Nothing
  }

ruleIntervalBound2 :: Rule
ruleIntervalBound2 = Rule
  { name = "under/less/lower/no more than <amount-of-money> (以下|以上)"
  , pattern =
    [ Predicate isSimpleAmountOfMoney
    , regex "(以下|以上)"
    ]
  , prod = \case
      (Token AmountOfMoney AmountOfMoneyData{TAmountOfMoney.value = Just to,
                  TAmountOfMoney.currency = c}:
       Token RegexMatch (GroupMatch (match:_)):
       _) -> case match of
        "以下" -> Just . Token AmountOfMoney . withMax to $ currencyOnly c
        "以上" -> Just . Token AmountOfMoney . withMin to $ currencyOnly c
        _ -> Nothing
      _ -> Nothing
  }

ruleApproximate :: Rule
ruleApproximate = Rule
  { name = "about <amount-of-money> (大约|差不多|大概)"
  , pattern =
    [ regex "(大约|差不多|大概)"
    , Predicate isSimpleAmountOfMoney
    ]
  , prod = \case
      (Token RegexMatch (GroupMatch (match:_)):
       Token AmountOfMoney AmountOfMoneyData{TAmountOfMoney.value = Just to,
                  TAmountOfMoney.currency = c}:
       _) -> Just . Token AmountOfMoney . withApproximate to $ currencyOnly c
      _ -> Nothing
  }

ruleApproximate2 :: Rule
ruleApproximate2 = Rule
  { name = "<amount-of-money> about (左右|上下)"
  , pattern =
    [ Predicate isSimpleAmountOfMoney
    , regex "(左右|上下)"
    ]
  , prod = \case
        (Token AmountOfMoney AmountOfMoneyData{TAmountOfMoney.value = Just to,
                             TAmountOfMoney.currency = c}:
         Token RegexMatch (GroupMatch (match:_)):
         _) -> Just . Token AmountOfMoney . withApproximate to $ currencyOnly c
        _ -> Nothing
  }

rules :: [Rule]
rules =
  [ ruleCent
  , ruleCNY
  , ruleCNYPrefix
  , ruleDime
  , ruleYuan
  , ruleDollar
  , ruleIntersect
  , ruleIntersect2
  , ruleIntersect3
  , ruleIntersectDimesAndCents
  , ruleIntersectDollarsAndDimesCents
  , ruleIntervalDash
  , ruleIntervalNumeralDash
  , ruleIntervalNumeralDash2
  , ruleIntervalBound
  , ruleIntervalBound2
  , rulePrecision
  , ruleApproximate
  , ruleApproximate2
  ]
