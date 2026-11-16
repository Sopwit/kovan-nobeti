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
| Enter | Bitiş ekranında yeni tur |
| F11 | Tam ekran |
| Esc | Duraklat, ayarlar (fare hassasiyeti, müzik, efekt sesi, parlaklık); kart ekranında da çalışır |

- Ölen böcek bal bırakır. Bal toplayınca seviye atlarsın, oyun durur ve üç karttan birini seçersin (yeni silah, silah seviyesi ya da özellik). Yedi silahtan en çok beşini taşırsın, eli beğenmezsen turda iki kez yenilersin.
- Altıncı seviyeye gelen silah, kartının altında yazan özellik yeterince yükselince evrilir ve evrim kartı ilk seviye atlamada gelir. Makas'ın ve Akrep'in sandığı, taşıdığın silahlardan birini seviyesine bakmadan evriltir.
- Zıplamak yerdeki böceklerin ısırığını, tükürüğü ve Kraliçe'nin kırmızı halkasını boşa çıkarır. Kayarken hasar almazsın. Yerde beliren kırmızı halka ve şeritler birazdan vurulacak yeri gösterir, içinden çık. Vurulduğunda ekranın ortasında yanan kırmızı yay vuruşun geldiği yönü gösterir.
- Böcek öldürdükçe Kovan Çağrısı dolar. Bastığında çevrendeki sürü savrulur, beş saniye boyunca arılar etrafını temizler ve biraz can alırsın.
- Haritada sandık (seçtiğin kart iki kez işler), sunak (halkasında 5 saniye dur, kalıcı +%15 hasar) ve bal kavanozu (can) var. Hepsi sağ üstteki radarda görünür. Radarın ortası sensin, üstü kameranın baktığı yön, kırmızı noktalar böcekler, açık renkli çizgi arena duvarı. Elit böcek öldüğünde sandık bırakır.
- 3:20'de Makas, 6:40'ta Akrep gelir. İkisi de devrilince evrim sandığı bırakır. 10. dakikada Kraliçe gelir, dövüş yaklaşık bir dakika sürer ve canı yarıya inince öfkelenir. Onu devirirsen tur biter. Bir tur 11-12 dakika sürer.
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

## İnceleme revizesinde ne değişti, neden
Bağımsız inceleme ajanının raporundaki altı sorunu kodda ve ölçümle tek tek doğruladım, altısı da gerçekti. Bu revizede üretim yapılmadı, kredi harcanmadı.

| Rapordaki sorun | Yapılan |
| --- | --- |
| Savaş kameranın arkasında kalıyor | Kamera 6,8 m ve 25 dereceden 11 m ve 36 dereceye alındı; kalabalıkta 14 m'ye, şampiyon ve Kraliçe sahnedeyken biraz daha geriye açılıyor. Küçük harita, ortasında arıcının durduğu ve üstü kameranın baktığı yön olan bir radara dönüştü; her böcek bir nokta, arena duvarı bir çizgi. |
| Ölüm ani geliyor, nedeni okunmuyor | Vuruşun geldiği yönde ekranın ortasında kırmızı bir yay yanıyor. Tam ekran kırmızı yerine kenarlarda toplanan bir kızarma var. Canı %30'un altına düşüren vuruş 1,3 saniye dokunulmazlık, çevreyi iten bir dalga ve "Canın azaldı" uyarısı veriyor (20 saniyede bir). |
| Kraliçe finali kısa ve soluk | Dövüş her yapı için yaklaşık 70 saniyeye boyutlanıyor ve uzak durmak onu kısaltmıyor. Canı yarıya inince afiş ve ağır çekimle öfkeleniyor, ikinci yarıya zehir yağmuru saldırısı ekleniyor. Büyük gövdelerde vuruş parlaması kısa darbelere indi, Kraliçe ve şampiyonlar artık kendi dokularıyla görünüyor. |
| Müzik vuruş seslerini örtüyor | Vuruş sesi 11 dB, öldürme 3 dB, toplama 2 dB yükseltildi; müziğe dokunulmadı (nedeni aşağıda). |
| İlk turlar "bir tur daha" dedirtecek bir şey bırakmıyor | Makas'ın ve Akrep'in sandığı bir silahı doğrudan evriltiyor. Kartların altında evrimin koşulu yazıyor, çekiliş evrime giden kartları biraz öne alıyor. Arılık'ın ilk basamağı 30 baldan 15'e indi (1:51'lik bir tur 24 bal veriyor). Bitiş ekranı bir sonraki Arılık hedefini gösteriyor ve Arılık'a doğrudan gidiyor. |
| Bitiş ekranında Boşluk turu yeniden başlatıyor, kart panelinde Esc çalışmıyor | Bitiş ekranındaki düğmeler klavye odağı almıyor, yeni tur yalnız Enter ya da fareyle başlıyor. Kart panelinde Esc duraklatma menüsünü açıyor, ikinci Esc kartlara geri dönüyor. |

Katılmadığım ya da farklı çözdüğüm noktalar da var.

- Müziği oyun içinde 6 dB indirme ve efektleri 6-8 dB yükseltme önerisini uygulamadım. Müziğin menüden itibaren net duyulması ve hiç kısılmaması bu oyunun baştan beri koşulu. Rapordaki hesap tek tek seslerin hedef seviyesine bakıyordu. Ben yoğun bir dövüşün efekt yatağını oyunun kendi kazançlarıyla render edip ölçtüm (`tools/miks.py`). Eski hâlinde yatak -22,5 LUFS'tu, müziğin 8,5 LU altında. Efektler toplamda kaybolmuyordu, kaybolan vuruş sesiydi (öldürme sesinin 11 dB altındaydı). Yeni seviyelerle yatak -20,2 LUFS, müziğin yaklaşık 6 LU altında. Önerilen kadar yükseltseydim efektler en sık hâllerinde müziği geçerdi; şimdi o uç durumda -14,1 LUFS, müzikle eşit. Varsayılan efekt ayarını da müzikle aynı değere (0,9) getirdim.
- İlk silahın 4. seviyede evrilmesi yerine şampiyon sandığını seçtim. Evrimi ucuzlatmak altıncı seviyeye kadar gelen kartları anlamsızlaştırırdı. Sandık evrimi Makas'ı devirmenin ödülü yapıyor ve hangi silahın evrileceğini oyuncuya bırakıyor. 20 bot turunun 18'inde ilk evrim 3:35 ile 7:03 arasında geldi (ortanca 4:45); kalan ikisinde bot Makas'ın sandığını alamadan öldü. Makas'tan önce ölen oyuncu yine evrim görmüyor.
- Kraliçe'nin canını ilk 10 saniyedeki hasara göre ayarlayan ölçümü kaldırmadım, alt sınır koydum. Ölçüm olmadan tek gövdeye zayıf bir yapı dakikalarca vurur, güçlü bir yapı onu 20 saniyede eritir. Artık ölçülen hasar, yapının sürüye verdiği hasarın %15'inden az sayılmıyor, yani uzak durmak dövüşü kısaltmıyor. 85. saniyeden sonra Kraliçe yoruluyor ve daha çok hasar alıyor, böylece zayıf bir yapı da finalde sıkışıp kalmıyor.
- Raporun "README 5'te 5 diyor, bot benim turumda öldü" notu haklı, beş tur küçük bir örnekti. Yeni rakamlar Bilinen zayıf noktalar'da.

## Kredi dökümü
Tavan iki aşamanın toplamı için 1.200 krediydi, harcanan 419,49 (ilk aşama 299,55, ikinci aşama 119,94). Rakam bakiye farkından değil, işlerin maliyetleri toplanarak hesaplandı. Her işin kimliği [kredi.csv](kredi.csv) dosyasında, ikinci aşamanın satırları `asama2` ile başlıyor. İnceleme revizesinde üretim yapılmadı.

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
Sürekli çalan tek ses müzik. Menü, oyunun ilk bölümü, gün batımı, gece ve Kraliçe için birer parça var, aynı anda yalnız biri çalar ve geçişler sessizlik olmadan çapraz geçişle yapılır. Ortam sesi, filtre ve müziği kısma yok. Seviyeler dosyalar ölçülerek ayarlandı. Müzik -14 LUFS'a, sık çalan efektler onun 11-16 LU altına, seyrek büyük efektler 3-6 LU altına. Yoğun bir dövüşün efekt yatağı birlikte ölçülünce müziğin yaklaşık 6 LU altında kalıyor (`tools/miks.py`). Ölçülen değerler `scripts/audio.gd` içindeki tabloda.

## Bilinen zayıf noktalar
- Oyunu ben elle hiç oynayamadım. Godot MCP girdi gönderemiyor; testlerim kendi kendine oynayan botla, ekran görüntüleriyle ve hata ayıklama bayraklarıyla yapıldı. Menüyü, ayar kaydırıcılarını, duraklatmayı, fare ve tuşla kart seçimini, Q tuşunu, bal kaydını ve Arılık'tan satın almayı bağımsız inceleme ajanı gerçek tuş ve fareyle doğruladı. Revizedeki tuş değişikliklerini (kart panelinde Esc, bitiş ekranında Boşluk ve Enter) oyunun girdi hattına gerçek tuş olayları gönderen bir test adımıyla doğruladım. Sağ tık, R, F11, kart paneli üstündeki duraklatma menüsünden ana menüye dönüş ve bitiş ekranındaki Arılık düğmesi hiçbir yolla denenmedi.
- Tam ekran hiç denenmedi. Test pencerelerinin yeri sistemce yönetildiği için F11 yalnız o oturum için geçerli, kaydedilmiyor ve açılışta uygulanmıyor. Arayüz yalnız 1280×720 pencerede kontrol edildi.
- Denge bota göre ayarlandı ve bot Arılık geliştirmeleri olmadan oynuyor. İnceleme revizesinde üç ölçüm alındı, aralarında küçük ayar farkları var: 6 turda 3, 8 turda 7, son hâliyle 6 turda 3 galibiyet, toplam 20 turun 13'ü. Yedi ölümün altısı 5. ile 9. dakika arasında, üçü arena duvarına sıkışarak oldu. Revizeden önceki 11 turun 9'u galibiyetti; fark bu örnek büyüklüğünde tesadüften ayırt edilemiyor, yani botun revizeyle daha iyi ya da daha kötü oynadığını söyleyemem. Kazanılan 13 turda Kraliçe dövüşü 53 ile 72 saniye sürdü. Duvara sıkışma botun zayıf yanı ama insan için de gerçek bir tehlike; radar duvarı çiziyor ve kenara ilk gidişte bir uyarı çıkıyor, başka önlem yok. Botun tepkileri insandan hızlı, plan yapması ise zayıf, bu yüzden bir insan için zorluk farklı çıkabilir; Arılık geliştirmeleri alındıkça oyun kolaylaşır. Bal İzi'nin hasardaki payı turdan tura %0 ile %19 arasında oynadı, değeri oyuncunun nasıl koştuğuna bağlı ve botla ölçülemiyor.
- Sesi hiç dinleyemedim, test pencerelerinin sesi kısık. Seviyeler ölçüme dayanıyor, müzikte konuşma ya da çığlık olup olmadığına yalnız spektrogramdan bakıldı; gece parçası da öyle. Efekt yatağı ölçümü bir benzetim: beş ses sabit aralıklarla üst üste çalınıyor, gerçek bir dövüşün kaydı değil. Vuruş sesinin artık duyulup duyulmadığını kulakla kimse doğrulamadı.
- Mirelo efektlerinin 10'u düz gürültü geldi ve yerlerine kodla üretilen sesler kondu (`tools/sentez.py`). O 10 işin 5 kredisi boşa gitti. İkinci aşamanın yeni olayları (hücum, zehir, Kovan Çağrısı) için yeni efekt üretilmedi, eldeki efektler kullanıldı.
- Yalnız arıcının iskelet animasyonu var. Böcekler, şampiyonlar ve Kraliçe katı modeller; bacak ve kanatları shader oynatıyor ve hangi köşelerin bacak sayılacağı modelin biçiminden tahmin ediliyor, bazı modellerde gövdenin alt kenarı da kıpırdayabilir. Arıcının bekleme, zıplama, kayma, düşme ve sevinme klipleri başka bir iskeletten ana iskelete çevrildi, ayak kayması görülebilir.
- Gece okunabilirliğine yalnız ekran görüntüleri ve kısa kayıtlarda baktım. Fener, ay ışığı ve böceklerdeki kenar parıltısı orada yetiyordu ama karanlık bir ekranda ya da düşük parlaklık ayarında kalabalık zor seçilebilir.
- Ana Kovan'ın gövdesi daire bir engel. Daireden taşan köklerin içinden yürünebiliyor.
- Kraliçe'nin canı, dövüşün ilk 10 saniyesinde ona verilen hasara göre yeniden ayarlanıyor (alt sınırı yapının sürüye verdiği hasarın %15'i) ve 85. saniyeden sonra aldığı hasar artıyor; şampiyonların canı da geldikleri andaki hasara göre belirleniyor. Böylece her yapıyla benzer uzunlukta dövüşler çıkıyor ama bunlar görünmez ayarlar, usta bir oyuncu güçlü yapısının finali kısaltmadığını fark edebilir. Canı azalan oyuncuya verilen dokunulmazlık ve itme de aynı türden bir yardım.
- Yeni kamerayla böcekler ekranda daha küçük. İkinci aşamada yakın kamera için yapılan bacak ve kanat hareketi uzaktan daha az seçiliyor. Fare kameranın eğimini değiştirir ama yakınlaştırma yok.
- Raporun ani ölüm bulgusu tepki vermeyen sürücülerle ölçülmüştü. O sürücüleri yeniden koşturamadım, bu yüzden ilk dakikalardaki ölümlerin azaldığını ölçemedim. Hasar yayını, radarı ve düşük can uyarısını yalnız bot turlarının ekran görüntülerinde gördüm; bir insanın bunları dövüş sırasında okuyup okumadığını bilmiyorum.
- Şampiyonun ödülünü, o devrildikten sonra açılan ilk sandık taşır; bu bir elit böceğin ya da haritanın sandığı da olabilir. Taşınan bütün silahlar evrilmişse sandık sıradan sandık olarak açılır.
- Geride kalan oyuncu toplama başına daha çok tecrübe alıyor ve kalabalık sabit bir hedefe göre doğuyor. İkisi de görünmez yardım, usta bir oyuncu bunu fark edebilir.
- Fizik motoru yok, zemin düz, engeller daire. Kamera ağaçların içinden geçebilir, araya giren ağaç ve böcekler noktalanarak soluyor.
- Ayarlar, rekor, bal ve Arılık geliştirmeleri `user://kovan_nobeti.json` dosyasına düz JSON olarak yazılıyor, elle değiştirilebilir. Bot hiç yazmadığı için oyunun kendi kayıt yolu elle denenmedi; yalnız yazma sırası (geçici dosyaya yaz, yerine taşı) ayrı bir betikle denendi. Tur sonu gösterisi sürerken (2-4 saniye) pencere kapatılırsa o turun balı yazılmaz.
- `tools/` altındaki betikler tek kullanıcılı bir geliştirme makinesi için yazıldı, çıktı klasörü ve kilit dosyası `/var/tmp` altında sabit adlarla duruyor.
- Başarım yalnız bu makinede ölçüldü, ekranda yaklaşık 170 düşmanla 145 kare/sn çıktı. Daha kalabalık durumlar yalnız ekransız bot turlarında görüldü, orada kare hızı ölçülmedi.
- `project.godot` yerel Beckett eklentisini çağırıyor, eklenti depoda değil. Temiz bir kopyada Godot açılışta eksik eklenti hatası yazar; oyun yine çalışır (temiz kopya ilk aşamada ekransız bir bot turuyla denendi). Bu makinede alınacak bir dışa aktarım eklentinin otomatik yüklenen betiğini de içerir; betik editör dışında kendini kapatıyor ama o kod benim değil, dağıtmadan önce `project.godot` içindeki iki Beckett satırını silmek daha doğru.

## Süre
İlk aşama 16 Kasım 2026'da 11:37'de başladı, 14:45'te bitti. İkinci aşama aynı gün 14:46'da başladı, 16:45'te bitti, yaklaşık 2 saat sürdü. İnceleme revizesi aynı gün 17:35'te başladı, 18:30'da bitti.
