//
//  PressCellHandler.swift
//  PairNote
//
//  Created by 张溢 on 2018/11/14.
//  Copyright © 2018年 z. All rights reserved.
//

import UIKit

class PressCellHandler {
    static let share = PressCellHandler()
    
    var title: String?
    
    var editAction: (()->Void)?
    
    var deleteAction: (()->Void)?
    
    private var presentableController: UIViewController?
    
    func present(from controller: UIViewController) {
        presentableController = controller
        
        present()
    }
}

private extension PressCellHandler {
    func present() {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        controller.addAction(UIAlertAction(title: "Edit", style: .default, handler: { _ in
            self.editAction?()
        }))
        
        controller.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.deleteAction?()
        }))
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            controller.dismiss(animated: true, completion: nil)
        }))
        
        presentableController?.present(controller, animated: true, completion: nil)
    }
}
