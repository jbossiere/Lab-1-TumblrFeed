//
//  PhotosViewController.swift
//  TumblrFeed
//
//  Created by Julian Bossiere on 1/18/17.
//  Copyright © 2017 Julian Bossiere. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class PhotosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {

    var posts: [NSDictionary] = []
    var isMoreDataLoading = false
    var loadingMoreView: InfiniteScrollActivityView?
    
    @IBOutlet weak var TumblrTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlAction(refreshControl :)), for: UIControlEvents.valueChanged)
        
        TumblrTableView.insertSubview(refreshControl, at: 0)
        
        TumblrTableView.delegate = self
        TumblrTableView.dataSource = self
        TumblrTableView.rowHeight = 240
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        loadContent()
        MBProgressHUD.hide(for: self.view, animated: true)
        
        let frame = CGRect(x: 0, y: TumblrTableView.contentSize.height, width: TumblrTableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.isHidden = true
        TumblrTableView.addSubview(loadingMoreView!)
        
        var insets = TumblrTableView.contentInset
        insets.bottom += InfiniteScrollActivityView.defaultHeight
        TumblrTableView.contentInset = insets

        // Do any additional setup after loading the view.
    }
    
    func refreshControlAction(refreshControl: UIRefreshControl) {
        loadContent()
        refreshControl.endRefreshing()
    }
    
    func loadContent() {
        let url = URL(string: "https://api.tumblr.com/v2/blog/humansofnewyork.tumblr.com/posts/photo?api_key=Q6vHoaVm5L1u2ZAW1fqv3Jw48gFzYVg9P0vH0VHl3GVy6quoGV")
        let request = URLRequest(url: url!)
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate: nil,
            delegateQueue: OperationQueue.main
        )
        
        let task : URLSessionDataTask = session.dataTask(
            with: request as URLRequest,
            completionHandler: { (data, response, error) in
                if let data = data {
                    if let responseDictionary = try! JSONSerialization.jsonObject(
                        with: data, options: []) as? NSDictionary {
                        print("responseDictionary: \(responseDictionary)")
                        
                        let responseFieldDictionary = responseDictionary["response"] as! NSDictionary
                        
                        self.posts = responseFieldDictionary["posts"] as! [NSDictionary]
                        self.TumblrTableView.reloadData()
                        
                    }
                }
//                refreshControl.endRefreshing()
        });
        task.resume()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = TumblrTableView.dequeueReusableCell(withIdentifier: "PhotoCell") as! PhotoCell
        let post = posts[indexPath.row]
        if let photos = post.value(forKeyPath: "photos") as? [NSDictionary] {
            let imageUrlString = photos[0].value(forKeyPath: "original_size.url") as? String
            if let imageUrl = URL(string: imageUrlString!) {
                cell.photoImageView.setImageWith(imageUrl)
            }
        }
        
        return cell
        
    }
    
    func loadMoreData() {
        let url = URL(string: "https://api.tumblr.com/v2/blog/humansofnewyork.tumblr.com/posts/photo?api_key=Q6vHoaVm5L1u2ZAW1fqv3Jw48gFzYVg9P0vH0VHl3GVy6quoGV&offset=\(self.posts.count)")
        let request = URLRequest(url: url!)
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate: nil,
            delegateQueue: OperationQueue.main
        )
        
        let task : URLSessionDataTask = session.dataTask(
            with: request as URLRequest,
            completionHandler: { (data, response, error) in
                self.isMoreDataLoading = false
                self.loadingMoreView!.stopAnimating()
                if let data = data {
                    if let responseDictionary = try! JSONSerialization.jsonObject(
                        with: data, options: []) as? NSDictionary {
                        print("responseDictionary: \(responseDictionary)")
                        
                        let responseFieldDictionary = responseDictionary["response"] as? NSDictionary
                        
                        self.posts += responseFieldDictionary?["posts"] as! [NSDictionary]
                        self.TumblrTableView.reloadData()
                        
                    }
                }
        });
        task.resume()

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (!isMoreDataLoading) {
            let scrollViewContentHeight = TumblrTableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - TumblrTableView.bounds.size.height
            
            if (scrollView.contentOffset.y > scrollOffsetThreshold && TumblrTableView.isDragging) {
                isMoreDataLoading = true
                
                let frame = CGRect(x: 0, y: TumblrTableView.contentSize.height, width: TumblrTableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                
                loadMoreData()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let photoDetails = segue.destination as! PhotoDetailsViewController
        var indexPath = TumblrTableView.indexPath(for: sender as! UITableViewCell)
        let post = posts[indexPath!.row]
        
        photoDetails.post = post
        
    }
    

}
