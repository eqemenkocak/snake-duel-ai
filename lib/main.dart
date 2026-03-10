import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flame/components.dart'; 
import 'dart:ui';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/yapay_zeka_yilani.dart';
import 'components/snake.dart';
import 'components/yem.dart';
import 'components/tas.dart';
import 'components/hiz_yemi.dart';
import 'components/altin_para.dart'; 

// --- GLOBAL OYUNCU VERİLERİ ---
int toplamAltin = 0; 
List<String> sahipOlunanSkinler = ["Klasik Yeşil"]; 
String aktifSkin = "Klasik Yeşil"; 
double kaydirmaHassasiyeti = 5.0; 

// ASLA SIFIRLANMAYACAK ÖLÜMSÜZ AYARLAR (GLOBAL)
String gOyuncuAdi = "";
double gSecilenZorluk = 2.0; 
double gHedefYem = 10.0; 
double gRakipSayisi = 1.0; 

late SharedPreferences prefs; 

// Bütün verileri açılışta çeker
void veriYukle() {
  toplamAltin = prefs.getInt('toplamAltin') ?? 0;
  sahipOlunanSkinler = prefs.getStringList('sahipOlunanSkinler') ?? ["Klasik Yeşil"];
  aktifSkin = prefs.getString('aktifSkin') ?? "Klasik Yeşil";
  kaydirmaHassasiyeti = prefs.getDouble('kaydirmaHassasiyeti') ?? 5.0;

  gOyuncuAdi = prefs.getString('gOyuncuAdi') ?? "";
  gSecilenZorluk = prefs.getDouble('gSecilenZorluk') ?? 2.0;
  gHedefYem = prefs.getDouble('gHedefYem') ?? 10.0;
  gRakipSayisi = prefs.getDouble('gRakipSayisi') ?? 1.0;
}

// Bütün verileri anında telefona yazar
Future<void> veriKaydet() async {
  await prefs.setInt('toplamAltin', toplamAltin);
  await prefs.setStringList('sahipOlunanSkinler', sahipOlunanSkinler);
  await prefs.setString('aktifSkin', aktifSkin);
  await prefs.setDouble('kaydirmaHassasiyeti', kaydirmaHassasiyeti);

  await prefs.setString('gOyuncuAdi', gOyuncuAdi);
  await prefs.setDouble('gSecilenZorluk', gSecilenZorluk);
  await prefs.setDouble('gHedefYem', gHedefYem);
  await prefs.setDouble('gRakipSayisi', gRakipSayisi);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  prefs = await SharedPreferences.getInstance();
  veriYukle();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft, 
    DeviceOrientation.landscapeRight
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: AnaMenu()));
}

class AnaMenu extends StatefulWidget { 
  @override 
  _AnaMenuState createState() => _AnaMenuState(); 
}

class _AnaMenuState extends State<AnaMenu> {
  bool oyunBasladi = false;
  SnakeGame? aktifOyun; 
  late TextEditingController isimKontrolcusu;

  @override
  void initState() {
    super.initState();
    isimKontrolcusu = TextEditingController(text: gOyuncuAdi);
  }

  String zorlukMetniAl(double deger) {
    if (deger == 1.0) return "Basit";
    if (deger == 2.0) return "Orta";
    return "Zor";
  }

  @override
  Widget build(BuildContext context) {
    if (oyunBasladi && aktifOyun != null) {
      return Scaffold(
        body: GameWidget(
          game: aktifOyun!, 
          overlayBuilderMap: {
            'GameOver': (context, SnakeGame game) => GameOverMenu(game: game)
          }
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(
            game: SnakeGame(oyuncuAdi: "", zorlukSeviyesi: 2, hedefYem: 10, rakipSayisi: 1), 
            overlayBuilderMap: {
              'GameOver': (context, SnakeGame game) => const SizedBox.shrink()
            }
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), 
            child: Container(color: Colors.black.withOpacity(0.4))
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 15), 
                width: MediaQuery.of(context).size.width * 0.65, 
                constraints: BoxConstraints(maxWidth: 320), 
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7), 
                  borderRadius: BorderRadius.circular(15), 
                  border: Border.all(color: Colors.green, width: 2), 
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15)]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("SNAKE DUEL AI", style: TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold)), 
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.store, color: Colors.black, size: 14), 
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0), minimumSize: Size(0, 30)), 
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MagazaEkrani())).then((value) => setState((){})), 
                          label: Text("MAĞAZA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black))
                        ), 
                        SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: Icon(Icons.settings, color: Colors.white, size: 14), 
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0), minimumSize: Size(0, 30)), 
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AyarlarEkrani())).then((value) => setState((){})), 
                          label: Text("AYARLAR", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white))
                        ),
                      ]
                    ), 
                    SizedBox(height: 10),
                    SizedBox(
                      height: 35, 
                      child: TextField(
                        controller: isimKontrolcusu, 
                        style: TextStyle(color: Colors.white, fontSize: 13), 
                        decoration: InputDecoration(
                          isDense: true, 
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0), 
                          labelText: "Savaşçı Adın", 
                          labelStyle: TextStyle(color: Colors.green, fontSize: 13), 
                          prefixIcon: Icon(Icons.person, color: Colors.green, size: 18), 
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)), 
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green, width: 2))
                        ),
                        onChanged: (deger) {
                          gOyuncuAdi = deger;
                          veriKaydet();
                        },
                      ),
                    ), 
                    SizedBox(height: 8),
                    Text("Rakip Yılan Sayısı: ${gRakipSayisi.toInt()}", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 24, 
                      child: Slider(
                        value: gRakipSayisi, min: 1.0, max: 5.0, divisions: 4, 
                        activeColor: Colors.red, inactiveColor: Colors.white24, 
                        onChanged: (deger) {
                          setState(() => gRakipSayisi = deger);
                          veriKaydet();
                        }
                      ),
                    ),
                    Text("Oyun Sonu Hedefi: ${gHedefYem.toInt()} Yem", style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 24,
                      child: Slider(
                        value: gHedefYem, min: 5.0, max: 20.0, divisions: 15, 
                        activeColor: Colors.amber, inactiveColor: Colors.white24, 
                        onChanged: (deger) {
                          setState(() => gHedefYem = deger);
                          veriKaydet();
                        }
                      ),
                    ),
                    Text("AI Zorluk: ${zorlukMetniAl(gSecilenZorluk)}", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 24,
                      child: Slider(
                        value: gSecilenZorluk, min: 1.0, max: 3.0, divisions: 2, 
                        activeColor: Colors.green, inactiveColor: Colors.white24, 
                        onChanged: (deger) {
                          setState(() => gSecilenZorluk = deger);
                          veriKaydet();
                        }
                      ),
                    ),
                    SizedBox(height: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, 
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8), 
                        minimumSize: Size(0, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ), 
                      onPressed: () { 
                        setState(() { 
                          if (isimKontrolcusu.text.isNotEmpty) gOyuncuAdi = isimKontrolcusu.text; 
                          veriKaydet(); 
                          aktifOyun = SnakeGame(
                            oyuncuAdi: gOyuncuAdi, 
                            zorlukSeviyesi: gSecilenZorluk.toInt(), 
                            hedefYem: gHedefYem.toInt(), 
                            rakipSayisi: gRakipSayisi.toInt()
                          ); 
                          oyunBasladi = true; 
                        }); 
                      }, 
                      child: Text("SAVAŞI BAŞLAT", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white))
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
          onPressed: () => Navigator.of(context).pop()
        )
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
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
                    child: Text("Kaydırma Hassasiyeti: ${kaydirmaHassasiyeti.toInt()}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  ), 
                  Slider(
                    value: kaydirmaHassasiyeti, min: 1.0, max: 20.0, divisions: 19, 
                    activeColor: Colors.greenAccent, inactiveColor: Colors.white24, 
                    onChanged: (yeniBoyut) {
                      setState(() => kaydirmaHassasiyeti = yeniBoyut);
                      veriKaydet(); 
                    }
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text("Not: Düşük değerler parmağınızın en ufak hareketini algılar.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  )
                ]
              )
            )
          ),
        ],
      ),
    );
  }
}

class MagazaEkrani extends StatefulWidget { 
  @override 
  _MagazaEkraniState createState() => _MagazaEkraniState(); 
}

class _MagazaEkraniState extends State<MagazaEkrani> {
  final List<Map<String, dynamic>> vitrin = [ 
    {"isim": "Klasik Yeşil", "fiyat": 0, "renk": Colors.green}, 
    {"isim": "Neon Mor", "fiyat": 20, "renk": Colors.purpleAccent}, 
    {"isim": "Ateş Kırmızısı", "fiyat": 50, "renk": Colors.redAccent}, 
    {"isim": "Saf Altın", "fiyat": 100, "renk": Colors.amber} 
  ];

  void satinAlVeyaGiy(String skinIsmi, int fiyat) {
    if (sahipOlunanSkinler.contains(skinIsmi)) { 
      setState(() { aktifSkin = skinIsmi; }); 
      veriKaydet(); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$skinIsmi kuşandın!"), backgroundColor: Colors.green)); 
    } else {
      if (toplamAltin >= fiyat) { 
        setState(() { toplamAltin -= fiyat; sahipOlunanSkinler.add(skinIsmi); aktifSkin = skinIsmi; }); 
        veriKaydet(); 
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
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Colors.amber), onPressed: () => Navigator.of(context).pop()), 
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20), 
              child: Text("$toplamAltin Altın", style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold))
            )
          )
        ]
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
            margin: EdgeInsets.only(bottom: 15), 
            shape: RoundedRectangleBorder(side: BorderSide(color: urun["renk"], width: 2), borderRadius: BorderRadius.circular(10)), 
            child: ListTile(
              leading: Icon(Icons.square, color: urun["renk"], size: 30), 
              title: Text(urun["isim"], style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), 
              subtitle: Text(sahipMi ? "Senin" : "${urun["fiyat"]} Altın", style: TextStyle(color: sahipMi ? Colors.green : Colors.amber)), 
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: giyiliMi ? Colors.grey : (sahipMi ? Colors.green : Colors.amber)), 
                onPressed: giyiliMi ? null : () => satinAlVeyaGiy(urun["isim"], urun["fiyat"]), 
                child: Text(giyiliMi ? "KUŞANILDI" : (sahipMi ? "KUŞAN" : "SATIN AL"), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
              )
            )
          );
        }
      ),
    );
  }
}

class GameOverMenu extends StatelessWidget {
  final SnakeGame game;
  const GameOverMenu({required this.game});

  @override
  Widget build(BuildContext context) {
    bool senKazandin = game.kazanan == game.oyuncuAdi;
    Color temaRengi = senKazandin ? Colors.green : Colors.red;
    
    // YENİLİK: Bitiş sebebi artık doğrudan oyun motorundan gelen özel mesaj!
    String bitisSebebi = game.bitisMesaji.isNotEmpty ? game.bitisMesaji : "BÜTÜN RAKİPLER ELENDİ!"; 

    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20), 
          width: MediaQuery.of(context).size.width * 0.85, 
          constraints: BoxConstraints(maxWidth: 400), 
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.85), borderRadius: BorderRadius.circular(20), border: Border.all(color: temaRengi, width: 3)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("OYUN BİTTİ", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2)), 
              SizedBox(height: 5),
              // Bitiş sebebini biraz daha görünür yapalım
              Text(bitisSebebi, textAlign: TextAlign.center, style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold)), 
              SizedBox(height: 10),
              Text("KAZANAN:", style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(game.kazanan.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(color: temaRengi, fontSize: 24, fontWeight: FontWeight.bold)), 
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(10), 
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), 
                child: Column(
                  children: [
                    if (senKazandin) Text("+${game.hedefYem} Altın (Görev Ödülü)", style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)), 
                    Text("Güncel Servetin: $toplamAltin Altın", style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold))
                  ]
                )
              ), 
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                children: [
                  Column(children: [Text(game.oyuncuAdi, style: TextStyle(color: Colors.white70, fontSize: 14)), Text("${game.oyuncuSkoru}", style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold))]), 
                  Container(width: 2, height: 40, color: Colors.white24), 
                  Column(children: [Text("Lider AI", style: TextStyle(color: Colors.white70, fontSize: 14)), Text("${game.aiSkoru}", style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold))])
                ]
              ), 
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh, color: Colors.black), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10)), 
                onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AnaMenu())), 
                label: Text("ANA MENÜ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black))
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SnakeGame extends FlameGame with KeyboardEvents, PanDetector {
  final String oyuncuAdi; 
  final int zorlukSeviyesi; 
  final int hedefYem; 
  final int rakipSayisi; 

  SnakeGame({
    required this.oyuncuAdi, 
    required this.zorlukSeviyesi, 
    required this.hedefYem, 
    required this.rakipSayisi
  });

  final double hucreBoyutu = 20.0;
  late OyuncuYilani oyuncu; 
  late Yem yem; 
  late HizYemi hizYemi; 
  late AltinPara altinPara; 
  
  List<YapayZekaYilani> yapayZekalar = []; 
  Map<YapayZekaYilani, int> bireyselAiSkorlari = {}; 

  bool oyunBitti = false; 
  String kazanan = "";
  // YENİLİK: Oyunun nasıl bittiğini tutan özel değişken
  String bitisMesaji = ""; 

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
      bool baslangicAlaniMi = (x < 8 && y < 8) || (x > yatayKareSayisi - 8 && y > dikeyKareSayisi - 8);
      if (!tasVarMi && !baslangicAlaniMi) { 
        engelKonumlari.add(yeniTasKonumu); 
        uretilenIcEngel++; 
      }
    }

    oyuncu = OyuncuYilani(hucreBoyutu: hucreBoyutu, seciliSkin: aktifSkin);
    add(oyuncu);

    for (int i = 0; i < rakipSayisi; i++) {
      var ai = YapayZekaYilani(hucreBoyutu: hucreBoyutu, yatayKare: yatayKareSayisi, dikeyKare: dikeyKareSayisi, zorlukSeviyesi: zorlukSeviyesi);
      double basX = 5; 
      double basY = 5;
      
      if (i == 0) { basX = (yatayKareSayisi - 5).toDouble(); basY = 5; }
      else if (i == 1) { basX = 5; basY = (dikeyKareSayisi - 5).toDouble(); }
      else if (i == 2) { basX = (yatayKareSayisi - 5).toDouble(); basY = (dikeyKareSayisi - 5).toDouble(); }
      else if (i == 3) { basX = (yatayKareSayisi ~/ 2).toDouble(); basY = 5; }
      else if (i == 4) { basX = (yatayKareSayisi ~/ 2).toDouble(); basY = (dikeyKareSayisi - 5).toDouble(); }

      ai.govde = [
        Vector2(basX, basY), 
        Vector2(basX, basY - 1), 
        Vector2(basX, basY - 2)
      ];
      ai.mevcutYon = Yon.asagi; 
      yapayZekalar.add(ai);
      add(ai);
      
      bireyselAiSkorlari[ai] = 0; 
    }

    yem = Yem(hucreBoyutu: hucreBoyutu, yatayKareSayisi: yatayKareSayisi, dikeyKareSayisi: dikeyKareSayisi); 
    hizYemi = HizYemi(hucreBoyutu: hucreBoyutu, yatayKareSayisi: yatayKareSayisi, dikeyKareSayisi: dikeyKareSayisi); 
    altinPara = AltinPara(hucreBoyutu: hucreBoyutu, yatayKareSayisi: yatayKareSayisi, dikeyKareSayisi: dikeyKareSayisi); 

    for (var tasKonumu in engelKonumlari) {
      add(Tas(hucreBoyutu: hucreBoyutu, baslangicKonumu: tasKonumu));
    }
    
    add(yem); 
    add(hizYemi); 
    add(altinPara);
    yaziFircasi = TextPaint(style: const TextStyle(fontSize: 14.0, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Arial'));
  }

  @override
  Color backgroundColor() => Colors.black;

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (oyunBitti) return;

    final dx = info.delta.global.x;
    final dy = info.delta.global.y;

    if (dx.abs() < kaydirmaHassasiyeti && dy.abs() < kaydirmaHassasiyeti) return;

    if (dx.abs() > dy.abs()) {
      if (dx > 0 && oyuncu.mevcutYon != Yon.sol) {
        oyuncu.mevcutYon = Yon.sag;
      } else if (dx < 0 && oyuncu.mevcutYon != Yon.sag) {
        oyuncu.mevcutYon = Yon.sol;
      }
    } else {
      if (dy > 0 && oyuncu.mevcutYon != Yon.yukari) {
        oyuncu.mevcutYon = Yon.asagi;
      } else if (dy < 0 && oyuncu.mevcutYon != Yon.asagi) {
        oyuncu.mevcutYon = Yon.yukari;
      }
    }
  }

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

    // YENİLİK: Oyuncunun neye çarptığını tek tek anlıyoruz
    bool duvaraCarpti = kafa.x < 0 || kafa.x >= yatayKareSayisi || kafa.y < 0 || kafa.y >= dikeyKareSayisi || engelKonumlari.any((t) => t.x == kafa.x && t.y == kafa.y);
    bool kendineCarpti = oyuncu.govde.skip(1).any((p) => p.x == kafa.x && p.y == kafa.y);
    bool rakibeCarpti = yapayZekalar.any((ai) => ai.govde.any((p) => p.x == kafa.x && p.y == kafa.y));

    if (duvaraCarpti) {
      bitisMesaji = "$oyuncuAdi, kafayı taşa vurdun!";
      oyunuBitir("Yapay Zeka"); 
      return; 
    } else if (kendineCarpti) {
      bitisMesaji = "Hey $oyuncuAdi, kuyruğunu yemeye mi çalışıyorsun?";
      oyunuBitir("Yapay Zeka"); 
      return; 
    } else if (rakibeCarpti) {
      bitisMesaji = "Dostum o yem değil, senin rakibin!";
      oyunuBitir("Yapay Zeka"); 
      return; 
    }

    List<YapayZekaYilani> olenYilanlar = [];

    for (var ai in yapayZekalar) {
      final aiKafa = ai.govde.first;
      bool carptiMi = aiKafa.x < 0 || aiKafa.x >= yatayKareSayisi || aiKafa.y < 0 || aiKafa.y >= dikeyKareSayisi || 
                      engelKonumlari.any((t) => t.x == aiKafa.x && t.y == aiKafa.y) || 
                      oyuncu.govde.any((p) => p.x == aiKafa.x && p.y == aiKafa.y) || 
                      ai.govde.skip(1).any((p) => p.x == aiKafa.x && p.y == aiKafa.y);
      
      if (!carptiMi) {
        for (var digerAi in yapayZekalar) {
          if (ai != digerAi && digerAi.govde.any((p) => p.x == aiKafa.x && p.y == aiKafa.y)) { 
            carptiMi = true; 
            break; 
          }
        }
      }

      if (carptiMi) {
        olenYilanlar.add(ai);
      } else {
        if (yem.konum != null && aiKafa.x == yem.konum!.x && aiKafa.y == yem.konum!.y) { 
          ai.yemYedi(); 
          yem.konumUret(); 
          
          bireyselAiSkorlari[ai] = (bireyselAiSkorlari[ai] ?? 0) + 10;
          
          if (bireyselAiSkorlari[ai]! >= hedefYem * 10) { 
            // YENİLİK: Rakip hedef yeme senden önce ulaşırsa yazacak mesaj
            bitisMesaji = "Çok yavaşsın çaylak!";
            oyunuBitir("Yapay Zeka"); 
            return; 
          } 
        }
        if (hizYemi.konum != null && aiKafa.x == hizYemi.konum!.x && aiKafa.y == hizYemi.konum!.y) { 
          ai.hizKazan(); 
          hizYemi.konumUret(); 
        }
        if (altinPara.konum != null && aiKafa.x == altinPara.konum!.x && aiKafa.y == altinPara.konum!.y) { 
          altinPara.konumUret(); 
        }
      }
    }

    for (var olen in olenYilanlar) {
      olen.oluMu = true; 
      remove(olen);
      yapayZekalar.remove(olen); 
      bireyselAiSkorlari.remove(olen); 
    }
    
    if (bireyselAiSkorlari.isNotEmpty) {
      aiSkoru = bireyselAiSkorlari.values.reduce(max);
    } else {
      aiSkoru = 0;
    }

    if (yapayZekalar.isEmpty) { 
      bitisMesaji = "BÜTÜN RAKİPLER ELENDİ, MEYDAN SENİN!";
      oyunuBitir(oyuncuAdi); 
      return; 
    }

    if (yem.konum != null && kafa.x == yem.konum!.x && kafa.y == yem.konum!.y) { 
      oyuncu.yemYedi(); 
      yem.konumUret(); 
      oyuncuSkoru += 10; 
      if (oyuncuSkoru >= hedefYem * 10) {
        bitisMesaji = "HEDEF YEME ULAŞTIN, ZAFER SENİN!";
        oyunuBitir(oyuncuAdi); 
      }
    }
    
    if (hizYemi.konum != null && kafa.x == hizYemi.konum!.x && kafa.y == hizYemi.konum!.y) { 
      oyuncu.hizKazan(); 
      hizYemi.konumUret(); 
    }
    
    if (altinPara.konum != null && kafa.x == altinPara.konum!.x && kafa.y == altinPara.konum!.y) { 
      toplamAltin += 1; 
      veriKaydet(); 
      altinPara.konumUret(); 
    }
  }

  void oyunuBitir(String kimKazandi) {
    if (oyunBitti) return; 
    oyunBitti = true; 
    kazanan = kimKazandi;
    if (kazanan == oyuncuAdi && oyuncuAdi != "") {
      toplamAltin += hedefYem;
      veriKaydet(); 
    }
    pauseEngine(); 
    if (overlays.add('GameOver')) {}
  }

  void skorTabelasiCiz(Canvas canvas, String yazi, double x, double y, Color cerceveRengi, int hizalama) {
    double kutuGenisligi = (yazi.length * 8.5) + 20.0; 
    double cizimX = x;
    if (hizalama == 2) cizimX = x - (kutuGenisligi / 2); 
    if (hizalama == 3) cizimX = x - kutuGenisligi;       
    final dikdortgen = RRect.fromRectAndRadius(Rect.fromLTWH(cizimX, y, kutuGenisligi, 30.0), const Radius.circular(10));
    canvas.drawRRect(dikdortgen, Paint()..color = Colors.black.withOpacity(0.6));
    canvas.drawRRect(dikdortgen, Paint()..color = cerceveRengi..style = PaintingStyle.stroke..strokeWidth = 2);
    yaziFircasi.render(canvas, yazi, Vector2(cizimX + 10, y + 6));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = Colors.white.withOpacity(0.1)..style = PaintingStyle.stroke;
    for (double x = 0; x < size.x; x += hucreBoyutu) canvas.drawLine(Offset(x, 0), Offset(x, size.y), paint);
    for (double y = 0; y < size.y; y += hucreBoyutu) canvas.drawLine(Offset(0, y), Offset(size.x, y), paint);
    skorTabelasiCiz(canvas, "$oyuncuAdi: $oyuncuSkoru / ${hedefYem * 10}", 15, 15, Colors.greenAccent, 1);
    skorTabelasiCiz(canvas, "Kalan Rakip: ${yapayZekalar.length}", size.x / 2, 15, Colors.amberAccent, 2);
    skorTabelasiCiz(canvas, "Lider AI: $aiSkoru / ${hedefYem * 10}", size.x - 15, 15, Colors.redAccent, 3);
  }
}