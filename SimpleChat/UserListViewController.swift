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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        users.append(User(id: "1", name: "User1", image: "userpic1"))
        users.append(User(id: "2", name: "User2", image: "userpic2"))
        users.append(User(id: "3", name: "User3", image: "userpic3"))
        users.append(User(id: "4", name: "User4", image: "userpic4"))
        users.append(User(id: "5", name: "User5", image: "userpic5"))

        self.tableView.reloadData()
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in // 2
            if let err = error { // 3
                print(err.localizedDescription)
                return
            }
        })
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { // 2
            return 5
    }

    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath)
        
        cell.textLabel?.text = "user1"
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            //let user = users[(indexPath as NSIndexPath).row]
            //self.performSegue(withIdentifier: "ShowChat", sender: user)
    }


}

