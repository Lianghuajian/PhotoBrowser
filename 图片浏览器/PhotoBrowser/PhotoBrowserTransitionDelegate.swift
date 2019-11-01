//
//  TransitioningDelegate.swift
//  图片浏览器
//
//  Created by 梁华建 on 2019/10/28.
//  Copyright © 2019 梁华建. All rights reserved.
//

import UIKit

//protocol PhotoBrowserPresentDataSrouce : NSObjectProtocol{
//    func toFrameForPresentAt(indexPath : IndexPath) -> CGRect
//    func fromFrameForPresentAt(indexPath : IndexPath) -> CGRect
//    func dataSourceForTransitionView() -> Any
//}
//
//protocol PhotoBrowserDimisssDataSrouce : NSObjectProtocol{
//    func toFrameForDismissAt(indexPath : IndexPath) -> CGRect
//    func fromFrameForDismissAt(indexPath : IndexPath) -> CGRect
//}

class PhotoBrowserTransitionDelegate : NSObject,UIViewControllerAnimatedTransitioning {
    //MARK: - 帮助完成转场动画的对象
    ///用于完成转场动画的视图
    var transitionView : UIImageView? = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFill
        imv.layer.masksToBounds = true
        return imv
    }()
    
    var imageNames : [String]?
    
    var isPresented = false
    
    var currentIndex  = 0
    {
        didSet
        {
            
            guard let imageName = imageNames?[currentIndex] else
            {
                return
            }
            
            self.transitionView?.image = UIImage.init(named: imageName)
        }
    }
    
    var imageFrameArray = [CGRect]()
    
    //MARK: - 转场动画代理方法
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
        return 0.5
        
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let transitionView = transitionView else
        {
            return
        }

        if !isPresented {
            
            guard let to = transitionContext.view(forKey: .to) else
                   {
                       return
                   }
                   to.alpha = 0;
                         
            
            transitionContext.containerView.addSubview(to)
            
            transitionContext.containerView.addSubview(transitionView)
            
            self.transitionView?.frame = imageFrameArray[currentIndex]
            
            var toValue = CGRect.zero
            
            guard let newSize = transitionView.image?.size.resizeBy(width: screenWidth) else
            {
                return
            }
            
            toValue = CGRect.init(x: 0, y: (screenHeight - newSize.height) / 2, width: newSize.width, height: newSize.height)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                to.alpha = 1;
                
                self.transitionView?.frame = toValue
                
            }) { (complete) in
                
                self.isPresented = true
                
                self.transitionView?.removeFromSuperview()
                
                transitionContext.completeTransition(true)
            }
            
        }else {
            //dismiss
            self.transitionView?.isHidden = false
            
            let fromVC = transitionContext.viewController(forKey: .from)
            
            transitionContext.containerView.addSubview(fromVC!.view)
            
            fromVC?.view.alpha = 1
            
            //我们这里需要把当前图片隐藏掉,然后保留fromVC的黑色背景,这个黑色背景做一个透明度从0到1的动画
            (fromVC as? PhotoBrowserViewController)?.collectionView.visibleCells.forEach({ (cell) in
                (cell as? PhotoBrowserCollectionViewCell)?.imageView.isHidden = true
            })
            
            transitionContext.containerView.addSubview(transitionView)
            
            UIView.animate(withDuration: 0.5, animations: {
                
                fromVC?.view.alpha = 0
                
                self.transitionView?.frame = self.imageFrameArray[self.currentIndex]
                
            }) { (complete) in
                self.transitionView?.removeFromSuperview()
                transitionContext.completeTransition(true)
            }
        }
    }
    
    deinit {
        print(#file.components(separatedBy: "/").last ?? ""," released")
    }
}
