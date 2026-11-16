# Kovan Nöbeti
Üçüncü şahıs kamerayla oynanan, 10 dakikalık bir hayatta kalma oyunu. Bir arıcısın, böcek sürüsü kovanlarına saldırıyor. Silahların kendi ateş eder; senin işin koşmak, zıplamak, kaymak ve toplamak. Godot 4.7 ile yapıldı.

## Nasıl oynanır
Klasörü Godot 4.7 ile aç ve F5'e bas ya da klasörün içinde şunu çalıştır:

```
godot --path .
```

| Tuş | İş |
| --- | --- |
| WASD ya da ok tuşları | Koş |
| Fare | Kamera |
| Boşluk | Zıpla |
| Shift ya da Ctrl | Kay |
| 1, 2, 3 ya da fare | Kart seç |
| Esc | Duraklat, ayarlar (fare hassasiyeti, müzik, efekt sesi, parlaklık) |

- Ölen böcek bal bırakır. Bal toplayınca seviye atlarsın, oyun durur ve üç karttan birini seçersin (yeni silah, silah seviyesi ya da özellik).
- Altıncı seviyeye gelen silah, kartının sağ üstünde görünen özellik yeterince yükselince evrilir ve evrim kartı ilk seviye atlamada gelir.
- Zıplamak yerdeki böceklerin ısırığını, tükürüğü ve Kraliçe'nin kırmızı halkasını boşa çıkarır. Kayarken hasar almazsın.
- Haritada sandık (seçtiğin kart iki kez işler), sunak (halkasında 5 saniye dur, kalıcı +%15 hasar) ve bal kavanozu (can) var. Hepsi küçük haritada görünür. Elit böcek öldüğünde sandık bırakır.
- 10. dakikada Kraliçe gelir. Onu devirirsen tur biter, ölürsen baştan başlarsın. Bir tur 10-12 dakika sürer.

## Kredi dökümü
Tavan 1.200 krediydi, harcanan 299,55. Rakam bakiye farkından değil, işlerin maliyetleri toplanarak hesaplandı. Her işin kimliği [kredi.csv](kredi.csv) dosyasında.

| Kalem | İş | Kredi |
| --- | --- | --- |
| Stil karesi (GPT Image, 3'ü başarısız) | 5 | 13,75 |
| Asset görselleri ve ikon sayfası (GPT Image) | 11 | 30,25 |
| İskeletli arıcı modeli (image_to_3d) | 1 | 38,00 |
| Düşman ve eşya modelleri (hunyuan3d LowPoly) | 9 | 126,00 |
| Ek animasyon klipleri (3d_rigging) | 3 | 24,00 |
| Müzik (ElevenLabs Music, 4 parça) | 4 | 57,55 |
| Ses efektleri (Mirelo) | 20 | 10,00 |
| Toplam | 53 | 299,55 |

Başarısız üç stil karesi işinin (8,25 kredi) hesaptan düşülüp düşülmediğini doğrulayamadım, toplamda sayılı. İkinci stil karesi (2,75) yedek modelle üretildi ve kullanılmadı.

## Ses
Sürekli çalan tek ses müzik. Menü, oyunun ilk yarısı, ikinci yarısı ve Kraliçe için birer parça var, aynı anda yalnız biri çalar ve geçişler sessizlik olmadan çapraz geçişle yapılır. Ortam sesi, filtre ve müziği kısma yok. Seviyeler dosyalar ölçülerek ayarlandı. Müzik -14 LUFS'a, sık çalan efektler onun 13-16 LU altına, seyrek büyük efektler 3-6 LU altına. Ölçülen değerler `scripts/audio.gd` içindeki tabloda.

## Bilinen zayıf noktalar
- Oyunu elle hiç oynayamadım. Godot MCP girdi gönderemediği için bütün testler kendi kendine oynayan botla yapıldı. Klavye ve fare yolu (koşma, kamera, kart seçimi, menü düğmeleri) kodda var ama gerçek girdiyle bir kez bile çalıştırılmadı, ilk elle oynayışta hata çıkabilir.
- Denge bota göre ayarlandı. Son ayarlarla oynanan 8 bot turunun 8'i de Kraliçe'yi devirdi; bir önceki, biraz daha sert ayarlarda 18 turun 10'u galibiyetti ve ölümler 6. ile 10. dakika arasındaydı. Botun tepkileri insandan hızlı, plan yapması ise zayıf, bu yüzden bir insan için zorluk farklı çıkabilir; son hâli fazla kolay da olabilir.
- Sesi hiç dinleyemedim, test pencerelerinin sesi kısık. Seviyeler ölçüme dayanıyor, müzikte konuşma ya da çığlık olup olmadığına yalnız spektrogramdan bakıldı.
- Mirelo efektlerinin 10'u düz gürültü geldi ve yerlerine kodla üretilen sesler kondu (`tools/sentez.py`). O 10 işin 5 kredisi boşa gitti.
- Yalnız arıcının iskelet animasyonu var. Böcekler ve Kraliçe katı modeller, kodla hareket ediyor. Arıcının bekleme, zıplama ve kayma klipleri başka bir iskeletten ana iskelete çevrildi, ayak kayması görülebilir.
- Kraliçe'nin canı, dövüşün ilk 10 saniyesinde ona verilen hasara göre yeniden ayarlanıyor. Böylece her yapıyla yaklaşık bir dakikalık bir dövüş çıkıyor ama çok güçlü bir yapı onu beklediğinden yavaş, zayıf bir yapı beklediğinden hızlı devirir.
- Geride kalan oyuncu toplama başına daha çok tecrübe alıyor ve kalabalık sabit bir hedefe göre doğuyor. İkisi de görünmez yardım, usta bir oyuncu bunu fark edebilir.
- Fizik motoru yok, zemin düz, engeller daire. Kamera ağaçların içinden geçebilir, araya giren ağaç ve böcekler noktalanarak soluyor.
- Tam ekran seçeneği yok. Arayüz yalnız 1280×720 pencerede kontrol edildi. Ayarlar ve rekor `user://kovan_nobeti.json` dosyasına yazılıyor; bot hiç yazmadığı için bu kayıt yolu da elle denenmedi.
- Başarım yalnız bu makinede ölçüldü, ekranda yaklaşık 190 düşmanla 144 kare/sn çıktı. 250-300 düşmanlı durumlar yalnız ekransız bot turlarında görüldü, orada kare hızı ölçülmedi. Kraliçe ilk göründüğünde bir kerelik kısa bir takılma olabilir.
- `project.godot` yerel Beckett eklentisini çağırıyor, eklenti depoda değil. Temiz bir kopyada Godot açılışta eksik eklenti hatası yazar; oyun yine çalışır (temiz kopya ekransız bir bot turuyla denendi).

## Süre
16 Kasım 2026'da 11:37'de başladı, 14:45'te bitti, yaklaşık 3 saat 10 dakika sürdü.
