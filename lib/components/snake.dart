import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum Yon { yukari, asagi, sol, sag }

class OyuncuYilani extends Component {
  final double hucreBoyutu;
  List<Vector2> govde = []; 
  Yon mevcutYon = Yon.sag; 

  double zamanSayaci = 0;
  final double hareketAraligi = 0.1; 
  
  // Yılanın ne kadar büyüyeceğini tutan değişken
  int buyumeBekleyen = 0; 

  OyuncuYilani({required this.hucreBoyutu}) {
    govde.add(Vector2(5, 5)); 
    govde.add(Vector2(4, 5)); 
    govde.add(Vector2(3, 5)); 
  }

  @override
  void update(double dt) {
    super.update(dt);
    zamanSayaci += dt; 

    if (zamanSayaci >= hareketAraligi) {
      hareketEt();
      zamanSayaci = 0; 
    }
  }

  void hareketEt() {
    Vector2 yeniKafa = govde.first.clone();

    switch (mevcutYon) {
      case Yon.yukari:
        yeniKafa.y -= 1;
        break;
      case Yon.asagi:
        yeniKafa.y += 1;
        break;
      case Yon.sol:
        yeniKafa.x -= 1;
        break;
      case Yon.sag:
        yeniKafa.x += 1;
        break;
    }

    govde.insert(0, yeniKafa);

    // Büyüme mantığı burada devreye giriyor
    if (buyumeBekleyen > 0) {
      buyumeBekleyen--;
    } else {
      govde.removeLast(); 
    }
  }

  // Yem yediğinde dışarıdan çağıracağımız fonksiyon
  void yemYedi() {
    buyumeBekleyen++;
  }

  @override
  void render(Canvas canvas) {
    final firca = Paint()..color = Colors.green; 

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