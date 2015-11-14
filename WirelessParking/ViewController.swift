//
//  ViewController.swift
//  WirelessParking
//
//  Created by Wirawit Rueopas on 11/9/2558 BE.
//  Copyright © 2558 Wirawit Rueopas. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class ViewController: UIViewController, GCDAsyncUdpSocketDelegate {

    var portNumber: UInt16 = 9869
    var udpSocket: GCDAsyncUdpSocket?
    var netInfo: NetInfo?
    
    let userTypeCode = 2
    
    var availableSpaces: [CGPoint] = []
    let boardWidth = 10
    
    @IBOutlet weak var latestMessageLabel: UILabel!
    var insideBoard = UIView(frame: CGRectZero)
    @IBOutlet weak var spaceBoardView: BoardView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let tapgr = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        self.view.addGestureRecognizer(tapgr)
        self.spaceBoardView.addSubview(insideBoard)
        
        self.udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_main_queue())

    }
    func dismissKeyboard() {
        self.view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!) {
        if let mssg = String(data: data, encoding: NSUTF8StringEncoding) {
            print("RCV MSSG: \(mssg)")
            processReceivedMessage(mssg)
            latestMessageLabel.text = "Latest Message: \(mssg)"
            updateBoardUI()
        } else {
            print("UNKNOWN MSSG: \(data)")
            dispatch_async(dispatch_get_main_queue()) {
                self.alert("Received unknown message.")
            }
        }
    }
    @IBAction func updateBoardButtonPushed(sender: AnyObject) {
        self.updateBoardUI()
    }
    func updateBoardUI() {

        self.spaceBoardView.setNeedsDisplay()
    }
    func processReceivedMessage(mssg: String) {
        if !mssg.containsString("avail") {
            return
        }
        self.availableSpaces = []
        let comps = mssg.componentsSeparatedByString("|")
        for comp in comps {
            let loc = comp.componentsSeparatedByString(",")
            if loc.count == 2 {
                if let x = Int(loc[0]), y = Int(loc[1]) {
                    self.availableSpaces.append(CGPoint(x: x, y: y))
                    print("receive loc \(x),\(y)")
                }
            }
        }
        spaceBoardView.availableSpaces = self.availableSpaces
    }
    func setupUDPSocket(port: UInt16) {
        guard let udpSocket = self.udpSocket else {
            self.alert("No udp socket.")
            return
        }
        do {
            try udpSocket.bindToPort(portNumber)
            try udpSocket.enableBroadcast(true)
            try udpSocket.beginReceiving()
        } catch let error as NSError {
            self.alert("Cannot setup UDP socket. \n\(error.localizedDescription)")
        }
    }
    func broadcastUpdateFreeSpacesMessage() {
        self.getMyWifiAddress()
        guard let netInfo = self.netInfo, udpSocket = self.udpSocket else {
            self.alert("Netinfo or udpSocket not available.")
            return
        }
        let broadcast = netInfo.broadcast
        let message = "ask|\(userTypeCode)".dataUsingEncoding(NSUTF8StringEncoding)
        dispatch_async(dispatch_get_main_queue()){
            self.alert("Finish broadcast to \(broadcast).")
        }
        udpSocket.sendData(message, toHost: broadcast, port: portNumber, withTimeout: -1, tag: 1)
    }
    func alert(text: String) {
        let alert = UIAlertController(title: text, message: nil, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    func getMyWifiAddress() {
        if let netinfo = NetworkUtilities.sharedInstance.getMyWiFiAddress() {
            self.netInfo = netinfo
        } else {
            self.alert("This device's address not available.")
        }
    }
    @IBOutlet weak var portnumTextField: UITextField!
    @IBAction func updatePortNumberButtonPushed(sender: UIButton) {
        guard let text = portnumTextField.text else {
            alert("Port cannot be nil.")
            return
        }
        sender.enabled = false
        if let portnum = UInt16(text) {
            self.portNumber = portnum
            self.setupUDPSocket(self.portNumber)
            alert("Did set port number.")
            return
        } else {
            alert("Invalid port number.")
            return
        }
    }
    @IBAction func updateFreeSpacesButtonPushed(sender: UIButton) {
        broadcastUpdateFreeSpacesMessage()
    }
}

