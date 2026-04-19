import Foundation
import Combine
import ServiceManagement

enum WidgetStyle: String, CaseIterable, Identifiable {
    case nameAndTime = "Name and Time"
    case countdown = "Countdown"
    case iconOnly = "Icon Only"

    var id: String { self.rawValue }

    var displayName: String {
        NSLocalizedString(rawValue, comment: "")
    }
}

struct PrayerMoment {
    let type: PrayerType
    let date: Date
}

class AppViewModel: ObservableObject {
    @Published var timings: PrayerTimings?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var ulkeler: [EmushafUlke] = []
    @Published var sehirler: [EmushafSehir] = []
    @Published var ilceler: [EmushafIlce] = []
    
    @Published var isOnboardingCompleted: Bool {
        didSet { UserDefaults.standard.set(isOnboardingCompleted, forKey: "isOnboardingCompleted") }
    }
    
    var isAutoUpdatingLocation = false
    
    @Published var selectedUlkeID: String {
        didSet { UserDefaults.standard.set(selectedUlkeID, forKey: "ulkeID") }
    }
    @Published var selectedSehirID: String {
        didSet { UserDefaults.standard.set(selectedSehirID, forKey: "sehirID") }
    }
    @Published var selectedIlceID: String {
        didSet { UserDefaults.standard.set(selectedIlceID, forKey: "ilceID") }
    }
    
    @Published var widgetStyle: WidgetStyle {
        didSet { UserDefaults.standard.set(widgetStyle.rawValue, forKey: "widgetStyle"); updateWidgetText() }
    }
    
    @Published var enableNotifications: Bool {
        didSet {
            UserDefaults.standard.set(enableNotifications, forKey: "enableNotifications")
            if enableNotifications {
                Task {
                    let granted = await NotificationManager.shared.requestAuthorization()
                    if granted {
                        await MainActor.run {
                            scheduleNotifications()
                        }
                    }
                }
            } else {
                NotificationManager.shared.removeAllScheduledNotifications()
            }
        }
    }
    
    @Published var launchAtStartup: Bool {
        didSet {
            do {
                if launchAtStartup {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Başlangıç ayarı değiştirilemedi: \(error.localizedDescription)")
            }
        }
    }
    
    @Published var menuBarText: String = ""
    @Published var nextPrayerType: PrayerType?
    
    private var timer: AnyCancellable?
    private var prayerDates: [PrayerMoment] = []
    
    init() {
        self.selectedUlkeID = UserDefaults.standard.string(forKey: "ulkeID") ?? "2" // Turkey
        self.selectedSehirID = UserDefaults.standard.string(forKey: "sehirID") ?? "539" // Istanbul
        self.selectedIlceID = UserDefaults.standard.string(forKey: "ilceID") ?? "9541" // Istanbul-merkez
        
        if let savedStyleRaw = UserDefaults.standard.string(forKey: "widgetStyle"),
           let savedStyle = WidgetStyle(rawValue: savedStyleRaw) {
            self.widgetStyle = savedStyle
        } else {
            self.widgetStyle = .countdown
        }
        
        self.enableNotifications = UserDefaults.standard.bool(forKey: "enableNotifications")

        // Check notification authorization status on launch
        if self.enableNotifications {
            NotificationManager.shared.checkAuthorizationStatus()
        }
        
        self.isOnboardingCompleted = UserDefaults.standard.bool(forKey: "isOnboardingCompleted")
        self.launchAtStartup = SMAppService.mainApp.status == .enabled
        
        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.updateWidgetText()
        }
    }
    
    var selectedLocationName: String {
        let u = ulkeler.first { $0.UlkeID == selectedUlkeID }?.UlkeAdi ?? ""
        let s = sehirler.first { $0.SehirID == selectedSehirID }?.SehirAdi ?? ""
        let i = ilceler.first { $0.IlceID == selectedIlceID }?.IlceAdi ?? ""

        if !i.isEmpty && !s.isEmpty {
            return "\(i), \(s)"
        } else if !s.isEmpty {
            return "\(s), \(u)"
        }
        return "Location Not Selected"
    }
    
    @MainActor
    func initialFetch() async {
        isLoading = true
        do {
            ulkeler = try await APIService.shared.getUlkeler()
            sehirler = try await APIService.shared.getSehirler(ulkeID: selectedUlkeID)
            ilceler = try await APIService.shared.getIlceler(sehirID: selectedSehirID)
            fetchTimes()
        } catch {
            errorMessage = NSLocalizedString("Countries could not be loaded", comment: "")
        }
        isLoading = false
    }
    
    @MainActor
    func handleUlkeChange() async {
        guard !isAutoUpdatingLocation else { return }
        do {
            let s = try await APIService.shared.getSehirler(ulkeID: selectedUlkeID)
            self.sehirler = s
            if let first = s.first {
                self.selectedSehirID = first.SehirID
                await handleSehirChange()
            }
        } catch { print("Sehirler hata") }
    }
    
    @MainActor
    func handleSehirChange() async {
        guard !isAutoUpdatingLocation else { return }
        do {
            let i = try await APIService.shared.getIlceler(sehirID: selectedSehirID)
            self.ilceler = i
            if let first = i.first {
                self.selectedIlceID = first.IlceID
                fetchTimes()
            }
        } catch { print("Ilceler hata") }
    }
    
    func fetchTimes() {
        guard !selectedIlceID.isEmpty else { return }
        Task { @MainActor in
            isLoading = true
            errorMessage = nil
            do {
                timings = try await APIService.shared.fetchPrayerTimes(ilceID: selectedIlceID)
                parseDates()
                scheduleNotifications()
                updateWidgetText()
            } catch {
                errorMessage = NSLocalizedString("Times could not be loaded", comment: "")
            }
            isLoading = false
        }
    }
    
    @MainActor
    func autoFindLocation(lat: Double, lon: Double) async {
        isLoading = true
        isAutoUpdatingLocation = true
        do {
            if let result = try await APIService.shared.findLocationByCoordinates(latitude: lat, longitude: lon) {
                // Populate arrays before setting selections
                let sehirlerResponse = try await APIService.shared.getSehirler(ulkeID: result.ulkeID)
                let ilcelerResponse = try await APIService.shared.getIlceler(sehirID: result.sehirID)

                self.sehirler = sehirlerResponse
                self.ilceler = ilcelerResponse

                self.selectedUlkeID = result.ulkeID
                self.selectedSehirID = result.sehirID
                self.selectedIlceID = result.ilceID

                fetchTimes()
            } else {
                errorMessage = NSLocalizedString("Location could not be found", comment: "")
            }
        } catch {
            errorMessage = NSLocalizedString("Location finding error", comment: "")
        }
        isAutoUpdatingLocation = false
        isLoading = false
    }
    
    private func parseDates() {
        guard let timings = timings else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let calendar = Calendar.current
        let now = Date()
        
        prayerDates = []
        let typeStrings: [(PrayerType, String)] = [
            (.imsak, timings.imsak),
            (.sunrise, timings.sunrise),
            (.dhuhr, timings.dhuhr),
            (.asr, timings.asr),
            (.maghrib, timings.maghrib),
            (.isha, timings.isha)
        ]
        
        for (type, timeString) in typeStrings {
            if let timeDate = formatter.date(from: timeString) {
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute
                
                if let finalDate = calendar.date(from: components) {
                    prayerDates.append(PrayerMoment(type: type, date: finalDate))
                }
            }
        }
        
        prayerDates.sort { $0.date < $1.date }
    }
    
    private func scheduleNotifications() {
        guard enableNotifications else {
            print("Notifications are disabled, skipping schedule")
            return
        }
        NotificationManager.shared.removeAllScheduledNotifications()
        let now = Date()
        var scheduledCount = 0
        for moment in prayerDates {
            if moment.date > now {
                NotificationManager.shared.scheduleNotification(for: moment.type, at: moment.date)
                scheduledCount += 1
            }
        }
        print("Scheduled \(scheduledCount) notifications")
    }
    
    private func updateWidgetText() {
        guard let _ = timings, !prayerDates.isEmpty else {
            menuBarText = ""
            return
        }
        
        let now = Date()
        
        var nextPrayer: PrayerMoment? = nil
        for moment in prayerDates {
            if moment.date > now {
                nextPrayer = moment
                break
            }
        }
        
        if nextPrayer == nil {
            if let imsakDate = prayerDates.first?.date,
               let tomorrowImsak = Calendar.current.date(byAdding: .day, value: 1, to: imsakDate) {
                nextPrayer = PrayerMoment(type: .imsak, date: tomorrowImsak)
            }
        }
        
        guard let next = nextPrayer else {
            menuBarText = ""
            return
        }
        
        self.nextPrayerType = next.type
        
        switch widgetStyle {
        case .nameAndTime:
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            menuBarText = "\(next.type.displayName) \(formatter.string(from: next.date))"

        case .countdown:
            let diff = Calendar.current.dateComponents([.hour, .minute, .second], from: now, to: next.date)
            let h = String(format: "%02d", max(diff.hour ?? 0, 0))
            let m = String(format: "%02d", max(diff.minute ?? 0, 0))
            let s = String(format: "%02d", max(diff.second ?? 0, 0))
            if h == "00" {
                menuBarText = "\(next.type.displayName) \(m):\(s)"
            } else {
                menuBarText = "\(next.type.displayName) \(h):\(m):\(s)"
            }
        case .iconOnly:
            menuBarText = ""
        }
    }
}
// Required for Picker
extension EmushafUlke: Identifiable, Hashable {
    var id: String { UlkeID }
    static func == (lhs: EmushafUlke, rhs: EmushafUlke) -> Bool { lhs.UlkeID == rhs.UlkeID }
    func hash(into hasher: inout Hasher) { hasher.combine(UlkeID) }
}
extension EmushafSehir: Identifiable, Hashable {
    var id: String { SehirID }
    static func == (lhs: EmushafSehir, rhs: EmushafSehir) -> Bool { lhs.SehirID == rhs.SehirID }
    func hash(into hasher: inout Hasher) { hasher.combine(SehirID) }
}
extension EmushafIlce: Identifiable, Hashable {
    var id: String { IlceID }
    static func == (lhs: EmushafIlce, rhs: EmushafIlce) -> Bool { lhs.IlceID == rhs.IlceID }
    func hash(into hasher: inout Hasher) { hasher.combine(IlceID) }
}
