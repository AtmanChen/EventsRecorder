//
//  Utils.swift
//  EventRecorder
//
//  Created by Anderson  on 2023/7/5.
//

import Foundation

func consecutiveEventSegmentsToString(_ segments: [EventStatistics.ConsecutiveSegment]) -> String {
	let data = try! JSONEncoder().encode(segments)
	return String(data: data, encoding: .utf8)!
}

func stringToConsecutiveEventSegments(_ string: String) -> [(EventStatistics.ConsecutiveSegment)] {
	let data = string.data(using: .utf8)!
	return try! JSONDecoder().decode([EventStatistics.ConsecutiveSegment].self, from: data)
}
