import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadPrefs();
  runApp(const LithaApp());
}

class Api {
  static final url = _baseUrl();
  static String _baseUrl() {
    const configured = String.fromEnvironment('API_URL', defaultValue: '');
    if (configured.isNotEmpty) return configured;
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:9090'
        : 'http://localhost:9090';
  }

  static const headers = {'Content-Type': 'application/json'};
  static Future<List<Map<String, dynamic>>> getAll(String route) async {
    final response = await http.get(Uri.parse('$url/api/$route'));
    _check(response);
    return (jsonDecode(response.body) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> save(String route, Map<String, dynamic> value,
      {int? id}) async {
    final uri = Uri.parse('$url/api/$route${id == null ? '' : '/$id'}');
    final response = id == null
        ? await http.post(uri, headers: headers, body: jsonEncode(value))
        : await http.put(uri, headers: headers, body: jsonEncode(value));
    _check(response);
  }

  static Future<void> remove(String route, int id) async {
    final r = await http.delete(Uri.parse('$url/api/$route/$id'));
    _check(r);
  }

  static Future<String> upload(XFile file) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$url/api/uploads'));
    request.files.add(http.MultipartFile.fromBytes(
        'file', await file.readAsBytes(),
        filename: file.name));
    final response = await http.Response.fromStream(await request.send());
    _check(response);
    return '$url${jsonDecode(response.body)['path']}';
  }

  static void _check(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300)
      throw Exception('API error ${r.statusCode}: ${r.body}');
  }
}

// ── Theme system ──────────────────────────────────────────────────────────────

class LithaTheme {
  const LithaTheme({
    required this.name,
    required this.bg,
    required this.card,
    required this.accent,
    required this.muted,
    required this.imageBg,
    required this.brightness,
    required this.circle1,
    required this.circle2,
  });
  final String name;
  final Color bg, card, accent, muted, imageBg;
  final Brightness brightness;
  final Color circle1, circle2;
}

const _gothicTheme = LithaTheme(
  name: 'Gothic',
  bg: Color(0xff0d0a12),
  card: Color(0xff211a29),
  accent: Color(0xffb98be6),
  muted: Color(0xffa79bae),
  imageBg: Color(0xff30243b),
  brightness: Brightness.dark,
  circle1: Color(0xffb98be6),
  circle2: Color(0xff0d0a12),
);

const _romanticTheme = LithaTheme(
  name: 'Romantic',
  bg: Color(0xffFFF7FA),
  card: Color(0xffFFFFFF),
  accent: Color(0xffD98FA8),
  muted: Color(0xff8C737D),
  imageBg: Color(0xffF3C9D7),
  brightness: Brightness.light,
  circle1: Color(0xffD98FA8),
  circle2: Color(0xff8E526C),
);

const _botanicalTheme = LithaTheme(
  name: 'Botanical',
  bg: Color(0xffFAF8F2),
  card: Color(0xffFFFFFF),
  accent: Color(0xff9BAF91),
  muted: Color(0xff7C8075),
  imageBg: Color(0xffEEF1E8),
  brightness: Brightness.light,
  circle1: Color(0xff9BAF91),
  circle2: Color(0xff60485D),
);

const _themes = [_gothicTheme, _romanticTheme, _botanicalTheme];
final _themeNotifier = ValueNotifier<LithaTheme>(_gothicTheme);

final _nameNotifier = ValueNotifier<String>('Alisa');

Future<void> _loadPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  _nameNotifier.value = prefs.getString('user_name') ?? 'Alisa';
  _themeNotifier.value = _themes[
    (prefs.getInt('theme_index') ?? 0).clamp(0, _themes.length - 1)];
}

Future<void> _saveName(String name) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_name', name);
}

Future<void> _saveTheme(LithaTheme t) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('theme_index', _themes.indexOf(t));
}

// Shortcut getters — read from the active theme. NOT const.
Color get bg => _themeNotifier.value.bg;
Color get card => _themeNotifier.value.card;
Color get accent => _themeNotifier.value.accent;
Color get muted => _themeNotifier.value.muted;
Color get imageBg => _themeNotifier.value.imageBg;

// ── Typography helpers ────────────────────────────────────────────────────────
// Display serif — Cormorant Garamond
TextStyle serif(double size,
    {FontWeight weight = FontWeight.w400,
    FontStyle style = FontStyle.normal,
    Color? color}) =>
    GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: weight,
        fontStyle: style,
        color: color);

// Tracked caps — Cinzel
TextStyle caps(double size, {Color? color}) =>
    GoogleFonts.cinzel(
        fontSize: size,
        letterSpacing: 1.8,
        fontWeight: FontWeight.w500,
        color: color ?? accent);

// Temporary preview delay for the loading screen. Set to Duration.zero to remove it.
const loadingScreenPreviewDuration = Duration(seconds: 5);

class LithaApp extends StatelessWidget {
  const LithaApp({super.key});
  @override
  Widget build(BuildContext c) => ListenableBuilder(
      listenable: _themeNotifier,
      builder: (_, __) {
        final t = _themeNotifier.value;
        return MaterialApp(
          key: ObjectKey(t),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: t.brightness,
            useMaterial3: true,
            scaffoldBackgroundColor: t.bg,
            colorScheme: ColorScheme.fromSeed(
                seedColor: t.accent, brightness: t.brightness),
          ),
          home: const Shell(),
        );
      });
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  late final PageController pageController;
  bool showingLoadingPreview = true;
  bool busy = true;
  String? error;
  List<Map<String, dynamic>> stones = [], hunts = [], photos = [];
  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: tab);
    refresh();
    Future.delayed(loadingScreenPreviewDuration, () {
      if (mounted) setState(() => showingLoadingPreview = false);
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    setState(() => busy = true);
    try {
      final r = await Future.wait([
        Api.getAll('stones'),
        Api.getAll('hunt-items'),
        Api.getAll('stone-photos')
      ]);
      if (mounted)
        setState(() {
          stones = r[0];
          hunts = r[1];
          photos = r[2];
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) {
    final isLoading = showingLoadingPreview || (busy && stones.isEmpty);
    final pages = [
      Home(stones, hunts, photos, refresh),
      Collection(stones, photos, refresh),
      Hunt(hunts, stones, refresh),
      Profile(stones, hunts)
    ];
    return Scaffold(
        body: isLoading
            ? const LoadingScreen()
            : error != null && stones.isEmpty
                ? Offline(error!, refresh)
                : PageView.builder(
                    controller: pageController,
                    onPageChanged: (value) => setState(() => tab = value),
                    itemCount: pages.length,
                    itemBuilder: (_, index) => AnimatedBuilder(
                        animation: pageController,
                        child: pages[index],
                        builder: (_, child) {
                          final current = pageController.hasClients
                              ? pageController.page ?? tab.toDouble()
                              : tab.toDouble();
                          final distance = (current - index)
                              .abs()
                              .clamp(0.0, 1.0)
                              .toDouble();
                          return Transform.scale(
                              scale: 1 - (distance * .04),
                              child: Opacity(
                                  opacity: 1 - (distance * .25), child: child));
                        })),
        floatingActionButton: isLoading
            ? null
            : FloatingActionButton(
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: () {
                  if (tab == 1) {
                    stoneForm(c, refresh);
                  } else if (tab == 2) {
                    huntForm(c, refresh);
                  } else {
                    chooseAdd(c);
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [accent, const Color(0xff7B4FB8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                        color: accent.withValues(alpha: .35), width: 1),
                    boxShadow: [
                      BoxShadow(
                          color: accent.withValues(alpha: .40),
                          blurRadius: 18,
                          spreadRadius: 2),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                )),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: isLoading
            ? null
            : NavigationBar(
                selectedIndex: tab,
                onDestinationSelected: (v) => pageController.animateToPage(v,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic),
                destinations: const [
                    NavigationDestination(
                        icon: Icon(Icons.home_outlined), label: 'Home'),
                    NavigationDestination(
                        icon: Icon(Icons.diamond_outlined), label: 'Stones'),
                    NavigationDestination(
                        icon: Icon(Icons.explore_outlined), label: 'Hunt'),
                    NavigationDestination(
                        icon: Icon(Icons.person_outline), label: 'Me')
                  ]));
  }

  void chooseAdd(BuildContext c) => showModalBottomSheet(
      context: c,
      builder: (x) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
                leading: const Icon(Icons.diamond_outlined),
                title: const Text('Add stone'),
                onTap: () {
                  Navigator.pop(x);
                  stoneForm(c, refresh);
                }),
            ListTile(
                leading: const Icon(Icons.explore_outlined),
                title: const Text('Add hunt item'),
                onTap: () {
                  Navigator.pop(x);
                  huntForm(c, refresh);
                })
          ])));
}

class Home extends StatelessWidget {
  const Home(this.stones, this.hunts, this.photos, this.refresh, {super.key});
  final List<Map<String, dynamic>> stones, hunts, photos;
  final Future<void> Function() refresh;

  Map<String, dynamic>? get _heroStone =>
      stones.isNotEmpty ? stones.last : null;

  @override
  Widget build(BuildContext context) {
    final hero = _heroStone;
    final heroUrl = hero != null ? stonePhotoUrl(hero, photos) : null;
    final recentFour = stones.reversed.take(6).toList();
    final topHunt = hunts
        .where((h) => h['status'] == 'SEARCHING')
        .toList()
        .firstOrNull;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: refresh,
        child: Stack(
          children: [
            // Radial glow from top
            Positioned(
              top: -80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0x298B5FBF),
                        Colors.transparent,
                      ],
                      stops: const [0, .6],
                    ),
                  ),
                ),
              ),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
              children: [
                // ── Header ──────────────────────────────────────────────────
                ValueListenableBuilder<String>(
                  valueListenable: _nameNotifier,
                  builder: (_, name, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('☽ ',
                              style: TextStyle(
                                  fontSize: 12, color: muted)),
                          Text(_greeting(),
                              style:
                                  TextStyle(fontSize: 13, color: muted)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text("$name's cabinet",
                          style: serif(27,
                              weight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Hero card ───────────────────────────────────────────────
                if (hero != null)
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => Detail(hero, refresh))),
                    child: HeroFrame(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(21),
                                topRight: Radius.circular(21)),
                            child: heroUrl != null
                                ? Image.network(
                                    heroUrl,
                                    width: double.infinity,
                                    height: 240,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Container(
                                            width: double.infinity,
                                            height: 240,
                                            color: imageBg,
                                            child: Center(
                                                child: Icon(
                                                    Icons.diamond_outlined,
                                                    color: accent
                                                        .withValues(alpha: .4),
                                                    size: 56))),
                                  )
                                : Container(
                                    width: double.infinity,
                                    height: 240,
                                    color: imageBg,
                                    child: Center(
                                        child: Icon(
                                            Icons.diamond_outlined,
                                            color:
                                                accent.withValues(alpha: .4),
                                            size: 56))),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    hero['name'] ?? 'Unnamed stone',
                                    style: serif(19,
                                        weight: FontWeight.w600)),
                                if ((hero['whyKept'] ?? '')
                                    .toString()
                                    .isNotEmpty) ...[  
                                  const SizedBox(height: 4),
                                  Text(
                                      hero['whyKept'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: serif(13,
                                          style: FontStyle.italic,
                                          color: muted)),
                                ],
                                const SizedBox(height: 10),
                                Text('View this stone →',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: accent,
                                        letterSpacing: .3)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: accent.withValues(alpha: .18), width: 1)),
                    child: Center(
                        child: Column(mainAxisSize: MainAxisSize.min,
                            children: [
                          Icon(Icons.diamond_outlined,
                              color: accent.withValues(alpha: .4), size: 36),
                          const SizedBox(height: 8),
                          Text('Add your first stone',
                              style: TextStyle(color: muted)),
                        ])),
                  ),
                const SizedBox(height: 16),

                // ── Stats row ───────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: accent.withValues(alpha: .18), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCell('${stones.length}', 'stones'),
                      _Dot(),
                      _StatCell('${hunts.length}', 'hunts'),
                      _Dot(),
                      _StatCell(
                          '${photos.length}', 'photos'),
                      _Dot(),
                      _StatCell(
                          '${_yearsActive(stones)}', 'years'),
                    ],
                  ),
                ),

                // ── Ornament divider ────────────────────────────────────────
                const OrnamentDivider(),

                // ── Recently added label ────────────────────────────────────
                Text('RECENTLY ADDED', style: caps(10)),
                const SizedBox(height: 14),

                // ── Horizontal swatch row ───────────────────────────────────
                if (recentFour.isEmpty)
                  const Empty('Add your first stone.')
                else
                  SizedBox(
                    height: 168,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recentFour.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final s = recentFour[i];
                        final url = stonePhotoUrl(s, photos);
                        return GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => Detail(s, refresh))),
                          onLongPress: () =>
                              showStonePreview(context, s, url),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FacetedSwatch(
                                  width: 110,
                                  height: 130,
                                  imageUrl: url),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 110,
                                child: Text(
                                    s['name'] ?? '',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: muted)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                // ── Hunt teaser ─────────────────────────────────────────────
                if (topHunt != null) ...[
                  const OrnamentDivider(),
                  Text('THE HUNT', style: caps(10)),
                  const SizedBox(height: 12),
                  _HuntTeaser(topHunt, photos, refresh),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Good night,';
    if (h < 12) return 'Good morning,';
    if (h < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  int _yearsActive(List<Map<String, dynamic>> s) {
    if (s.isEmpty) return 0;
    // fallback: just return 1 as a warm default
    return 1;
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: serif(26, weight: FontWeight.w600, color: accent)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10, color: muted)),
        ],
      );
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: .3),
        ),
      );
}

class _HuntTeaser extends StatelessWidget {
  const _HuntTeaser(this.hunt, this.photos, this.refresh);
  final Map<String, dynamic> hunt;
  final List<Map<String, dynamic>> photos;
  final Future<void> Function() refresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: accent.withValues(alpha: .18), width: 1),
      ),
      child: Row(children: [
        FacetedSwatch(
            width: 64,
            height: 72,
            imageUrl: hunt['imageUrl'] as String?),
        const SizedBox(width: 14),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(hunt['name'] ?? 'Hunt item',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: serif(16, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('still searching',
                  style:
                      TextStyle(fontSize: 12, color: muted)),
            ])),
        Icon(Icons.chevron_right, color: muted, size: 18),
      ]),
    );
  }
}

class Collection extends StatefulWidget {
  const Collection(this.stones, this.photos, this.refresh, {super.key});
  final List<Map<String, dynamic>> stones;
  final List<Map<String, dynamic>> photos;
  final Future<void> Function() refresh;
  @override
  State<Collection> createState() => _CollectionState();
}

enum _Filter { all, favorites, recent, withMemories }

class _CollectionState extends State<Collection> {
  String q = '';
  _Filter filter = _Filter.all;

  List<Map<String, dynamic>> get _filtered {
    var list = widget.stones.where((s) {
      return (s['name'] ?? '')
          .toString()
          .toLowerCase()
          .contains(q.toLowerCase());
    }).toList();
    switch (filter) {
      case _Filter.favorites:
        list = list.where((s) => s['favorite'] == true).toList();
      case _Filter.recent:
        list = list.reversed.take(4).toList();
      case _Filter.withMemories:
        // stones with memories — we don't have memory count directly,
        // so show all for now (data isn't available at list level)
        break;
      case _Filter.all:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: widget.refresh,
        child: Stack(children: [
          // Radial glow
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0x1A8B5FBF),
                  Colors.transparent,
                ], stops: const [0, .6]),
              ),
            ),
          ),
          Column(children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.hexagon_outlined,
                        size: 12, color: muted),
                    const SizedBox(width: 6),
                    Text('Specimens kept',
                        style: TextStyle(fontSize: 13, color: muted)),
                  ]),
                  const SizedBox(height: 3),
                  Text('Stones', style: serif(28, weight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Search ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => q = v),
                style: TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 18),
                  hintText: 'Search your stones',
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: _themeNotifier.value.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                        color: accent.withValues(alpha: .2), width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                        color: accent.withValues(alpha: .2), width: 1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Filter chips ──────────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _Chip('All', _Filter.all, filter,
                      () => setState(() => filter = _Filter.all)),
                  const SizedBox(width: 8),
                  _Chip('Favorites', _Filter.favorites, filter,
                      () => setState(() => filter = _Filter.favorites)),
                  const SizedBox(width: 8),
                  _Chip('Recently added', _Filter.recent, filter,
                      () => setState(() => filter = _Filter.recent)),
                  const SizedBox(width: 8),
                  _Chip('With memories', _Filter.withMemories, filter,
                      () => setState(() => filter = _Filter.withMemories)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Masonry grid ──────────────────────────────────────────────
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Empty('No stones here yet.'))
                  : RefreshIndicator(
                      onRefresh: widget.refresh,
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 110),
                        child: _MasonryGrid(
                            list, widget.photos, widget.refresh),
                      ),
                    ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.value, this.current, this.onTap);
  final String label;
  final _Filter value, current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? accent : accent.withValues(alpha: .3),
              width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: active ? card : muted,
              fontWeight:
                  active ? FontWeight.w600 : FontWeight.normal),
        ),
      ),
    );
  }
}

class _MasonryGrid extends StatelessWidget {
  const _MasonryGrid(this.stones, this.photos, this.refresh);
  final List<Map<String, dynamic>> stones;
  final List<Map<String, dynamic>> photos;
  final Future<void> Function() refresh;

  double _cardHeight(Map<String, dynamic> stone) {
    // Stable pseudo-random height seeded from stone id
    final seed = (stone['id'] as int? ?? 0);
    final rng = math.Random(seed);
    return 148 + rng.nextDouble() * 60; // 148..208
  }

  @override
  Widget build(BuildContext context) {
    // Split into two columns alternately
    final left = <Map<String, dynamic>>[];
    final right = <Map<String, dynamic>>[];
    for (var i = 0; i < stones.length; i++) {
      (i.isEven ? left : right).add(stones[i]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: Column(
          children: left
              .map((s) => _GemCard(
                  s, photos, refresh, _cardHeight(s)))
              .toList(),
        )),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
          children: right
              .map((s) => _GemCard(
                  s, photos, refresh, _cardHeight(s)))
              .toList(),
        )),
      ],
    );
  }
}

class _GemCard extends StatelessWidget {
  const _GemCard(this.stone, this.photos, this.refresh, this.cardHeight);
  final Map<String, dynamic> stone;
  final List<Map<String, dynamic>> photos;
  final Future<void> Function() refresh;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    final url = stonePhotoUrl(stone, photos);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => Detail(stone, refresh))),
        onLongPress: () => showStonePreview(context, stone, url),
        child: Column(
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final w = constraints.maxWidth;
              return Stack(
                children: [
                  FacetedSwatch(
                      width: w,
                      height: cardHeight,
                      imageUrl: url),
                  if (stone['favorite'] == true)
                    Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(Icons.favorite,
                            size: 14, color: accent)),
                ],
              );
            }),
            const SizedBox(height: 6),
            Text(
              stone['name'] ?? 'Unnamed',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: muted),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class Hunt extends StatefulWidget {
  const Hunt(this.items, this.stones, this.refresh, {super.key});
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> stones;
  final Future<void> Function() refresh;

  @override
  State<Hunt> createState() => _HuntState();
}

class _HuntState extends State<Hunt> {
  bool showGrid = false;
  bool reverse = false;
  String q = '';
  HuntSort sort = HuntSort.date;
  HuntFilter filter = HuntFilter.all;

  List<Map<String, dynamic>> get sortedItems {
    final list = List<Map<String, dynamic>>.of(widget.items);
    switch (sort) {
      case HuntSort.az:
        list.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      case HuntSort.priority:
        list.sort((a, b) => (b['priority'] ?? 3).compareTo(a['priority'] ?? 3));
      case HuntSort.date:
        list.sort(
            (a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
    }
    final filtered = list
        .where((item) =>
            (filter == HuntFilter.all ||
                    (filter == HuntFilter.found
                        ? item['status'] == 'FOUND'
                        : item['status'] != 'FOUND')) &&
                (item['name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(q.toLowerCase()) ||
            (item['description'] ?? '')
                .toString()
                .toLowerCase()
                .contains(q.toLowerCase()))
        .toList();
    return reverse ? filtered.reversed.toList() : filtered;
  }

  Future<void> chooseSort() async {
    final result = await showModalBottomSheet<HuntSort>(
        context: context,
        builder: (c) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const ListTile(title: Text('Sort The Hunt')),
              ...HuntSort.values.map((choice) => ListTile(
                  leading: Icon(choice == sort
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off),
                  title: Text(choice.label),
                  onTap: () => Navigator.pop(c, choice)))
            ])));
    if (result != null && mounted) setState(() => sort = result);
  }

  @override
  Widget build(BuildContext c) => SafeArea(
          child: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 12, 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('The Hunt',
                        style: TextStyle(
                            fontSize: 38, fontStyle: FontStyle.italic)),
                    Text('Things you are looking for and have found.',
                        style: TextStyle(color: muted))
                  ])),
              IconButton(
                  tooltip: 'Sort hunts',
                  onPressed: chooseSort,
                  icon: const Icon(Icons.sort_rounded)),
              IconButton(
                  tooltip:
                      reverse ? 'Use normal sort order' : 'Reverse sort order',
                  onPressed: () => setState(() => reverse = !reverse),
                  icon: Icon(reverse
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded)),
              IconButton(
                  tooltip: 'Grid view',
                  isSelected: showGrid,
                  onPressed: () => setState(() => showGrid = true),
                  icon: const Icon(Icons.grid_view_rounded)),
              IconButton(
                  tooltip: 'List view',
                  isSelected: !showGrid,
                  onPressed: () => setState(() => showGrid = false),
                  icon: const Icon(Icons.view_list_rounded))
            ])),
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
                onChanged: (value) => setState(() => q = value),
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search the hunt'))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: SegmentedButton<HuntFilter>(
            segments: HuntFilter.values
                .map((value) => ButtonSegment(
                      value: value,
                      label: Text(value.label),
                    ))
                .toList(),
            selected: {filter},
            onSelectionChanged: (value) => setState(() => filter = value.first),
          ),
        ),
        Expanded(
            child: RefreshIndicator(
                onRefresh: widget.refresh,
                child: sortedItems.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                        children: [
                            Empty(widget.items.isEmpty
                                ? 'What are you looking for?'
                                : 'No hunt items match your search.')
                          ])
                    : showGrid
                        ? GridView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: .68),
                            itemCount: sortedItems.length,
                            itemBuilder: (_, i) => HuntCard(
                                sortedItems[i], widget.stones, widget.refresh))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                            itemCount: sortedItems.length,
                            itemBuilder: (_, i) => HuntTile(sortedItems[i],
                                widget.stones, widget.refresh))))
      ]));
}

enum HuntSort {
  date('Date added'),
  az('A–Z'),
  priority('How badly I want it');

  const HuntSort(this.label);
  final String label;
}

enum HuntFilter {
  all('All'),
  searching('Not found'),
  found('Found');

  const HuntFilter(this.label);
  final String label;
}

class Profile extends StatelessWidget {
  const Profile(this.stones, this.hunts, {super.key});
  final List stones, hunts;

  Future<void> _editName(BuildContext context) async {
    final controller =
        TextEditingController(text: _nameNotifier.value);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration:
              const InputDecoration(hintText: 'Enter your name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      _nameNotifier.value = result;
      await _saveName(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar + name
            const CircleAvatar(
                radius: 34, child: Icon(Icons.person, size: 32)),
            const SizedBox(height: 10),
            ValueListenableBuilder<String>(
              valueListenable: _nameNotifier,
              builder: (_, name, __) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("$name's cabinet",
                      style: serif(22, weight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _editName(context),
                    child: Icon(Icons.edit_outlined,
                        size: 15, color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Stats(stones.length, hunts.length),
            const SizedBox(height: 32),
            // Theme picker
            Text('Appearance',
                style: TextStyle(
                    fontSize: 13, color: muted, letterSpacing: .8)),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: _themeNotifier,
              builder: (_, __) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _themes
                    .map((t) => Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          child: _ThemeCircle(
                            theme: t,
                            isSelected: _themeNotifier.value == t,
                            onTap: () {
                              _themeNotifier.value = t;
                              _saveTheme(t);
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 32),
            Text(
                'Private collection · No account needed',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted)),
          ],
        ),
      ),
    );
  }
}

class Stats extends StatelessWidget {
  const Stats(this.a, this.b, {super.key});
  final int a, b;
  @override
  Widget build(BuildContext c) => Container(
      padding: const EdgeInsets.all(18),
      decoration: dec(),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        stat('$a', 'stones'),
        stat('$b', 'hunt items'),
        stat('$a', 'stories')
      ]));
  Widget stat(String a, String b) => Column(children: [
        Text(a, style: TextStyle(fontSize: 24, color: accent)),
        Text(b, style: TextStyle(color: muted, fontSize: 11))
      ]);
}

class Heading extends StatelessWidget {
  const Heading(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext c) => Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 21, fontStyle: FontStyle.italic)));
}

class Empty extends StatelessWidget {
  const Empty(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext c) => Container(
      padding: const EdgeInsets.all(20),
      decoration: dec(),
      child: Text(text, style: TextStyle(color: muted)));
}

BoxDecoration dec() => BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(18),
    border: _themeNotifier.value.brightness == Brightness.light
        ? Border.all(color: muted.withValues(alpha: .15), width: 1)
        : null);

Future<bool> confirmStoneRemoval(
        BuildContext context, Map<String, dynamic> stone) async =>
    await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Remove stone?'),
              content: Text(
                  'Remove "${stone['name'] ?? 'this stone'}" and its memories from your collection?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style:
                      FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Remove'),
                ),
              ],
            )) ??
    false;

class StoneTile extends StatelessWidget {
  const StoneTile(this.s, this.refresh, {this.photoUrl, super.key});
  final Map<String, dynamic> s;
  final Future<void> Function() refresh;
  final String? photoUrl;
  @override
  Widget build(BuildContext c) => Card(
      color: card,
      child: ListTile(
          leading: photoUrl == null || photoUrl!.isEmpty
              ? CircleAvatar(
                  child: Icon(
                      s['favorite'] == true
                          ? Icons.favorite
                          : Icons.diamond_outlined,
                      color: accent))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(photoUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const CircleAvatar(
                          child: Icon(Icons.diamond_outlined)))),
          title: Text(s['name'] ?? 'Unnamed stone'),
          subtitle: Text(s['description'] ?? s['whyKept'] ?? 'No notes',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () =>
              Navigator.push(c, MaterialPageRoute(builder: (_) => Detail(s, refresh)))));
}

String? stonePhotoUrl(
    Map<String, dynamic> stone, List<Map<String, dynamic>> photos) {
  final id = stone['id'];
  final matches = photos.where((photo) => photo['stoneId'] == id).toList();
  if (matches.isEmpty) return null;
  return (matches.firstWhere((photo) => photo['primaryPhoto'] == true,
          orElse: () => matches.first))['imageUrl']
      ?.toString();
}

class StoneCard extends StatelessWidget {
  const StoneCard(this.stone, this.photos, this.refresh,
      {this.previewOnLongPress = false, super.key});
  final Map<String, dynamic> stone;
  final List<Map<String, dynamic>> photos;
  final Future<void> Function() refresh;
  final bool previewOnLongPress;

  @override
  Widget build(BuildContext c) {
    final imageUrl = stonePhotoUrl(stone, photos);
    return Card(
        color: card,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: () => Navigator.push(
                c, MaterialPageRoute(builder: (_) => Detail(stone, refresh))),
            onLongPress: previewOnLongPress
                ? () => showStonePreview(c, stone, imageUrl)
                : null,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: imageUrl == null
                      ? Container(
                          color: imageBg,
                          alignment: Alignment.center,
                          child: Icon(Icons.diamond_outlined,
                              size: 42, color: accent))
                      : Image.network(imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: imageBg))),
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(stone['name'] ?? 'Unnamed stone',
                      maxLines: 1, overflow: TextOverflow.ellipsis))
            ])));
  }
}

Future<void> showStonePreview(
        BuildContext context, Map<String, dynamic> stone, String? imageUrl) =>
    showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: .5),
        barrierDismissible: false,
        builder: (dialogContext) => _StonePreviewDialog(
              stone: stone,
              imageUrl: imageUrl,
              onDismiss: () => Navigator.pop(dialogContext),
            ));

class _StonePreviewDialog extends StatefulWidget {
  const _StonePreviewDialog(
      {required this.stone, required this.imageUrl, required this.onDismiss});
  final Map<String, dynamic> stone;
  final String? imageUrl;
  final VoidCallback onDismiss;

  @override
  State<_StonePreviewDialog> createState() => _StonePreviewDialogState();
}

class _StonePreviewDialogState extends State<_StonePreviewDialog>
    with TickerProviderStateMixin {
  // Entry / exit animation
  late final AnimationController _entry = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
  late final AnimationController _exit = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  late final Animation<double> _scale =
      CurvedAnimation(parent: _entry, curve: Curves.elasticOut);
  late final Animation<double> _fade =
      CurvedAnimation(parent: _entry, curve: Curves.easeOut);
  late final Animation<double> _exitScale = Tween<double>(begin: 1, end: 0.0)
      .animate(CurvedAnimation(parent: _exit, curve: Curves.easeInBack));
  late final Animation<double> _exitFade = Tween<double>(begin: 1, end: 0)
      .animate(CurvedAnimation(parent: _exit, curve: Curves.easeIn));

  // Key to access the flip state of the card
  final GlobalKey<_StoneFlipPreviewState> _flipKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _entry.forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    _exit.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    final flipState = _flipKey.currentState;
    // If card is showing its back, flip to front first
    if (flipState != null && flipState.isShowingBack) {
      await flipState.flipToFront();
    }
    // Then play shrink-back exit animation
    await _exit.forward();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: GestureDetector(
        onTap: _handleDismiss,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: .15),
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_entry, _exit]),
              builder: (_, child) {
                final entryDone = _entry.isCompleted;
                final scale = entryDone ? _exitScale.value : _scale.value;
                final fade = entryDone ? _exitFade.value : _fade.value;
                return FadeTransition(
                  opacity: AlwaysStoppedAnimation(fade),
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () {},
                child: StoneFlipPreview(
                    key: _flipKey,
                    stone: widget.stone,
                    imageUrl: widget.imageUrl),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StoneFlipPreview extends StatefulWidget {
  const StoneFlipPreview({required this.stone, required this.imageUrl, super.key});
  final Map<String, dynamic> stone;
  final String? imageUrl;

  @override
  State<StoneFlipPreview> createState() => _StoneFlipPreviewState();
}

class _StoneFlipPreviewState extends State<StoneFlipPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController flip = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 680));
  late final Animation<double> _flipCurved =
      CurvedAnimation(parent: flip, curve: Curves.easeInOutCubic);

  bool get isShowingBack => _flipCurved.value >= .5;

  /// Flips back to front and waits for completion.
  Future<void> flipToFront() => flip.reverse();

  @override
  void dispose() {
    flip.dispose();
    super.dispose();
  }

  void toggle() => flip.status == AnimationStatus.completed
      ? flip.reverse()
      : flip.forward();

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _flipCurved,
      builder: (_, __) {
        final v = _flipCurved.value;
        final showingBack = v >= .5;
        final angle = v * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .0012)
            ..rotateY(angle),
          child: GestureDetector(
            onTap: toggle,
            child: SizedBox(
              width: 300,
              height: 300,
              child: showingBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _StonePreviewBack(stone: widget.stone),
                    )
                  : _StonePreviewFront(
                      stone: widget.stone, imageUrl: widget.imageUrl),
            ),
          ),
        );
      });
}

class _StonePreviewFront extends StatelessWidget {
  const _StonePreviewFront({required this.stone, required this.imageUrl});
  final Map<String, dynamic> stone;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(fit: StackFit.expand, children: [
        // Background image or fallback
        imageUrl == null || imageUrl!.isEmpty
            ? Container(
                color: imageBg,
                child: Center(
                    child: Icon(Icons.diamond_outlined,
                        size: 80, color: accent)))
            : Image.network(imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: imageBg,
                    child: Center(
                        child: Icon(Icons.broken_image_outlined,
                            size: 64, color: muted)))),

        // Gradient overlay bottom
        DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.45, 1.0],
                    colors: [Colors.transparent, bg.withAlpha(0xf0)]))),

        // Subtle top shimmer
        DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                  accent.withAlpha(0x18),
                  Colors.transparent,
                  accent.withAlpha(0x08),
                ]))),

        // Name tile at bottom
        Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, bg.withAlpha(0xf5)]),
              ),
              child: Text(
                stone['name'] ?? 'Unnamed stone',
                style: const TextStyle(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    height: 1.2),
              ),
            )),
      ]),
    );
  }
}

class _StonePreviewBack extends StatelessWidget {
  const _StonePreviewBack({required this.stone});
  final Map<String, dynamic> stone;

  String get _description {
    if (stone['description']?.toString().isNotEmpty == true) {
      return stone['description'];
    }
    if (stone['whyKept']?.toString().isNotEmpty == true) {
      return stone['whyKept'];
    }
    return 'No description has been added yet.';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: accent.withValues(alpha: .2), width: 1),
        ),
        child: Stack(fit: StackFit.expand, children: [
          // Decorative background pattern
          Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    accent.withValues(alpha: .08),
                    Colors.transparent
                  ]),
                ),
              )),
          Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    accent.withValues(alpha: .06),
                    Colors.transparent
                  ]),
                ),
              )),

          // Card content
          Padding(
            padding: const EdgeInsets.all(28),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header: logo area
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: accent.withValues(alpha: .3), width: 1),
                      ),
                      child: Icon(Icons.diamond_outlined,
                          color: accent, size: 22),
                    ),
                    if (stone['favorite'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xffe91e63).withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xffe91e63)
                                  .withValues(alpha: .3),
                              width: 1),
                        ),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite,
                                  size: 12, color: Color(0xffe91e63)),
                              SizedBox(width: 5),
                              Text('Favorite',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xffe91e63)))
                            ]),
                      )
                  ]),

              const Spacer(),

              // Divider line
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    accent.withValues(alpha: .4),
                    Colors.transparent
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // Stone name
              Text(
                stone['name'] ?? 'Unnamed stone',
                style: const TextStyle(
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    height: 1.2),
              ),
              if (stone['type']?.toString().isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(
                  stone['type'],
                  style: TextStyle(
                      fontSize: 13, color: accent, letterSpacing: .6),
                )
              ],
              const SizedBox(height: 16),

              // Description
              Text(
                _description,
                style: TextStyle(
                    color: muted, height: 1.6, fontSize: 14),
                maxLines: 7,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              if (stone['color']?.toString().isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    stone['color'],
                    style: TextStyle(fontSize: 12, color: accent),
                  ),
                )
              ]
            ]),
          )
        ]),
      ),
    );
  }
}

class RecentStones extends StatelessWidget {
  const RecentStones(this.stones, this.photos, this.refresh, {super.key});
  final List<Map<String, dynamic>> stones, photos;
  final Future<void> Function() refresh;

  @override
  Widget build(BuildContext context) => Column(children: [
        SizedBox(
            height: 260,
            width: double.infinity,
            child: StoneCard(stones.first, photos, refresh)),
        if (stones.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
              height: 120,
              child: Row(children: [
                for (final stone in stones.skip(1))
                  Expanded(
                      child: Padding(
                          padding: EdgeInsets.only(
                              right: stone == stones.last ? 0 : 8),
                          child: StoneCard(stone, photos, refresh)))
              ]))
        ]
      ]);
}

class HuntTile extends StatelessWidget {
  const HuntTile(this.h, this.stones, this.refresh, {super.key});
  final Map<String, dynamic> h;
  final List<Map<String, dynamic>> stones;
  final Future<void> Function() refresh;
  Future<void> mark(BuildContext c) async {
    await setHuntFound(c, h, stones, refresh);
  }

  Future<void> delete(BuildContext c) async {
    final approved = await confirmHuntDelete(c, h['name'] ?? 'this hunt');
    if (!approved) return;
    await Api.remove('hunt-items', h['id']);
    await refresh();
  }

  @override
  Widget build(BuildContext c) => Card(
      color: card,
      child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
          leading: HuntImage(h['referenceImageUrl'], size: 52),
          title: Text(h['name'] ?? ''),
          subtitle: Text(
              h['status'] == 'FOUND'
                  ? 'FOUND'
                  : '${huntPriority(h)} · ${huntPriorityLabels[huntPriority(h) - 1]}\n${h['description'] ?? 'Still searching'}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          onTap: () => Navigator.push(
              c,
              MaterialPageRoute(
                  builder: (_) => HuntDetail(h, stones, refresh))),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
                tooltip: h['status'] == 'FOUND'
                    ? 'Mark as searching'
                    : 'Mark as found',
                onPressed: () => mark(c),
                icon: Icon(h['status'] == 'FOUND'
                    ? Icons.undo_rounded
                    : Icons.task_alt_rounded),
                color: accent),
            IconButton(
                tooltip: 'Delete hunt',
                onPressed: () => delete(c),
                icon: const Icon(Icons.delete_outline),
                color: Colors.redAccent)
          ])));
}

class HuntCard extends StatelessWidget {
  const HuntCard(this.h, this.stones, this.refresh, {super.key});
  final Map<String, dynamic> h;
  final List<Map<String, dynamic>> stones;
  final Future<void> Function() refresh;

  @override
  Widget build(BuildContext c) => Card(
      color: card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: () => Navigator.push(
              c,
              MaterialPageRoute(
                  builder: (_) => HuntDetail(h, stones, refresh))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Stack(fit: StackFit.expand, children: [
              HuntImage(h['referenceImageUrl']),
              if (h['status'] == 'FOUND')
                const Positioned(
                    top: 8,
                    right: 8,
                    child: Chip(
                        label: Text('FOUND'),
                        labelStyle: TextStyle(fontSize: 11),
                        visualDensity: VisualDensity.compact))
            ])),
            Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h['name'] ?? '',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                          '${huntPriority(h)} · ${huntPriorityLabels[huntPriority(h) - 1]}\n${h['description'] ?? 'Still searching'}',
                          style: TextStyle(color: muted, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis)
                    ]))
          ])));
}

class HuntImage extends StatelessWidget {
  const HuntImage(this.url, {this.size, super.key});
  final String? url;
  final double? size;

  @override
  Widget build(BuildContext c) {
    final fallback = Container(
        color: imageBg,
        alignment: Alignment.center,
        child: Icon(Icons.explore_outlined,
            color: accent, size: size == null ? 42 : 28));
    if (url == null || url!.isEmpty) {
      return size == null
          ? fallback
          : SizedBox(
              width: size,
              height: size,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(10), child: fallback));
    }
    final image = Image.network(url!,
        fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
    return size == null
        ? image
        : SizedBox(
            width: size,
            height: size,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(10), child: image));
  }
}

class HuntDetail extends StatefulWidget {
  const HuntDetail(this.hunt, this.stones, this.refresh, {super.key});
  final Map<String, dynamic> hunt;
  final List<Map<String, dynamic>> stones;
  final Future<void> Function() refresh;

  @override
  State<HuntDetail> createState() => _HuntDetailState();
}

class _HuntDetailState extends State<HuntDetail> {
  late Map<String, dynamic> hunt = Map.of(widget.hunt);

  Future<void> toggleFound() async {
    await setHuntFound(context, hunt, widget.stones, widget.refresh);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> delete() async {
    if (!await confirmHuntDelete(context, hunt['name'] ?? 'this hunt')) return;
    await Api.remove('hunt-items', hunt['id']);
    await widget.refresh();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext c) {
    final linkedStone = hunt['stone'];
    final linkedStoneName =
        linkedStone is Map ? linkedStone['name']?.toString() : null;
    return Scaffold(
        appBar: AppBar(title: const Text('Hunt details'), actions: [
          IconButton(
              tooltip: 'Edit hunt',
              onPressed: () async {
                final updated =
                    await huntForm(c, widget.refresh, initial: hunt);
                if (updated != null && mounted) setState(() => hunt = updated);
              },
              icon: const Icon(Icons.edit_outlined))
        ]),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(hunt['name'] ?? '',
                  style: const TextStyle(
                      fontSize: 32, fontStyle: FontStyle.italic)),
              const SizedBox(height: 18),
              AspectRatio(
                  aspectRatio: 1.25,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: HuntImage(hunt['referenceImageUrl']))),
              const SizedBox(height: 20),
              Text(
                  hunt['description']?.toString().isNotEmpty == true
                      ? hunt['description']
                      : 'No description yet.',
                  style: const TextStyle(fontSize: 16, height: 1.5)),
              if (hunt['status'] == 'FOUND' && linkedStone != null) ...[
                const SizedBox(height: 18),
                Container(
                    padding: const EdgeInsets.all(14),
                    decoration: dec(),
                    child: Text('Found as: ${linkedStoneName ?? 'stone'}',
                        style: TextStyle(color: accent)))
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                  onPressed: toggleFound,
                  icon: Icon(hunt['status'] == 'FOUND'
                      ? Icons.undo_rounded
                      : Icons.task_alt_rounded),
                  label: Text(hunt['status'] == 'FOUND'
                      ? 'Mark as searching'
                      : 'Mark found')),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent),
                  onPressed: delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete hunt'))
            ]));
  }
}

const huntPriorityLabels = [
  'lwk cute',
  'kinda want it',
  'erm I need this',
  'Guang Guang I NEED this 😭',
  'Hey.'
];

int huntPriority(Map<String, dynamic> hunt) =>
    ((hunt['priority'] as num?)?.toInt() ?? 3).clamp(1, 5);

Future<void> setHuntFound(BuildContext c, Map<String, dynamic> hunt,
    List<Map<String, dynamic>> stones, Future<void> Function() refresh) async {
  final isFound = hunt['status'] == 'FOUND';
  Map<String, dynamic> changes;
  if (isFound) {
    changes = {'status': 'SEARCHING', 'foundAt': null, 'stone': null};
  } else {
    final photoChoice =
        await chooseFoundPhoto(c, hunt['referenceImageUrl']?.toString());
    if (photoChoice == null) return;
    final rating = await chooseStoneRating(c);
    if (rating == null) return;
    final response = await http.post(Uri.parse('${Api.url}/api/stones'),
        headers: Api.headers,
        body: jsonEncode({
          'name': hunt['name'] ?? 'Found stone',
          'description': hunt['description'] ?? '',
          'whyKept': 'Found from The Hunt.',
          'acquisitionType': 'FOUND',
          'favorite': false,
          'rating': rating
        }));
    Api._check(response);
    final stone = Map<String, dynamic>.from(jsonDecode(response.body));
    String? imageUrl = photoChoice.referenceUrl;
    if (photoChoice.file != null)
      imageUrl = await Api.upload(photoChoice.file!);
    if (imageUrl != null && imageUrl.isNotEmpty) {
      await Api.save('stone-photos', {
        'stone': {'id': stone['id']},
        'imageUrl': imageUrl,
        'caption': '',
        'displayOrder': 0,
        'primaryPhoto': true
      });
    }
    changes = {
      'status': 'FOUND',
      'foundAt': DateTime.now().toIso8601String().substring(0, 10),
      'stone': {'id': stone['id']}
    };
  }
  final saved = Map<String, dynamic>.of(hunt)..addAll(changes);
  await Api.save('hunt-items', saved, id: hunt['id']);
  hunt.addAll(changes);
  await refresh();
}

class FoundPhotoChoice {
  const FoundPhotoChoice({this.file, this.referenceUrl});
  final XFile? file;
  final String? referenceUrl;
}

Future<int?> chooseStoneRating(BuildContext context) async {
  int? rating;
  return showModalBottomSheet<int>(
      context: context,
      isDismissible: false,
      builder: (sheetContext) => StatefulBuilder(
          builder: (_, setSheetState) => SafeArea(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('How much do you like this stone?',
                        style: TextStyle(
                            fontSize: 21, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 8),
                    Text(
                        'This is separate from how much you wanted to find it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted)),
                    const SizedBox(height: 16),
                    StarRating(
                        value: rating,
                        onChanged: (value) =>
                            setSheetState(() => rating = value)),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: rating == null
                            ? null
                            : () => Navigator.pop(sheetContext, rating),
                        child: const Text('Add to stones'))
                  ])))));
}

class StarRating extends StatelessWidget {
  const StarRating({this.value, this.onChanged, this.size = 30, super.key});
  final int? value;
  final ValueChanged<int>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final star = index + 1;
        final icon = Icon(
            star <= (value ?? 0)
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            color: accent,
            size: size);
        return onChanged == null
            ? icon
            : IconButton(
                tooltip: '$star stars',
                onPressed: () => onChanged!(star),
                icon: icon);
      }));
}

Future<FoundPhotoChoice?> chooseFoundPhoto(
    BuildContext context, String? referenceUrl) async {
  final picker = ImagePicker();
  final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const ListTile(
                title: Text('Add this stone to your collection'),
                subtitle: Text('Choose the photo to keep with it.')),
            if (referenceUrl != null && referenceUrl.isNotEmpty)
              ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('Use the hunt photo'),
                  onTap: () => Navigator.pop(sheetContext, 'reference')),
            ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take the actual stone photo'),
                onTap: () => Navigator.pop(sheetContext, 'camera')),
            ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose the actual stone photo'),
                onTap: () => Navigator.pop(sheetContext, 'gallery')),
            ListTile(
                leading: const Icon(Icons.skip_next_outlined),
                title: const Text('Add without a photo'),
                onTap: () => Navigator.pop(sheetContext, 'skip'))
          ])));
  if (choice == null) return null;
  if (choice == 'reference')
    return FoundPhotoChoice(referenceUrl: referenceUrl);
  if (choice == 'skip') return const FoundPhotoChoice();
  final file = await picker.pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 88);
  return file == null ? null : FoundPhotoChoice(file: file);
}

Future<bool> confirmHuntDelete(BuildContext c, String name) async =>
    await showDialog<bool>(
        context: c,
        builder: (x) => AlertDialog(
                title: const Text('Delete hunt?'),
                content: Text('Remove "$name" from The Hunt?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(x, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                      onPressed: () => Navigator.pop(x, true),
                      child: const Text('Delete'))
                ])) ??
    false;

class Detail extends StatefulWidget {
  const Detail(this.stone, this.refresh, {super.key});
  final Map<String, dynamic> stone;
  final Future<void> Function() refresh;
  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  List<Map<String, dynamic>> memories = [], photos = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await Future.wait([
      Api.getAll('memories?stoneId=${widget.stone['id']}'),
      Api.getAll('stone-photos?stoneId=${widget.stone['id']}')
    ]);
    if (mounted)
      setState(() {
        memories = r[0];
        photos = r[1];
        loading = false;
      });
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: Text(widget.stone['name']), actions: [
        IconButton(
            onPressed: () =>
                stoneForm(c, widget.refresh, initial: widget.stone),
            icon: const Icon(Icons.edit)),
        IconButton(
            onPressed: () async {
              await Api.remove('stones', widget.stone['id']);
              await widget.refresh();
              if (mounted) Navigator.pop(c);
            },
            icon: const Icon(Icons.delete_outline))
      ]),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(20), children: [
              if (photos.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    photos.first['imageUrl']?.toString() ?? '',
                    width: double.infinity,
                    height: 280,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 280,
                      color: card,
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image_outlined,
                          color: muted, size: 46),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (widget.stone['rating'] != null) ...[
                Text('How much I like it',
                    style: TextStyle(color: muted)),
                const SizedBox(height: 4),
                StarRating(
                    value: (widget.stone['rating'] as num).toInt(), size: 26),
                const SizedBox(height: 16),
              ],
              ...photos.map((p) => ListTile(
                  leading: const Icon(Icons.image),
                  title: Text(p['caption'] ?? p['imageUrl']),
                  trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await Api.remove('stone-photos', p['id']);
                        load();
                      }))),
              OutlinedButton.icon(
                  onPressed: () => recordForm(
                      c,
                      'Add photo URL',
                      'Image URL',
                      'Caption',
                      (a, b) => Api.save('stone-photos', {
                            'stone': {'id': widget.stone['id']},
                            'imageUrl': a,
                            'caption': b,
                            'displayOrder': 0,
                            'primaryPhoto': false
                          }).then((_) => load())),
                  icon: const Icon(Icons.add_link),
                  label: const Text('Add photo link')),
              const Heading('Memories'),
              if (memories.isEmpty)
                const Empty('No memories yet.')
              else
                ...memories.map((m) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: dec(),
                    child: ListTile(
                        contentPadding:
                            const EdgeInsets.fromLTRB(18, 10, 8, 10),
                        leading: Icon(Icons.auto_stories_outlined,
                            color: accent),
                        title: Text(m['title']),
                        subtitle: m['content']?.toString().isNotEmpty == true
                            ? Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(m['content'],
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis),
                              )
                            : null,
                        trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await Api.remove('memories', m['id']);
                              load();
                            })))),
              FilledButton.icon(
                  onPressed: () => memoryForm(c, widget.stone['id'], load),
                  icon: const Icon(Icons.auto_stories_outlined),
                  label: const Text('Add a memory'))
            ]));
}

class StoneWizard extends StatefulWidget {
  const StoneWizard({super.key, required this.onSaved});
  final Future<void> Function() onSaved;
  @override
  State<StoneWizard> createState() => _StoneWizardState();
}

class _StoneWizardState extends State<StoneWizard> {
  final picker = ImagePicker(),
      name = TextEditingController(),
      description = TextEditingController(),
      why = TextEditingController();
  int step = 0;
  int? rating;
  XFile? photo;
  bool favorite = false, saving = false;
  String kind = 'FOUND';
  Future<void> pick(ImageSource source) async {
    final file = await picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (file != null && mounted)
      setState(() {
        photo = file;
        step = 1;
      });
  }

  Future<void> next() async {
    if (step == 0 && photo == null) {
      notice(context, 'Choose a photo before creating this stone.');
      return;
    }
    if (step == 1 && name.text.trim().isEmpty) {
      notice(context, 'Give this stone a name first.');
      return;
    }
    if (step == 3 && rating == null) {
      notice(context, 'Choose how much you like this stone.');
      return;
    }
    if (step < 3) {
      setState(() => step++);
      return;
    }
    setState(() => saving = true);
    try {
      final stone = <String, dynamic>{
        'name': name.text.trim(),
        'description': description.text.trim(),
        'whyKept': why.text.trim(),
        'acquisitionType': kind,
        'favorite': favorite,
        'rating': rating
      };
      final response = await http.post(Uri.parse('${Api.url}/api/stones'),
          headers: Api.headers, body: jsonEncode(stone));
      Api._check(response);
      final id = jsonDecode(response.body)['id'];
      if (photo != null) {
        final imageUrl = await Api.upload(photo!);
        await Api.save('stone-photos', {
          'stone': {'id': id},
          'imageUrl': imageUrl,
          'caption': '',
          'displayOrder': 0,
          'primaryPhoto': true
        });
      }
      await widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) notice(context, e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(step == 0 ? 'New stone' : 'New stone · ${step + 1} of 4'),
          leading: IconButton(
              tooltip: 'Cancel creating stone',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context)),
          actions: step == 0
              ? null
              : [
                  IconButton(
                      tooltip: 'Previous step',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => step--))
                ]),
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(value: (step + 1) / 4),
                    const SizedBox(height: 32),
                    Expanded(child: _body()),
                    FilledButton(
                        onPressed: saving ? null : next,
                        child: Text(saving
                            ? 'Saving your stone…'
                            : step == 3
                                ? 'Save stone'
                                : 'Continue'))
                  ]))));
  Widget _body() {
    if (step == 0)
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Begin with a photograph.',
            style: TextStyle(fontSize: 29, fontStyle: FontStyle.italic)),
        const SizedBox(height: 9),
        Text(
            'Take one right now, or choose something already in your gallery.',
            style: TextStyle(color: muted)),
        const SizedBox(height: 30),
        if (photo != null)
          ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FutureBuilder(
                  future: photo!.readAsBytes(),
                  builder: (context, snapshot) => snapshot.hasData
                      ? Image.memory(snapshot.data!,
                          height: 260, fit: BoxFit.cover)
                      : const SizedBox(
                          height: 260,
                          child: Center(child: CircularProgressIndicator()))))
        else
          Container(
              height: 260,
              decoration: dec(),
              child: Icon(Icons.add_a_photo_outlined,
                  size: 58, color: accent)),
        const SizedBox(height: 20),
        OutlinedButton.icon(
            onPressed: () => pick(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Take photo now')),
        const SizedBox(height: 12),
        FilledButton.icon(
            onPressed: () => pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose from gallery'))
      ]);
    if (step == 1)
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('What shall we call it?',
            style: TextStyle(fontSize: 29, fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
        Text(
            'It can be a mineral name or a name that only makes sense to you.',
            style: TextStyle(color: muted)),
        const SizedBox(height: 25),
        TextField(
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
                labelText: 'Stone name', hintText: 'The pink one'))
      ]);
    if (step == 2)
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tell its little story.',
            style: TextStyle(fontSize: 29, fontStyle: FontStyle.italic)),
        const SizedBox(height: 24),
        TextField(
            controller: description,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 5,
            decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Its colour, texture, or whatever you notice.'))
      ]);
    return ListView(children: [
      const Text('One last thing.',
          style: TextStyle(fontSize: 29, fontStyle: FontStyle.italic)),
      const SizedBox(height: 22),
      TextField(
          controller: why,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Why did you keep it?')),
      const SizedBox(height: 18),
      DropdownButtonFormField(
          value: kind,
          decoration:
              const InputDecoration(labelText: 'How did it come to you?'),
          items: ['FOUND', 'BOUGHT', 'GIFT', 'OTHER']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => kind = v!)),
      SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Make it a favorite'),
          subtitle: const Text('It will appear on your home page.'),
          value: favorite,
          onChanged: (v) => setState(() => favorite = v)),
      const SizedBox(height: 14),
      const Text('How much do you like this stone?',
          style: TextStyle(fontSize: 17)),
      const SizedBox(height: 6),
      StarRating(
          value: rating, onChanged: (value) => setState(() => rating = value))
    ]);
  }
}

void stoneForm(BuildContext c, Future<void> Function() done,
    {Map<String, dynamic>? initial}) {
  if (initial == null) {
    Navigator.push(
        c, MaterialPageRoute(builder: (_) => StoneWizard(onSaved: done)));
    return;
  }
  final n = TextEditingController(text: initial?['name'] ?? ''),
      d = TextEditingController(text: initial?['description'] ?? ''),
      w = TextEditingController(text: initial?['whyKept'] ?? '');
  bool favorite = initial?['favorite'] == true;
  int? rating = (initial?['rating'] as num?)?.toInt();
  String kind = initial?['acquisitionType'] ?? 'FOUND';
  showDialog(
      context: c,
      builder: (x) => StatefulBuilder(
          builder: (x, set) => AlertDialog(
                  title: Text(initial == null ? 'New stone' : 'Edit stone'),
                  content: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: n,
                        decoration: const InputDecoration(labelText: 'Name')),
                    TextField(
                        controller: d,
                        decoration:
                            const InputDecoration(labelText: 'Description')),
                    TextField(
                        controller: w,
                        decoration:
                            const InputDecoration(labelText: 'Why keep it?')),
                    DropdownButtonFormField(
                        value: kind,
                        items: ['FOUND', 'BOUGHT', 'GIFT', 'OTHER']
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => set(() => kind = v!)),
                    SwitchListTile(
                        title: const Text('Favorite'),
                        value: favorite,
                        onChanged: (v) => set(() => favorite = v)),
                    const SizedBox(height: 8),
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('How much do you like it?')),
                    StarRating(
                        value: rating,
                        onChanged: (value) => set(() => rating = value))
                  ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(x),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () async {
                          if (n.text.trim().isEmpty) return;
                          try {
                            await Api.save(
                                'stones',
                                {
                                  'name': n.text.trim(),
                                  'description': d.text.trim(),
                                  'whyKept': w.text.trim(),
                                  'acquisitionType': kind,
                                  'favorite': favorite,
                                  'rating': rating
                                },
                                id: initial?['id']);
                            await done();
                            if (x.mounted) Navigator.pop(x);
                          } catch (e) {
                            notice(c, e);
                          }
                        },
                        child: const Text('Save'))
                  ])));
}

class HuntWizard extends StatefulWidget {
  const HuntWizard({super.key, required this.onSaved, this.initial});
  final Future<void> Function() onSaved;
  final Map<String, dynamic>? initial;
  @override
  State<HuntWizard> createState() => _HuntWizardState();
}

class _HuntWizardState extends State<HuntWizard> {
  final picker = ImagePicker();
  final name = TextEditingController();
  final notes = TextEditingController();
  int step = 0;
  int? priority;
  XFile? photo;
  String? existingImageUrl;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    name.text = widget.initial?['name'] ?? '';
    notes.text = widget.initial?['description'] ?? '';
    existingImageUrl = widget.initial?['referenceImageUrl'];
    priority = (widget.initial?['priority'] as num?)?.toInt();
  }

  Future<void> pick(ImageSource source) async {
    final selected = await picker.pickImage(source: source, imageQuality: 88);
    if (selected != null && mounted)
      setState(() {
        photo = selected;
        step = 1;
      });
  }

  Future<void> next() async {
    if (step == 1 && name.text.trim().isEmpty) {
      notice(context, 'What are you hoping to find?');
      return;
    }
    if (step == 3 && priority == null) {
      notice(context, 'Choose how much you want to find it.');
      return;
    }
    if (step < 3) {
      setState(() => step++);
      return;
    }
    setState(() => saving = true);
    try {
      String? imageUrl = existingImageUrl;
      if (photo != null) imageUrl = await Api.upload(photo!);
      final saved = Map<String, dynamic>.of(widget.initial ?? {})
        ..addAll({
          'name': name.text.trim(),
          'description': notes.text.trim(),
          'referenceImageUrl': imageUrl,
          'priority': priority,
          'status': widget.initial?['status'] ?? 'SEARCHING'
        });
      await Api.save('hunt-items', saved, id: widget.initial?['id']);
      await widget.onSaved();
      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      if (mounted) notice(context, e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(widget.initial == null
              ? 'New hunt · ${step + 1} of 4'
              : 'Edit hunt · ${step + 1} of 4'),
          leading: IconButton(
              tooltip: 'Cancel creating hunt',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context)),
          actions: step == 0
              ? null
              : [
                  IconButton(
                      tooltip: 'Previous step',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => step--))
                ]),
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(value: (step + 1) / 4),
                    const SizedBox(height: 32),
                    Expanded(child: body()),
                    FilledButton(
                        onPressed: saving ? null : next,
                        child: Text(saving
                            ? 'Saving your hunt…'
                            : step == 3
                                ? 'Save hunt'
                                : 'Continue'))
                  ]))));

  Widget body() {
    if (step == 0)
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Start with a little inspiration.',
            style: TextStyle(fontSize: 29, fontStyle: FontStyle.italic)),
        const SizedBox(height: 9),
        Text('Take a photo, choose a reference, or skip this for now.',
            style: TextStyle(color: muted)),
        const SizedBox(height: 30),
        if (photo != null)
          ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FutureBuilder(
                  future: photo!.readAsBytes(),
                  builder: (context, snapshot) => snapshot.hasData
                      ? Image.memory(snapshot.data!,
                          height: 250, fit: BoxFit.cover)
                      : const SizedBox(
                          height: 250,
                          child: Center(child: CircularProgressIndicator()))))
        else
          Container(
              height: 250,
              decoration: dec(),
              child: Icon(Icons.auto_awesome, size: 58, color: accent)),
        const SizedBox(height: 20),
        OutlinedButton.icon(
            onPressed: () => pick(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Take photo now')),
        const SizedBox(height: 12),
        FilledButton.icon(
            onPressed: () => pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose from gallery')),
        TextButton(
            onPressed: () => setState(() => step = 1),
            child: const Text('Skip photo for now'))
      ]);
    if (step == 1)
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('What are you looking for?',
            style: TextStyle(fontSize: 29, fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
        Text(
            'It can be specific, strange, or simply a colour you want to find.',
            style: TextStyle(color: muted)),
        const SizedBox(height: 25),
        TextField(
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Hunt item', hintText: 'A really colourful opal'))
      ]);
    if (step == 2)
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('What makes it special?',
            style: TextStyle(fontSize: 29, fontStyle: FontStyle.italic)),
        const SizedBox(height: 24),
        TextField(
            controller: notes,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 6,
            decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Colour, shape, where you might find it…'))
      ]);
    return ListView(children: [
      const Text('How badly do you want it?',
          style: TextStyle(fontSize: 29, fontStyle: FontStyle.italic)),
      const SizedBox(height: 10),
      Text('This puts your most wanted finds first.',
          style: TextStyle(color: muted)),
      const SizedBox(height: 18),
      ...List.generate(
          5,
          (i) => RadioListTile<int>(
              contentPadding: EdgeInsets.zero,
              value: i + 1,
              groupValue: priority,
              title: Text(huntPriorityLabels[i]),
              onChanged: (value) => setState(() => priority = value!)))
    ]);
  }
}

Future<Map<String, dynamic>?> huntForm(
        BuildContext c, Future<void> Function() done,
        {Map<String, dynamic>? initial}) =>
    Navigator.push<Map<String, dynamic>>(
        c,
        MaterialPageRoute(
            builder: (_) => HuntWizard(onSaved: done, initial: initial)));
void recordForm(BuildContext c, String title, String one, String two,
    Future<void> Function(String, String) save) {
  final a = TextEditingController(), b = TextEditingController();
  showDialog(
      context: c,
      builder: (x) => AlertDialog(
              title: Text(title),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: a, decoration: InputDecoration(labelText: one)),
                TextField(
                    controller: b,
                    decoration: InputDecoration(labelText: two),
                    maxLines: 3)
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(x),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () async {
                      if (a.text.trim().isEmpty) return;
                      try {
                        await save(a.text.trim(), b.text.trim());
                        if (x.mounted) Navigator.pop(x);
                      } catch (e) {
                        notice(c, e);
                      }
                    },
                    child: const Text('Save'))
              ]));
}

Future<void> memoryForm(BuildContext context, dynamic stoneId,
    Future<void> Function() onSaved) async {
  final title = TextEditingController();
  final story = TextEditingController();
  var occurredAt = DateTime.now();
  var saving = false;
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
          builder: (_, setSheetState) => Padding(
                padding: EdgeInsets.only(
                    top: 80,
                    left: 12,
                    right: 12,
                    bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: accent.withValues(alpha: .25)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          const Expanded(
                              child: Text('Capture a memory',
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontStyle: FontStyle.italic))),
                          IconButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close))
                        ]),
                        Text('Give this stone a moment to hold onto.',
                            style: TextStyle(color: muted)),
                        const SizedBox(height: 24),
                        TextField(
                          controller: title,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'A short title',
                            hintText: 'The day I found it',
                            prefixIcon: Icon(Icons.title),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: story,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'What happened?',
                            hintText:
                                'Write the little details you want to remember.',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                                    final selected = await showDatePicker(
                                        context: sheetContext,
                                        initialDate: occurredAt,
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime.now());
                                    if (selected != null) {
                                      setSheetState(
                                          () => occurredAt = selected);
                                    }
                                  },
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                                'When: ${occurredAt.year}-${occurredAt.month.toString().padLeft(2, '0')}-${occurredAt.day.toString().padLeft(2, '0')}')),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                                    if (title.text.trim().isEmpty) {
                                      notice(sheetContext,
                                          'Give this memory a title.');
                                      return;
                                    }
                                    setSheetState(() => saving = true);
                                    try {
                                      await Api.save('memories', {
                                        'stone': {'id': stoneId},
                                        'title': title.text.trim(),
                                        'content': story.text.trim(),
                                        'occurredAt': occurredAt
                                            .toIso8601String()
                                            .split('T')
                                            .first,
                                      });
                                      await onSaved();
                                      if (sheetContext.mounted) {
                                        Navigator.pop(sheetContext);
                                      }
                                    } catch (e) {
                                      if (sheetContext.mounted)
                                        notice(sheetContext, e);
                                    } finally {
                                      if (sheetContext.mounted) {
                                        setSheetState(() => saving = false);
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.auto_stories_outlined),
                            label: Text(saving ? 'Saving…' : 'Save memory')),
                      ],
                    ),
                  ),
                ),
              )));
}

void notice(BuildContext c, Object e) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('$e')));

// ── Theme picker UI ──────────────────────────────────────────────────────────

class _ThemeCircle extends StatelessWidget {
  const _ThemeCircle(
      {required this.theme,
      required this.isSelected,
      required this.onTap});
  final LithaTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? theme.accent
                    : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: theme.accent.withValues(alpha: .35),
                          blurRadius: 12,
                          spreadRadius: 1)
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: CustomPaint(
                  painter:
                      _HalfCirclePainter(theme.circle1, theme.circle2),
                  size: const Size(54, 54),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? theme.accent : muted,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            child: Text(theme.name),
          ),
        ],
      ),
    );
  }
}

class _HalfCirclePainter extends CustomPainter {
  const _HalfCirclePainter(this.left, this.right);
  final Color left, right;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Right half
    canvas.drawRect(
        Rect.fromLTWH(w / 2, 0, w / 2, h), Paint()..color = right);
    // Left half
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w / 2, h), Paint()..color = left);
    // Thin divider line
    canvas.drawLine(
        Offset(w / 2, 0),
        Offset(w / 2, h),
        Paint()
          ..color = Colors.white.withValues(alpha: .25)
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant _HalfCirclePainter old) =>
      old.left != left || old.right != right;
}

// ── Faceted gem swatch ───────────────────────────────────────────────────────
class FacetedSwatch extends StatelessWidget {
  const FacetedSwatch({
    required this.width,
    required this.height,
    this.imageUrl,
    this.fallbackColor,
    this.child,
    super.key,
  });
  final double width, height;
  final String? imageUrl;
  final Color? fallbackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final fill = fallbackColor ?? imageBg;
    Widget content = imageUrl != null && imageUrl!.isNotEmpty
        ? Image.network(imageUrl!,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(width: width, height: height, color: fill))
        : Container(
            width: width,
            height: height,
            color: fill,
            child: child ??
                Center(
                    child: Icon(Icons.diamond_outlined,
                        color: accent.withValues(alpha: .5),
                        size: width * .35)));
    return ClipPath(
      clipper: _GemClipper(),
      child: Stack(children: [
        SizedBox(width: width, height: height, child: content),
        // Light sheen overlay
        Positioned.fill(
            child: DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                      Colors.white.withValues(alpha: .10),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                        stops: const [0, .45, 1])))),
      ]),
    );
  }
}

class _GemClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final w = s.width;
    final h = s.height;
    return Path()
      ..moveTo(w * .18, 0)
      ..lineTo(w * .82, 0)
      ..lineTo(w, h * .22)
      ..lineTo(w, h * .78)
      ..lineTo(w * .82, h)
      ..lineTo(w * .12, h)
      ..lineTo(0, h * .78)
      ..lineTo(0, h * .22)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ── Hero frame (bordered panel with gradient wash) ────────────────────────────
class HeroFrame extends StatelessWidget {
  const HeroFrame({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: .18), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: .07),
            _themeNotifier.value.card,
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(children: [
          child,
          // Sheen overlay
          Positioned.fill(
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                        Colors.white.withValues(alpha: .04),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                          stops: const [0, .4, 1])))),
        ]),
      ),
    );
  }
}

// ── Ornamental diamond divider ────────────────────────────────────────────────
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final lineColor = accent.withValues(alpha: .28);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
              child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.transparent, lineColor])))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('◆',
                  style: TextStyle(color: accent, fontSize: 9))),
          Expanded(
              child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [lineColor, Colors.transparent])))),
        ],
      ),
    );
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  static const facts = [
    'Every stone has been somewhere before it reached you.',
    'Your collection is a tiny museum of moments.',
    'A stone can hold a memory better than a photograph.',
    'The Hunt keeps the little things worth looking for close.',
    'There is no wrong reason to keep a beautiful thing.'
  ];
  late final AnimationController pulse;
  late final AnimationController glowMotion;
  late final Timer factTimer;
  late int factIndex;

  @override
  void initState() {
    super.initState();
    factIndex = DateTime.now().millisecondsSinceEpoch % facts.length;
    pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    glowMotion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
    factTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => factIndex = (factIndex + 1) % facts.length);
    });
  }

  @override
  void dispose() {
    pulse.dispose();
    glowMotion.dispose();
    factTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(child: EdgeAura(animation: glowMotion)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 56),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  AnimatedBuilder(
                    animation: pulse,
                    builder: (_, child) => Transform.scale(
                      scale: .96 + (pulse.value * .04),
                      child: child,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        'src/img/icon.png',
                        width: 184.8,
                        height: 132,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Litha',
                    style: TextStyle(fontSize: 32, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Opening your little museum',
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const Spacer(flex: 3),
                  Icon(Icons.auto_awesome, size: 18, color: accent),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    child: Text(
                      facts[factIndex],
                      key: ValueKey(factIndex),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class EdgeAura extends StatelessWidget {
  const EdgeAura({required this.animation, super.key});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _EdgeAuraPainter(animation),
        size: Size.infinite,
      );
}

class _EdgeAuraPainter extends CustomPainter {
  _EdgeAuraPainter(this.animation) : super(repaint: animation);
  final Animation<double> animation;

  // Reduced segment count – enough for smooth waves, cheap to compute.
  static const _kSegments = 80;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.save();
    canvas.clipRect(bounds);

    // Background radial vignette (single rect draw, free).
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.15,
          colors: [Color(0xff09070d), bg],
          stops: const [0, .72],
        ).createShader(bounds),
    );

    final phase = math.sin(animation.value * math.pi * 2) * math.pi * 1.4;

    // Pre-compute geometry & intensity once per frame.
    final starts = List<Offset>.filled(_kSegments, Offset.zero);
    final ends = List<Offset>.filled(_kSegments, Offset.zero);
    final intensities = List<double>.filled(_kSegments, 0);
    for (var i = 0; i < _kSegments; i++) {
      starts[i] = _pointOnPerimeter(i / _kSegments, size);
      ends[i] = _pointOnPerimeter((i + 1) / _kSegments, size);
      intensities[i] = _intensityAt(i / _kSegments, phase);
    }

    // --- Feather layer (wide, soft glow) ---
    // One saveLayer + ImageFilter replaces hundreds of MaskFilter.blur calls.
    canvas.saveLayer(
      bounds,
      Paint()
        ..imageFilter = ImageFilter.blur(sigmaX: 28, sigmaY: 28,
            tileMode: TileMode.decal),
    );
    final featherPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _kSegments; i++) {
      final hue = 268.0 + (intensities[i] * 45);
      featherPaint
        ..strokeWidth = 48 + (intensities[i] * 44)
        ..color = HSLColor.fromAHSL(
                .18 + (intensities[i] * .32), hue, .76, .56)
            .toColor();
      canvas.drawLine(starts[i], ends[i], featherPaint);
    }
    canvas.restore(); // applies the blur over the whole feather layer

    // --- Glow layer (narrower, brighter core) ---
    canvas.saveLayer(
      bounds,
      Paint()
        ..imageFilter = ImageFilter.blur(sigmaX: 10, sigmaY: 10,
            tileMode: TileMode.decal),
    );
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _kSegments; i++) {
      final hue = 268.0 + (intensities[i] * 45);
      glowPaint
        ..strokeWidth = 14 + (intensities[i] * 22)
        ..color = HSLColor.fromAHSL(
                .55 + (intensities[i] * .35), hue, .78, .62)
            .toColor();
      canvas.drawLine(starts[i], ends[i], glowPaint);
    }
    canvas.restore(); // applies the blur over the glow layer

    canvas.restore(); // clipRect
  }

  double _intensityAt(double position, double phase) {
    final angle = position * math.pi * 2;
    final waves = (.22 * math.sin(angle + phase)) +
        (.16 * math.sin((angle * 3) - (phase * 1.7))) +
        (.11 * math.sin((angle * 9) + (phase * 2.4)));
    return ((waves + .49) / .98).clamp(0.0, 1.0);
  }

  Offset _pointOnPerimeter(double position, Size size) {
    final radius = math.min(46.0, size.shortestSide / 5);
    final horizontal = size.width - (radius * 2);
    final vertical = size.height - (radius * 2);
    final corner = math.pi * radius / 2;
    final perimeter = (horizontal * 2) + (vertical * 2) + (corner * 4);
    var distance = (position % 1) * perimeter;

    if (distance <= horizontal) return Offset(radius + distance, 0);
    distance -= horizontal;
    if (distance <= corner) {
      return _corner(Offset(size.width - radius, radius), -math.pi / 2,
          distance / corner, radius);
    }
    distance -= corner;
    if (distance <= vertical) return Offset(size.width, radius + distance);
    distance -= vertical;
    if (distance <= corner) {
      return _corner(
          Offset(size.width - radius, size.height - radius), 0,
          distance / corner, radius);
    }
    distance -= corner;
    if (distance <= horizontal) {
      return Offset(size.width - radius - distance, size.height);
    }
    distance -= horizontal;
    if (distance <= corner) {
      return _corner(Offset(radius, size.height - radius), math.pi / 2,
          distance / corner, radius);
    }
    distance -= corner;
    if (distance <= vertical) {
      return Offset(0, size.height - radius - distance);
    }
    distance -= vertical;
    return _corner(Offset(radius, radius), math.pi, distance / corner, radius);
  }

  Offset _corner(Offset center, double startAngle, double progress, double r) {
    final angle = startAngle + ((math.pi / 2) * progress);
    return center + Offset(math.cos(angle) * r, math.sin(angle) * r);
  }

  @override
  bool shouldRepaint(covariant _EdgeAuraPainter oldDelegate) => false;
}

class Offline extends StatelessWidget {
  const Offline(this.error, this.retry, {super.key});
  final String error;
  final Future<void> Function() retry;
  @override
  Widget build(BuildContext c) => Center(
      child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off, size: 40, color: accent),
            const SizedBox(height: 12),
            const Text('Cannot reach the API'),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(color: muted)),
            FilledButton(onPressed: retry, child: const Text('Retry'))
          ])));
}
