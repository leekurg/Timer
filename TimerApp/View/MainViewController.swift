//
//  MainViewController.swift
//  TimerApp
//
//  Created by Ильяяя on 26.05.2022.
//


import UIKit
import SnapKit

class MainViewController: UIViewController {
    
    private let userDefaults = UserDefaults.standard
    private let timerInterval = 0.01
    
    private var timerLabel: UILabel!
    private var buttonStartPause: UIButton!
    private var buttonReset: UIButton!
    private var gestureReset: UILongPressGestureRecognizer!
    
    private var timer: Timer!
    private var timerValue: Double = 0.0 {
        didSet{
            updateTimerLabel()
        }
    }
    private var timerActive = false {
        didSet{
            if timerActive {
                buttonStartPause.setImage( UIImage(named: "pause.pdf"), for: .normal)
                
                buttonStartPause.backgroundColor = UIColor(red: 237/255, green: 65/255, blue: 21/255, alpha: 1)
                buttonReset.isEnabled = false
            }
            else {
                buttonStartPause.setImage( UIImage(named: "play.pdf"), for: .normal)
                buttonStartPause.backgroundColor = UIColor(red: 84/255, green: 118/255, blue: 171/255, alpha: 1)
                buttonReset.isEnabled = timerValue != 0
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 204/255, green: 227/255, blue: 220/255, alpha: 1)
        
        setupUI()
        handleAppStart()
    }
    
    private func setupUI() {
        
        timerLabel = {
            let label = UILabel()
            label.font = UIFont(name: "AvenirNext-UltraLight", size: 120)
            label.layer.cornerRadius = 40
            label.isUserInteractionEnabled = true
            
            gestureReset = UILongPressGestureRecognizer(target: self, action: #selector(resetGestureDidPerformed))
            if let gesture = gestureReset {
                gesture.minimumPressDuration = 0.5
                gesture.delaysTouchesBegan = true
                label.addGestureRecognizer(gesture)
            }
            return label
        }()
        updateTimerLabel()
        
        buttonStartPause = {
            let button = UIButton()
            button.layer.cornerRadius = 80
            button.layer.shadowOffset = CGSize(width: 2, height: 2)
            button.layer.shadowOpacity = 0.5
            button.layer.shadowRadius = 7.0
            
            return button
        }()
        
        buttonReset = {
            let button = UIButton( type: .system)
            button.setTitle("RESET", for: .normal)
            button.setTitleColor(  UIColor(red: 237/255, green: 65/255, blue: 21/255, alpha: 1), for: .normal)
            button.setTitleColor(  UIColor.systemGray, for: .disabled)
            
            button.isEnabled = false
            
            return button
        }()
        timerActive = false //forced update button state
        
        view.addSubview(timerLabel)
        view.addSubview(buttonStartPause)
        view.addSubview(buttonReset)
        
        let screenH = UIScreen.main.bounds.height
        //constraints
        timerLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset( screenH / 4)
        }
        
        buttonStartPause.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset( screenH / 6 )
            make.centerX.equalToSuperview()
            make.width.height.equalTo(160)
        }
        
        buttonReset.snp.makeConstraints { make in
            make.top.equalTo(timerLabel.snp.bottom).inset(-10)
            make.centerX.equalToSuperview()
        }
        
        //action
        buttonStartPause.addTarget(self, action: #selector(playPauseButtonDidTouch), for: .touchUpInside)
        buttonReset.addTarget(self, action: #selector(resetButtonDidTouch), for: .touchUpInside)
    }
    
    private func updateTimerLabel() {
        if timerValue < 100 {
            timerLabel?.text = String(format: "%.2f", timerValue)
        }
        else {
            timerLabel?.text = String(format: "%.1f", timerValue)
        }
    }
    
    
    //MARK: - Actions
    @objc func playPauseButtonDidTouch()
    {
        animateButtonPressed(button: buttonStartPause)
        if !timerActive {   //play
            createTimer()
        }
        else {              //pause
            stopTimer()
        }
    }
    
    @objc func resetButtonDidTouch()
    {
        stopTimer( resetValue: true )
        animateLabelToRed( completion: animateLabelFromRed(done:) )
    }
    
    @objc func resetGestureDidPerformed()
    {
        if gestureReset?.state == .began {
            animateLabelToRed()
            stopTimer(resetValue: true)
        }
        else if gestureReset?.state == .ended {
            animateLabelFromRed()
        }
        
    }
    
    //MARK: - Save/Restore session
    private func handleAppStart() {
        guard let timeStamp = userDefaults.object(forKey: UserDefaultKeys.keyTimestamp.rawValue) as? Date,
              let timerValue = userDefaults.object(forKey: UserDefaultKeys.keyTimerValue.rawValue) as? Double
        else {  return  }
        
        userDefaults.set( 0,forKey: UserDefaultKeys.keyTimerValue.rawValue)
        if timerValue == 0  {   return  }
        
        let interval = timeStamp.distance(to: Date.now)
        
        self.timerValue = timerValue + interval
        playPauseButtonDidTouch()
    }
    func hanleAppExit() {
        if !timerActive { return }
        
        userDefaults.set( Date.now,forKey: UserDefaultKeys.keyTimestamp.rawValue)
        userDefaults.set( timerValue,forKey: UserDefaultKeys.keyTimerValue.rawValue)
    }
    
    //MARK: - Animation
    private func animateLabelToRed(completion: ((Bool) -> Void)? = nil) {
        UIView.transition(with: timerLabel, duration: 0.2, options: .transitionCrossDissolve,
                          animations: { self.timerLabel.textColor = .red },
                          completion: completion
        )
    }
    
    private func animateLabelFromRed( done: Bool = true ) {
        UIView.transition(with: timerLabel, duration: 0.5, options: .transitionCrossDissolve) {
            self.timerLabel.textColor = .black
        }
    }
    
    private func animateButtonPressed( button: UIButton ) {

            button.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)

            UIView.animate(withDuration: 1.0,
                           delay: 0,
                           usingSpringWithDamping: CGFloat(10.0),
                           initialSpringVelocity: CGFloat(4.0),
                           options: UIView.AnimationOptions.allowUserInteraction,
                           animations: {
                                button.transform = CGAffineTransform.identity
                            },
                           completion: { Void in()  }
            )
    }
    
    //MARK: - Timer
    private func createTimer() {
        if timer != nil { return }
        
        timer = Timer.scheduledTimer(timeInterval: timerInterval,
                                     target: self,
                                     selector: #selector(updateTimer),
                                     userInfo: nil,
                                     repeats: true)
        timer.tolerance = 0.01
        timerActive = true
    }
    
    private func stopTimer( resetValue: Bool = false ) {
        timer?.invalidate()
        timer = nil
        
        if resetValue {
            timerValue = 0
        }
        timerActive = false
    }
    
    @objc private func updateTimer() {
        timerValue += timerInterval
    }
}

extension MainViewController {
    enum UserDefaultKeys: String{
        case keyTimestamp = "timestamp"
        case keyTimerValue = "timervalue"
    }
}
