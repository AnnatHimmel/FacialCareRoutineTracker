import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/l10n/generated/app_localizations.dart';
import '../../domain/services/streak_calculator.dart';
import '../../shared/providers/root_providers.dart';

// ── Public widget ──────────────────────────────────────────────────────────────

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, this.onContinue});
  final VoidCallback? onContinue;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

// ── State ──────────────────────────────────────────────────────────────────────

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _entranceCtrl;
  late AnimationController _flickerCtrl;
  late AnimationController _haloCtrl;
  late AnimationController _blobCtrl;
  late AnimationController _sunburstCtrl;
  late AnimationController _countdownCtrl;
  late AnimationController _confettiCtrl;
  late AnimationController _countUpCtrl;

  // Timer state
  Timer? _timer;
  Timer? _countdownTicker;
  int _secsLeft = 5;


  // Confetti
  bool _particlesInitialized = false;
  List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _flickerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _haloCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _blobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat();

    _sunburstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 18000),
    )..repeat();

    _countdownCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
      lowerBound: 0,
      upperBound: 1,
    )..forward();

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..forward();

    _countUpCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();

    // Start flicker after 1 second delay, then loop
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _flickerCtrl.repeat();
    });

    // Auto-dismiss after 5 seconds
    _timer = Timer(const Duration(seconds: 5), _onContinue);

    // Countdown ticker
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _secsLeft = (_secsLeft - 1).clamp(0, 5);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTicker?.cancel();
    _entranceCtrl.dispose();
    _flickerCtrl.dispose();
    _haloCtrl.dispose();
    _blobCtrl.dispose();
    _sunburstCtrl.dispose();
    _countdownCtrl.dispose();
    _confettiCtrl.dispose();
    _countUpCtrl.dispose();
    super.dispose();
  }

  void _onContinue() {
    _timer?.cancel();
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      if (mounted) context.go('/today');
    }
  }

  void _initParticles(Size screenSize) {
    if (_particlesInitialized) return;
    _particlesInitialized = true;
    final rng = math.Random(42);
    const colors = [
      Color(0xFFFFB4A4),
      Color(0xFFF06B50),
      Colors.white,
      Color(0xFFF0E585),
      Color(0xFFDE99A4),
      Color(0xFFFFD9DE),
      Color(0xFFD3C96C),
    ];
    _particles = [];
    // First 80: burst from center (cx, H*0.36); velocities in px/frame.
    for (int i = 0; i < 80; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final speed = 3.0 + rng.nextDouble() * 7.5;
      _particles.add(_Particle(
        cx: screenSize.width / 2,
        cy: screenSize.height * 0.36,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 3,
        wobble: rng.nextDouble() * math.pi * 2,
        size: 5.0 + rng.nextDouble() * 7,
        color: colors[rng.nextInt(colors.length)],
        isCircle: rng.nextDouble() < 0.45,
        rot: rng.nextDouble() * math.pi,
        vr: (rng.nextDouble() - 0.5) * 0.3,
      ));
    }
    // Last 60: fall from above the screen.
    for (int i = 0; i < 60; i++) {
      _particles.add(_Particle(
        cx: rng.nextDouble() * screenSize.width,
        cy: -20 - rng.nextDouble() * screenSize.height * 0.5,
        vx: (rng.nextDouble() - 0.5) * 1.5,
        vy: 1.5 + rng.nextDouble() * 2.5,
        wobble: rng.nextDouble() * math.pi * 2,
        size: 5.0 + rng.nextDouble() * 7,
        color: colors[rng.nextInt(colors.length)],
        isCircle: rng.nextDouble() < 0.45,
        rot: rng.nextDouble() * math.pi,
        vr: (rng.nextDouble() - 0.5) * 0.3,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    _initParticles(MediaQuery.of(context).size);

    final dayRecordsAsync = ref.watch(allDayRecordsProvider);
    final userNameAsync = ref.watch(userNameProvider);
    final streakCalc = ref.read(streakCalculatorProvider);
    final boundary = ref.read(dayBoundaryServiceProvider);
    final l10n = AppLocalizations.of(context)!;


    // Compute streak data
    final streakResult = dayRecordsAsync.when(
      data: (records) => streakCalc.compute(
        allRecords: records,
        asOf: DateTime.now(),
        boundary: boundary,
      ),
      loading: () => const StreakResult(
        currentStreak: 0,
        longestStreak: 0,
        missesThisWeek: 0,
      ),
      error: (e, s) => const StreakResult(
        currentStreak: 0,
        longestStreak: 0,
        missesThisWeek: 0,
      ),
    );

    final streak = streakResult.currentStreak;
    final best = streakResult.longestStreak;
    final graceLeft = (3 - streakResult.missesThisWeek).clamp(0, 3);

    final userName = userNameAsync.when(
      data: (n) => n,
      loading: () => null,
      error: (e, s) => null,
    );
    final firstName = userName?.trim().split(' ').first ?? '';

    final weekday = DateFormat.EEEE(
      Localizations.localeOf(context).toString(),
    ).format(DateTime.now());

    final screenH = MediaQuery.of(context).size.height;
    final topPad = (screenH * 0.07).clamp(28.0, 56.0);
    final botPad = (screenH * 0.05).clamp(24.0, 40.0);
    final msgMargin = (screenH * 0.035).clamp(16.0, 28.0);
    // Hero height tracks the streak number's font (same formula as
    // _CountUpNumber) so the digit always fits with breathing room.
    final numberFs = (MediaQuery.of(context).size.width * 0.26).clamp(96.0, 132.0);
    final heroH = numberFs + 20;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) => _onContinue(),
        child: Stack(
          children: [
            // 1. Base — diagonal linear gradient (160deg approximation)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.64, -1.0),
                  end: Alignment(0.64, 1.0),
                  colors: [Color(0xFFFF9E85), Color(0xFFF57A5C), Color(0xFFE05A3A)],
                  stops: [0.0, 0.52, 1.0],
                ),
              ),
            ),
            // 2. Radial top bloom overlay — large, centered at top (50% -10%)
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -1.0),
                  radius: 1.25,
                  colors: [Color(0xFFFFC8B2), Colors.transparent],
                  stops: [0.0, 0.58],
                ),
              ),
            ),
            // 3. Blob 1 (top-right)
            Positioned(
              top: -70,
              right: -70,
              child: _blob(260, const Color(0x73FFE0B4), _blobCtrl, false),
            ),
            // 4. Blob 2 (bottom-left)
            Positioned(
              bottom: -60,
              left: -60,
              child: _blob(230, const Color(0x80DE795E), _blobCtrl, true),
            ),
            // 5. Confetti canvas
            IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(_confettiCtrl, _particles),
                size: Size.infinite,
              ),
            ),
            // 6. Main content — bounded Column; two Spacers reproduce the
            // CSS auto-margins (hero margin-top:auto, stats margin-top:auto).
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(30, topPad, 30, botPad),
                child: Column(
                  children: [
                    // ── TOP: brand lockup ───────────────────────────────
                    _EntranceFade(
                      ctrl: _entranceCtrl,
                      start: 0.03,
                      end: 0.50,
                      // CSS white-space:nowrap — never wraps; scale down if the
                      // wordmark would exceed the available width.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.welcomeAppName,
                              maxLines: 1,
                              softWrap: false,
                              style: GoogleFonts.quicksand(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(color: Color(0x80961028), blurRadius: 22, offset: Offset(0, 4)),
                                  Shadow(color: Color(0x73961028), blurRadius: 8, offset: Offset(0, 2)),
                                  Shadow(color: Color(0x8C781E0C), blurRadius: 2, offset: Offset(0, 1)),
                                  Shadow(color: Color(0x99FFA080), blurRadius: 16, offset: Offset(0, 2)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 9),
                            Image.asset(
                              'assets/images/app_icon_no_bg.png',
                              width: 36,
                              height: 36,
                              errorBuilder: (ctx, err, trace) =>
                                  const SizedBox(width: 36, height: 36),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Greeting
                    _EntranceFade(
                      ctrl: _entranceCtrl,
                      start: 0.14,
                      end: 0.50,
                      child: Text(
                        l10n.welcomeGreeting(firstName, weekday),
                        style: GoogleFonts.quicksand(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // CSS: "margin: auto 0 0" on hero = Spacer above hero
                    const Spacer(),
                    // ── HERO — the streak number sits concentrically inside
                    // the sun / halo / ripple-rings. Fixed height so the glow
                    // can overflow (Clip.none) without disturbing the layout.
                    SizedBox(
                      height: heroH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Rays — 280px * scale(.6) = 168px visual
                          _SunburstWidget(_sunburstCtrl, _entranceCtrl),
                          // Halo — 220px radial glow
                          _HaloWidget(_haloCtrl),
                          // Ripple rings — base 150px → 300px
                          _RippleRing(_entranceCtrl, 0.14),
                          _RippleRing(_entranceCtrl, 0.39),
                          // numwrap — flame + count, gap 6
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FlameWidget(_flickerCtrl, _entranceCtrl),
                              const SizedBox(width: 6),
                              _CountUpNumber(
                                streak: streak,
                                countUpCtrl: _countUpCtrl,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // days "ימים ברצף" — margin-top 6
                    const SizedBox(height: 6),
                    _EntranceFade(
                      ctrl: _entranceCtrl,
                      start: 0.39,
                      end: 0.75,
                      child: Text(
                        l10n.welcomeStreakLabel,
                        style: GoogleFonts.quicksand(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xF5FFFFFF),
                        ),
                      ),
                    ),
                    // ── MESSAGE — CSS max-width 300px ───────────────────
                    SizedBox(height: msgMargin),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _EntranceFade(
                            ctrl: _entranceCtrl,
                            start: 0.50,
                            end: 1.00,
                            child: Text(
                              _headline(l10n, streak),
                              style: GoogleFonts.quicksand(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 7),
                          _EntranceFade(
                            ctrl: _entranceCtrl,
                            start: 0.57,
                            end: 1.00,
                            child: Text(
                              _subline(l10n, streak),
                              style: GoogleFonts.quicksand(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xE0FFFFFF),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // CSS: "margin-top: auto" on stats = Spacer above stats
                    const Spacer(),
                    // ── STATS — wider banner so the full grace sentence fits.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: _EntranceFade(
                      ctrl: _entranceCtrl,
                      start: 0.68,
                      end: 1.00,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0x24FFFFFF),
                          border: Border.all(color: const Color(0x38FFFFFF)),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              // First child = personal best (RIGHT in RTL)
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _statIconCircle(Icons.emoji_events, filled: true),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            l10n.welcomeDaysCount(best),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.quicksand(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              height: 1.1,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            l10n.welcomePersonalBestLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.quicksand(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              height: 1.2,
                                              color: const Color(0xD0FFFFFF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, color: const Color(0x38FFFFFF)),
                              const SizedBox(width: 12),
                              // Second child = grace (LEFT in RTL). Just the 3
                              // hearts + the full label (no big heart circle).
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Semantics(
                                      label: l10n.welcomeGraceMissedCount(3 - graceLeft),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          for (int i = 0; i < 3; i++)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 3),
                                              child: Container(
                                                width: 16, height: 16,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: i < graceLeft ? Colors.white : const Color(0x24FFFFFF),
                                                  border: i < graceLeft ? null : Border.all(color: const Color(0x4DFFFFFF)),
                                                ),
                                                child: Icon(
                                                  i < graceLeft ? Icons.favorite : Icons.favorite_border,
                                                  size: 10,
                                                  color: i < graceLeft ? const Color(0xFFF06B50) : const Color(0x8DFFFFFF),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.welcomeGraceLabel(graceLeft),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.quicksand(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        height: 1.25,
                                        color: const Color(0xD0FFFFFF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ),
                    // ── FOOTER — CSS width 100%, max-width 340px ────────
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: _EntranceFade(
                      ctrl: _entranceCtrl,
                      start: 0.75,
                      end: 1.00,
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _onContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFC8482F),
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                elevation: 12,
                                shadowColor: const Color(0x99781E0C),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      l10n.welcomeCta,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.quicksand(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFC8482F),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // textDirection.ltr suppresses RTL auto-mirror
                                  // so the arrow keeps pointing left (like the reference).
                                  const Icon(
                                    Icons.arrow_back,
                                    size: 20,
                                    color: Color(0xFFC8482F),
                                    textDirection: TextDirection.ltr,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            key: const Key('welcome_countdown'),
                            onTap: _onContinue,
                            child: SizedBox(
                              width: 56, height: 56,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0x28FFFFFF),
                                    ),
                                  ),
                                  AnimatedBuilder(
                                    animation: _countdownCtrl,
                                    builder: (ctx, child) => CustomPaint(
                                      painter: _CountdownRingPainter(_countdownCtrl),
                                      size: const Size(52, 52),
                                    ),
                                  ),
                                  Text(
                                    _secsLeft.toString(),
                                    style: GoogleFonts.quicksand(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                    const SizedBox(height: 10),
                    // Hint text
                    _EntranceFade(
                      ctrl: _entranceCtrl,
                      start: 0.84,
                      end: 1.00,
                      child: Text(
                        l10n.welcomeHint,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xC7FFFFFF),
                        ),
                      ),
                    ),
                  ], // Column children
                ), // Column
              ), // Padding
            ), // SafeArea
          ],
        ),
      ),
    );
  }

  Widget _blob(
    double size,
    Color color,
    AnimationController ctrl,
    bool reverse,
  ) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (ctx, child) {
          final t = ctrl.value * 2 * math.pi;
          final dx = (reverse ? -1 : 1) * 14 * math.sin(t);
          final dy = (reverse ? -1 : 1) * 18 * math.sin(t + math.pi / 2);
          final scale = 1.0 + 0.08 * math.sin(t);
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.scale(
              scale: scale,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 38, sigmaY: 38, tileMode: TileMode.decal),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statIconCircle(IconData icon, {bool filled = false}) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xEAFFFFFF),
      ),
      child: Icon(icon, size: 19, color: const Color(0xFFF06B50)),
    );
  }
}

// ── Headline / subline helpers ─────────────────────────────────────────────────

String _headline(AppLocalizations l, int streak) => switch (streak) {
      0 => l.welcomeHeadline0,
      1 => l.welcomeHeadline1,
      <= 4 => l.welcomeHeadline2to4(streak),
      <= 9 => l.welcomeHeadline5to9(streak),
      <= 29 => l.welcomeHeadline10to29(streak),
      _ => l.welcomeHeadline30plus(streak),
    };

String _subline(AppLocalizations l, int streak) => switch (streak) {
      0 => l.welcomeSubline0,
      1 => l.welcomeSubline1,
      <= 4 => l.welcomeSubline2to4(streak),
      <= 9 => l.welcomeSubline5to9(streak),
      <= 29 => l.welcomeSubline10to29(streak),
      _ => l.welcomeSubline30plus,
    };

// ── _EntranceFade ──────────────────────────────────────────────────────────────

class _EntranceFade extends StatelessWidget {
  const _EntranceFade({
    required this.ctrl,
    required this.start,
    required this.end,
    required this.child,
  });

  final AnimationController ctrl;
  final double start;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: ctrl,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }
}

// ── Animation helper widgets ───────────────────────────────────────────────────

class _FlameWidget extends StatelessWidget {
  const _FlameWidget(this.flickerCtrl, this.entranceCtrl);
  final AnimationController flickerCtrl, entranceCtrl;

  @override
  Widget build(BuildContext context) {
    // Spring entrance: scale 0.2 → 1.14 → 1.0, rotate -14° → 4° → 0°
    final entranceInterval = CurvedAnimation(
      parent: entranceCtrl,
      curve: const Interval(0.07, 0.64, curve: Curves.easeOut),
    );
    final scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.14), weight: 75),
      TweenSequenceItem(tween: Tween(begin: 1.14, end: 1.0), weight: 25),
    ]).animate(entranceInterval);
    final rotateAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -14 * math.pi / 180, end: 4 * math.pi / 180), weight: 75),
      TweenSequenceItem(tween: Tween(begin: 4 * math.pi / 180, end: 0.0), weight: 25),
    ]).animate(entranceInterval);
    final opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(entranceInterval);

    return AnimatedBuilder(
      animation: Listenable.merge([entranceCtrl, flickerCtrl]),
      builder: (ctx, _) {
        // Flicker: scale 1.0→1.05→0.97→1.03→1.0, rotation 0→-2°→2°→-1°→0°
        final fv = flickerCtrl.value;
        double flickerScale = 1.0;
        double flickerRot = 0.0;
        if (fv < 0.25) {
          flickerScale = 1.0 + 0.05 * (fv / 0.25);
          flickerRot = -2 * math.pi / 180 * (fv / 0.25);
        } else if (fv < 0.6) {
          flickerScale = 1.05 - 0.08 * ((fv - 0.25) / 0.35);
          flickerRot = -2 * math.pi / 180 + 4 * math.pi / 180 * ((fv - 0.25) / 0.35);
        } else if (fv < 0.82) {
          flickerScale = 0.97 + 0.06 * ((fv - 0.6) / 0.22);
          flickerRot = 2 * math.pi / 180 - 3 * math.pi / 180 * ((fv - 0.6) / 0.22);
        } else {
          flickerScale = 1.03 - 0.03 * ((fv - 0.82) / 0.18);
          flickerRot = -1 * math.pi / 180 + 1 * math.pi / 180 * ((fv - 0.82) / 0.18);
        }

        return Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Opacity(
            opacity: opacityAnim.value,
            child: Transform.rotate(
              angle: rotateAnim.value + flickerRot,
              child: Transform.scale(
                scale: scaleAnim.value * flickerScale,
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 46,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CountUpNumber extends StatelessWidget {
  const _CountUpNumber({required this.streak, required this.countUpCtrl});
  final int streak;
  final AnimationController countUpCtrl;

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(parent: countUpCtrl, curve: Curves.easeOutCubic);
    final tween = Tween<double>(begin: 0, end: streak.toDouble());
    return AnimatedBuilder(
      animation: countUpCtrl,
      builder: (ctx, _) {
        final val = tween.evaluate(anim);
        final fs = (MediaQuery.of(ctx).size.width * 0.26).clamp(96.0, 132.0);
        return Text(
          val.round().toString(),
          style: GoogleFonts.quicksand(
            fontSize: fs,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 0.82,
            letterSpacing: -0.04 * fs,
            shadows: const [
              Shadow(color: Color(0x7F781E0C), blurRadius: 26, offset: Offset(0, 4)),
              Shadow(color: Color(0x66781E0C), blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
        );
      },
    );
  }
}

class _HaloWidget extends StatelessWidget {
  const _HaloWidget(this.ctrl);
  final AnimationController ctrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (ctx, _) {
        final t = ctrl.value * math.pi;
        final scale = 0.86 + (1.12 - 0.86) * math.sin(t);
        final opacity = 0.7 + 0.3 * math.sin(t);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x9EFFE4BC), Colors.transparent],
                  stops: [0.0, 0.64],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SunburstWidget extends StatelessWidget {
  const _SunburstWidget(this.rotCtrl, this.entranceCtrl);
  final AnimationController rotCtrl, entranceCtrl;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: entranceCtrl,
        curve: const Interval(0.21, 0.85, curve: Curves.easeOut),
      ),
      child: AnimatedBuilder(
        animation: rotCtrl,
        builder: (ctx, _) => CustomPaint(
          painter: _SunburstPainter(rotCtrl),
          // CSS: 280px element with scale(0.6) → 168px visual
          size: const Size(168, 168),
        ),
      ),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  const _SunburstPainter(this.rotationAnim) : super(repaint: rotationAnim);
  final Animation<double> rotationAnim;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerR = size.width / 2;
    final innerR = outerR * 0.30;
    final outerMask = outerR * 0.78;

    // Ring clip: draw only in the ring between innerR and outerMask
    final ringPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: center, radius: outerMask))
      ..addOval(Rect.fromCircle(center: center, radius: innerR));
    canvas.save();
    canvas.clipPath(ringPath);

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    const rayDeg = 4.0 * math.pi / 180;
    const cycleDeg = 22.0 * math.pi / 180;
    final baseAngle = rotationAnim.value * 2 * math.pi;
    final nCycles = (2 * math.pi / cycleDeg).ceil() + 2;

    for (int i = 0; i < nCycles; i++) {
      final startAngle = baseAngle + i * cycleDeg;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: outerR),
          startAngle,
          rayDeg,
          false,
        )
        ..lineTo(center.dx, center.dy)
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SunburstPainter old) => true;
}

class _RippleRing extends StatelessWidget {
  const _RippleRing(this.ctrl, this.startInterval);
  final AnimationController ctrl;
  final double startInterval;

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: ctrl,
      curve: Interval(startInterval, 1.0, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final t = anim.value;
        // CSS: 150px ring, scale(0.4)→scale(2) = 60px→300px, opacity 0.6→0
        return SizedBox(
          width: 60 + 240 * t,
          height: 60 + 240 * t,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: (1 - t) * 0.5),
                width: 2.0,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Painters ───────────────────────────────────────────────────────────────────

class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter(this.animation) : super(repaint: animation);
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 3.5;
    final trackPaint = Paint()
      ..color = const Color(0x47FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius, trackPaint);
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final sweep = (1 - animation.value) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CountdownRingPainter old) => true;
}

// ── Confetti ───────────────────────────────────────────────────────────────────

class _Particle {
  const _Particle({
    required this.cx,
    required this.cy,
    required this.vx,
    required this.vy,
    required this.wobble,
    required this.size,
    required this.color,
    required this.isCircle,
    required this.rot,
    required this.vr,
  });

  // Per-frame initial velocities (px/frame at 60fps), matching the JS reference.
  final double cx, cy, vx, vy, wobble, size, rot, vr;
  final Color color;
  final bool isCircle;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.animation, this.particles)
      : super(repaint: animation);
  final Animation<double> animation;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    // Reproduce the JS reference's per-frame Euler integration in closed form.
    // Per frame: vy += 0.13; vx *= 0.992; wobble += 0.08; then x/y advance.
    // With f = frame count (60fps), elapsed = animation.value * 4s:
    final f = 240.0 * animation.value; // 60fps * 4s
    final paint = Paint()..style = PaintingStyle.fill;
    final decay = math.pow(0.992, f).toDouble();
    // Σ_{k=1..f} sin(wobble + 0.08k) = sin(0.04f)/sin(0.04) * sin(wobble + 0.04(f+1))
    final wobbleEnvelope = math.sin(0.04 * f) / math.sin(0.04);
    for (final p in particles) {
      // vertical: y0 + vy0*f + 0.13*f*(f+1)/2  (gravity accumulates per frame)
      final py = p.cy + p.vy * f + 0.13 * f * (f + 1) / 2;
      final alpha = ((size.height + 30 - py) / 120).clamp(0.0, 1.0);
      if (alpha <= 0) continue;
      // horizontal: vx geometric-decay sum + wobble sum
      final vxSum = p.vx * 124.0 * (1 - decay);
      final wobbleSum =
          0.6 * wobbleEnvelope * math.sin(p.wobble + 0.04 * (f + 1));
      final px = p.cx + vxSum + wobbleSum;
      final rot = p.rot + p.vr * f;
      paint.color = p.color.withValues(alpha: alpha);
      if (p.isCircle) {
        canvas.drawCircle(Offset(px, py), p.size / 2, paint);
      } else {
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(rot);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.66,
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
