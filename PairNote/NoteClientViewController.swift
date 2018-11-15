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
        
        setupServer()
        startReadingQueue()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                        let entries = PacketTool.share.readAllContentPacket(packet: bytes)
                        self.entryModel.initList(entries: entries)
                        DispatchQueue.main.async {
                            self.contentTableView.reloadData()
                        }
                        break
                    default: break
                    }
                    
                }
                
            }
        }
        self.readingQueue.async(execute: self.readingWorkItem!)
    }
    
    func presentAlert(title : String){
        let alert = UIAlertController(title: title, message: "Get New Message", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    func fetchList(){
        
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
        }
        return cell
    }
    
}


extension NoteClientViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //pressCell(cellNum: indexPath.row)
    }
    
}


