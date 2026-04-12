import Foundation
import CoreLocation

class APIService {
    static let shared = APIService()
    private let baseURL = "https://ezanvakti.emushaf.net"
    
    func getUlkeler() async throws -> [EmushafUlke] {
        let url = URL(string: "\(baseURL)/ulkeler")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([EmushafUlke].self, from: data)
    }
    
    func getSehirler(ulkeID: String) async throws -> [EmushafSehir] {
        let url = URL(string: "\(baseURL)/sehirler/\(ulkeID)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([EmushafSehir].self, from: data)
    }
    
    func getIlceler(sehirID: String) async throws -> [EmushafIlce] {
        let url = URL(string: "\(baseURL)/ilceler/\(sehirID)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([EmushafIlce].self, from: data)
    }
    
    func fetchPrayerTimes(ilceID: String) async throws -> PrayerTimings {
        let url = URL(string: "\(baseURL)/vakitler/\(ilceID)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let vakitler = try JSONDecoder().decode([EmushafVakit].self, from: data)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let todayStr = formatter.string(from: Date())
        
        guard let todaysVakit = vakitler.first(where: { $0.MiladiTarihKisa == todayStr }) ?? vakitler.first else {
            throw URLError(.badServerResponse)
        }
        
        return PrayerTimings(
            imsak: todaysVakit.Imsak,
            fajr: "", // Will be ignored by ui
            sunrise: todaysVakit.Gunes,
            dhuhr: todaysVakit.Ogle,
            asr: todaysVakit.Ikindi,
            sunset: todaysVakit.Aksam,
            maghrib: todaysVakit.Aksam,
            isha: todaysVakit.Yatsi,
            midnight: "00:00"
        )
    }
    
    func findLocationByCoordinates(latitude: Double, longitude: Double) async throws -> (ulkeID: String, sehirID: String, ilceID: String)? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        let country = placemarks.first?.country ?? "Turkey"
        let city = placemarks.first?.administrativeArea ?? placemarks.first?.locality ?? "Istanbul"
        let district = placemarks.first?.subLocality ?? placemarks.first?.locality ?? city
        
        // Very basic matching for auto location
        let ulkeler = try await getUlkeler()
        let cSearch = normalized(country)
        guard let u = ulkeler.first(where: { normalized($0.UlkeAdiEn) == cSearch || normalized($0.UlkeAdi) == cSearch }) else { return nil }
        
        let sehirler = try await getSehirler(ulkeID: u.UlkeID)
        let sSearch = normalized(city)
        guard let s = sehirler.first(where: { normalized($0.SehirAdiEn).contains(sSearch) || normalized($0.SehirAdi).contains(sSearch) }) else { return nil }
        
        let ilceler = try await getIlceler(sehirID: s.SehirID)
        let iSearch = normalized(district)
        let fallbackSearch = normalized(city)
        
        let matchedIlce: EmushafIlce
        if let match = ilceler.first(where: { normalized($0.IlceAdiEn).contains(iSearch) || normalized($0.IlceAdi).contains(iSearch) }) {
            matchedIlce = match
        } else if let fallback = ilceler.first(where: { normalized($0.IlceAdiEn) == fallbackSearch || normalized($0.IlceAdi) == fallbackSearch }) {
            matchedIlce = fallback
        } else if let firstIlce = ilceler.first {
            matchedIlce = firstIlce
        } else {
            return nil
        }
        
        return (u.UlkeID, s.SehirID, matchedIlce.IlceID)
    }
    
    private func normalized(_ text: String) -> String {
        return text.folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "İ", with: "I")
            .uppercased()
    }
}
