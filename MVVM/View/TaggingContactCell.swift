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
  func selectedCell(_ model: TaggingContactCellModel)
}

open class GenericCellViewModel {
  lazy open var keywordWords: [String] = {
    return self.keywords().characters.split {$0 == " "}.map { String($0) }
  }()
  
  func keywords() -> String{
    if let title = self.title {
      return title.lowercased()
    }
    return ""
    
  }
  
  open var isDisabled = false
  open var isSelected = false
  
  open var id: String?
  open var title: String?
  open var subtitle: String?
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
      return matchedContact.username.lowercased() + " " + matchedContact.name.lowercased()
    }
    return ""
  }
  
  weak var delegate: TaggingContactCellModelDelegate?
  
  func cellSelected() {
    delegate?.selectedCell(self)
  }
  
}

open class GenericTableViewCell: UITableViewCell {
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
      selectionStyle = .none
      titleLabel.text = viewModel.title
      subtitleLabel.text = viewModel.subtitle
    }
  }
  
  func didSelect() {
    
  }
}

class ContactCell: GenericTableViewCell {
  @IBOutlet var imageButton: UIButton!
  
  fileprivate func updateImageButton() {
    imageButton.layer.cornerRadius = 28.0
    imageButton.layer.masksToBounds = true
    imageButton.contentHorizontalAlignment = .fill
    imageButton.contentVerticalAlignment = .fill
    if let viewModel = viewModel as? ContactCellModel {
      if let imageName = viewModel.imageName {
        if imageName != "" {
          imageButton.setImage(UIImage(named: imageName), for: UIControlState())
          imageButton.setBackgroundImage(nil, for: UIControlState())
          return
        }
      }
      else if let imageUrl = viewModel.imageUrl {
        if let url = URL(string: imageUrl) {
          //todo: set image
          //          imageButton.yr_setImageWithUrl(url, forState: .Normal)
          //          imageButton.setBackgroundImage(nil, forState: .Normal)
          return
        }
      }
    }
    
    imageButton.setImage(nil, for: UIControlState())
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
