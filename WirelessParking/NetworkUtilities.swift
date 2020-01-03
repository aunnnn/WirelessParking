//
//  NetworkUtilities.swift
//  TestWirelessNetworking
//
//  Note: Majority of the code is NOT mine. It's been awhile, I believe I stitched them together from StackOverflow's answers.

import Foundation

class NetworkUtilities {
    // Get the local ip addresses used by this node
    static let sharedInstance = NetworkUtilities()

    func getIFAddresses() -> [NetInfo] {
        var addresses = [NetInfo]()
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
        if getifaddrs(&ifaddr) == 0 {
            
            // For each interface ...
            for (var ptr = ifaddr; ptr != nil; ptr = ptr.memory.ifa_next) {
                let flags = Int32(ptr.memory.ifa_flags)
                var addr = ptr.memory.ifa_addr.memory
                
                // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                        
                        // Convert interface address to a human readable string:
                        var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                        if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                                if let address = String.fromCString(hostname) {
                                    
                                    var net = ptr.memory.ifa_netmask.memory
                                    var netmaskName = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                                    getnameinfo(&net, socklen_t(net.sa_len), &netmaskName, socklen_t(netmaskName.count),
                                        nil, socklen_t(0), NI_NUMERICHOST) == 0
                                    if let netmask = String.fromCString(netmaskName) {
                                        addresses.append(NetInfo(ip: address, netmask: netmask))
                                    }
                                }
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return addresses
    }
    
    // Return IP address of WiFi interface (en0) as a String, or `nil`
    func getMyWiFiAddress() -> NetInfo? {
        var address : String = "error"
        var netmsk : String = "error"
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
        if getifaddrs(&ifaddr) == 0 {
            // For each interface ...
            for (var ptr = ifaddr; ptr != nil; ptr = ptr.memory.ifa_next) {
                let interface = ptr.memory
                
                // Check for IPv4 or IPv6 interface:
                let addrFamily = interface.ifa_addr.memory.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    print(interface.ifa_name.memory)
                    // Check interface name:
                    if let name = String.fromCString(interface.ifa_name) where name == "en0" {
                        
                        // Convert interface address to a human readable string:
                        var addr = interface.ifa_addr.memory
                        var netmask = interface.ifa_netmask.memory
                        
                        var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                        var netmaskname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                        
                        getnameinfo(&addr, socklen_t(interface.ifa_addr.memory.sa_len),
                            &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                        getnameinfo(&netmask, socklen_t(interface.ifa_netmask.memory.sa_len),
                            &netmaskname, socklen_t(netmaskname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                        
                        if let address1 = String.fromCString(hostname) {
                            address = address1
                        }
                        if let netmsk1 = String.fromCString(netmaskname) {
                            netmsk = netmsk1
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        if address == "error" || netmsk == "error" {
            return nil
        }
        
        return NetInfo(ip: address, netmask: netmsk)
    }
    
}

struct NetInfo {
    // IP Address
    let ip: String
    
    // Netmask Address
    let netmask: String
    
    // CIDR: Classless Inter-Domain Routing
    var cidr: Int {
        var cidr = 0
        for number in binaryRepresentation(netmask) {
            let numberOfOnes = number.componentsSeparatedByString("1").count - 1
            cidr += numberOfOnes
        }
        return cidr
    }
    
    // Network Address
    var network: String {
        return bitwise(&, net1: ip, net2: netmask)
    }
    
    // Broadcast Address
    var broadcast: String {
        let inverted_netmask = bitwise(~, net1: netmask)
        let broadcast = bitwise(|, net1: network, net2: inverted_netmask)
        return broadcast
    }
    
    private func binaryRepresentation(s: String) -> [String] {
        var result: [String] = []
        
        for numbers in s.componentsSeparatedByString(".") {
            if let intNumber = Int(numbers) {
                if let binary = Int(String(intNumber, radix: 2)) {
                    result.append(NSString(format: "%08d", binary) as String)
                }
            }
        }
        return result
    }
    
    private func bitwise(op: (UInt8,UInt8) -> UInt8, net1: String, net2: String) -> String {
        let net1numbers = toInts(net1)
        let net2numbers = toInts(net2)
        var result = ""
        for i in 0..<net1numbers.count {
            result += "\(op(net1numbers[i],net2numbers[i]))"
            if i < (net1numbers.count-1) {
                result += "."
            }
        }
        return result
    }
    
    private func bitwise(op: UInt8 -> UInt8, net1: String) -> String {
        let net1numbers = toInts(net1)
        var result = ""
        for i in 0..<net1numbers.count {
            result += "\(op(net1numbers[i]))"
            if i < (net1numbers.count-1) {
                result += "."
            }
        }
        return result
    }
    
    private func toInts(networkString: String) -> [UInt8] {
        return networkString.componentsSeparatedByString(".").map{UInt8($0)!}
    }
}
