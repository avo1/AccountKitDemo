// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit
import AccountKit
import FBSDKLoginKit

// MARK: - AccountViewController: UIViewController

class AccountViewController: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet weak var accountIDLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var accountView: UIStackView!
    @IBOutlet weak var fbNameLabel: UILabel!
    @IBOutlet weak var fbProfileImage: UIImageView!
    
    // MARK: Properties
    fileprivate var accountKit = AKFAccountKit(responseType: AKFResponseType.accessToken)
    
    /// A flag indicating the presence of an AccountKit access token
    fileprivate let isAccountKitLogin: Bool = {
        return AKFAccountKit(responseType: .accessToken).currentAccessToken != nil
    }()
    
    /// A flag indicating the presence of an Facebook SDK access token
    fileprivate let isFacebookLogin: Bool = {
        return FBSDKAccessToken.current() != nil
    }()
    
    // MARK: View Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyStyling()
        
        accountView.isHidden = isFacebookLogin
        
        if isFacebookLogin {
            let graphRequest = FBSDKGraphRequest.init(graphPath: "me", parameters: ["fields": "picture.width(200), name"])
            
            graphRequest?.start(completionHandler: { [weak self] (_, result, error) in
                
                if let error = error {
                    print("error: \(error.localizedDescription)")
                    return
                }
                
                if let result = result as? [String: Any] {
                    if let username = result["name"] as? String {
                        self?.fbNameLabel.text = username
                    }
                    
                    if let pic = result["picture"] as? NSDictionary {
                        let picUrlString = pic.value(forKeyPath: "data.url") as? String
                        
                        // too lazy to add a pod
                        DispatchQueue.global(qos: .userInitiated).async {
                            guard
                                let picUrl = URL(string: picUrlString!),
                                let imageData = NSData(contentsOf: picUrl)
                                else {
                                    return
                            }
                            
                            DispatchQueue.main.async {
                                self?.fbProfileImage.image = UIImage(data: imageData as Data)
                            }
                        }

                    }
                }
            })
            
        }
        
        if isAccountKitLogin {
            accountKit.requestAccount { [weak self] (account, error) in
                if let error = error {
                    self?.accountIDLabel.text = "N/A"
                    self?.titleLabel.text = "Error"
                    self?.valueLabel.text = error.localizedDescription
                } else {
                    self?.accountIDLabel.text = account?.accountID
                    
                    if let emailAddress = account?.emailAddress, emailAddress.characters.count > 0 {
                        self?.titleLabel.text = "Email Address"
                        self?.valueLabel.text = emailAddress
                    } else if let phoneNumber = account?.phoneNumber {
                        self?.titleLabel.text = "Phone Number"
                        self?.valueLabel.text = phoneNumber.stringRepresentation()
                    }
                }
            }
        }
    }
    
    // MARK: Styling
    
    func applyStyling() {
        UIApplication.shared.statusBarStyle = .lightContent
        navigationController?.navigationBar.barTintColor = UIColor(colorLiteralRed: 9/255, green: 212/255, blue: 182/255, alpha: 1.0)
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "Avenir-Heavy", size: 17)!]
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        navigationController?.navigationBar.tintColor = UIColor.white
        
        fbProfileImage.layer.cornerRadius = 50
        fbProfileImage.clipsToBounds = true
    }
    
    
    // MARK: Actions
    
    @IBAction func logout(_ sender: UIButton) {
        if isAccountKitLogin {
            accountKit.logOut()
        } else {
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
        }
        navigationController?.popToRootViewController(animated: true)
    }
    
}
