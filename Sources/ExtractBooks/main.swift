//
//  main.swift
//
//  Created by Marek Stankiewicz on 16/06/2018.
//
import Foundation


let mainLogic = MainLogic()
if CommandLine.argc < 1 {
    mainLogic.consoleDialog.printUsage()
} else {
    let returnStatus = mainLogic.startProcessing()
    if returnStatus.rc == 0 {
        mainLogic.consoleDialog.writeMessage(returnStatus.message, to: OutputType.standard)
    } else {
        mainLogic.consoleDialog.writeMessage(returnStatus.message, to: OutputType.error)
    }
    exit(Int32(returnStatus.rc))
}
