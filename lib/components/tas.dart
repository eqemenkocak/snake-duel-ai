import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Tas extends Component {
  final double hucreBoyutu;
  // Taşın haritadaki konumu (x, y koordinatı)
  late Vector2 konum;

  Tas({required this.hucreBoyutu, required Vector2 baslangicKonumu}) {
    konum = baslangicKonumu;
  }

  @override
  void render(Canvas canvas) {
    // Taşın rengi: Koyu gri, sert bir görünüm için
    final tasFircasi = Paint()..color = Colors.grey[700]!; 

    final dikdortgen = Rect.fromLTWH(
      konum.x * hucreBoyutu,
      konum.y * hucreBoyutu,
      hucreBoyutu,
      hucreBoyutu,
    );
    
    // Taşları daha belirgin yapmak için biraz içe doğru daraltıp çizelim
    canvas.drawRect(dikdortgen.deflate(1.0), tasFircasi); 
  }
}