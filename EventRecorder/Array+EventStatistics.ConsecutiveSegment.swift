//
//  Array+Extension.swift
//  EventRecorder
//
//  Created by Anderson  on 2023/7/5.
//

import Foundation

extension Array where Element == EventStatistics.ConsecutiveSegment {
	func mergeDate(_ date: Date) -> Self {
		var newSegments = self
		
		for (index, segment) in newSegments.enumerated() {
			
			if date >= segment.startDate && date <= segment.endDate {
				return newSegments
			}
			let nextDayAfterEndDate = segment.endDate.diffDaysCount(days: 1)
			let previousDayBeforeStartDate = segment.startDate.diffDaysCount(days: -1)
			
			if date == nextDayAfterEndDate {
				newSegments[index].endDate = date
				newSegments[index].count += 1
				
				if index + 1 < newSegments.count && newSegments[index].endDate.diffDaysCount(days: 1) == newSegments[index + 1].startDate {
					newSegments[index].endDate = newSegments[index + 1].endDate
					newSegments[index].count += newSegments[index + 1].count
					newSegments.remove(at: index + 1)
				}
				return newSegments
			}
			
			if date == previousDayBeforeStartDate {
				newSegments[index].startDate = date
				newSegments[index].count += 1
				
				if index > 0 && newSegments[index - 1].endDate.diffDaysCount(days: 1) == newSegments[index].startDate {
					newSegments[index - 1].endDate = newSegments[index].endDate
					newSegments[index - 1].count += newSegments[index].count
					newSegments.remove(at: index)
				}
				return newSegments
			}
		}
		
		let newSegment = EventStatistics.ConsecutiveSegment(startDate: date, endDate: date, count: 1)
		newSegments.append(newSegment)
		return newSegments.sorted(by: { $0.startDate < $1.startDate })
	}
	func totalDistinctDays() -> Int64 {
		self.reduce(0, { step, segment in step + segment.count })
	}
	func maxConsecutiveDays() -> Int64 {
		self.map(\.count).max() ?? 0
	}
	func removeDate(_ date: Date) -> Self {
		var newSegments = self
		
		for (index, segment) in newSegments.enumerated() {
			if date >= segment.startDate && date <= segment.endDate {
				if segment.count == 1 {
					newSegments.remove(at: index)
					break
				} else if date == segment.startDate {
					newSegments[index].startDate = segment.startDate.diffDaysCount(days: 1)
					newSegments[index].count -= 1
					break
				} else if date == segment.endDate {
					newSegments[index].endDate = segment.endDate.diffDaysCount(days: -1)
					newSegments[index].count -= 1
					break
				} else {
					let newSegment = EventStatistics.ConsecutiveSegment(startDate: date.diffDaysCount(days: 1), endDate: segment.endDate, count: segment.count - Int64(Calendar.current.dateComponents([.day], from: date, to: segment.endDate).day!))
					newSegments[index].endDate = date.diffDaysCount(days: -1)
					newSegments[index].count = Int64(Calendar.current.dateComponents([.day], from: segment.startDate, to: date).day!)
					newSegments.insert(newSegment, at: index + 1)
					break
				}
			}
		}
		
		return newSegments
	}
}
