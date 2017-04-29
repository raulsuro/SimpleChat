//
//  ChatViewController.swift
//  SimpleChat
//
//  Created by Raul on 26/04/2017.
//  Copyright © 2017 Raul. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import JSQMessagesViewController
import Photos

final class ChatViewController: JSQMessagesViewController {
    
    // MARK: Properties
    var userRef: FIRDatabaseReference?
    var user: User? {
        didSet {
            title = senderDisplayName
        }
    }
    
    var messages = [JSQMessage]()
    
    var timer = Timer()
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    lazy var storageRef: FIRStorageReference = FIRStorage.storage().reference(forURL: "gs://simplechat-70c6f.appspot.com")

    private let imageURLNotSetKey = "NOTSET"
    private var photoMessageMap = [String: JSQPhotoMediaItem]()
    private var updatedMessageRefHandle: FIRDatabaseHandle?
    
    private lazy var messageRef: FIRDatabaseReference = self.userRef!.child("messages")
    private var newMessageRefHandle: FIRDatabaseHandle?
    
    // MARK: Navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        super.prepare(for: segue, sender: sender)
//        
//        if let user = sender as? User {
//            let chatVc = segue.destination as! ChatViewController
//            
//            chatVc.senderDisplayName = senderDisplayName
//            chatVc.user = user
//            chatVc.channelRef = channelRef?.child(user.id)
//        }
//    }
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.senderId = FIRAuth.auth()?.currentUser?.uid

        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        observeMessages()
        scheduledTimerWithTimeInterval()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    func scheduledTimerWithTimeInterval(){
        timer = Timer.scheduledTimer(timeInterval: 6, target: self, selector: #selector(self.receiveMessages), userInfo: nil, repeats: true)
    }
    
    func receiveMessages(){
        addMessage(withId: "test", name: "Mr John", text: "Hello there!")
        addMessage(withId: "test2", name: "Mrs Eve", text: "Hello sir. How are you?")
        let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: true)
        addPhotoMessage(withId: "photo1", key: "1", mediaItem: mediaItem!)
        finishReceivingMessage()
    }
    
    private func addMessage(withId id: String, name: String, text: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
        }
    }
    
    private func addPhotoMessage(withId id: String, key: String, mediaItem: JSQPhotoMediaItem) {
        if let message = JSQMessage(senderId: id, displayName: "", media: mediaItem) {
            messages.append(message)
            
            if (mediaItem.image == nil) {
                photoMessageMap[key] = mediaItem
            }
            
            collectionView.reloadData()
        }
    }
    
    private func fetchImageDataAtURL(_ photoURL: String, forMediaItem mediaItem: JSQPhotoMediaItem, clearsPhotoMessageMapOnSuccessForKey key: String?) {
        // 1
        let storageRef = FIRStorage.storage().reference(forURL: photoURL)
        
        // 2
        storageRef.data(withMaxSize: INT64_MAX){ (data, error) in
            if let error = error {
                print("Error downloading image data: \(error)")
                return
            }
            
            // 3
            storageRef.metadata(completion: { (metadata, metadataErr) in
                if let error = metadataErr {
                    print("Error downloading metadata: \(error)")
                    return
                }
                
                // 4
//                if (metadata?.contentType == "image/gif") {
//                    mediaItem.image = UIImage.gif(data!)
//                } else {
                    mediaItem.image = UIImage.init(data: data!)
                //}
                self.collectionView.reloadData()
                
                // 5
                guard key != nil else {
                    return
                }
                self.photoMessageMap.removeValue(forKey: key!)
            })
        }
    }
    
    func sendPhotoMessage() -> String? {
        let itemRef = messageRef.childByAutoId()
        
        let messageItem = [
            "photoURL": imageURLNotSetKey,
            "senderId": senderId!,
            ]
        
        itemRef.setValue(messageItem)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        return itemRef.key
    }
    
    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
        let itemRef = messageRef.child(key)
        itemRef.updateChildValues(["photoURL": url])
    }
    
    override func didPressAccessoryButton(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = (self as! UIImagePickerControllerDelegate & UINavigationControllerDelegate)
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            picker.sourceType = UIImagePickerControllerSourceType.camera
        } else {
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        }
        
        present(picker, animated: true, completion:nil)
    }
    
    // MARK: Collection view data source (and related) methods
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    
    // MARK: Firebase related methods
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let itemRef = messageRef.childByAutoId() // 1
        let messageItem = [ // 2
            "senderId": senderId!,
            "senderName": senderDisplayName!,
            "text": text!,
            ]
        
        itemRef.setValue(messageItem) // 3
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4
        
        finishSendingMessage() // 5
    }
    
    
    
    // MARK: UI and User Interaction
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
    }
    
    private func observeMessages() {
        messageRef = userRef!.child("messages")
     
        let messageQuery = messageRef.queryLimited(toLast:30)
        
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
           
            let messageData = snapshot.value as! [String:AnyObject]
            
            if let id = messageData["senderId"] as! String!, let name = messageData["senderName"] as! String!, let text = messageData["text"] as! String!, text.characters.count > 0 {
            
                self.addMessage(withId: id, name: name, text: text)
                
         
                self.finishReceivingMessage()
                
            }else if let id = messageData["senderId"] as! String!,let photoURL = messageData["photoURL"] as! String! {
                    if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {
                        self.addPhotoMessage(withId: id, key: snapshot.key, mediaItem: mediaItem)
                        if photoURL.hasPrefix("gs://") {
                            self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                        }
                    }
                }
              else {
                print("Error! Could not decode message data")
            }
        })
            // We can also use the observer method to listen for
                // changes to existing messages.
                // We use this to be notified when a photo has been stored
                // to the Firebase Storage, so we can update the message data
                updatedMessageRefHandle = messageRef.observe(.childChanged, with: { (snapshot) in
                    let key = snapshot.key
                    let messageData = snapshot.value as! [String:AnyObject]
                    
                    if let photoURL = messageData["photoURL"] as! String! { // 2
                        // The photo has been updated.
                        if let mediaItem = self.photoMessageMap[key] { // 3
                            self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key) // 4
                        }
                    }
                })
    }
    
    
    // MARK: UITextViewDelegate methods
    
    deinit {
        if let refHandle = newMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
        
        if let refHandle = updatedMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
    }
    
}

// MARK: Image Picker Delegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true, completion:nil)
        
       
        if let photoReferenceUrl = info[UIImagePickerControllerReferenceURL] as? URL {
            // Handle picking a Photo from the Photo Library
            
            let assets = PHAsset.fetchAssets(withALAssetURLs: [photoReferenceUrl], options: nil)
            let asset = assets.firstObject
            
            
            if let key = sendPhotoMessage() {
                
                asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
                    let imageFileURL = contentEditingInput?.fullSizeImageURL
                   
                    
                    let path = "\(String(describing: FIRAuth.auth()?.currentUser?.uid))/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(photoReferenceUrl.lastPathComponent)"
                    
                    
                    self.storageRef.child(path).putFile(imageFileURL!, metadata: nil) { (metadata, error) in
                        if let error = error {
                            print("Error uploading photo: \(error.localizedDescription)")
                            return
                        }
                        
                        self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                    }
                })
            }
        } else {
            // Handle picking a Photo from the Camera
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            if let key = sendPhotoMessage() {
                let imageData = UIImageJPEGRepresentation(image, 1.0)
                let imagePath = FIRAuth.auth()!.currentUser!.uid + "https://koenig-assets.raywenderlich.com/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
                let metadata = FIRStorageMetadata()
                metadata.contentType = "image/jpeg"
                storageRef.child(imagePath).put(imageData!, metadata: metadata) { (metadata, error) in
                    if let error = error {
                        print("Error uploading photo: \(error)")
                        return
                    }
                    self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }
}
