//
//  ViewlayoutTestViewController.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/13.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class SnapKitTestView: UIView {
    
    var greenView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.red
        
        greenView.backgroundColor = UIColor.green
        self.addSubview(greenView)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = self.bounds.width
        let height = self.bounds.height
    
        greenView.frame = CGRect(0, 0, width, height)
    }
    
    
    
}

class PresentTestViewController : UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button1 = UIButton(frame: CGRect(0, 100, 100, 100))
        view.addSubview(button1)
        button1.backgroundColor = UIColor.red
        button1.setTitle("present", for: UIControlState.normal)
        button1.addTarget(self, action: #selector(onPresent), for: UIControlEvents.touchUpInside)
        
        let button2 = UIButton(frame: CGRect(0, 300, 100, 100))
        view.addSubview(button2)
        button2.backgroundColor = UIColor.red
        button2.setTitle("dismiss", for: UIControlState.normal)
        button2.addTarget(self, action: #selector(onDismiss), for: UIControlEvents.touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @objc func onPresent() {
        
        self.present(PresentTestViewController(), animated: true, completion: nil)
    }
    
    @objc func onDismiss() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
}

class CustomView: UITextView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        debug_print("CustomView layoutSubviews")
    }
}

class CurveLayerView: UIView {
    
    var ratio: CGFloat = 0.5
    
    override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }
    
    var shapeLayer: CAShapeLayer! {
        return self.layer as! CAShapeLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    var targetTransform: CGAffineTransform?
    
    var targetDate: Date?
    
    var duration = 0.3
 
    var displayLink: CADisplayLink?
    
    @objc func onTimer() {
        guard let targetDate = targetDate, let targetTransform = targetTransform, let displayLink = displayLink else { return }
        
        let i = CGFloat(displayLink.duration / (targetDate.timeIntervalSince1970 - Date().timeIntervalSince1970))
        if i <= 0 {
            if let targetTransform = self.targetTransform {
                self.transform = targetTransform
            }
            endTimer()
        }
        
        let a = targetTransform.a - transform.a
        let b = targetTransform.b - transform.b
        let c = targetTransform.c - transform.c
        let d = targetTransform.d - transform.d
        let tx = targetTransform.tx - transform.tx
        let ty = targetTransform.ty - transform.ty
        
        let newTransform = CGAffineTransform(a: i*a + transform.a, b: i*b + transform.b, c: i*c + transform.c, d: i*d + transform.d, tx: i*tx + transform.tx, ty: i*ty + transform.ty)
        
        self.transform = newTransform
    }
    
    func prepareTimer(targetTranform: CGAffineTransform) {
        endTimer()
        
        self.displayLink = CADisplayLink(target: self, selector: #selector(self.onTimer))
        self.targetTransform = targetTranform
        self.targetDate = Date.init(timeInterval: 3, since: Date())
        self.displayLink?.add(to: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    func endTimer() {
        displayLink?.invalidate()
        displayLink = nil
        targetTransform = nil
        targetDate = nil
    }
    
    
    func setHeight(_ height: CGFloat, withY y: CGFloat, animated: Bool = false) {
        
        if abs(height - self.height) < 0.1 && abs(y - self.top) < 0.1 {
            return
        }
        let scaleY =  max((height / self.bounds.height), 0.0001)
        if scaleY.isNaN {
            return
        }
        
        var newAnimated = false
        if UIView.inheritedAnimationDuration > 0.1{
            newAnimated = true
        }
        
        
        var transform = CGAffineTransform.identity
        let translatedY = y - self.layer.position.y + self.bounds.height/2 * scaleY
        transform = transform.translatedBy(x: 1, y: translatedY)
        transform = transform.scaledBy(x: 1, y: scaleY)
   
        if newAnimated {
            prepareTimer(targetTranform: transform)
        }
        else {
            endTimer()
            self.transform = transform
        }
    }
    
    func reload() {
        self.transform = CGAffineTransform.identity
        
        let width = self.bounds.width
        let layerHeight: CGFloat = self.bounds.height * ratio
        let controlPointHeight: CGFloat = (self.bounds.height - layerHeight) * 2.0 + layerHeight
        let bezier = UIBezierPath()
        bezier.move(to: CGPoint(x:0, y: layerHeight))
        bezier.addLine(to: CGPoint(x: 0,y: 0))
        bezier.addLine(to: CGPoint(x: width, y: 0))
        bezier.addLine(to: CGPoint(x: width, y: layerHeight))
        bezier.addQuadCurve(to: CGPoint(x: 0, y: layerHeight),
                            controlPoint: CGPoint(x: width / 2, y: controlPointHeight))
        
        shapeLayer.fillColor = UIColor.mpWarmPink2().cgColor
        shapeLayer.path = bezier.cgPath
    }
    

 
 
}


class HomeCurveView: UIImageView {
    
    var ratio: CGFloat = 0.5
    
    func reload() {
        
        let _ = UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 4)
        
        let width = self.bounds.width
        let layerHeight: CGFloat = self.bounds.height * ratio
        let controlPointHeight: CGFloat = (self.bounds.height - layerHeight) * 2.0 + layerHeight
        let bezier = UIBezierPath()
        bezier.move(to: CGPoint(x:0, y: layerHeight))
        bezier.addLine(to: CGPoint(x: 0,y: 0))
        bezier.addLine(to: CGPoint(x: width, y: 0))
        bezier.addLine(to: CGPoint(x: width, y: layerHeight))
        bezier.addQuadCurve(to: CGPoint(x: 0, y: layerHeight),
                            controlPoint: CGPoint(x: width / 2, y: controlPointHeight))
        UIColor.mpLightPink().setFill()
        bezier.fill()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.image = image
    }
}

class ViewLayoutTestViewModel: ViewModel {
 
    
    struct Input {
    }
    
    struct Output {
    }
    
    func transform(input: ViewLayoutTestViewModel.Input) -> ViewLayoutTestViewModel.Output {
        return Output.init()
    }
}


class ViewlayoutTestViewController: BaseViewController<ViewLayoutTestViewModel> {
    
    var customView: CustomView = CustomView()
    var customSubview: CustomView = CustomView()
    
    override func didBind(to viewModel: ViewLayoutTestViewModel?) {
        super.didBind(to: viewModel)
    }
    
    override func loadViewModel() -> ViewLayoutTestViewModel? {
        return ViewLayoutTestViewModel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        testSnapKit()
        testCurveView()
//        testTextView()
//        testPresent()
//        testAnimation()
//        testAnimation()
//        testSnapKit()
    }
    
    func testSnapKit() {
        
        let redView = SnapKitTestView()
   
        redView.frame = CGRect(0, 100, 375, 200)
        self.view.addSubview(redView)
        
      
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            UIView.animate(withDuration: 3) {
                redView.bounds = CGRect(0, 100, 200, 100)
                redView.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
                redView.layoutIfNeeded()
            }
        }
 
       
    }
    
    func testAnimation() {
        
        let v = UIView()
        view.addSubview(v)
        v.backgroundColor = UIColor.red
        v.frame = CGRect.init(100, 150, 100, 100)
        v.center = CGPoint(100,100)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(3)
        v.center = CGPoint(100,300)
        
        UIView.commitAnimations()
        
    
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            v.backgroundColor = UIColor.red
            v.frame = CGRect.init(100, 150, 100, 100)
            
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(1)
      
            v.center = CGPoint(100,500)
            
            UIView.commitAnimations()
        }
    }
    
    func testControllerWillAppear() {
        let controller = PresentTestViewController()
        controller.beginAppearanceTransition(true, animated: false)
        addChildViewController(controller)
        controller.endAppearanceTransition()
    }
    
    
    func testPresent() {
        let vc = PresentTestViewController()
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overCurrentContext
        
        self.present(vc, animated: true, completion: nil)
        
    }
    
    
    func testLabelSnapKit() {
        let label = UILabel()
        view.addSubview(label)
        
        let followLabel = UILabel()
        view.addSubview(followLabel)
        
        label.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: UILayoutConstraintAxis.horizontal)
        label.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(100)
            make.right.equalTo(followLabel.snp.left)
        }
        
        followLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: UILayoutConstraintAxis.horizontal)
        followLabel.snp.makeConstraints { (make) in
            make.right.lessThanOrEqualTo(self.view.snp.right).offset(-10)
            make.top.equalToSuperview().offset(100)
 
        }
        
        label.text = "阿什顿飞机"
        followLabel.text = "x2"
        
    }
    
    func testTextView() {
        
        let textView = UITextView()
        textView.frame = CGRect(10, 100, self.view.width - 20, 100)
        textView.isEditable = false
        textView.isSelectable = false
        textView.text = "asd按时;了肯德基福利卡萨减法;昆仑山;考虑对方;卡视角罚款了;1;卡神盾局;快乐发送;考虑对方;卡萨丁减法;快乐撒娇的;浪费开始打开放假啊;圣诞快乐放假啊快乐撒娇的疯狂拉升的疯狂拉升的法律;卡死;打开理发;快乐撒旦法律框架上大;福利卡;深刻了解asd按时;了肯德基福利卡萨减法;昆仑山;考虑对方;卡视角罚款了;1;卡神盾局;快乐发送;考虑对方;卡萨丁减法;快乐撒娇的;浪费开始打开放假啊;圣诞快乐放假啊快乐撒娇的疯狂拉升的疯狂拉升的法律;卡死;打开理发;快乐撒旦法律框架上大;福利卡;深刻了解asd按时;了肯德基福利卡萨减法;昆仑山;考虑对方;卡视角罚款了;1;卡神盾局;快乐发送;考虑对方;卡萨丁减法;快乐撒娇的;浪费开始打开放假啊;圣诞快乐放假啊快乐撒娇的疯狂拉升的疯狂拉升的法律;卡死;打开理发;快乐撒旦法律框架上大;福利卡;深刻了解asd按时;了肯德基福利卡萨减法;昆仑山;考虑对方;卡视角罚款了;1;卡神盾局;快乐发送;考虑对方;卡萨丁减法;快乐撒娇的;浪费开始打开放假啊;圣诞快乐放假啊快乐撒娇的疯狂拉升的疯狂拉升的法律;卡死;打开理发;快乐撒旦法律框架上大;福利卡;深刻了解asd按时;了肯德基福利卡萨减法;昆仑山;考虑对方;卡视角罚款了;1;卡神盾局;快乐发送;考虑对方;卡萨丁减法;快乐撒娇的;浪费开始打开放假啊;圣诞快乐放假啊快乐撒娇的疯狂拉升的疯狂拉升的法律;卡死;打开理发;快乐撒旦法律框架上大;福利卡;深刻了解asd按时;了肯德基福利卡萨减法;昆仑山;考虑对方;卡视角罚款了;1;卡神盾局;快乐发送;考虑对方;卡萨丁减法;快乐撒娇的;浪费开始打开放假啊;圣诞快乐放假啊快乐撒娇的疯狂拉升的疯狂拉升的法律;卡死;打开理发;快乐撒旦法律框架上大;福利卡;深刻了解"
        view.addSubview(textView)
        
    }
    
    func testCurveView() {
        
        let curveView = CurveLayerView()
        curveView.frame = CGRect(0, 300, view.width, 200)
        curveView.reload()
        curveView.backgroundColor = UIColor.black
        view.addSubview(curveView)
        
        curveView.clipsToBounds = true
 
 
//        UIView.beginAnimations(nil, context: nil)
//        UIView.setAnimationDuration(2)
 
//        CATransaction.begin()
//        CATransaction.setAnimationDuration(1)
//        CATransaction.setDisableActions(false)
//        curveView.layer.top = 100
//        CATransaction.commit()
//        UIView.commitAnimations()
        
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
//            UIView.beginAnimations(nil, context: nil)
//            UIView.setAnimationDuration(0.2)
//            curveView.top = 300
//
//
//
//
//            UIView.commitAnimations()
            
            CATransaction.begin()
            CATransaction.setAnimationDuration(1)
            CATransaction.setDisableActions(false)
            curveView.layer.top = 100
            CATransaction.commit()
        }
//
        self.kvoController.observe(curveView, keyPath: "frame", options: []) { (_, _, _) in
            print("curveView's frame: \(curveView.frame)")
        }
        
        
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
////            curveView.layer.removeAllAnimations()
//            curveView.center = CGPoint(self.view.width/2, 200)
//            UIView.animate(withDuration: 2, delay: 0, options: [UIViewAnimationOptions.allowUserInteraction, .beginFromCurrentState], animations: {
//                curveView.setHeight(100, withY: 80)
//            }, completion: nil)
//
////            curveView.setHeight(100, withY: 80)
//        }
//
        
        
        
    }
    
    func testLayout() {
        
        self.view.addSubview(customView)
        customView.frame = CGRect.init(x: 0, y: 100, width: self.view.width, height: 200)
        
        customView.addSubview(customSubview)
        
        var i: CGFloat = 0
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { (timer) in
            i += 0.1
            self.customSubview.frame = CGRect.init(x: 0, y: 0, width: 100, height: i)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
