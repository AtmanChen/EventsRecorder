//
//  Date+Extension.swift
//  EventRecorder
//
//  Created by Anderson  on 2023/7/3.
//

import Foundation

extension Date {
	func dateWithOnlyYearMonthDay() -> Date? {
		let calendar = Calendar.current
		let components = calendar.dateComponents([.year, .month, .day], from: self)
		return calendar.date(from: components)
	}
	func diffDaysCount(days: Int) -> Date {
		Calendar.current.date(byAdding: .day, value: days, to: self)!
	}
}
