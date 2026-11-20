# Bilet Satış Platformu: Mimari Tasarım

Nov 16, 2026 · @Utku Can KÜÇÜK

## Genel bakış

&#91;embedded content: genel bakış · giriş, servisler, event akışı, veri ve gözlemlenebilirlik\]

1. Kullanıcı önyüzü açar.
2. Global DNS onu en yakın bölgeye yönlendirir; statik içerik CDN'den gelir.
3. İstek bölgenin Edge'ine ulaşır.
4. Yoğunlukta Edge kullanıcıyı Waiting Room'a alır, sırası geldiğinde giriş izni verir.
5. İzinli istek senkron olarak servislere gider.
6. Durum değişiklikleri event olarak mesaj aracısına yazılır; Ticketing, Search ve Notification bunları tüketir, seçili event'ler diğer bölgelere replike edilir.

## Amaç ve kapsam

Çok sayıda ülke ve şehirde konser ve maç gibi etkinlikler için koltuklu bilet satan global bir platform kuruyoruz. Platform ani satış (flash sale) yükünü kaldırır; çok dil, çok para birimi ve çok saat dilimi destekler ve birden fazla coğrafi bölgede Kubernetes üzerinde çalışır. Asıl hedef ürün değil: mikroservis patternlerini, mesajlaşmayı, cache'i ve Kubernetes'i gerekçeleriyle öğrenmek.

Bu doküman teknoloji bağımsızdır. Bileşenler rolleriyle ("mesaj aracısı", "kimlik sağlayıcı") anılır. Somut teknoloji, her biri için seçenekler, artı/eksiler ve sektör kullanımı karşılaştırıldıktan sonra seçilir ve ADR olarak kaydedilir.

**Öğrenme hedefleri**

- Bounded context'lere göre servis ayrıştırma
- Senkron ve asenkron iletişim, dayanıklılık patternleri
- Saga, Transactional Outbox, Inbox, CQRS
- Çok katmanlı cache, invalidation, stampede koruması
- OAuth2/OIDC ile kimlik doğrulama ve BFF
- Uçtan uca izlenebilirlik
- Kubernetes üzerinde dağıtım, ölçekleme, konfigürasyon ve hata yönetimi

* Çok bölgeli mimari: bölgesel hücreler (cell), veri yerelliği, bölgeler arası replikasyon
* Çok dil, çok para birimi, saat dilimi ve ülkeye özel ödeme yönlendirmesi

**Kapsam dışı**

- Gerçek ödeme sağlayıcı entegrasyonu (sahte bir PSP kullanılacak)
- Gerçek bulut sağlayıcıda çoklu bölge kurulumu (bölgeler yerelde ayrı cluster'larla simüle edilecek)
- Gelişmiş önyüz tasarımı (önyüz basit tutulacak)

## Mimari ilkeler

1. **Servis başına veri sahipliği.** Her servis kendi veritabanına sahiptir. Başka servisin verisine yalnızca API veya event üzerinden erişilir.
2. **Durum değişikliği asenkron, sorgu senkron.** Bir servisin durumunu değiştiren akışlar event ile ilerler. Senkron çağrı yalnızca anlık cevap gereken okuma ve kontrollerde kullanılır.
3. **Her mesaj en az bir kez gelir.** Tüm tüketiciler idempotent yazılır, tüm komutlar idempotency key taşır.
4. **Durumsuz (stateless) uygulama pod'ları.** Oturum ve geçici durum dış depoda tutulur, böylece pod'lar serbestçe ölçeklenir ve yeniden başlatılır.
5. **Hata varsayılan durumdur.** Her dış çağrıda timeout, sınırlı retry ve circuit breaker vardır. Bir bağımlılık çöktüğünde sistem kısmi hizmet vermeye devam eder.
6. **Konfigürasyon koddan ayrıdır.** Ortam farkları Kubernetes konfigürasyonu ve secret'larıyla yönetilir, imaj her ortamda aynıdır.
7. **Gözlemlenebilirlik baştan gelir.** Her istek ve mesaj bir trace kimliği taşır. Log, metrik ve trace ilk servisle birlikte kurulur.
8. **Her kritik karar bir ADR'dir.** Seçenekler, artı/eksiler, sektör kullanımı ve gerekçe yazılı olarak tutulur.

9) **Global hazır veri modeli ilk günden.** Ülke, şehir, para birimi, saat dilimi ve bölge alanları ilk fazın veri modelinde yer alır; sonradan eklemek tüm servislere dokunur.
10) **Bir etkinliğin tek bir ev bölgesi vardır.** Koltuk ve sipariş yazmaları yalnızca o bölgede yapılır; güçlü tutarlılık bölge içinde, bölgeler arası ise nihai tutarlılık geçerlidir.

## Global tasarım

Platform bölgesel hücrelerden (cell) oluşur: her bölge kendi cluster'ında servislerin tam bir kopyasını çalıştırır ve kendi bölgesindeki etkinliklerin koltuk ve sipariş verisinin tek sahibidir. Bu, bu dokümanın önerisidir; kesin karar aşağıdaki seçeneklerle birlikte verilecek.

**Dağıtım modeli seçenekleri**

| Model | Nasıl çalışır | Artı | Eksi |
| --- | --- | --- | --- |
| Tek bölge + CDN | Tüm servisler tek bölgede, statik içerik ve cache'lenebilir okumalar CDN'den | Basit, tutarlılık sorunu yok | Uzak ülkelerde yüksek gecikme, bölge çökerse tüm sistem durur, veri yerelliği karşılanamaz |
| Aktif-pasif | Bir bölge aktif, diğeri replikasyonla bekler, felakette devralır | Felaket kurtarma, görece basit | Gecikme sorunu çözülmez, pasif bölge boşa maliyet |
| Bölgesel hücreler (öneri) | Her etkinliğin ev bölgesi var; yazma ev bölgesinde, katalog ve arama tüm bölgelere replike | Yerel gecikme, bölge hatası yalnız o bölgeyi etkiler, veri yerelliği mümkün | Yönlendirme ve replikasyon karmaşıklığı, bölgeler arası raporlama zor |
| Global aktif-aktif | Her veri her bölgede yazılabilir, çakışmalar çözülür | En yüksek erişilebilirlik | Koltuk gibi kesin tutarlılık gereken veride çift satış riski; global dağıtık veritabanı gerektirir |

Bölgesel hücre modeli bilet satışının doğasına uyar: bir etkinliğin koltukları tek bir mekanda, tek bir coğrafyadadır. Bu yüzden koltuk için global tutarlılığa gerek kalmaz.

&#91;embedded content: global topoloji · 3 bölgesel hücre\]

Kullanıcı her zaman en yakın bölgeye bağlanır ve kataloğu oradan okur. Satın alma ise etkinliğin ev bölgesine iletilir, böylece aynı koltuğun iki bölgede satılması imkansız hale gelir.

**Veri sınıfları ve nerede yaşadıkları**

| Veri | Yaşadığı yer | Tutarlılık |
| --- | --- | --- |
| Koltuk durumu, hold, sipariş, ödeme | Etkinliğin ev bölgesi | Güçlü (bölge içi) |
| Katalog (etkinlik, mekan, şehir, ülke) | Ev bölgesinde yazılır, tüm bölgelere event ile replike | Nihai (saniyeler) |
| Arama indeksi | Her bölgede yerel projeksiyon | Nihai |
| Kullanıcı hesabı ve kişisel veri | Kullanıcının kayıtlı olduğu bölge (veri yerelliği) | Güçlü (bölge içi) |
| Kullanıcının biletleri | Ev bölgesinde üretilir, kullanıcının bölgesine replike | Nihai |
| Referans veri (ülke, para birimi, döviz kuru) | Global, tüm bölgelere dağıtılır | Nihai |

**Yönlendirme:** Global DNS kullanıcıyı en yakın bölgenin Edge'ine götürür. Okumalar yerel bölgeden cevaplanır. Bir etkinliğe koltuk tutma veya satın alma isteği gelirse Edge, eventId'den ev bölgesini bulur ve isteği oraya iletir. Kimlik bilgisi bölgeden bağımsız doğrulanabilen bir token ile taşınır.

**Yerelleştirme kuralları**

- **Zaman:** Tüm zamanlar UTC saklanır, etkinlik ayrıca mekanın saat dilimini (IANA tz) taşır. Ekranda mekan saati gösterilir.
- **Para:** Fiyat etkinliğin para biriminde tutulur ve tahsil edilir; kullanıcıya bilgi amaçlı çevrilmiş tutar gösterilebilir. Tutarlar ondalık sayı ile değil, küsurat birimiyle (minor unit) tutulur.
- **Dil:** İçerik çevirileri Catalog'da dil bazında saklanır; arayüz metinleri önyüzde.
- **Ödeme:** Payment, ülke ve para birimine göre uygun ödeme sağlayıcıya yönlendiren bir adaptör katmanı kullanır (strategy pattern).
- **Vergi ve yasal metin:** Ülkeye özel KDV oranı ve satış koşulları referans veriden gelir.
- **Veri yerelliği:** Kişisel veri kullanıcının bölgesinden çıkmaz; diğer bölgelere yalnızca userId ve sipariş için gereken asgari bilgi gider (GDPR, KVKK gibi düzenlemeler).

## Mantıksal mimari

Kullanıcı trafiği yalnızca Edge'den girer; durum değiştiren akışlar servisler arasında mesaj aracısı üzerinden ilerler.

&#91;embedded content: mantıksal mimari · Edge, 8 servis, mesaj aracısı, iş kuyruğu\]

Üst yarı senkron dünyadır: önyüz, Edge ve isteğe anında cevap veren servisler. Alt yarı asenkron dünyadır: event'lerle beslenen Ticketing, Search ve Notification. Edge ayrıca arama isteklerini doğrudan Search'e yönlendirir.

## Servisler ve sorumluluklar

Platform sekiz servis ve bir önyüzden oluşur; dokuzuncu servis olan Waiting Room, "Yoğunluk yönetimi" bölümünde anlatılıyor. Her satır bir bounded context'tir ve kendi verisinin tek sahibidir.

| Servis | Sorumluluk | Sahip olduğu veri | Okuma/yazma profili | Öğrettiği pattern |
| --- | --- | --- | --- | --- |
| Edge (API Gateway + BFF) | Tek giriş noktası, yönlendirme, oturum ve token yönetimi, hız sınırlama, bekleme kuyruğu | Oturum (dış depoda) | Çok yüksek trafik, durumsuz | BFF, rate limiting, virtual waiting room |
| Catalog | Etkinlik, mekan, salon planı, fiyat kategorileri | Etkinlik ve mekan kayıtları | Çok okuma, az yazma | Çok katmanlı cache, event ile invalidation |
| Seat Inventory | Koltuk durumu, süreli koltuk tutma (hold), çakışma önleme | Koltuk durumları, hold kayıtları | Ani ve yoğun yazma | Atomik işlem, TTL, optimistic locking |
| Booking | Sipariş yaşam döngüsü, satın alma akışının yönetimi | Siparişler, saga durumu | Orta yazma | Saga orchestration, Outbox, durum makinesi |
| Payment | Ödeme alma, iade, defter kaydı | Ödeme işlemleri, ledger | Orta yazma, kesin tutarlılık | Idempotency key, Inbox, event sourcing (deneysel) |
| Ticketing | Ödemesi tamamlanan sipariş için bilet ve QR üretimi | Biletler | Düşük yazma | Event-driven tüketici |
| Notification | E-posta ve push bildirimleri | Gönderim kayıtları | Kuyruk tabanlı işleme | Work queue, retry, DLQ |
| Search | Etkinlik arama ve filtreleme | Sadece okuma modeli (projeksiyon) | Çok okuma | CQRS, event projeksiyonu |
| Web önyüz | Etkinlik listeleme, koltuk seçimi, satın alma, biletlerim | Yok | — | BFF üzerinden güvenli oturum |

Kimlik sağlayıcı (Identity Provider) bir iş servisi değil, platform bileşenidir: kullanıcı hesapları, giriş ve token üretimi ondadır. Ticketing ilk fazda Booking içinde başlayıp sonra ayrılabilir; bu ayrışma Strangler Fig pratikçiği olur.

## İletişim modeli ve event kataloğu

Servisler arası iletişim üç kanaldan geçer; hangi kanalın kullanılacağını ihtiyacın doğası belirler.

| Kanal | Ne zaman | Örnek |
| --- | --- | --- |
| Senkron istek/cevap | Çağıranın cevabı beklemesi zorunluysa ve işlem kısa sürerse | Önyüz → Edge → Catalog: etkinlik detayı; Booking → Seat Inventory: koltuk tut |
| Event akışı (publish/subscribe, kalıcı, yeniden okunabilir) | Bir domain olayı birden fazla servisi ilgilendiriyorsa, sıralama ve yeniden oynatma gerekiyorsa | OrderCreated, PaymentCompleted, EventUpdated |
| İş kuyruğu (work queue, tüketildiğinde silinir) | Tek bir işin bir tüketici tarafından yapılması gerekiyorsa, retry ve DLQ önemliyse | Bilet e-postası gönder, push bildirimi gönder |

**Event kataloğu (ilk taslak)**

| Event | Üreten | Tüketen | Anahtar (sıralama için) |
| --- | --- | --- | --- |
| EventPublished / EventUpdated | Catalog | Search, Catalog cache invalidation | eventId |
| SeatsHeld | Seat Inventory | Booking | eventId |
| SeatHoldExpired | Seat Inventory | Booking | eventId |
| SeatsReleased | Seat Inventory | Catalog (müsaitlik özeti) | eventId |
| OrderCreated | Booking | Payment | orderId |
| PaymentCompleted / PaymentFailed | Payment | Booking | orderId |
| SeatsConfirmed | Seat Inventory | Booking | eventId |
| OrderConfirmed / OrderCancelled | Booking | Ticketing, Notification, Search | orderId |
| TicketIssued | Ticketing | Notification | orderId |

Saga orchestration ile ilerlediğinde Booking'den Seat Inventory ve Payment'a giden mesajlar event değil, **komut** olur (ReserveSeats, ChargePayment). Choreography ile orchestration arasındaki farkı görmek için akışı iki yöntemle de yazacağız.

Tüm mesajlar ortak bir zarf taşır: messageId (idempotency için), correlationId, causationId, traceparent, schemaVersion, occurredAt, homeRegion (mesajın ait olduğu ev bölgesi; replikasyon döngüsünü önlemek için de kullanılır).

## Kritik akış: koltuk tutma ve satın alma sagası

Satın alma, üç servise yayılan ve tek bir veritabanı transaction'ı ile yapılamayan bir iştir. Bu yüzden Booking'in yönettiği bir saga olarak tasarlanır.

&#91;embedded content: satın alma sagası · 5 adım, 2 telafi yolu\]

Her adım kendi servisinde yerel bir transaction'dır ve sonucunu mesajla bildirir. Başarısız bir adım, önceki adımları telafi komutlarıyla geri alır. En zor durum, hold süresi dolduktan sonra gelen başarılı ödemedir: koltuk artık başkasına satılmış olabilir, bu yüzden ödeme iade edilir.

**Tasarım soruları (uygulamada cevaplanacak)**

- Hold süresi kaç dakika olmalı ve ödeme sayfasında süre uzatılabilir mi?
- Ödeme sağlayıcıdan cevap gelmezse (timeout) sipariş hangi durumda bekler?
- Aynı kullanıcı aynı anda kaç aktif hold tutabilir?

## Yoğunluk yönetimi: adil sıra ve kontrollü giriş

Satış açıldığında kullanıcılar doğrudan satın alma akışına değil, bir bekleme odasına girer. Sistem yalnızca satılabilir koltuk sayısı kadar kişiyi sırayla içeri alır. 100 koltuk ve 1.000 kişi varsa ilk gelenler kesin olarak satın alabilir, diğerleri sırasını bekler.

**Neden genelde kimse bilet alamıyor?** 1.000 kişinin aynı anda koltuk tutmaya çalışması, aynı satırlar üzerinde kilit ve versiyon çakışması üretir. İstekler zaman aşımına uğrar, kullanıcılar sayfayı yeniler ve her yenileme yükü katlar (retry storm). Sistem meşgul olmakla uğraşırken kimse akışı tamamlayamaz. Çözüm, gelme anını satın alma anından ayırmaktır: kuyruk yükü emer, satın alma tarafı yalnızca kaldırabileceği kadarını görür.

&#91;embedded content: bekleme odası · 5 adım, serbest kalan koltuğun döngüsü\]

Sıra yalnızca koltuk boşaldıkça ilerler. Vazgeçen ya da süresi dolan kullanıcının koltuğu, bütçe üzerinden sıradaki kullanıcıya geçer.

Bu iş için platforma yeni bir servis eklenir: **Waiting Room**. Sıra numarası verir, giriş bütçesini hesaplar ve giriş izni üretir. Edge, satın alma uçlarına yalnızca geçerli giriş izni taşıyan istekleri geçirir.

**Akış kuralları**

1. **Sıraya giriş:** Giriş yapmış olmak zorunludur ve her hesap bir etkinlik için tek bir sıra numarası alır. Numara etkinliğin ev bölgesindeki atomik bir sayaçtan gelir; aynı milisaniyede gelen iki istek bile farklı ve sıralı numara alır.
2. **Bekleme:** Bekleme sayfası CDN'den sunulur. Kullanıcı kendi numarasını ve o an içeri alınan son numarayı (serving number) görür. Herkes aynı tek değeri sorguladığı için bu değer cache'lenir, binlerce kullanıcı backend'e yük bindirmez.
3. **Giriş bütçesi:** Serving number, yalnızca satılabilir koltuk kaldıkça ilerler. Garantili kural: içeri alınan her kullanıcı için kullanıcı başına azami bilet sayısı kadar koltuk ayrılır. 100 koltuk ve kişi başı en fazla 4 bilet varsa ilk 25 kişi içeri girer. Onlar ortalama 2 bilet alırsa kalan 50 koltuk için sıradaki 12 kişi alınır ve bu, koltuklar bitene kadar sürer. Ayrıca aynı anda satın alma ekranında olabilecek kişi sayısı, backend kapasitesiyle sınırlanır.
4. **Giriş izni:** İçeri alınan kullanıcıya imzalı, kısa ömürlü bir token verilir (kullanıcı, etkinlik, son geçerlilik). Edge bu token'ı başka bir servise sormadan, imzasından doğrular.
5. **Satın alma penceresi:** Koltuk seçimi ve ödeme için iki ayrı süre vardır (örneğin 3 dk seçim, 7 dk ödeme; kesin değerler yük testinde belirlenecek). Sayfa açık olduğu sürece heartbeat gönderir; "Vazgeç" butonu koltuğu anında bırakır.
6. **Sıradakine geçiş:** Süre dolar, kullanıcı vazgeçer veya heartbeat kesilirse hold silinir ve SeatsReleased event'i yayınlanır. Waiting Room bütçeyi yeniden hesaplar ve sıradaki kullanıcıları içeri alır.
7. **Tükenme:** Tüm koltuklar satıldığında kuyruktaki herkese anında "tükendi" denir. Yalnızca hold'daki koltuklar kaldıysa "koltuk boşalabilir, beklemeye devam edebilirsin" bilgisi gösterilir.
8. **Kötüye kullanım:** Hesap başına bilet limiti, sıraya girişte hız sınırlama ve bot koruması (CAPTCHA). Aynı hesabın farklı sekmeleri aynı sıra numarasını görür.
9. **Global:** Sıra sayacı tek bir yerde, etkinliğin ev bölgesinde tutulur; diğer bölgelerin Edge'leri sıraya giriş isteğini oraya iletir. Katı FIFO'nun bedeli: uzak ülkedeki kullanıcı ağ gecikmesi kadar dezavantajlıdır.

### Etkinlik bazlı dinamik odalar

Her satışın kendi bekleme odası vardır; X etkinliğine bilet alan kullanıcı Y'nin sırasını beklemez. Oda birimi etkinlik değil satıştır: bir turnenin her tarihi ve aynı tarihin ön satışı ile genel satışı ayrı odalardır (anahtar: eventId + saleId). Giriş izni odaya bağlıdır; X'in izniyle Y'den bilet alınamaz.

&#91;embedded content: oda yaşam döngüsü · 5 durum, planlı ve otomatik açılış\]

Oda iki yoldan açılır: organizatörün tanımladığı planlı bir satış ya da bir etkinliğin anlık aktif alıcı sayısının eşiği aşması. Tükendikten sonra hold'u düşen koltuklar odayı yeniden AKTİF'e döndürür.

**İki seviyeli giriş bütçesi.** Odalar ayrı ama backend ortaktır. Aynı anda 30 popüler satış açılır ve her oda yalnızca kendi koltuk bütçesine bakarsa, toplamda Seat Inventory yine çökebilir. Bu yüzden bir odanın içeri alabileceği kişi sayısı iki bütçenin küçüğüdür:

```latex
\text{giriş}_i = \min\left(\text{koltuk bütçesi}_i,\; \max\left(\text{taban pay},\; C \cdot \frac{w_i}{\sum_j w_j}\right)\right)
```

Burada C, platformun aynı anda kaldırabildiği alıcı sayısı (yük testinden gelir), w ise odanın ağırlığıdır (örneğin kuyruk uzunluğu veya kalan koltuk). Taban pay, küçük bir etkinliğin dev bir konserin gölgesinde aç kalmamasını sağlar.

**Yalıtım (bulkhead) veri katmanında da sürer:**

- Bir odanın tüm durum kayıtları aynı partition/shard üzerinde tutulur; böylece odaya ait çok adımlı işlemler atomik olur ve sıcak bir oda yalnızca kendi shard'ını yorar.
- Çok büyük bir satış ayrı bir shard'a sabitlenebilir.
- Seat Inventory event'lerinde partition anahtarı eventId'dir.

**Mantıksal durum modeli (teknolojiden bağımsız):**

| Kayıt | İçerik | Ömür |
| --- | --- | --- |
| room/{eventId:saleId}/state | Oda durumu, ayarlar (kişi başı limit, sıralama yöntemi, ağırlık) | Satış boyunca |
| room/{eventId:saleId}/seq | Sıra sayacı (atomik artır) | Oda kapanınca TTL |
| room/{eventId:saleId}/serving | İçeri alınan son numara | Oda kapanınca TTL |
| room/{eventId:saleId}/members | userId → sıra numarası (tekrar girişi engeller) | Oda kapanınca TTL |
| room/{eventId:saleId}/admitted | userId → izin bitiş zamanı, heartbeat | İzin süresi |

**Edge oda durumunu her istekte sormaz.** Aktif odaların listesi Edge'de cache'lenir ve oda açılıp kapandıkça event ile güncellenir. Odası olmayan etkinliğin isteği ek bir çağrı olmadan geçer.

**Birden fazla oda:** Kullanıcı aynı anda farklı satışların odalarında bekleyebilir; bot riskine karşı hesap başına aktif oda sayısına üst sınır konur.

**Sıralama yöntemi seçenekleri**

| Yöntem | Nasıl çalışır | Artı | Eksi | Kimler kullanıyor |
| --- | --- | --- | --- | --- |
| Katı FIFO | Sunucuya varan sırayla numara verilir | Senin istediğin "ilk gelen alır" kuralı; tahmini bekleme süresi kesin | Satış açılış anında milisaniye yarışı; botlar ve yakın coğrafyadakiler avantajlı | [SeatGeek](https://archive.qconlondon.com/system/files/presentation-slides/qcon_london_seatgeek.pdf) (FIFO gereksinimi), [Cloudflare Waiting Room](https://developers.cloudflare.com/waiting-room/reference/queueing-methods/) varsayılan yöntemi |
| Ön kuyruk + rastgele + FIFO | Satış öncesi gelenler bekler, satış anında rastgele sıralanır; sonra gelenler FIFO ile arkaya eklenir | Erken gelenler arasında eşit şans; milisaniye yarışı ve bot hız avantajı ortadan kalkar | "İlk giren" garantisi satış açılış anı için geçerli değil | [Queue-it](https://queue-it.com/product/scheduled/) zamanlanmış satışlar, [Ticketmaster Smart Queue](https://business.ticketmaster.com/smart-queue/) (satış başlayınca sıra atanır) |
| Tamamen rastgele | Boş yer açıldıkça kuyruktan rastgele kişi seçilir | Kısa süreli, yoğun ilgili satışlarda eşit şans | Bekleme süresi tahmin edilemez | [Cloudflare Waiting Room](https://developers.cloudflare.com/waiting-room/reference/queueing-methods/) seçeneği |

Tasarım senin kuralınla katı FIFO üzerine kurulur. Sıralama yöntemi Waiting Room'da değiştirilebilir bir strateji olarak yazılır; böylece ikinci yöntem sonradan eklenebilir.

**Büyük bilet firmaları bu sorunu nasıl çözüyor**

| Firma / çözüm | Yaklaşım | Kamuya açık teknoloji bilgisi |
| --- | --- | --- |
| [Ticketmaster](https://business.ticketmaster.com/smart-queue/) | Smart Queue: hesapla giriş yapılır, satıştan önce bekleme odasına girilir. Satış başlayınca sıra atanır ve kullanıcılar satışın tamamlanma oranını en yüksek tutacak hızda içeri alınır. | [Kafka üzerinden haberleşen yüzlerce mikroservis](https://confluent.io/blog/event-streaming-reflections-as-confluent-turns-five-part-1); koltuk müsaitliği için Kafka Streams ve ksqlDB |
| [SeatGeek](https://aws.amazon.com/blogs/architecture/build-a-virtual-waiting-room-with-amazon-dynamodb-and-aws-lambda-at-seatgeek) | Üçüncü parti çözümü yetersiz bulup kendi bekleme odasını (Vroom) yazdı. İki mod: satış öncesi bekletme ve satış sırasında kısma. | [Kuyruk durumu AWS Lambda ve DynamoDB'de, doğrulama ve yönlendirme Fastly CDN edge'inde](https://archive.qconlondon.com/system/files/presentation-slides/qcon_london_seatgeek.pdf) |
| [AWS Virtual Waiting Room](https://docs.aws.amazon.com/solutions/latest/virtual-waiting-room-on-aws/solution-components.html) (açık kaynak referans) | Sıra numarası ve serving number; sırası gelene imzalı, süreli JWT | Redis sayacı, ani istekleri tamponlayan SQS, token kayıtları için DynamoDB |
| [Queue-it](https://queue-it.com/product/scheduled/) (SaaS) | Ön kuyruk, satış anında rastgele sıralama, sonrası FIFO | Yönetilen hizmet; site önüne yönlendirme ile entegre olur |
| [Cloudflare Waiting Room](https://developers.cloudflare.com/waiting-room/reference/queueing-methods/) (SaaS) | FIFO veya rastgele | Sıra, kullanıcının bekleme odasına ilk geldiği anı tutan bir cookie zaman damgasıyla belirlenir; Cloudflare CDN'i gerektirir |

**Projede bekleme odasının teknoloji seçenekleri**

Oda durumunu tutacak depo için gereksinimler: oda başına doğrusal (linearizable) atomik sayaç, üyelik ve tekrar kontrolü, TTL, satış açılışında saniyede binlerce yazma, failover sırasında sıra numarasının geri gitmemesi ve Kubernetes üzerinde çalışabilmesi.

| Seçenek | Artı | Eksi | Sektörde |
| --- | --- | --- | --- |
| Bellek içi KV: Redis / Valkey | Atomik artırma, sıralı küme, TTL; script ile çok adımlı atomik işlem; çok yaygın | Replikasyon asenkron: failover'da son yazmalar kaybolup sıra numarası tekrar verilebilir; Redis 8 AGPL/RSAL/SSPL lisanslı, Valkey BSD lisanslı bir fork | [AWS Virtual Waiting Room](https://docs.aws.amazon.com/solutions/latest/virtual-waiting-room-on-aws/solution-components.html) (Redis OSS) |
| Java veri gridi: Hazelcast (CP Subsystem) | [Raft tabanlı, doğrusal dağıtık AtomicLong](https://hazelcast.com/hazelcast-imdg-3-12-introduces-cp-subsystem/): failover'da sayaç tutarlı kalır; Java ve Spring ile doğal | Raft yazma gecikmesi; sıralı küme gibi yapılar kendin kurulur; topluluk Redis'ten küçük | Finans ve e-ticarette veri gridi olarak yaygın; bekleme odası örneği kamuya açık değil |
| Oda başına aktör: Apache Pekko Cluster Sharding | Her oda tek bir aktörde: sıralama doğal ve bellek içi hızda; Durable Objects modelinin self-hosted karşılığı | Öğrenme eğrisi yüksek; kalıcılık için ayrı journal gerekir | [Cloudflare Waiting Room](https://blog.cloudflare.com/building-waiting-room-on-workers-and-durable-objects) aynı fikri Workers ve Durable Objects ile uyguluyor |
| İlişkisel DB: PostgreSQL (sequence + tablo) | Kalıcı, zaten altyapıda var; sequence hızlı | Serving number tek bir sıcak satır; ani yazma dalgasında bağlantı havuzu ve WAL baskısı; TTL yok | Doğrudan örnek yok |
| Bulut KV: DynamoDB benzeri | Koşullu yazma, yönetilen ölçek | Bulut sağlayıcıya bağımlı, self-hosted Kubernetes hedefimize uymuyor | [SeatGeek](https://aws.amazon.com/blogs/architecture/build-a-virtual-waiting-room-with-amazon-dynamodb-and-aws-lambda-at-seatgeek) |
| Log: Kafka partition'ı | Sıralı, kalıcı; FIFO doğal | "Kaçıncı sıradaymışım" sorgusu ve tek tek içeri alma zahmetli | Doğrudan örnek yok |
| SaaS: Queue-it, Cloudflare | Hızlı devreye alma, hazır bot koruması | Öğrenme değeri düşük, maliyet, sağlayıcı bağımlılığı | Birçok bilet ve perakende sitesi |

**Karar durumu:** Depo teknolojisi seçilmedi; Faz 4 öncesinde ADR ile karar verilecek. İki güçlü aday var: yaygınlık ve zengin veri yapıları için Redis/Valkey, failover'da sıra numarasının tutarlı kalması için Hazelcast CP. Waiting Room depo erişimini bir port (arayüz) arkasında tutar, böylece iki aday aynı testlerle karşılaştırılabilir.

## Veri yönetimi ve tutarlılık

Koltuk ve ödeme verisi güçlü tutarlı, servisler arası görünüm ise nihai (eventual) tutarlıdır. Bu ayrım tüm veri kararlarının temelidir.

| Konu | Karar | Neden |
| --- | --- | --- |
| Servis başına veritabanı | Her servisin kendi şeması veya instance'ı vardır | Bağımsız değişiklik ve dağıtım; bir servisin şema değişikliği diğerini kırmaz |
| Koltuk çakışması | İki katmanlı koruma: hızlı depoda atomik hold + kalıcı depoda versiyon kontrolü | İlk katman yükü keser, ikinci katman doğruluğu garanti eder |
| Dual-write problemi | Transactional Outbox: iş verisi ve event aynı transaction'da yazılır, ayrı bir süreç event'i yayınlar | Veritabanı ve mesaj aracısına aynı anda atomik yazmak mümkün değil |
| Tekrar eden mesaj | Inbox tablosu: işlenen messageId'ler iş verisiyle aynı transaction'da kaydedilir | En az bir kez teslimat, tekrarı garanti eder |
| Okuma modelleri | CQRS: Search ve müsaitlik özeti event'lerden beslenir | Yazma modelini yormadan farklı sorgu ihtiyaçlarını karşılar |
| Ödeme defteri | Append-only ledger; deneysel olarak event sourcing | Denetlenebilirlik, finansal sistemlerdeki standart yaklaşım |
| Şema evrimi | Mesajlarda versiyon alanı, geriye uyumlu değişiklik kuralı | Servisler farklı zamanlarda güncellenir |

**Bilinçli olarak kabul edilen tutarsızlıklar:** Arama sonuçlarındaki müsaitlik bilgisi birkaç saniye geriden gelebilir. Kesin müsaitlik her zaman koltuk tutma anında Seat Inventory'den doğrulanır.

## Cache stratejisi

Cache üç farklı amaçla kullanılır: okuma yükünü azaltmak, geçici durumu tutmak ve dağıtık koordinasyon. Her birinin tutarlılık beklentisi farklıdır.

| Kullanım | Nerede | Strateji | Geçersizleştirme / süre |
| --- | --- | --- | --- |
| Etkinlik detayı ve salon planı | Catalog | İki katman: pod içi bellek (L1) + paylaşımlı dağıtık cache (L2), cache-aside | EventUpdated event'i ile L2 silinir, L1'lere yayın mesajı gider; ayrıca kısa TTL |
| Müsaitlik özeti ("%80 dolu") | Catalog / Search | Read-through, kısa TTL | Seat event'leri ile güncellenir; birkaç saniyelik gecikme kabul |
| Koltuk tutma (hold) | Seat Inventory | Dağıtık depoda atomik işlem, birincil kaynak gibi | Sabit TTL (örn. 10 dk); dolunca SeatHoldExpired |
| Oturum | Edge (BFF) | Dış depoda oturum, pod'lar durumsuz | Oturum süresi kadar |
| Idempotency key | Payment, Booking | İlk istekte kayıt, tekrarında kayıtlı cevabı dön | Akış süresi + güvenlik payı |
| Hız sınırlama ve bekleme kuyruğu | Edge | Kullanıcı/IP başına sayaç, sıralı kuyruk | Pencere süresi kadar |

**Ele alınacak zor problemler**

- **Cache stampede:** Popüler bir etkinliğin cache'i düştüğünde binlerce istek aynı anda veritabanına gider. Karşılığı: tek kişinin yeniden yüklemesi (request coalescing), erken ve olasılıksal yenileme.
- **Hot key:** Satış açılışında tek etkinlik anahtarı tüm trafiği çeker. Karşılığı: L1 katmanı ve anahtarı parçalama.
- **Tutarlılık penceresi:** "Önce DB yaz, sonra cache sil" sırası ve aradaki yarış koşulu (race condition) üzerinde çalışılacak.
- **Dağıtık kilidin sınırları:** Kilit süresi dolarken işlemin sürmesi ve fencing token ihtiyacı. Koltukta kilit yerine atomik işlem tercih edilmesinin nedeni bu.

## Güvenlik

Kimlik doğrulama standart bir protokolle (OAuth2 / OpenID Connect) dış bir kimlik sağlayıcıya devredilir; token tarayıcıya hiç inmez.

- **Kullanıcı girişi:** Önyüz → Edge (BFF) → kimlik sağlayıcı, Authorization Code + PKCE akışı. Edge token'ları sunucu tarafı oturumda saklar; tarayıcı yalnızca HttpOnly, Secure, SameSite cookie görür.
- **Servislere erişim:** Edge, isteği access token ile içeri iletir (token relay). Her servis token'ı kendisi doğrular (imza, süre, audience); gateway'e körü körüne güvenilmez.
- **Yetkilendirme:** Kaba yetki rollerle (customer, organizer, admin), ince yetki servis içinde kaynak sahipliğiyle ("bu sipariş bu kullanıcının mı?") kontrol edilir.
- **Servisler arası çağrı:** Kullanıcı adına yapılan çağrıda kullanıcı token'ı taşınır; arka plan işlerinde servis kendi kimliğiyle (client credentials) token alır.
- **Mesajlar:** Event'ler kullanıcı token'ı taşımaz, yalnızca userId taşır. Mesaj aracısında servis başına kullanıcı ve topic/kuyruk yetkisi tanımlanır.
- **Secret yönetimi:** Parolalar ve anahtarlar imajda veya repoda bulunmaz; Kubernetes secret'ı olarak verilir, ileri fazda harici bir secret yöneticisine taşınır.
- **Ağ:** Kubernetes network policy ile her servis yalnızca izinli bağımlılıklarına erişir; dışarıya yalnızca Edge açıktır.

## Gözlemlenebilirlik

Bir satın alma isteği, önyüzden bilet e-postasına kadar tek bir trace olarak izlenebilmelidir; senkron çağrılar ve mesajlar dahil.

- **Trace:** Trace bağlamı HTTP header'larında ve mesaj zarfında (traceparent) taşınır. Outbox'tan yayınlanan mesaj, orijinal isteğin trace'ine bağlanır.
- **Metrik:** Her serviste RED metrikleri (istek sayısı, hata oranı, süre). Ek olarak consumer lag, outbox birikimi, cache hit oranı, aktif hold sayısı, saga adımlarının süresi.
- **Log:** Yapılandırılmış (JSON) log; her satırda traceId, correlationId, userId. Loglar merkezi bir depoya toplanır.
- **Alarm ve SLO:** Örnek SLO'lar: koltuk tutma p99 gecikmesi, satın alma akışının başarı oranı, DLQ'ya düşen mesaj sayısı. Hedef değerler yük testinden sonra belirlenecek.
- **Sağlık kontrolleri:** Her serviste ayrı liveness ve readiness uçları. Readiness, bağımlılıklar hazır değilken trafiği keser; liveness dış bağımlılığa bakmaz (aksi halde zincirleme yeniden başlatma olur).

## Kubernetes dağıtım topolojisi

Uygulama servisleri durumsuz Deployment, altyapı bileşenleri durumlu StatefulSet olarak ayrı namespace'lerde çalışır. Diyagram tek bir bölgesel hücreyi gösterir; her bölge aynı topolojiye sahip ayrı bir cluster'dır. Proje tek bir yerel cluster'la başlar, çok bölge yerelde ikinci bir cluster ile simüle edilir.

&#91;embedded content: Kubernetes topolojisi · 5 namespace\]

Namespace ayrımı yetki (RBAC), network policy ve kaynak kotasını katman bazında yönetmeyi sağlar.

**Kubernetes'te öğrenilecek konular**

- Deployment, ReplicaSet, rolling update ve geri alma (rollback)
- Service, DNS tabanlı servis keşfi, Ingress / Gateway API
- ConfigMap, Secret, ortam başına konfigürasyon
- Liveness, readiness ve startup probe'ları; graceful shutdown ve preStop
- Kaynak istek/limitleri, HPA ile CPU ve özel metrik bazlı ölçekleme
- StatefulSet, PersistentVolume ve operator pattern'i
- PodDisruptionBudget, anti-affinity, network policy
- Job/CronJob (örn. süresi dolan hold temizliği, outbox temizliği)

## Açık teknoloji kararları

Aşağıdaki rollerin hiçbiri için henüz teknoloji seçilmedi. Uygulama dili Java ve Spring Boot, çalışma ortamı Kubernetes olarak sabittir. Her satır, ilgili fazdan önce seçenek karşılaştırmasıyla karara bağlanacak ve bir ADR olarak bu dokümana eklenecek.

| Rol | Değerlendirilecek seçenekler | Karar zamanı |
| --- | --- | --- |
| Global dağıtım modeli | Tek bölge + CDN, aktif-pasif, bölgesel hücreler, global aktif-aktif | Faz 0 |
| Yerel Kubernetes ortamı | kind, k3d, minikube, Docker Desktop | Faz 0 |
| Dağıtım paketleme | Ham manifest, Kustomize, Helm | Faz 0 |
| İşlemsel veritabanı | PostgreSQL, MySQL, dağıtık SQL (CockroachDB, YugabyteDB) | Faz 0 |
| Kimlik sağlayıcı | Keycloak, Spring Authorization Server, Zitadel, yönetilen SaaS (Auth0/Okta, Entra, Cognito) | Faz 1 |
| Ingress / Edge | Spring Cloud Gateway, Kubernetes Gateway API uygulamaları, NGINX | Faz 1 |
| Servis keşfi ve konfigürasyon | Kubernetes DNS + ConfigMap, Spring Cloud Kubernetes, Eureka + Config Server | Faz 1 |
| Önyüz ve i18n | React, Angular, Vue; framework'ün yerelleştirme kütüphanesi | Faz 1 |
| Dayanıklılık | Uygulama içi kütüphane, service mesh | Faz 2 |
| Event akışı | Kafka, Redpanda, Pulsar | Faz 3 |
| Outbox yayınlayıcı | CDC (Debezium), polling publisher | Faz 3 |
| Dağıtık cache / hızlı depo | Redis, Valkey, Hazelcast | Faz 4 |
| Pod içi cache | Caffeine, Spring'in basit cache'i | Faz 4 |
| CDN | Bulut sağlayıcının CDN'i, bağımsız CDN | Faz 4 |
| İş kuyruğu | RabbitMQ, event akışını kuyruk gibi kullanmak | Faz 5 |
| Arama deposu | Elasticsearch, OpenSearch, PostgreSQL tam metin | Faz 5 |
| Gözlemlenebilirlik yığını | OpenTelemetry + Prometheus/Grafana/Tempo/Loki, Elastic, SaaS | Faz 6 |
| Yük testi | k6, Gatling, JMeter | Faz 7 |
| Bölgeler arası replikasyon | Mesaj aracısı mirroring (örn. MirrorMaker), CDC, uygulama seviyesinde yayın | Faz 8 |
| Global trafik yönlendirme | GeoDNS, anycast, global load balancer | Faz 8 |
| Çoklu cluster yönetimi | GitOps (Argo CD, Flux), cluster başına ayrı pipeline | Faz 8 |

## Uygulama yol haritası

Her faz, Kubernetes üzerinde çalışan bir demo, ilgili ADR'ler ve "neyi kırdım, ne öğrendim" notuyla kapanır. Bir sonraki faza geçmeden önce o fazın teknoloji kararları birlikte verilir.

1. **Faz 0: Temel ve global veri modeli (2 hafta).** Global dağıtım modeli kararı. Yerel Kubernetes cluster'ı, dağıtım paketleme yöntemi, multi-module proje iskeleti, ortak kütüphaneler (mesaj zarfı, hata modeli, para ve zaman tipleri). İlk servis Catalog: ülke, şehir, mekan, etkinlik, ev bölgesi, saat dilimi, para birimi ve çok dilli içerik; migration, sağlık kontrolleri, ConfigMap/Secret, temel log ve metrik.
2. **Faz 1: Giriş kapısı ve kimlik (2 hafta).** Kimlik sağlayıcı cluster içinde, Edge (gateway + BFF), basit çok dilli önyüz: giriş, ülke/şehir seçimi, etkinlik listesi, etkinlik detayı (mekan saatiyle). Ingress ile dışarıya açma.
3. **Faz 2: Koltuk ve senkron akış (2 hafta).** Seat Inventory ve Booking. Koltuk tutma önce senkron ve yalnızca veritabanıyla. Timeout, retry, circuit breaker; bağımlılığı bilinçli olarak çökertip davranışı gözleme.
4. **Faz 3: Mesajlaşma ve saga (4 hafta).** Mesaj aracısı cluster içinde, Payment servisi (ülkeye göre sahte PSP adaptörleri). Outbox, Inbox, satın alma sagası: önce choreography, sonra orchestration. Retry, DLQ, consumer lag izleme. Önyüzde koltuk seçimi ve ödeme.
5. **Faz 4: Cache ve flash sale (3 hafta).** Dağıtık cache, koltuk hold'unun hızlı depoya taşınması, iki katmanlı Catalog cache'i ve invalidation, CDN'e uygun HTTP cache başlıkları, hız sınırlama, sanal bekleme kuyruğu.
6. **Faz 5: Okuma modelleri ve bildirim (2 hafta).** Search (ülke/şehir/tarih filtreli CQRS projeksiyonu), Notification (iş kuyruğu, çok dilli şablonlar), Ticketing'in Booking'den ayrılması. Önyüzde arama ve "biletlerim".
7. **Faz 6: Uçtan uca gözlemlenebilirlik (2 hafta).** Dağıtık trace (mesajlar dahil), dashboard'lar, alarmlar, SLO'lar.
8. **Faz 7: Yük, ölçek ve sertleştirme (3 hafta).** Flash sale yük testi, otomatik ölçekleme (HPA), PodDisruptionBudget, kaynak limitleri, network policy, contract testleri, kaos testleri. Darboğaz analizi ve ADR.
9. **Faz 8: Çok bölge (3-4 hafta).** İkinci yerel cluster ile ikinci bölge. Ev bölgesine yönlendirme, katalog ve bilet replikasyonu, kullanıcı verisinin bölgede kalması, GitOps ile iki cluster'a dağıtım. Bir bölgeyi kapatıp diğerinin davranışını gözleme.

Toplam yaklaşık 23-24 hafta. Faz süreleri haftalık çalışma temposuna göre güncellenecek.
