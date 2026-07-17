@echo off
rem ============================================================
rem GameCheck Detector - downloadcomputergames.net
rem يقرأ مواصفات جهازك الحقيقية من ويندوز ويفتح صفحة الفحص
rem والمواصفات جاهزة تلقائياً (لا يرسل أي بيانات لأي مكان آخر)
rem ============================================================
title GameCheck - fahs gehazak
echo.
echo    Jari qera'at mowasafat gehazak...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$cpu=(Get-CimInstance Win32_Processor|Select-Object -First 1).Name.Trim();$gpu=(Get-CimInstance Win32_VideoController|Where-Object{$_.Name -notmatch 'Basic|Remote'}|Sort-Object -Property @{E={[int64]$_.AdapterRAM}} -Descending|Select-Object -First 1).Name;$ram=[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB);$free=[math]::Round((Get-PSDrive C).Free/1GB);$cores=(Get-CimInstance Win32_Processor|Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum;$j=@{cpu=$cpu;gpu=$gpu;ram=$ram;storage=$free;cores=$cores}|ConvertTo-Json -Compress;$b=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($j)).Replace('+','-').Replace('/','_').TrimEnd('=');Start-Process ('https://www.downloadcomputergames.net/p/gamecheck.html?spec='+$b)"
echo    Tamam! Et-fatahet safhet el-fahs fel motasafeh.
timeout /t 4 >nul
