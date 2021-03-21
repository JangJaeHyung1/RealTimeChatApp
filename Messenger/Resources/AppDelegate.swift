//
//  AppDelegate.swift
//  Messenger
//
//  Created by jh on 2021/03/01.
//

import UIKit
import Firebase
import GoogleSignIn

@main
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            if let error = error{
                print("Failed to sign in whith Google: \(error)")
            }
            
            return
        }
        guard let user = user else{
            return
        }
        print("Did sign in with Google : \(user)")
        
        guard let email = user.profile.email,
              let firstName = user.profile.givenName,
              let lastName = user.profile.familyName else {
            return
        }
        
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
        
        DatabaseManager.shared.userExists(with: email) { (exists) in
            if !exists{
                //insert database
                let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                DatabaseManager.shared.insertUser(with: chatUser, completion:{ success in
                    if success{
                        // upload Image
                        
                        if user.profile.hasImage{
                            guard let url = user.profile.imageURL(withDimension: 200) else{
                                return
                            }
                            
                            URLSession.shared.dataTask(with: url) { (data, _, _) in
                                guard let data = data else{
                                    return
                                }
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { (result) in
                                    switch result {
                                    case .success(let downloadUrl):
                                        //다운로드URL을 디스크에 저장, 싱글톤으로 불러온다.(캐쉬개념)
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case.failure(let error):
                                        print("Storage manager error: \(error)")
                                    }
                                }
                            }.resume()
                            
                            
                        }
                        
                        
                    }
                    
                })
            }
        }
        
        
        guard let authentication = user.authentication else {
            print("Missing auth object off of Google user")
            return
        }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        
        FirebaseAuth.Auth.auth().signIn(with: credential) { (authDataResult, error) in
            guard authDataResult != nil, error == nil else{
                print("failed to log in with Google credential")
                return
            }
            
            print("Successfully signed in with Google cred")
            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
        }
    }
    
    
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
        print("Google user was disconnenct")
    }
    
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
    -> Bool {
        return GIDSignIn.sharedInstance().handle(url)
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
        
        // Override point for customization after application launch.
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
}

