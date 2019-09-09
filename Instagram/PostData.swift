//
//  PostDate.swift
//  Instagram
//
//  Created by 坪井衛三 on 2019/08/28.
//  Copyright © 2019 Eizo Tsuboi. All rights reserved.
//

import UIKit
import Firebase

class PostData: NSObject {
    var id: String?
    var image: UIImage?
    var imageString: String?
    var name: String?
    var caption: String?
    var date: Date?
    var likes: [String] = []
    var isLiked: Bool = false
    var comments: [String] = []
    var commentNames: [String] = []
    
    init(snapshot: DataSnapshot, myId: String){
        self.id = snapshot.key
        
        let valueDictionary = snapshot.value as! [String: Any]
        imageString = valueDictionary["image"] as? String
        image = UIImage(data: Data(base64Encoded: imageString!, options: .ignoreUnknownCharacters)!)
        
        self.name = valueDictionary["name"] as? String
        
        self.caption = valueDictionary["caption"] as? String
        
        let time = valueDictionary["time"] as? String
        self.date = Date(timeIntervalSinceReferenceDate: TimeInterval(time!)!)
        
        if let likes = valueDictionary["likes"] as? [String] {
            self.likes = likes
        }
        for likeId in self.likes{
            if likeId == myId{
                self.isLiked = true
                break
            }
        }
        
        if let comments = valueDictionary["comments"] as? [String]{
            self.comments = comments
        }
        if let commentNames = valueDictionary["commentNames"] as? [String]{
            self.commentNames = commentNames
        }
    }
}
