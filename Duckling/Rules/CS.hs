-- Copyright (c) 2016-present, Facebook, Inc.
-- All rights reserved.
--
-- This source code is licensed under the BSD-style license found in the
-- LICENSE file in the root directory of this source tree.


{-# LANGUAGE GADTs #-}


module Duckling.Rules.CS
  ( defaultRules
  , langRules
  , localeRules
  ) where

import Duckling.Dimensions.Types
import Duckling.Locale
import Duckling.Types
import qualified Duckling.Distance.CS.Rules as Distance
import qualified Duckling.Numeral.CS.Rules as Numeral

defaultRules :: Some Dimension -> [Rule]
defaultRules = langRules

localeRules :: Region -> Some Dimension -> [Rule]
localeRules region (This (CustomDimension dim)) = dimLocaleRules region dim
localeRules _ _ = []

langRules :: Some Dimension -> [Rule]
langRules (This AmountOfMoney) = []
langRules (This CreditCardNumber) = []
langRules (This Distance) = Distance.rules
langRules (This Duration) = []
langRules (This ModifiedDuration) = []
langRules (This Email) = []
langRules (This Numeral) = Numeral.rules
langRules (This ModifiedNumeral) = []
langRules (This Ordinal) = []
langRules (This PhoneNumber) = []
langRules (This Quantity) = []
langRules (This RegexMatch) = []
langRules (This Temperature) = []
langRules (This Time) = []
langRules (This TimeGrain) = []
langRules (This Url) = []
langRules (This Volume) = []
langRules (This (CustomDimension dim)) = dimLangRules CS dim
