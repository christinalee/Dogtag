//
//  TaggingTableViewController.swift
//  yaroll
//
//  Created by Ben Garrett on 2/9/16.
//  Copyright © 2016 Math Camp. All rights reserved.
//

import Foundation
import UIKit

protocol TaggingTableDelegate: class {
  func matchedContactSelected(_ matchedContact: ContactModel.MatchedContact)
  func sizeChanged(_ contentSize: CGSize)
}

open class TaggingTableViewController: UITableViewController {
  weak var taggingDelegate: TaggingTableDelegate?
//
//  public override func viewWillAppear(animated: Bool) {
//    super.viewWillAppear(animated)
//    
//    tableView.layer.cornerRadius = 10
//  }
//  
//  public override func viewWillDisappear(animated: Bool) {
//    super.viewWillDisappear(animated)
//    
//    taggingDelegate = nil
//  }
//  
//  public override func viewDidDisappear(animated: Bool) {
//    super.viewDidDisappear(animated)
//    
//    let cells = tableView.visibleCells
//    for cell in cells {
//      if let cell = cell as? TaggingContactCell {
//        cell.viewModel = nil
//        cell.parentVC = nil
//      }
//    }
////    dataSource.tableVC = nil
//  }
//  
//  override public func updateFromModel() -> Future<Void, NoError> {
//    let p = Promise<Void, NoError>()
//    
//    AppModules.sharedInstance.channelsModel.friendChannels().onSuccess(Queue.global.context) {
//      let filteredChannels = $0.filter { $0.description.profile.username != "" }
//      let contacts: [ContactModel.MatchedContact] = filteredChannels.map {
//        let c = ContactModel.MatchedContact()
//        c.name = $0.description.profile.name
//        c.photoUrl = $0.description.profile.imageUrl
//        c.userId = $0.description.profile.userId
//        c.username = $0.description.profile.username
//        return c
//      }.sort({ (a, b) -> Bool in a.name < b.name })
//    
//      var sectionNames: [String] = []
//      var sectionMetadatas: [GenericTableDataSource.SectionMetadata] = []
//
//      sectionNames.append("Friends on Shorts")
//      sectionMetadatas.append(GenericTableDataSource.SectionMetadata(name: "Friends on Shorts"))
//      
//      let contactsViewModels = contacts.map {
//        TaggingContactCellModel(matchedContact: $0)
//      }
//      contactsViewModels.forEach { (cellModel) -> () in
//        cellModel.delegate = self
//      }
//      let viewModels = [contactsViewModels] as [[GenericCellViewModel]]
//      
//      Queue.main.async {
//        self.dataSource.sectionNames = sectionNames
//        self.dataSource.sectionData = viewModels
//        self.dataSource.sectionDataMetadatas = sectionMetadatas
//        p.success()
//      }
//    }
//    
//    return p.future
//  }
//  
//  override func reloadData() {
//    tableView.reloadData()
//    taggingDelegate?.sizeChanged(self.tableView.contentSize)
//  }
//  
  open func updateSearchText(_ queryString: String) {
//    dataSource.filterItems(queryString).onSuccess(Queue.main.context) { _ in
//      self.reloadData()
//    }
  }
//}
//
//extension TaggingTableViewController: TaggingContactCellModelDelegate {
//  func selectedCell(model: TaggingContactCellModel) {
//    if let matchedContact = model.matchedContact {
//      taggingDelegate?.matchedContactSelected(matchedContact)
//    }
//  }
}
