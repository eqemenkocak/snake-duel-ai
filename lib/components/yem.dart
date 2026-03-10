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

  Yem({required this.hucreBoyutu, required this.yatayKareSayisi, required this.dikeyKareSayisi});

  @override
  Future<void> onLoad() async {
    super.onLoad();
    konumUret(); 
  }

  void konumUret() {
    if (yatayKareSayisi <= 2 || dikeyKareSayisi <= 2) { konum = Vector2(1, 1); return; }

    bool konumGuvenliMi = false;
    int deneme = 0; 
    
    while (!konumGuvenliMi && deneme < 100) {
      deneme++;
      int x = _rastgele.nextInt(yatayKareSayisi);
      int y = _rastgele.nextInt(dikeyKareSayisi);
      Vector2 yeniKonum = Vector2(x.toDouble(), y.toDouble());

      bool uzerindeEngelVarMi = false;
      try {
        bool tasVarMi = gameRef.engelKonumlari.any((tas) => tas.x == yeniKonum.x && tas.y == yeniKonum.y);
        // YENİLİK: Artık 1 yapay zekaya değil, BÜTÜN orduya (yapayZekalar) bakıyoruz!
        bool yilanVarMi = gameRef.oyuncu.govde.any((p) => p.x == yeniKonum.x && p.y == yeniKonum.y) || 
                          gameRef.yapayZekalar.any((ai) => ai.govde.any((p) => p.x == yeniKonum.x && p.y == yeniKonum.y));
        uzerindeEngelVarMi = tasVarMi || yilanVarMi;
      } catch (e) { uzerindeEngelVarMi = false; }

      bool surlarinDisiMi = (x == 0 || x == yatayKareSayisi - 1 || y == 0 || y == dikeyKareSayisi - 1);

      if (!uzerindeEngelVarMi && !surlarinDisiMi) {
        konum = yeniKonum;
        konumGuvenliMi = true;
      }
    }
    if (!konumGuvenliMi) konum = Vector2(1, 1);
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