//
//  SqliteManager.swift
//  Mammon
//
//  Created by Simon Shoban on 2019-01-18.
//  Copyright © 2019 Simon Shoban. All rights reserved.
//

import Foundation
import SQLite3

class SqliteManager {
    private static let INSERT_STATEMENT: String =
    "INSERT INTO expenses (date, description, expense, category, covered) VALUES (?, ?, ?, ?, ?);"
    
    private static let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    class func openDatabase() -> OpaquePointer? {
        var db: OpaquePointer?
        
        if sqlite3_open_v2(DirectoryManager.getDatabaseLocation(), &db, SQLITE_OPEN_READWRITE, nil) != SQLITE_OK {
            print("error opening database")
            sqlite3_close_v2(db)
        }
        
        return db
    }
    
    class func getDailyTotal() -> String {
        let db = openDatabase()
        
        var statement: OpaquePointer?
        
        print(Utils.getCurrentDate())
        
        sqlite3_prepare_v2(db, "SELECT SUM(expense) FROM expenses WHERE date LIKE '\(Utils.getCurrentDate())';", -1, &statement, nil)
        
        if (sqlite3_step(statement) == SQLITE_ROW) {
            let dailyTotal = sqlite3_column_double(statement, 0)
            
            sqlite3_finalize(statement)
            sqlite3_close_v2(db)
            
            return String(format: "$%.02f", dailyTotal)
        }
        
        sqlite3_finalize(statement)
        sqlite3_close_v2(db)
        
        return "$0.00$"
    }
    
    class func printStuffFromDatabase() {
        let db = openDatabase()
        
        var statement: OpaquePointer?
        
        sqlite3_prepare(db!, "SELECT * FROM expenses ORDER BY date DESC LIMIT 4;", -1, &statement, nil)
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
            print(sqlite3_column_int(statement, 0), String(cString: sqlite3_column_text(statement, 1)), String(cString: sqlite3_column_text(statement, 2)), sqlite3_column_double(statement, 3), String(cString: sqlite3_column_text(statement, 4)))
        }
        
        sqlite3_finalize(statement)
        sqlite3_close_v2(db)
    }
    
    class func convertDatabaseDateFormat() {
        var selectStatement: OpaquePointer? = nil
        
        let selectQuery = "SELECT expense_id, date FROM expenses;"
        
        let db = openDatabase()
        
        var expenses = [Expense]()
        
        if sqlite3_prepare_v2(db, selectQuery, -1, &selectStatement, nil) == SQLITE_OK {
            while (sqlite3_step(selectStatement) == SQLITE_ROW) {
                let expenseID = sqlite3_column_int(selectStatement, 0)
                let oldDate = String(cString: sqlite3_column_text(selectStatement, 1))
                var expense = Expense(date: oldDate, description: "test", amount: 0, category: ExpenseCategory.Food, isCovered: false)
                
                expense.setExpenseID(expenseID)
                
                expenses.append(expense)
            }
        }
        
        sqlite3_finalize(selectStatement)
        
        for expense in expenses {
            var updateStatement: OpaquePointer? = nil
            let formattedDate = Utils.convertStringDateFormat(dateString: expense.date, oldFormat: "M/d/yyyy", newFormat: "yyyy/MM/dd")
            
            if sqlite3_prepare_v2(db, "UPDATE expenses SET date = '\(formattedDate)' WHERE expense_id LIKE \(expense.expenseID);", -1, &updateStatement, nil) == SQLITE_OK {
                
                if sqlite3_step(updateStatement) == SQLITE_DONE {
                    print("Updating \(expense.date) to \(formattedDate)")
                } else {
                    print("ERROR updating date")
                }
            }
            
            sqlite3_finalize(updateStatement)
        }
        
        sqlite3_close_v2(db)
    }
    
    class func insertExpense(_ expense: Expense) -> Int32 {
        var retval: Int32 = 0;
        var insertStatement: OpaquePointer? = nil
        
        let db = openDatabase()
        
        var x: Int32 = 0
        
        if sqlite3_prepare_v2(db, INSERT_STATEMENT, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(insertStatement, 1, expense.date, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(insertStatement, 2, expense.description, -1, SQLITE_TRANSIENT)
            sqlite3_bind_double(insertStatement, 3, expense.amount)
            sqlite3_bind_text(insertStatement, 4, expense.category.rawValue, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(insertStatement, 5, expense.covered)
            
            x = sqlite3_step(insertStatement)
            
            if (x == SQLITE_DONE) {
                print("Successfully inserted row.")
                retval = SQLITE_DONE
            } else {
                print("Could not insert row.")
            }
        } else {
            print("INSERT statement could not be prepared.")
        }

        sqlite3_finalize(insertStatement)
        sqlite3_close_v2(db)
        
        return retval
    }
    
    class func getMostRecentExpenses(numberOfExpenses: Int) -> [Expense?] {
        let db = openDatabase()
        let selectStatement = "SELECT * FROM expenses ORDER BY date DESC, expense_id DESC LIMIT \(numberOfExpenses);"
        
        var statement: OpaquePointer?
        var expenses = [Expense?](repeating: nil, count: numberOfExpenses)
        var index = 0;
        
        if (sqlite3_prepare_v2(db!, selectStatement, -1, &statement, nil) != SQLITE_OK) {
            sqlite3_finalize(statement)
            sqlite3_close_v2(db)
            
            return expenses
        }
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
            var expense = Expense(
                date: String(cString: sqlite3_column_text(statement, 1)),
                description: String(cString: sqlite3_column_text(statement, 2)),
                amount: sqlite3_column_double(statement, 3),
                category: ExpenseCategory(rawValue: String(cString: sqlite3_column_text(statement, 4)))!,
                isCovered: (sqlite3_column_double(statement, 5) == 1) ? true : false)
            
            expense.setExpenseID(sqlite3_column_int(statement, 0))
            
            expenses[index] = expense
            
            index += 1
        }
        
        sqlite3_finalize(statement)
        sqlite3_close_v2(db)
        
        return expenses as! [Expense]
    }
}
