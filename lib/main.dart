import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flame/components.dart'; 
import 'dart:ui';
import 'dart:math';

import 'components/yapay_zeka_yilani.dart';
import 'components/snake.dart';
import 'components/yem.dart';
import 'components/tas.dart';
import 'components/hiz_yemi.dart';
import 'components/altin_para.dart'; 

// --- GLOBAL OYUNCU VERİLERİ VE AYARLAR ---
int toplamAltin = 0; 
List<String> sahipOlunanSkinler = ["Klasik Yeşil"]; 
String aktifSkin = "Klasik Yeşil"; 

double dPadBoyutu = 30.0; 
bool dPadSagdaMi = false; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnaMenu(),
    ),
  );
}

// --- 1. ANA MENÜ TASARIMI ---
class AnaMenu extends StatefulWidget {
  @override
  _AnaMenuState createState() => _AnaMenuState();
}

class _AnaMenuState extends State<AnaMenu> {
  bool oyunBasladi = false;
  String oyuncuAdi = "Oyuncu";
  double secilenZorluk = 2.0; 
  TextEditingController isimKontrolcusu = TextEditingController();
  
  SnakeGame? aktifOyun; 

  String zorlukMetniAl(double deger) {
    if (deger == 1.0) return "Basit";
    if (deger == 2.0) return "Orta";
    return "Zor";
  }

  Widget dPadButonu(IconData icon, VoidCallback basildi) {
    return GestureDetector(
      onTap: basildi,
      child: Container(
        margin: EdgeInsets.all(dPadBoyutu / 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54, width: 2),
        ),
        child: Padding(
          padding: EdgeInsets.all(dPadBoyutu / 3), 
          child: Icon(icon, color: Colors.white, size: dPadBoyutu), 
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (oyunBasladi && aktifOyun != null) {
      return Scaffold(
        body: Stack(
          children: [
            GameWidget(
              game: aktifOyun!,
              overlayBuilderMap: {
                'GameOver': (context, SnakeGame game) => GameOverMenu(game: game),
              },
            ),
            Positioned(
              bottom: 20,
              left: dPadSagdaMi ? null : 20, 
              right: dPadSagdaMi ? 20 : null,
              child: Column(
                children: [
                  dPadButonu(Icons.keyboard_arrow_up, () => aktifOyun!.yonUygula(Yon.yukari)),
                  Row(
                    children: [
                      dPadButonu(Icons.keyboard_arrow_left, () => aktifOyun!.yonUygula(Yon.sol)),
                      SizedBox(width: dPadBoyutu * 1.5), 
                      dPadButonu(Icons.keyboard_arrow_right, () => aktifOyun!.yonUygula(Yon.sag)),
                    ],
                  ),
                  dPadButonu(Icons.keyboard_arrow_down, () => aktifOyun!.yonUygula(Yon.asagi)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(
            game: SnakeGame(oyuncuAdi: "", zorlukSeviyesi: 2),
            overlayBuilderMap: {
              'GameOver': (context, SnakeGame game) => const SizedBox.shrink(),
            },
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(15),
                width: MediaQuery.of(context).size.width * 0.75,
                constraints: BoxConstraints(maxWidth: 340), 
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green, width: 2),
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("SNAKE DUEL AI", style: TextStyle(color: Colors.green, fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("Aktif Skin: $aktifSkin", style: TextStyle(color: Colors.white70, fontSize: 11)),
                    
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber, width: 1)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                          SizedBox(width: 5),
                          Text("$toplamAltin Altın", style: TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.store, color: Colors.black, size: 18),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => MagazaEkrani())).then((value) => setState((){}));
                          },
                          label: Text("MAĞAZA", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: Icon(Icons.settings, color: Colors.white, size: 18),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => AyarlarEkrani())).then((value) => setState((){}));
                          },
                          label: Text("AYARLAR", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),

                    SizedBox(height: 10),
                    TextField(
                      controller: isimKontrolcusu,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true, 
                        contentPadding: EdgeInsets.all(10), 
                        labelText: "Savaşçı Adın",
                        labelStyle: TextStyle(color: Colors.green, fontSize: 14),
                        prefixIcon: Icon(Icons.person, color: Colors.green, size: 20),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green, width: 2)),
                      ),
                    ),
                    SizedBox(height: 5),
                    
                    Text("AI Zorluk: ${zorlukMetniAl(secilenZorluk)}", style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                    Slider(
                      value: secilenZorluk, min: 1.0, max: 3.0, divisions: 2,
                      activeColor: Colors.green, inactiveColor: Colors.white24,
                      onChanged: (yeniDeger) { setState(() { secilenZorluk = yeniDeger; }); },
                    ),
                    
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                      onPressed: () {
                        setState(() {
                          if (isimKontrolcusu.text.isNotEmpty) oyuncuAdi = isimKontrolcusu.text;
                          aktifOyun = SnakeGame(oyuncuAdi: oyuncuAdi, zorlukSeviyesi: secilenZorluk.toInt());
                          oyunBasladi = true; 
                        });
                      },
                      child: Text("OYUNA BAŞLA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- AYARLAR EKRANI ---
class AyarlarEkrani extends StatefulWidget {
  @override
  _AyarlarEkraniState createState() => _AyarlarEkraniState();
}

class _AyarlarEkraniState extends State<AyarlarEkrani> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text("AYARLAR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.greenAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Card(
            color: Colors.black,
            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.white38, width: 1), borderRadius: BorderRadius.circular(10)),
            child: SwitchListTile(
              title: Text("Yön Tuşları Sağda Olsun", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text("Solak veya sağlak modunu ayarla.", style: TextStyle(color: Colors.white70)),
              activeColor: Colors.green,
              value: dPadSagdaMi,
              onChanged: (bool deger) {
                setState(() {
                  dPadSagdaMi = deger;
                });
              },
            ),
          ),
          SizedBox(height: 20),
          Card(
            color: Colors.black,
            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.white38, width: 1), borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text("Yön Tuşları Boyutu: ${dPadBoyutu.toInt()}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  Slider(
                    value: dPadBoyutu,
                    min: 20.0, 
                    max: 50.0, 
                    divisions: 6,
                    activeColor: Colors.greenAccent,
                    inactiveColor: Colors.white24,
                    onChanged: (yeniBoyut) {
                      setState(() {
                        dPadBoyutu = yeniBoyut;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- MAĞAZA EKRANI ---
class MagazaEkrani extends StatefulWidget {
  @override
  _MagazaEkraniState createState() => _MagazaEkraniState();
}

class _MagazaEkraniState extends State<MagazaEkrani> {
  final List<Map<String, dynamic>> vitrin = [
    {"isim": "Klasik Yeşil", "fiyat": 0, "renk": Colors.green},
    {"isim": "Neon Mor", "fiyat": 20, "renk": Colors.purpleAccent},
    {"isim": "Ateş Kırmızısı", "fiyat": 50, "renk": Colors.redAccent},
    {"isim": "Saf Altın", "fiyat": 100, "renk": Colors.amber}, 
  ];

  void satinAlVeyaGiy(String skinIsmi, int fiyat) {
    if (sahipOlunanSkinler.contains(skinIsmi)) {
      setState(() { aktifSkin = skinIsmi; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$skinIsmi kuşandın!"), backgroundColor: Colors.green));
    } else {
      if (toplamAltin >= fiyat) {
        setState(() {
          toplamAltin -= fiyat;
          sahipOlunanSkinler.add(skinIsmi);
          aktifSkin = skinIsmi;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$skinIsmi satın alındı!"), backgroundColor: Colors.amber));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Yetersiz Altın!"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text("MAĞAZA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.amber),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Center(child: Padding(padding: const EdgeInsets.only(right: 20), child: Text("$toplamAltin Altın", style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)))),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: vitrin.length,
        itemBuilder: (context, index) {
          var urun = vitrin[index];
          bool sahipMi = sahipOlunanSkinler.contains(urun["isim"]);
          bool giyiliMi = aktifSkin == urun["isim"];

          return Card(
            color: Colors.black,
            shape: RoundedRectangleBorder(side: BorderSide(color: urun["renk"], width: 2), borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.only(bottom: 15),
            child: ListTile(
              leading: Icon(Icons.square, color: urun["renk"], size: 30),
              title: Text(urun["isim"], style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              subtitle: Text(sahipMi ? "Senin" : "${urun["fiyat"]} Altın", style: TextStyle(color: sahipMi ? Colors.green : Colors.amber)),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: giyiliMi ? Colors.grey : (sahipMi ? Colors.green : Colors.amber)),
                onPressed: giyiliMi ? null : () => satinAlVeyaGiy(urun["isim"], urun["fiyat"]),
                child: Text(giyiliMi ? "KUŞANILDI" : (sahipMi ? "KUŞAN" : "SATIN AL"), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- OYUN BİTTİ EKRANI ---
class GameOverMenu extends StatelessWidget {
  final SnakeGame game;
  const GameOverMenu({required this.game});

  @override
  Widget build(BuildContext context) {
    bool senKazandin = game.kazanan == game.oyuncuAdi;
    Color temaRengi = senKazandin ? Colors.green : Colors.red;
    String bitisSebebi = (game.oyuncuSkoru >= 100 || game.aiSkoru >= 100) ? "100 PUANA ULAŞILDI!" : "ÇARPIŞMA!";

    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85), 
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: temaRengi, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("OYUN BİTTİ", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2)),
              SizedBox(height: 5),
              Text(bitisSebebi, style: TextStyle(color: Colors.orangeAccent, fontSize: 14, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("KAZANAN:", style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(game.kazanan.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(color: temaRengi, fontSize: 24, fontWeight: FontWeight.bold)),
              
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    if (senKazandin) Text("+10 Altın (Zafer Ödülü)", style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                    Text("Güncel Servetin: $toplamAltin Altın", style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      // YENİLİK: Buradaki "Sen" yazısı da artık senin ismin oldu!
                      Text(game.oyuncuAdi, style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text("${game.oyuncuSkoru}", style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(width: 2, height: 40, color: Colors.white24), 
                  Column(
                    children: [
                      Text("AI", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text("${game.aiSkoru}", style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh, color: Colors.black),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                onPressed: () { Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AnaMenu())); },
                label: Text("ANA MENÜ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- ANA OYUN MOTORU ---
class SnakeGame extends FlameGame with KeyboardEvents {
  final String oyuncuAdi;
  final int zorlukSeviyesi; 
  
  SnakeGame({required this.oyuncuAdi, required this.zorlukSeviyesi});

  final double hucreBoyutu = 20.0;
  late OyuncuYilani oyuncu;
  late Yem yem;
  late HizYemi hizYemi; 
  late AltinPara altinPara; 
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

    for (int x = 0; x < yatayKareSayisi; x++) { engelKonumlari.add(Vector2(x.toDouble(), 0)); engelKonumlari.add(Vector2(x.toDouble(), (dikeyKareSayisi - 1).toDouble())); }
    for (int y = 0; y < dikeyKareSayisi; y++) { engelKonumlari.add(Vector2(0, y.toDouble())); engelKonumlari.add(Vector2((yatayKareSayisi - 1).toDouble(), y.toDouble())); }

    int uretilenIcEngel = 0;
    int guvenlikSayaci = 0; 

    if (yatayKareSayisi > 5 && dikeyKareSayisi > 5) {
      while (uretilenIcEngel < 20 && guvenlikSayaci < 200) {
        guvenlikSayaci++;
        int x = _rastgele.nextInt(yatayKareSayisi - 2) + 1;
        int y = _rastgele.nextInt(dikeyKareSayisi - 2) + 1;
        Vector2 yeniTasKonumu = Vector2(x.toDouble(), y.toDouble());
        bool tasVarMi = engelKonumlari.any((tas) => tas.x == yeniTasKonumu.x && tas.y == yeniTasKonumu.y);
        
        bool baslangicAlaniMi = (x < 8 && y < 8) || (x > yatayKareSayisi - 8 && y > dikeyKareSayisi - 8);
        
        if (!tasVarMi && !baslangicAlaniMi) { 
          engelKonumlari.add(yeniTasKonumu); 
          uretilenIcEngel++; 
        }
      }
    }

    oyuncu = OyuncuYilani(hucreBoyutu: hucreBoyutu, seciliSkin: aktifSkin);
    yapayZeka = YapayZekaYilani(hucreBoyutu: hucreBoyutu, yatayKare: yatayKareSayisi, dikeyKare: dikeyKareSayisi, zorlukSeviyesi: zorlukSeviyesi);
    
    yem = Yem(hucreBoyutu: hucreBoyutu, yatayKareSayisi: yatayKareSayisi, dikeyKareSayisi: dikeyKareSayisi); 
    hizYemi = HizYemi(hucreBoyutu: hucreBoyutu, yatayKareSayisi: yatayKareSayisi, dikeyKareSayisi: dikeyKareSayisi); 
    altinPara = AltinPara(hucreBoyutu: hucreBoyutu, yatayKareSayisi: yatayKareSayisi, dikeyKareSayisi: dikeyKareSayisi); 

    for (var tasKonumu in engelKonumlari) add(Tas(hucreBoyutu: hucreBoyutu, baslangicKonumu: tasKonumu));
    
    add(oyuncu);
    add(yapayZeka);
    add(yem);
    add(hizYemi);
    add(altinPara);

    yaziFircasi = TextPaint(style: const TextStyle(fontSize: 14.0, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Arial'));
  }

  @override
  Color backgroundColor() => Colors.black;

  void yonUygula(Yon yeniYon) {
    if (yeniYon == Yon.yukari && oyuncu.mevcutYon != Yon.asagi) oyuncu.mevcutYon = Yon.yukari;
    else if (yeniYon == Yon.asagi && oyuncu.mevcutYon != Yon.yukari) oyuncu.mevcutYon = Yon.asagi;
    else if (yeniYon == Yon.sol && oyuncu.mevcutYon != Yon.sag) oyuncu.mevcutYon = Yon.sol;
    else if (yeniYon == Yon.sag && oyuncu.mevcutYon != Yon.sol) oyuncu.mevcutYon = Yon.sag;
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp)) yonUygula(Yon.yukari);
    else if (keysPressed.contains(LogicalKeyboardKey.arrowDown)) yonUygula(Yon.asagi);
    else if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) yonUygula(Yon.sol);
    else if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) yonUygula(Yon.sag);
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void update(double dt) {
    if (oyunBitti) return;
    super.update(dt);
    final kafa = oyuncu.govde.first;
    final aiKafa = yapayZeka.govde.first;

    for (var tas in engelKonumlari) if (kafa.x == tas.x && kafa.y == tas.y) { oyunuBitir("Yapay Zeka"); return; }
    for (var tas in engelKonumlari) if (aiKafa.x == tas.x && aiKafa.y == tas.y) { oyunuBitir(oyuncuAdi); return; }

    if (kafa.x < 0 || kafa.x >= yatayKareSayisi || kafa.y < 0 || kafa.y >= dikeyKareSayisi) oyunuBitir("Yapay Zeka");
    if (aiKafa.x < 0 || aiKafa.x >= yatayKareSayisi || aiKafa.y < 0 || aiKafa.y >= dikeyKareSayisi) oyunuBitir(oyuncuAdi);

    for (int i = 1; i < oyuncu.govde.length; i++) if (kafa.x == oyuncu.govde[i].x && kafa.y == oyuncu.govde[i].y) oyunuBitir("Yapay Zeka");
    for (int i = 1; i < yapayZeka.govde.length; i++) if (aiKafa.x == yapayZeka.govde[i].x && aiKafa.y == yapayZeka.govde[i].y) oyunuBitir(oyuncuAdi);

    for (var p in yapayZeka.govde) if (kafa.x == p.x && kafa.y == p.y) oyunuBitir("Yapay Zeka");
    for (var p in oyuncu.govde) if (aiKafa.x == p.x && aiKafa.y == p.y) oyunuBitir(oyuncuAdi);

    if (!oyunBitti && yem.konum != null && kafa.x == yem.konum!.x && kafa.y == yem.konum!.y) { oyuncu.yemYedi(); yem.konumUret(); oyuncuSkoru += 10; if (oyuncuSkoru >= 100) oyunuBitir(oyuncuAdi); }
    if (!oyunBitti && yem.konum != null && aiKafa.x == yem.konum!.x && aiKafa.y == yem.konum!.y) { yapayZeka.yemYedi(); yem.konumUret(); aiSkoru += 10; if (aiSkoru >= 100) oyunuBitir("Yapay Zeka"); }

    if (!oyunBitti && hizYemi.konum != null && kafa.x == hizYemi.konum!.x && kafa.y == hizYemi.konum!.y) { oyuncu.hizKazan(); hizYemi.konumUret(); }
    if (!oyunBitti && hizYemi.konum != null && aiKafa.x == hizYemi.konum!.x && aiKafa.y == hizYemi.konum!.y) { yapayZeka.hizKazan(); hizYemi.konumUret(); }

    if (!oyunBitti && altinPara.konum != null && kafa.x == altinPara.konum!.x && kafa.y == altinPara.konum!.y) { toplamAltin += 1; altinPara.konumUret(); }
    if (!oyunBitti && altinPara.konum != null && aiKafa.x == altinPara.konum!.x && aiKafa.y == altinPara.konum!.y) { altinPara.konumUret(); }
  }

  void oyunuBitir(String kimKazandi) {
    if (oyunBitti) return; 
    oyunBitti = true; kazanan = kimKazandi;
    if (kazanan == oyuncuAdi && oyuncuAdi != "") toplamAltin += 10;
    pauseEngine(); 
    if (overlays.activeOverlays.contains('GameOver') || overlays.add('GameOver')) {}
  }

  void skorTabelasiCiz(Canvas canvas, String yazi, double x, double y, Color cerceveRengi, int hizalama) {
    double kutuGenisligi = (yazi.length * 8.5) + 20.0; 
    double kutuYuksekligi = 30.0;
    
    double cizimX = x;
    if (hizalama == 2) cizimX = x - (kutuGenisligi / 2); 
    if (hizalama == 3) cizimX = x - kutuGenisligi;       

    final dikdortgen = RRect.fromRectAndRadius(
      Rect.fromLTWH(cizimX, y, kutuGenisligi, kutuYuksekligi),
      const Radius.circular(10), 
    );
    
    canvas.drawRRect(dikdortgen, Paint()..color = Colors.black.withOpacity(0.6));
    
    canvas.drawRRect(dikdortgen, Paint()
      ..color = cerceveRengi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    yaziFircasi.render(canvas, yazi, Vector2(cizimX + 10, y + 6));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = Colors.white.withOpacity(0.1)..style = PaintingStyle.stroke;
    for (double x = 0; x < size.x; x += hucreBoyutu) canvas.drawLine(Offset(x, 0), Offset(x, size.y), paint);
    for (double y = 0; y < size.y; y += hucreBoyutu) canvas.drawLine(Offset(0, y), Offset(size.x, y), paint);

    // YENİLİK: İşte buradaki 'Sen' yazısı gitti, oyuncuAdi geldi! Kutu da ismin uzunluğuna göre dinamik olarak büyüyecek.
    skorTabelasiCiz(canvas, "$oyuncuAdi: $oyuncuSkoru", 15, 15, Colors.greenAccent, 1);
    
    skorTabelasiCiz(canvas, "Altın: $toplamAltin", size.x / 2, 15, Colors.amberAccent, 2);
    skorTabelasiCiz(canvas, "AI: $aiSkoru", size.x - 15, 15, Colors.redAccent, 3);
  }
}