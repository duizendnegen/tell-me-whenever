require 'date'
require 'active_support'
require 'active_support/core_ext/date'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/integer/time'

class TellMeWhen
  def self.parse(str)
    str = str.downcase
    target = nil

    # figure out whether an exact date was used
    # match against months
    months = { "january" => 1,
      "february" => 2,
      "march" => 3,
      "april" => 4,
      "may" => 5,
      "june" => 6,
      "july" => 7,
      "august" => 8,
      "september" => 9,
      "october" => 10,
      "november" => 11,
      "december" => 12}

    targetMonth = 0
    months.each do |key, value|
      if str.include? key then
        targetMonth = value
      end
    end

    # match against weekdays
    weekdays = { "monday" => 1,
      "tuesday" => 2,
      "wednesday" => 3,
      "thursday" => 4,
      "friday" => 5,
      "saturday" => 6,
      "sunday" => 7}
    targetWeekday = 0
    weekdays.each do |key, value|
      if str.include? key then
        targetWeekday = value
      end
    end

    # match against date offset
    units = ["year", "month", "week", "day", "hour"]
    targetUnits = []
    units.each do |unit|
      if str.include? unit then
        targetUnits.push unit
      end
    end

    if targetMonth != 0 then
      target = DateTime.now.beginning_of_day.change({ month: targetMonth, day: 1, hour: 9 })

      # find out whether a specific day was specified
      str.scan(/\d+/).map(&:to_i).sort.reverse.each do |day|
        # is this date within this month?
        if target.end_of_month.day >= day
          target = target.change({day: day})
          break
        end
      end
    elsif targetWeekday != 0 then
      target = DateTime.now.beginning_of_day.change({ hour: 9 })

      # falls within this week or next week?
      if target.monday.next_day(targetWeekday - 1) < target then
        target = target.next_week.next_day(targetWeekday - 1).change({hour: 9})
      else
        target = target.monday.next_day(targetWeekday - 1).change({hour: 9})
      end
    elsif targetUnits.length > 0 then
      target = DateTime.now

      if(!targetUnits.include?("hour") && !targetUnits.include?("day")) then
        target = target.change({hour: 9})
      end

      # try to find all applicable quantifiers in the str string
      targetUnits.each do |unit|
        magnitude = 1
        first = str.slice(0, str.index(unit)).scan(/\d+/).map(&:to_i).reverse.first
        if first != nil then
          magnitude = first
        end

        # TODO flag special cases on magnitude limitations
        if unit == "year" then
          if magnitude > 100 then
            magnitude = 100
          end
          target = target + magnitude.years
        elsif unit == "month" then
          if magnitude > 1200 then
            magnitude = 1200
          end
          target = target + magnitude.months
        elsif unit == "week" then
          if magnitude > 63600 then
            magnitude = 63600
          end
          target = target + magnitude.weeks
        elsif unit == "day" then
          if magnitude > 100000 then
            magnitude = 100000
          end
          target = target + magnitude.days
        elsif unit == "hour" then
          if magnitude > 100000 then
            magnitude = 100000
          end
          target = target + magnitude.hours
        end
      end
    elsif str.include?("tomorrow") then
      target = DateTime.now.beginning_of_day.change({ hour: 9 }) + 1.days
    end

    return target
  end
end
