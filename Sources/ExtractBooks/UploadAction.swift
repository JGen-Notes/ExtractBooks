//
//  UploadAction.swift
//  BooksUpload
//
//  Created by Marek Stankiewicz on 25/06/2018.
//

import Foundation
import SwiftKuery
import SwiftKuerySQLite
import MongoKitten

class ZBXITEM: Table {
    let tableName = "ZBXITEM"
    let zpkitem = Column("Z_PK", Int32.self)
    let zisbn = Column("ZISBN")
    let ztitle = Column("ZTITLE")
    let zlocation = Column("ZLOCATION")
    let zproductdescription = Column("ZPRODUCTDESCRIPTION")
    let zpublisher = Column("ZPUBLISHER")
    let zpages = Column("ZPAGES", Int32.self)
    let zlanguage = Column("ZLANGUAGE")
    let zdatepublished = Column("ZDATEPUBLISHED", Timestamp.self, notNull: false)
}

class ZBXIMAGE: Table {
    let tableName = "ZBXIMAGE"
    let zpkimage = Column("Z_PK")
    let zfilename = Column("ZFILENAME")
}

class ZBXAUTHOR: Table {
    let tableName = "ZBXAUTHOR"
    let zpkauthor = Column("Z_PK", Int32.self)
    let zname = Column("ZNAME")
}

class UploadAction {
    
    var processResponse : ProcessResponse = ProcessResponse.successfull
    var connection : SQLiteConnection
    
    init(filename: String){
        self.processResponse = ProcessResponse.successfull
        self.connection = SQLiteConnection(filename: filename)
    }
    
    func upload(fromSQLite : String, toMongoDB: String, collectionName: String) -> ProcessResponse {
        connection.connect() { error in
            if error == nil {
                let url = URL(string: fromSQLite)
                let imagedir = url?.deletingLastPathComponent().absoluteString
                process(toMongoDB: toMongoDB,collectionName: collectionName, imagedir: imagedir! + "images/")
            }
            else if let error = error {
                processResponse = ProcessResponse.noSQLiteConnect("Error opening database: \(error.description)")
            }
        }
        return processResponse
    }
    
    func extractTimestamp(number: Any) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'.'HH.mm.ss.00000"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        if number is Int32 {
            return formatter.string(from: Date(timeIntervalSince1970: Double(number as! Int32)))
        } else if number is Double {
            return formatter.string(from: Date(timeIntervalSince1970: number as! Double))
        }
        return ""
    }
    
    func process(toMongoDB: String, collectionName: String, imagedir: String) {
        do {
            let library = try MongoKitten.Database(toMongoDB)
            let books = library[collectionName]
            
            let zbxitems = ZBXITEM()
            let query = Select(zbxitems.zpkitem,
                               zbxitems.zisbn,
                               zbxitems.ztitle,
                               zbxitems.zlocation,
                               zbxitems.zproductdescription,
                               zbxitems.zpublisher,
                               zbxitems.zpages,
                               zbxitems.zlanguage,
                               zbxitems.zdatepublished, from: zbxitems)
            connection.execute(query: query) { queryResult in
                if let rows = queryResult.asRows {
                    for row in rows {
                        var book:  Document  = Document()
                        
                        // Primary key
                        let zpkitem = row["Z_PK"].unsafelyUnwrapped as! Int32
                        book.append(zpkitem, forKey: "_id")
   
                        // ISBN Number
                        let zisbn = row["ZISBN"]
                        if zisbn.unsafelyUnwrapped != nil {
                            book.append(zisbn! as! Primitive, forKey: "isbn")
                        }
                        
                        // Title
                        let ztitle = row["ZTITLE"]
                        if ztitle.unsafelyUnwrapped != nil {
                            book.append(ztitle! as! Primitive, forKey: "title")
                        }
                        
                        // Location
                        let zlocation = row["ZLOCATION"]
                        if zlocation.unsafelyUnwrapped != nil {
                          //  book.append(zlocation! as! Primitive, forKey: "location")
                        }
                        
                        // Product Description
                        let zproductdescription = row["ZPRODUCTDESCRIPTION"]
                        if zproductdescription.unsafelyUnwrapped != nil {
                            book.append(zproductdescription! as! Primitive, forKey: "description")
                        }
                        
                        // Publisher
                        let zpublisher = row["ZPUBLISHER"]
                        if zpublisher.unsafelyUnwrapped != nil {
                            book.append(zpublisher! as! Primitive, forKey: "publisher")
                        }
                        
                        // Pages
                        let zpages = row["ZPAGES"]
                        if zpages.unsafelyUnwrapped != nil {
                            book.append(zpages as! Primitive, forKey: "pages")
                        }
                        
                        // Language
                        let zlanguage = row["ZLANGUAGE"]
                        if zlanguage.unsafelyUnwrapped != nil {
                            book.append(zlanguage! as! Primitive, forKey: "language")
                        }
                        
                        // Date Published
                        let zdatepublished = row["ZDATEPUBLISHED"]
                        if zdatepublished.unsafelyUnwrapped != nil {
                            book.append(self.extractTimestamp(number: zdatepublished.unsafelyUnwrapped ?? "unknown"), forKey: "datepublished")
                        }
                        
                        var authors = [String]()
                        
                        let zbxauthor = ZBXAUTHOR()
                        
                        let queryAuthor = Select(zbxauthor.zpkauthor,
                                           zbxauthor.zname, from: zbxauthor).where(zbxauthor.zpkauthor == Parameter())
                        self.connection.execute(query: queryAuthor, parameters: [Int(zpkitem)]) { queryResult in
                        
                            if let rows = queryResult.asRows {
                               
                                for row in rows {
                                    // Author Name
                                    let zname = row["ZNAME"]
                                    if zname.unsafelyUnwrapped != nil {
                                        authors.append(zname as! String)
                                    }
                                }
                            }
                         }
                         book.append(authors, forKey: "authors")
                        
                        let zbximage = ZBXIMAGE()
                        
                        let queryImage = Select(zbximage.zpkimage,
                                                 zbximage.zfilename, from: zbximage).where(zbximage.zpkimage == Parameter())
                        self.connection.execute(query: queryImage, parameters: [Int(zpkitem)]) { queryResult in
                            
                            if let rows = queryResult.asRows {
                                for row in rows {
                                    // Author Name
                                    let zfilename = row["ZFILENAME"]
                                    if zfilename.unsafelyUnwrapped != nil {
                                         let path = imagedir + (zfilename.unsafelyUnwrapped as! String)
                                        
                                        // File Name
                                        let url = URL(string: path)
                                        do {
                                            let file: FileHandle? = try FileHandle(forReadingFrom: url!)
                                            if file != nil {
                                                let data = file?.readDataToEndOfFile()
                                                file?.closeFile()
                                                book.append(Binary(data: data!, withSubtype: Binary.Subtype.generic), forKey: "image")
                                            }
                                        } catch {
                                            self.processResponse = ProcessResponse.problemOpeningImageFile("Problem opening image file: \(String(describing: url))")
                                        }
                                      }
                                }
                            }
                        }
                       
                         do {
                            try books.append(book)
                        } catch {
                            self.processResponse = ProcessResponse.problemCreatingMongoDBDoument("Problem appending a new document for item: \(Int(zpkitem))")
                        }
                    }
                }
            }

        } catch {
            self.processResponse = ProcessResponse.problemProcessingMongoDB("Problem processing MongoDB")
        }
        return
    }
    
}


