import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../main.dart';
import 'snake.dart';

class YapayZekaYilani extends Component with HasGameRef<SnakeGame> {
final double hucreBoyutu;
final int yatayKare;
final int dikeyKare;
final int zorlukSeviyesi;
List<Vector2> govde = [Vector2(5, 5)];
Yon mevcutYon = Yon.asagi;
double hareketZamani = 0;
double hizCarpani = 1.0;
late Color yilanRengi;
bool oluMu = false; // YENİLİK: Zombi virüsünü engelleyen hayat kurtarıcı şalter!

YapayZekaYilani({required this.hucreBoyutu, required this.yatayKare, required this.dikeyKare, required this.zorlukSeviyesi});

@override
Future<void> onLoad() async {
super.onLoad();
List<Color> renkler = [Colors.redAccent, Colors.orangeAccent, Colors.purpleAccent, Colors.deepOrange, Colors.pinkAccent, Colors.blueAccent];
yilanRengi = renkler[Random().nextInt(renkler.length)];
}

@override
void update(double dt) {
if (oluMu) return; // Yılan öldüyse beynini anında durdur!
super.update(dt);
double normalHiz = 0.3;
if (zorlukSeviyesi == 1) normalHiz = 0.4;
if (zorlukSeviyesi == 2) normalHiz = 0.18;
if (zorlukSeviyesi == 3) normalHiz = 0.15;
hareketZamani += dt;
if (hareketZamani > normalHiz * hizCarpani) {
hareketZamani = 0;
hedefeYonelVeHayattaKal();
ilerle();
}
}

void hedefeYonelVeHayattaKal() {
List<Vector2> hedefler = [];
if (gameRef.yem.konum != null) hedefler.add(gameRef.yem.konum!);
if (gameRef.hizYemi.konum != null) hedefler.add(gameRef.hizYemi.konum!);
if (hedefler.isEmpty) return;
Vector2 kafa = govde.first;
Vector2 hedef = hedefler.first;
double minMesafeHedef = double.infinity;
for (var h in hedefler) {
double m = (h.x - kafa.x).abs() + (h.y - kafa.y).abs();
if (m < minMesafeHedef) { minMesafeHedef = m; hedef = h; }
}
List<Yon> tumYonler = [Yon.yukari, Yon.asagi, Yon.sol, Yon.sag];
tumYonler.removeWhere((y) => (y == Yon.yukari && mevcutYon == Yon.asagi) || (y == Yon.asagi && mevcutYon == Yon.yukari) || (y == Yon.sol && mevcutYon == Yon.sag) || (y == Yon.sag && mevcutYon == Yon.sol));
List<Yon> guvenliYonler = [];
for (var y in tumYonler) { if (yonGuvenliMi(y)) guvenliYonler.add(y); }
if (guvenliYonler.isEmpty) return;
guvenliYonler.sort((a, b) {
double mesafeA = mesafeHesapla(kafa, hedef, a);
double mesafeB = mesafeHesapla(kafa, hedef, b);
int kiyas = mesafeA.compareTo(mesafeB);
if (kiyas == 0) {
if (a == mevcutYon) return -1;
if (b == mevcutYon) return 1;
}
return kiyas;
});
mevcutYon = guvenliYonler.first;
}

double mesafeHesapla(Vector2 baslangic, Vector2 hedef, Yon? yon) {
double x = baslangic.x;
double y = baslangic.y;
if (yon == Yon.yukari) y -= 1;
else if (yon == Yon.asagi) y += 1;
else if (yon == Yon.sol) x -= 1;
else if (yon == Yon.sag) x += 1;
return (hedef.x - x).abs() + (hedef.y - y).abs();
}

bool yonGuvenliMi(Yon yon) {
Vector2 kafa = govde.first;
Vector2 adim = Vector2(kafa.x, kafa.y);
if (yon == Yon.yukari) adim.y -= 1;
else if (yon == Yon.asagi) adim.y += 1;
else if (yon == Yon.sol) adim.x -= 1;
else if (yon == Yon.sag) adim.x += 1;
if (adim.x < 0 || adim.x >= yatayKare || adim.y < 0 || adim.y >= dikeyKare) return false;
try {
if (gameRef.engelKonumlari.any((t) => t.x == adim.x && t.y == adim.y)) return false;
for (int i = 0; i < govde.length - 1; i++) { if (govde[i].x == adim.x && govde[i].y == adim.y) return false; }
if (gameRef.oyuncu.govde.any((p) => p.x == adim.x && p.y == adim.y)) return false;
for (var ai in gameRef.yapayZekalar) {
if (ai != this && !ai.oluMu && ai.govde.any((p) => p.x == adim.x && p.y == adim.y)) return false;
}
} catch (e) { return false; }
return true;
}

void ilerle() {
Vector2 kafa = govde.first;
Vector2 yeni = Vector2(kafa.x, kafa.y);
if (mevcutYon == Yon.yukari) yeni.y -= 1;
else if (mevcutYon == Yon.asagi) yeni.y += 1;
else if (mevcutYon == Yon.sol) yeni.x -= 1;
else if (mevcutYon == Yon.sag) yeni.x += 1;
govde.insert(0, yeni);
govde.removeLast();
}

void yemYedi() { govde.add(Vector2(govde.last.x, govde.last.y)); }
void hizKazan() { hizCarpani = 0.5; Future.delayed(const Duration(seconds: 3), () { hizCarpani = 1.0; }); }

@override
void render(Canvas canvas) {
if (oluMu) return; // Yılan öldüyse çizimi (hayaleti) ekrandan sil!
final firca = Paint()..color = yilanRengi;
for (int i = 0; i < govde.length; i++) {
final p = govde[i];
final rect = Rect.fromLTWH(p.x * hucreBoyutu, p.y * hucreBoyutu, hucreBoyutu, hucreBoyutu);
canvas.drawRect(rect, firca);
}
}
}