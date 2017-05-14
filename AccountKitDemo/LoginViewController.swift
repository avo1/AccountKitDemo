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
import FBSDKCoreKit
import FBSDKLoginKit

// MARK: - LoginViewController: UIViewController

final class LoginViewController: UIViewController {

    // MARK: Properties
    fileprivate var accountKit = AKFAccountKit(responseType: AKFResponseType.accessToken)
    fileprivate var dataEntryViewController: AKFViewController? = nil
    fileprivate var showAccountOnAppear = false
    
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var surfConnectLabel: UILabel!
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Account Kit
        showAccountOnAppear = accountKit.currentAccessToken != nil
        dataEntryViewController = accountKit.viewControllerForLoginResume() as? AKFViewController
        
        // Styling
        facebookButton.titleLabel?.addTextSpacing(2.0)
        surfConnectLabel.addTextSpacing(4.0)
        
        // Facebook Login
        
        /* If you want to manually create the FB login button
        // Create the login button
        let loginButton = FBSDKLoginButton()
        loginButton.center = view.center
        loginButton.delegate = self
        view.addSubview(loginButton)
        // Set read permissions
        loginButton.readPermissions = ["public_profile"]
        */
        
        // Check if user is logged in
        if ((FBSDKAccessToken.current()) != nil) {
            presentWithSegueIdentifier("showAccount", animated: false)
        }
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
     // If showAccountOnAppear is true, present the AccountViewController
     // else, prepare and present the dataEntryViewController
        if showAccountOnAppear {
            showAccountOnAppear = false
            presentWithSegueIdentifier("showAccount", animated: animated)
        } else if let vc = dataEntryViewController as? UIViewController {
            present(vc, animated: animated, completion: nil)
            dataEntryViewController = nil
        }
    
        self.navigationController?.isNavigationBarHidden = true
    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    // MARK: Actions
    @IBAction func loginWithPhone(_ sender: UIButton) {
        FBSDKAppEvents.logEvent("loginWithPhone clicked")
        if let vc = accountKit.viewControllerForPhoneLogin() as? AKFViewController {
            prepareDataEntryViewController(vc)
            if let vc = vc as? UIViewController {
                present(vc, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func loginWithEmail(_ sender: UIButton) {
        FBSDKAppEvents.logEvent("loginWithEmail clicked")
        if let vc = accountKit.viewControllerForEmailLogin() as? AKFViewController {
            prepareDataEntryViewController(vc)
            if let vc = vc as? UIViewController {
                present(vc, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func loginWithFacebook(_ sender: UIButton) {
        FBSDKAppEvents.logEvent("loginWithFB clicked")
        
        let readPermissions = ["public_profile", "user_friends"]
        let loginManager = FBSDKLoginManager()
        loginManager.logIn(withReadPermissions: readPermissions, from: self) { (result, error) in
            if ((error) != nil){
                print("login failed with error: \(String(describing: error))")
            } else if (result?.isCancelled)! {
                print("login cancelled")
            } else {
                //present the account view controller
                self.presentWithSegueIdentifier("showAccount",animated: true)
            }
        }
    }
    
    // MARK: Helper Methods
    func prepareDataEntryViewController(_ viewController: AKFViewController) {
        viewController.delegate = self
        
//        viewController.uiManager = AKFSkinManager.init(skinType:
//            AKFSkinType.classic, primaryColor: UIColor.blue,
//                                 backgroundImage: #imageLiteral(resourceName: "bgWave"),
//                                 backgroundTint: AKFBackgroundTint.black, tintIntensity: 0.55)
    }
    
    fileprivate func presentWithSegueIdentifier(_ segueIdentifier: String, animated: Bool) {
        if animated {
            performSegue(withIdentifier: segueIdentifier, sender: nil)
        } else {
            UIView.performWithoutAnimation {
                self.performSegue(withIdentifier: segueIdentifier, sender: nil)
            }
        }
    }
   
}

// MARK: - LoginViewController: AKFViewControllerDelegate
extension LoginViewController: AKFViewControllerDelegate {
    
    func viewController(_ viewController: UIViewController!, didCompleteLoginWith accessToken: AKFAccessToken!, state: String!) {
        presentWithSegueIdentifier("showAccount", animated: true)
    }
    
    func viewController(_ viewController: UIViewController!, didFailWithError error: Error!) {
        print("error: \(error.localizedDescription)")
    }
}

// MARK: - LoginViewController: FBSDKLoginButtonDelegate
extension LoginViewController: FBSDKLoginButtonDelegate {
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let error = error {
            print("error: \(error.localizedDescription)")
        }
        
        // The FBSDKAccessToken is expected to be available, so we can navigate
        // to the account view controller
        if result.token != nil {
            presentWithSegueIdentifier("showAccount", animated: true)
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
    }
}


