import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class Yem extends Component {
  final double hucreBoyutu;
  final int yatayKareSayisi;
  final int dikeyKareSayisi;
  late Vector2 konum;
  final Random _rastgele = Random();

  Yem({
    required this.hucreBoyutu,
    required this.yatayKareSayisi,
    required this.dikeyKareSayisi,
  }) {
    konumUret(); // Yem oluşturulduğunda ilk konumunu belirle
  }

  void konumUret() {
    // Ekranın dışına taşmaması için ızgara sınırları içinde rastgele bir (x, y) seçiyoruz
    int x = _rastgele.nextInt(yatayKareSayisi);
    int y = _rastgele.nextInt(dikeyKareSayisi);
    konum = Vector2(x.toDouble(), y.toDouble());
  }

  @override
  void render(Canvas canvas) {
    // Yemimiz kırmızı renkte olsun
    final firca = Paint()..color = Colors.red; 
    
    // Yemi yeşil yılandan ayırt etmek için kare yerine yuvarlak (çember) çizelim
    final merkezX = (konum.x * hucreBoyutu) + (hucreBoyutu / 2);
    final merkezY = (konum.y * hucreBoyutu) + (hucreBoyutu / 2);
    
    canvas.drawCircle(Offset(merkezX, merkezY), hucreBoyutu / 2.5, firca);
  }
}