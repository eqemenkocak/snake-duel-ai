import 'package:flame/components.dart';

class Dugum {
  Vector2 konum;
  Dugum? ebeveyn; 
  
  int gMaliyeti = 0; 
  int hMaliyeti = 0; 

  Dugum(this.konum);

  int get fMaliyeti => gMaliyeti + hMaliyeti;
}

class AYildiz {
  static List<Vector2> yolBul({
    required Vector2 baslangic,
    required Vector2 hedef,
    required int yatayKareSayisi,
    required int dikeyKareSayisi,
    required List<Vector2> engeller,
  }) {
    List<Dugum> acikListe = [];   
    List<Dugum> kapaliListe = []; 

    acikListe.add(Dugum(baslangic));
    
    int aramaLimiti = 0; // HATA ÇÖZÜMÜ: Performans için sınır koyduk

    while (acikListe.isNotEmpty) {
      aramaLimiti++;
      // Eğer AI hedefi bulamayıp tüm haritayı taramaya kalkarsa oyunu dondurur.
      // 400 denemeden sonra beyni yakmadan pes etmesini söylüyoruz.
      if (aramaLimiti > 400) {
        return [];
      }

      Dugum gecerliDugum = acikListe[0];
      for (int i = 1; i < acikListe.length; i++) {
        if (acikListe[i].fMaliyeti < gecerliDugum.fMaliyeti ||
            (acikListe[i].fMaliyeti == gecerliDugum.fMaliyeti && acikListe[i].hMaliyeti < gecerliDugum.hMaliyeti)) {
          gecerliDugum = acikListe[i];
        }
      }

      acikListe.remove(gecerliDugum);
      kapaliListe.add(gecerliDugum);

      if (gecerliDugum.konum == hedef) {
        List<Vector2> yol = [];
        Dugum? aktif = gecerliDugum;
        while (aktif != null) {
          yol.add(aktif.konum);
          aktif = aktif.ebeveyn;
        }
        return yol.reversed.toList(); 
      }

      List<Vector2> komsular = [
        Vector2(gecerliDugum.konum.x, gecerliDugum.konum.y - 1),
        Vector2(gecerliDugum.konum.x, gecerliDugum.konum.y + 1),
        Vector2(gecerliDugum.konum.x - 1, gecerliDugum.konum.y),
        Vector2(gecerliDugum.konum.x + 1, gecerliDugum.konum.y),
      ];

      for (Vector2 komsuKonum in komsular) {
        if (komsuKonum.x < 0 || komsuKonum.x >= yatayKareSayisi || komsuKonum.y < 0 || komsuKonum.y >= dikeyKareSayisi) {
          continue;
        }

        bool engelMi = engeller.any((engel) => engel.x == komsuKonum.x && engel.y == komsuKonum.y);
        if (engelMi) continue;

        bool kapaliMi = kapaliListe.any((d) => d.konum.x == komsuKonum.x && d.konum.y == komsuKonum.y);
        if (kapaliMi) continue;

        int yeniGMaliyeti = gecerliDugum.gMaliyeti + 1;
        
        Dugum? komsuDugum;
        try {
          komsuDugum = acikListe.firstWhere((d) => d.konum.x == komsuKonum.x && d.konum.y == komsuKonum.y);
        } catch(e) {
          komsuDugum = null;
        }

        if (komsuDugum == null || yeniGMaliyeti < komsuDugum.gMaliyeti) {
          if (komsuDugum == null) {
            komsuDugum = Dugum(komsuKonum);
            acikListe.add(komsuDugum);
          }
          
          komsuDugum.gMaliyeti = yeniGMaliyeti;
          komsuDugum.hMaliyeti = ((komsuKonum.x - hedef.x).abs() + (komsuKonum.y - hedef.y).abs()).toInt();
          komsuDugum.ebeveyn = gecerliDugum;
        }
      }
    }

    return []; 
  }
}