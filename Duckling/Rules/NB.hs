-- Copyright (c) 2016-present, Facebook, Inc.
-- All rights reserved.
--
-- This source code is licensed under the BSD-style license found in the
-- LICENSE file in the root directory of this source tree.


{-# LANGUAGE GADTs #-}


module Duckling.Rules.NB
  ( defaultRules
  , langRules
  , localeRules
  ) where

import Duckling.Dimensions.Types
import Duckling.Locale
import Duckling.Types
import qualified Duckling.AmountOfMoney.NB.Rules as AmountOfMoney
import qualified Duckling.Duration.NB.Rules as Duration
import qualified Duckling.Numeral.NB.Rules as Numeral
import qualified Duckling.Ordinal.NB.Rules as Ordinal
import qualified Duckling.Time.NB.Rules as Time
import qualified Duckling.TimeGrain.NB.Rules as TimeGrain

defaultRules :: Some Dimension -> [Rule]
defaultRules = langRules

localeRules :: Region -> Some Dimension -> [Rule]
localeRules region (This (CustomDimension dim)) = dimLocaleRules region dim
localeRules _ _ = []

langRules :: Some Dimension -> [Rule]
langRules (This AmountOfMoney) = AmountOfMoney.rules
langRules (This CreditCardNumber) = []
langRules (This Distance) = []
langRules (This Duration) = Duration.rules
langRules (This ModifiedDuration) = []
langRules (This Email) = []
langRules (This Numeral) = Numeral.rules
langRules (This ModifiedNumeral) = []
langRules (This Ordinal) = Ordinal.rules
langRules (This PhoneNumber) = []
langRules (This Quantity) = []
langRules (This RegexMatch) = []
langRules (This Temperature) = []
langRules (This Time) = Time.rules
langRules (This TimeGrain) = TimeGrain.rules
langRules (This Url) = []
langRules (This Volume) = []
langRules (This (CustomDimension dim)) = dimLangRules NB dim
