//
//  FakeDataTypes.swift
//  MVVM
//
//  Created by Christina on 6/15/16.
//  Copyright © 2016 Christina. All rights reserved.
//

import Foundation
import UIKit

//Because we don't have real userids
public struct TagOwner {
  public static let Own: String = "own123"
  public static let OtherPerson: String = "otherPerson123"
}

public class ContactModel: NSObject {
  public class MatchedContact {
    var name: String
    var photoUrl: String 
    var userId: String
    var username: String
    
    init(name: String, photoUrl: String, userId: String, username: String) {
      self.name = name
      self.photoUrl = photoUrl
      self.userId = userId
      self.username = username
    }
  }
}

public class PhotoTypes: NSObject {
  public class Tag {
    var tagId: String
    var location: CGPoint
    var text: NSAttributedString
    var canEdit: Bool
    var createdAt: Double
    var createdBy: String
    
    init(tagId: String, location: CGPoint, text: NSAttributedString, canEdit: Bool, createdAt: Double, createdBy: String) {
      self.tagId = tagId
      self.location = location
      self.text = text
      self.canEdit = canEdit
      self.createdAt = createdAt
      self.createdBy = createdBy
    }
  }
}


//public class GenericTableDataSource: NSObject {
//  weak var tableVC: GenericTableViewController?
//  
//  public var filterString: String = ""
//  
//  public var isFiltering: Bool {
//    return filterString.characters.count > 0
//  }
//}
//
////Index related methods
//extension GenericTableDataSource {
//  public func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
//    return 0
//  }
//  
//  public func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
//    return nil
//  }
//}
//
//// Search Related Stuff
//extension GenericTableDataSource {
//  public func filterItems(filterString: String) -> Future<Bool, NoError> {
//    let p = Promise<Bool, NoError>()
//    self.filterString = filterString
//    updateSections().onSuccess(Queue.global.context) { result in
//      p.success(result)
//    }
//    return p.future
//  }
//  
//  public func searchItems(queryString: String, arr: [GenericCellViewModel]) -> [GenericCellViewModel] {
//    let query = queryString
//    if query == "" { return arr }
//    return arr.filter {
//      let s = $0.keywords()
//      if s.rangeOfString(query) != nil {
//        return true
//      }
//      return false
//    }
//  }
//  
//  public func updateSectionsImmediate() {
//    var idx = 0
//    sections = []
//    sectionMetadatas = []
//    
//    for section in sectionData {
//      var filteredSection = searchItems(filterString, arr: section)
//      if filteredSection.count > 0 {
//        if maxItemsToDisplay > 0 {
//          let numItems = filteredSection.count
//          if numItems > maxItemsToDisplay {
//            let range = maxItemsToDisplay ..< numItems
//            filteredSection.removeRange(range)
//          }
//        }
//        
//        sections.append(filteredSection)
//        sectionMetadatas.append(sectionDataMetadatas[idx])
//      }
//      idx += 1
//    }
//  }
//  
//  public func updateSections() -> Future<Bool, NoError> {
//    let p = Promise<Bool, NoError>()
//    
//    if isFiltering && filterIntoSingleSection {
//      dispatch_async(dataSourceQueue) {
//        let filterString = self.filterString
//        var items = [GenericCellViewModel]()
//        
//        // determine if filter string is actually searching for a username
//        let finalFilterString = filterString.lowercaseString
//        for section in self.sectionData {
//          items += self.searchItems(finalFilterString, arr: section)
//        }
//        
//        if items.count > 0 {
//          if self.maxItemsToDisplay > 0 {
//            let numItems = items.count
//            if numItems > self.maxItemsToDisplay {
//              let range = self.maxItemsToDisplay ..< numItems
//              items.removeRange(range)
//            }
//          }
//          self.sections = [ items ]
//          self.sectionMetadatas = [ SectionMetadata(name: "Search for " + self.filterString) ]
//        }
//        else {
//          self.sections = []
//          self.sectionMetadatas = []
//        }
//        // log("Search items num items =\(items.count)")
//        p.success(true)
//      }
//    } else {
//      var idx = 0
//      sections = []
//      sectionMetadatas = []
//      
//      for section in sectionData {
//        var filteredSection = searchItems(filterString, arr: section)
//        if filteredSection.count > 0 {
//          if maxItemsToDisplay > 0 {
//            let numItems = filteredSection.count
//            if numItems > maxItemsToDisplay {
//              let range = maxItemsToDisplay ..< numItems
//              filteredSection.removeRange(range)
//            }
//          }
//          
//          sections.append(filteredSection)
//          sectionMetadatas.append(sectionDataMetadatas[idx])
//        }
//        idx += 1
//      }
//      p.success(true)
//    }
//    return p.future
//  }
//}
//
//extension GenericTableDataSource: UITableViewDataSource {
//  public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//    return sections[section].count
//  }
//  
//  public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//    return sections.count
//  }
//  
//  public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//    return tableVC?.tableView(tableView, cellForRowAtIndexPath: indexPath) ?? UITableViewCell()
//  }
//}