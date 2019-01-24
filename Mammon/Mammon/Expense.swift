//
//  Expense.swift
//  Mammon
//
//  Created by Simon Shoban on 2019-01-19.
//  Copyright © 2019 Simon Shoban. All rights reserved.
//

import Foundation

struct Expense: Equatable{
    var expenseID: Int32
    var date: String
    var description: String
    var amount: Double
    var category: ExpenseCategory
    var isCovered: Bool
    var covered: Int32
    
    init (date: String, description: String, amount: Double, category: ExpenseCategory, isCovered: Bool) {
        self.date = date
        self.description = description
        self.amount = amount
        self.category = category
        self.isCovered = isCovered
        self.covered = isCovered ? 1 : 0
        
        self.expenseID = -1
    }
    
    mutating func setExpenseID(_ id: Int32) {
        self.expenseID = id
    }
    
    static func == (lhs: Expense, rhs: Expense) -> Bool {
        return lhs.expenseID == rhs.expenseID
    }
}
