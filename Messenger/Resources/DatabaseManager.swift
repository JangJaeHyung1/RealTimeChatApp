//
//  DatabaseManager.swift
//  Messenger
//
//  Created by jh on 2021/03/04.
//

import Foundation
import FirebaseDatabase
import MessageKit


final class DatabaseManager{
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}


extension DatabaseManager {
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void ) {
        self.database.child("\(path)").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}




// MARK: - Accoun Management

extension DatabaseManager{
    
    
    
    public func userExists(with email: String,
                           completion: @escaping((Bool) -> Void)) {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.value as? String != nil else{
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// Inserts new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping(Bool) -> Void){
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ]) { (error, databaseRef) in
            guard error == nil else{
                print("failed to write to datebase")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value) { (snapshot) in
                if var usersCollection = snapshot.value as? [[String: String]]{
                    //append to user dictionoary
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    
                    self.database.child("users").setValue(usersCollection) { (error, _) in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
                else{
                    //create that arry
                    let newCollection:[[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    
                    self.database.child("users").setValue(newCollection) { (error, _) in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                    
                }
            }
//            completion(true)
        }
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void ){
        database.child("users").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public enum DatabaseError: Error{
        case failedToFetch
    }
    
}


//MARK: - Sending Message / conversation

extension DatabaseManager{
    
    /// Creates a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentUserName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind{
            
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversation: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipientNewConversation: [String: Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentUserName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            //Update recipient conversation entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self](snapshot) in
                if var conversations = snapshot.value as?  [[String: Any]] {
                    //append
                    conversations.append(recipientNewConversation)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }
                else{
                    //create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipientNewConversation])
                }
            }
            
            //Update current user
            if var conversations = userNode["conversations"] as? [[String: Any]]{
                //conversation array exists for current user
                //you should append
                
                conversations.append(newConversation)
                userNode["conversations"] = conversations
                ref.setValue(userNode) { [weak self] (error, _) in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                    
                }
                
            }else{
                //conversation array does no exist
                //creat it
                userNode["conversations"] = [
                    newConversation
                ]
                ref.setValue(userNode) { [weak self] (error, _) in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                    
                }
                
            }
        }
    }
    
    private func finishCreatingConversation(name: String, conversationId: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
//        {
//            "id": String,
//            "type": text, photo, video,
//            "content": String,
//            "date": Date(),
//            "sender_email": String,
//            "isRead": Bool
//        }
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        switch firstMessage.kind{
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collcetionMessage: [String: Any] = [
            "name": name,
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false
        ]
        
        let value: [String: Any] = [
            "messages": [
                collcetionMessage
            ]
        ]
        
        print("add conversation, id : \(conversationId)")
        
        database.child("\(conversationId)").setValue(value) { (error, _) in
            guard error == nil else{
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    
    /// Fetches and returns all conversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation],Error>) -> Void){
        database.child("\(email)/conversations").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else {
                    return nil
                }
                let latestMessageObject = LatestMessage(date: date,
                                                        text: message,
                                                        isRead: isRead)
                return Conversation(id: conversationId,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
            })
            completion(.success(conversations))
        }
    }
    
    /// Gets all message for a given conversation
    public func getAllMessageForConversation(with id: String, completion: @escaping (Result<[Message],Error>) -> Void){
        database.child("\(id)/messages").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageId = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else{
                    return nil
                }
                
                var kind: MessageKind?
                
                if type == "photo" {
                    guard let imageUrl = URL(string: content),
                          let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Meida(url: imageUrl, image: nil , placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                }
                
                else if type == "video" {
                    guard let videoUrl = URL(string: content),
                          let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Meida(url: videoUrl, image: nil , placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                }
                
                else{
                    kind = .text(content)
                }
                
                guard let finalKind = kind else{
                    return nil
                }
                
                
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: finalKind)
                      
            })
            completion(.success(messages))
        }
    }
    
    /// Send a Message with target conversation and message
    public func sendMessage(to conversationId: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void){
        // add new message
        // update sender latest message
        // update recipient latest message
        
        database.child("\(conversationId)/messages").observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let strongSelf = self else{
                return
            }
            guard var currentMessages = snapshot.value as? [[String: Any]] else{
                completion(false)
                return
            }
            
            // add new message
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            switch newMessage.kind{
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
            
            let newMessageEntry: [String: Any] = [
                "name": name,
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false
            ]
            currentMessages.append(newMessageEntry)
            
            strongSelf.database.child("\(conversationId)/messages").setValue(currentMessages) { (error, _) in
                guard error == nil else{
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(currentUserEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else{
                        completion(false)
                        return
                    }
                    
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]
                    
                    var targetConversation: [String: Any]?
                    var position = 0
                    
                    for conversationDictionary in currentUserConversations {
                        if let currentId = conversationDictionary["id"] as? String, currentId == conversationId {
                            targetConversation = conversationDictionary
                            break
                        }
                        position += 1
                    }
                    
                    targetConversation?["latest_message"] = updatedValue
                    guard let finalConversation = targetConversation else {
                        completion(false)
                        return
                    }
                    
                    currentUserConversations[position] = finalConversation
                    strongSelf.database.child("\(currentUserEmail)/conversations").setValue(currentUserConversations) { (error, _) in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        
                        
                        // Update latest message for recipient user
                        
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
                            guard var otherUserConversations = snapshot.value as? [[String: Any]] else{
                                completion(false)
                                return
                            }
                            
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]
                            
                            var targetConversation: [String: Any]?
                            var position = 0
                            
                            for conversationDictionary in otherUserConversations {
                                if let currentId = conversationDictionary["id"] as? String, currentId == conversationId {
                                    targetConversation = conversationDictionary
                                    break
                                }
                                position += 1
                            }
                            
                            targetConversation?["latest_message"] = updatedValue
                            guard let finalConversation = targetConversation else {
                                completion(false)
                                return
                            }
                            
                            otherUserConversations[position] = finalConversation
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations) { (error, _) in
                                guard error == nil else{
                                    completion(false)
                                    return
                                }
                                completion(true)
                            }
                        }
                    }
                }
            }
        }
    }
}




struct ChatAppUser{
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail:String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String{
        return "\(safeEmail)_profile_picture.png"
    }
}
