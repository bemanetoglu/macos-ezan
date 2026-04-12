import Foundation

struct PrayerAPIResponse: Codable {
    let code: Int
    let status: String
    let data: PrayerData
}

struct PrayerData: Codable {
    let timings: PrayerTimings
    let date: PrayerDate
}

struct PrayerTimings: Codable {
    let imsak: String
    let fajr: String
    let sunrise: String
    let dhuhr: String
    let asr: String
    let sunset: String
    let maghrib: String
    let isha: String
    let midnight: String
    
    enum CodingKeys: String, CodingKey {
        case imsak = "Imsak"
        case fajr = "Fajr"
        case sunrise = "Sunrise"
        case dhuhr = "Dhuhr"
        case asr = "Asr"
        case sunset = "Sunset"
        case maghrib = "Maghrib"
        case isha = "Isha"
        case midnight = "Midnight"
    }
}

struct PrayerDate: Codable {
    let readable: String
    let gregorian: GregorianDate
}

struct GregorianDate: Codable {
    let date: String
    let format: String
    let day: String
}

enum PrayerType: String, CaseIterable, Identifiable {
    case imsak = "İmsak"
    case sunrise = "Güneş"
    case dhuhr = "Öğle"
    case asr = "İkindi"
    case maghrib = "Akşam"
    case isha = "Yatsı"
    
    var id: String { self.rawValue }
    
    var apiKey: String {
        switch self {
        case .imsak: return "Imsak"
        case .sunrise: return "Sunrise"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }
}
