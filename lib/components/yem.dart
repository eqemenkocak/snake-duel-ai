import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../main.dart';

class Yem extends Component with HasGameRef<SnakeGame> {
  final double hucreBoyutu;
  final int yatayKareSayisi;
  final int dikeyKareSayisi;
  Vector2? konum; 
  final Random _rastgele = Random();

  Yem({
    required this.hucreBoyutu,
    required this.yatayKareSayisi,
    required this.dikeyKareSayisi,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    konumUret(); 
  }

  void konumUret() {
    bool konumGuvenliMi = false;
    
    while (!konumGuvenliMi) {
      int x = _rastgele.nextInt(yatayKareSayisi);
      int y = _rastgele.nextInt(dikeyKareSayisi);
      Vector2 yeniKonum = Vector2(x.toDouble(), y.toDouble());

      bool tasVarMi = false;
      try {
        tasVarMi = gameRef.engelKonumlari.any((tas) => tas.x == yeniKonum.x && tas.y == yeniKonum.y);
      } catch (e) {
        tasVarMi = false; 
      }

      bool surlarinDisiMi = (x == 0 || x == yatayKareSayisi - 1 || y == 0 || y == dikeyKareSayisi - 1);

      if (!tasVarMi && !surlarinDisiMi) {
        konum = yeniKonum;
        konumGuvenliMi = true;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (konum == null) return; 

    final firca = Paint()..color = Colors.red; 
    final merkezX = (konum!.x * hucreBoyutu) + (hucreBoyutu / 2);
    final merkezY = (konum!.y * hucreBoyutu) + (hucreBoyutu / 2);
    
    canvas.drawCircle(Offset(merkezX, merkezY), hucreBoyutu / 2.5, firca);
  }
}