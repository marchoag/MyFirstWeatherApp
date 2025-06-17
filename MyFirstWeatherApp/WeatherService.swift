//
//  WeatherService.swift
//  MyFirstWeatherApp
//
//  Created by Marc Hoag on 6/16/25.
//

import Foundation

enum WeatherError: Error {
    case invalidAPIKey
    case cityNotFound
    case serverError
    case dataParsingError
    case networkError
}

class WeatherService {
    static let shared = WeatherService()
    private init() {}
    
    func getWeather(for city: String, useFahrenheit: Bool = true) async throws -> WeatherResponse {
        let baseURL = "https://api.openweathermap.org/data/2.5/weather"
        let apiKey = Config.openWeatherMapAPIKey
        let units = "metric" // Always fetch in Celsius for consistent conversion
        
        print("API Key (first 8 chars): \(String(apiKey.prefix(8)))...")
        print("City: \(city)")
        
        // URL encode the city parameter to handle spaces and special characters
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?q=\(encodedCity)&appid=\(apiKey)&units=\(units)") else {
            print("URL creation failed")
            throw WeatherError.networkError
        }
        
        print("Request URL: \(url.absoluteString)")
        
        // Create URLRequest with timeout
        var request = URLRequest(url: url)
        request.timeoutInterval = 3.0 // 3 seconds timeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP status codes
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status Code: \(httpResponse.statusCode)")
            print("Response URL: \(httpResponse.url?.absoluteString ?? "No URL")")
            
            if httpResponse.statusCode == 401 {
                print("API Key Error: Invalid API key")
                throw WeatherError.invalidAPIKey
            } else if httpResponse.statusCode == 404 {
                print("City Not Found Error")
                throw WeatherError.cityNotFound
            } else if httpResponse.statusCode != 200 {
                print("HTTP Error: \(httpResponse.statusCode)")
                if let responseData = String(data: data, encoding: .utf8) {
                    print("Response: \(responseData)")
                }
                throw WeatherError.serverError
            }
        }
        
        do {
            let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
            return weatherResponse
        } catch {
            print("JSON Decode Error: \(error)")
            throw WeatherError.dataParsingError
        }
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
        var dailyForecasts: [Date: (highs: [Double], lows: [Double], conditions: [String], mainConditions: [String])] = [:]
        
        for item in forecastItems {
            let date = Date(timeIntervalSince1970: TimeInterval(item.dt))
            let dayStart = calendar.startOfDay(for: date)
            
            // Skip today, start from tomorrow
            if dayStart <= today { continue }
            
            if dailyForecasts[dayStart] == nil {
                dailyForecasts[dayStart] = (highs: [], lows: [], conditions: [], mainConditions: [])
            }
            
            dailyForecasts[dayStart]?.highs.append(item.main.temp)
            dailyForecasts[dayStart]?.lows.append(item.main.temp)
            if let weather = item.weather.first {
                dailyForecasts[dayStart]?.conditions.append(weather.description)
                dailyForecasts[dayStart]?.mainConditions.append(weather.main)
            }
        }
        
        // Convert to DailyForecast array and get first 5 days
        let sortedDays = dailyForecasts.keys.sorted().prefix(5)
        
        return sortedDays.compactMap { day in
            guard let data = dailyForecasts[day],
                  let high = data.highs.max(),
                  let low = data.lows.min(),
                  let condition = data.conditions.first,
                  let mainCondition = data.mainConditions.first else { return nil }
            
            return DailyForecast(
                date: day,
                highTemp: high,
                lowTemp: low,
                condition: condition,
                description: condition.capitalized,
                mainCondition: mainCondition
            )
        }
    }
} 