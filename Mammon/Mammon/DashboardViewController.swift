//
//  DashboardViewController.swift
//  Mammon
//
//  Created by Simon Shoban on 2018-12-29.
//  Copyright © 2018 Simon Shoban. All rights reserved.
//

import UIKit
import AWSAuthCore
import AWSAuthUI
import AWSMobileClient

class DashboardViewController: UIViewController {
    @IBOutlet weak var dailyTotal: UILabel!
    @IBOutlet weak var recentExpensesTable: UITableView!
    
    let numRecentExpenses = 4
    var recentExpenses: [Expense]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        print("loaded")
        
        //AWSMobileClient.sharedInstance().signOut()
        
        awsCognitoAuthentication() {
            () in
            
            print("auth complete")
            
            // If local database doesn't exist or newer database is available, load database from S3
            if (!DirectoryManager.localDatabaseExists() || S3Manager.newerDatabaseIsAvailable()) {
                DirectoryManager.createDatabaseDirectoryIfNotExists()
                S3Manager.loadDatabaseFromS3()
            }
        
            self.recentExpensesTable.register(ExpenseCell.self, forCellReuseIdentifier: "ExpenseCell")
            self.recentExpensesTable.delegate = self
            self.recentExpensesTable.dataSource = self
        }
    }
    
    func updatePage() {
        dailyTotal.text = SqliteManager.getDailyTotal()
        
        SqliteManager.printStuffFromDatabase()
        
        reloadRecentExpensesTable()
    }
    
    func reloadRecentExpensesTable() {
        let newRecentExpenses = SqliteManager.getMostRecentExpenses(numberOfExpenses: numRecentExpenses)
        
        if (newRecentExpenses[0] != nil && (recentExpenses == nil || !newRecentExpenses.elementsEqual(recentExpenses!))) {
            recentExpensesTable.beginUpdates()
            
            if (recentExpenses != nil) {
                for index in 0...recentExpenses!.count - 1 {
                    recentExpensesTable.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                }
            }
            
            recentExpenses = newRecentExpenses as? [Expense]
            
            for index in 0...recentExpenses!.count - 1 {
                recentExpensesTable.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            }
            
            recentExpensesTable.endUpdates()
        }
    }
    
    func awsCognitoAuthentication(completionHandler: @escaping () -> Void) {
        var authStatus = false
        
        print("In auth")
        
        AWSMobileClient.sharedInstance().initialize { (userState, error) in
            if let userState = userState {
                print("UserState: \(userState.rawValue)")
                authStatus = userState.rawValue == "signedIn"
            } else if let error = error {
                print("error: \(error.localizedDescription)")
            }
        }

        if authStatus {
            print("Already signed in")
            completionHandler()
            return
        }
        
        AWSMobileClient.sharedInstance().showSignIn(navigationController: self.navigationController!, { (signInState, error) in
            if signInState != nil {
                print("logged in!")
            } else {
                print("error logging in: \(error!.localizedDescription)")
            }
            
            completionHandler()
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updatePage()
    }
    
    @IBAction func unwindWithSegue(_ segue: UIStoryboardSegue) {
        
    }
}

extension DashboardViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentExpenses?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseCell", for: indexPath) as! ExpenseCell
        let expense = recentExpenses![indexPath.row]
        
        cell.textLabel?.text = "\(expense.description) $\(expense.amount) \(Utils.getHumanizedDateString(dateString: expense.date))"
        cell.detailTextLabel?.text = "Test"
        
        return cell
    }
}
