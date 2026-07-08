// CCA-F ARCADE — Práctica para Claude Certified Architect (Foundations)
// Lógica y UI del juego. Las preguntas viven en questions.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'questions.dart';
import 'questions_en.dart';

void main() => runApp(const CcaArcadeApp());

// ============================================================ APP

class CcaArcadeApp extends StatelessWidget {
  const CcaArcadeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CCA-F Arcade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E1A),
        fontFamily: 'monospace',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4EE1FF),
          secondary: Color(0xFFFF4E9B),
          surface: Color(0xFF141830),
        ),
        useMaterial3: true,
      ),
      home: const GameShell(),
    );
  }
}

enum Screen { menu, playing, results }

class GameShell extends StatefulWidget {
  const GameShell({super.key});
  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> {
  Screen screen = Screen.menu;
  bool english = false;

  List<Question> get bank => english ? questionsEn : questionsEs;
  List<DomainInfo> get doms => english ? domainsEn : domainsEs;
  String t(String es, String en) => english ? en : es;

  // Progreso persistente durante la sesión
  final Map<int, int> bestByDomain = {}; // domain -> mejor % de acierto
  int totalXp = 0;

  // Estado de la partida
  late List<Question> deck;
  int idx = 0;
  int lives = 3;
  int score = 0;
  int streak = 0;
  int bestStreak = 0;
  int correctCount = 0;
  int fifties = 3;
  final Set<int> hidden = {};
  int? selected;
  bool answered = false;
  bool isBoss = false;
  int missionDomain = -1;
  final List<Question> failed = [];

  final rng = Random();

  /// Baraja las opciones de una pregunta y recalcula el índice correcto,
  /// para que la respuesta no caiga siempre en la misma letra.
  Question _shuffleOptions(Question q) {
    final order = List<int>.generate(q.options.length, (i) => i)..shuffle(rng);
    final opts = [for (final i in order) q.options[i]];
    return Question(q.domain, q.q, opts, order.indexOf(q.answer), q.why);
  }

  void startMission(int domain) {
    final pool = bank.where((q) => q.domain == domain).toList()
      ..shuffle(rng);
    _start(pool.map(_shuffleOptions).toList(), boss: false, domain: domain);
  }

  void startBoss() {
    final pool = List<Question>.from(bank)..shuffle(rng);
    _start(pool.take(20).map(_shuffleOptions).toList(),
        boss: true, domain: -1);
  }

  void _start(List<Question> qs, {required bool boss, required int domain}) {
    setState(() {
      deck = qs;
      idx = 0;
      lives = 3;
      score = 0;
      streak = 0;
      bestStreak = 0;
      correctCount = 0;
      fifties = 3;
      hidden.clear();
      selected = null;
      answered = false;
      isBoss = boss;
      missionDomain = domain;
      failed.clear();
      screen = Screen.playing;
    });
  }

  int get multiplier => min(1 + streak ~/ 2, 5);

  void _useFifty() {
    if (answered || fifties <= 0 || hidden.isNotEmpty) return;
    final q = deck[idx];
    final wrongs = [for (var i = 0; i < q.options.length; i++) if (i != q.answer) i]
      ..shuffle(rng);
    setState(() {
      hidden.addAll(wrongs.take(2));
      fifties--;
    });
  }

  void _answer(int i) {
    if (answered) return;
    final q = deck[idx];
    final ok = i == q.answer;
    setState(() {
      selected = i;
      answered = true;
      if (ok) {
        streak++;
        bestStreak = max(bestStreak, streak);
        correctCount++;
        score += 100 * multiplier;
      } else {
        streak = 0;
        lives--;
        failed.add(q);
      }
    });
  }

  void _next() {
    if (lives <= 0 || idx + 1 >= deck.length) {
      _finish();
      return;
    }
    setState(() {
      idx++;
      selected = null;
      answered = false;
      hidden.clear();
    });
  }

  void _finish() {
    final pct = deck.isEmpty ? 0 : (correctCount * 100 ~/ deck.length);
    if (missionDomain >= 0) {
      bestByDomain[missionDomain] =
          max(bestByDomain[missionDomain] ?? 0, pct);
    }
    setState(() {
      totalXp += score;
      screen = Screen.results;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (screen) {
      case Screen.menu:
        return _menu();
      case Screen.playing:
        return _play();
      case Screen.results:
        return _results();
    }
  }

  // ---------------------------------------------------------- MENÚ

  Widget _menu() {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            const Text('▲ CCA-F ARCADE',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Color(0xFF4EE1FF))),
            const SizedBox(height: 6),
            const Text('Claude Certified Architect · Foundations',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('${t('XP TOTAL', 'TOTAL XP')}: $totalXp',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFFFFC24B),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _langChip('🇪🇸 ESPAÑOL', false),
                const SizedBox(width: 10),
                _langChip('🇺🇸 ENGLISH', true),
              ],
            ),
            const SizedBox(height: 20),
            Text(t('ELIGE TU MISIÓN', 'CHOOSE YOUR MISSION'),
                style: TextStyle(
                    color: Colors.white54,
                    letterSpacing: 3,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (var d = 0; d < doms.length; d++) _missionCard(d),
            const SizedBox(height: 8),
            _bossCard(),
            const SizedBox(height: 24),
            Text(
              t('Reglas: 3 vidas · racha de aciertos = multiplicador de puntos '
                    '(hasta x5) · sin límite de tiempo: piensa cada respuesta. '
                    'El JEFE FINAL mezcla los 5 dominios en un solo simulacro.',
                'Rules: 3 lives · answer streak = score multiplier (up to x5) · '
                    'no time limit: think each answer through. '
                    'The FINAL BOSS mixes all 5 domains into one mock exam.'),
              style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _missionCard(int d) {
    final info = doms[d];
    final best = bestByDomain[d];
    final count = bank.where((q) => q.domain == d).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => startMission(d),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF141830),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: info.color.withOpacity(0.55), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: info.color.withOpacity(0.15),
                  blurRadius: 14,
                  spreadRadius: 1),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: info.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(info.icon, color: info.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${t('NIVEL', 'LEVEL')} ${d + 1} · ${info.name}',
                        style: TextStyle(
                            color: info.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 3),
                    Text('${info.subtitle} · $count ${t('preguntas', 'questions')}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    if (best != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${t('MEJOR', 'BEST')}: $best%',
                            style: TextStyle(
                                color: best >= 72
                                    ? const Color(0xFF57E39A)
                                    : const Color(0xFFFFC24B),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1)),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bossCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: startBoss,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(colors: [
            Color(0xFF2A0F3A),
            Color(0xFF3A0F2A),
          ]),
          border: Border.all(color: const Color(0xFFFF4E9B), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x66FF4E9B), blurRadius: 18),
          ],
        ),
        child: Row(
          children: [
            const Text('👾', style: TextStyle(fontSize: 34)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('JEFE FINAL · SIMULACRO', 'FINAL BOSS · MOCK EXAM'),
                      style: const TextStyle(
                          color: Color(0xFFFF4E9B),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2)),
                  const SizedBox(height: 3),
                  Text(
                      t('20 preguntas de todos los dominios · 3 comodines 50/50',
                        '20 questions from every domain · three 50/50 lifelines'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _langChip(String label, bool en) {
    final selected = english == en;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => english = en),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4EE1FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? const Color(0xFF4EE1FF) : Colors.white24),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.black : Colors.white54,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1)),
      ),
    );
  }

  // ---------------------------------------------------------- JUEGO

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141830),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF4EE1FF), width: 1.5),
        ),
        title: Text(t('¿Salir al mapa?', 'Exit to the map?'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        content: Text(
            t('Perderás el progreso y el puntaje de esta partida.',
              'You will lose this run\u0027s progress and score.'),
            style: const TextStyle(color: Colors.white70, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t('CANCELAR', 'CANCEL'),
                style: const TextStyle(color: Colors.white54, letterSpacing: 1.5)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF4E9B),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t('SALIR AL MAPA', 'EXIT TO MAP'),
                style: const TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      setState(() => screen = Screen.menu);
    }
  }

  Widget _play() {
    final q = deck[idx];
    final accent =
        q.domain >= 0 ? doms[q.domain].color : const Color(0xFFFF4E9B);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HUD
              Row(
                children: [
                  InkWell(
                    onTap: _confirmExit,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.close, color: Colors.white38, size: 20),
                    ),
                  ),
                  Text(List.filled(lives, '❤').join(' ') +
                      (lives < 3
                          ? ' ${List.filled(3 - lives, '·').join(' ')}'
                          : '')),
                  const Spacer(),
                  if (streak >= 2)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text('🔥x$multiplier',
                          style: const TextStyle(
                              color: Color(0xFFFFC24B),
                              fontWeight: FontWeight.bold)),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: _useFifty,
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: (!answered &&
                                      fifties > 0 &&
                                      hidden.isEmpty)
                                  ? const Color(0xFFFFC24B)
                                  : Colors.white12),
                        ),
                        child: Text('50:50 ×$fifties',
                            style: TextStyle(
                                color: (!answered &&
                                        fifties > 0 &&
                                        hidden.isEmpty)
                                    ? const Color(0xFFFFC24B)
                                    : Colors.white24,
                                fontWeight: FontWeight.w900,
                                fontSize: 12)),
                      ),
                    ),
                  ),
                  Text('$score PTS',
                      style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isBoss
                    ? '👾 ${t('JEFE FINAL', 'FINAL BOSS')} · ${idx + 1}/${deck.length} · ${doms[q.domain].name}'
                    : '${doms[q.domain].name} · ${idx + 1}/${deck.length}',
                style: TextStyle(
                    color: accent.withOpacity(0.85),
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141830),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accent.withOpacity(0.4)),
                      ),
                      child: Text(q.q,
                          style: const TextStyle(
                              fontSize: 16, height: 1.45, color: Colors.white)),
                    ),
                    const SizedBox(height: 14),
                    for (var i = 0; i < q.options.length; i++)
                      _option(q, i, accent),
                    if (answered) _feedback(q),
                  ],
                ),
              ),
              if (answered)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _next,
                    child: Text(
                      lives <= 0
                          ? t('VER RESULTADOS', 'SEE RESULTS')
                          : (idx + 1 >= deck.length
                              ? t('TERMINAR MISIÓN', 'FINISH MISSION')
                              : t('SIGUIENTE ▶', 'NEXT ▶')),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _option(Question q, int i, Color accent) {
    final removed = hidden.contains(i) && !answered;
    Color border = Colors.white12;
    Color bg = const Color(0xFF10142A);
    IconData? icon;
    if (answered) {
      if (i == q.answer) {
        border = const Color(0xFF57E39A);
        bg = const Color(0xFF10241B);
        icon = Icons.check_circle;
      } else if (i == selected) {
        border = const Color(0xFFFF5C5C);
        bg = const Color(0xFF2A1216);
        icon = Icons.cancel;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: (answered || removed) ? null : () => _answer(i),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: removed ? 0.22 : 1,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${String.fromCharCode(65 + i)} ',
                  style: TextStyle(
                      color: accent, fontWeight: FontWeight.w900)),
              Expanded(
                child: Text(q.options[i],
                    style: const TextStyle(
                        color: Colors.white, height: 1.35, fontSize: 14)),
              ),
              if (icon != null)
                Icon(icon,
                    size: 18,
                    color: i == q.answer
                        ? const Color(0xFF57E39A)
                        : const Color(0xFFFF5C5C)),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _feedback(Question q) {
    final ok = selected == q.answer;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFF10241B) : const Color(0xFF2A1216),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: ok ? const Color(0xFF57E39A) : const Color(0xFFFF5C5C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ok
                ? '✔ ${t('¡CORRECTO!', 'CORRECT!')}  +${100 * multiplier} pts'
                : '✘ ${t('INCORRECTO · -1 vida', 'WRONG · -1 life')}',
            style: TextStyle(
                color: ok ? const Color(0xFF57E39A) : const Color(0xFFFF5C5C),
                fontWeight: FontWeight.w900,
                letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(q.why,
              style: const TextStyle(
                  color: Colors.white70, height: 1.45, fontSize: 13)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- RESULTADOS

  Widget _results() {
    final pct = deck.isEmpty ? 0 : (correctCount * 100 / deck.length).round();
    final passed = pct >= 72; // 720/1000 del examen real
    final died = lives <= 0;
    String medal;
    if (died) {
      medal = '💀 GAME OVER';
    } else if (pct >= 90) {
      medal = t('🏆 ARQUITECTO LEGENDARIO', '🏆 LEGENDARY ARCHITECT');
    } else if (passed) {
      medal = t('🥇 ¡APROBADO! (≥72%)', '🥇 PASSED! (≥72%)');
    } else {
      medal = t('📚 SIGUE ENTRENANDO', '📚 KEEP TRAINING');
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            Text(medal,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: passed && !died
                        ? const Color(0xFF57E39A)
                        : const Color(0xFFFFC24B))),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF141830),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  _statRow(t('Aciertos', 'Correct'),
                      '$correctCount / ${idx + (answered ? 1 : 0)} ($pct%)'),
                  _statRow(t('Puntaje', 'Score'), '$score'),
                  _statRow(t('Mejor racha', 'Best streak'), '🔥 $bestStreak'),
                  _statRow(t('Vidas restantes', 'Lives left'), lives > 0 ? '❤ x$lives' : '—'),
                ],
              ),
            ),
            if (failed.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(t('REPASA ESTAS PREGUNTAS', 'REVIEW THESE QUESTIONS'),
                  style: const TextStyle(
                      color: Color(0xFFFF5C5C),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 12)),
              const SizedBox(height: 10),
              for (final f in failed)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10142A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.q,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              height: 1.4)),
                      const SizedBox(height: 6),
                      Text('✔ ${f.options[f.answer]}',
                          style: const TextStyle(
                              color: Color(0xFF57E39A),
                              fontSize: 12,
                              height: 1.4)),
                      const SizedBox(height: 4),
                      Text(f.why,
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              height: 1.4)),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4EE1FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                if (isBoss) {
                  startBoss();
                } else {
                  startMission(missionDomain);
                }
              },
              child: Text(t('REINTENTAR', 'RETRY'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 2)),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => setState(() => screen = Screen.menu),
              child: Text(t('VOLVER AL MAPA', 'BACK TO MAP'),
                  style: const TextStyle(letterSpacing: 2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
