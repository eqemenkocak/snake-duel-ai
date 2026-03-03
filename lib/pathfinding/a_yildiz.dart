import 'package:flame/components.dart';

// Izgara üzerindeki her bir kareyi (düğümü) temsil eden sınıf
class Dugum {
  Vector2 konum;
  Dugum? ebeveyn; // Bu kareye nereden geldiğimizi tutar ki yolu geriye doğru çizebilelim
  
  int gMaliyeti = 0; // Başlangıçtan bu kareye gelene kadar atılan adım sayısı
  int hMaliyeti = 0; // Bu kareden hedefe (yeme) olan kuş uçuşu mesafe (Manhattan)

  Dugum(this.konum);

  // F Maliyeti = G + H (Algoritma her zaman en düşük F'ye sahip kareyi seçer)
  int get fMaliyeti => gMaliyeti + hMaliyeti;
}

class AYildiz {
  // A* algoritmasıyla en kısa yolu bulan ana fonksiyon
  static List<Vector2> yolBul({
    required Vector2 baslangic,
    required Vector2 hedef,
    required int yatayKareSayisi,
    required int dikeyKareSayisi,
    required List<Vector2> engeller,
  }) {
    List<Dugum> acikListe = [];   // Gidilebilecek, değerlendirilecek kareler
    List<Dugum> kapaliListe = []; // Zaten değerlendirilmiş, işi bitmiş kareler

    acikListe.add(Dugum(baslangic));

    while (acikListe.isNotEmpty) {
      // 1. Açık listedeki en düşük F maliyetine sahip düğümü bul
      Dugum gecerliDugum = acikListe[0];
      for (int i = 1; i < acikListe.length; i++) {
        if (acikListe[i].fMaliyeti < gecerliDugum.fMaliyeti ||
            (acikListe[i].fMaliyeti == gecerliDugum.fMaliyeti && acikListe[i].hMaliyeti < gecerliDugum.hMaliyeti)) {
          gecerliDugum = acikListe[i];
        }
      }

      acikListe.remove(gecerliDugum);
      kapaliListe.add(gecerliDugum);

      // 2. Hedefe ulaştık mı? Ulaştıysak ebeveynleri takip ederek yolu çıkar
      if (gecerliDugum.konum == hedef) {
        List<Vector2> yol = [];
        Dugum? aktif = gecerliDugum;
        while (aktif != null) {
          yol.add(aktif.konum);
          aktif = aktif.ebeveyn;
        }
        return yol.reversed.toList(); // Yolu baştan sona (yılandan yeme) çevirip döndür
      }

      // 3. Komşu kareleri (Yukarı, Aşağı, Sağ, Sol) kontrol et
      List<Vector2> komsular = [
        Vector2(gecerliDugum.konum.x, gecerliDugum.konum.y - 1),
        Vector2(gecerliDugum.konum.x, gecerliDugum.konum.y + 1),
        Vector2(gecerliDugum.konum.x - 1, gecerliDugum.konum.y),
        Vector2(gecerliDugum.konum.x + 1, gecerliDugum.konum.y),
      ];

      for (Vector2 komsuKonum in komsular) {
        // A) Sınırların dışında mı?
        if (komsuKonum.x < 0 || komsuKonum.x >= yatayKareSayisi || komsuKonum.y < 0 || komsuKonum.y >= dikeyKareSayisi) {
          continue;
        }

        // B) Komşu kare bir engel mi? (Kendi gövdemiz veya oyuncunun gövdesi)
        bool engelMi = engeller.any((engel) => engel.x == komsuKonum.x && engel.y == komsuKonum.y);
        if (engelMi) continue;

        // C) Zaten kapalı listede (değerlendirilmiş) mi?
        bool kapaliMi = kapaliListe.any((d) => d.konum.x == komsuKonum.x && d.konum.y == komsuKonum.y);
        if (kapaliMi) continue;

        // Yeni G maliyetini hesapla
        int yeniGMaliyeti = gecerliDugum.gMaliyeti + 1;
        
        // Komşu düğüm açık listede var mı bak
        Dugum? komsuDugum;
        try {
          komsuDugum = acikListe.firstWhere((d) => d.konum.x == komsuKonum.x && d.konum.y == komsuKonum.y);
        } catch(e) {
          komsuDugum = null;
        }

        // Eğer komşu açık listede yoksa veya yeni yol daha kısaysa değerlerini güncelle
        if (komsuDugum == null || yeniGMaliyeti < komsuDugum.gMaliyeti) {
          if (komsuDugum == null) {
            komsuDugum = Dugum(komsuKonum);
            acikListe.add(komsuDugum);
          }
          
          komsuDugum.gMaliyeti = yeniGMaliyeti;
          // Manhattan Mesafe Formülü: |x1 - x2| + |y1 - y2|
          komsuDugum.hMaliyeti = ((komsuKonum.x - hedef.x).abs() + (komsuKonum.y - hedef.y).abs()).toInt();
          komsuDugum.ebeveyn = gecerliDugum;
        }
      }
    }

    // Hedefe giden hiçbir yol yoksa (örn: etrafı yılanlarla kapalıysa) boş liste dön
    return []; 
  }
}