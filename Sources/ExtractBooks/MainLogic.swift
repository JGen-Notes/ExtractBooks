//
//  MainLogic.swift
//
//  Created by Marek Stankiewicz on 16/06/2018.
//

import Foundation
import CoreData

enum OptionType: String {
    case upload = "-u"
    case help = "-h"
    case unknown
 
    init(value: String) {
        switch value {
        case "-u": self = .upload
        case "-h": self = .help
        default: self = .unknown
        }
    }
}


enum ProcessResponse  {
    case  successfull
    case  noSQLiteConnect(String)
    case  noMongoDBConnect(String)
    case  problemCreatingMongoDBDoument(String)
    case  problemProcessingMongoDB(String)
    case  problemOpeningImageFile(String)
}
    


class MainLogic {
    
    let consoleDialog = ConsoleDialog()
    
    func startProcessing() -> (rc: Int, message: String) {
        let arguments = CommandLine.argc
        if arguments < 1 {
            return (rc: ReturnCode.command_line_usage_error.rawValue, message: "No option parameters provided.")
        }

        let option = getOption(CommandLine.arguments[1])
        switch option {
        case .upload:
            let params = unpackCmdParams(array : CommandLine.arguments)
            if params == nil {
                return (rc: ReturnCode.command_line_usage_error.rawValue, message: "Wrong number of parameters for -u function.")
            }
            if !validateURL(url: (params?.sqLite)!) {
                return (rc: ReturnCode.command_line_usage_error.rawValue, message: "URL to SQLite database malformed.")
            }
            if !validateURL(url: (params?.mongodburl)!) {
                 return (rc: ReturnCode.command_line_usage_error.rawValue, message: "URL to MongoDB database malformed.")
            }
            let uploadAction = UploadAction(filename: (params?.sqLite)!)
            let processResponse = uploadAction.upload(fromSQLite: (params?.sqLite)!, toMongoDB: (params?.mongodburl)!, collectionName:  (params?.collectionName)!)
            return createRetrunMessage(processResponse: processResponse)
        case .help:
            consoleDialog.printUsage()
        case .unknown:
            return (rc: ReturnCode.command_line_usage_error.rawValue, message: "Unknown option.")
        }
        consoleDialog.printUsage()
        return (rc: ReturnCode.command_line_usage_error.rawValue, message: "Unknown option.")
    }
    
    func validateURL(url : String) -> Bool {
        let nsurl = NSURL(string: url)
        return nsurl == nil ? false : true
    }
    
    func unpackCmdParams(array : [String]) -> (sqLite : String, mongodburl : String, collectionName : String)? {
        if array.count != 5 {
            return nil
        }
        return (array[2], array[3], array[4])
    }
    
    func getOption(_ option: String) -> OptionType {
        return OptionType(value: option)
    }
    
    func createRetrunMessage(processResponse: ProcessResponse) -> (rc: Int, message: String) {
        switch processResponse {
        case .successfull:
            return (0,"Processing completed successfully")
        default:
            return (1, self.getDescription(processResponse: processResponse))
        }
    }
 
    func getDescription(processResponse: ProcessResponse) -> String {
        switch processResponse {
        case .successfull:
            return "successful"
        case let .noSQLiteConnect(message):
            return  message
        case let .noMongoDBConnect(message):
            return message
        case let .problemOpeningImageFile(message):
            return message
        case let .problemCreatingMongoDBDoument(message):
            return message
        case let .problemProcessingMongoDB(message):
            return message
        }
    }


        

    
}






    

