//
//  WeatherModel.swift
//  MyFirstWeatherApp
//
//  Created by Marc Hoag on 6/16/25.
//

import Foundation

struct WeatherResponse: Codable {
    let main: Main
    let weather: [Weather]
    let name: String
}

struct Main: Codable {
    let temp: Double
    let humidity: Int
}

struct Weather: Codable {
    let main: String
    let description: String
}

// Forecast models
struct ForecastResponse: Codable {
    let list: [ForecastItem]
    let city: City
}

struct ForecastItem: Codable {
    let dt: Int
    let main: Main
    let weather: [Weather]
    let dt_txt: String
}

struct City: Codable {
    let name: String
}

struct DailyForecast {
    let date: Date
    let highTemp: Double
    let lowTemp: Double
    let condition: String
    let description: String
} 