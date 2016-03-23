//
//  GreedoCollectionViewLayout.swift
//  GreedoSwift
//
//  Created by dungvh on 3/7/16.
//  Copyright © 2016 dungvh. All rights reserved.
//

import Foundation
import UIKit

protocol GreedoCollectionViewLayoutDataSource:class{
    func greedoCollectionViewLayout(layout:GreedoCollectionViewLayout,originalImageSizeAtIndexPath indexPath:NSIndexPath) -> CGSize
}

// MARK: --- Main Class
class GreedoCollectionViewLayout {
    weak var dataSource:GreedoCollectionViewLayoutDataSource?
    var rowMaximumHeight:CGFloat = 100
    var cellPadding:CGFloat = 0
    
    private lazy var sizeCache:[NSIndexPath:CGSize] = {
        let cache = [NSIndexPath:CGSize]()
        return cache
    }()
    
    private lazy var leftOvers:[CGSize] = {
        let left = [CGSize]()
        return left
    }()
    
    private var lastIndexPathAdded:NSIndexPath!
    private weak var collectionView:UICollectionView?
    
    init(){
        
    }
    
    convenience init(collectionView:UICollectionView?){
        self.init()
        self.collectionView = collectionView
    }
    
    
    deinit{
        print("Deinit class:\(self.dynamicType)")
    }
}

// MARK: --- Public Function
extension GreedoCollectionViewLayout{
    func sizeForPhotoAtIndexPath(indexPath:NSIndexPath) ->CGSize{
        if sizeCache[indexPath] == nil{
            self.lastIndexPathAdded = indexPath
            self.computeSizesAtIndexPath(indexPath)
        }
        
        var size = self.sizeCache[indexPath] ?? CGSizeZero
        if size.width < 0 || size.height < 0 {
            size = CGSizeZero
        }
        
        return size
    }
    
    func clearCache(){
        self.sizeCache.removeAll()
    }
    
    func clearCacheAfterIndexPath(indexPath:NSIndexPath){
        // Remove the indexPath
        self.sizeCache.removeValueForKey(indexPath)
        
        // Remove the indexPath for anything after
        self.sizeCache.keys.forEach{
            if indexPath.compare($0) == NSComparisonResult.OrderedDescending
            {
                self.sizeCache.removeValueForKey($0)
            }
        }
    }
}

// MARK: --- Private Method
private extension GreedoCollectionViewLayout{
    func computeSizesAtIndexPath(indexPath:NSIndexPath){
        guard let collectionView = self.collectionView else{
            return
        }
        
        var contentWidth = collectionView.bounds.size.width
        var interitemSpacing:CGFloat = 0
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            contentWidth -= (layout.sectionInset.left + layout.sectionInset.right)
            interitemSpacing = layout.minimumInteritemSpacing
        }
        
        var photoSize = self.dataSource?.greedoCollectionViewLayout(self, originalImageSizeAtIndexPath: indexPath) ?? CGSizeZero
        self.leftOvers.append(photoSize)
        
        if photoSize.width < 1 || photoSize.height < 1 {
            // Photo with no height or width
            photoSize.width  = self.rowMaximumHeight
            photoSize.height = self.rowMaximumHeight
        }
        
        var totalWidth:CGFloat = 0.0
        for size in leftOvers {
            totalWidth += (size.width / size.height)
        }
        
        contentWidth -= CGFloat((self.leftOvers.count - 1)) * cellPadding
        
        let heightThatFits = contentWidth / totalWidth
        
        guard heightThatFits <= self.rowMaximumHeight else{
            // The line is not full, let's ask the next photo and try to fill up the line
            self.computeSizesAtIndexPath(NSIndexPath(forItem: indexPath.item + 1, inSection: indexPath.section))
            return
        }
        
        // The line is full!
        var availableSpace = contentWidth
        
        for leftOverSize in leftOvers {
            var newWidth = ceil((heightThatFits * leftOverSize.width) / leftOverSize.height)
            newWidth = min(availableSpace, newWidth)
            
            // Add the size in the cache
            self.sizeCache[self.lastIndexPathAdded] = CGSizeMake(newWidth, heightThatFits)
            
            availableSpace = availableSpace - newWidth - interitemSpacing
            
            // We need to keep track of the last index path added
            self.lastIndexPathAdded = NSIndexPath(forItem: self.lastIndexPathAdded.item + 1, inSection: self.lastIndexPathAdded.section)
        }
        
        self.leftOvers.removeAll()
    }
}
