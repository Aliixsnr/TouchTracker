//
//  DrawLine.swift
//  TouchTracker
//
//  Created by Alex on 3/20/18.
//  Copyright © 2018 Yuhbok. All rights reserved.
//

import UIKit
class DrawView: UIView, UIGestureRecognizerDelegate {
    var currentLines = [NSValue:Line]()
    var finnishedLines = [Line]()
    var moveRecognizer: UIPanGestureRecognizer!
    var selectedLineIndex : Int? {
        didSet {
            if selectedLineIndex == nil {
                let menu = UIMenuController.shared
                menu.setMenuVisible(false, animated: true)
            }
        }
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let doubleTapRecoginzer = UITapGestureRecognizer(target: self, action: #selector(DrawView.doubleTap(_:)))
        doubleTapRecoginzer.numberOfTapsRequired = 2
        doubleTapRecoginzer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecoginzer)
        
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(DrawView.tap(_:)))
        tapRecognizer.delaysTouchesBegan = true
        // double tap has to fail
        tapRecognizer.require(toFail: doubleTapRecoginzer)
        addGestureRecognizer(tapRecognizer)
        
        let longPressRecoginzer = UILongPressGestureRecognizer(target: self, action: #selector(DrawView.longPress(_:)))
        addGestureRecognizer(longPressRecoginzer)
        
        moveRecognizer = UIPanGestureRecognizer(target: self, action: #selector(DrawView.moveLine(_:)))
        moveRecognizer.delegate = self
        moveRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(moveRecognizer)
      
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    @objc func moveLine(_ gestureRecognizer: UIPanGestureRecognizer){
        print("Reconized pan ")
        // If a line was selected
        if let index = selectedLineIndex {
        // When the pan recgonexer chanes its positon..
            if gestureRecognizer.state == . changed{
                // How far has the gesture moved
                let translation = gestureRecognizer.translation(in: self)
                // add the translation to the current beginning and end pots of the line and make sure ther are no co copy and paste typos!
                    finnishedLines[index].begin.x += translation.x
                    finnishedLines[index].begin.y += translation.y
                    finnishedLines[index].end.x += translation.x
                    finnishedLines[index].end.y += translation.y
                
                    gestureRecognizer.setTranslation(CGPoint.zero, in: self)
                
                // Redraw the screen
                    setNeedsDisplay()
                
            }
            
        } else {
            // iF NO LINE SELECTED
            return
        }
    }
    @objc func longPress(_ gestureRecognizer: UIGestureRecognizer){
        print("Long Press Recognized")
        
        if gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: self)
            selectedLineIndex = indexOfLine(at: point)
            
            if selectedLineIndex != nil {
                currentLines.removeAll()
            }
        } else if gestureRecognizer.state == .ended {
            selectedLineIndex = nil
        }
        setNeedsDisplay()
    }
   @objc func tap(_ gestureRecognizer: UITapGestureRecognizer)  {
        print("Tap recognzed")
    // get the location of the point tapped
    let point = gestureRecognizer.location(in: self)
    selectedLineIndex = indexOfLine(at: point)
    
    // Grabs the menu controller
    let menu = UIMenuController.shared

    if selectedLineIndex != nil {
        // make drawview the targe of menut item action messages
        becomeFirstResponder()
        
        // create a new "Delete" UIMENU
        let deleteItem = UIMenuItem(title: "Delete", action: #selector(DrawView.deleteItem(_:)))
        menu.menuItems = [deleteItem]
        
        // tell the menu where it should come from and show it
        let targetRect = CGRect(x: point.x, y: point.y, width: 2, height: 2)
        menu.setTargetRect(targetRect, in: self)
        menu.setMenuVisible(true, animated: true)
    } else {
        menu.setMenuVisible(false, animated: true)
        
    }
    
    setNeedsDisplay()
    }
      override var canBecomeFirstResponder : Bool {
            return true
        }
    
   @objc func deleteItem(_ sender: UIMenuController){
        // Remove the selected line fropm thje list of finnished lines
        if let index = selectedLineIndex {
            finnishedLines.remove(at: index)
            selectedLineIndex = nil
            
            // redraw everthing
            setNeedsDisplay()
        }
        
    }
    
    // Draws the stroke
    func stroke(_ line: Line){
        let path = UIBezierPath()
        
        path.lineCapStyle = .round
        
        path.move(to: line.begin)
        path.addLine(to: line.end)
        path.stroke()
        
    }
    override func draw(_ rect: CGRect) {
        // DRAWS A LINE
        finnisheLineColor.setStroke()
        for line in finnishedLines {
            stroke(line)
        }
        currentLineColor.setStroke()
        for (_,line) in currentLines {
            stroke(line)
        }
        if let index = selectedLineIndex {
            UIColor.green.setStroke()
            let selectedLine = finnishedLines[index]
            stroke(selectedLine)
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        for touch in touches{
        // get location of the touch in the views coordinated system
            let location = touch.location(in: self)
            let newline = Line(begin: location, end: location)
            let key = NSValue(nonretainedObject: touch)
            currentLines[key] = newline
        }
        setNeedsDisplay()
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        for touch in touches {
            let key = NSValue(nonretainedObject: touch)
            currentLines[key]?.end = touch.location(in: self)
            
        }
        
        setNeedsDisplay()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        for touch in touches {
            let key = NSValue(nonretainedObject: touch)
            if var line = currentLines[key]{
                line.end = touch.location(in: self)
                finnishedLines.append(line)
                currentLines.removeValue(forKey: key)
            }
            
        }
       setNeedsDisplay()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        currentLines.removeAll()
        setNeedsDisplay()
    }
    @IBInspectable var finnisheLineColor: UIColor = UIColor.black {
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable var currentLineColor: UIColor = UIColor.red {
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable var lineThickness: CGFloat = 10 {
        didSet {
            setNeedsDisplay()
        }
    }
    @objc func doubleTap(_ gestureRecognizer: UIGestureRecognizer){
        print("Recognized a double tap")
        selectedLineIndex = nil
        currentLines.removeAll()
        finnishedLines.removeAll()
        setNeedsDisplay()
    }
    // returns the index of the lione closes to the given point
    func indexOfLine(at point: CGPoint) -> Int? {
        // Find the line close to point
        for (index, line) in finnishedLines.enumerated() {
            let begin = line.begin
            let end = line.end
            
            // check a few points on the line
            for t in stride(from: CGFloat(0), to: 1.0, by: 0.05) {
                let x = begin.x + ((end.x - begin.x) * t)
                let y = begin.y + ((end.y - begin.y) * t)
                
                // if the tapped point is withing 20 points, lets reutrn this line
                if hypot(x - point.x, y - point.y) < 20.0 {
                    return index
                }
            }
        }
        // If nothing is close enough to the tapped point, then we did not select a line
        return nil
    }
    
}



















