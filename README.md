# Kovan Nöbeti
Üçüncü şahıs kamerayla oynanan, 10 dakikalık bir hayatta kalma oyunu. Bir arıcısın, böcek sürüsü Ana Kovan'a saldırıyor. Silahların kendi ateş eder; senin işin koşmak, zıplamak, kaymak, toplamak ve doğru anda kovanı yardıma çağırmak. Godot 4.7 ile yapıldı.

## İndir

Derlenmiş sürümler [Releases](https://github.com/yusufipk/kovan-nobeti/releases/latest) sayfasında. Windows'ta `.exe` dosyasını indirip çalıştır. Linux'ta `.x86_64` dosyasını indir, `chmod +x` ile çalıştırılabilir yap ve çalıştır.

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
- Böcek öldürdükçe Kovan Çağrısı dolar, en erken 55 saniyede. Dolunca can çubuğunun yanındaki petek çınlar ve Q tuşu yanar. Bastığında çevrendeki sürü savrulur ve dört saniye boyunca arılar etrafını temizler.
- Haritada sandık (seçtiğin kart iki kez işler), sunak (halkasında 5 saniye dur, kalıcı +%15 hasar) ve bal kavanozu (can) var. Hepsi sağ üstteki radarda görünür. Radarın ortası sensin, üstü kameranın baktığı yön, kırmızı noktalar böcekler, açık renkli çizgi arena duvarı. Elit böcek öldüğünde sandık bırakır.
- 3:20'de Makas, 6:40'ta Akrep gelir. İkisi de devrilince evrim sandığı bırakır. 10. dakikada Kraliçe gelir, dövüş yaklaşık bir dakika sürer ve canı yarıya inince öfkelenir. Sıçradığında ineceği yer kırmızı daireyle işaretlenir, indiği yerde bir an kalır. Onu devirirsen tur biter. Bir tur 11-12 dakika sürer.
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

## Son düzeltme turunda ne değişti, neden
Yusuf'un iki turda söylediklerini koda ve ölçüme vurdum. Bu turda iki müzik parçası üretildi, 30,52 kredi.

| Söylenen | Yapılan |
| --- | --- |
| Q fazla güçlü, Kraliçe saldırılarını gösteremeden ölüyor | Kovan Çağrısı en erken 55 saniyede doluyor (38'di). Patlaması şampiyonun ve Kraliçe'nin canının %5'i yerine %2'sini alıyor, sürünün onlara vuruşu üçte bire indi ve 5 yerine 4 saniye sürüyor. Artık can vermiyor, dokunulmazlığı 0,8 saniye. |
| Mıknatıs çok sık çıkıyor, çekince seviye atlıyorum | Sahada aynı anda tek mıknatıs olabiliyor ve iki mıknatıs arasında en az 100 saniye geçiyor. Yerdeki bal kavanozu sınırı 5'ten 4'e indi. |
| İlk turda Q'yu unuttum | Gösterge dolunca can çubuğunun üstünde "Q Kovan Çağrısı hazır" şeridi çıkıyor, bir ses çalıyor, petek göstergeden halkalar yayılıyor ve Q tuşu basılana kadar yanıp sönüyor. |
| Arayüz ve ikonlar yapay zeka işi gibi duruyor, Arılık geliştirilebilir | Bütün arayüz yeniden çizildi. Motorun varsayılan yazı tipinin yerinde Baloo 2 var (SIL OFL, lisansı `assets/font/OFL.txt`). Lacivert yuvarlak kutuların yerini köşesi kesik, koyu bal rengi paneller aldı. İkonların arkasındaki kareler kesildi (`tools/ikon_kes.py`), her ikon kodla çizilen bir petek gözünde duruyor. Kartlarda türü söyleyen renkli bir bant, seviye petekleri ve evrim koşulunu eşinin ikonuyla gösteren bir alt satır var. Arılık'ta alınabilen geliştirmenin fiyatı bal rengi bir etiketle öne çıkıyor. |
| Fare öbür oyundaki kadar iyi değil, biraz akıyor | Kamera farenin gösterdiği yere yumuşatılarak gidiyordu. Bu yüzden her dönüş elin arkasından geliyor, fare durduktan sonra da kayıyordu. Yörünge artık fareyi birebir izliyor, yalnız zıplamadaki yükseklik yumuşatılıyor. |
| Menü müziği sıradan, ilk bölümün müziği farklı olmalıydı | İkisi de yeniden üretildi. Beğenilen üçüncü parçaya, gece ve Kraliçe parçalarına dokunulmadı. |
| Boss hareketleri iyileştirilebilir | Kraliçe'ye sıçrama eklendi, iki yarıda da üçüncü hamlesi. İneceği yer kırmızı daireyle işaretleniyor, indiği yerde bir saniye kadar kalıyor ve o an vurulabiliyor. Q dövüşü artık atlatmadığı için öbür saldırıları da görülüyor. |
| Sunak uyanınca donuyor mu | Sunağı 112 böcek varken uyandırıp kare sürelerini ölçtüm, 40 ms'yi geçen kare çıkmadı. Tek duraksama, patlamada ölen elit böceğin kasıtlı 0,09 saniyelik vuruş duraklamasıydı. Sunak patlamasında artık çalışmıyor. |

Farklı çözdüğüm ya da yapmadığım şeyler de var.

- "Daha zor olmalı" için düşmanların hasarını ve canını da artırmayı denedim, geri aldım. O hâliyle bot 8 turun 1'ini kazandı ve yedi ölümün altısı 4. ile 6. dakika arasında, Makas sahadayken oldu. Zorluk şimdi yalnız Q'nun ve mıknatısın zayıflamasından geliyor. Bot bu hâliyle 8 turun 3'ünü kazanıyor, önceki sürümde 20 turun 13'üydü.
- Seviye atlamak can yenilemiyor, kodda böyle bir şey yok. Can yalnız kavanozlardan, can kartlarından, sunaktan ve devrilen şampiyondan geliyor. Görülen şey büyük olasılıkla mıknatısla art arda gelen seviyelerdi. Her kart seçiminden sonra çevredeki sürü itiliyor ve yarım saniye hasar alınmıyor. Mıknatıs seyrekleşince bu zincir de seyrekleşti. İtmeye dokunmadım, kart ekranından çıkar çıkmaz ısırılmamak için duruyor.
- Birden fazla harita yapmadım. Yeni bir harita yeni zemin, engel ve ışık düzeni demek ve kameraya elle hiç oynanmadan çıkardı. Son turda var olanı sağlamlaştırmayı seçtim.
- Beğenilenlere (yaratıkların okunurluğu, vuruş hissi, doğma animasyonları, sunak, zıplama hasarı, kavanoz arama, menzilli düşmanlar, Arılık'ın kuralları, evrim koşulları) dokunmadım.

## Kredi dökümü
Tavan bütün aşamaların toplamı için 1.200 kredi, harcanan 450,01 (ilk aşama 299,55, ikinci aşama 119,94, son düzeltme turu 30,52). Rakam bakiye farkından değil, işlerin maliyetleri toplanarak hesaplandı. Her işin kimliği [kredi.csv](kredi.csv) dosyasında, ikinci aşamanın satırları `asama2`, son turunkiler `duzeltme` ile başlıyor. İnceleme revizesinde üretim yapılmadı.

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
| Yeni menü ve ilk bölüm müziği (ElevenLabs Music), son düzeltme turu | 2 | 30,52 |
| Toplam | 69 | 450,01 |

Başarısız üç stil karesi işinin (8,25 kredi) hesaptan düşülüp düşülmediğini doğrulayamadım, toplamda sayılı. İkinci stil karesi (2,75) yedek modelle üretildi ve kullanılmadı. İlk aşamanın dört müzik parçasından ikisi (menü ve ilk bölüm, 26,16 kredi) son turda değiştirildiği için artık oyunda değil.

## Ses
Sürekli çalan tek ses müzik. Menü, oyunun ilk bölümü, gün batımı, gece ve Kraliçe için birer parça var, aynı anda yalnız biri çalar ve geçişler sessizlik olmadan çapraz geçişle yapılır. Ortam sesi, filtre ve müziği kısma yok. Seviyeler dosyalar ölçülerek ayarlandı. Müzik -14 LUFS'a, sık çalan efektler onun 11-16 LU altına, seyrek büyük efektler 3-6 LU altına. Yoğun bir dövüşün efekt yatağı birlikte ölçülünce müziğin yaklaşık 6 LU altında kalıyor (`tools/miks.py`). Ölçülen değerler `scripts/audio.gd` içindeki tabloda. Son turda üretilen menü parçasının ilk 8 saniyesi parçanın geri kalanından 11 LU kısıktı; kısık giriş ve çıkış kırpıldı, menüde çalan 59 saniyelik orta bölüm.

## Bilinen zayıf noktalar
- Oyunu ben elle hiç oynayamadım. Godot MCP girdi gönderemiyor; testlerim kendi kendine oynayan botla, ekran görüntüleriyle ve hata ayıklama bayraklarıyla yapıldı. Menüyü, ayar kaydırıcılarını, duraklatmayı, fare ve tuşla kart seçimini, Q tuşunu, bal kaydını ve Arılık'tan satın almayı bağımsız inceleme ajanı gerçek tuş ve fareyle doğruladı. Revizedeki tuş değişikliklerini (kart panelinde Esc, bitiş ekranında Boşluk ve Enter) oyunun girdi hattına gerçek tuş olayları gönderen bir test adımıyla doğruladım. Sağ tık, R, F11, kart paneli üstündeki duraklatma menüsünden ana menüye dönüş ve bitiş ekranındaki Arılık düğmesi hiçbir yolla denenmedi. Son düzeltme turunda arayüzün tamamı yeniden yazıldı ve o günden sonra hiçbir düğmesine gerçek fare ya da tuşla basılmadı; girdi kodu aynı kaldı, ekranların hepsine bot modunda ekran görüntüsüyle baktım. Kameranın artık akmadığını da ölçemem, yalnız gecikmeyi yaratan yumuşatmayı kaldırdım.
- Tam ekran hiç denenmedi. Test pencerelerinin yeri sistemce yönetildiği için F11 yalnız o oturum için geçerli, kaydedilmiyor ve açılışta uygulanmıyor. Arayüz yalnız 1280×720 pencerede kontrol edildi.
- Denge bota göre ayarlandı ve bot Arılık geliştirmeleri olmadan oynuyor. Son hâliyle 8 turun 3'ünü kazandı; beş ölümün üçü 4. ile 6. dakika arasında, Makas sahadayken geldi, yani ilk şampiyon artık gerçek bir eşik. Sekiz tur küçük bir örnek, bu sonuçla gerçek oran %9 ile %76 arasında herhangi bir yerde olabilir (%95 güven aralığı). İnceleme revizesindeki sürümde 20 turun 13'ü galibiyetti. Botun tepkileri insandan hızlı, plan yapması zayıf ve arena duvarına sıkışmak onun zayıf yanı; bir insan için zorluk farklı çıkabilir, Arılık geliştirmeleri alındıkça da oyun kolaylaşır. Q'nun ve mıknatısın yeni değerleri hiçbir insan turunda denenmedi, fazla sert ya da hâlâ yumuşak kalmış olabilirler. Bal İzi'nin hasardaki payı turdan tura çok oynuyor, değeri oyuncunun nasıl koştuğuna bağlı ve botla ölçülemiyor.
- Sesi hiç dinleyemedim, test pencerelerinin sesi kısık. Seviyeler ölçüme dayanıyor, müzikte konuşma ya da çığlık olup olmadığına yalnız spektrogramdan bakıldı; gece parçası da öyle. Efekt yatağı ölçümü bir benzetim: beş ses sabit aralıklarla üst üste çalınıyor, gerçek bir dövüşün kaydı değil. Vuruş sesinin artık duyulup duyulmadığını kulakla kimse doğrulamadı. Son turun iki yeni parçasını da dinleyemedim. Menü parçasının spektrogramında düzenli yinelenen yaylar var; bir enstrümanın perde kayması olarak yorumladım ama insan sesi olmadığını kulakla doğrulayan olmadı. Parçaların öncekilerden daha az sıradan olduğunu da yalnız verdiğim tariften biliyorum.
- Mirelo efektlerinin 10'u düz gürültü geldi ve yerlerine kodla üretilen sesler kondu (`tools/sentez.py`). O 10 işin 5 kredisi boşa gitti. İkinci aşamanın yeni olayları (hücum, zehir, Kovan Çağrısı) için yeni efekt üretilmedi, eldeki efektler kullanıldı.
- Yalnız arıcının iskelet animasyonu var. Böcekler, şampiyonlar ve Kraliçe katı modeller; bacak ve kanatları shader oynatıyor ve hangi köşelerin bacak sayılacağı modelin biçiminden tahmin ediliyor, bazı modellerde gövdenin alt kenarı da kıpırdayabilir. Arıcının bekleme, zıplama, kayma, düşme ve sevinme klipleri başka bir iskeletten ana iskelete çevrildi, ayak kayması görülebilir.
- Gece okunabilirliğine yalnız ekran görüntüleri ve kısa kayıtlarda baktım. Fener, ay ışığı ve böceklerdeki kenar parıltısı orada yetiyordu ama karanlık bir ekranda ya da düşük parlaklık ayarında kalabalık zor seçilebilir.
- Kraliçe sıçrarken kamerayla arıcının arasından geçebiliyor ve bir an ekranın büyük kısmını kaplıyor (noktalanarak soluyor). Havadayken ölmüyor, son vuruş yere indikten sonra sayılıyor. Sıçramayı yalnız bot kayıtlarında gördüm.
- İkonların arka planı renk eşiğiyle kesildi. 1280×720'de temiz görünüyorlar ama koyu kenarlı ikonlarda kenarın bir kısmı da gitmiş olabilir, daha büyük bir ekranda bakılmadı.
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

## Süre
İlk aşama 16 Kasım 2026'da 11:37'de başladı, 14:45'te bitti. İkinci aşama aynı gün 14:46'da başladı, 16:45'te bitti, yaklaşık 2 saat sürdü. İnceleme revizesi aynı gün 17:35'te başladı, 18:30'da bitti. Son düzeltme turu 17 Kasım 2026'da 14:55'te başladı, 15:56'da bitti.
