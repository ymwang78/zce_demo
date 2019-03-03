--
-- Author: yuanjc
-- Date: 2018/11/05
--

--将日期格式 2015-10-29 18:00:00 转换为时间戳
--返回 时间戳

timeutils = timeutils or {}

--2016-02-22T00:00:00
function timeutils.datestr_to_timestamp(str)
    local year, month, day, hour, min, sec = str:match("([^-]+)-([^-]+)-([^T]+)T([^:]+):([^:]+):([^:]+)")
    return os.time({year = year, month = month, day = day, hour = hour, min = min, sec = sec})
end

--2016-02-22 00:00:00
function timeutils.datestr_to_timestamp_ex(str)
    local year, month, day, hour, min, sec = str:match("([^-]+)-([^-]+)-([^T]+) ([^:]+):([^:]+):([^:]+)")
    return os.time({year = year, month = month, day = day, hour = hour, min = min, sec = sec})
end

function timeutils.timestamp_to_datestr(timestamp)
    local date = os.date("*t", timestamp)
    return string.format('%d-%02d-%02d %02d:%02d:%02d', date.year, date.month, date.day, date.hour, date.min, date.sec)
end
--判读是否是同一天
function timeutils.is_same_day_ex(datastr, nowstr)
    local year1, month1, day1, hour1, min1, sec1 = datastr:match("([^-]+)-([^-]+)-([^T]+) ([^:]+):([^:]+):([^:]+)")
    local year2, month2, day2, hour2, min2, sec2
    if(nowstr) then
        year2, month2, day2, hour2, min2, sec2 = nowstr:match("([^-]+)-([^-]+)-([^T]+) ([^:]+):([^:]+):([^:]+)")
    else
        local date = os.date("*t", os.time())
        year2, month2, day2, hour2, min2, sec2 = date.year, date.month, date.day, date.hour, date.min, date.sec
    end
    LOG_DEBUG("year1:" .. year1 .. "month1:" .. month1 .. "day1:" .. day1 .. "hour1:" .. hour1 .. "min1:" .. min1 .. "sec1:" .. sec1)
    LOG_DEBUG("year2:" .. year2 .. "month2:" .. month2 .. "day2:" .. day2 .. "hour2:" .. hour2 .. "min2:" .. min2 .. "sec2:" .. sec2)
    if(tonumber(year1) ~= tonumber(year2)) then
        return false
    end
    if(tonumber(month1) ~= tonumber(month2)) then
        return false
    end
    if(tonumber(day1) ~= tonumber(day2)) then
        return false
    end
    return true
end

--判读是否是同一天
function timeutils.is_same_day(timestamp1, timestamp2)
    local datastr = timeutils.timestamp_to_datestr(timestamp1)
    local year1, month1, day1, hour1, min1, sec1 = datastr:match("([^-]+)-([^-]+)-([^T]+) ([^:]+):([^:]+):([^:]+)")
    local year2, month2, day2, hour2, min2, sec2
    if(timestamp2) then
        local nowstr = timeutils.timestamp_to_datestr(timestamp2)
        year2, month2, day2, hour2, min2, sec2 = nowstr:match("([^-]+)-([^-]+)-([^T]+) ([^:]+):([^:]+):([^:]+)")
    else
        local date = os.date("*t", os.time())
        year2, month2, day2, hour2, min2, sec2 = date.year, date.month, date.day, date.hour, date.min, date.sec
    end
    LOG_DEBUG("year1:" .. year1 .. "month1:" .. month1 .. "day1:" .. day1 .. "hour1:" .. hour1 .. "min1:" .. min1 .. "sec1:" .. sec1)
    LOG_DEBUG("year2:" .. year2 .. "month2:" .. month2 .. "day2:" .. day2 .. "hour2:" .. hour2 .. "min2:" .. min2 .. "sec2:" .. sec2)
    if(tonumber(year1) ~= tonumber(year2)) then
        return false
    end
    if(tonumber(month1) ~= tonumber(month2)) then
        return false
    end
    if(tonumber(day1) ~= tonumber(day2)) then
        return false
    end
    return true
end
function timeutils.cault_left_time(start_time, duration)
    if(start_time == nil) then
        return 0
    end
    local end_time = timeutils.datestr_to_timestamp_ex(start_time) + tonumber(duration)
    local cur_time = os.time()
    local left = end_time - cur_time
    if left < 0 then left = 0 end
    return left
end

--获取指定时间当天的开始时间
function timeutils.daytime_start(timestamp)
    local tab = os.date("*t", timestamp)
    tab.hour = 0
    tab.min = 0
    tab.sec = 0
    local result = os.time(tab)
    return result
end

--获取指定时间当天的结束时间
function timeutils.daytime_end(timestamp)
    local tab = os.date("*t", timestamp)
    tab.hour = 0
    tab.min = 0
    tab.sec = 0
    local result = tonumber(os.time(tab) + 86400)
    return result
end

--获取当天某事件的时间戳
function timeutils.getcurday_time(second)
    local tab = os.date("*t", time)
    tab.hour = 0
    tab.min = 0
    tab.sec = 0
    local result = tonumber(os.time(tab) + second)
    return result
end

--判断是否在时间段内
function timeutils.bround(start_time, end_time, now)
    if(not now) then
        now = os.time()
    end
    local start_strap = timeutils.getcurday_time(start_time)
    local end_strap = timeutils.getcurday_time(end_time)
    if(start_strap <= now and end_strap >= now) then
        return true
    else
        return false
    end
end

