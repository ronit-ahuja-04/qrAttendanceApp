# Graph Report - qrAttendanceApp  (2026-08-23)

## Corpus Check
- 173 files · ~162,816 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1614 nodes · 2217 edges · 93 communities (76 shown, 17 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 34 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Windows Flutter Runner
- Faculty QR Generator UI
- Faculty Timetable Manager UI
- Student Dashboard UI
- iOS/macOS Runner
- Community 5
- Community 6
- Community 7
- Community 8
- Community 9
- Community 10
- Community 11
- Community 12
- Community 13
- Community 14
- Community 15
- Community 16
- Community 17
- Community 18
- Community 19
- Community 20
- Community 21
- Community 22
- Community 23
- Community 24
- Community 25
- Community 26
- Community 27
- Community 28
- Community 29
- Community 30
- Community 31
- Community 32
- Community 33
- Community 34
- Community 35
- Community 36
- Community 37
- Community 38
- Community 39
- Community 40
- Community 41
- Community 42
- Community 43
- Community 44
- Community 45
- Community 46
- Community 47
- Community 48
- Community 49
- Community 50
- Community 51
- Community 52
- Community 53
- Community 54
- Community 55
- Community 56
- Community 57
- Community 58
- Community 59
- Community 60
- Community 61
- Community 62
- Community 63
- Community 64
- Community 65
- Community 66
- Community 67
- Community 68
- Community 69
- Community 70
- Community 71
- Community 72
- Community 73
- Community 74
- Community 75
- Community 76
- Community 77
- Community 78
- Community 79
- Community 80
- Community 81
- Community 82
- Community 83
- Community 84
- Community 85
- Community 86
- Community 87
- Community 92

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 24 edges
2. `compilerOptions` - 16 edges
3. `MessageHandler` - 12 edges
4. `FlutterWindow` - 10 edges
5. `Create` - 10 edges
6. `WndProc` - 10 edges
7. `MessageHandler` - 9 edges
8. `_MyApplication` - 7 edges
9. `OnCreate` - 7 edges
10. `WindowClassRegistrar` - 7 edges

## Surprising Connections (you probably didn't know these)
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  app/windows/runner/main.cpp → app/windows/runner/utils.cpp
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  app/windows/runner/win32_window.cpp → app/windows/runner/win32_window.h
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  app/linux/runner/my_application.cc → app/linux/flutter/generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  app/linux/runner/main.cc → app/linux/runner/my_application.cc
- `OnCreate` --calls--> `RegisterPlugins()`  [INFERRED]
  app/windows/runner/flutter_window.h → app/windows/flutter/generated_plugin_registrant.cc

## Import Cycles
- None detected.

## Communities (93 total, 17 thin omitted)

### Community 0 - "Windows Flutter Runner"
Cohesion: 0.05
Nodes (57): RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow (+49 more)

### Community 1 - "Faculty QR Generator UI"
Cohesion: 0.04
Nodes (48): ../ams/api_services.dart, _AttendanceProgressCard, _autoRefresh, batchTarget, build, _ClassDetailsCard, _closeSession, _CloseSessionButton (+40 more)

### Community 2 - "Faculty Timetable Manager UI"
Cohesion: 0.04
Nodes (48): _AddSlotModal, _AddSlotModalState, _Badge, _batch, _batches, build, color, createState (+40 more)

### Community 3 - "Student Dashboard UI"
Cohesion: 0.04
Nodes (47): animation, _animController, child, _CircularStatCard, color, createState, dispose, _eventSub (+39 more)

### Community 4 - "iOS/macOS Runner"
Cohesion: 0.05
Nodes (32): Any, AppDelegate, Bool, SceneDelegate, RunnerTests, RegisterGeneratedPlugins(), AppDelegate, Bool (+24 more)

### Community 5 - "Community 5"
Cohesion: 0.04
Nodes (44): AttendanceMethod, AttendanceRecord, AttendanceSession, AttendanceStatus, code, copyWith, courseCode, createdAt (+36 more)

### Community 6 - "Community 6"
Cohesion: 0.05
Nodes (43): batch, course, createState, date, _DetailRow, dispose, _eventSub, _FacultyProfileBlock (+35 more)

### Community 7 - "Community 7"
Cohesion: 0.05
Nodes (40): absent, absentCount, angle, build, _checkCtrl, _checkProgress, _circleCtrl, _circleProgress (+32 more)

### Community 8 - "Community 8"
Cohesion: 0.05
Nodes (39): absent, angle, build, _checkCtrl, _checkProgress, _circleCtrl, _circleProgress, color (+31 more)

### Community 9 - "Community 9"
Cohesion: 0.05
Nodes (38): _animController, build, _buildStep, confirmController, _confirmPasswordController, controller, createState, dispose (+30 more)

### Community 10 - "Community 10"
Cohesion: 0.05
Nodes (37): _Audience, _AudiencePill, bg, _bodyController, border, _BottomAction, _broadcast, build (+29 more)

### Community 11 - "Community 11"
Cohesion: 0.06
Nodes (36): Animation, _animation, borderRadius, build, child, controller, createState, dispose (+28 more)

### Community 12 - "Community 12"
Cohesion: 0.06
Nodes (35): amberGlow, AppColors, debossedWell, error, errorContainer, getAttendanceColor, inverseOnSurface, inverseSurface (+27 more)

### Community 13 - "Community 13"
Cohesion: 0.06
Nodes (34): active, borderRadius, build, child, controller, createState, currentIndex, DebossedField (+26 more)

### Community 14 - "Community 14"
Cohesion: 0.06
Nodes (33): ApiAttendanceService, ApiSessionService, closeSession, createSession, createTimetableSlot, deleteTimetableSlot, forgotPassword, getActiveSession (+25 more)

### Community 15 - "Community 15"
Cohesion: 0.06
Nodes (33): body, build, by, byIcon, createState, _fetchData, _formatDate, _getColor (+25 more)

### Community 16 - "Community 16"
Cohesion: 0.06
Nodes (33): build, _CalendarCard, createState, day, _DayCell, _DaySession, _daysInMonth, detail (+25 more)

### Community 17 - "Community 17"
Cohesion: 0.06
Nodes (33): build, _buildOption, _confirmAndSubmit, createState, divisionLabel, _fetchVerificationList, initState, _isLoading (+25 more)

### Community 18 - "Community 18"
Cohesion: 0.06
Nodes (31): _ActiveSessionBanner, _AttendanceCard, _AttendanceEntry, AttendanceHistoryScreen, _AttendanceStatus, build, compact, _DayGroup (+23 more)

### Community 19 - "Community 19"
Cohesion: 0.06
Nodes (31): better-sqlite3, author, dependencies, better-sqlite3, cors, express, description, devDependencies (+23 more)

### Community 20 - "Community 20"
Cohesion: 0.07
Nodes (29): advanceSeconds, attendanceRepo, AttendanceService, AttendanceValidator, Clock, closeSession, createSession, _current (+21 more)

### Community 21 - "Community 21"
Cohesion: 0.07
Nodes (28): build, createState, _exportToExcel, _fetchReport, _fetchSessions, GenerateReportScreen, _GenerateReportScreenState, _Header (+20 more)

### Community 22 - "Community 22"
Cohesion: 0.08
Nodes (26): body, by, byIcon, createState, _FacNotif, FacultyNotificationsScreen, _FacultyNotificationsScreenState, _Header (+18 more)

### Community 23 - "Community 23"
Cohesion: 0.09
Nodes (22): fl_register_plugins(), main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line() (+14 more)

### Community 24 - "Community 24"
Cohesion: 0.08
Nodes (24): AndroidFlutterLocalNotificationsPlugin, connectSse, _connectWithRetry, _eventController, events, flutterLocalNotificationsPlugin, init, _initialized (+16 more)

### Community 25 - "Community 25"
Cohesion: 0.08
Nodes (24): app_colors.dart, AppTextStyles, _body, bodyLg, bodyMd, _display, displayLg, headlineMd (+16 more)

### Community 26 - "Community 26"
Cohesion: 0.09
Nodes (24): AccountSettingsScreen, _AccountSettingsScreenState, appVersion, _comingSoon, createState, department, _Header, icon (+16 more)

### Community 27 - "Community 27"
Cohesion: 0.08
Nodes (24): author, dependencies, cors, dotenv, express, multer, nodemailer, sqlite3 (+16 more)

### Community 28 - "Community 28"
Cohesion: 0.09
Nodes (22): AttendanceStatisticsScreen, attended, build, heightFraction, isLow, label, _MonthBar, _MonthlyTrendCard (+14 more)

### Community 29 - "Community 29"
Cohesion: 0.09
Nodes (19): db, sqlite3, app, cors, db, express, fs, mailer (+11 more)

### Community 30 - "Community 30"
Cohesion: 0.10
Nodes (21): build, child, color, _comingSoon, createState, _DropWell, _Header, icon (+13 more)

### Community 31 - "Community 31"
Cohesion: 0.11
Nodes (19): ../ams/globals.dart, _batch, _batches, build, _ConfigureSessionHeader, ConfigureSessionScreen, _ConfigureSessionScreenState, createState (+11 more)

### Community 32 - "Community 32"
Cohesion: 0.13
Nodes (15): db, insertUser, AttendanceMethod, AttendanceStatus, AttendanceValidator, buildAms(), Otp, reasonText (+7 more)

### Community 33 - "Community 33"
Cohesion: 0.11
Nodes (18): ../ams/models.dart, build, createState, dispose, _FieldLabel, _Header, label, onBack (+10 more)

### Community 34 - "Community 34"
Cohesion: 0.15
Nodes (18): _ActionHub, _ActionHubState, _SessionTileState, _SettingsButtonState, ForgotPasswordScreen, _ForgotPasswordScreenState, _ActionHubState, _SessionTileState (+10 more)

### Community 35 - "Community 35"
Cohesion: 0.11
Nodes (17): createState, FacultyProfileScreen, _Header, icon, _IdBadgeCard, _InfoField, _isHovering, label (+9 more)

### Community 36 - "Community 36"
Cohesion: 0.12
Nodes (17): _agreedToTerms, build, _confirmController, createState, dispose, _emailController, _formKey, _goToLogin (+9 more)

### Community 37 - "Community 37"
Cohesion: 0.12
Nodes (16): account_settings_screen.dart, _ContactWell, _DigitalIdCard, _Header, icon, _InfoField, label, _logout (+8 more)

### Community 38 - "Community 38"
Cohesion: 0.12
Nodes (16): build, ChangePasswordScreen, _ChangePasswordScreenState, _confirmController, createState, _currentController, dispose, _formKey (+8 more)

### Community 39 - "Community 39"
Cohesion: 0.12
Nodes (16): createState, dispose, _emailController, _formKey, _handleSignIn, _isLoading, LoginScreen, _LoginScreenState (+8 more)

### Community 40 - "Community 40"
Cohesion: 0.12
Nodes (16): build, _continueToTimeline, createState, _division, _divisions, onBack, _ProgressDots, _ReportFiltersHeader (+8 more)

### Community 41 - "Community 41"
Cohesion: 0.24
Nodes (6): failure(), isOtpExpired(), nextId(), SessionRepository, SessionService, success()

### Community 42 - "Community 42"
Cohesion: 0.12
Nodes (16): compilerOptions, declaration, declarationMap, exactOptionalPropertyTypes, isolatedModules, jsx, module, moduleDetection (+8 more)

### Community 43 - "Community 43"
Cohesion: 0.12
Nodes (15): api_services.dart, activeSessionId, AmsGlobals, attendanceService, formatStudentName, getBatchColor, loggedInUser, sessionService (+7 more)

### Community 44 - "Community 44"
Cohesion: 0.13
Nodes (15): _onTap, build, _openCalendarFilter, _switchSession, _generateQr, build, _showSessionDetails, build (+7 more)

### Community 45 - "Community 45"
Cohesion: 0.13
Nodes (14): AttendanceRepository, exists, findAll, findById, findBySession, InMemoryAttendanceRepository, InMemorySessionRepository, save (+6 more)

### Community 46 - "Community 46"
Cohesion: 0.14
Nodes (14): build, createState, onBack, onTap, ReportTimeline, _ReportTimelineHeader, ReportTimelineScreen, _ReportTimelineScreenState (+6 more)

### Community 47 - "Community 47"
Cohesion: 0.14
Nodes (13): ../ams/notification_service.dart, AttendancePortalApp, build, main, navigatorKey, _VesitPageTransition, GlobalKey, NavigatorState (+5 more)

### Community 48 - "Community 48"
Cohesion: 0.14
Nodes (14): _ActionHub, FacultyDashboardScreen, _FacultyDashboardScreenState, _ProfileAvatar, _ProfileAvatarState, _SessionTile, _SidebarMenuItem, _SidebarMenuItemState (+6 more)

### Community 49 - "Community 49"
Cohesion: 0.15
Nodes (13): DottedBorder, _Footer, ConfigCard, DebossedDropdown, DebossedWell, LedDot, PilotLight, RaisedPanel (+5 more)

### Community 50 - "Community 50"
Cohesion: 0.24
Nodes (9): wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16(), _In_, _In_opt_ (+1 more)

### Community 51 - "Community 51"
Cohesion: 0.18
Nodes (10): AnimationController, build, _controller, createState, dispose, _icons, initState, size (+2 more)

### Community 52 - "Community 52"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 53 - "Community 53"
Cohesion: 0.18
Nodes (3): AttendanceRepository, AttendanceService, InMemoryAttendanceRepository

### Community 54 - "Community 54"
Cohesion: 0.22
Nodes (9): code, crypto, db, fs, getCoreBatch(), match, processStudents(), sqlite3 (+1 more)

### Community 55 - "Community 55"
Cohesion: 0.29
Nodes (7): crypto, db, fs, getCoreBatch(), processStudents(), sqlite3, students

### Community 56 - "Community 56"
Cohesion: 0.25
Nodes (3): Clock, MutableClock, SystemClock

### Community 57 - "Community 57"
Cohesion: 0.33
Nodes (5): FadeBlurPageRoute, page, dart:ui, PageRouteBuilder, Widget

### Community 58 - "Community 58"
Cohesion: 0.33
Nodes (6): _ConfettiPainter, _SuccessPainter, _ConfettiPainter, _SuccessPainter, _DashedRectPainter, CustomPainter

### Community 59 - "Community 59"
Cohesion: 0.33
Nodes (4): getIconForSubject, SubjectIcons, main, package:flutter/material.dart

### Community 62 - "Community 62"
Cohesion: 0.40
Nodes (5): AttendanceSubmittedScreen, _AttendanceSubmittedScreenState, StudentAttendanceSuccessScreen, _StudentAttendanceSuccessScreenState, TickerProviderStateMixin

### Community 63 - "Community 63"
Cohesion: 0.40
Nodes (4): db, dbPath, path, sqlite3

### Community 64 - "Community 64"
Cohesion: 0.40
Nodes (4): db, dbPath, path, sqlite3

### Community 65 - "Community 65"
Cohesion: 0.40
Nodes (4): code, endIndex, fs, insertPos

### Community 66 - "Community 66"
Cohesion: 0.40
Nodes (4): crypto, db, sqlite3, timetableData

### Community 67 - "Community 67"
Cohesion: 0.40
Nodes (4): crypto, db, sqlite3, timetableData

### Community 68 - "Community 68"
Cohesion: 0.40
Nodes (3): fs, path, replacements

### Community 70 - "Community 70"
Cohesion: 0.50
Nodes (3): json, main, dart:convert

### Community 71 - "Community 71"
Cohesion: 0.50
Nodes (3): db, migrations, sqlite3

### Community 72 - "Community 72"
Cohesion: 0.50
Nodes (3): content, fs, timeMap

### Community 73 - "Community 73"
Cohesion: 0.50
Nodes (3): content, fs, timeMap

### Community 76 - "Community 76"
Cohesion: 0.67
Nodes (3): MutableClock, SystemClock, Clock

## Knowledge Gaps
- **957 isolated node(s):** `ApiSessionService`, `ApiAttendanceService`, `getTimetable`, `getStudentTimetableToday`, `createTimetableSlot` (+952 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **17 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FlutterWindow` connect `Windows Flutter Runner` to `iOS/macOS Runner`?**
  _High betweenness centrality (0.005) - this node is a cross-community bridge._
- **What connects `ApiSessionService`, `ApiAttendanceService`, `getTimetable` to the rest of the system?**
  _957 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Windows Flutter Runner` be split into smaller, more focused modules?**
  _Cohesion score 0.05311676909569798 - nodes in this community are weakly interconnected._
- **Should `Faculty QR Generator UI` be split into smaller, more focused modules?**
  _Cohesion score 0.04251700680272109 - nodes in this community are weakly interconnected._
- **Should `Faculty Timetable Manager UI` be split into smaller, more focused modules?**
  _Cohesion score 0.04251700680272109 - nodes in this community are weakly interconnected._
- **Should `Student Dashboard UI` be split into smaller, more focused modules?**
  _Cohesion score 0.041666666666666664 - nodes in this community are weakly interconnected._
- **Should `iOS/macOS Runner` be split into smaller, more focused modules?**
  _Cohesion score 0.05217391304347826 - nodes in this community are weakly interconnected._