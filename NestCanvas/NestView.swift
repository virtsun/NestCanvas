//
//  NestView.swift
//  NestCanvas
//
//  Created by 孙兰涛 on 2020/11/18.
//

import UIKit


class Point : UIView{

    var direction:CGPoint = .zero;
    
    override init(frame: CGRect) {
        super.init(frame: frame)
  
//        if arc4random_uniform(2) == 1{
//            self.animateOpacity()
//        }
//        if arc4random_uniform(5) == 1{
//            self.animateScale()
//        }
    }
    func animateOpacity() {
        let anim = CAKeyframeAnimation(keyPath: "opacity")
        anim.duration = CFTimeInterval(arc4random_uniform(10) + 1)
        anim.values = [0.1,0.3,0.2,0.0,0.2,0.3,0.5,0.8,1.0,0.7,0.5]
        anim.repeatCount = MAXFLOAT
        self.layer.add(anim, forKey: anim.keyPath)
    }
    func animateScale() {
        let anim = CAKeyframeAnimation(keyPath: "transform.scale")
        anim.duration = CFTimeInterval(arc4random_uniform(10) + 1)
        anim.values = [0.2,0.5,1.0,2.0,1.8,1.5,1.2,1.0]
        anim.repeatCount = MAXFLOAT
        self.layer.add(anim, forKey: anim.keyPath)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func draw(_ rect: CGRect) {
        
        // 创建色彩空间对象
        let rgb = CGColorSpaceCreateDeviceRGB();
        
        var cc = [[CGFloat(0x99), CGFloat(0x99),CGFloat(0x99), CGFloat(1)], [CGFloat(0x99), CGFloat(0x99), CGFloat(0x99), CGFloat(0)]].flatMap{$0}
        var locations:[CGFloat] = [1, 0]           //形成梯形，渐变的效果
        guard let gradient = CGGradient(colorSpace: rgb, colorComponents: &cc, locations: &locations, count: 2) else {
            return
        }
        let start = CGPoint(x: self.frame.size.width/2, y: self.frame.size.width/2);
        let end = CGPoint(x:self.frame.size.width/2, y:self.frame.size.height/2);
        let startRadius = CGFloat(0);
        let endRadius = CGFloat(self.frame.size.width/2);
        let context = UIGraphicsGetCurrentContext();
        context?.drawRadialGradient(gradient, startCenter: start, startRadius: startRadius, endCenter: end, endRadius: endRadius, options: .drawsAfterEndLocation)
    }
}

class NestView: UIView {
    lazy var shaperLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        
        layer.frame = self.bounds
        layer.strokeColor = UIColor.black.withAlphaComponent(0.1).cgColor
        layer.lineWidth = 0.5;
        layer.fillColor = UIColor.clear.cgColor
        
        return layer
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.randomPoints()
        
        self.layer.addSublayer(self.shaperLayer)
        
        let link = CADisplayLink(target: self, selector: #selector(move(_:)))
        link.preferredFramesPerSecond = 24
        link.add(to: .current, forMode: .default)
        
        let swipe = UIPanGestureRecognizer(target: self, action: #selector(swipe(gesture:)))
        self.addGestureRecognizer(swipe)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    internal var points = [Point]()
    func randomPoints() {
        for _ in 0...100 {
            let p = Point(frame: CGRect(x: 0, y: 0, width: 5, height: 5))
            let w = UInt32(self.frame.width)
            let h = UInt32(self.frame.height)

            p.direction = randomSpeed()
            p.center = CGPoint(x: Int(arc4random_uniform(w)), y: Int(arc4random_uniform(h)))
            self.addSubview(p)
            self.points.append(p)
        }
    }
    func randomSpeed() -> CGPoint {
        let speedX = CGFloat(arc4random_uniform(100)+1) / CGFloat(200.0)
        let speedY = CGFloat(arc4random_uniform(100)+1) / CGFloat(200.0)

        return CGPoint(x: speedX * (arc4random_uniform(2) > 0 ? 1 : -1), y: speedY * (arc4random_uniform(2) > 0 ? 1 : -1))
    }
    
    internal var timestamp : UInt64 = 0
    @objc
    func move(_ link:CADisplayLink) {
        defer{
            self.timestamp += 1;
        }
        
        for p in self.points{
            let x = p.center.x + p.direction.x;
            let y = p.center.y + p.direction.y;
            p.center = CGPoint(x: x, y: y)
            
            ///检测碰撞，到边缘时，重新设定速度
            var collision:Bool = false
            if (p.direction.x + p.frame.minX < 0
                || p.direction.x + p.frame.maxX > self.frame.width){
                collision = true
            }
            if (p.direction.y + p.frame.minY < 0
                || p.direction.y + p.frame.maxY > self.frame.height){
                collision = true
            }
            if collision {
                p.direction = randomSpeed()
            }
        }
        if self.timestamp % UInt64(link.preferredFramesPerSecond) == 0 {
            linePoints()
        }

        drawLines()
    }
    var pointGroup = [[UIView]]()
    func linePoints() {
        
        var xx = self.points.map{$0}
        
        pointGroup.removeAll()
        
        while xx.count > 0 {
            guard let t = xx.first else {
                break
            }
            var a = [t]
            for (idx, p) in xx.enumerated(){
                if idx == 0 {continue}
                
                for e in a{
                    let x = abs(e.center.x - p.center.x);
                    let y = abs(e.center.y - p.center.y);
                    
                    if (x < 50 && y < 50 && a.count < 5){
                        a.append(p)
                        break
                    }
                }
                
            }
            for c in a.reversed(){
                guard let i = xx.firstIndex(of: c) else {
                    continue
                }
                xx.remove(at: i)
            }
            if a.count > 0{
                pointGroup.append(a)
            }
        }
       
    }
    
    func drawLines() {
        let bezier = UIBezierPath()
        
        for a in self.pointGroup {
            
            guard let b = a.first,
                  a.count > 1 else {
                continue
            }
            bezier.move(to: b.center)
            
            for idx in 1...a.count-1{
                bezier.addLine(to: a[idx].center)
            }
        }
        self.shaperLayer.path = bezier.cgPath
    }
    
     
    lazy var animator = {() -> UIDynamicAnimator in
        return UIDynamicAnimator(referenceView: self)
    }()
    
    internal var attachments = [UIAttachmentBehavior]()
    @objc
    func swipe(gesture:UIGestureRecognizer) {
        
        let p = gesture.location(in: self)
        if gesture.state == .began{
            for point in self.points {
                if abs(Int32(point.center.x - p.x)) < 50 && abs(Int32(point.center.y - p.y)) < 50{
                    let attach = UIAttachmentBehavior(item: point, attachedToAnchor: p)
                    self.animator.addBehavior(attach)
                    self.attachments.append(attach)
                }
            }
            
        }else if gesture.state == .changed{
            _ = self.attachments.map{$0.anchorPoint = p}
        }else{
            self.animator.removeAllBehaviors()
            self.attachments.removeAll()
        }
       
    }
    
}
