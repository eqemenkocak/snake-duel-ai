import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum Yon { yukari, asagi, sol, sag }

class OyuncuYilani extends Component {
  final double hucreBoyutu;
  final String seciliSkin; // YENİLİK: Mağazadan gelen skin adı
  
  List<Vector2> govde = [];
  Yon mevcutYon = Yon.sag;
  
  double zamanSayaci = 0;
  double normalHareketAraligi = 0.1; 
  double hareketAraligi = 0.1; 
  
  int buyumeBekleyen = 0;
  bool hizliMi = false;
  double hizSuresi = 0;

  // YENİLİK: Constructora seçili skini de ekledik
  OyuncuYilani({required this.hucreBoyutu, required this.seciliSkin}) {
    govde.add(Vector2(5.0, 5.0)); 
    govde.add(Vector2(4.0, 5.0)); 
    govde.add(Vector2(3.0, 5.0)); 
  }

  void hizKazan() {
    hizliMi = true;
    hizSuresi = 3.0; 
    hareketAraligi = normalHareketAraligi / 2; 
  }

  @override
  void update(double dt) {
    super.update(dt);
    zamanSayaci += dt;

    if (hizliMi) {
      hizSuresi -= dt;
      if (hizSuresi <= 0) {
        hizliMi = false;
        hareketAraligi = normalHareketAraligi; 
      }
    }

    if (zamanSayaci >= hareketAraligi) {
      hareketUygula();
      zamanSayaci = 0;
    }
  }

  void hareketUygula() {
    Vector2 yeniKafa = govde.first.clone();

    switch (mevcutYon) {
      case Yon.yukari: yeniKafa.y -= 1; break;
      case Yon.asagi: yeniKafa.y += 1; break;
      case Yon.sol: yeniKafa.x -= 1; break;
      case Yon.sag: yeniKafa.x += 1; break;
    }

    govde.insert(0, yeniKafa);

    if (buyumeBekleyen > 0) {
      buyumeBekleyen--;
    } else {
      govde.removeLast();
    }
  }

  void yemYedi() {
    buyumeBekleyen++;
  }

  @override
  void render(Canvas canvas) {
    Paint firca = Paint();

    // YENİLİK: Skinlere Göre Renk Belirleme
    if (hizliMi) {
      firca.color = Colors.cyanAccent; // Hızlanınca her türlü parlasın
    } else {
      if (seciliSkin == "Neon Mor") {
        firca.color = Colors.purpleAccent;
      } else if (seciliSkin == "Ateş Kırmızısı") {
        firca.color = Colors.redAccent;
      } else if (seciliSkin == "Saf Altın") {
        firca.color = Colors.amber;
      } else {
        firca.color = Colors.green; // Klasik Yeşil
      }
    }

    for (var parca in govde) {
      final dikdortgen = Rect.fromLTWH(
        parca.x * hucreBoyutu,
        parca.y * hucreBoyutu,
        hucreBoyutu,
        hucreBoyutu,
      );
      canvas.drawRect(dikdortgen.deflate(1.0), firca);
    }
  }
}