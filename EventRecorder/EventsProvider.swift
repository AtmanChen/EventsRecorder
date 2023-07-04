//
//  EventsProvider.swift
//  EventRecorder
//
//  Created by Anderson  on 2023/7/3.
//

import Foundation
import SQLite

protocol EventsProvider {
	func createEvent(name: String?, timestamp: TimeInterval, date: Date) async -> Event?
	func deleteEvent(by id: Int64) async -> Bool
	func getAllEvents() async -> [Event]
	func getTotalEventsCount() async -> Int
	func getTotalDistinctDaysCount() async -> Int64
	func getCurrentConsecutiveDaysCount() async -> Int
	func getMaxConsecutiveDaysCount() async -> Int
}

private let daySeconds: TimeInterval = 24 * 60 * 60

actor SQLiteEventsProvider: EventsProvider {
	let userId: String
	static private let eventsFileName = "events.sqlite3"
	private var db: Connection?
	private let events = Table("events")
	private let id = Expression<Int64>("id")
	private let name = Expression<String?>("name")
	private let timestamp = Expression<TimeInterval>("timestamp")
	private let date = Expression<Date>("date")
	private let deleted = Expression<Bool>("deleted")
	private var dbPath: String = ""
	
	init(userId: String) {
		self.userId = userId
		if let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
			let accountUrl = documentDir.appending(path: "\(userId)")
			do {
				try FileManager.default.createDirectory(
					atPath: accountUrl.path(), withIntermediateDirectories: true, attributes: nil
				)
				self.dbPath = accountUrl.appending(path: Self.eventsFileName).path()
				self.db = try Connection(self.dbPath)
				Task {
					await createTable()
				}
			} catch {
				print("\(error)")
			}
		}
	}
	private func createTable() async {
		guard let db else {
			return
		}
		do {
			try db.run(events.create(ifNotExists: true) { table in
				table.column(id, primaryKey: .autoincrement)
				table.column(name)
				table.column(timestamp)
				table.column(date, unique: false)
				table.column(deleted)
			})
			print("Events table created at: \(self.dbPath)")
		} catch {
			print("Events table created failed...")
		}
	}
	
	func createEvent(name: String?, timestamp: TimeInterval, date: Date) async -> Event? {
		guard let db else {
			print("Events db connection not found")
			return nil
		}
		let insert = events.insert(self.name <- name, self.timestamp <- timestamp, self.date <- date, self.deleted <- false)
		do {
			let rowId = try db.run(insert)
			print("Event created with rowId: \(rowId)")
			return Event(id: rowId, name: name, timestamp: timestamp, date: date, deleted: false)
		} catch {
			print("Event created failed: \(error)")
			return nil
		}
	}
	func deleteEvent(by id: Int64) async -> Bool {
		guard let db else {
			print("Events db connection not found")
			return false
		}
		let filter = events.filter(self.id == id)
		do {
			try db.run(filter.update(self.deleted <- true))
			return true
		} catch {
			print("Event delete failed: \(error)")
			return false
		}
	}
	func getAllEvents() async -> [Event] {
		var results: [Event] = []
		guard let db else {
			print("Events db connection not found")
			return results
		}
		let orderedEvents = events.order(id.desc).filter(!deleted)
		do {
			for event in try db.prepare(orderedEvents) {
				results.append(Event(id: event[id], name: event[name], timestamp: event[timestamp], date: event[date], deleted: false))
			}
			return results
		} catch {
			print("Event get failed: \(error)")
			return []
		}
	}
	func getTotalEventsCount() async -> Int {
		guard let db else {
			print("Events db connection not found")
			return 0
		}
		do {
			return try db.scalar(events.count)
		} catch {
			return 0
		}
	}
	func getTotalDistinctDaysCount() async -> Int64 {
		guard let db else {
			print("Events db connection not found")
			return 0
		}
		do {
			let query = """
				SELECT COUNT(*)
				FROM (
						SELECT strftime('%Y-%m-%d', date) AS date_only
						FROM events
						GROUP BY date_only
				)
				"""
			
			if let count = try db.scalar(query) as? Int64 {
				print("Distinct date count: \(count)")
				return count
			} else {
				print("Error: Failed to convert the result to Int64")
			}
		} catch {
			print("Error: \(error)")
		}
		return 0
	}
	func getMaxConsecutiveDaysCount() async -> Int {
		guard let db else {
			print("Events db connection not found")
			return 0
		}
		
		let orderedEvents = events.order(date)
		
		var maxConsecutiveDays = 0
		var currentConsecutiveDays = 0
		var previousDate: Date? = nil
		
		do {
			for event in try db.prepare(orderedEvents) {
				let eventDate = event[date]
				if let pd = previousDate {
					let isEventSameDay = Calendar.current.isDate(eventDate, inSameDayAs: pd)
					print("Event date: \(pd) \(eventDate) \(isEventSameDay)")
					if isEventSameDay {
						previousDate = eventDate
						continue
					}
					let isContinues = Calendar.current.isDate(eventDate, inSameDayAs: pd.addingTimeInterval(daySeconds))
					if isContinues {
						currentConsecutiveDays += 1
					} else {
						currentConsecutiveDays = 1
					}
				} else {
					currentConsecutiveDays = 1
				}
				
				maxConsecutiveDays = max(maxConsecutiveDays, currentConsecutiveDays)
				previousDate = eventDate
			}
		} catch {
			print("Error while calculating max consecutive days: \(error)")
		}
		
		return maxConsecutiveDays
	}
	func getCurrentConsecutiveDaysCount() async -> Int {
		guard let db else {
			print("Events db connection not found")
			return 0
		}
		let orderedEvents = events.order(date.desc)
		
		var currentConsecutiveDays = 0
		var previousDate: Date? = nil
		do {
			for event in try db.prepare(orderedEvents) {
				let eventDate = event[date]
				if currentConsecutiveDays == 0 {
					currentConsecutiveDays = 1
				} else {
					let isEventSameDay = Calendar.current.isDate(eventDate, inSameDayAs: previousDate!)
					if isEventSameDay {
						previousDate = eventDate
						continue
					}
					let isEventContinuse = Calendar.current.isDate(eventDate, inSameDayAs: previousDate!.addingTimeInterval(-daySeconds))
					if isEventContinuse {
						currentConsecutiveDays += 1
					} else {
						break
					}
				}
				previousDate = eventDate
			}
		} catch {
			print("Error while calculating current consecutive days: \(error)")
		}
		return currentConsecutiveDays
	}
}

