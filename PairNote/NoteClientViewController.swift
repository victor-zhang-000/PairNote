//
//  NoteClientViewController.swift
//  PairNote
//
//  Created by 张溢 on 2018/11/11.
//  Copyright © 2018年 z. All rights reserved.
//

import UIKit
import SwiftSocket

class NoteClientViewController: UIViewController {

    var server : UDPServer!
    var client : UDPClient!
    var selfIP : String?
    var partnerIP : String?
    var readingWorkItem: DispatchWorkItem?
    var readingQueue = DispatchQueue(label: "my reading queue2")
    var entryModel : AllEntries = AllEntries()

    
    @IBOutlet weak var contentTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentTableView.delegate = self
        contentTableView.dataSource = self
        
        let textAttributes = [NSAttributedStringKey.foregroundColor:UIColor.red]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonClicked(_:)))
        self.navigationItem.rightBarButtonItem = addBarButton
        
        setupServer()
        startReadingQueue()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.server.close()
    }
    
    @objc func addButtonClicked( _ sender: Any) {
        let alert = UIAlertController(title: "Add a new entry", message: "", preferredStyle: .alert)
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Enter content here"
            textField.delegate = self
        })
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler:  { [weak alert] (_) in
            if let textField = alert?.textFields?[0], let content = textField.text {
                self.client.send(data: PacketTool.share.addEntry(content: content))
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        print(client.send(data: PacketTool.share.pullRequest()))
    }
    
    
    func setupServer(){
        if let ip1 = selfIP, let ip2 = partnerIP {
            server = UDPServer(address: ip1, port: 55600)
            client = UDPClient(address: ip2, port: 55500)
        }
    }
    
    func startReadingQueue() {
        readingWorkItem = DispatchWorkItem {
            guard let item = self.readingWorkItem else { return }
            while !item.isCancelled {
                let (packet, _ , _) = self.server.recv(3202)
                if let bytes = packet{
                    //self.presentAlert(title: "String")
                    let packetType = PacketTool.share.handlePacket(packet: bytes)
                    print(packetType)
                    switch packetType{
                    case .allContent:
                        let myGroup = DispatchGroup()
                        myGroup.enter()
                        let entries = PacketTool.share.readAllContentPacket(packet: bytes)
                        self.entryModel.initList(entries: entries)
                        myGroup.leave()
                        myGroup.notify(queue: DispatchQueue.main) {
                            self.contentTableView.reloadData()
                            self.navigationItem.title = ""
                        }
                        break
                    case .notifyNew:
                        DispatchQueue.main.async {
                            self.navigationItem.title = "New Message"
                        }
                    case .respondRequest:
                        let (id, granted) = PacketTool.share.getRequestResult(packet: bytes)
                        if(granted) {
                            if let entry = self.entryModel.getEntry(id: id) {
                                entry.isLocked = true
                                DispatchQueue.main.async {
                                    self.contentTableView.reloadData()
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.presentAlert(title: "Request Fail", messageStr: "Server is Editing")
                            }
                        }
                        break
                    default: break
                    }
                }
                
            }
        }
        self.readingQueue.async(execute: self.readingWorkItem!)
    }
    
    func presentAlert(title : String, messageStr : String){
        let alert = UIAlertController(title: title, message: messageStr, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    func pressCell(cellNum : Int){
        let entry = entryModel.entryList[cellNum]
        let entryId = entry.identifier
        let entryMessage = entry.content
        
        if(entry.isLocked) {
            let handler = PressCellHandler.share
            
            handler.editAction = {
                let alert = UIAlertController(title: "Edit this entry", message: "", preferredStyle: .alert)
                alert.addTextField(configurationHandler: { (textField) in
                    textField.text = entryMessage
                    textField.delegate = self
                })
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler:  { [weak alert] (_) in
                    if let textField = alert?.textFields?[0], let content = textField.text {
                        //tell server
                        self.client.send(data: PacketTool.share.modifyEntry(id: entryId, content: content))
                        entry.isLocked = false
                    }
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
            
            handler.deleteAction = {
                //tell server
                self.client.send(data: PacketTool.share.deleteEntry(id: entryId))
                entry.isLocked = false
            }
            
            handler.present(from: self, type: .normal)
            
        } else {
            //request access
            let handler = PressCellHandler.share
            handler.requestAction = {
                self.client.send(data: PacketTool.share.requestModify(id : entryId))
            }
            handler.present(from: self, type: .request)
        }
    }

}

extension NoteClientViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entryModel.entryList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContentCellClient")!
        let entry = entryModel.entryList[indexPath.row]
        cell.textLabel?.text = "\(indexPath.row + 1) \(entry.content)"
        if(entry.isLocked) {
            cell.textLabel?.textColor = UIColor.blue
        } else {
            cell.textLabel?.textColor = UIColor.black
        }
        return cell
    }
    
}


extension NoteClientViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        pressCell(cellNum: indexPath.row)
    }
    
}

extension NoteClientViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let count = text.count + string.count - range.length
        return count <= 48
    }
}

