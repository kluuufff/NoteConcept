import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var notesTableView: UITableView!
    @IBOutlet weak var newNoteTextView: UITextView!
    @IBOutlet weak var noNotesLabel: UILabel!
    @IBOutlet weak var rollUpCellsButton: UIButton!
    @IBOutlet weak var addNewNoteButton: UIButton!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var searchNotesBar: UISearchBar!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    

    private var notesArray: [NSManagedObject] = []
    private var dateArray: [NSManagedObject] = []
    private var searchNotes: [NSManagedObject] = []
    private var activityViewController: UIActivityViewController? = nil
    private let formatDate = DateFormatter()
    private let toolbar = UIToolbar()
    private var myId = 0
    
    
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
        
        notesTableView.setContentOffset(CGPoint.init(x: 0, y: 44), animated: false)
        
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
    
    @IBAction func addNewNoteButtonAction(_ sender: UIButton) {
        newNoteTextView.isHidden = false
        sender.isHidden = true
        rollUpCellsButton.isHidden = true
        notesTableView.isHidden = true
        noNotesLabel.isHidden = true
        newNoteTextView.becomeFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        if let newText = newNoteTextView.text {
            formatDate.dateFormat = "dd.MM.yy, HH:mm"
            let currentDate = formatDate.string(from: Date())
            formatDate.dateFormat = "dd.MM.yy, HH:mm:ss"
            let fullCurrentDate = formatDate.string(from: Date())
            if newText != "" {
                myId += 1
                self.save(id: myId, note: newText, date: currentDate, formData: fullCurrentDate)
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
    
    //MARK: - TextView
    
    @objc func doneButtonAction() {
        if let newText = newNoteTextView.text {
            formatDate.dateFormat = "dd.MM.yy, HH:mm"
            let currentDate = formatDate.string(from: Date())
            formatDate.dateFormat = "dd.MM.yy, HH:mm:ss"
            let fullCurrentDate = formatDate.string(from: Date())
            if newText != "" {
                myId += 1
                self.save(id: myId, note: newText, date: currentDate, formData: fullCurrentDate)
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
    
    private var flag = true
    
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
    
    //MARK: - viewWillAppear
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetch()
        
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
    
    //MARK: - Save Notes
    
    private func save(id: Int, note: String, date: String, formData: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let entity_note = NSEntityDescription.entity(forEntityName: "Notes", in: context)
        
        let newNote = NSManagedObject(entity: entity_note!, insertInto: context)
        
        newNote.setValue(id, forKey: "id")
        newNote.setValue(note, forKey: "note")
        newNote.setValue(date, forKey: "date")
        newNote.setValue(formData, forKey: "formatData")
        
        do {
            try context.save()
            notesArray.append(newNote)
            dateArray.append(newNote)
        } catch {
            print("Error")
        }
        notesTableView.reloadData()
    }
    
    //MARK: - Fetch Data
    
    private func fetch() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let request_note = NSFetchRequest<NSManagedObject>(entityName: "Notes")
        request_note.sortDescriptors = [NSSortDescriptor(key: "formatData", ascending: false)]
        
        do {
            notesArray = try context.fetch(request_note)
            dateArray = try context.fetch(request_note)
            notesTableView.reloadData()
        } catch {
            print("Error")
        }
    }
    
    //MARK: - Update Data ...not work
    
    private func update(id: Int, note: String, date: String, formData: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "Notes")
        request.predicate = NSPredicate(format: "id = \(id)")
        do {
            let testNote = try context.fetch(request)
            
            let objectUpdate = testNote[0] as! NSManagedObject
            print("testNote: \(testNote)")
            objectUpdate.setValue(note, forKey: "note")
            objectUpdate.setValue(date, forKey: "date")
            objectUpdate.setValue(formData, forKey: "formatData")
            do {
                try context.save()
                print("saved")
            } catch {
                print("Error save")
            }
        } catch {
            print("Error")
        }
        notesTableView.reloadData()
    }
    
    //MARK: - TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notesArray.count
    }
    
    private var myIndexPath = IndexPath()
    
    //MARK: - Update Button
    
    @IBAction func saveUpdateDataAction(_ sender: UIBarButtonItem) {
        let cell = notesTableView.dequeueReusableCell(withIdentifier: "cell", for: myIndexPath) as! NoteTableViewCell
        formatDate.dateFormat = "dd.MM.yy, HH:mm"
        let currentDate = formatDate.string(from: Date())
        formatDate.dateFormat = "dd.MM.yy, HH:mm:ss"
        let fullCurrentDate = formatDate.string(from: Date())
        update(id: myIndexPath.row, note: cell.newNoteTextView.text, date: currentDate, formData: fullCurrentDate)
    }
    
    //MARK: - cellForRowAt
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        myIndexPath = indexPath
        let cell = notesTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! NoteTableViewCell
        let notes = notesArray[indexPath.row]
        
        
        cell.newNoteTextView?.text = notes.value(forKey: "note") as? String
        let date = dateArray[indexPath.row]
        cell.getCurrentTimeLabel?.text = date.value(forKey: "date") as? String
        cell.newNoteTextView.inputAccessoryView = toolbar
        return cell
    }
    
//    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        view.endEditing(true)
//    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if flag {
            return 65
        } else {
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if flag {
            return true
        } else {
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Удалить") { (action, indexPath) in
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext
            
            context.delete(self.notesArray[indexPath.row])
            context.delete(self.dateArray[indexPath.row])
            
            do {
                try context.save()
                self.notesArray.remove(at: indexPath.row)
                self.dateArray.remove(at: indexPath.row)
                self.notesTableView.deleteRows(at: [indexPath], with: .automatic)
            } catch {
                print("Error")
            }
            if self.notesTableView.visibleCells.isEmpty {
                tableView.beginUpdates()
                self.notesTableView.isHidden = true
                self.noNotesLabel.isHidden = false
                self.rollUpCellsButton.isHidden = true
                tableView.endUpdates()
            }
        }
        
        let share = UITableViewRowAction(style: .normal, title: "Отправить") { (action, indexPath) in
            let notes = self.notesArray[indexPath.row]
            let text = notes.value(forKey: "note") as? String
            self.activityViewController = UIActivityViewController(activityItems: [text ?? "nil"], applicationActivities: nil)
            self.present(self.activityViewController!, animated: true, completion: nil)
        }
        
        share.backgroundColor = .lightGray
        
        return [delete, share]
    }
    
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
            notesArray.removeAll(keepingCapacity: false)
            
            var predicate: NSPredicate = NSPredicate()
            predicate = NSPredicate(format: "note CONTAINS[c] '\(searchText)'")
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let managedObjectContext = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
            fetchRequest.predicate = predicate
            
            do {
                notesArray = try managedObjectContext.fetch(fetchRequest) as! [NSManagedObject]
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
