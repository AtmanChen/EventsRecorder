//
//  ViewController.swift
//  EventRecorder
//
//  Created by Anderson  on 2023/7/3.
//

import UIKit
import Combine

private let cellId = "UITableViewCell"

class EventsListViewController: UIViewController {
	private var cancellables: Set<AnyCancellable> = []
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var totalCount: UILabel!
	@IBOutlet weak var totalDays: UILabel!
	@IBOutlet weak var maxConsecutive: UILabel!
	@IBOutlet weak var currentConsecutive: UILabel!
	private let viewModel = EventsListViewModel(eventsManager: DefaultEventsManager(eventsProvider: SQLiteEventsProvider(userId: "account-1000")))
	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Events"
		Task {
			await viewModel.fetchEvents()
		}
		bindViewModel()
	}
	
	private func bindViewModel() {
		// total count
		viewModel.$events.sink(receiveValue: { [weak self] es in
			guard let self else {
				return
			}
			self.totalCount.text = "TC: \(es.count)"
			self.tableView.reloadData()
		})
		.store(in: &cancellables)
		
		// total days
		viewModel.$totalDistinctDays.sink(receiveValue: { [weak self] days in
			guard let self else {
				return
			}
			self.totalDays.text = "TD: \(days)"
		})
		.store(in: &cancellables)
		
		// max consecu
		viewModel.$maxConsecutiveDays.sink(receiveValue: { [weak self] count in
			guard let self else {
				return
			}
			self.maxConsecutive.text = "MC: \(count)"
		})
		.store(in: &cancellables)
		
		// current consecu
		viewModel.$currentConsecutiveDaysCount.sink(receiveValue: { [weak self] count in
			guard let self else {
				return
			}
			self.currentConsecutive.text = "CC: \(count)"
		})
		.store(in: &cancellables)
		
		viewModel.reloadUI = { [weak self] in
			guard let self else {
				return
			}
			self.tableView.reloadData()
		}
	}

	@IBAction func addEvent(_ sender: UIBarButtonItem) {
		Task {
			if let d = Date().dateWithOnlyYearMonthDay() {
				await viewModel.addEvent(d.description)
			}
		}
	}
	
}

extension EventsListViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		viewModel.events.count
	}
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCell(withIdentifier: cellId)
		if cell == nil {
			cell = UITableViewCell(style: .default, reuseIdentifier: cellId)
		}
		let event = viewModel.events[indexPath.row]
		cell?.textLabel?.text = "\(event.id). \(event.date.description)"
		return cell!
	}
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, _ in
			guard let self else {
				return
			}
			let eventId = viewModel.events[indexPath.row].id
			Task {
				await self.viewModel.deleteEvent(eventId)
			}
		}
		return UISwipeActionsConfiguration(actions: [deleteAction])
	}
}

