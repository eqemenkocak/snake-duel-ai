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
int toplamAltin = 5000; // HİLE AKTİF! İstediğin zaman 0 yapıp alttaki satırı açarsın
List<String> sahipOlunanSkinler = ["Klasik Yeşil"]; 
String aktifSkin = "Klasik Yeşil"; 
double kaydirmaHassasiyeti = 5.0; 

// YENİLİK: Artık bir liste tutuyoruz!
List<String> sahipOlunanAksesuarlar = []; 
List<String> aktifAksesuarlar = []; 

String gOyuncuAdi = "";
double gSecilenZorluk = 2.0; 
double gHedefYem = 10.0; 
double gRakipSayisi = 1.0; 
int klasikRekor = 0; 
int gSecilenMod = 0; 

late SharedPreferences prefs; 

void veriYukle() {
  toplamAltin = 5000; 
  // toplamAltin = prefs.getInt('toplamAltin') ?? 0; 
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
}

Future<void> veriKaydet() async {
  await prefs.setInt('toplamAltin', toplamAltin);
  await prefs.setStringList('sahipOlunanSkinler', sahipOlunanSkinler);
  await prefs.setString('aktifSkin', aktifSkin);
  await prefs.setStringList('sahipOlunanAksesuarlar', sahipOlunanAksesuarlar);
  await prefs.setStringList('aktifAksesuarlar', aktifAksesuarlar); // Liste olarak kaydet
  await prefs.setDouble('kaydirmaHassasiyeti', kaydirmaHassasiyeti);

  await prefs.setString('gOyuncuAdi', gOyuncuAdi);
  await prefs.setDouble('gSecilenZorluk', gSecilenZorluk);
  await prefs.setDouble('gHedefYem', gHedefYem);
  await prefs.setDouble('gRakipSayisi', gRakipSayisi);
  await prefs.setInt('klasikRekor', klasikRekor); 
  await prefs.setInt('gSecilenMod', gSecilenMod); 
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
                border: Border.all(color: secilenMod == 2 ? Colors.redAccent : Colors.blueAccent, width: 4),
                boxShadow: [BoxShadow(color: (secilenMod == 2 ? Colors.redAccent : Colors.blueAccent).withOpacity(0.4), blurRadius: 30)],
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("OYUNCU 1", style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          Text("$skor", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                        ],
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 30, right: 40,
                  child: secilenMod == 1 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("REKOR", style: TextStyle(color: Colors.amber.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        Text("$klasikRekor", style: TextStyle(color: Colors.amber, fontSize: 40, fontWeight: FontWeight.bold)),
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
            game: SnakeGame(oyuncuAdi: "", zorlukSeviyesi: 2, hedefYem: 10, rakipSayisi: 1, klasikModMu: false, ikiKisilikMi: false, seciliAksesuarlar: []), 
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
                width: MediaQuery.of(context).size.width * 0.68, 
                constraints: BoxConstraints(maxWidth: 420), 
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7), 
                  borderRadius: BorderRadius.circular(15), 
                  border: Border.all(color: secilenMod == 0 ? Colors.green : (secilenMod == 1 ? Colors.blueAccent : Colors.redAccent), width: 2), 
                  boxShadow: [BoxShadow(color: (secilenMod == 0 ? Colors.green : (secilenMod == 1 ? Colors.blueAccent : Colors.redAccent)).withOpacity(0.3), blurRadius: 15)]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("SNAKE DUEL AI", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)), 
                    SizedBox(height: 10),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: Text("Battle Royale", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: secilenMod == 0 ? Colors.black : Colors.white)),
                          selected: secilenMod == 0,
                          selectedColor: Colors.greenAccent,
                          backgroundColor: Colors.grey[800],
                          onSelected: (val) { setState(() { secilenMod = 0; gSecilenMod = 0; }); veriKaydet(); },
                        ),
                        SizedBox(width: 5),
                        ChoiceChip(
                          label: Text("Solo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: secilenMod == 1 ? Colors.black : Colors.white)),
                          selected: secilenMod == 1,
                          selectedColor: Colors.blueAccent,
                          backgroundColor: Colors.grey[800],
                          onSelected: (val) { setState(() { secilenMod = 1; gSecilenMod = 1; }); veriKaydet(); },
                        ),
                        SizedBox(width: 5),
                        ChoiceChip(
                          label: Text("1v1 Düello", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: secilenMod == 2 ? Colors.black : Colors.white)),
                          selected: secilenMod == 2,
                          selectedColor: Colors.redAccent,
                          backgroundColor: Colors.grey[800],
                          onSelected: (val) { setState(() { secilenMod = 2; gSecilenMod = 2; }); veriKaydet(); },
                        ),
                      ],
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
                    
                    if (secilenMod == 0) ...[
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
                      Text("Rakip Yılan Sayısı: ${gRakipSayisi.toInt()}", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 24, child: Slider(value: gRakipSayisi, min: 1.0, max: 5.0, divisions: 4, activeColor: Colors.red, inactiveColor: Colors.white24, onChanged: (deger) { setState(() => gRakipSayisi = deger); veriKaydet(); })),
                      Text("Oyun Sonu Hedefi: ${gHedefYem.toInt()} Yem", style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 24, child: Slider(value: gHedefYem, min: 5.0, max: 20.0, divisions: 15, activeColor: Colors.amber, inactiveColor: Colors.white24, onChanged: (deger) { setState(() => gHedefYem = deger); veriKaydet(); })),
                      Text("AI Zorluk: ${zorlukMetniAl(gSecilenZorluk)}", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 24, child: Slider(value: gSecilenZorluk, min: 1.0, max: 3.0, divisions: 2, activeColor: Colors.green, inactiveColor: Colors.white24, onChanged: (deger) { setState(() => gSecilenZorluk = deger); veriKaydet(); })),
                    ] else if (secilenMod == 1) ...[
                      SizedBox(height: 10),
                      Text("🐍 SOLO REKORUN: $klasikRekor 🐍", style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("Her yemde %7 daha hızlanırsın!", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      SizedBox(height: 20),
                    ] else if (secilenMod == 2) ...[
                      SizedBox(height: 10),
                      Text("⚔️ 1 VS 1 DÜELLO ⚔️", style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("Sol ekran: Oyuncu 1 | Sağ Ekran: Oyuncu 2", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      SizedBox(height: 20),
                    ],
                    
                    SizedBox(height: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secilenMod == 0 ? Colors.green : (secilenMod == 1 ? Colors.blueAccent : Colors.redAccent), 
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ), 
                      onPressed: () { 
                        setState(() { 
                          if (isimKontrolcusu.text.isNotEmpty) gOyuncuAdi = isimKontrolcusu.text; 
                          veriKaydet(); 
                          aktifOyun = SnakeGame(
                            oyuncuAdi: gOyuncuAdi, 
                            zorlukSeviyesi: gSecilenZorluk.toInt(), 
                            hedefYem: secilenMod > 0 ? 9999 : gHedefYem.toInt(), 
                            rakipSayisi: secilenMod > 0 ? 0 : gRakipSayisi.toInt(),
                            klasikModMu: secilenMod > 0,
                            ikiKisilikMi: secilenMod == 2,
                            seciliAksesuarlar: aktifAksesuarlar // YENİLİK: Listeyi gönder
                          ); 
                          oyunBasladi = true; 
                        }); 
                      }, 
                      child: Text("SAVAŞI BAŞLAT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))
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
    {"isim": "Hepsini Çıkar", "fiyat": 0, "ikon": "❌"}, // YENİLİK
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

  // YENİLİK: Çoklu Aksesuar Mantığı
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
          aktifAksesuarlar.remove(isim); // Giyiliyse çıkar
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$isim çıkarıldı!"), backgroundColor: Colors.redAccent)); 
        } else {
          aktifAksesuarlar.add(isim); // Değilse tak
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$isim takıldı!"), backgroundColor: Colors.green)); 
        }
      }); 
      veriKaydet(); 
    } else {
      if (toplamAltin >= fiyat) { 
        setState(() { 
          toplamAltin -= fiyat; 
          sahipOlunanAksesuarlar.add(isim); 
          aktifAksesuarlar.add(isim); // Satın alınca direkt taksın
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
              
              if (!game.klasikModMu) ...[
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
                    if (senKazandin && !game.klasikModMu) Text("+${game.hedefYem} Altın (Görev Ödülü)", style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)), 
                    if (game.klasikModMu && !game.ikiKisilikMi) Text("+${(game.oyuncuSkoru ~/ 20)} Altın (Performans Ödülü)", style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)), 
                    Text("Güncel Servetin: $toplamAltin Altın", style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold))
                  ]
                )
              ), 
              
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh, color: Colors.black), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10)), 
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

class SnakeGame extends FlameGame with KeyboardEvents {
  final String oyuncuAdi; 
  final int zorlukSeviyesi; 
  final int hedefYem; 
  final int rakipSayisi; 
  final bool klasikModMu; 
  final bool ikiKisilikMi; 
  final List<String> seciliAksesuarlar; // YENİLİK

  final ValueNotifier<int> skorNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> skorNotifier2 = ValueNotifier<int>(0); 

  SnakeGame({
    required this.oyuncuAdi, required this.zorlukSeviyesi, required this.hedefYem, 
    required this.rakipSayisi, required this.klasikModMu, required this.ikiKisilikMi,
    required this.seciliAksesuarlar
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
  late TextPaint yaziFircasi;
  List<Vector2> engelKonumlari = []; 
  final Random _rastgele = Random();

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    dikeyKareSayisi = (size.y / hucreBoyutu).floor();
    yatayKareSayisi = klasikModMu ? dikeyKareSayisi : (size.x / hucreBoyutu).floor(); 

    for (int x = 0; x < yatayKareSayisi; x++) { engelKonumlari.add(Vector2(x.toDouble(), 0)); engelKonumlari.add(Vector2(x.toDouble(), (dikeyKareSayisi - 1).toDouble())); }
    for (int y = 0; y < dikeyKareSayisi; y++) { engelKonumlari.add(Vector2(0, y.toDouble())); engelKonumlari.add(Vector2((yatayKareSayisi - 1).toDouble(), y.toDouble())); }

    int uretilenIcEngel = 0;
    int tasLimiti = klasikModMu ? 10 : 20; 
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

    if (!klasikModMu) {
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

    if (!klasikModMu) {
      hizYemi = HizYemi(hucreBoyutu: hucreBoyutu, yatayKareSayisi: yatayKareSayisi, dikeyKareSayisi: dikeyKareSayisi); add(hizYemi);
    }

    for (var t in engelKonumlari) { add(Tas(hucreBoyutu: hucreBoyutu, baslangicKonumu: t)); }
    yaziFircasi = TextPaint(style: const TextStyle(fontSize: 14.0, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Arial'));
  }

  @override
  Color backgroundColor() => Colors.black;

  void yonUygula(Yon yeniYon, int oyuncuNo) {
    if (oyuncuNo == 1) {
      if (yeniYon == Yon.yukari && oyuncu.mevcutYon != Yon.asagi) oyuncu.mevcutYon = Yon.yukari;
      else if (yeniYon == Yon.asagi && oyuncu.mevcutYon != Yon.yukari) oyuncu.mevcutYon = Yon.asagi;
      else if (yeniYon == Yon.sol && oyuncu.mevcutYon != Yon.sag) oyuncu.mevcutYon = Yon.sol;
      else if (yeniYon == Yon.sag && oyuncu.mevcutYon != Yon.sol) oyuncu.mevcutYon = Yon.sag;
    } else if (oyuncuNo == 2 && ikiKisilikMi && oyuncu2 != null) {
      if (yeniYon == Yon.yukari && oyuncu2!.mevcutYon != Yon.asagi) oyuncu2!.mevcutYon = Yon.yukari;
      else if (yeniYon == Yon.asagi && oyuncu2!.mevcutYon != Yon.yukari) oyuncu2!.mevcutYon = Yon.asagi;
      else if (yeniYon == Yon.sol && oyuncu2!.mevcutYon != Yon.sag) oyuncu2!.mevcutYon = Yon.sol;
      else if (yeniYon == Yon.sag && oyuncu2!.mevcutYon != Yon.sol) oyuncu2!.mevcutYon = Yon.sag;
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

  @override
  void update(double dt) {
    if (oyunBitti) return;
    super.update(dt);
    
    final kafa1 = oyuncu.govde.first;

    bool p2Oldu = false;
    if (ikiKisilikMi && oyuncu2 != null) {
      final kafa2 = oyuncu2!.govde.first;
      bool p2Duvar = kafa2.x < 0 || kafa2.x >= yatayKareSayisi || kafa2.y < 0 || kafa2.y >= dikeyKareSayisi || engelKonumlari.any((t) => t.x == kafa2.x && t.y == kafa2.y);
      bool p2Kendine = oyuncu2!.govde.skip(1).any((p) => p.x == kafa2.x && p.y == kafa2.y);
      bool p2P1eVurdu = oyuncu.govde.any((p) => p.x == kafa2.x && p.y == kafa2.y);
      p2Oldu = p2Duvar || p2Kendine || p2P1eVurdu;
      
      if (yem.konum != null && kafa2.x == yem.konum!.x && kafa2.y == yem.konum!.y) {
        oyuncu2!.yemYedi(); yem.konumUret(); oyuncu2Skoru += 10; skorNotifier2.value = oyuncu2Skoru;
        try { oyuncu2!.kaliciHizArtir(); } catch(e) {}
      }
    }

    bool p1Duvar = kafa1.x < 0 || kafa1.x >= yatayKareSayisi || kafa1.y < 0 || kafa1.y >= dikeyKareSayisi || engelKonumlari.any((t) => t.x == kafa1.x && t.y == kafa1.y);
    bool p1Kendine = oyuncu.govde.skip(1).any((p) => p.x == kafa1.x && p.y == kafa1.y);
    bool p1RakibeCarpti = !klasikModMu ? yapayZekalar.any((ai) => ai.govde.any((p) => p.x == kafa1.x && p.y == kafa1.y)) : (ikiKisilikMi ? oyuncu2!.govde.any((p) => p.x == kafa1.x && p.y == kafa1.y) : false);
    bool p1Oldu = p1Duvar || p1Kendine || p1RakibeCarpti;

    if (p1Oldu && p2Oldu) { bitisMesaji = "KAFA KAFAYA ÇARPIŞTINIZ!"; oyunuBitir("BERABERE"); return;
    } else if (p1Oldu) { bitisMesaji = ikiKisilikMi ? "OYUNCU 2 (Kırmızı) KAZANDI!" : "DUVARA VEYA KENDİNE ÇARPTIN!"; oyunuBitir(ikiKisilikMi ? "OYUNCU 2" : "Yapay Zeka"); return;
    } else if (p2Oldu) { bitisMesaji = "OYUNCU 1 (Yeşil) KAZANDI!"; oyunuBitir("OYUNCU 1"); return; }

    if (!klasikModMu) {
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
            ai.yemYedi(); yem.konumUret(); 
            bireyselAiSkorlari[ai] = (bireyselAiSkorlari[ai] ?? 0) + 10;
            if (bireyselAiSkorlari[ai]! >= hedefYem * 10) { bitisMesaji = "Çok yavaşsın çaylak!"; oyunuBitir("Yapay Zeka"); return; } 
          }
          if (hizYemi.konum != null && aiKafa.x == hizYemi.konum!.x && aiKafa.y == hizYemi.konum!.y) { ai.hizKazan(); hizYemi.konumUret(); }
          if (altinPara.konum != null && aiKafa.x == altinPara.konum!.x && aiKafa.y == altinPara.konum!.y) { altinPara.konumUret(); }
        }
      }

      for (var olen in olenYilanlar) { olen.oluMu = true; remove(olen); yapayZekalar.remove(olen); bireyselAiSkorlari.remove(olen); }
      if (bireyselAiSkorlari.isNotEmpty) { aiSkoru = bireyselAiSkorlari.values.reduce(max); } else { aiSkoru = 0; }
      if (yapayZekalar.isEmpty) { bitisMesaji = "BÜTÜN RAKİPLER ELENDİ, MEYDAN SENİN!"; oyunuBitir(oyuncuAdi); return; }
    }

    if (yem.konum != null && kafa1.x == yem.konum!.x && kafa1.y == yem.konum!.y) { 
      oyuncu.yemYedi(); yem.konumUret(); oyuncuSkoru += 10; skorNotifier.value = oyuncuSkoru; 

      if (klasikModMu) {
        if (!ikiKisilikMi && oyuncuSkoru > klasikRekor) { klasikRekor = oyuncuSkoru; }
        try { oyuncu.kaliciHizArtir(); } catch (e) {}
      } else if (oyuncuSkoru >= hedefYem * 10) { bitisMesaji = "HEDEF YEME ULAŞTIN, ZAFER SENİN!"; oyunuBitir(oyuncuAdi); }
    }
    
    if (!klasikModMu && hizYemi.konum != null && kafa1.x == hizYemi.konum!.x && kafa1.y == hizYemi.konum!.y) { oyuncu.hizKazan(); hizYemi.konumUret(); }
    if (altinPara.konum != null && kafa1.x == altinPara.konum!.x && kafa1.y == altinPara.konum!.y) { toplamAltin += 1; veriKaydet(); altinPara.konumUret(); }
  }

  void oyunuBitir(String kimKazandi) {
    if (oyunBitti) return; 
    oyunBitti = true; 
    kazanan = kimKazandi;
    if (!klasikModMu && kazanan == oyuncuAdi && oyuncuAdi != "") {
      toplamAltin += hedefYem;
    } else if (klasikModMu && !ikiKisilikMi) {
      toplamAltin += (oyuncuSkoru ~/ 20); 
    }
    veriKaydet(); 
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
    
    for (double x = 0; x <= yatayKareSayisi * hucreBoyutu; x += hucreBoyutu) canvas.drawLine(Offset(x, 0), Offset(x, dikeyKareSayisi * hucreBoyutu), paint);
    for (double y = 0; y <= dikeyKareSayisi * hucreBoyutu; y += hucreBoyutu) canvas.drawLine(Offset(0, y), Offset(yatayKareSayisi * hucreBoyutu, y), paint);
    
    if (!klasikModMu) {
      skorTabelasiCiz(canvas, "$oyuncuAdi: $oyuncuSkoru / ${hedefYem * 10}", 15, 15, Colors.greenAccent, 1);
      skorTabelasiCiz(canvas, "Kalan Rakip: ${yapayZekalar.length}", size.x / 2, 15, Colors.amberAccent, 2);
      skorTabelasiCiz(canvas, "Lider AI: $aiSkoru / ${hedefYem * 10}", size.x - 15, 15, Colors.redAccent, 3);
    }
  }
}