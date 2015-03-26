//
//  TranslateQuery.swift
//
//  Created by Andrii Liakh on 14.03.15.
//

import Foundation

public class TranslateQuery{
    
    private let translateQuery = "https://www.googleapis.com/language/translate/v2"
    private let getLanguagesQuery = "https://www.googleapis.com/language/translate/v2/languages"
    private let detectLanguageQuery = "https://www.googleapis.com/language/translate/v2/detect"
    
    private var defaultQuery:String
    
    private var jsonName:String
    
    private var parameters:NSMutableDictionary = NSMutableDictionary()
    
    
    init(type:TranslateQueryType, withKey apiKey:String){
        switch type{
        case TranslateQueryType.TRANSLATE:
            defaultQuery = translateQuery
            jsonName = "translate"
        case TranslateQueryType.GET_LANGUAGES:
            defaultQuery = getLanguagesQuery
            jsonName = "languages"
        case TranslateQueryType.DETECT:
            defaultQuery = detectLanguageQuery
            jsonName = "detections"
        default:
            defaultQuery = translateQuery
            jsonName = "translate"
        }
        addParameter(named: "key", value: apiKey)
    }
    
    public func addParameter(named name:String, value val:String){
        parameters.setObject(val, forKey: name)
    }
    
    public func runQuery() -> NSArray{
        var query:String = "\(defaultQuery)?"
        
        for (parameter, value) in parameters{
            query += "&\(parameter)=\(value)"
        }
        
        var request = NSMutableURLRequest(URL: NSURL(string: query)!)
        request.HTTPMethod = "GET"
        request.setValue("text/plain; charset=UTF-8", forHTTPHeaderField: "content-type")
        
        var response:NSURLResponse?
        
        var error:NSError?
        
        var responseData:NSData = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)!
        
        var jsonResult:NSDictionary = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers, error: &error) as NSDictionary
        if (jsonResult.objectForKey("data") != nil){
            return (jsonResult.objectForKey("data") as NSDictionary).objectForKey(jsonName) as NSArray
        }else if(jsonResult.objectForKey("error") != nil){
            return (jsonResult.objectForKey("data") as NSDictionary).allValues
        }else{
            return NSArray()
        }
        
    }
    
    
}

public enum TranslateQueryType:Int{
    case TRANSLATE = 1
    case GET_LANGUAGES = 2
    case DETECT = 3
}

