import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flame/events.dart';

import 'components/snake.dart';
import 'components/yem.dart'; // Yem dosyamızı projeye dahil ettik

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget(game: SnakeGame()),
      ),
    ),
  );
}

class SnakeGame extends FlameGame with KeyboardEvents {
  final double hucreBoyutu = 20.0;
  late OyuncuYilani oyuncu;
  late Yem yem; // Yem değişkenimizi tanımladık

  int yatayKareSayisi = 0;
  int dikeyKareSayisi = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Ekran boyutuna göre ızgarada kaç satır ve sütun olduğunu hesaplıyoruz
    yatayKareSayisi = (size.x / hucreBoyutu).floor();
    dikeyKareSayisi = (size.y / hucreBoyutu).floor();

    oyuncu = OyuncuYilani(hucreBoyutu: hucreBoyutu);
    add(oyuncu);

    // Yemi sahneye ekliyoruz
    yem = Yem(
      hucreBoyutu: hucreBoyutu,
      yatayKareSayisi: yatayKareSayisi,
      dikeyKareSayisi: dikeyKareSayisi,
    );
    add(yem);
  }

  @override
  Color backgroundColor() => Colors.black;

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) && oyuncu.mevcutYon != Yon.asagi) {
      oyuncu.mevcutYon = Yon.yukari;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowDown) && oyuncu.mevcutYon != Yon.yukari) {
      oyuncu.mevcutYon = Yon.asagi;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) && oyuncu.mevcutYon != Yon.sag) {
      oyuncu.mevcutYon = Yon.sol;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight) && oyuncu.mevcutYon != Yon.sol) {
      oyuncu.mevcutYon = Yon.sag;
    }

    return super.onKeyEvent(event, keysPressed);
  }
  @override
void update(double dt) {
  super.update(dt);

  // Çarpışma Kontrolü: Yılanın kafasının koordinatları, yemin koordinatlarıyla aynı mı?
  if (oyuncu.govde.first.x == yem.konum.x && oyuncu.govde.first.y == yem.konum.y) {
    oyuncu.yemYedi(); // Yılanı 1 kare büyüt
    yem.konumUret(); // Yemi haritada yeni rastgele bir yere ışınla
  }
}
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.x; x += hucreBoyutu) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), paint);
    }
    for (double y = 0; y < size.y; y += hucreBoyutu) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), paint);
    }
  }
}