//
//  EventStatistics.swift
//  EventRecorder
//
//  Created by Anderson  on 2023/7/5.
//

import Foundation

struct EventStatistics {
	let uid: String
	let totalEventCount: Int64
	let consecutiveSegments: [ConsecutiveSegment]
	
	struct ConsecutiveSegment: Codable {
		var startDate: Date
		var endDate: Date
		var count: Int64
	}
}
