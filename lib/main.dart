import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'dart:math';
import 'components/yapay_zeka_yilani.dart';
import 'components/snake.dart';
import 'components/yem.dart';
import 'components/tas.dart';

import 'dart:ui'; // Bulanıklık (ImageFilter) efekti için gerekli
import 'package:flame/game.dart'; // GameWidget için gerekli (Zaten vardır ama kontrol et)

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnaMenu(),
    ),
  );
}

// --- 1. ANA MENÜ TASARIMI ---
// --- 1. ANA MENÜ TASARIMI (GÜNCELLENDİ: BULANIK ARKA PLAN EFECTİ) ---
class AnaMenu extends StatefulWidget {
  @override
  _AnaMenuState createState() => _AnaMenuState();
}

class _AnaMenuState extends State<AnaMenu> {
  bool oyunBasladi = false;
  String oyuncuAdi = "Oyuncu";
  TextEditingController isimKontrolcusu = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Eğer butona basıldıysa Flame oyun motorunu tam ekran başlat
    if (oyunBasladi) {
      return Scaffold(
        body: GameWidget(
          game: SnakeGame(oyuncuAdi: oyuncuAdi),
          overlayBuilderMap: {
            'GameOver': (context, SnakeGame game) => GameOverMenu(game: game),
          },
        ),
      );
    }

    // Oyun henüz başlamadıysa fiyakalı, bulanık arka planlı giriş ekranını göster
    return Scaffold(
      backgroundColor: Colors.black, // Formun dışında kalan şeritler için siyah
      body: Stack(
        // ÜST ÜSTE BİNMİŞ KATMANLAR
        fit: StackFit.expand, // Stack'i ekranı kaplayacak şekilde zorla
        children: [
          // 1. KATMAN (EN ALT): OYUNUN ARKA PLAN ÖNİZLEMESİ
          GameWidget(
            game: SnakeGame(oyuncuAdi: ""), // Giriş ekranında henüz isme gerek yok, boş bırak
            // overlays ve overlayBuilderMap'i burada kullanmıyoruz, sadece haritayı göster
          ),

          // 2. KATMAN (ORTA): BULANIKLIK EFECTİ (FROSTED GLASS)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Bulanıklık miktarı
            child: Container(
              color: Colors.black.withOpacity(0.4), // Bulanıklığı daha belirgin yapmak için yarı saydam siyah katman
            ),
          ),

          // 3. KATMAN (EN ÜST): GİRİŞ FORMU
          Center(
            child: Container(
              padding: EdgeInsets.all(30),
              width: 350,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7), // Formun arkasını yarı saydam siyah yap
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "SNAKE DUEL AI",
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text("İnsan vs Yapay Zeka",
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  SizedBox(height: 30),
                  TextField(
                    controller: isimKontrolcusu,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Savaşçı Adın",
                      labelStyle: TextStyle(color: Colors.green),
                      prefixIcon: Icon(Icons.person, color: Colors.green),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green, width: 2)),
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() {
                        if (isimKontrolcusu.text.isNotEmpty) {
                          oyuncuAdi = isimKontrolcusu.text;
                        }
                        oyunBasladi = true; // Oyunu başlat tetikleyicisi
                      });
                    },
                    child: Text("OYUNA BAŞLA",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// --- 2. YENİ ŞIK OYUN BİTTİ EKRANI (OVERLAY) ---
class GameOverMenu extends StatelessWidget {
  final SnakeGame game;
  const GameOverMenu({required this.game});

  @override
  Widget build(BuildContext context) {
    // Kimin kazandığına göre renkleri ayarlıyoruz (Sen kazanırsan yeşil, AI kazanırsa kırmızı)
    bool senKazandin = game.kazanan == game.oyuncuAdi;
    Color temaRengi = senKazandin ? Colors.green : Colors.red;

    return Center(
      child: Container(
        padding: EdgeInsets.all(40),
        width: 400,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85), // Yarı saydam arka plan
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: temaRengi, width: 3),
          boxShadow: [BoxShadow(color: temaRengi.withOpacity(0.4), blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "OYUN BİTTİ",
              style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            SizedBox(height: 15),
            Text(
              "KAZANAN:",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            Text(
              game.kazanan.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(color: temaRengi, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            
            // SKOR TABLOSU
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(game.oyuncuAdi, style: TextStyle(color: Colors.white70, fontSize: 16)),
                    Text("${game.oyuncuSkoru}", style: TextStyle(color: Colors.green, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(width: 2, height: 40, color: Colors.white24), // Araya çizgi
                Column(
                  children: [
                    Text("Yapay Zeka", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    Text("${game.aiSkoru}", style: TextStyle(color: Colors.red, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 40),

            // YENİDEN BAŞLATMA BUTONU
            ElevatedButton.icon(
              icon: Icon(Icons.refresh, color: Colors.black),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                // Oyunu sıfırlayıp ana menüye geri döndürür
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => AnaMenu())
                );
              },
              label: Text("ANA MENÜYE DÖN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            )
          ],
        ),
      ),
    );
  }
}

// --- 3. ANA OYUN MOTORU ---
class SnakeGame extends FlameGame with KeyboardEvents {
  final String oyuncuAdi;
  SnakeGame({required this.oyuncuAdi});

  final double hucreBoyutu = 20.0;
  late OyuncuYilani oyuncu;
  late Yem yem;
  late YapayZekaYilani yapayZeka;

  bool oyunBitti = false;
  String kazanan = "";

  int yatayKareSayisi = 0;
  int dikeyKareSayisi = 0;

  int oyuncuSkoru = 0;
  int aiSkoru = 0;
  late TextPaint yaziFircasi;

  List<Vector2> engelKonumlari = [];
  final Random _rastgele = Random();

  @override
  Future<void> onLoad() async {
    super.onLoad();

    yatayKareSayisi = (size.x / hucreBoyutu).floor();
    dikeyKareSayisi = (size.y / hucreBoyutu).floor();

    for (int x = 0; x < yatayKareSayisi; x++) {
      engelKonumlari.add(Vector2(x.toDouble(), 0));
      engelKonumlari.add(Vector2(x.toDouble(), (dikeyKareSayisi - 1).toDouble()));
    }
    for (int y = 0; y < dikeyKareSayisi; y++) {
      engelKonumlari.add(Vector2(0, y.toDouble()));
      engelKonumlari.add(Vector2((yatayKareSayisi - 1).toDouble(), y.toDouble()));
    }

    int uretilenIcEngel = 0;
    while (uretilenIcEngel < 20) {
      int x = _rastgele.nextInt(yatayKareSayisi - 2) + 1;
      int y = _rastgele.nextInt(dikeyKareSayisi - 2) + 1;
      Vector2 yeniTasKonumu = Vector2(x.toDouble(), y.toDouble());

      bool tasVarMi = engelKonumlari.any((tas) => tas.x == yeniTasKonumu.x && tas.y == yeniTasKonumu.y);
      bool baslangicAlaniMi = (x < 10 && y < 10) || (x > yatayKareSayisi - 10 && y > dikeyKareSayisi - 10);

      if (!tasVarMi && !baslangicAlaniMi) {
        engelKonumlari.add(yeniTasKonumu);
        uretilenIcEngel++;
      }
    }

    for (var tasKonumu in engelKonumlari) {
      add(Tas(hucreBoyutu: hucreBoyutu, baslangicKonumu: tasKonumu));
    }

    oyuncu = OyuncuYilani(hucreBoyutu: hucreBoyutu);
    add(oyuncu);

    yem = Yem(
      hucreBoyutu: hucreBoyutu,
      yatayKareSayisi: yatayKareSayisi,
      dikeyKareSayisi: dikeyKareSayisi,
    );
    add(yem);

    yapayZeka = YapayZekaYilani(
      hucreBoyutu: hucreBoyutu,
      yatayKare: yatayKareSayisi,
      dikeyKare: dikeyKareSayisi,
    );
    add(yapayZeka);

    yaziFircasi = TextPaint(
      style: const TextStyle(
        fontSize: 24.0,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontFamily: 'Arial',
      ),
    );
  }

  @override
  Color backgroundColor() => Colors.black;

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) && oyuncu.mevcutYon != Yon.asagi) {
      oyuncu.mevcutYon = Yon.yukari;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowDown) && oyuncu.mevcutYon != Yon.yukari) {
      oyuncu.mevcutYon = Yon.asagi;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) && oyuncu.mevcutYon != Yon.sag) {
      oyuncu.mevcutYon = Yon.sol;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight) && oyuncu.mevcutYon != Yon.sol) {
      oyuncu.mevcutYon = Yon.sag;
    }
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void update(double dt) {
    if (oyunBitti) return;

    super.update(dt);

    final kafa = oyuncu.govde.first;
    final aiKafa = yapayZeka.govde.first;

    for (var tasKonumu in engelKonumlari) {
      if (kafa.x == tasKonumu.x && kafa.y == tasKonumu.y) {
        oyunuBitir("Yapay Zeka");
        return;
      }
    }

    for (var tasKonumu in engelKonumlari) {
      if (aiKafa.x == tasKonumu.x && aiKafa.y == tasKonumu.y) {
        oyunuBitir(oyuncuAdi);
        return;
      }
    }

    if (kafa.x < 0 || kafa.x >= yatayKareSayisi || kafa.y < 0 || kafa.y >= dikeyKareSayisi) {
      oyunuBitir("Yapay Zeka");
    }
    if (aiKafa.x < 0 || aiKafa.x >= yatayKareSayisi || aiKafa.y < 0 || aiKafa.y >= dikeyKareSayisi) {
      oyunuBitir(oyuncuAdi);
    }

    for (int i = 1; i < oyuncu.govde.length; i++) {
      if (kafa.x == oyuncu.govde[i].x && kafa.y == oyuncu.govde[i].y) oyunuBitir("Yapay Zeka");
    }
    for (int i = 1; i < yapayZeka.govde.length; i++) {
      if (aiKafa.x == yapayZeka.govde[i].x && aiKafa.y == yapayZeka.govde[i].y) oyunuBitir(oyuncuAdi);
    }

    for (var parca in yapayZeka.govde) {
      if (kafa.x == parca.x && kafa.y == parca.y) oyunuBitir("Yapay Zeka");
    }
    for (var parca in oyuncu.govde) {
      if (aiKafa.x == parca.x && aiKafa.y == parca.y) oyunuBitir(oyuncuAdi);
    }

    if (!oyunBitti && yem.konum != null && kafa.x == yem.konum!.x && kafa.y == yem.konum!.y) {
      oyuncu.yemYedi();
      yem.konumUret();
      oyuncuSkoru += 10;
    }

    if (!oyunBitti && yem.konum != null && aiKafa.x == yem.konum!.x && aiKafa.y == yem.konum!.y) {
      yapayZeka.yemYedi();
      yem.konumUret();
      aiSkoru += 10;
    }
  }

  void oyunuBitir(String kimKazandi) {
    if (oyunBitti) return; // Çift tetiklenmeyi önle
    oyunBitti = true;
    kazanan = kimKazandi;
    pauseEngine(); 
    overlays.add('GameOver'); // YENİLİK: Flame'e "Ekrana tasarımı fırlat" diyoruz!
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.x; x += hucreBoyutu) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), paint);
    }
    for (double y = 0; y < size.y; y += hucreBoyutu) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), paint);
    }

    yaziFircasi.render(canvas, "$oyuncuAdi: $oyuncuSkoru", Vector2(20, 20));
    yaziFircasi.render(canvas, "Yapay Zeka: $aiSkoru", Vector2(size.x - 250, 20));
    
    // YENİLİK: Oyun bitti yazısını sildik, çünkü artık havalı Overlay menümüz var!
  }
}