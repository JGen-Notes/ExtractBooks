//
//  ConsoleDialog.swift
//
//  Created by Marek Stankiewicz on 16/06/2018.
//

import Foundation

enum ReturnCode: Int {
    case successful_termination = 0
    case command_line_usage_error = 64
    case cannot_open_input = 66
    case internal_software_error = 70
    case unknown
}

enum OutputType {
    case error
    case standard
}

class ConsoleDialog {
    func writeMessage(_ message: String, to: OutputType = .standard) {
        switch to {
        case .standard:
            print("\(message)")
        case .error:
            fputs("\(message)\n", stderr)
        }
    }
    
    func printUsage() {  
        
        print(
        """
        Extracting Books from Booxter Database, Version 0.1

        Usage:

           -h to show usage information

           or

           -u <fromURL> <toURL> <name> to upload data from SQLLite to MongoDB database

               where:
                    <fromURL> is URL to SQL Lite database
                    <toURL> is URL to MongoDB database
                    <name> MongoDB collection name

        """
        )
        
    }
    
}
