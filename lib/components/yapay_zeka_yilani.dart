import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'snake.dart';
import '../pathfinding/a_yildiz.dart'; 
import '../main.dart'; 

class YapayZekaYilani extends Component with HasGameRef<SnakeGame> {
  final double hucreBoyutu;
  final int yatayKare;
  final int dikeyKare;
  final int zorlukSeviyesi; 
  
  List<Vector2> govde = [];
  Yon mevcutYon = Yon.sol;

  double zamanSayaci = 0;
  late double normalHareketAraligi; 
  late double hareketAraligi; 
  int buyumeBekleyen = 0;

  // YENİLİK: Nitro değişkenleri
  bool hizliMi = false;
  double hizSuresi = 0;

  YapayZekaYilani({
    required this.hucreBoyutu, 
    required this.yatayKare, 
    required this.dikeyKare,
    required this.zorlukSeviyesi, 
  }) {
    govde.add(Vector2(yatayKare - 5.0, dikeyKare - 5.0)); 
    govde.add(Vector2(yatayKare - 4.0, dikeyKare - 5.0)); 
    govde.add(Vector2(yatayKare - 3.0, dikeyKare - 5.0)); 

    if (zorlukSeviyesi == 1) {
      normalHareketAraligi = 0.3; 
    } else if (zorlukSeviyesi == 2) {
      normalHareketAraligi = 0.2; 
    } else {
      normalHareketAraligi = 0.1; 
    }
    hareketAraligi = normalHareketAraligi;
  }

  void hizKazan() {
    hizliMi = true;
    hizSuresi = 3.0; // 3 Saniye
    hareketAraligi = normalHareketAraligi / 2; // AI da 2 kat hızlanır
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
      rotaHesaplaVeHareketEt(); 
      zamanSayaci = 0;
    }
  }

  void rotaHesaplaVeHareketEt() {
    try {
      if (gameRef.yem.konum == null) return; 

      Vector2 hedef = gameRef.yem.konum!;

      // YENİLİK: AI Zekası - Eğer mavi hız yemi ona daha yakınsa, onu hedeflesin!
      if (gameRef.hizYemi.konum != null) {
        double mesafeKirmizi = govde.first.distanceTo(gameRef.yem.konum!);
        double mesafeMavi = govde.first.distanceTo(gameRef.hizYemi.konum!);
        
        if (mesafeMavi < mesafeKirmizi) {
          hedef = gameRef.hizYemi.konum!;
        }
      }

      List<Vector2> engeller = [];
      engeller.addAll(gameRef.engelKonumlari); 
      engeller.addAll(gameRef.oyuncu.govde); 
      for (int i = 1; i < govde.length; i++) engeller.add(govde[i]); 

      List<Vector2> yol = AYildiz.yolBul(
        baslangic: govde.first,
        hedef: hedef,
        yatayKareSayisi: yatayKare,
        dikeyKareSayisi: dikeyKare,
        engeller: engeller, 
      );

      if (yol.length > 1) {
        Vector2 sonrakiKare = yol[1]; 
        Vector2 mevcutKafa = govde.first;

        if (sonrakiKare.x > mevcutKafa.x) mevcutYon = Yon.sag;
        else if (sonrakiKare.x < mevcutKafa.x) mevcutYon = Yon.sol;
        else if (sonrakiKare.y > mevcutKafa.y) mevcutYon = Yon.asagi;
        else if (sonrakiKare.y < mevcutKafa.y) mevcutYon = Yon.yukari;
      }

      hareketUygula();
    } catch (e) {
      return;
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
    // YENİLİK: AI hızlanınca rengi parlasın (Cyan)
    final firca = Paint()..color = hizliMi ? Colors.cyanAccent : Colors.blue;

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