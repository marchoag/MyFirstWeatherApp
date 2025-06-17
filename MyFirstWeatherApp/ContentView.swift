//
//  ContentView.swift
//  MyFirstWeatherApp
//
//  Created by Marc Hoag on 6/16/25.
//

import SwiftUI

enum TemperatureUnit: String, CaseIterable {
    case fahrenheit = "°F"
    case celsius = "°C"
}

struct ContentView: View {
    @State private var isLoading = false
    @State private var weather: WeatherResponse?
    @State private var forecast: [DailyForecast] = []
    @State private var errorMessage: String?
    @State private var cityName = ""
    @State private var selectedUnit = TemperatureUnit.fahrenheit
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerView
                    
                    // Search Section
                    searchSection
                    
                    // Main Weather Card
                    if isLoading {
                        loadingView
                    } else if let weather = weather {
                        currentWeatherCard(weather: weather)
                        
                        // Forecast Section
                        if !forecast.isEmpty {
                            forecastSection
                        }
                    } else {
                        welcomeView
                    }
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        errorView(message: errorMessage)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Weather")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue, .orange)
                .symbolRenderingMode(.palette)
            
            Text("Weather Forecast")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.top, 20)
    }
    
    private var searchSection: some View {
        VStack(spacing: 16) {
            // Temperature Unit Selector
            Picker("Temperature Unit", selection: $selectedUnit) {
                ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Search Card
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search for a city", text: $cityName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await getWeather() }
                        }
                    
                    if !cityName.isEmpty {
                        Button {
                            cityName = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("International: Paris,FR • Tokyo,JP • London,GB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("US Cities: Springfield,MA,US • Austin,TX,US")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                Button {
                    Task { await getWeather() }
                } label: {
                    HStack {
                        Image(systemName: "location.circle.fill")
                        Text("Get Weather")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(cityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading weather...")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func currentWeatherCard(weather: WeatherResponse) -> some View {
        VStack(spacing: 20) {
            // Location
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                Text(weather.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Main Temperature
            VStack(spacing: 8) {
                Text(formatTemp(weather.main.temp))
                    .font(.system(size: 72, weight: .thin, design: .default))
                    .foregroundColor(.primary)
                
                Text(weather.weather.first?.description.capitalized ?? "")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // Weather Details
            HStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "humidity.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("\(weather.main.humidity)%")
                        .font(.headline)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 8) {
                    Image(systemName: "thermometer.medium")
                        .foregroundColor(.orange)
                        .font(.title3)
                    Text(formatTemp(weather.main.temp))
                        .font(.headline)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 8) {
                    Image(systemName: weatherIcon(for: weather.weather.first?.main ?? ""))
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text(weather.weather.first?.main ?? "")
                        .font(.headline)
                }
            }
        }
        .padding(24)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
    
    private var forecastSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("5-Day Forecast")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                ForEach(forecast.indices, id: \.self) { index in
                    let dailyForecast = forecast[index]
                    forecastRow(dailyForecast, isLast: index == forecast.count - 1)
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
    
    private func forecastRow(_ dailyForecast: DailyForecast, isLast: Bool) -> some View {
        HStack(alignment: .center, spacing: 16) {
            // Day
            Text(dayFormatter.string(from: dailyForecast.date))
                .font(.body)
                .fontWeight(.medium)
                .frame(width: 50, alignment: .leading)
            
            // Weather Icon
            Image(systemName: weatherIcon(for: dailyForecast.mainCondition))
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 30)
            
            // Description
            Text(dailyForecast.description)
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Temperature Range
            HStack(spacing: 8) {
                Text("\(Int(convertTemp(dailyForecast.lowTemp)))°")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("\(Int(convertTemp(dailyForecast.highTemp)))°")
                    .font(.body)
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .overlay(
            Rectangle()
                .frame(height: isLast ? 0 : 0.5)
                .foregroundColor(Color(.separator))
                .padding(.leading, 20),
            alignment: .bottom
        )
    }
    
    private var welcomeView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Welcome to Weather")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Search for a city to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func errorView(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(message)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemYellow).opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemYellow), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helper Functions
    
    private func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case "clear": return "sun.max.fill"
        case "clouds": return "cloud.fill"
        case "rain": return "cloud.rain.fill"
        case "snow": return "cloud.snow.fill"
        case "thunderstorm": return "cloud.bolt.fill"
        case "drizzle": return "cloud.drizzle.fill"
        case "mist", "fog": return "cloud.fog.fill"
        default: return "cloud.sun.fill"
        }
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }
    
    private func convertTemp(_ celsius: Double) -> Double {
        return selectedUnit == .fahrenheit ? (celsius * 9/5) + 32 : celsius
    }
    
    private func formatTemp(_ celsius: Double) -> String {
        return "\(Int(convertTemp(celsius)))\(selectedUnit.rawValue)"
    }
    
    private func getWeather() async {
        let city = cityName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !city.isEmpty else {
            errorMessage = "Please enter a city name"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let weatherData = try await WeatherService.shared.getWeather(for: city)
            let forecastData = try await WeatherService.shared.getForecast(for: city)
            await MainActor.run {
                self.weather = weatherData
                self.forecast = forecastData
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                print("Error caught: \(error)")
                
                // Check for specific weather errors
                if let weatherError = error as? WeatherError {
                    switch weatherError {
                    case .invalidAPIKey:
                        self.errorMessage = "Invalid API key. Check Config.swift"
                    case .cityNotFound:
                        self.errorMessage = "City not found. Try format like Paris,FR"
                    case .serverError:
                        self.errorMessage = "Server error. Try again later"
                    case .dataParsingError:
                        self.errorMessage = "Data parsing error"
                    case .networkError:
                        self.errorMessage = "Network error"
                    }
                } else if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .timedOut:
                        self.errorMessage = "No internet connection"
                    default:
                        self.errorMessage = "Network error: \(urlError.localizedDescription)"
                    }
                } else {
                    self.errorMessage = "Unknown error: \(error.localizedDescription)"
                }
                self.isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
}
