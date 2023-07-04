//
//  Event.swift
//  EventRecorder
//
//  Created by Anderson  on 2023/7/3.
//

import Foundation
import SQLite

struct Event: Identifiable {
	let id: Int64
	let name: String?
	let timestamp: TimeInterval
	let date: Date // year month day
	let deleted: Bool
}

extension Event: Sendable {}
