//
//  ViewController.swift
//  Photo Editor
//
//  Created by Mohamed Hamed on 4/23/17.
//  Copyright © 2017 Mohamed Hamed. All rights reserved.
//

import UIKit

public final class PhotoEditorViewController: UIViewController {
    
    /** holding the 2 imageViews original image and drawing & stickers */
    @IBOutlet weak var canvasView: UIView!
    //To hold the image
    @IBOutlet var imageView: UIImageView!
    //To hold the drawings and stickers
    @IBOutlet weak var canvasImageView: UIImageView!
    // (tfountain) To hold the containing scrollview
    @IBOutlet weak var scrollView: UIScrollView!
    // (tfountain) Constraints for zooming the image
    @IBOutlet weak var innerView: UIView!
    @IBOutlet weak var innerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var innerViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var innerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var innerViewTrailingConstraint: NSLayoutConstraint!

    @IBOutlet weak var topToolbar: UIView!
    @IBOutlet weak var bottomToolbar: UIView!

    @IBOutlet weak var topGradient: UIView!
    @IBOutlet weak var bottomGradient: UIView!
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var colorsCollectionView: UICollectionView!
    @IBOutlet weak var colorPickerView: UIView!
    @IBOutlet weak var colorPickerViewBottomConstraint: NSLayoutConstraint!
    
    //Controls
    @IBOutlet weak var cropButton: UIButton!
    @IBOutlet weak var stickerButton: UIButton!
    @IBOutlet weak var drawButton: UIButton!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    public var image: UIImage?
    /**
     Array of Stickers -UIImage- that the user will choose from
     */
    public var stickers : [UIImage] = []
    /**
     Array of Colors that will show while drawing or typing
     */
    public var colors  : [UIColor] = []
    
    public var photoEditorDelegate: PhotoEditorDelegate?
    var colorsCollectionViewDelegate: ColorsCollectionViewDelegate!
    
    // list of controls to be hidden
    public var hiddenControls : [control] = []

    public var lineDrawWidth: Float = 15.0
    var scaledLineDrawWidth: Float = 15.0
    
    var stickersVCIsVisible = false
    var drawColor: UIColor = UIColor.black
    var textColor: UIColor = UIColor.white
    var isDrawing: Bool = false
    var lastPoint: CGPoint!
    var swiped = false
    var lastPanPoint: CGPoint?
    var lastTextViewTransform: CGAffineTransform?
    var lastTextViewTransCenter: CGPoint?
    var lastTextViewFont:UIFont?
    var activeTextView: UITextView?
    var imageViewToPan: UIImageView?
    var isTyping: Bool = false
    
    var stickersViewController: StickersViewController!

    //Register Custom font before we load XIB
    public override func loadView() {
        registerFont()
        super.loadView()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.setImageView(image: image!)
        
        scrollView.contentSize = image!.size
        
        scaledLineDrawWidth = lineDrawWidth
        
        deleteView.layer.cornerRadius = deleteView.bounds.height / 2
        deleteView.layer.borderWidth = 2.0
        deleteView.layer.borderColor = UIColor.white.cgColor
        deleteView.clipsToBounds = true
        
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        edgePan.edges = .bottom
        edgePan.delegate = self
        self.view.addGestureRecognizer(edgePan)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow),
                                               name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(keyboardWillChangeFrame(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        
        configureCollectionView()
        stickersViewController = StickersViewController(nibName: "StickersViewController", bundle: Bundle(for: StickersViewController.self))
        hideControls()
    }
    
    override public func viewWillLayoutSubviews() {
      super.viewWillLayoutSubviews()
      updateMinZoomScaleForSize(view.bounds.size)
    }
    
    func updateMinZoomScaleForSize(_ size: CGSize) {
      let widthScale = size.width / innerView.bounds.width
      let heightScale = size.height / innerView.bounds.height
      let minScale = min(widthScale, heightScale)
        
      scrollView.minimumZoomScale = minScale
      scrollView.zoomScale = minScale
      
      updateLineWidth()
    }
    
    func updateLineWidth() {
        scaledLineDrawWidth = lineDrawWidth / Float(scrollView.zoomScale)
    }
    
    func configureCollectionView() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 30, height: 30)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        colorsCollectionView.collectionViewLayout = layout
        colorsCollectionViewDelegate = ColorsCollectionViewDelegate()
        colorsCollectionViewDelegate.colorDelegate = self
        if !colors.isEmpty {
            colorsCollectionViewDelegate.colors = colors
        }
        colorsCollectionView.delegate = colorsCollectionViewDelegate
        colorsCollectionView.dataSource = colorsCollectionViewDelegate
        
        colorsCollectionView.register(
            UINib(nibName: "ColorCollectionViewCell", bundle: Bundle(for: ColorCollectionViewCell.self)),
            forCellWithReuseIdentifier: "ColorCollectionViewCell")
    }
    
    func setImageView(image: UIImage) {
//        let size = image.suitableSize(widthLimit: UIScreen.main.bounds.width * 2)
        imageView.image = image
        imageView.bounds = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        canvasImageView.bounds = imageView.bounds
        innerView.bounds = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
//        imageViewHeightConstraint.constant = (size?.height)!
    }
    
    func hideToolbar(hide: Bool) {
        topToolbar.isHidden = hide
        topGradient.isHidden = hide
        bottomToolbar.isHidden = hide
        bottomGradient.isHidden = hide
    }

    public func setScrollViewEnabled(enabled: Bool) {
        scrollView.isUserInteractionEnabled = enabled
    }
}

extension PhotoEditorViewController: ColorDelegate {
    func didSelectColor(color: UIColor) {
        if isDrawing {
            self.drawColor = color
        } else if activeTextView != nil {
            activeTextView?.textColor = color
            textColor = color
        }
    }
}

extension PhotoEditorViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return innerView
  }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
      updateConstraintsForSize(innerView.bounds.size)
        
      updateLineWidth()
    }
    
    func updateConstraintsForSize(_ size: CGSize) {
      let yOffset = max(0, (size.height - imageView.frame.height) / 2)
      innerViewTopConstraint.constant = yOffset
      innerViewBottomConstraint.constant = yOffset
      
      let xOffset = max(0, (size.width - imageView.frame.width) / 2)
      innerViewLeadingConstraint.constant = xOffset
      innerViewTrailingConstraint.constant = xOffset
        
      view.layoutIfNeeded()
    }
}
