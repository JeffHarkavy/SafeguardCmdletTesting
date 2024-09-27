try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

$GLOBALS.currentTest = $DATA.Tests.NewSchedules
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

# This is just to test schedule creation calls - not assigning them to anything.
# The calls just create and return a new object, they do not write anything to SPP.
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
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardSchedule"; message = "successful"; })
   }
   else {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "New-SafeguardSchedule"; message = "NOT successful"; })
   }

   $schedDaily = New-SafeguardScheduleDaily -StartTime "23:00" -TimeZone "Central Europe Standard Time"
   if ($schedDaily.StartHour -eq 23 -and `
         $schedDaily.RepeatInterval -eq 1 -and `
         $schedDaily.TimeOfDayType -eq "Instant" -and `
         $schedDaily.TimeZoneId -eq "Central Europe Standard Time" -and `
         $schedDaily.ScheduleType -eq "Daily" -and `
         $schedDaily.StartMinute -eq 0) {
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardScheduleDaily"; message = "successful"; })
   }
   else {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "New-SafeguardScheduleDaily"; message = "NOT successful"; })
   }

   $schedMonthlyByDay = New-SafeguardScheduleMonthlyByDay -DayOfMonth 1 -StartHour 22 -StartMinute 0 -TimeZone "Mountain Standard Time"
   if ($schedMonthlyByDay.StartHour -eq 22 -and `
         $schedMonthlyByDay.TimeOfDayType -eq "Instant" -and `
         $schedMonthlyByDay.RepeatMonthlyScheduleType -eq "DayOfMonth" -and `
         $schedMonthlyByDay.RepeatDayOfMonth -eq 1 -and `
         $schedMonthlyByDay.TimeZoneId -eq "Mountain Standard Time" -and `
         $schedMonthlyByDay.ScheduleType -eq "Monthly" -and `
         $schedMonthlyByDay.StartMinute -eq 0) {
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardScheduleMonthlyByDay"; message = "successful"; })
   }
   else {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "New-SafeguardScheduleMonthlyByDay"; message = "NOT successful"; })
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
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardScheduleMonthlyByDayOfWeek"; message = "successful"; })
   }
   else {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "New-SafeguardScheduleMonthlyByDayOfWeek"; message = "NOT successful"; })
   }

   $schedWeekly = New-SafeguardScheduleWeekly -RepeatDaysOfWeek Tuesday, Saturday -StartHour 23 -StartMinute 30 -TimeZone "Pacific Standard Time"
   if ($schedWeekly.StartHour -eq 23 -and `
         $schedWeekly.RepeatInterval -eq 1 -and `
         $schedWeekly.TimeOfDayType -eq "Instant" -and `
         $schedWeekly.RepeatDaysOfWeek -join " " -eq "Tuesday Saturday" -and `
         $schedWeekly.TimeZoneId -eq "Pacific Standard Time" -and `
         $schedWeekly.ScheduleType -eq "Weekly" -and `
         $schedWeekly.StartMinute -eq 30) {
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardScheduleWeekly"; message = "successful"; })
   }
   else {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "New-SafeguardScheduleWeekly"; message = "NOT successful"; })
   }

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "general"; message = "Unexpected error testing schedule creation" ; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   $GLOBALS.testBlockHeader($script:blockInfo)
}
