//
//  PhotoBrowserCollectionViewCell.swift
//  图片浏览器
//
//  Created by 梁华建 on 2019/10/23.
//  Copyright © 2019 梁华建. All rights reserved.
//

import UIKit

protocol PhotoBrowserCollectionViewCellDelegate : NSObjectProtocol{
    ///图片被点击或者缩小到一定程度需要结束图片浏览的时候,会调用该方法
    func didClickedCell(cell : PhotoBrowserCollectionViewCell)
}

class PhotoBrowserCollectionViewCell: UICollectionViewCell {
    //MARK: - 成员变量
   weak var delegate : PhotoBrowserCollectionViewCellDelegate?
    
    var imageName : String?
    {
        didSet
        {
            if imageName == nil
            {
                return
            }
            
            imageView.image = UIImage.init(named: imageName!)
            
            imageView.frame.size = imageView.image?.size.resizeBy(width: screenWidth) ?? CGSize.zero
            
            imageView.frame.origin = CGPoint.init(x: 0, y: (screenHeight - imageView.frame.size.height) / 2)
        }
        
    }
    
    var imageView : UIImageView =
    {
        let imv = UIImageView()
        imv.isUserInteractionEnabled = true
        imv.contentMode = .scaleAspectFill
        imv.layer.masksToBounds = true
        return imv
    }()
    ///用于装载图片的scrollView
    let scrollView = UIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: screenWidth , height: screenHeight))
    
    //MARK: - 拖动各种需要的属性
    ///pan手势拖动开始的点
    var dragBeginPoint = CGPoint.zero
    ///图片拖动前的frame,基于scrollView
    var imageFrameBeforeDrag = CGRect.zero
    ///图片拖动前的center,基于scrollView
    var imageCenterBeforeDrag : CGPoint = .zero
    ///是否在往下拖动
    var downDragging = false
    ///拖动系数:0.0-1.0,系数越大,说明拖动距离越大,图片越小,背景越透明
    var dragCoefficient : CGFloat = 0.0
    {
        didSet
        {
            //背景透明度最多为0.2
            //这里superView是collectionView,背景颜色为透明;collectionView的superView为view,背景颜色为黑色
            self.superview?.superview?.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 1-dragCoefficient < 0.2 ? 0.2 : 1-dragCoefficient)
            self.scrollView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 1-dragCoefficient < 0.2 ? 0.2 : 1-dragCoefficient)
        }
    }
    ///图片可拖动的最大距离,随后拖动系数为1(大于1置为1)
    var maxMoveY : CGFloat = screenHeight * 0.15
    //MARK: - 生命周期
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        //添加图片到scrollView
        scrollView.addSubview(imageView)
        //添加scrollView到cell
        contentView.addSubview(scrollView)
        
        scrollView.isPagingEnabled = true
        
        scrollView.backgroundColor = .black
        
        scrollView.delegate = self
        
        if #available(iOS 11.0, *) {
            //在iOS11后的scrollView的新属性,他会根据机型在显示scrollView的时候,担心scrollView的content会遮住iPhone头部的statusBar,会产生一个动画把content往下移动一点,并触发scrollView的代理方法
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        imageView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(pictureTapped)))
        //重要:设置该属性后,无论scrollView的contentSize是否为0(为0则无法滚动),scrollView允许我们上下滑动一段距离,这样就会调用scrollView的拖动代理方法,实现监听图片是否在被往下拖动
        scrollView.alwaysBounceVertical = true
        //一开始想要通过把pan手势加到imageView上面,结果发现imageView的手势会和collectionView的左右滑动冲突,并且这个冲突的手势会有很多,collectionView上面的tap,longPress等都会触发,会导致左滑的时候图片被缩小
        //        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(paningOnPicture(gesture:)))
        //
        //        pan.delegate = self
        //
        //        imageView.addGestureRecognizer(pan)
        
    }
    required init?(coder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
       }
    
    ///图片被单击的时候会调用
    @objc func pictureTapped(gesture : UITapGestureRecognizer)  {
        self.delegate?.didClickedCell(cell: self)
    }
    
    func setDragStatusToBegin() {
        
        dragBeginPoint = .zero
        
        downDragging = false
        
    }
    
    /// 图片拖动调用的方法,主要完成照片随着拖动手势移动以及放大缩小
    /// - Parameter gesture: 拖动手势
    @objc func draggingPicture(gesture : UIPanGestureRecognizer) {
        //手势状态未准备好或结束,直接返回并把状态置为未开始拖动
        if  gesture.state == .possible || gesture.state == .ended
        {
            setDragStatusToBegin()
            
            return
        }
        //开始滑动
        let panCurrentPoint = gesture.location(in: gesture.view ?? self)
        //记录初始值并返回
        if dragBeginPoint == .zero {
            
            dragBeginPoint = panCurrentPoint
            
            savePictureFrameBeforeDrag()
            
            return
        }
        
        //translation:手势在一段时间内的偏移量,y比之前的点大说明正在往下拉
        downDragging = gesture.translation(in: self.scrollView).y > 0
        
        //起点和终点的距离/最大拖动距离 = 拖动系数 (随着拖动系数变大,图片缩小,背景变透明)
        let dragCoefficient = dragBeginPoint.distanceTo(point: panCurrentPoint) / maxMoveY
        //这是一个观察者属性,didSet里面会根据新传进来的拖动系数设置背景的透明度
        self.dragCoefficient = dragCoefficient > 1.0 ? 1.0 : dragCoefficient
        
        if downDragging
        {
            //图片最小能缩小到0.4
            self.imageView.bounds.size.width = imageFrameBeforeDrag.size.width * ((1 - dragCoefficient) < 0.4 ? 0.4 : (1 - dragCoefficient))
            
            self.imageView.bounds.size.height = imageFrameBeforeDrag.size.height * ((1 - dragCoefficient) < 0.4 ? 0.4 : (1 - dragCoefficient))
        }else
        {
            self.imageView.bounds.size.width = imageFrameBeforeDrag.size.width
            
            self.imageView.bounds.size.height = imageFrameBeforeDrag.size.height
        }
 
        self.imageView.center.x = imageCenterBeforeDrag.x + (panCurrentPoint.x - dragBeginPoint.x)
        
        self.imageView.center.y = imageCenterBeforeDrag.y + (panCurrentPoint.y - dragBeginPoint.y)
        
    }
    
    ///记录图片拖动前的frame和center
    func savePictureFrameBeforeDrag()
    {
        imageFrameBeforeDrag = imageView.frame
    
        //对于图片比屏幕高的,我们把其Y设为0
        imageFrameBeforeDrag.origin.y = imageView.frame.origin.y < screenHeight ?
            (screenHeight - imageView.frame.size.height) * 0.5 : 0.0
        
        imageCenterBeforeDrag = imageView.center
    
    }
    
    /// 拖动结束:两种情况 1. 通知外界dismiss图片浏览器; 2. 把图片还原到拖动前的frame
    func dragDidEnd()
    {
        //0.2的时候是用户有意识的下滑并取消浏览图片,大于0.6后是拖到比较远的距离,用户是在尝试这个拖动效果,而不是想取消浏览
        if self.dragCoefficient > 0.2 && self.dragCoefficient < 0.6 {
            //通知上层vc进行dismiss,并把cell传出去,通过cell转场动画代理可以获取拖动的最终frame,在图片最终位置进行动画转场
            self.delegate?.didClickedCell(cell: self)
        }else
        {
            //恢复原状
            if self.dragBeginPoint == .zero {
                return
            }
            UIView.animate(withDuration: 0.5, animations: {
                
                self.dragCoefficient = 0
                
                self.imageView.frame = self.imageFrameBeforeDrag
                
            }) { (complete) in
                self.imageCenterBeforeDrag = .zero
                self.imageFrameBeforeDrag = .zero
            }
        }
        
    }
}

extension PhotoBrowserCollectionViewCell : UIScrollViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //通知图片所在的scrollView发生拖动,上或下
        draggingPicture(gesture: scrollView.panGestureRecognizer)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        if scrollView === self.scrollView
        {
            //通知图片所在的scrollView拖动结束
            dragDidEnd()
        }
    }
}

extension CGSize
{
    ///按宽度去拉伸图片高度
    func resizeBy(width : CGFloat ) -> CGSize
    {
        return  CGSize.init(width: width, height: self.height * (width / self.width))
    }
    
    func resizeBy(height : CGFloat ) -> CGSize
    {
        return  CGSize.init(width: self.width * (height / self.height), height: height)
    }
    
}

extension CGPoint
{
    func distanceTo(point : CGPoint) -> CGFloat
    {
        return sqrt(pow(self.x - point.x, 2) + pow(self.y - point.y, 2))
    }
}
