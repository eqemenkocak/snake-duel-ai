import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'snake.dart';
import '../pathfinding/a_yildiz.dart'; 
import '../main.dart'; 

class YapayZekaYilani extends Component with HasGameRef<SnakeGame> {
  final double hucreBoyutu;
  final int yatayKare;
  final int dikeyKare;
  
  List<Vector2> govde = [];
  Yon mevcutYon = Yon.sol;

  double zamanSayaci = 0;
  final double hareketAraligi = 0.1; 
  int buyumeBekleyen = 0;

  YapayZekaYilani({
    required this.hucreBoyutu, 
    required this.yatayKare, 
    required this.dikeyKare
  }) {
    govde.add(Vector2(yatayKare - 5.0, dikeyKare - 5.0)); 
    govde.add(Vector2(yatayKare - 4.0, dikeyKare - 5.0)); 
    govde.add(Vector2(yatayKare - 3.0, dikeyKare - 5.0)); 
  }

  @override
  void update(double dt) {
    super.update(dt);
    zamanSayaci += dt;

    if (zamanSayaci >= hareketAraligi) {
      rotaHesaplaVeHareketEt(); 
      zamanSayaci = 0;
    }
  }

  void rotaHesaplaVeHareketEt() {
    try {
      if (gameRef.yem.konum == null) return; 

      Vector2 hedef = gameRef.yem.konum!;
      List<Vector2> engeller = [];

      engeller.addAll(gameRef.engelKonumlari); 
      engeller.addAll(gameRef.oyuncu.govde); 
      
      for (int i = 1; i < govde.length; i++) {
        engeller.add(govde[i]); 
      }

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
    final firca = Paint()..color = Colors.blue;

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