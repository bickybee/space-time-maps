//
//  Combinatorics.swift
//  Space-Time-Maps
//
//  Created by Vicky on 10/10/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation

class Combinatorics {
    
    // permuteWirth from
    // https://github.com/raywenderlich/swift-algorithm-club/tree/master/Combinatorics
    // usage example: Utils.permute(indices, indices.count - 1, &permutations)
    static func permute<T>(_ a: [T], _ n: Int, _ result: inout [[T]]) {
        if n == 0 {
            //print(a)   // display the current permutation
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
    
    // from https://www.geeksforgeeks.org/print-subsets-given-size-set/
    static func subsets(_ arr: [Int], _ n: Int, _ size: Int) -> [[Int]] {
        
        var data : [Int] = Array(0 ... size - 1)
        var output = [[Int]]()
        subsetUtil(arr, n, size, 0, &data, 0, &output)
        return output
        
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
    
}
