-- Copyright (c) 2016-present, Facebook, Inc.
-- All rights reserved.
--
-- This source code is licensed under the BSD-style license found in the
-- LICENSE file in the root directory of this source tree.


{-# LANGUAGE GADTs #-}
{-# LANGUAGE NoRebindableSyntax #-}
{-# LANGUAGE OverloadedStrings #-}

module Duckling.Time.ZH.Rules
  ( rules
  ) where

import Data.Text (Text)
import Prelude
import qualified Data.HashMap.Strict as HashMap
import qualified Data.Text as Text

import Duckling.Dimensions.Types
import Duckling.Numeral.Helpers (parseInt)
import Duckling.Regex.Types
import Duckling.Time.Computed
import Duckling.Time.Helpers
import Duckling.Time.Types (TimeData (..))
import Duckling.Duration.Types (DurationData (..))
import Duckling.Types
import qualified Duckling.Ordinal.Types as TOrdinal
import qualified Duckling.Duration.Types as TDuration
import qualified Duckling.Time.Types as TTime
import qualified Duckling.TimeGrain.Types as TG

digitZHRegex :: String
digitZHRegex = "〇|零|一|二|三|四|五|伍|六|七|八|九"

integerMap :: HashMap.HashMap Text Integer
integerMap = HashMap.fromList
  [ ( "0", 0 )
  , ( "〇", 0 )
  , ( "零", 0 )
  , ( "1", 1 )
  , ( "一", 1 )
  , ( "2", 2 )
  , ( "二", 2 )
  , ( "3", 3 )
  , ( "三", 3 )
  , ( "4", 4 )
  , ( "四", 4 )
  , ( "5", 5 )
  , ( "五", 5 )
  , ( "6", 6 )
  , ( "六", 6 )
  , ( "7", 7 )
  , ( "七", 7 )
  , ( "8", 8 )
  , ( "八", 8 )
  , ( "9", 9 )
  , ( "九", 9 )
  ]

ruleTheDayAfterTomorrow :: Rule
ruleTheDayAfterTomorrow = Rule
  { name = "the day after tomorrow"
  , pattern =
    [ regex "后天|後天|後日"
    ]
  , prod = \_ -> tt $ cycleNth TG.Day 2
  }

ruleTheDayAfterTheDayAfterTomorrow :: Rule
ruleTheDayAfterTheDayAfterTomorrow = Rule
  { name = "the day after the day after tomorrow"
  , pattern =
    [ regex "大后天|大後天|大後日"
    ]
  , prod = \_ -> tt $ cycleNth TG.Day 3
  }

ruleRelativeMinutesTotillbeforeIntegerHourofday :: Rule
ruleRelativeMinutesTotillbeforeIntegerHourofday = Rule
  { name = "relative minutes to|till|before <integer> (hour-of-day)"
  , pattern =
    [ Predicate isAnHourOfDay
    , regex "(点|點|时|時)差"
    , Predicate $ isIntegerBetween 1 59
    ]
  , prod = \tokens -> case tokens of
      (Token Time td:_:token:_) -> do
        n <- getIntValue token
        Token Time <$> minutesBefore n td
      _ -> Nothing
  }

ruleRelativeMinutesTotillbeforeIntegerHourofdayWithMinuteUnit :: Rule
ruleRelativeMinutesTotillbeforeIntegerHourofdayWithMinuteUnit = Rule
  { name = "relative minutes to|till|before <integer> (hour-of-day) with minute unit"
  , pattern =
    [ Predicate isAnHourOfDay
    , regex "(点|點|时|時)差"
    , Predicate $ isIntegerBetween 1 59
    , regex "分"
    ]
  , prod = \tokens -> case tokens of
      (Token Time td:_:token:_) -> do
        n <- getIntValue token
        Token Time <$> minutesBefore n td
      _ -> Nothing
  }

ruleRelativeMinutesTotillbeforeIntegerHourofdayWithMinuteUnitReversed :: Rule
ruleRelativeMinutesTotillbeforeIntegerHourofdayWithMinuteUnitReversed = Rule
  { name = "relative minutes to|till|before <integer> (hour-of-day) with minute unit reversed"
  , pattern =
    [ regex "差"
    , Predicate $ isIntegerBetween 1 59
    , regex "分"
    , Predicate isAnHourOfDay
    , regex "(点|點|时|時)"
    ]
  , prod = \tokens -> case tokens of
      (_:token:_:Token Time td:_) -> do
        n <- getIntValue token
        Token Time <$> minutesBefore n td
      _ -> Nothing
  }

ruleRelativeMinutesTotillbeforeNoonmidnight :: Rule
ruleRelativeMinutesTotillbeforeNoonmidnight = Rule
  { name = "relative minutes to|till|before noon|midnight"
  , pattern =
    [ Predicate isMidnightOrNoon
    , regex "差"
    , Predicate $ isIntegerBetween 1 59
    ]
  , prod = \tokens -> case tokens of
      (Token Time td:_:token:_) -> do
        n <- getIntValue token
        Token Time <$> minutesBefore n td
      _ -> Nothing
  }

ruleRelativeMinutesTotillbeforeNoonmidnightWithMinuteUnit :: Rule
ruleRelativeMinutesTotillbeforeNoonmidnightWithMinuteUnit = Rule
  { name = "relative minutes to|till|before noon|midnight with minute unit"
  , pattern =
    [ Predicate isMidnightOrNoon
    , regex "差"
    , Predicate $ isIntegerBetween 1 59
    , regex "分"
    ]
  , prod = \tokens -> case tokens of
      (Token Time td:_:token:_) -> do
        n <- getIntValue token
        Token Time <$> minutesBefore n td
      _ -> Nothing
  }
  
ruleRelativeMinutesAfterpastIntegerHourofday :: Rule
ruleRelativeMinutesAfterpastIntegerHourofday = Rule
  { name = "relative minutes after|past <integer> (hour-of-day)"
  , pattern =
    [ Predicate isAnHourOfDay
    , regex "点|點|时|時"
    , Predicate $ isIntegerBetween 1 59
    ]
  , prod = \tokens -> case tokens of
      (Token Time TimeData {TTime.form = Just (TTime.TimeOfDay (Just hours) _)}:
       _:
       token:
       _) -> do
        n <- getIntValue token
        tt $ hourMinute True hours n
      _ -> Nothing
  }

ruleRelativeMinutesAfterpastIntegerHourofdayWithMinuteUnit :: Rule
ruleRelativeMinutesAfterpastIntegerHourofdayWithMinuteUnit = Rule
  { name = "relative minutes after|past <integer> (hour-of-day) with minute unit"
  , pattern =
    [ Predicate isAnHourOfDay
    , regex "点|點|时|時"
    , Predicate $ isIntegerBetween 1 59
    , regex "分"
    ]
  , prod = \tokens -> case tokens of
      (Token Time TimeData {TTime.form = Just (TTime.TimeOfDay (Just hours) _)}:
        _:
        token:
        _) -> do
        n <- getIntValue token
        tt $ hourMinute True hours n
      _ -> Nothing
  }

ruleRelativeMinutesAfterpastNoonmidnight :: Rule
ruleRelativeMinutesAfterpastNoonmidnight = Rule
  { name = "relative minutes after|past noon|midnight"
  , pattern =
    [ Predicate isMidnightOrNoon
    , regex "过|\x904e"
    , Predicate $ isIntegerBetween 1 59
    ]
  , prod = \tokens -> case tokens of
      (Token Time TimeData {TTime.form = Just (TTime.TimeOfDay (Just hours) _)}:
       _:
       token:
       _) -> do
        n <- getIntValue token
        tt $ hourMinute True hours n
      _ -> Nothing
  }

ruleRelativeMinutesAfterpastNoonmidnightWithMinuteUnit :: Rule
ruleRelativeMinutesAfterpastNoonmidnightWithMinuteUnit = Rule
  { name = "relative minutes after|past noon|midnight with minute unit"
  , pattern =
    [ Predicate isMidnightOrNoon
    , regex "过|\x904e"
    , Predicate $ isIntegerBetween 1 59
    ]
  , prod = \tokens -> case tokens of
      (Token Time TimeData {TTime.form = Just (TTime.TimeOfDay (Just hours) _)}:
        _:
        token:
        _) -> do
        n <- getIntValue token
        tt $ hourMinute True hours n
      _ -> Nothing
  }
  
ruleQuarterTotillbeforeIntegerHourofday :: Rule
ruleQuarterTotillbeforeIntegerHourofday = Rule
  { name = "quarter to|till|before <integer> (hour-of-day)"
  , pattern =
    [ Predicate isAnHourOfDay
    , regex "(点|點|时|時)差"
    , regex "一刻"
    ]
  , prod = \tokens -> case tokens of
      (Token Time td:_) -> Token Time <$> minutesBefore 15 td
      _ -> Nothing
  }
ruleQuarterTotillbeforeNoonmidnight :: Rule
ruleQuarterTotillbeforeNoonmidnight = Rule
  { name = "quarter to|till|before noon|midnight"
  , pattern =
    [ Predicate isMidnightOrNoon
    , regex "差"
    , regex "一刻"
    ]
  , prod = \tokens -> case tokens of
      (Token Time td:_) -> Token Time <$> minutesBefore 15 td
      _ -> Nothing
  }
ruleQuarterAfterpastIntegerHourofday :: Rule
ruleQuarterAfterpastIntegerHourofday = Rule
  { name = "quarter after|past <integer> (hour-of-day)"
  , pattern =
    [ Predicate isAnHourOfDay
    , regex "点|點|时|時"
    , regex "一刻"
    ]
  , prod = \tokens -> case tokens of
      (Token Time TimeData {TTime.form = Just (TTime.TimeOfDay (Just hours) _)}:
       _) -> tt $ hourMinute True hours 15
      _ -> Nothing
  }
ruleThreeQuarterAfterpastIntegerHourofday :: Rule
ruleThreeQuarterAfterpastIntegerHourofday = Rule
  { name = "three quarter after|past <integer> (hour-of-day)"
  , pattern =
    [ Predicate isAnHourOfDay
    , regex "点|點|时|時"
    , regex "三刻"
    ]
  , prod = \tokens -> case tokens of
      (Token Time TimeData {TTime.form = Just (TTime.TimeOfDay (Just hours) _)}:
       _) -> tt $ hourMinute True hours 45
      _ -> Nothing
  }
ruleQuarterAfterpastNoonmidnight :: Rule
ruleQuarterAfterpastNoonmidnight = Rule
  { name = "quarter after|past noon|midnight"
  , pattern =
    [ Predicate isMidnightOrNoon
    , regex "过"
    , regex "一刻"
    ]
  , prod = \tokens -> case tokens of
      (Token Time TimeData {TTime.form = Just (TTime.TimeOfDay (Just hours) _)}:
       _) -> tt $ hourMinute True hours 15
      _ -> Nothing
  }

ruleHalfTotillbeforeIntegerHourofday :: Rule
ruleHalfTotillbeforeIntegerHourofday = Rule
  { name = "half to|till|before <integer> (hour-of-day)"
  , pattern =
    [ Predicate isAnHourOfDay
    , regex "(点|點|时|時)差"
    , regex "半"
    ]
  , prod = \tokens -> case tokens of
      (Token Time td:_) -> Token Time <$> minutesBefore 30 td
      _ -> Nothing
  }
ruleHalfTotillbeforeNoonmidnight :: Rule
ruleHalfTotillbeforeNoonmidnight = Rule
  { name = "half to|till|before noon|midnight"
  , pattern =
    [ Predicate isMidnightOrNoon
    , regex "差"
    , regex "半"
    ]
  , prod = \tokens -> case tokens of
      (Token Time td:_) -> Token Time <$> minutesBefore 30 td
      _ -> Nothing
  }
ruleHalfAfterpastIntegerHourofday :: Rule
ruleHalfAfterpastIntegerHourofday = Rule
  { name = "half after|past <integer> (hour-of-day)"
  , pattern =
    [ Predicate isAnHourOfDay
    , regex "点|點|时|時"
    , regex "半"
    ]
  , prod = \tokens -> case tokens of
      (Token Time TimeData {TTime.form = Just (TTime.TimeOfDay (Just hours) _)}:
       _) -> tt $ hourMinute True hours 30
      _ -> Nothing
  }
ruleHalfAfterpastNoonmidnight :: Rule
ruleHalfAfterpastNoonmidnight = Rule
  { name = "half after|past noon|midnight"
  , pattern =
    [ Predicate isMidnightOrNoon
    , regex "过"
    , regex "半"
    ]
  , prod = \tokens -> case tokens of
      (Token Time TimeData {TTime.form = Just (TTime.TimeOfDay (Just hours) _)}:
       _) -> tt $ hourMinute True hours 30
      _ -> Nothing
  }

ruleHhmmTimeofday :: Rule
ruleHhmmTimeofday = Rule
  { name = "hh:mm (time-of-day)"
  , pattern =
    [ regex "((?:[01]?\\d)|(?:2[0-3]))[:：︓﹕]([0-5]\\d)"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (hh:mm:_)):_) -> do
        h <- parseInt hh
        m <- parseInt mm
        tt $ hourMinute True h m
      _ -> Nothing
  }

ruleHHMMSS :: Rule
ruleHHMMSS = Rule
  { name = "hh:mm:ss"
  , pattern = [regex "((?:[01]?\\d)|(?:2[0-3]))[:.]([0-5]\\d)[:.]([0-5]\\d)"]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (hh:mm:ss:_)):_) -> do
        h <- parseInt hh
        m <- parseInt mm
        s <- parseInt ss
        tt $ hourMinuteSecond (h < 12) h m s
      _ -> Nothing
  }

ruleThisDayofweek :: Rule
ruleThisDayofweek = Rule
  { name = "this <day-of-week>"
  , pattern =
    [ regex "(这|這|今)(个|個)?|(本|当)"
    , Predicate isADayOfWeek
    ]
  , prod = \tokens -> case tokens of
      (_:Token Time td:_) -> do
        tw <- Just $ cycleNth TG.Week 0
        Token Time <$> intersect td tw
      _ -> Nothing
  }

ruleNthTimeOfTime2 :: Rule
ruleNthTimeOfTime2 = Rule
  { name = "nth <time> of <time> 2"
  , pattern =
    [ dimension Time
    , regex "的"
    , dimension Ordinal
    , dimension Time
    ]
  , prod = \tokens -> case tokens of
      (Token Time td1:_:Token Ordinal od:Token Time td2:_) -> Token Time .
        predNth (TOrdinal.value od - 1) False <$> intersect td2 td1
      _ -> Nothing
  }

ruleLastTime :: Rule
ruleLastTime = Rule
  { name = "last <time>"
  , pattern =
    [ regex "去|上(个|個)?"
    , Predicate isOkWithThisNext
    ]
  , prod = \tokens -> case tokens of
      (_:Token Time td:_) -> tt $ predNth (- 1) False td
      _ -> Nothing
  }

ruleInDuration :: Rule
ruleInDuration = Rule
  { name = "in <duration>"
  , pattern =
    [ regex "再"
    , dimension Duration
    ]
  , prod = \tokens -> case tokens of
      (_:Token Duration dd:_) -> tt $ inDuration dd
      _ -> Nothing
  }

ruleNow :: Rule
ruleNow = Rule
  { name = "now"
  , pattern =
    [ regex "现在|此时|此刻|当前|現在|此時|當前|\x5b9c\x5bb6|\x800c\x5bb6|\x4f9d\x5bb6"
    ]
  , prod = \_ -> tt now
  }

ruleTheCycleAfterTime :: Rule
ruleTheCycleAfterTime = Rule
  { name = "the <cycle> after <time>"
  , pattern =
    [ regex "那"
    , dimension TimeGrain
    , regex "(之)?(后|後)"
    , dimension Time
    ]
  , prod = \tokens -> case tokens of
      (_:Token TimeGrain grain:_:Token Time td:_) ->
        tt $ cycleNthAfter False grain 1 td
      _ -> Nothing
  }

ruleTheCycleBeforeTime :: Rule
ruleTheCycleBeforeTime = Rule
  { name = "the <cycle> before <time>"
  , pattern =
    [ regex "那"
    , dimension TimeGrain
    , regex "(之)?前"
    , dimension Time
    ]
  , prod = \tokens -> case tokens of
      (_:Token TimeGrain grain:_:Token Time td:_) ->
        tt $ cycleNthAfter False grain (-1) td
      _ -> Nothing
  }

ruleNoon :: Rule
ruleNoon = Rule
  { name = "noon"
  , pattern =
    [ regex "中午"
    ]
  , prod = \_ ->
      let from = hour False 11
          to = hour False 13
      in Token Time . mkLatent . partOfDay <$>
           interval TTime.Open from to
  }

ruleToday :: Rule
ruleToday = Rule
  { name = "today"
  , pattern =
    [ regex "今天|今日"
    ]
  , prod = \_ -> tt today
  }

ruleTheDayBeforeYesterday :: Rule
ruleTheDayBeforeYesterday = Rule
  { name = "the day before yesterday"
  , pattern =
    [ regex "前天|前日"
    ]
  , prod = \_ -> tt . cycleNth TG.Day $ - 2
  }

ruleTheDayBeforeTheDayBeforeYesterday :: Rule
ruleTheDayBeforeTheDayBeforeYesterday = Rule
  { name = "the day before the day before yesterday"
  , pattern =
    [ regex "大前天|大前日"
    ]
  , prod = \_ -> tt . cycleNth TG.Day $ - 3
  }

ruleNextCycle :: Rule
ruleNextCycle = Rule
  { name = "next <cycle>"
  , pattern =
    [ regex "下(个|個)?"
    , dimension TimeGrain
    ]
  , prod = \tokens -> case tokens of
      (_:Token TimeGrain grain:_) ->
        tt $ cycleNth grain 1
      _ -> Nothing
  }

ruleDurationFromNow :: Rule
ruleDurationFromNow = Rule
  { name = "<duration> from now"
  , pattern =
    [ dimension Duration
    , regex "后|後|之後"
    ]
  , prod = \tokens -> case tokens of
      (Token Duration DurationData{TDuration.grain = g, TDuration.value = v}:_)
        -> tt $ cycleNth g v
      _ -> Nothing
  }

ruleLastCycle :: Rule
ruleLastCycle = Rule
  { name = "last <cycle>"
  , pattern =
    [ regex "上(个|個)?"
    , dimension TimeGrain
    ]
  , prod = \tokens -> case tokens of
      (_:Token TimeGrain grain:_) ->
        tt . cycleNth grain $ - 1
      _ -> Nothing
  }

ruleAfternoon :: Rule
ruleAfternoon = Rule
  { name = "afternoon"
  , pattern =
    [ regex "下午|\x664f\x665d"
    ]
  , prod = \_ ->
      let from = hour False 12
          to = hour False 19
      in Token Time . mkLatent . partOfDay <$>
           interval TTime.Open from to
  }

ruleMidnight :: Rule
ruleMidnight = Rule
  { name = "midnight"
  , pattern =
    [ regex "午夜|半夜"
    ]
  , prod = \_ -> tt $ mkOkForThisNext $ hour False 0
  }

ruleInduringThePartofday :: Rule
ruleInduringThePartofday = Rule
  { name = "in|during the <part-of-day>"
  , pattern =
    [ Predicate isAPartOfDay
    , regex "点|點|时|時"
    ]
  , prod = \tokens -> case tokens of
      (Token Time td:_) ->
        tt $ notLatent td
      _ -> Nothing
  }

ruleIntersectBy :: Rule
ruleIntersectBy = Rule
  { name = "intersect by \",\""
  , pattern =
    [ Predicate isNotLatent
    , regex ","
    , Predicate isNotLatent
    ]
  , prod = \tokens -> case tokens of
      (Token Time td1:_:Token Time td2:_) ->
        Token Time <$> intersect td1 td2
      _ -> Nothing
  }

ruleMmdd :: Rule
ruleMmdd = Rule
  { name = "mm/dd"
  , pattern =
    [ regex "(0?[1-9]|1[0-2])/(3[01]|[12]\\d|0?[1-9])"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (mm:dd:_)):_) -> do
        m <- parseInt mm
        d <- parseInt dd
        tt $ monthDay m d
      _ -> Nothing
  }

ruleIntegerLatentTimeofday :: Rule
ruleIntegerLatentTimeofday = Rule
  { name = "<integer> (latent time-of-day)"
  , pattern =
    [ Predicate $ isIntegerBetween 0 23
    ]
  , prod = \tokens -> case tokens of
      (token:_) -> do
        v <- getIntValue token
        tt . mkLatent $ hour True v
      _ -> Nothing
  }

ruleYearNumericWithYearSymbol :: Rule
ruleYearNumericWithYearSymbol = Rule
  { name = "year (numeric with year symbol)"
  , pattern =
    [ Predicate $ isIntegerBetween 1000 9999
    , regex "年"
    ]
  , prod = \tokens -> case tokens of
      (token:_) -> do
        v <- getIntValue token
        tt $ year v
      _ -> Nothing
  }

ruleYearNumericWithYearSymbol2 :: Rule
ruleYearNumericWithYearSymbol2 = Rule
  { name = "year (numeric with year symbol2)"
  , pattern =
    [ regex "([0-9])([0-9])"
    , regex "年"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (dTen:dDigit:_)):_) -> do
        vTen <- HashMap.lookup dTen integerMap
        vDigit <- HashMap.lookup dDigit integerMap
        let v = fromIntegral vTen * 10 + fromIntegral vDigit
        case (v > -1 && v < 100) of
          True -> tt $ year (if v > -1 && v < 49 then (2000 + v) else (1900 + v))
          False -> Nothing
      _ -> Nothing
  }


ruleYearNumericWithYearSymbol3 :: Rule
ruleYearNumericWithYearSymbol3 = Rule
  { name = "year (numeric with year symbol3)"
  , pattern =
    [ regex $ "(" ++ digitZHRegex ++ ")(" ++ digitZHRegex ++ ")"
    , regex "年"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (dTen:dDigit:_)):_) -> do
        vTen <- HashMap.lookup dTen integerMap
        vDigit <- HashMap.lookup dDigit integerMap
        let v = fromIntegral vTen * 10 + fromIntegral vDigit
        case (v > -1 && v < 100) of
          True -> tt $ year (if v > -1 && v < 49 then (2000 + v) else (1900 + v))
          False -> Nothing
      _ -> Nothing
  }

ruleDurationAgo :: Rule
ruleDurationAgo = Rule
  { name = "<duration> ago"
  , pattern =
    [ dimension Duration
    , regex "(之)?前"
    ]
  , prod = \tokens -> case tokens of
      (Token Duration DurationData{TDuration.grain = g, TDuration.value = v}:_)
        -> tt $ cycleNth g (- v)
      _ -> Nothing
  }

ruleHhmmMilitaryTimeofday :: Rule
ruleHhmmMilitaryTimeofday = Rule
  { name = "hhmm (military time-of-day)"
  , pattern =
    [ regex "((?:[01]?\\d)|(?:2[0-3]))([0-5]\\d)"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (hh:mm:_)):_) -> do
        h <- parseInt hh
        m <- parseInt mm
        tt . mkLatent $ hourMinute False h m
      _ -> Nothing
  }

ruleLastNCycle :: Rule
ruleLastNCycle = Rule
  { name = "last n <cycle>"
  , pattern =
    [ regex "上|前"
    , Predicate $ isIntegerBetween 1 9999
    , dimension TimeGrain
    ]
  , prod = \tokens -> case tokens of
      (_:token:Token TimeGrain grain:_) -> do
        v <- getIntValue token
        tt $ cycleN True grain (- v)
      _ -> Nothing
  }

ruleNCycleLast :: Rule
ruleNCycleLast = Rule
  { name = "n <cycle> last"
  , pattern =
    [ Predicate $ isIntegerBetween 1 9999
    , dimension TimeGrain
    , regex "(之)?前"
    ]
  , prod = \tokens -> case tokens of
      (token:Token TimeGrain grain:_) -> do
        v <- getIntValue token
        tt $ cycleNth grain $ - v
      _ -> Nothing
}

ruleIntersect :: Rule
ruleIntersect = Rule
  { name = "intersect"
  , pattern =
    [ Predicate isNotLatent
    , Predicate isNotLatent
    ]
  , prod = \tokens -> case tokens of
      (Token Time td1:Token Time td2:_) ->
        Token Time <$> intersect td1 td2
      _ -> Nothing
  }

ruleNthTimeOfTime :: Rule
ruleNthTimeOfTime = Rule
  { name = "nth <time> of <time>"
  , pattern =
    [ dimension Time
    , dimension Ordinal
    , dimension Time
    ]
  , prod = \tokens -> case tokens of
      (Token Time td1:Token Ordinal od:Token Time td2:_) -> Token Time .
        predNth (TOrdinal.value od - 1) False <$> intersect td2 td1
      _ -> Nothing
  }

ruleWeekend :: Rule
ruleWeekend = Rule
  { name = "week-end"
  , pattern =
    [ regex "周末|週末"
    ]
  , prod = \_ -> tt $ mkOkForThisNext weekend
  }

ruleLastYear :: Rule
ruleLastYear = Rule
  { name = "last year"
  , pattern =
    [ regex "去年|上年"
    ]
  , prod = \_ -> tt . cycleNth TG.Year $ - 1
  }

ruleLastLastYear :: Rule
ruleLastLastYear = Rule
  { name = "last last year"
  , pattern =
    [ regex "前年"
    ]
  , prod = \_ -> tt . cycleNth TG.Year $ - 2
  }

ruleDimTimePartofday :: Rule
ruleDimTimePartofday = Rule
  { name = "<dim time> <part-of-day>"
  , pattern =
    [ dimension Time
    , Predicate isAPartOfDay
    ]
  , prod = \tokens -> case tokens of
      (Token Time td1:Token Time td2:_) ->
        Token Time <$> intersect td1 td2
      _ -> Nothing
  }

ruleNextTime :: Rule
ruleNextTime = Rule
  { name = "next <time>"
  , pattern =
    [ regex "明|下(个|個)?"
    , Predicate isOkWithThisNext
    ]
  , prod = \tokens -> case tokens of
      (_:Token Time td:_) -> tt $ predNth 1 False td
      _ -> Nothing
  }

ruleYyyymmdd :: Rule
ruleYyyymmdd = Rule
  { name = "yyyy-mm-dd"
  , pattern =
    [ regex "(\\d{2,4})[\\p{Pd}(−|/)](0?[1-9]|1[0-2])[\\p{Pd}(−|/)](3[01]|[12]\\d|0?[1-9])"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (yy:mm:dd:_)):_) -> do
        y <- parseInt yy
        m <- parseInt mm
        d <- parseInt dd
        tt $ yearMonthDay y m d
      _ -> Nothing
  }

ruleNextNCycle :: Rule
ruleNextNCycle = Rule
  { name = "next n <cycle>"
  , pattern =
    [ regex "下|后|後"
    , Predicate $ isIntegerBetween 1 9999
    , dimension TimeGrain
    ]
  , prod = \tokens -> case tokens of
      (_:token:Token TimeGrain grain:_) -> do
        v <- getIntValue token
        tt $ cycleN True grain v
      _ -> Nothing
  }

ruleNCycleNext :: Rule
ruleNCycleNext = Rule
  { name = "next n <cycle>"
  , pattern =
    [ Predicate $ isIntegerBetween 1 9999
    , dimension TimeGrain
    , regex "下|(之)?后|(之)?後"
    ]
  , prod = \tokens -> case tokens of
      (token:Token TimeGrain grain:_) -> do
        v <- getIntValue token
        tt $ cycleNth grain v
      _ -> Nothing
  }

ruleMorning :: Rule
ruleMorning = Rule
  { name = "morning"
  , pattern =
    [ regex "早上|上午|早晨|早|\x671d(\x982d)?早"
    ]
  , prod = \_ ->
      let from = hour False 4
          to = hour False 12
      in Token Time . mkLatent . partOfDay <$>
           interval TTime.Open from to
  }

ruleEarlyMorning :: Rule
ruleEarlyMorning = Rule
  { name = "early morning"
  , pattern =
    [ regex "凌晨"
    ]
  , prod = \_ ->
      let from = hour False 0
          to = hour False 6
      in Token Time . mkLatent . partOfDay <$>
           interval TTime.Open from to
  }

ruleNextYear :: Rule
ruleNextYear = Rule
  { name = "next year"
  , pattern =
    [ regex "明年|下年"
    ]
  , prod = \_ -> tt $ cycleNth TG.Year 1
  }

ruleNextNextYear :: Rule
ruleNextNextYear = Rule
  { name = "next next year"
  , pattern =
    [ regex "后年|後年"
    ]
  , prod = \_ -> tt $ cycleNth TG.Year 2
  }

ruleThisCycle :: Rule
ruleThisCycle = Rule
  { name = "this <cycle>"
  , pattern =
    [ regex "今(个|個)?|(这|這)(一|个|個)?|(本|当)"
    , dimension TimeGrain
    ]
  , prod = \tokens -> case tokens of
      (_:Token TimeGrain grain:_) -> tt $ cycleNth grain 0
      _ -> Nothing
  }

ruleThisTime :: Rule
ruleThisTime = Rule
  { name = "this <time>"
  , pattern =
    [ regex "今(个|個)?|(这|這)(一|个|個)?|(本|当)"
    , Predicate isOkWithThisNext
    ]
  , prod = \tokens -> case tokens of
      (_:Token Time td:_) -> tt $ predNth 0 False td
      _ -> Nothing
  }

ruleYesterday :: Rule
ruleYesterday = Rule
  { name = "yesterday"
  , pattern =
    [ regex "昨天|昨日|\x5c0b日"
    ]
  , prod = \_ -> tt . cycleNth TG.Day $ - 1
  }

ruleLastNight :: Rule
ruleLastNight = Rule
  { name = "last night"
  , pattern =
    [ regex "昨晚|昨天晚上|\x5c0b晚"
    ]
  , prod = \_ -> do
      let td1 = cycleNth TG.Day $ - 1
      td2 <- interval TTime.Open (hour False 18) (hour False 0)
      Token Time . partOfDay <$> intersect td1 td2
  }

ruleTimeofdayAmpm :: Rule
ruleTimeofdayAmpm = Rule
  { name = "<time-of-day> am|pm"
  , pattern =
    [ Predicate isATimeOfDay
    , regex "([ap])(\\s|\\.)?m?\\.?"
    ]
  , prod = \tokens -> case tokens of
      (Token Time td:Token RegexMatch (GroupMatch (ap:_)):_) ->
        tt $ timeOfDayAMPM (Text.toLower ap == "a") td
      _ -> Nothing
  }

ruleDOM :: Rule
ruleDOM = Rule
  { name = "<day-of-month>"
  , pattern =
    [ Predicate isDOMInteger
    , regex "号|號|日"
    ]
  , prod = \tokens -> case tokens of
      (token:_) -> do
        v <- getIntValue token
        tt $ dayOfMonth v
      _ -> Nothing
  }

ruleNamedmonthDayofmonth :: Rule
ruleNamedmonthDayofmonth = Rule
  { name = "<named-month> <day-of-month>"
  , pattern =
    [ Predicate isAMonth
    , Predicate isDOMInteger
    , regex "号|號|日"
    ]
  , prod = \tokens -> case tokens of
      (Token Time td:token:_) -> Token Time <$> intersectDOM td token
      _ -> Nothing
  }

rulePartofdayDimTime :: Rule
rulePartofdayDimTime = Rule
  { name = "<part-of-day> <dim time>"
  , pattern =
    [ Predicate isAPartOfDay
    , dimension Time
    ]
  , prod = \tokens -> case tokens of
      (Token Time td1:Token Time td2:_) ->
        Token Time <$> intersect td1 td2
      _ -> Nothing
  }

ruleTonight :: Rule
ruleTonight = Rule
  { name = "tonight"
  , pattern =
    [ regex "今晚|今天晚上"
    ]
  , prod = \_ -> do
      td2 <- interval TTime.Open (hour False 18) (hour False 0)
      Token Time . partOfDay <$> intersect today td2
  }

ruleTomorrowNight :: Rule
ruleTomorrowNight = Rule
  { name = "tomorrow night"
  , pattern =
    [ regex "明晚|明天晚上|\x807d晚"
    ]
  , prod = \_ -> do
      let td1 = cycleNth TG.Day 1
      td2 <- interval TTime.Open (hour False 18) (hour False 0)
      Token Time . partOfDay <$> intersect td1 td2
  }

ruleThisYear :: Rule
ruleThisYear = Rule
  { name = "this year"
  , pattern =
    [ regex "今年"
    ]
  , prod = \_ -> tt $ cycleNth TG.Year 0
  }

ruleAbsorptionOfAfterNamedDay :: Rule
ruleAbsorptionOfAfterNamedDay = Rule
  { name = "absorption of , after named day"
  , pattern =
    [ Predicate isADayOfWeek
    , regex ","
    ]
  , prod = \tokens -> case tokens of
      (x:_) -> Just x
      _ -> Nothing
  }

ruleEveningnight :: Rule
ruleEveningnight = Rule
  { name = "evening|night"
  , pattern =
    [ regex "晚上|傍晚|晚间|夜间|晚"
    ]
  , prod = \_ ->
      let from = hour False 18
          to = hour False 0
      in Token Time . partOfDay . mkLatent <$>
           interval TTime.Open from to
  }

ruleMmddyyyy :: Rule
ruleMmddyyyy = Rule
  { name = "mm/dd/yyyy"
  , pattern =
    [ regex "(0?[1-9]|1[0-2])/(3[01]|[12]\\d|0?[1-9])/(\\d{2,4})"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (mm:dd:yy:_)):_) -> do
        y <- parseInt yy
        m <- parseInt mm
        d <- parseInt dd
        tt $ yearMonthDay y m d
      _ -> Nothing
  }

ruleTomorrow :: Rule
ruleTomorrow = Rule
  { name = "tomorrow"
  , pattern =
    [ regex "明天|明日|\x807d日"
    ]
  , prod = \_ -> tt $ cycleNth TG.Day 1
  }

ruleTimeofdayOclock :: Rule
ruleTimeofdayOclock = Rule
  { name = "<time-of-day> o'clock"
  , pattern =
    [ Predicate isATimeOfDay
    , regex "點|点|时|時"
    ]
  , prod = \tokens -> case tokens of
      (Token Time td:_) ->
        tt $ notLatent td
      _ -> Nothing
  }

ruleTimezone :: Rule
ruleTimezone = Rule
  { name = "<time> timezone"
  , pattern =
    [ Predicate $ and . sequence [isNotLatent, isATimeOfDay]
    , regex "\\b(YEKT|YEKST|YAKT|YAKST|WITA|WIT|WIB|WGT|WGST|WFT|WET|WEST|WAT|WAST|VUT|VLAT|VLAST|VET|UZT|UYT|UYST|UTC|ULAT|TVT|TMT|TLT|TKT|TJT|TFT|TAHT|SST|SRT|SGT|SCT|SBT|SAST|SAMT|RET|PYT|PYST|PWT|PST|PONT|PMST|PMDT|PKT|PHT|PHOT|PGT|PETT|PETST|PET|PDT|OMST|OMSST|NZST|NZDT|NUT|NST|NPT|NOVT|NOVST|NFT|NDT|NCT|MYT|MVT|MUT|MST|MSK|MSD|MMT|MHT|MDT|MAWT|MART|MAGT|MAGST|LINT|LHST|LHDT|KUYT|KST|KRAT|KRAST|KGT|JST|IST|IRST|IRKT|IRKST|IRDT|IOT|IDT|ICT|HOVT|HKT|GYT|GST|GMT|GILT|GFT|GET|GAMT|GALT|FNT|FKT|FKST|FJT|FJST|EST|EGT|EGST|EET|EEST|EDT|ECT|EAT|EAST|EASST|DAVT|ChST|CXT|CVT|CST|COT|CLT|CLST|CKT|CHAST|CHADT|CET|CEST|CDT|CCT|CAT|CAST|BTT|BST|BRT|BRST|BOT|BNT|AZT|AZST|AZOT|AZOST|AWST|AWDT|AST|ART|AQTT|ANAT|ANAST|AMT|AMST|ALMT|AKST|AKDT|AFT|AEST|AEDT|ADT|ACST|ACDT)\\b"
    ]
  , prod = \tokens -> case tokens of
      (Token Time td:
       Token RegexMatch (GroupMatch (tz:_)):
       _) -> Token Time <$> inTimezone (Text.toUpper tz) td
      _ -> Nothing
  }

ruleDaysOfWeek :: [Rule]
ruleDaysOfWeek = mkRuleDaysOfWeekWithNotImmediate
  [ ( "Monday", "星期一|周一|礼拜一|禮拜一|週一", False )
  , ( "Tuesday", "星期二|周二|礼拜二|禮拜二|週二", False )
  , ( "Wednesday", "星期三|周三|礼拜三|禮拜三|週三", False )
  , ( "Thursday", "星期四|周四|礼拜四|禮拜四|週四", False )
  , ( "Friday", "星期五|周五|礼拜五|禮拜五|週五", False )
  , ( "Saturday", "星期六|周六|礼拜六|禮拜六|週六", False )
  , ( "Sunday", "星期日|星期天|礼拜天|礼拜日|周日|禮拜天|週日|禮拜日", False )
  ]

ruleMonths :: [Rule]
ruleMonths = mkRuleMonths
  [ ( "January", "(一|1)月(份)?" )
  , ( "February", "(二|2)月(份)?" )
  , ( "March", "(三|3)月(份)?" )
  , ( "April", "(四|4)月(份)?" )
  , ( "May", "(五|5)月(份)?" )
  , ( "June", "(六|6)月(份)?" )
  , ( "July", "(七|7)月(份)?" )
  , ( "August", "(八|8)月(份)?" )
  , ( "September", "(九|9)月(份)?" )
  , ( "October", "(十|10)月(份)?" )
  , ( "November", "(十一|11)月(份)?" )
  , ( "December", "(十二|12)月(份)?" )
  ]

rulePeriodicHolidays :: [Rule]
rulePeriodicHolidays = mkRuleHolidays
  -- Fixed dates, year over year
  [ ( "中国共产党的生日", "中(国共产党诞|國共產黨誕)生日|(党|黨)的生日", monthDay 7 1 )
  , ( "愚人节", "愚人(节|節)", monthDay 4 1 )
  , ( "建军节", "(中国人民解放(军|軍)|八一)?建(军节|軍節)", monthDay 8 1 )
  , ( "植树节", "中(国植树节|國植樹節)", monthDay 3 12 )
  , ( "五四青年节", "(中(国|國))?(五四|54)?青年(节|節)", monthDay 5 4 )
  , ( "圣诞节", "(圣诞|聖誕)(节|節)?", monthDay 12 25 )
  , ( "平安夜", "(平安|聖誕)夜", monthDay 12 24 )
  , ( "哥伦布日", "哥(伦|倫)布日", monthDay 10 12 )
  , ( "双十一", "(双|雙)(十一|11)", monthDay 11 11 )
  , ( "万圣节", "万圣节|萬聖節", monthDay 10 31 )
  , ( "香港回归纪念日", "香港回(归纪|歸紀)念日", monthDay 7 1 )
  , ( "人权日", "人(权|權)日", monthDay 12 10 )
  , ( "美国独立日", "(美国)?(独|獨)立日", monthDay 7 4 )
  , ( "儿童节", "(国际|國際)?(六一|61)?(儿|兒)童(节|節)", monthDay 6 1 )
  , ( "国际慈善日", "(国际|國際)慈善日", monthDay 9 5 )
  , ( "国际瑜伽日", "(国际|國際)瑜伽日", monthDay 6 21 )
  , ( "国际爵士日", "(国际|國際)爵士日", monthDay 4 30 )
  , ( "国际奥林匹克日", "(国际|國際)奥林匹克日", monthDay 6 23 )
  , ( "妇女节", "(国际劳动|國際勞動|三八)?(妇|婦)女(节|節)", monthDay 3 8 )
  , ( "劳动节", "(五一|51)?(国际|國際)?(劳动|勞動)(节|節)", monthDay 5 1 )
  , ( "国际青年节", "(国际|國際)青年(节|節)", monthDay 8 12 )
  , ( "澳门回归纪念日", "澳(门|門)回(归纪|歸紀)念日", monthDay 12 20 )
  , ( "全国爱牙日", "全(国爱|國愛)牙日", monthDay 9 20 )
  , ( "全国爱耳日", "全(国爱|國愛)耳日", monthDay 3 3 )
  , ( "全国爱眼日", "全(国爱|國愛)眼日", monthDay 6 6 )
  , ( "南京大屠杀纪念日", "南京大屠(杀纪|殺紀)念日", monthDay 12 13 )
  , ( "辛亥革命纪念日", "辛亥革命(纪|紀)念日", monthDay 10 10 )
  , ( "元旦", "元旦(节|節)?|((公|(阳|陽))(历|曆))?新年", monthDay 1 1 )
  , ( "新年夜", "新年夜", monthDay 12 31 )
  , ( "情人节", "(情人|(圣瓦伦丁|聖瓦倫丁))(节|節)", monthDay 2 14 )
  , ( "清明节", "清明(节|節)", monthDay 4 5 )
  , ( "光棍节", "光棍(节|節)", monthDay 11 11 )
  , ( "圣帕特里克节", "圣帕特里克节|聖帕特裏克節", monthDay 3 17 )
  , ( "教师节", "(中(国|國))?教师(节|節)", monthDay 9 10 )
  , ( "退伍军人节", "(退伍(军|軍)人|老兵)(节|節)", monthDay 11 11 )
  , ( "白色情人节", "白色情人(节|節)", monthDay 3 14 )
  , ( "世界艾滋病日", "世界艾滋病日", monthDay 12 1 )
  , ( "世界献血日", "世界(献|獻)血日", monthDay 6 14 )
  , ( "世界癌症日", "世界癌(症|癥)日", monthDay 2 4 )
  , ( "国际消费者权益日", "(国际|世界)?(消费者权益|消費者權益)日|三一五", monthDay 3 15 )
  , ( "世界糖尿病日", "世界糖尿病日", monthDay 11 14 )
  , ( "世界环境日", "世界(环|環)境日", monthDay 6 5 )
  , ( "世界粮食日", "世界((粮|糧)食|食物)日", monthDay 10 16 )
  , ( "世界心脏日", "世界心(脏|臟)日", monthDay 9 29 )
  , ( "世界海洋日", "世界海洋日", monthDay 6 8 )
  , ( "世界诗歌日", "世界(诗|詩)歌日", monthDay 3 21 )
  , ( "世界人口日", "世界人口日", monthDay 7 11 )
  , ( "世界难民日", "世界(难|難)民日", monthDay 6 20 )
  , ( "世界教师日", "世界教师日", monthDay 10 5 )
  , ( "世界旅游日", "世界旅游日", monthDay 9 27 )

  -- Fixed day/week/month, year over year
  , ( "父亲节", "父(亲节|親節)", nthDOWOfMonth 3 7 6 )
  , ( "马丁路德金日", "(马|馬)丁路德金((纪|紀)念)?日", nthDOWOfMonth 3 1 1)
  , ( "母亲节", "母(亲节|親節)", nthDOWOfMonth 2 7 5 )
  ]


ruleComputedHolidays :: [Rule]
ruleComputedHolidays = mkRuleHolidays
  [ ( "耶稣升天节", "耶(稣|穌)升天(节|節|日)"
    , cycleNthAfter False TG.Day 39 easterSunday )
  , ( "大斋首日", "大(斋|齋)首日|(圣|聖)灰((礼仪|禮儀)?日|星期三)|灰日"
    , cycleNthAfter False TG.Day (-46) easterSunday )
  , ( "阿舒拉节", "阿舒拉(节|節)"
    , cycleNthAfter False TG.Day 9 muharram )
  , ( "克哈特普迦节", "克哈特普迦(节|節)"
    , cycleNthAfter False TG.Day 8 dhanteras )
  , ( "春节", "春(节|節)|(农历|農曆|唐人)新年|新(正|春)|正月(正(时|時)|朔日)|岁首"
    , chineseNewYear )
  , ( "基督圣体节", "基督(圣体|聖體)((圣|聖)血)?((节|節)|瞻(礼|禮))"
    , cycleNthAfter False TG.Day 60 easterSunday )
  , ( "排灯节", "(排|万|萬|印度)(灯节|燈節)"
    , cycleNthAfter False TG.Day 2 dhanteras )
  , ( "复活节星期一", "(复|復)活(节|節)星期一"
    , cycleNthAfter False TG.Day 1 easterSunday )
  , ( "复活节", "(复|復)活(节|節)|主(复|復)活日", easterSunday )
  , ( "古尔邦节", "古(尔|爾)邦(节|節)|宰牲(节|節)"
    , eidalAdha )
  , ( "开斋节", "(开斋|開齋|肉孜|(尔|爾)代)(节|節)", eidalFitr )
  , ( "耶稣受难日", "(耶(稣|穌)|主)受(难|難)(节|節|日)|(圣|聖|沈默)(周|週)五"
    , cycleNthAfter False TG.Day (-2) easterSunday )
  , ( "侯丽节", "((侯|荷)(丽|麗)|洒红|灑紅|欢悦|歡悅|五彩|胡里|好利|霍利)(节|節)"
    , cycleNthAfter False TG.Day 39 vasantPanchami )
  , ( "圣周六"
    , "神?(圣周|聖週)六|(耶(稣|穌)|主)受(难|難)(节|節|日)翌日|(复|復)活(节|節)前夜|黑色星期六"
    , cycleNthAfter False TG.Day (-1) easterSunday )
  , ( "伊斯兰新年", "伊斯兰(教)?(历)?新年"
    , muharram )
  , ( "登霄节"
    , "(夜行)?登霄(节|節)"
    , cycleNthAfter False TG.Day 26 rajab
    )
  , ( "印度丰收节第四天", "(印度(丰|豐)收|(庞|龐)格(尔|爾))(节|節)第四天"
    , cycleNthAfter False TG.Day 2 thaiPongal )
  , ( "篝火节", "((犹|猶)太教)?篝火(节|節)", lagBaOmer )
  , ( "法令之夜"
    , "(法令|命运|权力)之夜"
    , cycleNthAfter False TG.Day 26 ramadan )
  , ( "拉撒路圣周六", "拉撒路(圣周|聖週)六|拉匝路(周|週)六"
    , cycleNthAfter False TG.Day (-8) orthodoxEaster )
  , ( "印度丰收节第三天", "(印度(丰|豐)收|(庞|龐)格(尔|爾))(节|節)第三天"
    , cycleNthAfter False TG.Day 1 thaiPongal )
  , ( "神圣星期四"
    , "濯足(节|節)|神(圣|聖)星期四|(圣周|聖週)(星期)?四|(设|設)立(圣|聖)餐日"
    , cycleNthAfter False TG.Day (-3) easterSunday )
  , ( "圣纪节" , "圣纪节|聖紀節", mawlid )
  , ( "东正教复活节星期一", "(东|東)正教(复|復)活(节|節)星期一"
    , cycleNthAfter False TG.Day 1 orthodoxEaster )
  , ( "东正教复活节", "(东|東)正教((复|復)活(节|節)|主(复|復)活日)"
    , orthodoxEaster )
  , ( "东正教圣周六"
    , "(东|東)正教(神?(圣周|聖週)六|(耶(稣|穌)|主)受(难|難)(节|節|日)翌日|(复|復)活(节|節)前夜)"
    , cycleNthAfter False TG.Day (-1) orthodoxEaster )
  , ( "东正教耶稣受难日", "(东|東)正教((耶(稣|穌)|主)受(难|難)(节|節|日)|(圣|聖|沈默)(周|週)五)"
    , cycleNthAfter False TG.Day (-2) orthodoxEaster )
  , ( "东正教棕枝主日", "(东|東)正教((棕|圣|聖)枝|圣树|聖樹|基督苦(难|難))主日"
    , cycleNthAfter False TG.Day (-7) orthodoxEaster )
  , ( "棕枝主日", "((棕|圣|聖)枝|圣树|聖樹|基督苦(难|難))主日"
    , cycleNthAfter False TG.Day (-7) easterSunday )
  , ( "五旬节", "五旬(节|節)|(圣灵|聖靈)降(临|臨)(日|节|節)"
    , cycleNthAfter False TG.Day 49 easterSunday )
  , ( "印度兄妹节", "(印度兄妹|拉克沙班丹)(节|節)", rakshaBandhan )
  , ( "圣会节", "(圣|聖)会(节|節)"
    , cycleNthAfter False TG.Day 21 roshHashana )
  , ( "忏悔节", "忏悔(节|節|火曜日)|煎(饼|餅)星期二"
    , cycleNthAfter False TG.Day (-47) easterSunday )
  , ( "西赫托拉节", "(西赫(托拉|妥拉)|诵经|誦經|转经|轉經|律法|(欢庆圣|歡慶聖)法)(节|節)"
    , cycleNthAfter False TG.Day 22 roshHashana )
  , ( "印度丰收节", "(印度|淡米(尔|爾))(丰|豐)收(节|節)", thaiPongal )
  , ( "欧南节", "欧南(节|節)", thiruOnam )
  , ( "圣殿被毁日", "((圣|聖)殿被毁|禁食)日", tishaBAv )
  , ( "圣三一主日", "((天主)?(圣|聖)?三一|(圣|聖)三)(主日|节|節)"
    , cycleNthAfter False TG.Day 56 easterSunday )
  , ( "十胜节", "(十(胜|勝)|(凯|凱)旋|(圣|聖)母)(节|節)"
    , cycleNthAfter False TG.Day 9 navaratri )
  -- 15th day of Shevat
  , ( "犹太植树节", "((犹|猶)太植(树|樹)|(图|圖)比舍巴特)(节|節)|(树|樹)木新年", tuBishvat )
  -- day of the full moon in May in the Gregorian calendar
  , ( "卫塞节", "((卫|衛)塞|威瑟|比(萨宝|薩寶)蕉)(节|節)", vesak )
  , ( "以色列独立日", "以色列((独|獨)立日|国庆节|國慶節)", yomHaatzmaut )
  , ( "赎罪日", "(赎|贖)罪日", cycleNthAfter False TG.Day 9 roshHashana )
  , ( "圣灵节庆日", "(圣灵节庆|聖靈節慶)日"
    , cycleNthAfter False TG.Day 50 easterSunday )

  -- Other
  , ( "老板节", "老(板节|闆節)"
    , predNthClosest 0 weekday (monthDay 10 16) )
  ]

ruleComputedHolidays' :: [Rule]
ruleComputedHolidays' = mkRuleHolidays'
  [ ( "全球青年服务日", "全球青年服(务|務)日"
    , let start = globalYouthServiceDay
          end = cycleNthAfter False TG.Day 2 globalYouthServiceDay
        in interval TTime.Open start end )
  , ( "四旬节", "四旬(节|節)"
    , let start = cycleNthAfter False TG.Day (-48) orthodoxEaster
          end = cycleNthAfter False TG.Day (-9) orthodoxEaster
        in interval TTime.Open start end )
  , ( "光明节", "(光明|修殿|(献|獻)殿|(烛|燭)光|哈努卡|(马|馬)加比)(节|節)"
    , let start = chanukah
          end = cycleNthAfter False TG.Day 7 chanukah
        in interval TTime.Open start end )
  , ( "大斋期", "大(斋|齋)(期|节|節)"
    , let start = cycleNthAfter False TG.Day (-46) easterSunday
          end = cycleNthAfter False TG.Day (-1) easterSunday
        in interval TTime.Open start end )
  , ( "九夜节", "(九夜|(难|難)近母)(节|節)"
    , let start = navaratri
          end = cycleNthAfter False TG.Day 9 navaratri
        in interval TTime.Open start end )
  , ( "逾越节", "逾越(节|節)"
    , let start = passover
          end = cycleNthAfter False TG.Day 8 passover
        in interval TTime.Open start end )
  , ( "斋月", "(穆斯林)?(斋|齋)月"
    , let start = ramadan
          end = cycleNthAfter False TG.Day (-1) eidalFitr
        in interval TTime.Open start end )
  , ( "犹太新年", "(犹|猶)太新年"
    , let start = roshHashana
          end = cycleNthAfter False TG.Day 2 roshHashana
        in interval TTime.Open start end )
  , ( "七七节", "(七七|沙夫幼特|(周|週)日|收(获|穫)|新果(实|實))(节|節)"
    , let start = cycleNthAfter False TG.Day 50 passover
          end = cycleNthAfter False TG.Day 52 passover
        in interval TTime.Open start end )
  , ( "住棚节", "住棚(节|節)"
    , let start = cycleNthAfter False TG.Day 14 roshHashana
          end = cycleNthAfter False TG.Day 22 roshHashana
        in interval TTime.Open start end )

  -- Other
  -- Last Saturday of March unless it falls on Holy Saturday
  -- In which case it's the Saturday before
  , ( "地球一小时", "地球一小(时|時)"
    , let holySaturday = cycleNthAfter False TG.Day (-1) easterSunday
          tentative = predLastOf (dayOfWeek 6) (month 3)
          alternative = cycleNthAfter False TG.Day (-7) tentative
        in do
          day <- intersectWithReplacement holySaturday tentative alternative
          start <- intersect day $ hourMinute True 20 30
          interval TTime.Closed start $ cycleNthAfter False TG.Minute 60 start )
  ]
ruleApproximate :: Rule
ruleApproximate = Rule
  { name = "<time-of-day> about (左右|上下)"
  , pattern =
--    [ Predicate $ isGrainFinerThan TG.Year
--    [ Predicate $ and . sequence [isGrainFinerThan TG.Year, hasNoDirection]
--    [ dimension Time
    [ Predicate $ and . sequence [hasNoDirection, not . isApproximate]
    , regex "(左右|上下)"
    ]
  , prod = \tokens -> case tokens of
      (Token Time td:_) -> tt $ approximate $ notLatent td
      _ -> Nothing
  }

ruleApproximate2 :: Rule
ruleApproximate2 = Rule
  { name = "(大约|差不多|大概) about <time>"
  , pattern =
    [ regex "(大约|差不多|大概)"
    , Predicate $ and . sequence [hasNoDirection, not . isApproximate]
--     , Predicate $ or . sequence [isATimeOfDay, isDOMValue, isAMonth]
    ]
  , prod = \tokens -> case tokens of
      (_:Token Time td:_) -> tt $ approximate $ notLatent td
      _ -> Nothing
  }

ruleIntervalBeforeTime :: Rule
ruleIntervalBeforeTime = Rule
  { name = "<time> before (之|以)?前"
  , pattern =
    [ Predicate $ and . sequence [hasNoDirection, not . isApproximate]
    , regex "(之|以)?前"
    ]
  , prod = \tokens -> case tokens of
      (Token Time td:_) -> tt . withDirection TTime.Before $ notLatent td
      _ -> Nothing
  }

ruleIntervalAfterTime :: Rule
ruleIntervalAfterTime = Rule
  { name = "<time> after (之|以)?后"
  , pattern =
    [ Predicate $ and . sequence [hasNoDirection, not . isApproximate]
    , regex "(之|以)?后"
    ]
  , prod = \tokens -> case tokens of
      (Token Time td:_) -> tt . withDirection TTime.After $ notLatent td
      _ -> Nothing
  }

ruleIntervalTODBetween :: Rule
ruleIntervalTODBetween = Rule
  { name = "<datetime> -到 <datetime> interval of time of day"
  , pattern =
    [ Predicate isATimeOfDay
    , regex "(到|-|~|至)"
    , Predicate isATimeOfDay
    ]
  , prod = \tokens -> case tokens of
      (Token Time td1:_:Token Time td2:_) ->
        Token Time <$> interval TTime.Closed td1 td2
      _ -> Nothing
  }

ruleIntervalDOWBetween :: Rule
ruleIntervalDOWBetween = Rule
  { name = "<dayOfWeek> -到 <dayOfWeek> interval of dayOfWeek"
  , pattern =
    [ Predicate isADayOfWeek
    , regex "(到|-|~|至)"
    , Predicate isADayOfWeek
    ]
  , prod = \tokens -> case tokens of
      (Token Time td1:_:Token Time td2:_) ->
        Token Time <$> interval TTime.Closed td1 td2
      _ -> Nothing
  }

ruleIntervalDayBetween :: Rule
ruleIntervalDayBetween = Rule
  { name = "<day> -到 <day> interval of day"
  , pattern =
    [ Predicate $ and . sequence [isNotLatent,  isGrainOfTime TG.Day]
    , regex "(到|-|~|至)"
    , Predicate $ and . sequence [isNotLatent,  isGrainOfTime TG.Day]
    ]
  , prod = \tokens -> case tokens of
      (Token Time td1:_:Token Time td2:_) ->
        Token Time <$> interval TTime.Closed td1 td2
      _ -> Nothing
  }

ruleIntervalMonthBetween :: Rule
ruleIntervalMonthBetween = Rule
  { name = "<month> -到 <month> interval of month"
  , pattern =
    [ Predicate isAMonth
    , regex "(到|-|~|至)"
    , Predicate isAMonth
    ]
  , prod = \tokens -> case tokens of
      (Token Time td1:_:Token Time td2:_) ->
        Token Time <$> interval TTime.Closed td1 td2
      _ -> Nothing
  }

ruleIntervalMonthOfYearBetween :: Rule
ruleIntervalMonthOfYearBetween = Rule
  { name = "<monthOfYear> -到 <monthOfYear> interval of monthOfYear"
  , pattern =
    [ Predicate $ and . sequence [isNotLatent,  isGrainOfTime TG.Month]
    , regex "(到|-|~|至)"
    , Predicate $ and . sequence [isNotLatent,  isGrainOfTime TG.Month]
    ]
  , prod = \tokens -> case tokens of
      (Token Time td1:_:Token Time td2:_) ->
        Token Time <$> interval TTime.Closed td1 td2
      _ -> Nothing
  }

ruleIntervalYearBetween :: Rule
ruleIntervalYearBetween = Rule
  { name = "<year> -到 <year> interval of year"
  , pattern =
    [ Predicate $ and . sequence [isNotLatent,  isGrainOfTime TG.Year]
    , regex "(到|-|~|至)"
    , Predicate $ and . sequence [isNotLatent,  isGrainOfTime TG.Year]
    ]
  , prod = \tokens -> case tokens of
      (Token Time td1:_:Token Time td2:_) ->
        Token Time <$> interval TTime.Closed td1 td2
      _ -> Nothing
  }

rules :: [Rule]
rules =
  [ ruleAbsorptionOfAfterNamedDay
  , ruleAfternoon
  , ruleDimTimePartofday
  , ruleDurationAgo
  , ruleDurationFromNow
  , ruleEveningnight
  , ruleHhmmMilitaryTimeofday
  , ruleHhmmTimeofday
  , ruleHHMMSS
  , ruleInDuration
  , ruleInduringThePartofday
  , ruleIntegerLatentTimeofday
  , ruleIntersect
  , ruleIntersectBy
  , ruleLastCycle
  , ruleLastNCycle
  , ruleNCycleLast
  , ruleDOM
  , ruleLastNight
  , ruleLastTime
  , ruleLastYear
  , ruleLastLastYear
  , ruleMidnight
  , ruleMmdd
  , ruleMmddyyyy
  , ruleMorning
  , ruleEarlyMorning
  , ruleNamedmonthDayofmonth
  , ruleNextCycle
  , ruleNextNCycle
  , ruleNCycleNext
  , ruleNextTime
  , ruleNextYear
  , ruleNextNextYear
  , ruleNoon
  , ruleNow
  , ruleNthTimeOfTime
  , ruleNthTimeOfTime2
  , rulePartofdayDimTime
  , ruleRelativeMinutesAfterpastIntegerHourofday
  , ruleRelativeMinutesAfterpastIntegerHourofdayWithMinuteUnit
  , ruleRelativeMinutesAfterpastNoonmidnight
  , ruleRelativeMinutesAfterpastNoonmidnightWithMinuteUnit
  , ruleRelativeMinutesTotillbeforeIntegerHourofday
  , ruleRelativeMinutesTotillbeforeIntegerHourofdayWithMinuteUnit
  , ruleRelativeMinutesTotillbeforeIntegerHourofdayWithMinuteUnitReversed
  , ruleRelativeMinutesTotillbeforeNoonmidnight
  , ruleRelativeMinutesTotillbeforeNoonmidnightWithMinuteUnit
  , ruleQuarterAfterpastIntegerHourofday
  , ruleThreeQuarterAfterpastIntegerHourofday
  , ruleQuarterAfterpastNoonmidnight
  , ruleQuarterTotillbeforeIntegerHourofday
  , ruleQuarterTotillbeforeNoonmidnight
  , ruleHalfAfterpastIntegerHourofday
  , ruleHalfAfterpastNoonmidnight
  , ruleHalfTotillbeforeIntegerHourofday
  , ruleHalfTotillbeforeNoonmidnight
  , ruleTheCycleAfterTime
  , ruleTheCycleBeforeTime
  , ruleTheDayAfterTomorrow
  , ruleTheDayAfterTheDayAfterTomorrow
  , ruleTheDayBeforeYesterday
  , ruleTheDayBeforeTheDayBeforeYesterday
  , ruleThisDayofweek
  , ruleThisCycle
  , ruleThisTime
  , ruleThisYear
  , ruleTimeofdayAmpm
  , ruleTimeofdayOclock
  , ruleToday
  , ruleTomorrow
  , ruleTomorrowNight
  , ruleTonight
  , ruleWeekend
  , ruleYearNumericWithYearSymbol
  , ruleYearNumericWithYearSymbol2
  , ruleYearNumericWithYearSymbol3
  , ruleYesterday
  , ruleYyyymmdd
  , ruleTimezone
  , ruleApproximate
  , ruleApproximate2
  , ruleIntervalBeforeTime
  , ruleIntervalAfterTime
  , ruleIntervalTODBetween
  , ruleIntervalDOWBetween
  , ruleIntervalDayBetween
  , ruleIntervalMonthBetween
  , ruleIntervalMonthOfYearBetween
  , ruleIntervalYearBetween
  ]
  ++ ruleDaysOfWeek
  ++ ruleMonths
  ++ ruleComputedHolidays
  ++ ruleComputedHolidays'
  ++ rulePeriodicHolidays
