//
//  ListDataGenerator.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/7/21.
//

import Foundation

func generateListData(listCount:Int = 10) -> [Checklist] {
    var lists:[Checklist] = []
    for index in 0..<listCount {
        let list = generateList(id: index.description)
        lists.append(list)
    }
    return lists.sorted { $0.updated > $1.updated }
}

func generateList(id: String) -> Checklist {
    let items:[Checklist.Item] = generateListItems(partiallyComplete: Bool.random())
    let title = "List \(id)"
    let secondsInWeek = 60 * 60 * 24 * 7
    let randomRatio = Double.random(in: 0...1)
    let randomWeekishTimeInterval = TimeInterval(randomRatio * Double(secondsInWeek))
    let updated = Date.now.advanced(by: -randomWeekishTimeInterval)
    return Checklist(title: title, updated: updated, items: items)
}

func generateListItems(count: Int = 10, partiallyComplete: Bool) -> [Checklist.Item] {
    return (0..<count).map { index in
        generateListItem(id: index, checked: partiallyComplete ? Bool.random() : false)
    }
}

func generateListItem(id: Int, checked: Bool = false) -> Checklist.Item {

    let randomItem = sampleItems.randomElement() ?? "apples"
    
    return Checklist.Item(id: id, title: randomItem, checked: checked)
    
    
}

private let sampleItems:[String] = [
    "Apples",
    "Oranges",
    "Asparagus",
    "Broccoli ",
    "Carrots",
    "Cauliflower",
    "Celery",
    "Corn",
    "Cucumbers",
    "Kale",
    "Mushrooms",
    "Onions",
    "Peppers",
    "Potatoes",
    "Spinach",
    "Squash",
    "Zucchini",
    "Tomatoes",
    "Pepperocini",
    "Beets",
    "Potatoes",
    "Purple cabbage",
    "Oatmeal",
    "Root beer",
    "Vanilla ice cream",
    "Bell peppers",
    "Cilantro",
    "Spinach",
    "Arugula",
    "Popsicles",
    "Ube stuff",
    "Truffle ketchup",
    "Scallions",
    "Tomatoes",
    "Red onion",
    "Chips",
]
