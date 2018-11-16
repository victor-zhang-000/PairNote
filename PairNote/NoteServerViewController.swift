//
//  NoteViewController.swift
//  PairNote
//
//  Created by 张溢 on 2018/11/11.
//  Copyright © 2018年 z. All rights reserved.
//

import UIKit
import SwiftSocket

class NoteServerViewController: UIViewController {

    var server : UDPServer!
    var client : UDPClient!
    var selfIP : String?
    var partnerIP : String?
    var readingWorkItem: DispatchWorkItem?
    var readingQueue = DispatchQueue(label: "my reading queue")
    var entryModel : AllEntries = AllEntries()
    
    @IBOutlet weak var contentTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentTableView.delegate = self
        contentTableView.dataSource = self
        setupServer()
        startReadingQueue()
        
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonClicked(_:)))
        self.navigationItem.rightBarButtonItem = addBarButton
        
    }

    @objc func addButtonClicked( _ sender: Any) {
        let alert = UIAlertController(title: "Add a new entry", message: "", preferredStyle: .alert)
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Enter content here"
        })
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler:  { [weak alert] (_) in
            //print("Text field: \(textField?.text)")
            if let textField = alert?.textFields?[0], let content = textField.text {
                //self.addNewEntry(content)
                self.entryModel.add(content: content, completion: {
                    self.contentTableView.reloadData()
                    self.client.send(data: PacketTool.share.notifyNewPacket())
                })
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sendMessage(_ sender: Any) {
//        let str = "Hello"
//        client.send(data: Array(str.utf8))
        //print(PacketTool.share.allContent(entries: entryModel.entryList).count)
        client.send(data: PacketTool.share.allContent(entries: entryModel.entryList))
    }
    
    func setupServer(){
        //print("self IP: " + selfIP!)
        //print("partner IP: " + partnerIP!)
        if let ip1 = selfIP, let ip2 = partnerIP {
            server = UDPServer(address: ip1, port: 55500)
            client = UDPClient(address: ip2, port: 55600)
        }
    }
    
    func startReadingQueue() {
        
        readingWorkItem = DispatchWorkItem {
            guard let item = self.readingWorkItem else { return }
            
            while !item.isCancelled {
                let (packet, _ , _) = self.server.recv(3202)
                if let bytes = packet{
                    //self.presentAlert()
                    let packetType = PacketTool.share.handlePacket(packet: bytes)
                    print(packetType)
                    switch packetType{
                    case .pull:
                        self.client.send(data: PacketTool.share.allContent(entries: self.entryModel.entryList))
                        break
                    case .requestModify:
                        let (granted, id, sendPacket) = PacketTool.share.handleRequest(entryModel: self.entryModel, packet: bytes)
                        if(granted) {
                            if let entry = self.entryModel.getEntry(id: id) {
                                entry.isLocked = true
                                DispatchQueue.main.async {
                                    self.contentTableView.reloadData()
                                }
                            }
                        }
                        self.client.send(data: sendPacket)
                        break
                    case .entryAdd:
                        let content = PacketTool.share.getPacketContent(packet: bytes)
                        self.entryModel.add(content: content, completion: {
                            //send dated one, why?
                            //print("sending")
                            self.client.send(data: PacketTool.share.allContent(entries: self.entryModel.entryList))
                            //print("sent")
                            DispatchQueue.main.async {
                                self.contentTableView.reloadData()
                            }
                        })
                    case .entryModify:
                        let (entryId, entryContent) = PacketTool.share.getModifyPacket(packet: bytes)
                        if let entry = self.entryModel.getEntry(id: entryId), entry.isLocked == true{
                            self.entryModel.edit(id: entryId, newContent: entryContent, completion: {
                                self.client.send(data: PacketTool.share.allContent(entries: self.entryModel.entryList))
                                DispatchQueue.main.async {
                                    entry.isLocked = false
                                    self.contentTableView.reloadData()
                                }
                            })
                        }
                        break
                    case .entryDelete:
                        let entryId = PacketTool.share.getPacketID(packet: bytes)
                        if let entry = self.entryModel.getEntry(id: entryId), entry.isLocked == true{
                            self.entryModel.remove(id: entryId, completion: {
                                self.client.send(data: PacketTool.share.allContent(entries: self.entryModel.entryList))
                                DispatchQueue.main.async {
                                    self.contentTableView.reloadData()
                                }
                            })
                        }
                        break
                    default: break
                    }
                    
                }
            }
        }
        self.readingQueue.async(execute: self.readingWorkItem!)
    }
    
    func presentAlert(){
        let alert = UIAlertController(title: "Get Message", message: "Get New Message", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
//    func addNewEntry(_ content : String){
//        let newEntry = Entry(id : PacketTool.share.generateID())
//        newEntry.content = content
//        allEntries.entryList.append(newEntry)
//    }
//
//    func editEntry(id : String, content : String) {
//
//    }
    
    func pressCell(cellNum : Int){
        let entry = entryModel.entryList[cellNum]
        let entryId = entry.identifier
        let entryMessage = entry.content
        let handler = PressCellHandler.share
        
        if(entry.isLocked) {
            handler.unlockAction = {
                entry.isLocked = false
                DispatchQueue.main.async {
                    self.contentTableView.reloadData()
                }
            }
            handler.present(from: self, type: .unlock)
        } else {
            handler.editAction = {
                let alert = UIAlertController(title: "Edit this entry", message: "", preferredStyle: .alert)
                alert.addTextField(configurationHandler: { (textField) in
                    textField.text = entryMessage
                })
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler:  { [weak alert] (_) in
                    if let textField = alert?.textFields?[0], let content = textField.text {
                        //self.editEntry(id: entryId, content: content)
                        self.entryModel.edit(id: entryId, newContent: content, completion: {
                            entry.serverEditing = false
                            self.client.send(data: PacketTool.share.notifyNewPacket())
                            self.contentTableView.reloadData()
                        })
                    }
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                entry.serverEditing = true
                
            }
            
            handler.deleteAction = {
                self.entryModel.remove(id: entryId, completion: {
                    self.client.send(data: PacketTool.share.notifyNewPacket())
                    self.contentTableView.reloadData()
                })
            }
            
            handler.present(from: self, type: .normal)
        }
        
    }

}

extension NoteServerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entryModel.entryList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContentCell")!
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


extension NoteServerViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        pressCell(cellNum: indexPath.row)
    }

}
