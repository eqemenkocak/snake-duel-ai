import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flame/components.dart'; 
import 'dart:ui';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame_audio/flame_audio.dart'; 

import 'components/yapay_zeka_yilani.dart';
import 'components/snake.dart';
import 'components/yem.dart';
import 'components/tas.dart';
import 'components/hiz_yemi.dart';
import 'components/altin_para.dart'; 

// --- GLOBAL OYUNCU VERİLERİ ---
int toplamAltin = 5000; 
List<String> sahipOlunanSkinler = ["Klasik Yeşil"]; 
String aktifSkin = "Klasik Yeşil"; 
double kaydirmaHassasiyeti = 5.0; 

List<String> sahipOlunanAksesuarlar = []; 
List<String> aktifAksesuarlar = []; 

String gOyuncuAdi = "";
double gSecilenZorluk = 2.0; 
double gHedefYem = 10.0; 
double gRakipSayisi = 1.0; 
int klasikRekor = 0; 
int gSecilenMod = 0; 

// --- GÜNLÜK GÖREV SİSTEMİ DEĞİŞKENLERİ ---
String gSonGorevTarihi = "";
bool gGorevTamamlandi = false;
int gHedefHareketli = 5;
int gHedefAltin = 5;
int gHedefHiz = 3;

late SharedPreferences prefs; 

void veriYukle() {
  toplamAltin = 5000; 
  sahipOlunanSkinler = prefs.getStringList('sahipOlunanSkinler') ?? ["Klasik Yeşil"];
  aktifSkin = prefs.getString('aktifSkin') ?? "Klasik Yeşil";
  sahipOlunanAksesuarlar = prefs.getStringList('sahipOlunanAksesuarlar') ?? [];
  aktifAksesuarlar = prefs.getStringList('aktifAksesuarlar') ?? [];
  kaydirmaHassasiyeti = prefs.getDouble('kaydirmaHassasiyeti') ?? 5.0;

  gOyuncuAdi = prefs.getString('gOyuncuAdi') ?? "";
  gSecilenZorluk = prefs.getDouble('gSecilenZorluk') ?? 2.0;
  gHedefYem = prefs.getDouble('gHedefYem') ?? 10.0;
  gRakipSayisi = prefs.getDouble('gRakipSayisi') ?? 1.0;
  klasikRekor = prefs.getInt('klasikRekor') ?? 0; 
  gSecilenMod = prefs.getInt('gSecilenMod') ?? 0; 

  String bugun = DateTime.now().toIso8601String().substring(0, 10);
  gSonGorevTarihi = prefs.getString('gSonGorevTarihi') ?? "";
  gGorevTamamlandi = prefs.getBool('gGorevTamamlandi') ?? false;

  if (gSonGorevTarihi != bugun) {
    gSonGorevTarihi = bugun;
    gGorevTamamlandi = false;
    gHedefHareketli = Random().nextInt(5) + 3; 
    gHedefAltin = Random().nextInt(4) + 3;     
    gHedefHiz = Random().nextInt(3) + 2;       
    
    prefs.setString('gSonGorevTarihi', gSonGorevTarihi);
    prefs.setBool('gGorevTamamlandi', gGorevTamamlandi);
    prefs.setInt('gHedefHareketli', gHedefHareketli);
    prefs.setInt('gHedefAltin', gHedefAltin);
    prefs.setInt('gHedefHiz', gHedefHiz);
  } else {
    gHedefHareketli = prefs.getInt('gHedefHareketli') ?? 5;
    gHedefAltin = prefs.getInt('gHedefAltin') ?? 5;
    gHedefHiz = prefs.getInt('gHedefHiz') ?? 3;
  }
}

Future<void> veriKaydet() async {
  await prefs.setInt('toplamAltin', toplamAltin);
  await prefs.setStringList('sahipOlunanSkinler', sahipOlunanSkinler);
  await prefs.setString('aktifSkin', aktifSkin);
  await prefs.setStringList('sahipOlunanAksesuarlar', sahipOlunanAksesuarlar);
  await prefs.setStringList('aktifAksesuarlar', aktifAksesuarlar); 
  await prefs.setDouble('kaydirmaHassasiyeti', kaydirmaHassasiyeti);

  await prefs.setString('gOyuncuAdi', gOyuncuAdi);
  await prefs.setDouble('gSecilenZorluk', gSecilenZorluk);
  await prefs.setDouble('gHedefYem', gHedefYem);
  await prefs.setDouble('gRakipSayisi', gRakipSayisi);
  await prefs.setInt('klasikRekor', klasikRekor); 
  await prefs.setInt('gSecilenMod', gSecilenMod); 

  await prefs.setString('gSonGorevTarihi', gSonGorevTarihi);
  await prefs.setBool('gGorevTamamlandi', gGorevTamamlandi);
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
  late int secilenMod; 

  @override
  void initState() {
    super.initState();
    isimKontrolcusu = TextEditingController(text: gOyuncuAdi);
    secilenMod = gSecilenMod; 
  }

  String zorlukMetniAl(double deger) {
    if (deger == 1.0) return "Basit";
    if (deger == 2.0) return "Orta";
    return "Zor";
  }

  @override
  Widget build(BuildContext context) {
    if (oyunBasladi && aktifOyun != null) {
      Widget oyunEkrani = GameWidget(
        game: aktifOyun!, 
        overlayBuilderMap: {
          'GameOver': (context, SnakeGame game) => GameOverMenu(game: game)
        }
      );

      if (secilenMod > 0) { 
        oyunEkrani = Center(
          child: AspectRatio(
            aspectRatio: 1.0, 
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: secilenMod == 2 ? Colors.redAccent : (secilenMod == 3 ? Colors.orangeAccent : Colors.blueAccent), width: 4),
                boxShadow: [BoxShadow(color: (secilenMod == 2 ? Colors.redAccent : (secilenMod == 3 ? Colors.orangeAccent : Colors.blueAccent)).withOpacity(0.4), blurRadius: 30)],
                color: Colors.black,
              ),
              child: ClipRRect(child: oyunEkrani),
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            if (aktifOyun == null || aktifOyun!.oyunBitti) return;
            
            final dx = details.delta.dx;
            final dy = details.delta.dy;
            if (dx.abs() < kaydirmaHassasiyeti && dy.abs() < kaydirmaHassasiyeti) return;

            int oyuncuNo = 1;
            if (secilenMod == 2) {
              bool solTarafMi = details.globalPosition.dx < MediaQuery.of(context).size.width / 2;
              oyuncuNo = solTarafMi ? 1 : 2;
            }

            if (dx.abs() > dy.abs()) {
              aktifOyun!.yonUygula(dx > 0 ? Yon.sag : Yon.sol, oyuncuNo);
            } else {
              aktifOyun!.yonUygula(dy > 0 ? Yon.asagi : Yon.yukari, oyuncuNo);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              oyunEkrani, 
              if (secilenMod > 0) ...[
                Positioned(
                  top: 30, left: 40,
                  child: ValueListenableBuilder<int>(
                    valueListenable: aktifOyun!.skorNotifier,
                    builder: (context, skor, child) {
                      String ustYazi = "OYUNCU 1";
                      if (secilenMod != 2) {
                        ustYazi = aktifOyun!.oyuncuAdi.isNotEmpty ? aktifOyun!.oyuncuAdi.toUpperCase() : "SENİN SKORUN";
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ustYazi, style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          Text("$skor", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                        ],
                      );
                    },
                  ),
                ),
                
                Positioned(
                  top: 30, right: 40,
                  child: (secilenMod == 1 || secilenMod == 3) 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(secilenMod == 3 ? "ÖDÜL" : "REKOR", style: TextStyle(color: Colors.amber.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        Text(secilenMod == 3 ? "30G" : "$klasikRekor", style: TextStyle(color: Colors.amber, fontSize: 40, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : ValueListenableBuilder<int>(
                      valueListenable: aktifOyun!.skorNotifier2,
                      builder: (context, skor, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("OYUNCU 2", style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                            Text("$skor", style: TextStyle(color: Colors.redAccent, fontSize: 40, fontWeight: FontWeight.bold)),
                          ],
                        );
                      },
                    ),
                ),

                if (secilenMod == 3 || secilenMod == 0)
                  Positioned(
                    bottom: 30, left: 40,
                    child: ValueListenableBuilder<int>(
                      valueListenable: aktifOyun!.uiTetikleyici,
                      builder: (context, val, child) {
                        if (secilenMod == 3) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("🎯 HEDEFLER", style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                              SizedBox(height: 8),
                              Text("🍎 Kırmızı Yem: ${aktifOyun!.toplananHareketli} / $gHedefHareketli", style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text("⚡ Hız Yemi: ${aktifOyun!.toplananHiz} / $gHedefHiz", style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text("💰 Altın Para: ${aktifOyun!.toplananAltin} / $gHedefAltin", style: TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
                            ]
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("⚔️ SAVAŞ DURUMU", style: TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                              SizedBox(height: 8),
                              Text("Kalan Rakip: ${aktifOyun!.yapayZekalar.length}", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text("Lider AI Skoru: ${aktifOyun!.aiSkoru} / ${gHedefYem.toInt() * 10}", style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                            ]
                          );
                        }
                      }
                    )
                  )
              ]
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(
            game: SnakeGame(oyuncuAdi: "", zorlukSeviyesi: 2, hedefYem: 10, rakipSayisi: 1, klasikModMu: false, ikiKisilikMi: false, gunlukModMu: false, seciliAksesuarlar: []), 
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
                width: MediaQuery.of(context).size.width * 0.72, 
                constraints: BoxConstraints(maxWidth: 480), 
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7), 
                  borderRadius: BorderRadius.circular(15), 
                  border: Border.all(color: secilenMod == 0 ? Colors.green : (secilenMod == 1 ? Colors.blueAccent : (secilenMod == 3 ? Colors.orangeAccent : Colors.redAccent)), width: 2), 
                  boxShadow: [BoxShadow(color: (secilenMod == 0 ? Colors.green : (secilenMod == 1 ? Colors.blueAccent : (secilenMod == 3 ? Colors.orangeAccent : Colors.redAccent))).withOpacity(0.3), blurRadius: 15)]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("SNAKE DUEL AI", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)), 
                    SizedBox(height: 10),
                    
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: Text("Battle Royale", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: secilenMod == 0 ? Colors.black : Colors.white)),
                            selected: secilenMod == 0, selectedColor: Colors.greenAccent, backgroundColor: Colors.grey[800],
                            onSelected: (val) { setState(() { secilenMod = 0; gSecilenMod = 0; }); veriKaydet(); },
                          ),
                          SizedBox(width: 5),
                          ChoiceChip(
                            label: Text("Solo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: secilenMod == 1 ? Colors.black : Colors.white)),
                            selected: secilenMod == 1, selectedColor: Colors.blueAccent, backgroundColor: Colors.grey[800],
                            onSelected: (val) { setState(() { secilenMod = 1; gSecilenMod = 1; }); veriKaydet(); },
                          ),
                          SizedBox(width: 5),
                          ChoiceChip(
                            label: Text("1v1 Düello", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: secilenMod == 2 ? Colors.black : Colors.white)),
                            selected: secilenMod == 2, selectedColor: Colors.redAccent, backgroundColor: Colors.grey[800],
                            onSelected: (val) { setState(() { secilenMod = 2; gSecilenMod = 2; }); veriKaydet(); },
                          ),
                          SizedBox(width: 5),
                          ChoiceChip(
                            label: Text("Günlük Görev", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: secilenMod == 3 ? Colors.black : Colors.white)),
                            selected: secilenMod == 3, selectedColor: Colors.orangeAccent, backgroundColor: Colors.grey[800],
                            onSelected: (val) { setState(() { secilenMod = 3; gSecilenMod = 3; }); veriKaydet(); },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),

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
                    
                    if (secilenMod != 2) ...[
                      SizedBox(
                        height: 35, 
                        child: TextField(
                          controller: isimKontrolcusu, 
                          style: TextStyle(color: Colors.white, fontSize: 13), 
                          decoration: InputDecoration(
                            isDense: true, 
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0), 
                            labelText: "Savaşçı Adın", 
                            labelStyle: TextStyle(color: Colors.white70, fontSize: 13), 
                            prefixIcon: Icon(Icons.person, color: Colors.white70, size: 18), 
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)), 
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green, width: 2))
                          ),
                          onChanged: (deger) { gOyuncuAdi = deger; veriKaydet(); },
                        ),
                      ), 
                      SizedBox(height: 8),
                    ],

                    if (secilenMod == 0) ...[
                      Text("Rakip Yılan Sayısı: ${gRakipSayisi.toInt()}", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 24, child: Slider(value: gRakipSayisi, min: 1.0, max: 5.0, divisions: 4, activeColor: Colors.red, inactiveColor: Colors.white24, onChanged: (deger) { setState(() => gRakipSayisi = deger); veriKaydet(); })),
                      Text("Oyun Sonu Hedefi: ${gHedefYem.toInt()} Yem", style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 24, child: Slider(value: gHedefYem, min: 5.0, max: 20.0, divisions: 15, activeColor: Colors.amber, inactiveColor: Colors.white24, onChanged: (deger) { setState(() => gHedefYem = deger); veriKaydet(); })),
                      Text("AI Zorluk: ${zorlukMetniAl(gSecilenZorluk)}", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 24, child: Slider(value: gSecilenZorluk, min: 1.0, max: 3.0, divisions: 2, activeColor: Colors.green, inactiveColor: Colors.white24, onChanged: (deger) { setState(() => gSecilenZorluk = deger); veriKaydet(); })),
                    ] else if (secilenMod == 1) ...[
                      SizedBox(height: 5),
                      Text("🐍 SOLO REKORUN: $klasikRekor 🐍", style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("Her yemde %2 daha hızlanırsın!", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      SizedBox(height: 20),
                    ] else if (secilenMod == 2) ...[
                      SizedBox(height: 10),
                      Text("⚔️ 1 VS 1 DÜELLO ⚔️", style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("Sol ekran: Oyuncu 1 | Sağ Ekran: Oyuncu 2", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      SizedBox(height: 20),
                    ] else if (secilenMod == 3) ...[
                      SizedBox(height: 5),
                      Text("🎯 GÜNLÜK GÖREV 🎯", style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      if (gGorevTamamlandi)
                        Text("Bugünün görevini tamamladın!\nYeni görev için yarına bekle.", textAlign: TextAlign.center, style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold))
                      else ...[
                        Text("Hedef: $gHedefHareketli Hareketli Yem, $gHedefAltin Altın, $gHedefHiz Hız Yemi", style: TextStyle(color: Colors.white, fontSize: 12)),
                        Text("Ödül: 30 Altın!", style: TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                      SizedBox(height: 20),
                    ],
                    
                    SizedBox(height: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secilenMod == 0 ? Colors.green : (secilenMod == 1 ? Colors.blueAccent : (secilenMod == 3 ? Colors.orangeAccent : Colors.redAccent)), 
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ), 
                      onPressed: (secilenMod == 3 && gGorevTamamlandi) ? null : () { 
                        setState(() { 
                          if (isimKontrolcusu.text.isNotEmpty) gOyuncuAdi = isimKontrolcusu.text; 
                          veriKaydet(); 
                          aktifOyun = SnakeGame(
                            oyuncuAdi: gOyuncuAdi, 
                            zorlukSeviyesi: gSecilenZorluk.toInt(), 
                            hedefYem: secilenMod > 0 ? 9999 : gHedefYem.toInt(), 
                            rakipSayisi: secilenMod == 0 ? gRakipSayisi.toInt() : 0,
                            klasikModMu: secilenMod == 1,
                            ikiKisilikMi: secilenMod == 2,
                            gunlukModMu: secilenMod == 3,
                            seciliAksesuarlar: aktifAksesuarlar 
                          ); 
                          oyunBasladi = true; 
                        }); 
                      }, 
                      child: Text((secilenMod == 3 && gGorevTamamlandi) ? "GÖREV TAMAMLANDI" : "SAVAŞI BAŞLAT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))
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
      appBar: AppBar(title: Text("AYARLAR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.black, leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Colors.greenAccent), onPressed: () => Navigator.of(context).pop())),
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
                  Padding(padding: const EdgeInsets.only(left: 10), child: Text("Kaydırma Hassasiyeti: ${kaydirmaHassasiyeti.toInt()}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))), 
                  Slider(value: kaydirmaHassasiyeti, min: 1.0, max: 20.0, divisions: 19, activeColor: Colors.greenAccent, inactiveColor: Colors.white24, onChanged: (yeniBoyut) { setState(() => kaydirmaHassasiyeti = yeniBoyut); veriKaydet(); }),
                  Padding(padding: const EdgeInsets.only(left: 10), child: Text("Not: Düşük değerler parmağınızın ufak hareketini algılar.", style: TextStyle(color: Colors.white54, fontSize: 12))),
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

class _MagazaEkraniState extends State<MagazaEkrani> with SingleTickerProviderStateMixin {
  late TabController tabController;

  final List<Map<String, dynamic>> skinVitrin = [ 
    {"isim": "Klasik Yeşil", "fiyat": 0, "renk": Colors.green}, 
    {"isim": "Neon Mor", "fiyat": 20, "renk": Colors.purpleAccent}, 
    {"isim": "Ateş Kırmızısı", "fiyat": 50, "renk": Colors.redAccent}, 
    {"isim": "Saf Altın", "fiyat": 100, "renk": Colors.amber} 
  ];

  final List<Map<String, dynamic>> aksesuarVitrin = [
    {"isim": "Hepsini Çıkar", "fiyat": 0, "ikon": "❌"},
    {"isim": "Koca Burun", "fiyat": 100, "ikon": "👃"},
    {"isim": "Komik Ağız", "fiyat": 100, "ikon": "👄"},
    {"isim": "Siyah Gözlük", "fiyat": 150, "ikon": "🕶️"},
    {"isim": "Kırmızı Gözlük", "fiyat": 150, "ikon": "👓"},
    {"isim": "3D Gözlük", "fiyat": 200, "ikon": "🎥"},
    {"isim": "Kral Tacı", "fiyat": 300, "ikon": "👑"},
  ];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  void skinIslemi(String isim, int fiyat) {
    if (sahipOlunanSkinler.contains(isim)) { 
      setState(() { aktifSkin = isim; }); veriKaydet(); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$isim kuşandın!"), backgroundColor: Colors.green)); 
    } else {
      if (toplamAltin >= fiyat) { 
        setState(() { toplamAltin -= fiyat; sahipOlunanSkinler.add(isim); aktifSkin = isim; }); veriKaydet(); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$isim satın alındı!"), backgroundColor: Colors.amber)); 
      } else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Yetersiz Altın!"), backgroundColor: Colors.red)); }
    }
  }

  void aksesuarIslemi(String isim, int fiyat) {
    if (isim == "Hepsini Çıkar") {
      setState(() { aktifAksesuarlar.clear(); });
      veriKaydet();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bütün aksesuarlar çıkarıldı!"), backgroundColor: Colors.blueGrey)); 
      return;
    }

    if (sahipOlunanAksesuarlar.contains(isim)) { 
      setState(() { 
        if (aktifAksesuarlar.contains(isim)) {
          aktifAksesuarlar.remove(isim); 
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$isim çıkarıldı!"), backgroundColor: Colors.redAccent)); 
        } else {
          aktifAksesuarlar.add(isim); 
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$isim takıldı!"), backgroundColor: Colors.green)); 
        }
      }); 
      veriKaydet(); 
    } else {
      if (toplamAltin >= fiyat) { 
        setState(() { 
          toplamAltin -= fiyat; 
          sahipOlunanAksesuarlar.add(isim); 
          aktifAksesuarlar.add(isim); 
        }); 
        veriKaydet(); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$isim satın alındı ve takıldı!"), backgroundColor: Colors.amber)); 
      } else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Yetersiz Altın!"), backgroundColor: Colors.red)); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text("MAĞAZA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.black, 
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Colors.amber), onPressed: () => Navigator.of(context).pop()), 
        actions: [Center(child: Padding(padding: const EdgeInsets.only(right: 20), child: Text("$toplamAltin Altın", style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold))))],
        bottom: TabBar(
          controller: tabController, indicatorColor: Colors.amber, labelColor: Colors.amber, unselectedLabelColor: Colors.white54,
          tabs: [Tab(icon: Icon(Icons.palette), text: "RENKLER"), Tab(icon: Icon(Icons.face), text: "AKSESUARLAR")],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          ListView.builder(
            padding: EdgeInsets.all(20), itemCount: skinVitrin.length, 
            itemBuilder: (context, index) {
              var urun = skinVitrin[index]; 
              bool sahipMi = sahipOlunanSkinler.contains(urun["isim"]); bool giyiliMi = aktifSkin == urun["isim"];
              return Card(
                color: Colors.black, margin: EdgeInsets.only(bottom: 15), shape: RoundedRectangleBorder(side: BorderSide(color: urun["renk"], width: 2), borderRadius: BorderRadius.circular(10)), 
                child: ListTile(
                  leading: Icon(Icons.square, color: urun["renk"], size: 30), 
                  title: Text(urun["isim"], style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), subtitle: Text(sahipMi ? "Senin" : "${urun["fiyat"]} Altın", style: TextStyle(color: sahipMi ? Colors.green : Colors.amber)), 
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: giyiliMi ? Colors.grey : (sahipMi ? Colors.green : Colors.amber)), 
                    onPressed: giyiliMi ? null : () => skinIslemi(urun["isim"], urun["fiyat"]), 
                    child: Text(giyiliMi ? "KUŞANILDI" : (sahipMi ? "KUŞAN" : "SATIN AL"), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
                  )
                )
              );
            }
          ),
          ListView.builder(
            padding: EdgeInsets.all(20), itemCount: aksesuarVitrin.length, 
            itemBuilder: (context, index) {
              var urun = aksesuarVitrin[index]; 
              bool sahipMi = sahipOlunanAksesuarlar.contains(urun["isim"]) || urun["isim"] == "Hepsini Çıkar"; 
              bool giyiliMi = aktifAksesuarlar.contains(urun["isim"]);
              return Card(
                color: Colors.black, margin: EdgeInsets.only(bottom: 15), shape: RoundedRectangleBorder(side: BorderSide(color: Colors.white38, width: 2), borderRadius: BorderRadius.circular(10)), 
                child: ListTile(
                  leading: Text(urun["ikon"], style: TextStyle(fontSize: 24)), 
                  title: Text(urun["isim"], style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), subtitle: Text(sahipMi ? (urun["isim"] == "Hepsini Çıkar" ? "Ücretsiz" : "Senin") : "${urun["fiyat"]} Altın", style: TextStyle(color: sahipMi ? Colors.green : Colors.amber)), 
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: urun["isim"] == "Hepsini Çıkar" ? Colors.redAccent : (giyiliMi ? Colors.blueGrey : (sahipMi ? Colors.green : Colors.amber))), 
                    onPressed: () => aksesuarIslemi(urun["isim"], urun["fiyat"]), 
                    child: Text(urun["isim"] == "Hepsini Çıkar" ? "TEMİZLE" : (giyiliMi ? "ÇIKAR" : (sahipMi ? "TAK" : "SATIN AL")), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
                  )
                )
              );
            }
          ),
        ]
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
    String bitisSebebi = game.bitisMesaji.isNotEmpty ? game.bitisMesaji : "BÜTÜN RAKİPLER ELENDİ!"; 

    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20), width: MediaQuery.of(context).size.width * 0.85, constraints: BoxConstraints(maxWidth: 400), 
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.85), borderRadius: BorderRadius.circular(20), border: Border.all(color: temaRengi, width: 3)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("OYUN BİTTİ", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2)), 
              SizedBox(height: 5),
              Text(bitisSebebi, textAlign: TextAlign.center, style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold)), 
              SizedBox(height: 10),
              
              if (game.gunlukModMu) ...[
                Text("GÖREV DURUMU:", style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(gGorevTamamlandi ? "BAŞARILI!" : "BAŞARISIZ OLDU", textAlign: TextAlign.center, style: TextStyle(color: gGorevTamamlandi ? Colors.green : Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)), 
              ] else if (!game.klasikModMu) ...[
                Text("KAZANAN:", style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(game.kazanan.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(color: temaRengi, fontSize: 24, fontWeight: FontWeight.bold)), 
              ] else if (game.ikiKisilikMi) ...[
                Text("KAZANAN:", style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(game.kazanan, textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent, fontSize: 32, fontWeight: FontWeight.bold)), 
              ] else ...[
                Text("KLASİK MOD SKORUN:", style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text("${game.oyuncuSkoru}", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueAccent, fontSize: 36, fontWeight: FontWeight.bold)), 
              ],

              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), 
                child: Column(
                  children: [
                    if (game.gunlukModMu && gGorevTamamlandi) Text("+30 Altın (Günlük Görev Ödülü!)", style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)), 
                    if (senKazandin && !game.klasikModMu && !game.gunlukModMu) Text("+${game.hedefYem} Altın (Görev Ödülü)", style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)), 
                    if (game.klasikModMu && !game.ikiKisilikMi && !game.gunlukModMu) Text("+${(game.oyuncuSkoru ~/ 20)} Altın (Performans Ödülü)", style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)), 
                    Text("Güncel Servetin: $toplamAltin Altın", style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold))
                  ]
                )
              ), 
              
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh, color: Colors.black), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10)), 
                onPressed: () {
                  FlameAudio.bgm.stop(); 
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AnaMenu()));
                }, 
                label: Text("ANA MENÜ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black))
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SnakeGame extends FlameGame with KeyboardEvents {
  final String oyuncuAdi; 
  final int zorlukSeviyesi; 
  final int hedefYem; 
  final int rakipSayisi; 
  final bool klasikModMu; 
  final bool ikiKisilikMi; 
  final bool gunlukModMu; 
  final List<String> seciliAksesuarlar; 

  final ValueNotifier<int> skorNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> skorNotifier2 = ValueNotifier<int>(0); 
  final ValueNotifier<int> uiTetikleyici = ValueNotifier<int>(0);

  late AudioPool yemSesiHavuzu;
  late AudioPool altinSesiHavuzu;
  bool seslerHazir = false;

  SnakeGame({
    required this.oyuncuAdi, required this.zorlukSeviyesi, required this.hedefYem, 
    required this.rakipSayisi, required this.klasikModMu, required this.ikiKisilikMi,
    required this.gunlukModMu, required this.seciliAksesuarlar
  });

  final double hucreBoyutu = 20.0;
  late OyuncuYilani oyuncu; 
  OyuncuYilani? oyuncu2; 
  
  late Yem yem; 
  late HizYemi hizYemi; 
  late AltinPara altinPara; 
  List<YapayZekaYilani> yapayZekalar = []; 
  Map<YapayZekaYilani, int> bireyselAiSkorlari = {}; 

  bool oyunBitti = false; 
  String kazanan = "";
  String bitisMesaji = ""; 

  int yatayKareSayisi = 0; 
  int dikeyKareSayisi = 0;
  int oyuncuSkoru = 0; 
  int oyuncu2Skoru = 0; 
  int aiSkoru = 0; 
  List<Vector2> engelKonumlari = []; 
  final Random _rastgele = Random();

  int toplananHareketli = 0;
  int toplananAltin = 0;
  int toplananHiz = 0;
  double yemHareketZamani = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    await FlameAudio.audioCache.loadAll(['fon.mp3', 'yem.mp3', 'gum.mp3', 'altin.mp3']);
    yemSesiHavuzu = await FlameAudio.createPool('yem.mp3', minPlayers: 3, maxPlayers: 10);
    altinSesiHavuzu = await FlameAudio.createPool('altin.mp3', minPlayers: 2, maxPlayers: 5);
    seslerHazir = true;
    
    FlameAudio.bgm.play('fon.mp3', volume: 0.25);
    
    dikeyKareSayisi = (size.y / hucreBoyutu).floor();
    yatayKareSayisi = (klasikModMu || gunlukModMu) ? dikeyKareSayisi : (size.x / hucreBoyutu).floor(); 

    for (int x = 0; x < yatayKareSayisi; x++) { engelKonumlari.add(Vector2(x.toDouble(), 0)); engelKonumlari.add(Vector2(x.toDouble(), (dikeyKareSayisi - 1).toDouble())); }
    for (int y = 0; y < dikeyKareSayisi; y++) { engelKonumlari.add(Vector2(0, y.toDouble())); engelKonumlari.add(Vector2((yatayKareSayisi - 1).toDouble(), y.toDouble())); }

    int tasLimiti = 0;
    if (!klasikModMu && !gunlukModMu && !ikiKisilikMi) {
      tasLimiti = 20; 
    } else if (ikiKisilikMi) {
      tasLimiti = 10; 
    } else {
      tasLimiti = 0;  
    }

    int uretilenIcEngel = 0;
    while (uretilenIcEngel < tasLimiti) {
      int x = _rastgele.nextInt(yatayKareSayisi - 2) + 1; int y = _rastgele.nextInt(dikeyKareSayisi - 2) + 1;
      Vector2 yeniTasKonumu = Vector2(x.toDouble(), y.toDouble());
      bool tasVarMi = engelKonumlari.any((tas) => tas.x == yeniTasKonumu.x && tas.y == yeniTasKonumu.y);
      bool baslangicAlaniMi = (x < 8 && y < 8) || (x > yatayKareSayisi - 8 && y > dikeyKareSayisi - 8);
      if (!tasVarMi && !baslangicAlaniMi) { engelKonumlari.add(yeniTasKonumu); uretilenIcEngel++; }
    }

    oyuncu = OyuncuYilani(hucreBoyutu: hucreBoyutu, seciliSkin: aktifSkin, seciliAksesuarlar: seciliAksesuarlar);
    oyuncu.govde = [Vector2(5, 5), Vector2(5, 4), Vector2(5, 3)];
    add(oyuncu);

    if (ikiKisilikMi) {
      oyuncu2 = OyuncuYilani(hucreBoyutu: hucreBoyutu, seciliSkin: "Ateş Kırmızısı", seciliAksesuarlar: []); 
      oyuncu2!.govde = [
        Vector2((yatayKareSayisi - 5).toDouble(), (dikeyKareSayisi - 5).toDouble()),
        Vector2((yatayKareSayisi - 5).toDouble(), (dikeyKareSayisi - 4).toDouble()),
        Vector2((yatayKareSayisi - 5).toDouble(), (dikeyKareSayisi - 3).toDouble()),
      ];
      oyuncu2!.mevcutYon = Yon.yukari;
      add(oyuncu2!);
    }

    if (!klasikModMu && !gunlukModMu && !ikiKisilikMi) {
      for (int i = 0; i < rakipSayisi; i++) {
        var ai = YapayZekaYilani(hucreBoyutu: hucreBoyutu, yatayKare: yatayKareSayisi, dikeyKare: dikeyKareSayisi, zorlukSeviyesi: zorlukSeviyesi);
        double basX = 5; double basY = 5;
        if (i == 0) { basX = (yatayKareSayisi - 5).toDouble(); basY = 5; } else if (i == 1) { basX = 5; basY = (dikeyKareSayisi - 5).toDouble(); } else if (i == 2) { basX = (yatayKareSayisi - 5).toDouble(); basY = (dikeyKareSayisi - 5).toDouble(); } else if (i == 3) { basX = (yatayKareSayisi ~/ 2).toDouble(); basY = 5; } else if (i == 4) { basX = (yatayKareSayisi ~/ 2).toDouble(); basY = (dikeyKareSayisi - 5).toDouble(); }
        ai.govde = [Vector2(basX, basY), Vector2(basX, basY - 1), Vector2(basX, basY - 2)]; ai.mevcutYon = Yon.asagi; 
        yapayZekalar.add(ai); add(ai); bireyselAiSkorlari[ai] = 0; 
      }
    }

    yem = Yem(hucreBoyutu: hucreBoyutu, yatayKareSayisi: yatayKareSayisi, dikeyKareSayisi: dikeyKareSayisi); add(yem); 
    altinPara = AltinPara(hucreBoyutu: hucreBoyutu, yatayKareSayisi: yatayKareSayisi, dikeyKareSayisi: dikeyKareSayisi); add(altinPara);
    hizYemi = HizYemi(hucreBoyutu: hucreBoyutu, yatayKareSayisi: yatayKareSayisi, dikeyKareSayisi: dikeyKareSayisi); add(hizYemi);
    
    // YENİLİK: Unutulan Taş Çizdirme Kodu eklendi! (Artık Battle Royale'de taşlar görünecek)
    for (var t in engelKonumlari) { add(Tas(hucreBoyutu: hucreBoyutu, baslangicKonumu: t)); }
  }

  @override
  Color backgroundColor() => Colors.black;

  void yonUygula(Yon yeniYon, int oyuncuNo) {
    if (oyuncuNo == 1) {
      oyuncu.yonKuyrugaEkle(yeniYon);
    } else if (oyuncuNo == 2 && ikiKisilikMi && oyuncu2 != null) {
      oyuncu2!.yonKuyrugaEkle(yeniYon);
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp)) yonUygula(Yon.yukari, 1);
    else if (keysPressed.contains(LogicalKeyboardKey.arrowDown)) yonUygula(Yon.asagi, 1);
    else if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) yonUygula(Yon.sol, 1);
    else if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) yonUygula(Yon.sag, 1);
    
    if (ikiKisilikMi) {
      if (keysPressed.contains(LogicalKeyboardKey.keyW)) yonUygula(Yon.yukari, 2);
      else if (keysPressed.contains(LogicalKeyboardKey.keyS)) yonUygula(Yon.asagi, 2);
      else if (keysPressed.contains(LogicalKeyboardKey.keyA)) yonUygula(Yon.sol, 2);
      else if (keysPressed.contains(LogicalKeyboardKey.keyD)) yonUygula(Yon.sag, 2);
    }
    return super.onKeyEvent(event, keysPressed);
  }

  void yemleriKacir(dynamic hedef) {
    if (hedef.konum == null) return;
    Vector2 k = hedef.konum!;
    List<Vector2> kacanAdimlar = [];
    if (k.x > 1) kacanAdimlar.add(Vector2(k.x - 1, k.y));
    if (k.x < yatayKareSayisi - 2) kacanAdimlar.add(Vector2(k.x + 1, k.y));
    if (k.y > 1) kacanAdimlar.add(Vector2(k.x, k.y - 1));
    if (k.y < dikeyKareSayisi - 2) kacanAdimlar.add(Vector2(k.x, k.y + 1));

    kacanAdimlar.removeWhere((v) => 
      engelKonumlari.any((e) => e.x == v.x && e.y == v.y) || 
      oyuncu.govde.any((g) => g.x == v.x && g.y == v.y)
    );

    if (kacanAdimlar.isNotEmpty) {
      hedef.konum = kacanAdimlar[_rastgele.nextInt(kacanAdimlar.length)];
    }
  }

  void goreviKontrolEt() {
    if (gunlukModMu && !gGorevTamamlandi) {
      if (toplananHareketli >= gHedefHareketli && toplananAltin >= gHedefAltin && toplananHiz >= gHedefHiz) {
        bitisMesaji = "GÖREV BAŞARILI! 30 ALTIN KAZANDIN!";
        gGorevTamamlandi = true;
        toplamAltin += 30;
        veriKaydet();
        oyunuBitir(oyuncuAdi);
      }
    }
  }

  @override
  void update(double dt) {
    if (oyunBitti) return;
    super.update(dt);
    
    if (gunlukModMu) {
      yemHareketZamani += dt;
      if (yemHareketZamani >= 0.6) {
        yemHareketZamani = 0;
        yemleriKacir(yem);
        yemleriKacir(hizYemi); 
      }
    }

    final kafa1 = oyuncu.govde.first;

    bool p2Oldu = false;
    if (ikiKisilikMi && oyuncu2 != null) {
      final kafa2 = oyuncu2!.govde.first;
      bool p2Duvar = kafa2.x < 0 || kafa2.x >= yatayKareSayisi || kafa2.y < 0 || kafa2.y >= dikeyKareSayisi || engelKonumlari.any((t) => t.x == kafa2.x && t.y == kafa2.y);
      bool p2Kendine = oyuncu2!.govde.skip(1).any((p) => p.x == kafa2.x && p.y == kafa2.y);
      bool p2P1eVurdu = oyuncu.govde.any((p) => p.x == kafa2.x && p.y == kafa2.y);
      p2Oldu = p2Duvar || p2Kendine || p2P1eVurdu;
      
      if (yem.konum != null && kafa2.x == yem.konum!.x && kafa2.y == yem.konum!.y) {
        if (seslerHazir) yemSesiHavuzu.start(volume: 0.4); 
        oyuncu2!.yemYedi(); yem.konumUret(); oyuncu2Skoru += 10; skorNotifier2.value = oyuncu2Skoru;
        try { oyuncu2!.kaliciHizArtir(); } catch(e) {}
      }
    }

    bool p1Duvar = kafa1.x < 0 || kafa1.x >= yatayKareSayisi || kafa1.y < 0 || kafa1.y >= dikeyKareSayisi || engelKonumlari.any((t) => t.x == kafa1.x && t.y == kafa1.y);
    bool p1Kendine = oyuncu.govde.skip(1).any((p) => p.x == kafa1.x && p.y == kafa1.y);
    bool p1RakibeCarpti = (!klasikModMu && !gunlukModMu) ? yapayZekalar.any((ai) => ai.govde.any((p) => p.x == kafa1.x && p.y == kafa1.y)) : (ikiKisilikMi ? oyuncu2!.govde.any((p) => p.x == kafa1.x && p.y == kafa1.y) : false);
    bool p1Oldu = p1Duvar || p1Kendine || p1RakibeCarpti;

    if (p1Oldu && p2Oldu) { 
      bitisMesaji = "KAFA KAFAYA ÇARPIŞTINIZ!"; 
      oyunuBitir("BERABERE"); 
      return;
    } else if (p2Oldu) { 
      bitisMesaji = "OYUNCU 1 (Yeşil) KAZANDI!"; 
      oyunuBitir("OYUNCU 1"); 
      return; 
    } else if (p1Oldu) { 
      if (ikiKisilikMi) {
        bitisMesaji = "OYUNCU 2 (Kırmızı) KAZANDI!"; 
        oyunuBitir("OYUNCU 2");
      } else if (gunlukModMu) {
        String sebep = p1Kendine ? "Kendi kuyruğunu yedin!" : "Duvara tosladın!";
        bitisMesaji = "GÖREV BAŞARISIZ!\n$sebep";
        oyunuBitir(oyuncuAdi);
      } else {
        String isim = oyuncuAdi.isEmpty ? "Şampiyon" : oyuncuAdi;
        if (p1Duvar) {
          bitisMesaji = "$isim, kafayı taşa vurdun!";
        } else if (p1Kendine) {
          bitisMesaji = "Hey $isim, kendi kuyruğunu mu yiyorsun!";
        } else if (p1RakibeCarpti) {
          bitisMesaji = "Dostum o yem değil, rakibin!";
        } else {
          bitisMesaji = "ÇARPIŞMA!";
        }
        oyunuBitir("Yapay Zeka");
      }
      return;
    }

    if (!klasikModMu && !gunlukModMu && !ikiKisilikMi) {
      List<YapayZekaYilani> olenYilanlar = [];
      for (var ai in yapayZekalar) {
        final aiKafa = ai.govde.first;
        bool carptiMi = aiKafa.x < 0 || aiKafa.x >= yatayKareSayisi || aiKafa.y < 0 || aiKafa.y >= dikeyKareSayisi || 
                        engelKonumlari.any((t) => t.x == aiKafa.x && t.y == aiKafa.y) || 
                        oyuncu.govde.any((p) => p.x == aiKafa.x && p.y == aiKafa.y) || 
                        ai.govde.skip(1).any((p) => p.x == aiKafa.x && p.y == aiKafa.y);
        
        if (!carptiMi) {
          for (var digerAi in yapayZekalar) {
            if (ai != digerAi && digerAi.govde.any((p) => p.x == aiKafa.x && p.y == aiKafa.y)) { carptiMi = true; break; }
          }
        }

        if (carptiMi) {
          olenYilanlar.add(ai);
        } else {
          if (yem.konum != null && aiKafa.x == yem.konum!.x && aiKafa.y == yem.konum!.y) { 
            if (seslerHazir) yemSesiHavuzu.start(volume: 0.3); 
            ai.yemYedi(); yem.konumUret(); 
            bireyselAiSkorlari[ai] = (bireyselAiSkorlari[ai] ?? 0) + 10;
            uiTetikleyici.value++; 
            if (bireyselAiSkorlari[ai]! >= hedefYem * 10) { bitisMesaji = "Çok yavaşsın çaylak!"; oyunuBitir("Yapay Zeka"); return; } 
          }
          if (hizYemi.konum != null && aiKafa.x == hizYemi.konum!.x && aiKafa.y == hizYemi.konum!.y) { ai.hizKazan(); hizYemi.konumUret(); }
          if (altinPara.konum != null && aiKafa.x == altinPara.konum!.x && aiKafa.y == altinPara.konum!.y) { altinPara.konumUret(); }
        }
      }

      for (var olen in olenYilanlar) { olen.oluMu = true; remove(olen); yapayZekalar.remove(olen); bireyselAiSkorlari.remove(olen); uiTetikleyici.value++; } 
      if (bireyselAiSkorlari.isNotEmpty) { aiSkoru = bireyselAiSkorlari.values.reduce(max); } else { aiSkoru = 0; }
      if (yapayZekalar.isEmpty) { bitisMesaji = "BÜTÜN RAKİPLER ELENDİ, MEYDAN SENİN!"; oyunuBitir(oyuncuAdi); return; }
    }

    if (yem.konum != null && kafa1.x == yem.konum!.x && kafa1.y == yem.konum!.y) { 
      if (seslerHazir) yemSesiHavuzu.start(volume: 0.4); 
      oyuncu.yemYedi(); yem.konumUret(); oyuncuSkoru += 10; skorNotifier.value = oyuncuSkoru; 
      
      if (gunlukModMu) { toplananHareketli++; goreviKontrolEt(); uiTetikleyici.value++; }

      if (klasikModMu) {
        if (!ikiKisilikMi && oyuncuSkoru > klasikRekor) { klasikRekor = oyuncuSkoru; }
        try { oyuncu.kaliciHizArtir(); } catch (e) {}
      } else if (!gunlukModMu && oyuncuSkoru >= hedefYem * 10) { bitisMesaji = "HEDEF YEME ULAŞTIN, ZAFER SENİN!"; oyunuBitir(oyuncuAdi); }
    }
    
    if (hizYemi.konum != null && kafa1.x == hizYemi.konum!.x && kafa1.y == hizYemi.konum!.y) { 
      oyuncu.hizKazan(); hizYemi.konumUret(); 
      if (gunlukModMu) { toplananHiz++; goreviKontrolEt(); uiTetikleyici.value++; }
    }
    
    if (altinPara.konum != null && kafa1.x == altinPara.konum!.x && kafa1.y == altinPara.konum!.y) { 
      if (seslerHazir) altinSesiHavuzu.start(volume: 0.8); 
      toplamAltin += 1; veriKaydet(); altinPara.konumUret(); 
      if (gunlukModMu) { toplananAltin++; goreviKontrolEt(); uiTetikleyici.value++; }
    }
  }

  void oyunuBitir(String kimKazandi) {
    if (oyunBitti) return; 
    
    FlameAudio.bgm.stop(); 
    FlameAudio.play('gum.mp3'); 

    oyunBitti = true; 
    kazanan = kimKazandi;
    if (!klasikModMu && !gunlukModMu && kazanan == oyuncuAdi && oyuncuAdi != "") {
      toplamAltin += hedefYem;
    } else if (klasikModMu && !ikiKisilikMi) {
      toplamAltin += (oyuncuSkoru ~/ 20); 
    }
    veriKaydet(); 
    pauseEngine(); 
    if (overlays.add('GameOver')) {}
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = Colors.white.withOpacity(0.1)..style = PaintingStyle.stroke;
    
    for (double x = 0; x <= yatayKareSayisi * hucreBoyutu; x += hucreBoyutu) canvas.drawLine(Offset(x, 0), Offset(x, dikeyKareSayisi * hucreBoyutu), paint);
    for (double y = 0; y <= dikeyKareSayisi * hucreBoyutu; y += hucreBoyutu) canvas.drawLine(Offset(0, y), Offset(yatayKareSayisi * hucreBoyutu, y), paint);
  }
}