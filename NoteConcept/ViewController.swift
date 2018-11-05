//
//  ViewController.swift
//  NoteConcept
//
//  Created by Nadiya on 10/25/18.
//  Copyright © 2018 Nadiya. All rights reserved.
//

//MARK: - Import Libraries

import UIKit
import CoreData

//MARK: - Main Class ViewController

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    //MARK: - @IBOutlets
    
    @IBOutlet weak var notesTableView: UITableView!
    @IBOutlet weak var newNoteTextView: UITextView!
    @IBOutlet weak var noNotesLabel: UILabel!
    @IBOutlet weak var rollUpCellsButton: UIButton!
    @IBOutlet weak var addNewNoteButton: UIButton!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var searchNotesBar: UISearchBar!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!

    //MARK: - Variables & Constants

    private var myItems: [Notes] = []
    private var activityViewController: UIActivityViewController? = nil
    private let formatDate = DateFormatter()
    private let toolbar = UIToolbar()
    private var flag = true
    private var isEditState = false
    private var indexPathId = 0
    private var myId = 0
    
    //MARK: - viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //move up textField
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handleKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handleKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        newNoteTextView.layer.borderColor = UIColor.gray.cgColor
        newNoteTextView.layer.borderWidth = 1
        
        //done button above keyboard
        
        toolbar.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneButton = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(doneButtonAction))
        toolbar.setItems([flexibleSpace, doneButton], animated: false)
        newNoteTextView.inputAccessoryView = toolbar
        
        newNoteTextView.delegate = self
        searchNotesBar.delegate = self
        
        notesTableView.tableHeaderView = searchNotesBar
        
//        notesTableView.setContentOffset(CGPoint.init(x: 0, y: 56), animated: false)
        
    }
    
    //MARK: - viewWillAppear
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetch()
        myId = myItems.first?.id as! Int
        
        //hide empty cells
        if notesTableView.visibleCells.isEmpty {
            notesTableView.isHidden = true
            noNotesLabel.isHidden = false
            rollUpCellsButton.isHidden = true
        } else {
            notesTableView.isHidden = false
            noNotesLabel.isHidden = true
            rollUpCellsButton.isHidden = false
        }
        notesTableView.tableFooterView = UIView()
    }
    
    //MARK: - Show/Hide keyboard
    
    @objc func handleKeyboard(notification: NSNotification) {
        if let userInfo = notification.userInfo {
        
            guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            let keyboardFrame = keyboardSize.cgRectValue
            
            let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
            bottomConstraint.constant = isKeyboardShowing ? +keyboardFrame.height + 10 : 0
            tableViewBottomConstraint.constant = isKeyboardShowing ? +keyboardFrame.height + 10 : 87
            
            UIView.animate(withDuration: 0, delay: 0, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
                }, completion: { (completed) in
            
            })
        }
    }
    
    //MARK: - Add new note Button
    
    @IBAction func addNewNoteButtonAction(_ sender: UIButton) {
        newNoteTextView.isHidden = false
        sender.isHidden = true
        rollUpCellsButton.isHidden = true
        notesTableView.isHidden = true
        noNotesLabel.isHidden = true
        newNoteTextView.becomeFirstResponder()
    }
    
    //MARK: - Touch for Hide Keyboard
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        if let newText = newNoteTextView.text {
            if newText != "" {
                myId += 1
                self.save()
            }
        }
        if !notesTableView.visibleCells.isEmpty {
            notesTableView.isHidden = false
            noNotesLabel.isHidden = true
            rollUpCellsButton.isHidden = false
        }
        newNoteTextView.text = ""
        newNoteTextView.resignFirstResponder()
        newNoteTextView.isHidden = true
        addNewNoteButton.isHidden = false
    }
    
    //MARK: - Press Done Button for Hide Keyboard
    
    @objc func doneButtonAction() {
        if let newText = newNoteTextView.text {
            if newText != "" {
                myId += 1
                self.save()
            }
        }
        if !notesTableView.visibleCells.isEmpty {
            notesTableView.isHidden = false
            noNotesLabel.isHidden = true
            rollUpCellsButton.isHidden = false
        }
        newNoteTextView.text = ""
        view.endEditing(true)
        newNoteTextView.isHidden = true
        addNewNoteButton.isHidden = false
    }
    
    //MARK: - Roll All Cells Button
    
    @IBAction func rollUpCellsButtonAction(_ sender: UIButton) {
        
        if !flag {
            self.notesTableView.beginUpdates()
            flag = true
            self.notesTableView.endUpdates()
            sender.setTitle("Развернуть все", for: .normal)
        } else {
            self.notesTableView.beginUpdates()
            flag = false
            self.notesTableView.endUpdates()
            sender.setTitle("Свернуть все", for: .normal)
        }
        view.endEditing(true)
    }
    
    //MARK: - Save Notes
    
    private func save() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let myItem = NSEntityDescription.insertNewObject(forEntityName: "Notes", into: context) as! Notes
        
        formatDate.dateFormat = "dd.MM.yy, HH:mm"
        let currentDate = formatDate.string(from: Date())
        print("current data: \(currentDate)")
        
        myItem.note = newNoteTextView.text
        myItem.id = myId as NSNumber
        myItem.date = currentDate
        
        do {
            try context.save()
        } catch {
            print("Error")
        }
        fetch()
        notesTableView.reloadData()
    }
    
    //MARK: - Fetch Data
    
    private func fetch() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Notes")
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            myItems = try context.fetch(fetchRequest) as! [Notes]
            notesTableView.reloadData()
        } catch {
            print("Error")
        }
    }
    
    //MARK: - Update Data ...not work
    
    private func update() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let note = myItems[indexPathId] as NSManagedObject
        
        note.setValue(newNoteTextView.text, forKey: "note")
        
        do {
            try context.save()
            notesTableView.reloadData()
        } catch {
            print("Error")
        }
    }
    
    //MARK: - Update Button
    
    @IBAction func saveUpdateDataAction(_ sender: UIBarButtonItem) {
        
        if isEditState {
            update()
            if !notesTableView.visibleCells.isEmpty {
                notesTableView.isHidden = false
                noNotesLabel.isHidden = true
                rollUpCellsButton.isHidden = false
            }
            view.endEditing(true)
            newNoteTextView.isHidden = true
            addNewNoteButton.isHidden = false
            isEditState = false
        } else {
            let alert = UIAlertController(title: "Ошибка!", message: "Заметка не выбрана!", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        }
        
    }
    
    //MARK: - TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myItems.count
    }
    
    //MARK: - cellForRowAt
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = notesTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! NoteTableViewCell
        
        cell.textLabel?.text = myItems[indexPath.row].note
        cell.getCurrentTimeLabel.text = myItems[indexPath.row].date

        return cell
    }
    
    //MARK: - heightForRowAt
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if flag {
            return 44
        } else {
            return UITableView.automaticDimension
        }
    }
    
    //MARK: - canEditRowAt
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if flag {
            return true
        } else {
            return false
        }
    }
    
    //MARK: - Added Share Actions
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Удалить") { (action, indexPath) in
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext
            
            context.delete(self.myItems[indexPath.row])
            
            do {
                try context.save()
                self.myItems.remove(at: indexPath.row)
                self.notesTableView.deleteRows(at: [indexPath], with: .automatic)
            } catch {
                print("Error")
            }
            if self.notesTableView.visibleCells.isEmpty {
                self.myId = 0
                self.notesTableView.isHidden = true
                self.noNotesLabel.isHidden = false
                self.rollUpCellsButton.isHidden = true
            }
        }
        
        let share = UITableViewRowAction(style: .normal, title: "Отправить") { (action, indexPath) in
            let notes = self.myItems[indexPath.row]
            let text = notes.value(forKey: "note") as? String
            self.activityViewController = UIActivityViewController(activityItems: [text ?? "nil"], applicationActivities: nil)
            self.present(self.activityViewController!, animated: true, completion: nil)
        }
        
        share.backgroundColor = .lightGray
        
        return [delete, share]
    }
    
    //MARK: - Edit Row
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        isEditState = true
        indexPathId = indexPath.row
        newNoteTextView.text = myItems[indexPathId].note
        addNewNoteButton.isHidden = true
        newNoteTextView.isHidden = false
        rollUpCellsButton.isHidden = true
        notesTableView.isHidden = true
        noNotesLabel.isHidden = true
        newNoteTextView.becomeFirstResponder()
        
    }
    
    //MARK: - Deinit NSCenter
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

//MARK: - Resizable TextView

extension ViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if newNoteTextView.contentSize.height < textViewHeight.constant {
            newNoteTextView.isScrollEnabled = false
        } else {
            newNoteTextView.isScrollEnabled = true
        }
        return true
    }
}

//MARK: - SearchBar

extension ViewController: UISearchBarDelegate, UISearchDisplayDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            myItems.removeAll(keepingCapacity: false)
            
            var predicate: NSPredicate = NSPredicate()
            predicate = NSPredicate(format: "note CONTAINS[c] '\(searchText)'")
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let managedObjectContext = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
            fetchRequest.predicate = predicate
            
            do {
                myItems = try managedObjectContext.fetch(fetchRequest) as! [Notes]
            } catch {
                print("Error")
            }
        
            notesTableView.reloadData()
        } else {
            fetch()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        searchNotesBar.text = ""
//        fetch()
        searchNotesBar.resignFirstResponder()
//        notesTableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchNotesBar.text = ""
        fetch()
        searchNotesBar.endEditing(true)
        notesTableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchNotesBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchNotesBar.setShowsCancelButton(false, animated: true)
    }
    
}
