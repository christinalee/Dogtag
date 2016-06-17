//
//  TaggingContactCell.swift
//  yaroll
//
//  Created by Christina on 2/23/16.
//  Copyright © 2016 Math Camp. All rights reserved.
//

import Foundation
import UIKit

protocol TaggingContactCellModelDelegate: class {
  func selectedCell(model: TaggingContactCellModel)
}

public class GenericCellViewModel {
  lazy public var keywordWords: [String] = {
    return self.keywords().characters.split {$0 == " "}.map { String($0) }
  }()
  
  func keywords() -> String{
    if let title = self.title {
      return title.lowercaseString
    }
    return ""
    
  }
  
  public var isDisabled = false
  public var isSelected = false
  
  public var id: String?
  public var title: String?
  public var subtitle: String?
}

class ContactCellModel: GenericCellViewModel {
  var matchedContact: ContactModel.MatchedContact?
  let images = ["avatar_shorts_bazooka", "avatar_shorts_johnnytsunami", "avatar_shorts_surfandchill"]
  var imageName: String?
  var imageUrl: String?
  
  var name: String {
    if let matchedContact = matchedContact {
      return matchedContact.name
    }
    return ""
  }
  
  init(matchedContact: ContactModel.MatchedContact) {
    super.init()
    self.matchedContact = matchedContact
    self.title = matchedContact.name
    self.subtitle = "@"+matchedContact.username
    self.imageUrl = matchedContact.photoUrl
  }
}

class TaggingContactCellModel: ContactCellModel {
  override func keywords() -> String {
    if let matchedContact = matchedContact {
      return matchedContact.username.lowercaseString + " " + matchedContact.name.lowercaseString
    }
    return ""
  }
  
  weak var delegate: TaggingContactCellModelDelegate?
  
  func cellSelected() {
    delegate?.selectedCell(self)
  }
  
}

public class GenericTableViewCell: UITableViewCell {
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var subtitleLabel: UILabel!
  
  weak var parentVC: UITableViewController?
  
  var viewModel: GenericCellViewModel! {
    didSet {
      viewModelChanged()
    }
  }
  
  func viewModelChanged() {
    if let viewModel = viewModel {
      selectionStyle = .None
      titleLabel.text = viewModel.title
      subtitleLabel.text = viewModel.subtitle
    }
  }
  
  func didSelect() {
    
  }
}

class ContactCell: GenericTableViewCell {
  @IBOutlet var imageButton: UIButton!
  
  private func updateImageButton() {
    imageButton.layer.cornerRadius = 28.0
    imageButton.layer.masksToBounds = true
    imageButton.contentHorizontalAlignment = .Fill
    imageButton.contentVerticalAlignment = .Fill
    if let viewModel = viewModel as? ContactCellModel {
      if let imageName = viewModel.imageName {
        if imageName != "" {
          imageButton.setImage(UIImage(named: imageName), forState: .Normal)
          imageButton.setBackgroundImage(nil, forState: .Normal)
          return
        }
      }
      else if let imageUrl = viewModel.imageUrl {
        if let url = NSURL(string: imageUrl) {
          //todo: set image
          //          imageButton.yr_setImageWithUrl(url, forState: .Normal)
          //          imageButton.setBackgroundImage(nil, forState: .Normal)
          return
        }
      }
    }
    
    imageButton.setImage(nil, forState: .Normal)
  }
}

class TaggingContactCell: ContactCell {
  
  override func didSelect() {
    if let model = viewModel as? TaggingContactCellModel {
      model.cellSelected()
    }
  }
  
  override func viewModelChanged() {
    super.viewModelChanged()
    imageButton.layer.cornerRadius = 20.0
  }
}