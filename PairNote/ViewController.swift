//
//  ViewController.swift
//  PairNote
//
//  Created by 张溢 on 2018/11/11.
//  Copyright © 2018年 z. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var myIPLabel: UILabel!
    @IBOutlet weak var partnerIPTextField: UITextField!
    var ipAddressTool = IPAddressTool.share
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        partnerIPTextField.delegate = self
        if let addr = ipAddressTool.getCurWiFiAddress() {
            myIPLabel.text = addr
        } else {
            print("No WiFi address")
        }
        
        if let partnerAddr = ipAddressTool.getLastFilledPartnerAddress() {
            partnerIPTextField.text = partnerAddr
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func ipValid() -> Bool{
        let partnerIP = partnerIPTextField.text ?? ""
        if (!ipAddressTool.isValidIP(partnerIP) ){
            //alert
            return false
        }
        ipAddressTool.updateIP(ipAddr: partnerIP)
        return true
    }
    
    @IBAction func startServerPressed(_ sender: Any) {
        if (!ipValid()) {
            return
        }
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
        if let controller = storyBoard.instantiateViewController(withIdentifier: "NoteServerViewController") as? NoteServerViewController{
            controller.selfIP = myIPLabel.text
            controller.partnerIP = partnerIPTextField.text
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    @IBAction func startClientPressed(_ sender: Any) {
        if (!ipValid()) {
            return
        }
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
        if let controller = storyBoard.instantiateViewController(withIdentifier: "NoteClientViewController") as? NoteClientViewController{
            controller.selfIP = myIPLabel.text
            controller.partnerIP = partnerIPTextField.text
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    

}

extension ViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        partnerIPTextField.resignFirstResponder()
        return true
    }
}

