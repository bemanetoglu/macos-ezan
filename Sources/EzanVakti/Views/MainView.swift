import SwiftUI
import CoreLocation

struct MainView: View {
    @ObservedObject var viewModel: AppViewModel
    @StateObject var locationManager = LocationManager()
    @State private var showLocationEditor = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
            
            if !viewModel.isOnboardingCompleted {
                onboardingView
            } else {
                locationHeader
                
                if showLocationEditor {
                    locationForm
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                }
                
                Divider()
                
                prayerListView
                
                Divider()
                
                settingsView
            }
        }
        .frame(width: 320)
        .padding(.vertical, 8)
        .onAppear {
            Task {
                await viewModel.initialFetch()
            }
        }
        .onChange(of: locationManager.updateTrigger) { _ in
            if let loc = locationManager.location {
                Task {
                    await viewModel.autoFindLocation(lat: loc.latitude, lon: loc.longitude)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Image(systemName: "moon.stars.fill")
                .foregroundColor(.yellow)
                .font(.title2)
            Text("Ezan Vakti")
                .font(.headline)
        }
        .padding(.bottom, 8)
    }

    private var onboardingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe.europe.africa.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .padding(.top, 16)

            Text("Welcome Title")
                .font(.title3)
                .bold()

            Text("Welcome Description")
                .font(.caption)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)

            locationForm

            Button(action: {
                withAnimation {
                    viewModel.isOnboardingCompleted = true
                }
            }) {
                Text("Save and Start")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(BorderedProminentButtonStyle())
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }
    
    private var locationHeader: some View {
        HStack {
            Image(systemName: "mappin.and.ellipse")
                .foregroundColor(.red)
            VStack(alignment: .leading) {
                Text(viewModel.selectedLocationName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            Spacer()
            Button(action: {
                withAnimation {
                    showLocationEditor.toggle()
                }
            }) {
                Image(systemName: showLocationEditor ? "chevron.up.circle.fill" : "pencil.circle.fill")
                    .foregroundColor(showLocationEditor ? .secondary : .blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    private var locationForm: some View {
        VStack(spacing: 8) {
            HStack {
                Picker("Country", selection: $viewModel.selectedUlkeID) {
                    ForEach(viewModel.ulkeler) { ulke in
                        Text(ulke.UlkeAdi).tag(ulke.UlkeID)
                    }
                }
                .disabled(viewModel.ulkeler.isEmpty)
                .onChange(of: viewModel.selectedUlkeID) { _ in
                    Task { await viewModel.handleUlkeChange() }
                }

                Picker("City", selection: $viewModel.selectedSehirID) {
                    ForEach(viewModel.sehirler) { sehir in
                        Text(sehir.SehirAdi).tag(sehir.SehirID)
                    }
                }
                .disabled(viewModel.sehirler.isEmpty)
                .onChange(of: viewModel.selectedSehirID) { _ in
                    Task { await viewModel.handleSehirChange() }
                }
            }
            .padding(.horizontal)

            HStack {
                Picker("District", selection: $viewModel.selectedIlceID) {
                    ForEach(viewModel.ilceler) { ilce in
                        Text(ilce.IlceAdi).tag(ilce.IlceID)
                    }
                }
                .disabled(viewModel.ilceler.isEmpty)
                .onChange(of: viewModel.selectedIlceID) { _ in
                    viewModel.fetchTimes()
                }

                Button(action: {
                    locationManager.requestLocation()
                }) {
                    HStack {
                        if locationManager.isRequestingLocation {
                            ProgressView().scaleEffect(0.5).frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "location.fill")
                        }
                        Text("Location")
                    }
                }
                .frame(width: 90)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var prayerListView: some View {
        VStack(spacing: 4) {
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            } else if let timings = viewModel.timings {
                PrayerRow(title: PrayerType.imsak.displayName, time: timings.imsak, isNext: viewModel.nextPrayerType == .imsak)
                PrayerRow(title: PrayerType.sunrise.displayName, time: timings.sunrise, isNext: viewModel.nextPrayerType == .sunrise)
                PrayerRow(title: PrayerType.dhuhr.displayName, time: timings.dhuhr, isNext: viewModel.nextPrayerType == .dhuhr)
                PrayerRow(title: PrayerType.asr.displayName, time: timings.asr, isNext: viewModel.nextPrayerType == .asr)
                PrayerRow(title: PrayerType.maghrib.displayName, time: timings.maghrib, isNext: viewModel.nextPrayerType == .maghrib)
                PrayerRow(title: PrayerType.isha.displayName, time: timings.isha, isNext: viewModel.nextPrayerType == .isha)
            } else {
                Text("Times could not be loaded")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding(.vertical, 8)
    }
    
    private var settingsView: some View {
        VStack(spacing: 8) {
            Toggle("Launch at Startup", isOn: $viewModel.launchAtStartup)
                .padding(.horizontal)

            Toggle("Enable Notifications", isOn: $viewModel.enableNotifications)
                .padding(.horizontal)

            Picker("Widget Style", selection: $viewModel.widgetStyle) {
                ForEach(WidgetStyle.allCases) { style in
                    Text(style.displayName).tag(style)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal)

            Button("Exit") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.top, 4)
        }
        .padding(.top, 8)
    }
}

struct PrayerRow: View {
    let title: String
    let time: String
    let isNext: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(isNext ? .bold : .regular)
            Spacer()
            Text(time)
                .fontWeight(isNext ? .bold : .regular)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(isNext ? Color.green.opacity(0.2) : Color.clear)
        .cornerRadius(6)
        .padding(.horizontal, 8)
    }
}
