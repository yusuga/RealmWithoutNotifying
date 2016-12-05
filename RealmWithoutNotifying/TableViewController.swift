//
//  TableViewController.swift
//  RealmWithoutNotifying
//
//  Created by Yu Sugawara on 12/5/16.
//  Copyright © 2016 Yu Sugawara. All rights reserved.
//

import UIKit
import RealmSwift

class TableViewController: UITableViewController {
    
    let list: DemoList
    var notificationToken: NotificationToken?
    
    required init?(coder aDecoder: NSCoder) {
        let realm = try! Realm()
        list = realm.object(ofType: DemoList.self, forPrimaryKey: DemoList.defaultID) ?? {
            let list = DemoList()
            try! realm.write {
                realm.add(list)
            }
            return list
        }()
        
        super.init(coder: aDecoder)
        
        notificationToken = list.objects.addNotificationBlock { [weak self] (changes) in
            guard let strongSelf = self,
                strongSelf.isViewLoaded,
                let tableView = strongSelf.tableView else { return }
            
            switch changes {
            case .initial:
                break
            case .update(_, let deletions, let insertions, let modifications):
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
                                     with: .automatic)
                tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.endUpdates()
                
                print("insertions: \(insertions)\ndeletions: \(deletions)\nmodifications: \(modifications)")
            case .error(let error):
                fatalError("\(error)")
                break
            }
        }
        
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    deinit {
        notificationToken?.stop()
    }
    
    @IBAction func addObject() {
        let realm = try! Realm()
        try! realm.write {
            let maxID: Int = {
                guard let object = realm.objects(DemoObject.self).sorted(byProperty: "id", ascending: false).first else {
                    return 1
                }
                return object.id + 1
            }()
            list.objects.insert(DemoObject(value: ["id": maxID]),
                                at: 0)
        }
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.objects.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let object = list.objects[indexPath.row]
        cell.textLabel?.text = String(object.id)
        cell.detailTextLabel?.text = dateFormatter.string(from: object.date)

        return cell
    }
    
    // MARK: セルの移動
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let realm = try! Realm()
        
        realm.beginWrite()
        list.objects.move(from: sourceIndexPath.row, to: destinationIndexPath.row) // モデルオブジェクトの移動
        try! realm.commitWrite(withoutNotifying: [notificationToken!]) // 指定の通知をスキップしコミット
        
        tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath) // UI更新
    }
    
    // MARK: セルの削除
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let realm = try! Realm()
            
            try! realm.write {
                realm.delete(list.objects[indexPath.row])
            }
        }    
    }
    
    // MARK: Util
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
    
}
