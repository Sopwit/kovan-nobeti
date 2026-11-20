# Kovan Nöbeti

Godot 4.7 ile geliştirilmiş üçüncü şahıs hayatta kalma oyunu. Sürülere dayan, arılığını güçlendir ve finalde Kraliçe’yi yen.

## Bu sürümde

- **Nöbet sunağı.** Altın çemberde 12 saniye kal, üç dalgaya dayan ve bir sandıkla birlikte koşu boyunca %15 ek hasar kazan.
- **Şampiyon kalkanları.** Makas ve Akrep’in her biri, Kraliçe savaşında bir darbeyi engelleyen bir kalkan kazandırır.
- **Silah evrimleri.** Yükseltme kartları, seçimden sonraki silah ve pasif seviye ilerlemesini gösterir.

## İndir

[**Kovan Nöbeti 1.0.0 RC 1**](https://github.com/Sopwit/kovan-nobeti/releases/tag/v1.0.0-rc.1) ön sürümünde macOS Universal ZIP, Windows x64 EXE ve Linux x64 paketleri var. Kurulum adımları ve platform testlerinin durumu sürüm notlarında.

## Oyna

Kaynak kodunu Godot 4.7 ile aç ve **F5** ile başlat. WASD ile hareket et, fare ile kamerayı çevir, Boşluk ile zıpla ve Shift ile kay. Kovan Çağrısı hazır olduğunda Q veya sağ tıkla kullan.

Ana projenin yayımlanmış Windows ve Linux sürümleri [Releases sayfasında](https://github.com/yusufipk/kovan-nobeti/releases) bulunur.

## Derle

Godot sürümünle eşleşen dışa aktarma şablonlarını yükle. Windows ve Linux için Godot’un **Project → Export** menüsündeki profilleri kullan.

macOS’ta Apple Silicon ve Intel destekli, yerel imzalı uygulamayı ve ZIP arşivini oluşturmak için proje kökünde aşağıdaki komutu çalıştır.

```sh
tools/export_macos.sh
```

Çıktılar `build/macos/` klasörüne yazılır. Godot farklı bir konumdaysa `GODOT_BIN` ile motorun çalıştırılabilir dosyasını belirt.

## Kaynak ve lisans

[yusufipk/kovan-nobeti](https://github.com/yusufipk/kovan-nobeti) projesinin geliştirilmiş bir fork’udur. Oyun [MIT lisanslıdır](LICENSE). Baloo 2 yazı tipi [SIL Open Font License](assets/font/OFL.txt) ile dağıtılır.
