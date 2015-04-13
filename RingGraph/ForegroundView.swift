//
//  ForegroundView.swift
//  RingMeter
//
//  Created by Michał Kreft on 01/04/15.
//  Copyright (c) 2015 Michał Kreft. All rights reserved.
//

import UIKit

enum GraphViewDescriptionPreset {
    case None
    case CentralDescription
    case MetersDescription
}

internal class ForegroundView: UIView {
    let graph: RingGraph
    let descriptionPreset: GraphViewDescriptionPreset
    var animationState: AnimationState
    var displayLink: CADisplayLink?
    var ringDescriptionLabels = [FadeOutLabel]()
    var progressTextView: ProgressTextView?
    
    required init(frame: CGRect, graph: RingGraph, preset: GraphViewDescriptionPreset) {
        self.graph = graph
        descriptionPreset = preset
        animationState = AnimationState(totalDuration: 1.3, progress: 1.0)
        
        super.init(frame: frame)
        backgroundColor = UIColor.clearColor()
        
        switch descriptionPreset {
        case .CentralDescription:
            addProgressTextView()
        case .MetersDescription:
            addRingDescriptionLabels()
        case .None:
            break
        }
        
    }
    
    required init(coder aDecoder: NSCoder) { //ugh!
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawRect(rect: CGRect) {
        if isAnimating() {
            animationState.incrementDuration(displayLink!.duration)
        }
        
        let animationProgress = animationState.progress()

        if isAnimating() && animationProgress == 1.0 {
            endAnimation()
        }
        
        let ringAnimationState = RingGraphAnimationState(graph: graph, animationProgress: animationProgress)
        
        let painter = RignGraphPainter(ringGraph: graph, drawingRect: rect, context: UIGraphicsGetCurrentContext())
        painter.drawForeground(ringAnimationState)
        
        for label in ringDescriptionLabels {
            label.setAnimationProgress(animationProgress)
        }
        
        if let progressTextView = self.progressTextView {
            progressTextView.setAnimationProgress(animationProgress)
        }
    }
    
    func animate() {
        if isAnimating() {
            endAnimation()
        }
        
        displayLink = CADisplayLink(target: self, selector: "setNeedsDisplay")
        displayLink!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        animationState.currentTime = 0.0
    }
}

private extension ForegroundView {
    private func isAnimating() -> Bool {
        return displayLink != nil
    }
    
    private func endAnimation() {
        if isAnimating() {
            displayLink!.invalidate()
            displayLink = nil
        }
    }
    
    private func addRingDescriptionLabels() {
        let painter = RignGraphPainter(ringGraph: graph, drawingRect: self.frame)
        
        for (index, labelFrame) in enumerate(painter.framesForDescriptionLabels()) {
            let meter = graph.meters[index]
            let label = FadeOutLabel(frame: labelFrame)
            label.text = meter.title.uppercaseString
            label.textAlignment = .Right
            label.font = UIFont.boldSystemFontOfSize(20.0)
            label.textColor = meter.descriptionLabelColor
            self.addSubview(label)
            ringDescriptionLabels.append(label)
        }
    }
    
    private func addProgressTextView() {
        let painter = RignGraphPainter(ringGraph: graph, drawingRect: self.frame)
        
        let view = ProgressTextView(frame: painter.frameForDescriptionText(), ringMeter: graph.meters.first!)
        addSubview(view)
        progressTextView = view
    }
}