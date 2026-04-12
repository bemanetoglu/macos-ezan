import Foundation

// Models matching ezanvakti.emushaf.net
struct EmushafUlke: Codable {
    let UlkeAdi: String
    let UlkeAdiEn: String
    let UlkeID: String
}

struct EmushafSehir: Codable {
    let SehirAdi: String
    let SehirAdiEn: String
    let SehirID: String
}

struct EmushafIlce: Codable {
    let IlceAdi: String
    let IlceAdiEn: String
    let IlceID: String
}

struct EmushafVakit: Codable {
    let Imsak: String
    let Gunes: String
    let Ogle: String
    let Ikindi: String
    let Aksam: String
    let Yatsi: String
    let MiladiTarihKisa: String // "12.04.2026"
    let MiladiTarihKisaIso8601: String? // "12.04.2026"
}
