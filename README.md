# Kovan Nöbeti
Üçüncü şahıs kamerayla oynanan, 10 dakikalık bir hayatta kalma oyunu. Bir arıcısın, böcek sürüsü Ana Kovan'a saldırıyor. Silahların kendi ateş eder; senin işin koşmak, zıplamak, kaymak, toplamak ve doğru anda kovanı yardıma çağırmak. Godot 4.7 ile yapıldı.

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
| Q ya da sağ tık | Kovan Çağrısı (göstergesi dolunca) |
| 1, 2, 3 ya da fare | Kart seç |
| R | Kartları yenile |
| F11 | Tam ekran |
| Esc | Duraklat, ayarlar (fare hassasiyeti, müzik, efekt sesi, parlaklık) |

- Ölen böcek bal bırakır. Bal toplayınca seviye atlarsın, oyun durur ve üç karttan birini seçersin (yeni silah, silah seviyesi ya da özellik). Yedi silahtan en çok beşini taşırsın, eli beğenmezsen turda iki kez yenilersin.
- Altıncı seviyeye gelen silah, kartının sağ üstünde görünen özellik yeterince yükselince evrilir ve evrim kartı ilk seviye atlamada gelir.
- Zıplamak yerdeki böceklerin ısırığını, tükürüğü ve Kraliçe'nin kırmızı halkasını boşa çıkarır. Kayarken hasar almazsın. Yerde beliren kırmızı halka ve şeritler birazdan vurulacak yeri gösterir, içinden çık.
- Böcek öldürdükçe Kovan Çağrısı dolar. Bastığında çevrendeki sürü savrulur, beş saniye boyunca arılar etrafını temizler ve biraz can alırsın.
- Haritada sandık (seçtiğin kart iki kez işler), sunak (halkasında 5 saniye dur, kalıcı +%15 hasar) ve bal kavanozu (can) var. Hepsi küçük haritada görünür. Elit böcek öldüğünde sandık bırakır.
- 3:20'de Makas, 6:40'ta Akrep gelir. İkisi de devrilince sandık bırakır. 10. dakikada Kraliçe gelir, onu devirirsen tur biter. Bir tur 10-12 dakika sürer.
- Her tur, kazansan da kaybetsen de bal kazandırır. Menüdeki Arılık'ta bu balla kalıcı geliştirme alırsın.

## İkinci aşamada ne eklendi, neden
İlk sürümü gösteri modunda baştan sona izleyip kayıtlarına baktım. Her satır orada gördüğüm bir zayıflığa karşılık geliyor.

| İlk sürümde zayıf kalan | Eklenen |
| --- | --- |
| Kamera uzaktı, arıcı ve böcekler küçük kalıyordu; böcekler katı heykel gibi kayıyordu | Yakın kamera, shader ile oynayan bacak ve kanatlar, topraktan çıkarak doğma, yerde kalan izler |
| On dakika boyunca aynı öğlen ışığı, boş ve düz bir çayır | Tur öğleden altın saate, gün batımına ve aylı geceye akar (gece müziğiyle); otlar rüzgârda ve arıcının geçişinde eğilir, gece ateş böcekleri ve fener çıkar |
| Haritanın bir merkezi, savunulan bir şey yoktu | Ortada balı gece parlayan dev Ana Kovan ağacı, petek döşeli meydan ve dört yol |
| Dört düşman türü de dümdüz üstüne yürüyordu | Yaklaşınca fitili yanan ve vurulunca yanındakileri de patlatan Patlak, önüne sıçrayan Çekirge; vuruşlar yerde önceden işaretlenir |
| Başlangıçla Kraliçe arasında olay yoktu | 3:20'de şeritte hücum eden Makas, 6:40'ta zehir yağdıran Akrep; kendi can çubukları ve sandık ödülleriyle |
| Kraliçe bir anda beliriyor, ölümü ve zafer sönük geçiyordu | Kraliçe yavaş çekimde ve kamera ona dönerek gelir, sarsılarak ölür; arıcının düşme ve sevinme animasyonu var |
| Koşmak dışında basacak bir şey yoktu | Öldürdükçe dolan, sıkışınca basılan Kovan Çağrısı |
| Kötü gelen el değiştirilemiyor, yapılar birbirine benziyordu | Kart yenileme, iki yeni silah (Nöbetçi Kovan, Bal İzi) ve evrimleri, beş silahlık kemer |
| Tur bitince geriye rekordan başka bir şey kalmıyordu | Arılık'ta turda kazanılan balla alınan sekiz kalıcı geliştirme |

Bir de hata düzeltmesi var. Hasar sayıları her farklı yazı boyutu için yeni bir yazı dokusu açtığından bellek tur boyunca şişiyordu, boyutlar basamaklandırıldı.

## Kredi dökümü
Tavan iki aşamanın toplamı için 1.200 krediydi, harcanan 419,49 (ilk aşama 299,55, ikinci aşama 119,94). Rakam bakiye farkından değil, işlerin maliyetleri toplanarak hesaplandı. Her işin kimliği [kredi.csv](kredi.csv) dosyasında, ikinci aşamanın satırları `asama2` ile başlıyor.

| Kalem | İş | Kredi |
| --- | --- | --- |
| Stil karesi (GPT Image, 3'ü başarısız) | 5 | 13,75 |
| Asset görselleri ve ikon sayfası (GPT Image) | 11 | 30,25 |
| İskeletli arıcı modeli (image_to_3d) | 1 | 38,00 |
| Düşman ve eşya modelleri (hunyuan3d LowPoly) | 9 | 126,00 |
| Ek animasyon klipleri (3d_rigging) | 3 | 24,00 |
| Müzik (ElevenLabs Music, 4 parça) | 4 | 57,55 |
| Ses efektleri (Mirelo) | 20 | 10,00 |
| İlk aşama | 53 | 299,55 |
| Yeni düşman, Ana Kovan ve ikon görselleri (GPT Image) | 6 | 16,50 |
| Makas, Akrep, Patlak, Çekirge, Ana Kovan modelleri (hunyuan3d LowPoly) | 5 | 70,00 |
| Gece müziği (ElevenLabs Music) | 1 | 17,44 |
| Düşme ve sevinme klipleri (3d_rigging) | 2 | 16,00 |
| İkinci aşama | 14 | 119,94 |
| Toplam | 67 | 419,49 |

Başarısız üç stil karesi işinin (8,25 kredi) hesaptan düşülüp düşülmediğini doğrulayamadım, toplamda sayılı. İkinci stil karesi (2,75) yedek modelle üretildi ve kullanılmadı.

## Ses
Sürekli çalan tek ses müzik. Menü, oyunun ilk bölümü, gün batımı, gece ve Kraliçe için birer parça var, aynı anda yalnız biri çalar ve geçişler sessizlik olmadan çapraz geçişle yapılır. Ortam sesi, filtre ve müziği kısma yok. Seviyeler dosyalar ölçülerek ayarlandı. Müzik -14 LUFS'a, sık çalan efektler onun 13-16 LU altına, seyrek büyük efektler 3-6 LU altına. Ölçülen değerler `scripts/audio.gd` içindeki tabloda.

## Bilinen zayıf noktalar
- Oyunu elle hiç oynayamadım. Godot MCP girdi gönderemediği için bütün testler kendi kendine oynayan botla yapıldı. Klavye ve fare yolu (koşma, kamera, kart seçimi, menü düğmeleri) kodda var ama gerçek girdiyle bir kez bile çalıştırılmadı, ilk elle oynayışta hata çıkabilir. İkinci aşamanın tuşları (Q, sağ tık, R, F11) ve Arılık'tan tıklayarak satın alma da buna dahil; Arılık ekranını yalnız hata ayıklama bayrağıyla açıp ekran görüntüsünde gördüm.
- Tam ekran hiç denenmedi. Test pencerelerinin yeri sistemce yönetildiği için F11 yalnız o oturum için geçerli, kaydedilmiyor ve açılışta uygulanmıyor. Arayüz yalnız 1280×720 pencerede kontrol edildi.
- Denge bota göre ayarlandı ve bot Arılık geliştirmeleri olmadan oynuyor. Son ayarlarla oynanan 5 bot turunun 5'i de Kraliçe'yi devirdi (seviye 38-46, 8.400-11.800 öldürme). Bir önceki ayarlarda 6 turun 2'sinde bot 4. ve 5. dakikada Makas'a yenilmişti; ardından Makas'ın şeridi hücum boyunca açık bırakıldı ve vuruşu hafifletildi. Botun tepkileri insandan hızlı, plan yapması ise zayıf, bu yüzden bir insan için zorluk farklı çıkabilir; son hâli fazla kolay da olabilir, Arılık geliştirmeleri alındıkça daha da kolaylaşır. Bal İzi'nin hasardaki payı turdan tura %0 ile %19 arasında oynadı, değeri oyuncunun nasıl koştuğuna bağlı ve botla ölçülemiyor.
- Sesi hiç dinleyemedim, test pencerelerinin sesi kısık. Seviyeler ölçüme dayanıyor, müzikte konuşma ya da çığlık olup olmadığına yalnız spektrogramdan bakıldı; gece parçası da öyle.
- Mirelo efektlerinin 10'u düz gürültü geldi ve yerlerine kodla üretilen sesler kondu (`tools/sentez.py`). O 10 işin 5 kredisi boşa gitti. İkinci aşamanın yeni olayları (hücum, zehir, Kovan Çağrısı) için yeni efekt üretilmedi, eldeki efektler kullanıldı.
- Yalnız arıcının iskelet animasyonu var. Böcekler, şampiyonlar ve Kraliçe katı modeller; bacak ve kanatları shader oynatıyor ve hangi köşelerin bacak sayılacağı modelin biçiminden tahmin ediliyor, bazı modellerde gövdenin alt kenarı da kıpırdayabilir. Arıcının bekleme, zıplama, kayma, düşme ve sevinme klipleri başka bir iskeletten ana iskelete çevrildi, ayak kayması görülebilir.
- Gece okunabilirliğine yalnız ekran görüntüleri ve kısa kayıtlarda baktım. Fener, ay ışığı ve böceklerdeki kenar parıltısı orada yetiyordu ama karanlık bir ekranda ya da düşük parlaklık ayarında kalabalık zor seçilebilir.
- Ana Kovan'ın gövdesi daire bir engel. Daireden taşan köklerin içinden yürünebiliyor.
- Kraliçe'nin canı, dövüşün ilk 10 saniyesinde ona verilen hasara göre yeniden ayarlanıyor; şampiyonların canı da geldikleri andaki hasarına göre belirleniyor. Böylece her yapıyla benzer uzunlukta dövüşler çıkıyor ama çok güçlü bir yapı onları beklediğinden yavaş, zayıf bir yapı beklediğinden hızlı devirir.
- Geride kalan oyuncu toplama başına daha çok tecrübe alıyor ve kalabalık sabit bir hedefe göre doğuyor. İkisi de görünmez yardım, usta bir oyuncu bunu fark edebilir.
- Fizik motoru yok, zemin düz, engeller daire. Kamera ağaçların içinden geçebilir, araya giren ağaç ve böcekler noktalanarak soluyor.
- Ayarlar, rekor, bal ve Arılık geliştirmeleri `user://kovan_nobeti.json` dosyasına düz JSON olarak yazılıyor, elle değiştirilebilir. Bot hiç yazmadığı için oyunun kendi kayıt yolu elle denenmedi; yalnız yazma sırası (geçici dosyaya yaz, yerine taşı) ayrı bir betikle denendi. Tur sonu gösterisi sürerken (2-4 saniye) pencere kapatılırsa o turun balı yazılmaz.
- `tools/` altındaki betikler tek kullanıcılı bir geliştirme makinesi için yazıldı, çıktı klasörü ve kilit dosyası `/var/tmp` altında sabit adlarla duruyor.
- Başarım yalnız bu makinede ölçüldü, ekranda yaklaşık 170 düşmanla 145 kare/sn çıktı. Daha kalabalık durumlar yalnız ekransız bot turlarında görüldü, orada kare hızı ölçülmedi.
- `project.godot` yerel Beckett eklentisini çağırıyor, eklenti depoda değil. Temiz bir kopyada Godot açılışta eksik eklenti hatası yazar; oyun yine çalışır (temiz kopya ilk aşamada ekransız bir bot turuyla denendi). Bu makinede alınacak bir dışa aktarım eklentinin otomatik yüklenen betiğini de içerir; betik editör dışında kendini kapatıyor ama o kod benim değil, dağıtmadan önce `project.godot` içindeki iki Beckett satırını silmek daha doğru.

## Süre
İlk aşama 16 Kasım 2026'da 11:37'de başladı, 14:45'te bitti. İkinci aşama aynı gün 14:46'da başladı, 16:45'te bitti, yaklaşık 2 saat sürdü.
