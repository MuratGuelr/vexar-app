# 🚀 Vexar for macOS

> **Discord erişim engellerini aşmak için tasarlanmış, modern ve kullanımı kolay menü çubuğu asistanı.**

[![Platform](https://img.shields.io/badge/Platform-macOS%2012%2B-blue.svg)](https://www.apple.com/macos)
[![Architecture](https://img.shields.io/badge/Architecture-Intel%20%7C%20Apple%20Silicon-green.svg)](https://www.apple.com/mac)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📋 İçindekiler

- [Özellikler](#-özellikler)
- [Nasıl Çalışır](#-nasıl-çalışır)
- [Sistem Gereksinimleri](#-sistem-gereksinimleri)
- [Kurulum](#-kurulum)
- [Kullanım](#-kullanım)
- [Geliştirici](#-geliştirici)
- [Destek](#-destek)
- [Sorumluluk Reddi](#-sorumluluk-reddi)

---

## ✨ Özellikler

Vexar, karmaşık terminal komutlarıyla uğraşmadan Discord'u güvenli bir şekilde kullanmanızı sağlayan native bir macOS uygulamasıdır.

### 🎯 Temel Özellikler

- **Menü Çubuğu Entegrasyonu**: Her zaman elinizin altında, sistem kaynaklarını yormayan hafif tasarım.
- **Tek Tıkla Bağlantı**: "Bağlan" butonuna tıklayarak Discord'u proxy modunda başlatın.
- **Otomatik Bağımlılık Yönetimi**: Homebrew ve SpoofDPI kurulu değilse sizin yerinize kurar ve yapılandırır.
- **Akıllı Süreç Yönetimi**: Discord zaten açıksa otomatik olarak kapatıp proxy ile yeniden başlatır.
- **Sistem Durumu İzleme**: Bağlantı durumunu ve arka plan servislerini anlık olarak takip eder.

### 🎨 Modern Arayüz

- **Premium Tasarım**: Glassmorphism efektleri ve akıcı animasyonlar.
- **Karanlık Mod**: Göz yormayan, işletim sistemiyle uyumlu koyu tema.
- **Canlı Loglar**: İşlemleri detaylıca görebileceğiniz entegre log görüntüleyici.

---

## 🔧 Nasıl Çalışır?

Vexar, arka planda güvenilir araçları kullanarak Discord trafiğini optimize eder:

1. **Proxy Servisi**: `spoofdpi` aracını yerel bir portta (örn. 8080) çalıştırır.
2. **Discord Başlatma**: Resmi Discord uygulamasını `--proxy-server="http://127.0.0.1:PORT"` parametresiyle başlatır.
3. **Otomasyon**: Tüm bu süreci tek bir butona indirger ve karmaşık terminal işlemlerini ortadan kaldırır.

---

## 💻 Sistem Gereksinimleri

- **İşletim Sistemi**: macOS 12 (Monterey) veya üstü
- **Mimar**: Intel (x86_64) veya Apple Silicon (M1/M2/M3/M4)
- **Discord**: `/Applications/Discord.app` konumunda kurulu olmalıdır.
- **İnternet**: İlk kurulumda Homebrew ve SpoofDPI indirmek için gereklidir.

---

## 🚀 Kurulum

1. **İndirin**: Projenin [Releases](https://github.com/MuratGuelr/vexar-app/releases) sayfasından son sürümü indirin.
2. **Uygulamayı Taşıyın**: `Vexar.app` dosyasını `Uygulamalar` klasörüne sürükleyin.
3. **İlk Açılış**: Uygulamayı açın. İlk açılışta gerekli izinleri isteyecektir.
   - *Not: Eğer Homebrew veya SpoofDPI sisteminizde yoksa, Vexar bunları kurmak için sizden onay isteyecek ve kurulumu Terminal üzerinden şeffaf bir şekilde yapacaktır.*

---

## 🎮 Kullanım

1. Menü çubuğundaki **Vexar** ikonuna tıklayın.
2. Açılan pencerede **"BAĞLAN"** butonuna basın.
3. Vexar şunları yapacaktır:
   - Gerekirse arka plandaki servisleri başlatacak.
   - Açık olan Discord uygulamasını kapatacak.
   - Discord'u proxy ayarlarıyla yeniden açacak.
4. Bağlantıyı kesmek ve Discord'u normal moda döndürmek için tekrar **"BAĞLANTIYI KES"** butonuna basmanız yeterlidir.

---

## 🛠 Geliştirme

Projeyi yerel ortamınızda geliştirmek için:

```bash
git clone https://github.com/MuratGuelr/vexar-app.git
cd vexar-app
open Vexar.xcodeproj
```

Xcode üzerinden projeyi build edip çalıştırabilirsiniz.

---

## � Destek

Bu proje açık kaynaklıdır ve topluluk desteğiyle geliştirilmektedir. Destek olmak isterseniz:

**GitHub Sponsor:**

[![Sponsor](https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86)](https://github.com/sponsors/MuratGuelr)

**Patreon:**

[![Patreon](https://img.shields.io/badge/MuratGuelr-purple?logo=patreon&label=Patreon)](https://www.patreon.com/posts/splitwire-for-v1-140359525)

---

## 📄 Lisans

```
Copyright © 2025 ConsolAktif

MIT License ile lisanslanmıştır.
Detaylar için LICENSE dosyasına bakın.
```

---

## ⚖️ Sorumluluk Reddi

> [!IMPORTANT]
> **Bu yazılım eğitim ve erişilebilirlik amaçlı oluşturulmuştur.**

- ✅ Kodlama eğitimi ve kişisel kullanım için tasarlanmıştır.
- ❌ Ticari kullanım garantisi verilmez.
- ⚠️ Geliştirici, kullanımdan doğabilecek zararlardan sorumlu değildir.
- 📚 Kullanıcılar bu yazılımı kendi sorumlulukları altında kullanırlar.
- ⚖️ Bu araç sadece DPI kısıtlamalarını aşmak için yerel bir proxy oluşturur; verilerinizi kaydetmez veya izlemez.

**Yasal Uyarı:** Bu programın kullanımından doğan her türlü yasal sorumluluk kullanıcıya aittir. Uygulama yalnızca eğitim ve araştırma amaçları ile geliştirilmiştir.

---

<div align="center">

**🚀 Vexar ile kesintisiz iletişim.**

Made with ❤️ by [ConsolAktif](https://github.com/MuratGuelr)

</div>
