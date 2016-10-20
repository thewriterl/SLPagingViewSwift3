//
//  File.swift
//  NavigationBar
//
//  Created by Luiz Fernando França on 10/20/16.
//  Copyright © 2016 Luiz Fernando França. All rights reserved.
//

import UIKit

public enum SLNavigationSideItemsStyle: Int {
    case SLNavigationSideItemsStyleOnBounds = 40
    case SLNavigationSideItemsStyleClose = 30
    case SLNavigationSideItemsStyleNormal = 20
    case SLNavigationSideItemsStyleFar = 10
    case SLNavigationSideItemsStyleDefault = 0
    case SLNavigationSideItemsStyleCloseToEachOne = -40
}

public typealias SLPagingViewMoving = ((_ subviews: [UIView])-> ())
public typealias SLPagingViewMovingRedefine = ((_ scrollView: UIScrollView, _ subviews: NSArray)-> ())
public typealias SLPagingViewDidChanged = ((_ currentPage: Int)-> ())

public class SLPagingViewSwift: UIViewController, UIScrollViewDelegate {
    
    // MARK: - Public properties
    var views = [Int : UIView]()
    public var currentPageControlColor: UIColor?
    public var tintPageControlColor: UIColor?
    public var pagingViewMoving: SLPagingViewMoving?
    public var pagingViewMovingRedefine: SLPagingViewMovingRedefine?
    public var didChangedPage: SLPagingViewDidChanged?
    public var navigationSideItemsStyle: SLNavigationSideItemsStyle = .SLNavigationSideItemsStyleDefault

    
    // MARK: - Private properties
    private var SCREENSIZE: CGSize {
        return UIScreen.main.bounds.size
    }
    private var scrollView: UIScrollView!
    private var pageControl: UIPageControl!
    private var navigationBarView: UIView = UIView()
    private var navItems: [UIView] = []
    private var needToShowPageControl: Bool = false
    private var isUserInteraction: Bool = false
    private var indexSelected: Int = 0

    // MARK: - Constructors
    public required init(coder decoder: NSCoder) {
        super.init(coder: decoder)!
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        // Here you can init your properties
    }

    // MARK: - Constructors with items & views
    public convenience init(items: [UIView], views: [UIView]) {
        self.init(items: items, views: views, showPageControl:false, navBarBackground: UIColor.white)
    }

    public convenience init(items: [UIView], views: [UIView], showPageControl: Bool){
        self.init(items: items, views: views, showPageControl:showPageControl, navBarBackground:UIColor.white)
    }
    
    public init(items: [UIView], views: [UIView], showPageControl: Bool, navBarBackground: UIColor) {
        super.init(nibName: nil, bundle: nil)
        needToShowPageControl = showPageControl
        navigationBarView.backgroundColor = navBarBackground
        isUserInteraction = true
        for (i, v) in items.enumerated() {
            let vSize: CGSize = (v as? UILabel)?._slpGetSize() ?? v.frame.size
            let originX = (self.SCREENSIZE.width/2.0 - vSize.width/2.0) + CGFloat(i * 100)
            v.frame = CGRect(x: originX,y: 8,width: vSize.width,height: vSize.height)
            v.tag = i
            let tap = UITapGestureRecognizer(target: self, action: Selector(("tapOnHeader:")))
            v.addGestureRecognizer(tap)
            v.isUserInteractionEnabled = true
            self.navigationBarView.addSubview(v)
            self.navItems.append(v)
        }
        
        for (i, view) in views.enumerated() {
            view.tag = i
            self.views[i] = view
        }
    }

    // MARK: - Constructors with controllers
    public convenience init(controllers: [UIViewController]){
       self.init(controllers: controllers, showPageControl: true, navBarBackground: UIColor.white)
    }
    
    public convenience init(controllers: [UIViewController], showPageControl: Bool){
        self.init(controllers: controllers, showPageControl: true, navBarBackground: UIColor.white)
    }

    public convenience init(controllers: [UIViewController], showPageControl: Bool, navBarBackground: UIColor){
        var views = [UIView]()
        var items = [UILabel]()
        for ctr in controllers {
            let item  = UILabel()
            item.text = ctr.title
            views.append(ctr.view)
            items.append(item)
        }
        self.init(items: items, views: views, showPageControl:showPageControl, navBarBackground:navBarBackground)
    }
    
    // MARK: - Constructors with items & controllers
    public convenience init(items: [UIView], controllers: [UIViewController]){
        self.init(items: items, controllers: controllers, showPageControl: true, navBarBackground: UIColor.white)
    }
    public convenience init(items: [UIView], controllers: [UIViewController], showPageControl: Bool){
        self.init(items: items, controllers: controllers, showPageControl: showPageControl, navBarBackground: UIColor.white)
    }

    public convenience init(items: [UIView], controllers: [UIViewController], showPageControl: Bool, navBarBackground: UIColor){
        var views = [UIView]()
        for ctr in controllers {
            views.append(ctr.view)
        }
        self.init(items: items, views: views, showPageControl:showPageControl, navBarBackground:navBarBackground)
    }
    
    // MARK: - Life cycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.setupPagingProcess()
        self.setCurrentIndex(index: self.indexSelected, animated: false)
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.navigationBarView.frame = CGRect(x: 0,y: 0,width: self.SCREENSIZE.width,height: 44)
    }
    
    // MARK: - Public methods
    public func updateUserInteractionOnNavigation(active: Bool){
        self.isUserInteraction = active
    }
    
    public func setCurrentIndex(index: Int, animated: Bool){
        // Be sure we got an existing index
        if(index < 0 || index > self.navigationBarView.subviews.count-1){
            let exc = NSException(name: NSExceptionName(rawValue: "Index out of range"), reason: "The index is out of range of subviews's countsd!", userInfo: nil)
            exc.raise()
        }
        self.indexSelected = index
        // Get the right position and update it
        let xOffset = CGFloat(index) * self.SCREENSIZE.width
        self.scrollView.setContentOffset(CGPoint(x: xOffset,y: self.scrollView.contentOffset.y), animated: animated)
    }
    
    // MARK: - Internal methods
    private func setupPagingProcess() {
        let frame: CGRect = CGRect(x: 0,y: 0,width: SCREENSIZE.width,height: self.view.frame.height)
        
        self.scrollView = UIScrollView(frame: frame)
        self.scrollView.backgroundColor = UIColor.clear
        self.scrollView.isPagingEnabled = true
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.delegate = self
        self.scrollView.bounces = false
        self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -80, right: 0)
        self.view.addSubview(self.scrollView)
        
        // Adds all views
        self.addViews()
        
        if(self.needToShowPageControl){
            // Make the page control
            self.pageControl = UIPageControl(frame: CGRect(x: 0,y: 35,width: 0,height: 0))
            self.pageControl.numberOfPages = self.navigationBarView.subviews.count
            self.pageControl.currentPage = 0
            if self.currentPageControlColor != nil {
                self.pageControl.currentPageIndicatorTintColor = self.currentPageControlColor
            }
            if self.tintPageControlColor != nil {
                self.pageControl.pageIndicatorTintColor = self.tintPageControlColor
            }
            self.navigationBarView.addSubview(self.pageControl)
        }
        
        self.navigationController?.navigationBar.addSubview(self.navigationBarView)
        
    }
    
    // Loads all views
    private func addViews() {
        if self.views.count > 0 {
            let width = SCREENSIZE.width * CGFloat(self.views.count)
            let height = self.view.frame.height
            self.scrollView.contentSize = CGSize(width: width, height: height)
            var i: Int = 0
            while let v = views[i] {
                v.frame = CGRect(x: self.SCREENSIZE.width * CGFloat(i),y:  0,width: self.SCREENSIZE.width,height: self.SCREENSIZE.height)
                self.scrollView.addSubview(v)
                i += 1
            }
        }
    }
    
  
    private func sendNewIndex(scrollView: UIScrollView){
        let xOffset = Float(scrollView.contentOffset.x)
        let currentIndex = (Int(roundf(xOffset)) % (self.navigationBarView.subviews.count * Int(self.SCREENSIZE.width))) / Int(self.SCREENSIZE.width)
        if self.needToShowPageControl && self.pageControl.currentPage != currentIndex {
            self.pageControl.currentPage = currentIndex
            self.didChangedPage?(currentIndex)
        }
    }
    
    func getOriginX(vSize: CGSize, idx: CGFloat, distance: CGFloat, xOffset: CGFloat) -> CGFloat{
        var result = self.SCREENSIZE.width / 2.0 - vSize.width/2.0
        result += (idx * distance)
        result -= xOffset / (self.SCREENSIZE.width / distance)
        return result
    }
    
    // Scroll to the view tapped
    func tapOnHeader(recognizer: UITapGestureRecognizer){
        if let key = recognizer.view?.tag, let view = self.views[key] , self.isUserInteraction {
            self.scrollView.scrollRectToVisible(view.frame, animated: true)
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let xOffset = scrollView.contentOffset.x
        let distance = CGFloat(100 + self.navigationSideItemsStyle.rawValue)
        for (i, v) in self.navItems.enumerated() /*(self.navItems) */ {
            let vSize = v.frame.size
            let originX = self.getOriginX(vSize: vSize, idx: CGFloat(i), distance: CGFloat(distance), xOffset: xOffset)
            v.frame = CGRect(x: originX,y: 8,width: vSize.width,height: vSize.height)
        }
        self.pagingViewMovingRedefine?(scrollView, self.navItems as NSArray)
        self.pagingViewMoving?(self.navItems)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.sendNewIndex(scrollView: scrollView)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.sendNewIndex(scrollView: scrollView)
    }
    
}


extension UILabel {
    func _slpGetSize() -> CGSize? {
        return (text as NSString?)?.size(attributes: [NSFontAttributeName: font])
    }
}
