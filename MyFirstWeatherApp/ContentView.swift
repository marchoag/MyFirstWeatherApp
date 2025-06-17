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
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            
            if isLoading {
                Text("Loading weather...")
            } else if let weather = weather {
                VStack {
                    Text(weather.name)
                        .font(.title)
                    Text(formatTemp(weather.main.temp))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(weather.weather.first?.description.capitalized ?? "")
                        .font(.headline)
                    Text("Humidity: \(weather.main.humidity)%")
                        .font(.subheadline)
                    
                    // 5-day forecast
                    if !forecast.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("5-Day Forecast")
                                .font(.headline)
                                .padding(.top)
                            
                            ForEach(forecast.indices, id: \.self) { index in
                                let dailyForecast = forecast[index]
                                HStack {
                                    Text(dayFormatter.string(from: dailyForecast.date))
                                        .frame(width: 60, alignment: .leading)
                                        .font(.subheadline)
                                    
                                    Text(dailyForecast.description)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .font(.subheadline)
                                    
                                    Text("\(Int(convertTemp(dailyForecast.lowTemp)))°/\(Int(convertTemp(dailyForecast.highTemp)))°")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                }
            } else {
                Text("MyFirstWeatherApp")
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Picker("Temperature Unit", selection: $selectedUnit) {
                ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            VStack {
                TextField("Enter city,country (e.g., Paris,FR)", text: $cityName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                VStack(spacing: 2) {
                    Text("International: Paris,FR • Tokyo,JP • London,GB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("US Cities: Springfield,MA,US • Springfield,IL,US • Austin,TX,US")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            Button("Get Weather") {
                Task {
                    await getWeather()
                }
            }
        }
        .padding()
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
                // Check for specific network errors
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .timedOut:
                        self.errorMessage = "No internet connection"
                    case .badServerResponse:
                        self.errorMessage = "City not found. Try format like Paris,FR"
                    default:
                        self.errorMessage = "Failed to load weather data"
                    }
                } else {
                    self.errorMessage = "Failed to load weather data"
                }
                self.isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
}
