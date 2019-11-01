//
//  ViewController.swift
//  图片浏览器
//
//  Created by 梁华建 on 2019/10/23.
//  Copyright © 2019 梁华建. All rights reserved.
//

import UIKit

let screenWidth = UIScreen.main.bounds.size.width

let screenHeight = UIScreen.main.bounds.size.height

let CellID = "CellID"

let CellMargin : CGFloat = 10

let CellCounts : CGFloat = 6

let row : CGFloat = CellCounts / 3

let col : CGFloat = CellCounts < 3 ? CellCounts : 3


///该控制器用来显示未跳动前的显示图片缩略图的collectionView,想看跳转逻辑建议直接看collectionView的点击方法
class ViewController: UIViewController {
    
    var imageNames = ["1","2","3","4","5","6"]
    
    var imageFrameArray = [CGRect].init(repeating: .zero, count: Int(CellCounts))
    
    var collectionView : UICollectionView  = {
        
        let layout = UICollectionViewFlowLayout()
        
        layout.itemSize = CGSize.init(width: (screenWidth - CellMargin * (col - 1)) / 3, height: (screenWidth - CellMargin * (row - 1)) / 3)
        
        layout.minimumInteritemSpacing = CellMargin
        
        layout.minimumLineSpacing = CellMargin
        
        layout.scrollDirection = .vertical
        
        let cv = UICollectionView.init(frame: CGRect.init(x: 0, y: 0, width: screenWidth, height: row * layout.itemSize.height + CellMargin * (row - 1)), collectionViewLayout: layout)
        
        return cv
    }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        collectionView.backgroundColor = .black
        
        collectionView.dataSource = self
        
        collectionView.delegate = self
        
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: CellID)
        
        self.view.addSubview(collectionView)
        
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        //viewSafeArea改变的时候改变collectionView视图高度,这样collectionView就不会被navgationBar遮住,可以在safeArea外布局,该方法在viewDidAppear前调用
        collectionView.frame.origin.y = self.view.safeAreaInsets.top
    }
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        //cell这时候可以进行坐标轴转换,无论什么机型都不会被navigationBar遮住
        for i in 0..<collectionView.visibleCells.count
        {
            let cell = collectionView.visibleCells[i]
            let newRect = cell.convert(cell.bounds, to: UIApplication.shared.windows.first)
            imageFrameArray[i] = newRect
        }
    }
    
}

extension ViewController : UICollectionViewDelegate,UICollectionViewDataSource
{
    ///点击图片跳转
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let pbvc = PhotoBrowserViewController.init(imageNames: imageNames,imageFrameArray: imageFrameArray, currentIndex: indexPath.row)
        //设置了该属性,跳转后就不会把后面vc隐藏掉
        pbvc.modalPresentationStyle = .overFullScreen
        
        //跳转
        self.present(pbvc, animated: true) {
            
            pbvc.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellID, for: indexPath)
        
        cell.backgroundColor = .white
        
        let imv = UIImageView.init(frame: cell.bounds)
        
        imv.contentMode = .scaleAspectFill
        
        imv.layer.masksToBounds = true
        
        imv.image = UIImage.init(named: imageNames[indexPath.row])
        
        cell.contentView.addSubview(imv)
        
        return cell
        
    }
    
}

func isIPhoneX() -> Bool
{
    return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone
}
