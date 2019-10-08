//
//  Helpers.swift
//  Space-Time-Maps
//
//  Created by Vicky on 13/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation
import UIKit.UIColor

class Utils {
    
    private static let roundHourTo : Double = 0.25
    
    private static let starterPlaces : [Place] = [
        Place(name: "Gladstone Hotel", coordinate: Coordinate(lat: 43.642698, lon: -79.426906), placeID: "ChIJwScp6qo1K4gRcuheo9LY6ZI"),
        Place(name: "Art Gallery of Ontario", coordinate: Coordinate(lat: 43.6536066, lon: -79.39251229999999), placeID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o"),
        Place(name: "Casa Loma", coordinate: Coordinate(lat: 43.67803709999999, lon: -79.4094439), placeID: "ChIJs6Elz500K4gRT1jWAsHIfGE"),
        Place(name: "Christie Pits Park", coordinate: Coordinate(lat: 43.6645888, lon: -79.4206809), placeID: "ChIJ8f_In4s0K4gRRK-KutieqXA"),
        Place(name: "Evergreen Brick Works", coordinate: Coordinate(lat: 43.6846206, lon: -79.3654466), placeID: "ChIJsXBSVKTM1IkRtVcT_EMpDho"),
        Place(name: "The Selby", coordinate: Coordinate(lat: 43.6710771, lon: -79.37722099999999), placeID: "ChIJZ2alrsfL1IkRXnxh_Pw8p0w")
    ]
    
    static func secondsToString(seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        let formattedString = formatter.string(from: seconds) ?? "error"
        
        return formattedString
    }
    
    static func currentTime() -> Double? {
        
        // Get current time
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.hour, .minute], from: Date())
        
        // Get components of time
        guard let currentHour = currentComponents.hour else { return nil }
        guard let currentMinute = currentComponents.minute else { return nil }
        let currentTime = TimeInterval.from(hours: currentHour) + TimeInterval.from(minutes: currentMinute)
        
        return currentTime
        
    }
    
    static func defaultPlaces() -> [Place] {
        var places = [Place]()
        places.append(contentsOf: starterPlaces)
        return places
    }
    
    static func defaultPlacesGroups() -> [PlaceGroup] {
        
        var groups = [PlaceGroup]()
        
        let places0 = PlaceGroup(name: "", places: Array(starterPlaces[0...1]), kind: .none)
        groups.append(places0)
        
        let places1 = PlaceGroup(name: "one of", places: Array(starterPlaces[2...3]), kind: .oneOf)
        groups.append(places1)
        
        let places2 = PlaceGroup(name: "as many of", places: Array(starterPlaces[4...5]), kind: .asManyOf)
        groups.append(places2)
        
        return groups
    }
    
    static func floorHour(_ hour: Double) -> Double {
        let decimal = hour.truncatingRemainder(dividingBy: 1.0)
        let clampedHour = floor(hour) + floor(decimal / Utils.roundHourTo) * Utils.roundHourTo
        return clampedHour
    }
    
    static func ceilHour(_ hour: Double) -> Double {
        let decimal = hour.truncatingRemainder(dividingBy: 1.0)
        let clampedHour = floor(hour) + ceil(decimal / Utils.roundHourTo) * Utils.roundHourTo
        return clampedHour
    }
    
    static func ceilTime(_ time: TimeInterval) -> TimeInterval {
        let hour = time.inHours()
        let clamped = ceilHour(hour)
        return TimeInterval.from(hours: clamped)
    }
    
    static func floorTime(_ time: TimeInterval) -> TimeInterval {
        let hour = time.inHours()
        let clamped = floorHour(hour)
        return TimeInterval.from(hours: clamped)
    }
    
    // permuteWirth from
    // https://github.com/raywenderlich/swift-algorithm-club/tree/master/Combinatorics
    // usage example: Utils.permute(indices, indices.count - 1, &permutations)
    static func permute<T>(_ a: [T], _ n: Int, _ result: inout [[T]]) {
        if n == 0 {
            print(a)   // display the current permutation
            result.append(a)
        } else {
            var a = a
            permute(a, n - 1, &result)
            for i in 0..<n {
                a.swapAt(i, n)
                permute(a, n - 1, &result)
                a.swapAt(i, n)
            }
        }
    }
    
    static func cartesianProduct<T>(_ arrs: [[[T]]]) -> [[T]] {
        
        var output = [[T]]()
        
        for i in 0 ..< arrs.count - 1 {
            let a1 = arrs[i]
            let a2 = arrs[i + 1]
            
            for val1 in a1 {
                for val2 in a2 {
                    output.append(val1 + val2)
                }
            }
        }
        
        return output
    }
    
    static func combinations<T>(_ input: [[T]], _ output: inout [[T]], _ prev: [T], _ i: Int, _ n: Int) {
        for elem in input[i] {
            if (i == n) {
                output.append(prev + [elem])
            } else {
                combinations(input, &output, prev + [elem], i + 1, n)
            }
        }
    }
    
    // from https://www.geeksforgeeks.org/print-subsets-given-size-set/
    private static func subsetUtil(_ arr: [Int], _ n: Int, _ r: Int, _ index: Int, _ data: inout [Int], _ i: Int, _ output: inout [[Int]]) {
        
        if(index == r){
            var temp = [Int]()
            for j in 0 ..< r {
                temp.append(data[j])
            }
            output.append(temp)
            return
        }
        
        if(i >= n){
            return
        }
        
        data[index] = arr[i]
        
        subsetUtil(arr, n, r, index + 1, &data, i + 1, &output)
        subsetUtil(arr, n, r, index, &data, i + 1, &output)
        
    }
    
    // from https://www.geeksforgeeks.org/print-subsets-given-size-set/
    static func subsets(_ arr: [Int], _ n: Int, _ size: Int) -> [[Int]] {
        
        var data : [Int] = Array(0 ... size - 1)
        var output = [[Int]]()
        subsetUtil(arr, n, size, 0, &data, 0, &output)
        return output
        
    }

    static func subsetPermutations(input: [Int], size: Int) -> [[Int]] {
        let subs = subsets(input, input.count, size)
        var perms = [[Int]]()
        for s in subs {
            var result = [[Int]]()
            permute(s, s.count - 1, &result)
            perms.append(contentsOf: result)
        }
        return perms
    }
    
}
