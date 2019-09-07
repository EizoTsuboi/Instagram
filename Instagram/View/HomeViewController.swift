//
//  HomeViewController.swift
//  Instagram
//
//  Created by 坪井衛三 on 2019/08/25.
//  Copyright © 2019 Eizo Tsuboi. All rights reserved.
//

import UIKit
import Firebase

class HomeViewController: UIViewController, UITableViewDelegate,UITableViewDataSource {

    var postArray: [PostData] = []
    //DatabaseのobserveEventの登録状態を表す
    var observing = false

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.allowsSelection = false

        let nib = UINib(nibName: "PostTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Cell")
        //Tableのrowの高さをAutoLayoutで自動調整する
        tableView.rowHeight = UITableView.automaticDimension
        //テーブルrowの高さの概算値を設定しておく
        //高さの概算値　= 「縦横比1:1のUIImageViewの高さ（＝画面幅)」+「いいね!ボタン、captionラベル、その他余白の高さの合計概算（=100pt）」
        tableView.estimatedRowHeight = UIScreen.main.bounds.width + 100
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DEBUG_PRINT: viewwillApper")
        
        if Auth.auth().currentUser != nil{
            if self.observing == false{
                //要素が追加されたらpostArrayに追加してTableViewを再表示する
                let postsRef = Database.database().reference().child(Const.PostPath)
                postsRef.observe(.childAdded, with: { snapshot in //データが追加されたときに送られてくる「Datasnapshot」
                    print("DEBUG_PRINT: .childAddedイベントが発生しました。")
                    //PostDataクラスを作成して受け取ったデータを設定する
                    if let uid = Auth.auth().currentUser?.uid{
                        let postData = PostData(snapshot: snapshot, myId: uid)
                        self.postArray.insert(postData, at: 0)
                        //TableViewを再表示する
                        self.tableView.reloadData()
                    }
                })
                //要素が変更されたら該当のデータをpostArrayから一度削除した後に新しいデータを追加してTableViewを再表示する
                postsRef.observe(.childChanged, with:{ snapshot in //データが更新されたときに送られてくる「Datasnapshot」
                    print("DEBUG_PRINT: .childChangedイベントが発生しました")
                    if let uid = Auth.auth().currentUser?.uid{
                        //PostDataクラスを作成して受け取ったデータを設定する
                        let postData = PostData(snapshot: snapshot, myId: uid)
                        //保持している配列からidが同じものを探す
                        var index:Int = 0
                        for post in self.postArray{
                            if post.id == postData.id{
                                index = self.postArray.firstIndex(of: post)!
                                break
                            }
                        }
                        //差し替えるため一度削除する
                        self.postArray.remove(at: index)
                        //削除したところに更新済みのデータを追加する
                        self.postArray.insert(postData, at: index) //postDataは追加されたデータをPostDatクラスのインスタンス
                        self.tableView.reloadData()
                    }
                })
                //DatabaseのobserveEventが上記コードにより登録されたため
                //trueとする
                observing = true
            }
        }else{
            if observing == true{
                //ログアウトを検出したら、一旦テーブルをクリアしてオブザーバーを削除する
                //テーブルをクリアする
                postArray = []
                tableView.reloadData()
                //オブザーバーを削除する
                let postsRef = Database.database().reference().child(Const.PostPath)
                postsRef.removeAllObservers()
                
                //DatabaseのobserveEventが上記コードにより解除されたため
                //falseとする
                observing = false
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PostTableViewCell
        cell.setPostDate(postArray[indexPath.row])
        
        //セル内のlikeボタンのアクションをソースコードで設定する
        cell.likeButton.addTarget(self, action:#selector(handleButton(_:forEvent:)), for: .touchUpInside)
        
        //セル内のsentボタンのアクションをソースコードで設定
        cell.commentSentButton.tag = indexPath.row
        cell.commentSentButton.addTarget(self, action:#selector(sentComment(_:forEvent:)), for: .touchUpInside)
        
        return cell
    }
    
    @objc func handleButton(_ sender: UIButton, forEvent event: UIEvent){
        print("DEBUG_PRINT: likeButtonがタップされました")
        
        //タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        //配列からタップされたインデッククスのデータを取り出す
        let postData = postArray[indexPath!.row]
        
        //Firebaseに保存するデータの準備
        if let uid = Auth.auth().currentUser?.uid{
            if postData.isLiked{
                //すでにいいねをしていた場合はいいねを解除するためIDを取り除く
                var index = -1
                for likeId in postData.likes{
                    if likeId == uid{
                    //削除するためにインデックスを保持しておく
                    index = postData.likes.firstIndex(of: likeId)!
                    break
                    }
                }
                postData.likes.remove(at: index)
                
            }else{
                postData.likes.append(uid)
            }
            
            //増えたlikesをFirebaseに保存する
            let postRef = Database.database().reference().child(Const.PostPath).child(postData.id!)
            let likes = ["likes": postData.likes]
            postRef.updateChildValues(likes)
        }
    }
    
    
    @objc func sentComment(_ sender: UIButton, forEvent event: UIEvent){
        print("DEBUG_PRINT: sentボタンがタッチされた")
        
        //タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        
        let cell = self.tableView.cellForRow(at: indexPath!) as! PostTableViewCell
        
        //配列からタップされたインデックスのデータを取り出す
        let postData = postArray[indexPath!.row]
        let myName = Auth.auth().currentUser?.displayName
        
        //Firebaseに保存するデータの準備
        if let comment = cell.inputCommentTextField.text, let inputName = myName{
            postData.comments.append(comment)
            postData.commentNames.append(inputName)
        }
        
        //辞書を作成してFirebaseに保存する
        let postRef = Database.database().reference().child(Const.PostPath).child(postData.id!)
        let comments = ["comments": postData.comments]
        let commentNames = ["commentNames": postData.commentNames]
        postRef.updateChildValues(comments)
        postRef.updateChildValues(commentNames)
        
        cell.inputCommentTextField.text = ""
        self.tableView.reloadData()
    }
}

