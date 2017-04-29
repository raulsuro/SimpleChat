//
//  ViewController.swift
//  SimpleChat
//
//  Created by Raul on 26/04/2017.
//  Copyright © 2017 Raul. All rights reserved.
//

import UIKit
import Firebase

class UserListViewController: UITableViewController {
    private var users: [User] = []
    private lazy var userRef: FIRDatabaseReference = FIRDatabase.database().reference().child("users")
    private var userRefHandle: FIRDatabaseHandle?
    private var numberOfSelectedRows: Int = 0
    private var indexes: [Int] = []
    private var groupName: String = ""
    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        groupName = ""
        indexes=[]
        self.navigationItem.rightBarButtonItem?.isEnabled = false;

    
        self.tableView.reloadData()
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        users.append(User(id: "1", name: "John Doe", image: "userpic1", selected: false))
        users.append(User(id: "2", name: "María Suarez", image: "userpic2", selected: false))
        users.append(User(id: "3", name: "David Sho", image: "userpic3", selected: false))
        users.append(User(id: "4", name: "Hugo Gorny", image: "userpic4", selected: false))
        users.append(User(id: "5", name: "Laura Perez", image: "userpic5", selected: false))
        groupName = ""
        indexes=[]
        self.tableView.allowsMultipleSelection = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Chat", style: .plain, target: self, action: #selector(goToChat(sender:)))

        FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
            if let err = error {
                print(err.localizedDescription)
                return
            }
        })
        
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
       
        
        if let user = sender as? User {
            let chatVc = segue.destination as! ChatViewController
            //let group = users[0].name + ", " + users[1].name
            print(groupName)
            chatVc.senderDisplayName = groupName
            chatVc.user = user
            chatVc.userRef = userRef.child(user.id)
        }
    }
    
    
    // MARK: UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return 5
    }

    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath)
        
        //cell.textLabel!.text = "User \(indexPath.row)"
        print((indexPath as NSIndexPath).row)
        let user = users[(indexPath as NSIndexPath).row]
        cell.textLabel!.text = user.name
        
        if cell.isSelected
        {
            cell.isSelected = false
            if cell.accessoryType == UITableViewCellAccessoryType.none
            {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            }
            else
            {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
        }
        
        
        cell.imageView!.image = UIImage(named: "profilehim")
        if (indexPath as NSIndexPath).row == 1 || (indexPath as NSIndexPath).row == 4 {
           cell.imageView!.image = UIImage(named: "profileher")
        }
        
       
        
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
            self.indexes.append((indexPath as NSIndexPath).row)
        
        
        print("indexes count: ")
        print(indexes.count)
        
       
//            if index == 0{
//               users[index] = User(id: "1", name: "John Doe", image: "userpic1", selected: true)
//                groupName = groupName+", "+users[index].name
//            }
//            if index == 1{
//                users[index] = User(id: "2", name: "María Suarez", image: "userpic2", selected: true)
//                groupName = groupName+", "+users[index].name
//            }
//            if index == 2{
//                users[index] = User(id: "3", name: "David Sho", image: "userpic3", selected: true)
//                groupName = groupName+", "+users[index].name
//            }
//            if index == 3{
//                users[index] = User(id: "4", name: "Hugo Gorny", image: "userpic4", selected: true)
//                groupName = groupName+", "+users[index].name
//            }
//            if index == 4{
//                users[index] = User(id: "5", name: "Laura Perez", image: "userpic5", selected: true)
//                groupName = groupName+", "+users[index].name
//            }
        
        
            numberOfSelectedRows = numberOfSelectedRows + 1
        if indexes.count > 1
        {
            self.navigationItem.rightBarButtonItem?.isEnabled = true;
        }else{
            self.navigationItem.rightBarButtonItem?.isEnabled = false;
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexes.contains((indexPath as NSIndexPath).row){
            self.indexes = self.indexes.filter {$0 != (indexPath as NSIndexPath).row}
        }
        
        //
        print("indexes count deselected: ")
        print(indexes.count)
        
        if indexes.count > 1
        {
            self.navigationItem.rightBarButtonItem?.isEnabled = true;
        }else{
            self.navigationItem.rightBarButtonItem?.isEnabled = false;
        }
    }
    
    func goToChat(sender: UIBarButtonItem){
        let user = users[indexes[0]]
       // let chatVc = segue.destination as! ChatViewController
        
        //chatVc.senderDisplayName = user.name
        for index in indexes {
            if groupName.isEmpty {
                groupName = users[index].name
            }else{
                groupName = groupName + ", " + users[index].name
            }
        }
        self.performSegue(withIdentifier: "ChatView", sender: user)
    }


}

