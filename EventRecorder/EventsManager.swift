//
//  EventsManager.swift
//  EventRecorder
//
//  Created by Anderson  on 2023/7/3.
//

import Foundation

protocol EventsManager {
	func addEvent(name: String?, timestamp: TimeInterval, date: Date) async -> Event?
	func removeEvent(by id: Int64) async -> Bool
	func getEvents(from: Date, to: Date) async -> [Event]
	func getTotalEventsCount() async -> Int64
	func getTotalDistinctDaysCount() async -> Int64
	func getCurrentConsecutiveDaysCount() async -> Int64
	func getMaxConsecutiveDaysCount() async -> Int64
}

actor DefaultEventsManager: EventsManager {
	var eventsProvider: EventsProvider
	init(eventsProvider: EventsProvider) {
		self.eventsProvider = eventsProvider
	}
	func addEvent(name: String?, timestamp: TimeInterval, date: Date) async -> Event? {
		if let event = await self.eventsProvider.createEvent(name: name, timestamp: timestamp, date: date) {
			print("Create event successfully, notify UI")
			return event
		} else {
			print("Create event failed")
			return nil
		}
	}
	func removeEvent(by id: Int64) async -> Bool {
		if await self.eventsProvider.deleteEvent(by: id) {
			print("Delete event successfully, notify UI")
			return true
		} else {
			print("Delete event failed")
		}
		return false
	}
	func getEvents(from: Date, to: Date) async -> [Event] {
		await self.eventsProvider.getEvents(from: from, to: to)
	}
	func getTotalEventsCount() async -> Int64 {
		await self.eventsProvider.getTotalEventsCount()
	}
	func getTotalDistinctDaysCount() async -> Int64 {
		await self.eventsProvider.getTotalDistinctDaysCount()
	}
	func getMaxConsecutiveDaysCount() async -> Int64 {
		await self.eventsProvider.getMaxConsecutiveDaysCount()
	}
	func getCurrentConsecutiveDaysCount() async -> Int64 {
		await self.eventsProvider.getCurrentConsecutiveDaysCount()
	}
}
