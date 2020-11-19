//
//  NestView.swift
//  NestCanvas
//
//  Created by 孙兰涛 on 2020/11/18.
//

import UIKit


class Point : UIView{

    var direction:CGPoint = .zero;
   
    override func draw(_ rect: CGRect) {
        
        // 创建色彩空间对象
        let rgb = CGColorSpaceCreateDeviceRGB();
        
        var cc = [[CGFloat(255), CGFloat(255),CGFloat(255), CGFloat(0.0)], [CGFloat(255), CGFloat(255), CGFloat(255), CGFloat(1)]].flatMap{$0}
        var locations:[CGFloat] = [0, 1]           //形成梯形，渐变的效果
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
        layer.strokeColor = UIColor.black.withAlphaComponent(0.3).cgColor
        layer.lineWidth = 0.5;
        layer.fillColor = UIColor.clear.cgColor
        
        return layer
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.randomPoints()
        
        self.layer.addSublayer(self.shaperLayer)
        
        let link = CADisplayLink(target: self, selector: #selector(move))
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
            let speedX = CGFloat(arc4random_uniform(9)+1) / CGFloat(20.0)
            let speedY = CGFloat(arc4random_uniform(9)+1) / CGFloat(20.0)

            p.direction = CGPoint(x: speedX * (arc4random_uniform(2) > 0 ? 1 : -1), y: speedY * (arc4random_uniform(2) > 0 ? 1 : -1))
            p.center = CGPoint(x: Int(arc4random_uniform(w)), y: Int(arc4random_uniform(h)))
            self.addSubview(p)
            self.points.append(p)
        }
    }
    @objc
    func move() {
        for p in self.points{
            let x = p.center.x + p.direction.x;
            let y = p.center.y + p.direction.y;
            p.center = CGPoint(x: x, y: y)
            
            var collision:Bool = false
            if (p.direction.x + p.center.x < 0
                || p.direction.x + p.center.x > self.frame.width){
                collision = true
            }
            if (p.direction.y + p.center.y < 0
                || p.direction.y + p.center.y > self.frame.height){
                collision = true
            }
            if collision{
                p.direction = CGPoint(x: 0.1 * (arc4random_uniform(2) > 0 ? 1 : -1), y: 0.1 * (arc4random_uniform(2) > 0 ? 1 : -1))
            }
        }
        linePoints()
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
            var a = [Point]()
            a.append(t)
            for (idx, p) in xx.enumerated(){
                if idx == 0 {continue}
                
                let x = abs(t.center.x - p.center.x);
                let y = abs(t.center.y - p.center.y);
                
                if (x < 50 && y < 50 && a.count < 10){
                    a.append(p)
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
            let b = a.first
            bezier.move(to: b!.center)
            for c in a {
                bezier.addLine(to: c.center)
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
