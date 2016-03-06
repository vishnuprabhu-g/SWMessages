//
//  SWMessageView.swift
//
//  Copyright (c) 2016-present Sai Prasanna R
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

private let messageViewMinimumPadding :CGFloat = 15.0
private let swDesignFileName = "SWMessagesDefaultDesign"

public class SWMessageView :UIView , UIGestureRecognizerDelegate {
    
    /** The displayed title of this message */
    public let title :String
    
    /** The displayed subtitle of this message */
    public let subtitle :String?
    
    /** The view controller this message is displayed in */
    public let viewController :UIViewController

    public let buttonTitle :String?
    
    /** The duration of the displayed message. */
    public var duration :SWMessageDuration = .Automatic
    
    /** The position of the message (top or bottom or as overlay) */
    public var messagePosition :SWMessageNotificationPosition
    public var notificationType :SWMessageNotificationType
    
    /** Is the message currenlty fully displayed? Is set as soon as the message is really fully visible */
    public var messageIsFullyDisplayed = false
    
    /** Customize title font using UIApperance */
    public dynamic var titleFont :UIFont? {
        get {
            return titleLabel.font
        }
        set {
            titleLabel.font = newValue
        }
    }
    
    /** Customize title text color using UIApperance */
    public dynamic var titleTextColor :UIColor? {
        get {
            return titleLabel.textColor
        }
        set {
            titleLabel.textColor = newValue
        }
    }
    
    /** Customize content font using UIApperance */
    public dynamic var contentFont :UIFont? {
        get {
            return contentLabel.font
        }
        set {
            contentLabel.font = newValue
        }
    }
    
    /** Customize content text color using UIApperance */
    public dynamic var contentTextColor :UIColor? {
        get {
            return contentLabel.textColor
        }
        set {
            contentLabel.textColor = newValue
        }
    }
    
    /** Customize message icon using UIApperance */
    public dynamic var messageIcon :UIImage? {
        didSet {
            updateCurrentIcon()
        }
    }
    
    /** Customize error icon using UIApperance */
    public dynamic var errorIcon :UIImage? {
        didSet {
            updateCurrentIcon()
        }
    }
    
    /** Customize success icon using UIApperance */
    public dynamic var successIcon :UIImage? {
        didSet {
            updateCurrentIcon()
        }
    }
    
    /** Customize warning icon using UIApperance */
    public dynamic var warningIcon :UIImage? {
        didSet {
            updateCurrentIcon()
        }
    }
    
    private let titleLabel = UILabel()
    private lazy var contentLabel = UILabel()
    private var iconImageView :UIImageView?
    private var button :UIButton?
    private let backgroundBlurView = SWBlurView()
    private var textSpaceLeft :CGFloat = 0
    private var textSpaceRight :CGFloat = 0
    private var callback :(()-> Void)?
    private var buttonCallback :(()-> Void)?
    private let padding :CGFloat
    
    static private var notificationDesign :JSON = {
        let path = NSBundle(forClass: SWMessageView.self).pathForResource(swDesignFileName, ofType: "json")
        let data = NSData(contentsOfFile: path!)
        return JSON(data: data!)
    }()
    
    
    /** Used internally to modify design */
    class func addNotificationDesignFromFile(filename: String) {
        let path = NSBundle.mainBundle().pathForResource(filename, ofType: nil) ?? ""
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            SWMessageView.notificationDesign = JSON(data:NSData(contentsOfFile: path)!)
        }
        else {
            assert(false, "Error loading design file with name")
        }
    }
    
    /** 
     
     Inits the notification view. Do not call this from outside this library.
     
     - Parameter title:  The title of the notification view
     - Parameter subtitle:  The subtitle of the notification view (optional)
     - Parameter image:  A custom icon image (optional)
     - Parameter notificationType:  The type (color) of the notification view
     - Parameter duration:  The duration this notification should be displayed (optional)
     - Parameter viewController:  The view controller this message should be displayed in
     - Parameter callback:  The block that should be executed, when the user tapped on the message
     - Parameter buttonTitle:  The title for button (optional)
     - Parameter buttonCallback:  The block that should be executed, when the user tapped on the button
     - Parameter position:  The position of the message on the screen
     - Parameter dismissingEnabled:  Should this message be dismissed when the user taps/swipes it?
     */
    init(title :String,
        subtitle :String?,
        image :UIImage?,
        type :SWMessageNotificationType,
        duration :SWMessageDuration?,
        viewController :UIViewController,
        callback :(()-> Void)?,
        buttonTitle :String?,
        buttonCallback :(()-> Void)?,
        position :SWMessageNotificationPosition,
        dismissingEnabled :Bool)
    {
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.duration = duration ?? .Automatic
        self.viewController = viewController
        self.messagePosition = position
        self.callback = callback
        self.buttonCallback = buttonCallback
        let screenWidth: CGFloat = viewController.view.bounds.size.width
        self.padding = messagePosition == .NavBarOverlay ? messageViewMinimumPadding + 10 : messageViewMinimumPadding
        self.notificationType = type
        
        super.init(frame :CGRect.zero)
        
        let current: JSON
        let currentString: String
        switch notificationType {
        case .Message:
            currentString = "message"
        case .Error:
            currentString = "error"
        case .Success:
            currentString = "success"
        case .Warning:
            currentString = "warning"
        }
        
        current = SWMessageView.notificationDesign[currentString]
        let currentImage = image ?? bundledImageNamed(current["imageName"].stringValue) ?? UIImage(named: current["imageName"].stringValue)
        
        backgroundColor = UIColor.clearColor()
        backgroundBlurView.autoresizingMask = .FlexibleWidth
        backgroundBlurView.blurTintColor = UIColor(hexString: current["backgroundColor"].stringValue)
        addSubview(backgroundBlurView)
        
        let fontColor: UIColor = UIColor(hexString: current["textColor"].stringValue)
        textSpaceLeft = 2 * padding
        if let currentImage = currentImage {
            textSpaceLeft += currentImage.size.width + 2 * padding
            iconImageView = UIImageView(image: currentImage)
            iconImageView!.frame = CGRectMake(padding * 2, padding, currentImage.size.width, currentImage.size.height)
            addSubview(iconImageView!)
        }
        // Set up title label
        titleLabel.text = title
        titleLabel.textColor = fontColor
        titleLabel.backgroundColor = UIColor.clearColor()
        
        let fontSize  = CGFloat(current["titleFontSize"].floatValue)
        let fontName = current["titleFontName"].stringValue
        
        if fontName.characters.count > 0 {
            titleLabel.font = UIFont(name: fontName, size: fontSize )
        }
        else {
            titleLabel.font = UIFont.boldSystemFontOfSize(fontSize)
        }
        
        titleLabel.shadowColor = UIColor(hexString: current["shadowColor"].stringValue)
        titleLabel.shadowOffset = CGSizeMake(CGFloat(current["shadowOffsetX"].floatValue), CGFloat(current["shadowOffsetY"].floatValue))
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .ByWordWrapping
        addSubview(titleLabel)
        
        // Set up content label (if set)
        if subtitle?.characters.count > 0 {
            contentLabel.text = subtitle
            contentLabel.textColor = UIColor(hexString: current["contentTextColor"].stringValue) ?? fontColor
            contentLabel.backgroundColor = UIColor.clearColor()
            let fontSize = CGFloat(current["contentFontSize"].floatValue)
            let fontName  = current["contentFontName"].string
            if let fontName = fontName {
                contentLabel.font = UIFont(name: fontName, size: fontSize)
            }
            else {
                contentLabel.font = UIFont.systemFontOfSize(fontSize)
            }
            contentLabel.shadowColor = titleLabel.shadowColor
            contentLabel.shadowOffset = titleLabel.shadowOffset
            contentLabel.lineBreakMode = titleLabel.lineBreakMode
            contentLabel.numberOfLines = 0
            addSubview(contentLabel)
        }
        
        // Set up button (if set)
        if let buttonTitle = buttonTitle where buttonTitle.characters.count > 0 {
            button = UIButton(type: .Custom)
            var buttonBackgroundImage = bundledImageNamed(current["buttonBackgroundImageName"].stringValue) ?? UIImage(named: current["buttonBackgroundImageName"].stringValue)
            buttonBackgroundImage = buttonBackgroundImage?.resizableImageWithCapInsets(UIEdgeInsetsMake(15.0, 12.0, 15.0, 11.0))
            button?.setBackgroundImage(buttonBackgroundImage, forState: .Normal)
            button?.setTitle(buttonTitle, forState: .Normal)
            let buttonTitleShadowColor = UIColor(hexString: current["buttonTitleShadowColor"].stringValue) ?? titleLabel.shadowColor
            button?.setTitleShadowColor(buttonTitleShadowColor, forState: .Normal)
            let buttonTitleTextColor = UIColor(hexString: current["buttonTitleTextColor"].stringValue) ?? fontColor
            button?.setTitleColor(buttonTitleTextColor, forState: .Normal)
            button?.titleLabel?.font = UIFont.boldSystemFontOfSize(14.0)
            button?.titleLabel?.shadowOffset = CGSizeMake(CGFloat(current["buttonTitleShadowOffsetX"].floatValue), CGFloat(current["buttonTitleShadowOffsetY"].floatValue))
            button?.addTarget(self, action: "buttonTapped:", forControlEvents: .TouchUpInside)
            button?.contentEdgeInsets = UIEdgeInsetsMake(0.0, 5.0, 0.0, 5.0)
            button?.sizeToFit()
            button?.frame = CGRectMake(screenWidth - padding - button!.frame.size.width, 0.0, button!.frame.size.width, 31.0)
            addSubview(button!)
            textSpaceRight = button!.frame.size.width + padding
        }
        
        let actualHeight: CGFloat = updateHeightOfMessageView()
        // this call also takes care of positioning the labels
        var topPosition: CGFloat = -actualHeight
        if messagePosition == .Bottom {
            topPosition = viewController.view.bounds.size.height
        }
        frame = CGRectMake(0.0, topPosition, screenWidth, actualHeight)
        if messagePosition == .Top {
            autoresizingMask = .FlexibleWidth
        }
        else {
            autoresizingMask = ([.FlexibleWidth, .FlexibleTopMargin, .FlexibleBottomMargin])
        }
        if dismissingEnabled {
            let gestureRec: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "fadeMeOut")
            gestureRec.direction = (messagePosition == .Top ? .Up : .Down)
            addGestureRecognizer(gestureRec)
            let tapRec: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "fadeMeOut")
            addGestureRecognizer(tapRec)
        }
        if let _ = callback {
            let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
            tapGesture.delegate = self
            addGestureRecognizer(tapGesture)
        }
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateCurrentIcon() {
        let image :UIImage
        switch(notificationType) {
        case .Message :
            image = messageIcon!
            iconImageView?.image = messageIcon
        case .Error :
            image = errorIcon!
            iconImageView?.image = errorIcon
        case .Success :
            image = successIcon!
            iconImageView?.image = successIcon
        case .Warning :
            image = warningIcon!
            iconImageView?.image = warningIcon
        }
        iconImageView?.frame = CGRect(x: padding * 2, y: padding, width: image.size.width, height: image.size.height)
    }
    
    func updateHeightOfMessageView() -> CGFloat {
        var currentHeight: CGFloat
        let screenWidth: CGFloat = viewController.view.bounds.size.width
        titleLabel.frame = CGRectMake(textSpaceLeft, padding, screenWidth - padding - textSpaceLeft - textSpaceRight, 0.0)
        titleLabel.sizeToFit()
        if subtitle?.characters.count > 0 {
            contentLabel.frame = CGRectMake(textSpaceLeft, titleLabel.frame.origin.y + titleLabel.frame.size.height + 5.0, screenWidth - padding - textSpaceLeft - textSpaceRight, 0.0)
            contentLabel.sizeToFit()
            currentHeight = contentLabel.frame.origin.y + contentLabel.frame.size.height
        }
        else {
            // only the title was set
            currentHeight = titleLabel.frame.origin.y + titleLabel.frame.size.height
        }
        currentHeight += padding
        if let iconImageView = iconImageView {
            // Check if that makes the popup larger (height)
            if iconImageView.frame.origin.y + iconImageView.frame.size.height + padding > currentHeight {
                currentHeight = iconImageView.frame.origin.y + iconImageView.frame.size.height + padding
            }
            else {
                // z-align
                iconImageView.center = CGPointMake(iconImageView.center.x, round(currentHeight / 2.0))
            }
        }
        frame = CGRectMake(0.0, frame.origin.y, frame.size.width, currentHeight)
        if let button = button {
            // z-align button
            button.center = CGPointMake(button.center.x, round(currentHeight / 2.0))
            button.frame = CGRectMake(frame.size.width - textSpaceRight, round((frame.size.height / 2.0) - button.frame.size.height / 2.0), button.frame.size.width, button.frame.size.height)
        }
        var backgroundFrame: CGRect = CGRectMake(0, 0, screenWidth, currentHeight)
        // increase frame of background view because of the spring animation
        if messagePosition == .Top {
            var topOffset: CGFloat = 0.0
            let navigationController: UINavigationController? = viewController as? UINavigationController ?? viewController.navigationController
            
            if let nav = navigationController {
                let isNavBarIsHidden: Bool =  SWMessage.isNavigationBarInNavigationControllerHidden(nav)
                let isNavBarIsOpaque: Bool = !nav.navigationBar.translucent && nav.navigationBar.alpha == 1
                if isNavBarIsHidden || isNavBarIsOpaque {
                    topOffset = -30.0
                }
            }
            backgroundFrame = UIEdgeInsetsInsetRect(backgroundFrame, UIEdgeInsetsMake(topOffset, 0.0, 0.0, 0.0))
        }
        else if messagePosition == .Bottom {
            backgroundFrame = UIEdgeInsetsInsetRect(backgroundFrame, UIEdgeInsetsMake(0.0, 0.0, -30.0, 0.0))
        }
        backgroundBlurView.frame = backgroundFrame
        return currentHeight
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        updateHeightOfMessageView()
    }
    
    /** Fades out this notification view */
    public func fadeMeOut() {
        SWMessage.sharedMessage.performSelectorOnMainThread("fadeOutNotification:", withObject: self, waitUntilDone: false)
    }
    
    override  public func didMoveToWindow() {
        super.didMoveToWindow()
        if duration == SWMessageDuration.Endless && superview != nil && window == nil {
            // view controller was dismissed, let's fade out
            fadeMeOut()
        }
    }
    
    func buttonTapped(sender: AnyObject) {
        buttonCallback?()
        fadeMeOut()
    }
    
    func handleTap(tapGesture: UITapGestureRecognizer) {
        if tapGesture.state == .Recognized {
            callback?()
        }
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return touch.view is UIControl
    }
    
    private func bundledImageNamed(name: String) -> UIImage? {
        let bundle: NSBundle = NSBundle(forClass: self.dynamicType)
        let imagePath: String = bundle.pathForResource(name, ofType: nil) ?? ""
        return UIImage(contentsOfFile: imagePath)
    }
}

private class SWBlurView :UIView {
    
    var blurTintColor :UIColor? {
        get {
            return toolbar.barTintColor
        }
        set(newValue) {
            toolbar.barTintColor = newValue
        }
    }
    private lazy var toolbar :UIToolbar = {
        let toolbar = UIToolbar(frame: self.bounds)
        toolbar.userInteractionEnabled = false
        toolbar.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        toolbar.setBackgroundImage(nil, forToolbarPosition: .Any, barMetrics: .Default)
        self.addSubview(toolbar)
        return toolbar
    }()
}