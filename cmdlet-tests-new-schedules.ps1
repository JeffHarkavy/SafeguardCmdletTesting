try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName ="Running New Schedule Creation Tests"
$blockInfo = testBlockHeader "begin" $TestBlockName
# ===== Covered Commands =====
# New-SafeguardSchedule
# New-SafeguardScheduleDaily
# New-SafeguardScheduleMonthlyByDay
# New-SafeguardScheduleMonthlyByDayOfWeek
# New-SafeguardScheduleWeekly
#
# This is just to test schedule creation calls - not assigning them to anything
try {
   $schedPlain = New-SafeguardSchedule -MonthsByDayOfWeek -ScheduleInterval 6 -WeekOfMonth Last -DayOfWeekOfMonth Saturday -StartHour 1 -StartMinute 30 -TimeZone "Eastern Standard Time"
   if ($schedPlain.StartHour -eq 1 -and `
         $schedPlain.RepeatInterval -eq 6 -and `
         $schedPlain.TimeOfDayType -eq "Instant" -and `
         $schedPlain.RepeatMonthlyScheduleType -eq "DayOfWeekOfMonth" -and `
         $schedPlain.RepeatDayOfWeek -eq "Saturday" -and `
         $schedPlain.RepeatWeekOfMonth -eq "Last" -and `
         $schedPlain.TimeZoneId -eq "Eastern Standard Time" -and `
         $schedPlain.ScheduleType -eq "Monthly" -and `
         $schedPlain.StartMinute -eq 30) {
      goodResult "New-SafeguardSchedule"  "successful"
   }
   else {
      badResult "New-SafeguardSchedule"  "NOT successful"
   }

   $schedDaily = New-SafeguardScheduleDaily -StartTime "23:00" -TimeZone "Central Europe Standard Time"
   if ($schedDaily.StartHour -eq 23 -and `
         $schedDaily.RepeatInterval -eq 1 -and `
         $schedDaily.TimeOfDayType -eq "Instant" -and `
         $schedDaily.TimeZoneId -eq "Central Europe Standard Time" -and `
         $schedDaily.ScheduleType -eq "Daily" -and `
         $schedDaily.StartMinute -eq 0) {
      goodResult "New-SafeguardScheduleDaily"  "successful"
   }
   else {
      badResult "New-SafeguardScheduleDaily"  "NOT successful"
   }

   $schedMonthlyByDay = New-SafeguardScheduleMonthlyByDay -DayOfMonth 1 -StartHour 22 -StartMinute 0 -TimeZone "Mountain Standard Time"
   if ($schedMonthlyByDay.StartHour -eq 22 -and `
         $schedMonthlyByDay.TimeOfDayType -eq "Instant" -and `
         $schedMonthlyByDay.RepeatMonthlyScheduleType -eq "DayOfMonth" -and `
         $schedMonthlyByDay.RepeatDayOfMonth -eq 1 -and `
         $schedMonthlyByDay.TimeZoneId -eq "Mountain Standard Time" -and `
         $schedMonthlyByDay.ScheduleType -eq "Monthly" -and `
         $schedMonthlyByDay.StartMinute -eq 0) {
      goodResult "New-SafeguardScheduleMonthlyByDay"  "successful"
   }
   else {
      badResult "New-SafeguardScheduleMonthlyByDay"  "NOT successful"
   }

   $schedMonthlyByDayOfWeek = New-SafeguardScheduleMonthlyByDayOfWeek -WeekOfMonth First -DayOfWeekOfMonth Sunday -StartTime "5:00" -TimeZone "Pacific Standard Time"
   if ($schedMonthlyByDayOfWeek.StartHour -eq 5 -and `
         $schedMonthlyByDayOfWeek.RepeatInterval -eq 1 -and `
         $schedMonthlyByDayOfWeek.TimeOfDayType -eq "Instant" -and `
         $schedMonthlyByDayOfWeek.RepeatMonthlyScheduleType -eq "DayOfWeekOfMonth" -and `
         $schedMonthlyByDayOfWeek.RepeatDayOfWeek -eq "Sunday" -and `
         $schedMonthlyByDayOfWeek.RepeatWeekOfMonth -eq "First" -and `
         $schedMonthlyByDayOfWeek.TimeZoneId -eq "Pacific Standard Time" -and `
         $schedMonthlyByDayOfWeek.ScheduleType -eq "Monthly" -and `
         $schedMonthlyByDayOfWeek.StartMinute -eq 0) {
      goodResult "New-SafeguardScheduleMonthlyByDayOfWeek"  "successful"
   }
   else {
      badResult "New-SafeguardScheduleMonthlyByDayOfWeek"  "NOT successful"
   }

   $schedWeekly = New-SafeguardScheduleWeekly -RepeatDaysOfWeek Tuesday, Saturday -StartHour 23 -StartMinute 30 -TimeZone "Pacific Standard Time"
   if ($schedWeekly.StartHour -eq 23 -and `
         $schedWeekly.RepeatInterval -eq 1 -and `
         $schedWeekly.TimeOfDayType -eq "Instant" -and `
         $schedWeekly.RepeatDaysOfWeek -join " " -eq "Tuesday Saturday" -and `
         $schedWeekly.TimeZoneId -eq "Pacific Standard Time" -and `
         $schedWeekly.ScheduleType -eq "Weekly" -and `
         $schedWeekly.StartMinute -eq 30) {
      goodResult "New-SafeguardScheduleWeekly"  "successful"
   }
   else {
      badResult "New-SafeguardScheduleWeekly"  "NOT successful"
   }
}
catch {
   badResult "general" "Unexpected error testing schedule creation"  $_.Exception
}

testBlockHeader "end" $TestBlockName $blockInfo
