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
	func getEvents(from: Date, to: Date) async -> [Event]
	func getTotalEventsCount() async -> Int64
	func getTotalDistinctDaysCount() async -> Int64
	func getCurrentConsecutiveDaysCount() async -> Int64
	func getMaxConsecutiveDaysCount() async -> Int64
}

let daySeconds: TimeInterval = 24 * 60 * 60

actor SQLiteEventsProvider: EventsProvider {
	let userId: String
	static private let eventsFileName = "events.sqlite3"
	
	// MARK: Event statistics structure
	private let eventStatistics = Table("eventStatistics")
	private let uid = Expression<String>("uid")
	private let totalEventCount = Expression<Int64>("totalEventCount")
	private let consecutiveSegments = Expression<String>("consecutiveEventSegments")
	
	// MARK: Event structure
	private let events = Table("events")
	private let id = Expression<Int64>("id")
	private let name = Expression<String?>("name")
	private let timestamp = Expression<TimeInterval>("timestamp")
	private let date = Expression<Date>("date")
	private let deleted = Expression<Bool>("deleted")
	
	// MARK: db
	private var dbPath: String = ""
	private var db: Connection?
	
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
			try db.run(eventStatistics.create(ifNotExists: true) { table in
				table.column(uid, primaryKey: true)
				table.column(totalEventCount)
				table.column(consecutiveSegments)
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
		do {
			// modify statistics
			let stateRow = eventStatistics.filter(uid == self.userId)
			let eventStatisticsRow = try db.pluck(stateRow)
			if let eventStatisticsRow {
				let updateEventCount = eventStatisticsRow[totalEventCount] + 1
				let consecutiveSegments = stringToConsecutiveEventSegments(eventStatisticsRow[consecutiveSegments])
				let updatedConsecutiveSegments = consecutiveSegments.mergeDate(date)
				let updatedConsecutiveSegmentsString = consecutiveEventSegmentsToString(updatedConsecutiveSegments)
				print("consecutiveSegmentsString: \(updatedConsecutiveSegmentsString)")
				let eventStatisticsUpdate = stateRow.update(
					self.totalEventCount <- updateEventCount,
					self.consecutiveSegments <- updatedConsecutiveSegmentsString
				)
				try db.run(eventStatisticsUpdate)
			} else {
				let consecutiveSegments = [EventStatistics.ConsecutiveSegment]().mergeDate(date)
				let consecutiveSegmentsString = consecutiveEventSegmentsToString(consecutiveSegments)
				let eventStatisticsInsert = self.eventStatistics.insert(
					uid <- self.userId,
					totalEventCount <- 1,
					self.consecutiveSegments <- consecutiveSegmentsString
				)
				print("consecutiveSegmentsString: \(consecutiveSegmentsString)")
				try db.run(eventStatisticsInsert)
			}
			let insert = self.events.insert(self.name <- name, self.timestamp <- timestamp, self.date <- date, self.deleted <- false)
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
		guard let eventToDelete = try? db.pluck(filter) else { return false }
		do {
			try db.run(filter.update(self.deleted <- true))
			let otherEventsOnSameDay = try db.prepare(events.filter(self.date == eventToDelete[date] && self.id != id && self.deleted == false))
			if Array(otherEventsOnSameDay).count == 0 {
				let stateRow = eventStatistics.filter(uid == self.userId)
				if let eventStatisticsRow = try db.pluck(stateRow) {
					let consecutiveSegments = stringToConsecutiveEventSegments(eventStatisticsRow[consecutiveSegments])
					let updatedConsecutiveSegments = consecutiveSegments.removeDate(eventToDelete[date])
					let updatedConsecutiveSegmentsString = consecutiveEventSegmentsToString(updatedConsecutiveSegments)
					let eventStatisticsUpdate = stateRow.update(
						self.consecutiveSegments <- updatedConsecutiveSegmentsString
					)
					try db.run(eventStatisticsUpdate)
				}
			}
			
			return true
		} catch {
			print("Event delete failed: \(error)")
			return false
		}
	}
	func getEvents(from: Date, to: Date) async -> [Event] {
		var results: [Event] = []
		guard let db else {
			print("Events db connection not found")
			return results
		}
		let orderedEvents = events
			.filter(date >= from && date <= to && deleted == false)
			.order(self.timestamp.desc)
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
	func getTotalEventsCount() async -> Int64 {
		guard let db else {
			print("Events db connection not found")
			return 0
		}
		do {
			let stateRow = eventStatistics.filter(uid == self.userId)
			if let eventStatisticsRow = try db.pluck(stateRow) {
				return eventStatisticsRow[totalEventCount]
			}
			return 0
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
			let stateRow = eventStatistics.filter(uid == self.userId)
			if let eventStatisticsRow = try db.pluck(stateRow) {
				let consecutiveSegmentsString = eventStatisticsRow[consecutiveSegments]
				let consecutiveSegments = stringToConsecutiveEventSegments(consecutiveSegmentsString)
				return consecutiveSegments.totalDistinctDays()
			}
			return 0
		} catch {
			print("Error: \(error)")
		}
		return 0
	}
	func getMaxConsecutiveDaysCount() async -> Int64 {
		guard let db else {
			print("Events db connection not found")
			return 0
		}
		do {
			let stateRow = eventStatistics.filter(uid == self.userId)
			if let eventStatisticsRow = try db.pluck(stateRow) {
				let consecutiveSegmentsString = eventStatisticsRow[consecutiveSegments]
				let consecutiveSegments = stringToConsecutiveEventSegments(consecutiveSegmentsString)
				return consecutiveSegments.maxConsecutiveDays()
			}
			return 0
		} catch {
			print("Error while calculating max consecutive days: \(error)")
		}
		
		return 0
	}
	func getCurrentConsecutiveDaysCount() async -> Int64 {
		guard let db else {
			print("Events db connection not found")
			return 0
		}
		do {
			let stateRow = eventStatistics.filter(uid == self.userId)
			if let eventStatisticsRow = try db.pluck(stateRow) {
				let consecutiveSegmentsString = eventStatisticsRow[consecutiveSegments]
				let consecutiveSegments = stringToConsecutiveEventSegments(consecutiveSegmentsString)
				return consecutiveSegments.last!.count
			}
			return 0
		} catch {
			print("Error while calculating current consecutive days: \(error)")
		}
		return 0
	}
}

