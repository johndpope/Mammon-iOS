//
//  AddNewExpenseViewController.swift
//  Mammon
//
//  Created by Simon Shoban on 2019-01-11.
//  Copyright © 2019 Simon Shoban. All rights reserved.
//

import UIKit
import SQLite3

class AddNewExpenseViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    let expenseCategories = ["Food", "Clothes", "Services", "Items"]
    let datePicker: UIDatePicker = UIDatePicker()
    let categoryPicker: UIPickerView = UIPickerView();
    
    @IBOutlet weak var expenseDateField: UITextField!
    @IBOutlet weak var expenseCategoryField: UITextField!
    @IBOutlet weak var expenseField: UITextField!
    @IBOutlet weak var expenseDescriptionView: UITextView!
    @IBOutlet weak var expenseCoveredSwitch: UISwitch!
    
    @IBAction func recordExpense(_ sender: Any) {
        resetAllFormInputBorders()
        
        if (!formsAreValid()) {
            return
        }
        
        let expense = createExpenseFromFields()
        
        if SqliteManager.insertExpense(expense) != SQLITE_DONE {
            print("DB transaction failed")
            return
        }
        
        S3Manager.uploadDatabaseToS3()
        
        // Return to previous ViewController
        dismiss(animated: true, completion: nil)
    }
    
    func createExpenseFromFields() -> Expense {
        return Expense(date: expenseDateField!.text!, description: expenseDescriptionView!.text, amount: Double(expenseField!.text!)!, category: ExpenseCategory(rawValue: expenseCategoryField!.text!.lowercased())!, isCovered: expenseCoveredSwitch.isSelected)
    }
    
    func formsAreValid() -> Bool {
        if expenseDateField.text!.isEmpty {
            print("Date field is empty!")
            setViewBorderToRed(expenseDateField)
            showFormIncompleteAlert()
            return false
        }
        
        if expenseCategoryField.text!.isEmpty {
            print("Category field is empty!")
            setViewBorderToRed(expenseCategoryField)
            showFormIncompleteAlert()
            return false
        }
        
        if expenseField.text!.isEmpty {
            print("Expense field is empty")
            setViewBorderToRed(expenseField)
            showFormIncompleteAlert()
            return false
        }
        
        if expenseDescriptionView.text.isEmpty {
            print("Expense description is empty!")
            setViewBorderToRed(expenseDescriptionView)
            showFormIncompleteAlert()
            return false
        }
        
        return true
    }
    
    func resetAllFormInputBorders() {
        setViewBorderToDefault(expenseDateField)
        setViewBorderToDefault(expenseCategoryField)
        setViewBorderToDefault(expenseField)
        setViewBorderToDefault(expenseDescriptionView)
    }
    
    func showFormIncompleteAlert() {
        // create the alert
        let alert = UIAlertController(title: "Please complete the form.", message: "", preferredStyle: UIAlertController.Style.alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    func setViewBorderToDefault(_ view: UIView) {
        view.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
    }
    
    func setViewBorderToRed(_ view: UIView) {
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0).cgColor
    }
    
    func ToolbarPiker(mySelect : Selector) -> UIToolbar {
        
        let toolBar = UIToolbar()
        
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor.black
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: mySelect)
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        toolBar.setItems([ spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        return toolBar
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDatePicker()
        setupCategoryPicker()
        
        setupDateField()
        setupCategoryField()
        
        setDescriptionViewBorder()
    }
    
    func setupCategoryField() {
        // Creates done button for expense category field input
        let categoryPickerToolBar = ToolbarPiker(mySelect: #selector(self.dismissCategoryPicker))
        
        expenseCategoryField.inputAccessoryView = categoryPickerToolBar
        expenseCategoryField.inputView = categoryPicker
    }
    
    func setupDateField() {
        // Creates done button for expense date field input
        let datePickerToolBar = ToolbarPiker(mySelect: #selector(self.dismissDatePicker))
        
        expenseDateField.inputAccessoryView = datePickerToolBar
        expenseDateField.inputView = datePicker
    }
    
    func setupDatePicker() {
        // Set some of UIDatePicker properties
        datePicker.timeZone = NSTimeZone.local
        datePicker.datePickerMode = .date
        datePicker.backgroundColor = UIColor.white
    }
    
    func setupCategoryPicker() {
        // Sets data input to categoryPicker
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        
        categoryPicker.backgroundColor = UIColor.white
    }
    
    func setDescriptionViewBorder() {
        // Set border of this TextView to match the default border of TextField
        expenseDescriptionView.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        expenseDescriptionView.layer.borderWidth = 1.0
        expenseDescriptionView.layer.cornerRadius = 5
    }
    
    @objc func dismissCategoryPicker() {
        expenseCategoryField.text = expenseCategories[categoryPicker.selectedRow(inComponent: 0)]
        
        view.endEditing(true)
    }
    
    @objc func dismissDatePicker() {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy/MM/dd"
        
        expenseDateField.text = formatter.string(for: datePicker.date)
        
        view.endEditing(true)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return expenseCategories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return expenseCategories[row]
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
