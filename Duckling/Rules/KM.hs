-- Copyright (c) 2016-present, Facebook, Inc.
-- All rights reserved.
--
-- This source code is licensed under the BSD-style license found in the
-- LICENSE file in the root directory of this source tree.


{-# LANGUAGE GADTs #-}


module Duckling.Rules.KM
  ( defaultRules
  , langRules
  , localeRules
  ) where

import Duckling.Dimensions.Types
import Duckling.Locale
import Duckling.Types
import qualified Duckling.Distance.KM.Rules as Distance
import qualified Duckling.Numeral.KM.Rules as Numeral
import qualified Duckling.Ordinal.KM.Rules as Ordinal
import qualified Duckling.Quantity.KM.Rules as Quantity
import qualified Duckling.Temperature.KM.Rules as Temperature
import qualified Duckling.Volume.KM.Rules as Volume

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
langRules (This Ordinal) = Ordinal.rules
langRules (This PhoneNumber) = []
langRules (This Quantity) = Quantity.rules
langRules (This RegexMatch) = []
langRules (This Temperature) = Temperature.rules
langRules (This Time) = []
langRules (This TimeGrain) = []
langRules (This Url) = []
langRules (This Volume) = Volume.rules
langRules (This (CustomDimension dim)) = dimLangRules KM dim
