import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:math';

enum Yon { yukari, asagi, sol, sag }

class OyuncuYilani extends Component with HasGameRef<FlameGame> {
  final double hucreBoyutu;
  final String seciliSkin; 
  final List<String> seciliAksesuarlar; 
  
  List<Vector2> govde = [];
  Yon mevcutYon = Yon.sag;
  
  double zamanSayaci = 0;
  double normalHareketAraligi = 0.1; 
  double hareketAraligi = 0.1; 
  
  int buyumeBekleyen = 0;
  bool hizliMi = false;
  double hizSuresi = 0;

  Map<String, Sprite> aksesuarGorselleri = {};

  OyuncuYilani({required this.hucreBoyutu, required this.seciliSkin, required this.seciliAksesuarlar}) {
    govde.add(Vector2(5.0, 5.0)); 
    govde.add(Vector2(4.0, 5.0)); 
    govde.add(Vector2(3.0, 5.0)); 
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    for (String aks in seciliAksesuarlar) {
      String dosyaAdi = "";
      if (aks == "Kral Tacı") dosyaAdi = "tac.png";
      else if (aks == "Siyah Gözlük") dosyaAdi = "black.png";
      else if (aks == "Kırmızı Gözlük") dosyaAdi = "red.png";
      else if (aks == "3D Gözlük") dosyaAdi = "3d (1).png";
      else if (aks == "Koca Burun") dosyaAdi = "nose.png";
      else if (aks == "Komik Ağız") dosyaAdi = "3d (4).png";

      if (dosyaAdi.isNotEmpty) {
        aksesuarGorselleri[aks] = await gameRef.loadSprite(dosyaAdi);
      }
    }
  }

  void kaliciHizArtir() {
    normalHareketAraligi = normalHareketAraligi * 0.93; 
    if (normalHareketAraligi < 0.04) {
      normalHareketAraligi = 0.04;
    }
    if (!hizliMi) {
      hareketAraligi = normalHareketAraligi;
    }
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

    if (hizliMi) {
      firca.color = Colors.cyanAccent; 
    } else {
      if (seciliSkin == "Neon Mor") firca.color = Colors.purpleAccent;
      else if (seciliSkin == "Ateş Kırmızısı") firca.color = Colors.redAccent;
      else if (seciliSkin == "Saf Altın") firca.color = Colors.amber;
      else firca.color = Colors.green; 
    }

    for (var parca in govde) {
      final dikdortgen = Rect.fromLTWH(
        parca.x * hucreBoyutu, parca.y * hucreBoyutu,
        hucreBoyutu, hucreBoyutu,
      );
      canvas.drawRect(dikdortgen.deflate(1.0), firca);
    }

    if (govde.isNotEmpty) {
      Vector2 kafa = govde.first;
      double merkezX = (kafa.x * hucreBoyutu) + (hucreBoyutu / 2);
      double merkezY = (kafa.y * hucreBoyutu) + (hucreBoyutu / 2);

      double aci = 0;
      if (mevcutYon == Yon.sag) aci = pi / 2;       
      else if (mevcutYon == Yon.asagi) aci = pi;    
      else if (mevcutYon == Yon.sol) aci = -pi / 2; 
      else if (mevcutYon == Yon.yukari) aci = 0;    

      canvas.save(); 
      canvas.translate(merkezX, merkezY); 
      canvas.rotate(aci); 
      
      // YENİLİK: ÇİZİM SIRASI (Z-INDEX) GÜNCELLENDİ
      // Önce Ağız ve Burun çizilir (En altta kalırlar)
      List<String> siralama = ["Komik Ağız", "Koca Burun"];
      
      // Sonra Gözlükler çizilir (Burunun üstüne biner)
      for (String aks in seciliAksesuarlar) {
        if (aks.contains("Gözlük")) {
          siralama.add(aks);
        }
      }
      
      // EN SON KRAL TACI ÇİZİLİR (Her şeyin en önünde/üstünde durur!)
      if (seciliAksesuarlar.contains("Kral Tacı")) {
        siralama.add("Kral Tacı");
      }

      for (String aks in siralama) {
        if (!seciliAksesuarlar.contains(aks)) continue;

        Sprite? spr = aksesuarGorselleri[aks];
        if (spr == null) continue;

        double aksesuarGenislik = hucreBoyutu; 
        double offsetY = 0;

        if (aks == "Kral Tacı") {
          aksesuarGenislik = hucreBoyutu * 1.0; 
          offsetY = -hucreBoyutu * 0.6; // En Önde
        } else if (aks == "Komik Ağız") {
          aksesuarGenislik = hucreBoyutu * 0.7; 
          offsetY = hucreBoyutu * 0.5; // En altta
        } else if (aks == "Koca Burun") {
          aksesuarGenislik = hucreBoyutu * 0.5; 
          offsetY = 0.0; // Tam merkezde
        } else if (aks.contains("Gözlük")) {
          aksesuarGenislik = hucreBoyutu * 1.1; 
          offsetY = -hucreBoyutu * 0.15; 
        }

        double aksesuarYukseklik = aksesuarGenislik; 
        if (spr.srcSize.y != 0) { 
          double oran = spr.srcSize.x / spr.srcSize.y; 
          aksesuarYukseklik = aksesuarGenislik / oran; 
        }

        spr.render(
          canvas,
          position: Vector2(-aksesuarGenislik / 2, (-aksesuarYukseklik / 2) + offsetY),
          size: Vector2(aksesuarGenislik, aksesuarYukseklik)
        );
      }
      
      canvas.restore(); 
    }
  }
}