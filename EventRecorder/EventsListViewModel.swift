//
//  EventsListViewModel.swift
//  EventRecorder
//
//  Created by Anderson  on 2023/7/3.
//

import Foundation

@MainActor
final class EventsListViewModel {
	private let eventsManager: EventsManager
	var reloadUI: (() -> Void)?
	init(eventsManager: EventsManager) {
		self.eventsManager = eventsManager
	}
	@Published var events: [Event] = []
	@Published var totalDistinctDays: Int64 = 0
	@Published var maxConsecutiveDays: Int64 = 0
	@Published var currentConsecutiveDaysCount: Int64 = 0
	func fetchEvents() async {
		let date: Date
		if events.isEmpty {
			date = Date().dateWithOnlyYearMonthDay()!
		} else {
			date = events.last!.date
		}
		let pageDate = date.diffDaysCount(days: -30)
		async let events = await self.eventsManager.getEvents(from: pageDate, to: date)
		async let currentConsecutiveDaysCount = await self.eventsManager.getCurrentConsecutiveDaysCount()
		async let totalDistinctDays = await self.eventsManager.getTotalDistinctDaysCount()
		async let maxConsecutiveDays = await self.eventsManager.getMaxConsecutiveDaysCount()
		self.events = await events
		self.currentConsecutiveDaysCount = await currentConsecutiveDaysCount
		self.totalDistinctDays = await totalDistinctDays
		self.maxConsecutiveDays = await maxConsecutiveDays
		await MainActor.run {
			if let reloadUI {
				reloadUI()
			}
		}
	}
	func addEvent(_ name: String?) async {
		let date = Date()
		if let d = date.dateWithOnlyYearMonthDay(),
			 let event = await self.eventsManager.addEvent(name: name, timestamp: date.timeIntervalSince1970, date: d) {
			print("Events date: \(d)")
			self.events.insert(event, at: 0)
			await eventsChangedTrigger()
			await MainActor.run {
				if let reloadUI {
					reloadUI()
				}
			}
		}
	}
	func deleteEvent(_ id: Int64) async {
		let deleteResult = await self.eventsManager.removeEvent(by: id)
		if deleteResult {
			await MainActor.run {
				self.events.removeAll(where: { $0.id == id })
				if let reloadUI {
					reloadUI()
				}
			}
			await eventsChangedTrigger()
		}
	}
	private func eventsChangedTrigger() async {
		self.currentConsecutiveDaysCount = await self.eventsManager.getCurrentConsecutiveDaysCount()
		self.totalDistinctDays = await self.eventsManager.getTotalDistinctDaysCount()
		self.maxConsecutiveDays = await self.eventsManager.getMaxConsecutiveDaysCount()
	}
}
