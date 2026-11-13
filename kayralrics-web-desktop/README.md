# Kayralrics Web Desktop

Fedora KDE üzerinde, ana KDE oturumundan bağımsız çalışan bir XFCE masaüstünü tarayıcıdan açar. Masaüstü `Xvfb` üzerinde sanal bir X11 ekranında çalışır; `x11vnc` görüntüyü VNC ile sunar; `noVNC` ve `websockify` masaüstünü tarayıcıya taşır.

**Varsayılan adres:** `http://127.0.0.1:1337/vnc.html`

**Varsayılan komut:** `kayralrics`

## Özellikler

- KDE Plasma oturumu açık kalırken ayrı bir XFCE oturumu çalışır.
- Tarayıcı sekmesini veya noVNC penceresini kapatmak XFCE oturumunu kapatmaz.
- XFCE içinden Fedora'ya kurulu masaüstü uygulamaları açılabilir.
- `systemd --user` servisi ile masaüstü arka planda yönetilir.
- `loginctl enable-linger` sayesinde servis kullanıcı grafik oturumuna giriş yapmadan da sistem açılışında başlayabilir.
- VNC parola korumalıdır; VNC ve noVNC yalnızca `127.0.0.1` üzerinde dinler.
- Xvfb, Xauthority erişim kontrolüyle başlatılır; `-ac` kullanılmaz.

## Nasıl çalışır?

```text
Fedora Linux
├── KDE Plasma (mevcut ana masaüstü)
└── systemd --user: kayralrics.service
    ├── Xvfb :99                 sanal X11 ekranı
    ├── XFCE                     ayrı masaüstü oturumu
    ├── x11vnc :5901             parola korumalı VNC
    └── noVNC/websockify :1337   yalnızca localhost web arayüzü
```

Bu kurulum sanal makine veya ikinci işletim sistemi değildir. KDE ve XFCE aynı Fedora kurulumunu, kullanıcı hesabını, dosyaları, kurulu programları, RAM'i ve CPU'yu paylaşır. XFCE'nin görüntüsü ayrı bir sanal ekrandan gelir.

## Gereksinimler

- Fedora Workstation veya Fedora KDE Spin
- Normal bir kullanıcı hesabı; kurulum sırasında `sudo` yetkisi
- Fedora depolarına erişim
- Tarayıcıda JavaScript ve WebSocket desteği

Kurulum betiği Fedora depolarından Xvfb, XFCE bileşenleri, x11vnc, noVNC, Xauthority, D-Bus ve yardımcı araçları yükler. Paket adları Fedora paket kayıtlarıyla uyumludur.

## Kurulum

Projeyi klonla:

```bash
git clone https://github.com/USERNAME/kayralrics-web-desktop.git
cd kayralrics-web-desktop
```

Kurulumu normal kullanıcı hesabınla başlat:

```bash
chmod +x install.sh uninstall.sh
./install.sh
```

Kurulum sırasında:

1. Gerekli Fedora paketleri yüklenir.
2. `~/.vnc/passwd` yoksa x11vnc parola oluşturma ekranı açılır.
3. Betik ve systemd kullanıcı servisi kullanıcının ev dizinine kopyalanır.
4. `loginctl enable-linger` etkinleştirilir.
5. `kayralrics.service` etkinleştirilir ve başlatılır.

### VNC parolası hakkında

x11vnc'nin klasik VNC parola doğrulaması parolanın yalnızca ilk 8 karakterini kullanır. Uzun bir parola yazılsa bile ilk sekiz karakter dışındaki kısım doğrulamada dikkate alınmaz. Bu parolayı başka hesaplarda kullanma. Parolayı değiştirmek için:

```bash
x11vnc -storepasswd
chmod 600 ~/.vnc/passwd
systemctl --user restart kayralrics.service
```

## Kullanım

Yeni bir terminal açtıktan sonra:

```bash
kayralrics
```

Bu komut servisi başlatır ve tarayıcıda masaüstü sayfasını açar. noVNC ekranında VNC parolasını gir.

Komut seçenekleri:

| Komut | İşlev |
|---|---|
| `kayralrics` veya `kayralrics open` | Servisi başlatır ve tarayıcıyı açar |
| `kayralrics start` | Servisi başlatır |
| `kayralrics stop` | Servisi durdurur |
| `kayralrics restart` | Servisi yeniden başlatır |
| `kayralrics status` | Servis durumunu gösterir |
| `kayralrics logs` | Canlı servis günlüğünü gösterir |

Tarayıcı adresi:

```text
http://127.0.0.1:1337/vnc.html
```

## Bilgisayar açılışında otomatik başlatma

Kurulum betiği aşağıdaki işlemleri zaten yapar:

```bash
sudo loginctl enable-linger "$USER"
systemctl --user enable --now kayralrics.service
```

`enable-linger`, kullanıcı systemd yöneticisinin sistem açılışında başlatılmasını ve kullanıcı oturumu kapalıyken de kullanıcı servislerini çalıştırmasını sağlar. Servisin durumu:

```bash
loginctl show-user "$USER" -p Linger
systemctl --user is-enabled kayralrics.service
systemctl --user status kayralrics.service
```

Beklenen değerler `Linger=yes` ve `enabled` şeklindedir.

Linger özelliği yalnızca Kayralrics'e özel değildir; aynı kullanıcının diğer systemd kullanıcı servislerinin de oturum kapalıyken çalışmasına izin verir. Artık istemiyorsan:

```bash
sudo loginctl disable-linger "$USER"
```

## Tarayıcıyı kapatırsam otomasyon çalışır mı?

Evet. Tarayıcı ve noVNC yalnızca XFCE ekranını görüntülemek/kontrol etmek için istemci görevi görür. Tarayıcı sekmesini kapatmak VNC bağlantısını keser; Xvfb, XFCE ve bu masaüstünde çalışan uygulamalar çalışmaya devam eder.

Ancak şu durumlarda masaüstü ve onun içindeki süreçler durur:

- `kayralrics stop` veya `systemctl --user stop kayralrics` çalıştırılırsa
- Bilgisayar kapanır veya yeniden başlarsa
- Servis durdurulursa ya da sanal masaüstü çökerse

Yeniden başlatma sonrasında GUI otomasyonunun da otomatik başlaması gerekiyorsa, otomasyon uygulamasını XFCE oturumunun otomatik başlatma listesine ekle veya onu ayrı bir systemd kullanıcı servisi olarak tanımla. Yalnızca tarayıcıdan açılmış bir web sayfasının çalışmasına güvenme.

Xvfb sanal ekrandır; fiziksel GPU/monitör oturumu değildir. GPU hızlandırması, donanım erişimi, DRM koruması, fiziksel USB aygıtı veya gerçek ekran gerektiren uygulamalar bu ortamda çalışmayabilir. Çalışma durumunu uygulama bazında test et.

## Ekran boyutu ve portlar

Varsayılanlar:

| Ayar | Değer |
|---|---|
| X11 ekranı | `:99` |
| Çözünürlük | `1600x900x24` |
| VNC | `127.0.0.1:5901` |
| noVNC | `127.0.0.1:1337` |

Değerleri değiştirmek için `~/.config/systemd/user/kayralrics.service` dosyasına `[Service]` altına `Environment=` satırları ekleyebilirsin. Örneğin:

```ini
Environment=KAYRALRICS_SCREEN=1920x1080x24
Environment=KAYRALRICS_WEB_PORT=1337
Environment=KAYRALRICS_VNC_PORT=5901
```

Ardından:

```bash
systemctl --user daemon-reload
systemctl --user restart kayralrics.service
```

## Güvenlik

Bu proje varsayılan olarak yerel bilgisayar kullanımı için yapılandırılmıştır.

- noVNC `127.0.0.1:1337` adresine bağlanır.
- x11vnc `-localhost` seçeneğiyle yalnızca loopback arayüzünde dinler.
- VNC bağlantısı parola ister.
- VNC parola dosyası `~/.vnc/passwd` konumunda ve `0600` izinleriyle saklanır.
- Xvfb, `~/.local/state/kayralrics/Xauthority` dosyasındaki X11 çereziyle korunur.
- Xvfb `-ac` ile erişim kontrolünü kapatmaz.
- Kurulum hiçbir güvenlik duvarı portunu açmaz.

**`127.0.0.1` ayarlarını `0.0.0.0` olarak değiştirme ve 1337/5901 portlarını yönlendirici üzerinden internete açma.** noVNC sayfası yerel bağlantıda HTTP kullanır; bu tasarım internet üzerinden güvenli uzaktan erişim sağlamak için hazırlanmadı. Uzak erişim gerekiyorsa ayrı bir VPN/SSH tüneli ve ilave güvenlik yapılandırması gerekir.

VNC'nin klasik parola mekanizması modern güçlü kimlik doğrulama yerine geçmez. Yerel bilgisayardaki diğer kullanıcılar ve kötü amaçlı yazılımlar için mutlak koruma sağlamaz. Güvenmediğin makinelerde kullanma.

## Sorun giderme

### Servis durumu

```bash
systemctl --user status kayralrics.service --no-pager -l
```

### Günlükler

```bash
journalctl --user -u kayralrics.service -n 100 --no-pager
```

Canlı izleme:

```bash
kayralrics logs
```

### Portlar

```bash
ss -ltnp | grep -E ':(1337|5901)\b'
```

İki port da `127.0.0.1` üzerinde LISTEN olmalıdır. `5901` yoksa VNC sunucusu başlamamıştır; servis günlüklerine bak. `1337` yoksa noVNC/websockify başlamamıştır.

### VNC parolasını yenileme

```bash
x11vnc -storepasswd
chmod 600 ~/.vnc/passwd
systemctl --user restart kayralrics.service
```

### X ekranı kullanımda hatası

`:99` başka bir X sunucusu tarafından kullanılıyor olabilir. Önce servisi durdur:

```bash
systemctl --user stop kayralrics.service
pgrep -af 'Xvfb :99'
```

Eski Xvfb süreci gerçekten çalışıyorsa onu kontrollü biçimde durdur. Başka bir uygulamaya ait X sunucusunun kilit veya soket dosyalarını gelişigüzel silme.

## GUI otomasyonunu XFCE açılışında başlatma

Tarayıcı sekmesi kapalıyken otomasyonun devam etmesi için otomasyon programı XFCE sanal oturumunda çalışıyor olmalıdır. Programı her XFCE oturumunda otomatik başlatmak için kullanıcı autostart dizinine bir `.desktop` dosyası ekle.

Örnek şablon (uygulama yolunu ve parametrelerini kendi programına göre değiştir):

```ini
[Desktop Entry]
Type=Application
Name=My Automation
Exec=/absolute/path/to/automation-program --your-options
Terminal=false
X-GNOME-Autostart-enabled=true
```

Dosyayı `~/.config/autostart/my-automation.desktop` konumuna kaydet. Uygulama grafik oturumu gerektiriyorsa XFCE içinde açıldığını ve noVNC bağlantısını kapattıktan sonra da çalıştığını doğrula. Otomasyon programının kendine ait oturum/hesap koşulları ve hata kurtarma davranışı ayrıca yapılandırılmalıdır.

## GitHub'a yayımlama

GitHub'da boş bir repository oluşturduktan sonra proje klasöründe: 

```bash
git init -b main
git add .
git commit -m "Initial Kayralrics web desktop setup"
git remote add origin https://github.com/USERNAME/kayralrics-web-desktop.git
git push -u origin main
```

`USERNAME` ve repository adını kendi GitHub bilgilerinle değiştir. `~/.vnc/passwd`, kişisel günlükler veya gerçek otomasyon kimlik bilgilerini repository'ye ekleme.

## Kaldırma

```bash
./uninstall.sh
```

Kaldırma betiği servisi devre dışı bırakır ve proje dosyalarını kaldırır. VNC parolasını, günlükleri ve Fedora paketlerini silmez. Bunları ayrıca silmek istersen:

```bash
rm -f ~/.vnc/passwd
rm -rf ~/.local/state/kayralrics
```

`loginctl` lingering ayarı başka kullanıcı servislerini de etkileyebileceğinden otomatik kaldırılmaz. Yalnızca artık kullanıcı servislerinin oturum kapalıyken çalışmasını istemiyorsan `sudo loginctl disable-linger "$USER"` kullan.

## Kaynaklar

- [Fedora: Xvfb paketi](https://packages.fedoraproject.org/pkgs/xorg-x11-server/xorg-x11-server-Xvfb/)
- [Fedora: x11vnc paketi](https://packages.fedoraproject.org/pkgs/x11vnc/x11vnc/)
- [Fedora: noVNC paketi](https://packages.fedoraproject.org/pkgs/novnc/novnc/)
- [Fedora: xorg-x11-xauth paketi](https://packages.fedoraproject.org/pkgs/xorg-x11-xauth/xorg-x11-xauth/)
- [Fedora: XFCE paketleri](https://packages.fedoraproject.org/pkgs/xfce4-session/xfce4-session/)
- [Fedora: xset paketi](https://packages.fedoraproject.org/pkgs/xset/xset/)
- [noVNC resmi deposu ve kullanım bilgisi](https://github.com/novnc/noVNC)
- [systemd loginctl: enable-linger](https://www.freedesktop.org/software/systemd/man/latest/loginctl.html)

## Lisans

MIT. Ayrıntılar için [LICENSE](LICENSE) dosyasına bak.
