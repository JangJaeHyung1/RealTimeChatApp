//
//  ProfileViewController.swift
//  Messenger
//
//  Created by jh on 2021/03/01.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import SDWebImage

final class ProfileViewController: UIViewController {

    @IBOutlet var tableView : UITableView!
    
    var data = [ProfileViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        
        data.removeAll()
        
        data.append(ProfileViewModel(viewModelType: .info, title: "이름: \(UserDefaults.standard.value(forKey: "name") as? String ?? "no name")", handler: nil))
        data.append(ProfileViewModel(viewModelType: .info, title: "이메일: \(UserDefaults.standard.value(forKey: "email") as? String ?? "no email")", handler: nil))
        data.append(ProfileViewModel(viewModelType: .logout, title: "로그아웃", handler: { [weak self] in
            
            let actionSheet = UIAlertController.init(title: "", message: "", preferredStyle: .actionSheet)
            
            actionSheet.addAction(UIAlertAction.init(title: "로그아웃", style: .destructive, handler: { [weak self]
                (action) in
                guard let strongSelf = self else{
                    return
                }
                
                UserDefaults.standard.setValue(" ", forKey: "email")
                UserDefaults.standard.setValue(" ", forKey: "name")
                
                // Google Log out
                GIDSignIn.sharedInstance()?.signOut()
                
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    
                    let vc = LoginViewController()
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    
                    
                    strongSelf.present(nav, animated: true, completion: nil)
                    
                } catch  {
                    print("Failed to log out")
                }
            }))
            
            actionSheet.addAction(UIAlertAction.init(title: "취소", style: .cancel, handler: nil))
            
            self?.present(actionSheet, animated: true, completion: nil)
        }))
        
        
        
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.tableHeaderView = createTableHeader()
        
        data[0] = (ProfileViewModel(viewModelType: .info, title: "이름: \(UserDefaults.standard.value(forKey: "name") as? String ?? "no name")", handler: nil))
        data[1] = (ProfileViewModel(viewModelType: .info, title: "이메일: \(UserDefaults.standard.value(forKey: "email") as? String ?? "no email")", handler: nil))
      
        tableView.reloadData()
    }
    func createTableHeader() -> UIView? {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        
        let path = "images/" + fileName
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: 300))
        
//        headerView.backgroundColor = .link
        
        let imageView = UIImageView(frame: CGRect(x: (view.width - 200)/2, y: 50, width: 200, height: 200))
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.backgroundColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.systemGray6.cgColor
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width/2
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadURL(for: path) { [weak self] (result) in
            switch result {
            case .success(let url):
                self?.downloadImage(imageView: imageView, url: url)
                print("성공햇냐?")
            case .failure(let error):
                print("실패햇냐?")
                print("failed to get download url: \(error)")
            }
        }
        return headerView
    }
    
    func downloadImage(imageView: UIImageView, url: URL){
        imageView.sd_setImage(with: url, completed: nil)
    }
    
    
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        cell.setUp(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        data[indexPath.row].handler?()
    }
    
}

class ProfileTableViewCell: UITableViewCell {
    
    static let identifier = "ProfileTableViewCell"
    
    public func setUp(with viewModel: ProfileViewModel){
        
        textLabel?.text = viewModel.title
        
        switch viewModel.viewModelType {
        case .info:
            textLabel?.textAlignment = .left
            selectionStyle = .none
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
        }
    }
}
