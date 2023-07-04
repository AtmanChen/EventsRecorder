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
	func getAllEvents() async -> [Event]
	func getTotalEventsCount() async -> Int
	func getTotalDistinctDaysCount() async -> Int64
	func getCurrentConsecutiveDaysCount() async -> Int
	func getMaxConsecutiveDaysCount() async -> Int
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
	func getAllEvents() async -> [Event] {
		await self.eventsProvider.getAllEvents()
	}
	func getTotalEventsCount() async -> Int {
		await self.eventsProvider.getTotalEventsCount()
	}
	func getTotalDistinctDaysCount() async -> Int64 {
		await self.eventsProvider.getTotalDistinctDaysCount()
	}
	func getMaxConsecutiveDaysCount() async -> Int {
		await self.eventsProvider.getMaxConsecutiveDaysCount()
	}
	func getCurrentConsecutiveDaysCount() async -> Int {
		await self.eventsProvider.getCurrentConsecutiveDaysCount()
	}
}
