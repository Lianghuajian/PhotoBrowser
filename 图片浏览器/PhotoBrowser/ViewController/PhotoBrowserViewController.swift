//
//  PhotoBrowserViewController.swift
//  图片浏览器
//
//  Created by 梁华建 on 2019/10/23.
//  Copyright © 2019 梁华建. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class PhotoBrowserViewController: UIViewController {
    //MARK: - 成员变量
    ///完成转场动画的代理
    var transitionDelegate : PhotoBrowserTransitionDelegate? = PhotoBrowserTransitionDelegate()
    
    let collectionView : UICollectionView =
    {
        let layout = UICollectionViewFlowLayout()
        //添加照片间的黑边,view只能显示没有黑边的图片部分,在滑动的时候会看见,因为图片的宽度是屏幕宽,而itemSize比屏幕宽20,20就是黑边
        layout.itemSize = CGSize.init(width: screenWidth + 20, height: screenHeight)
        
        layout.minimumInteritemSpacing = 0
        
        layout.minimumLineSpacing = 0
        
        layout.scrollDirection = .horizontal
        
        let cv = UICollectionView(frame: CGRect.init(x: 0, y: 0, width: screenWidth + 20, height: screenHeight), collectionViewLayout: layout)
        
        return cv
        
    }()
    
    var imageFrameArray : [CGRect]?
    {
        didSet
        {
            if imageFrameArray == nil
            {
                return
            }
            
            transitionDelegate?.imageFrameArray = imageFrameArray!
        }
    }
    
    var currentIndex = 0
    {
        didSet
        {
            
            transitionDelegate?.currentIndex = currentIndex
        }
    }
    
    var imageNames : [String]?
    {
        didSet
        {
            
            self.transitionDelegate?.imageNames = imageNames
        }
    }
    
    //MARK: - 生命周期
    /// 提供必要的转场动画数据并初始化图片浏览器
    /// - Parameter imageNames: 图片的名字数组,这边如果是URL就自己拿去改一下
    /// - Parameter imageFrameArray:图片的相对于window上面的frame
    /// - Parameter currentIndex: 点击所在图片的下标
    convenience init(imageNames : [String], imageFrameArray : [CGRect] , currentIndex : Int ) {
        
        self.init()
        //注意:init方法里面属性的didSet方法不会被调用
        self.currentIndex = currentIndex
    
        self.imageFrameArray = imageFrameArray
        
        self.imageNames = imageNames
        
        self.transitionDelegate?.imageNames = imageNames
        
        self.transitionDelegate?.imageFrameArray = imageFrameArray
        
        self.transitionDelegate?.currentIndex = currentIndex
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //图片浏览器布局
        self.view.addSubview(self.collectionView)
        //这里把view设置为黑色,用于在进行present动画的时候,有个从背景颜色透明变黑的效果;在dismiss的时候我们也应该操作这个view的背景颜色透明度,才能看到后面的视图.
        self.view.backgroundColor = .black
        
        self.collectionView.isPagingEnabled = true
        //collectionView的父类view是黑色背景,这个就不用设置为黑色了
        self.collectionView.backgroundColor = .clear
        self.collectionView.register(PhotoBrowserCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView.isHidden = true
        self.collectionView.dataSource = self
        self.transitioningDelegate = self
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.collectionView.isHidden = false
    }
    deinit {
       print(#file.components(separatedBy: "/").last ?? ""," released")
    }
    
}
//MARK: - UICollectionViewDataSource
extension PhotoBrowserViewController : UICollectionViewDataSource
{
     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return imageNames?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoBrowserCollectionViewCell
        //这里？可以规避imageNames还没有被赋值的情况
        cell.imageName = imageNames?[indexPath.row]
        
        cell.delegate = self
        
        return cell
    }
}
//MARK: - PhotoBrowserCollectionViewCellDelegate
extension PhotoBrowserViewController : PhotoBrowserCollectionViewCellDelegate
{
    
    func didClickedCell(cell: PhotoBrowserCollectionViewCell) {

        guard let currentIndex = collectionView.indexPath(for: cell)?.row else {
            return
        }
        
        self.currentIndex = currentIndex
        
        self.transitionDelegate?.transitionView?.frame = cell.imageView.frame

        self.dismiss(animated: true, completion: nil)
        
    }
    
}
//MARK: - UIViewControllerTransitioningDelegate
extension PhotoBrowserViewController : UIViewControllerTransitioningDelegate
{
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        return self.transitionDelegate
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        return self.transitionDelegate
    }
}
