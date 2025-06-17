//
//  WeatherService.swift
//  MyFirstWeatherApp
//
//  Created by Marc Hoag on 6/16/25.
//

import Foundation

class WeatherService {
    static let shared = WeatherService()
    private init() {}
    
    func getWeather(for city: String, useFahrenheit: Bool = true) async throws -> WeatherResponse {
        let baseURL = "https://api.openweathermap.org/data/2.5/weather"
        let apiKey = Config.openWeatherMapAPIKey
        let units = "metric" // Always fetch in Celsius for consistent conversion
        
        // URL encode the city parameter to handle spaces and special characters
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?q=\(encodedCity)&appid=\(apiKey)&units=\(units)") else {
            throw URLError(.badURL)
        }
        
        // Create URLRequest with timeout
        var request = URLRequest(url: url)
        request.timeoutInterval = 3.0 // 3 seconds timeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP status codes
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 404 {
                throw URLError(.badServerResponse)
            } else if httpResponse.statusCode != 200 {
                throw URLError(.badServerResponse)
            }
        }
        
        let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
        return weatherResponse
    }
    
    func getForecast(for city: String, useFahrenheit: Bool = true) async throws -> [DailyForecast] {
        let baseURL = "https://api.openweathermap.org/data/2.5/forecast"
        let apiKey = Config.openWeatherMapAPIKey
        let units = "metric" // Always fetch in Celsius for consistent conversion
        
        // URL encode the city parameter
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?q=\(encodedCity)&appid=\(apiKey)&units=\(units)") else {
            throw URLError(.badURL)
        }
        
        // Create URLRequest with timeout
        var request = URLRequest(url: url)
        request.timeoutInterval = 3.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP status codes
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 404 {
                throw URLError(.badServerResponse)
            } else if httpResponse.statusCode != 200 {
                throw URLError(.badServerResponse)
            }
        }
        
        let forecastResponse = try JSONDecoder().decode(ForecastResponse.self, from: data)
        return processForecastData(forecastResponse.list)
    }
    
    private func processForecastData(_ forecastItems: [ForecastItem]) -> [DailyForecast] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Group forecast items by day
        var dailyForecasts: [Date: (highs: [Double], lows: [Double], conditions: [String])] = [:]
        
        for item in forecastItems {
            let date = Date(timeIntervalSince1970: TimeInterval(item.dt))
            let dayStart = calendar.startOfDay(for: date)
            
            // Skip today, start from tomorrow
            if dayStart <= today { continue }
            
            if dailyForecasts[dayStart] == nil {
                dailyForecasts[dayStart] = (highs: [], lows: [], conditions: [])
            }
            
            dailyForecasts[dayStart]?.highs.append(item.main.temp)
            dailyForecasts[dayStart]?.lows.append(item.main.temp)
            if let weather = item.weather.first {
                dailyForecasts[dayStart]?.conditions.append(weather.description)
            }
        }
        
        // Convert to DailyForecast array and get first 5 days
        let sortedDays = dailyForecasts.keys.sorted().prefix(5)
        
        return sortedDays.compactMap { day in
            guard let data = dailyForecasts[day],
                  let high = data.highs.max(),
                  let low = data.lows.min(),
                  let condition = data.conditions.first else { return nil }
            
            return DailyForecast(
                date: day,
                highTemp: high,
                lowTemp: low,
                condition: condition,
                description: condition.capitalized
            )
        }
    }
} 