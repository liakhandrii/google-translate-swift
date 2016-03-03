//
//  TranslateQuery.swift
//
//  Created by Andrii Liakh on 14.03.2015. Updated by Mike (mikesomething98@gmail.com) on 01.03.2016.
//

import Foundation

extension String {
    public func urlEncode() -> String {
        let encodedURL = CFURLCreateStringByAddingPercentEscapes(
            nil,
            self as NSString,
            nil,
            "!@#$%&*'();:=+,/?[]",
            CFStringBuiltInEncodings.UTF8.rawValue)
        return encodedURL as String
    }
}

public class TranslateQuery {
    
    private let translateQuery = "https://www.googleapis.com/language/translate/v2"
    private let getLanguagesQuery = "https://www.googleapis.com/language/translate/v2/languages"
    private let detectLanguageQuery = "https://www.googleapis.com/language/translate/v2/detect"
    
    private var sourceStr:String
    private var sourceLang:String
    private var targetLang:String="en"
    private var status="error"
    private var defaultQuery:String
    private var jsonName:String
    private var parameters:NSMutableDictionary = NSMutableDictionary()
    
    var languages:Array<Language>;
    
    var queryResult:String
    var queryResultMessage:String
    
    init(sourceString:String, optional sourceLanguage:String, optional targetLanguage:String, withKey apiKey:String) {
        sourceStr = sourceString
        
        sourceLang=sourceLanguage
        if (!targetLanguage.isEmpty) {
            targetLang=targetLanguage
        }
        if (!sourceLanguage.isEmpty) {
            sourceLang=sourceLanguage
        }
        status = ""
        queryResult = ""
        queryResultMessage = "Nothing done..."
        defaultQuery = detectLanguageQuery
        jsonName = "detections"
        languages=Array<Language>()
        addParameter(named: "key", value: apiKey)
    }
    
    func translate() -> Bool {
        addParameter(named: "target",value: targetLang)
        addParameter(named: "q",value: sourceStr.urlEncode())
        let availableLangs = languages.filter { $0.targetLanguage == targetLang }
        
        if (availableLangs.isEmpty) {
            //discover supported languages for this target language
            setType(TranslateQueryType.GET_LANGUAGES)
            let arrResults=runQuery()
            for result in arrResults {
                let lang=Language()
                lang.targetLanguage=targetLang
                for (key,val) in result as! NSDictionary {
                    if (key as! String == "language") {
                        lang.supportedLanguageCode=val as! String
                    }
                    if (key as! String == "name") {
                        lang.supportedLanguageName=val as! String
                    }
                }

                languages.append(lang)
            }
            
        }
        
        if (sourceLang.isEmpty) {
            setType(TranslateQueryType.DETECT)
            let arrResults=runQuery()
            if (arrResults.count>0)
            {
                if let result = arrResults.lastObject!.lastObject as? NSDictionary {
                    sourceLang=result["language"] as! String
                    queryResultMessage="Detected"
                }
            }
            else
            {
                queryResultMessage="Сannot determine source language"
                return false
            }
        }
        
        addParameter(named: "source",value: sourceLang)
        
        //here we should have known source and target languages
        let thisLang = languages.filter { $0.targetLanguage == targetLang && $0.supportedLanguageCode == sourceLang}
        
        //report with friendlyname of detected language
        if (!thisLang.isEmpty) {
            queryResultMessage+=" " + thisLang[0].supportedLanguageName
            queryResultMessage=queryResultMessage.stringByTrimmingCharactersInSet(
                NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }
        
        //now let's translate stuff
        let array = sourceStr.componentsSeparatedByString("\n")
        
        for translateThis in array {
            setType(TranslateQueryType.TRANSLATE)
            addParameter(named: "q",value: translateThis.urlEncode())

            let arrResults=runQuery()

            if (status == "error") {
                queryResultMessage=arrResults[0] as! String
                return false
            }
            else {
                for result in arrResults {
                    for (key,val) in (result as? NSDictionary)! {
                        if (key as! String == "translatedText") {
                            queryResult+=val as! String + "\n"
                        }
                    }
                }
            
            }
        }
        return true
    }
    
    private func setType(type:TranslateQueryType) {
        switch type{
        case TranslateQueryType.TRANSLATE:
            defaultQuery = translateQuery
            status = ""
            jsonName = "translations"
        case TranslateQueryType.GET_LANGUAGES:
            defaultQuery = getLanguagesQuery
            status = ""
            jsonName = "languages"
        case TranslateQueryType.DETECT:
            defaultQuery = detectLanguageQuery
            status = ""
            jsonName = "detections"
        }
    }
    
    private func addParameter(named name:String, value val:String) {
        parameters.setObject(val, forKey: name)
    }
    
    private func runQuery() -> NSArray {
        var query:String = "\(defaultQuery)?"
        
        for (parameter, value) in parameters {
            query += "&\(parameter)=\(value)"
        }

        
        let request = NSMutableURLRequest(URL: NSURL(string: query)!)
        request.HTTPMethod = "GET"
        request.setValue("text/plain; charset=UTF-8", forHTTPHeaderField: "content-type")
        
        var response:NSURLResponse?
        
        do {
            let responseData:NSData = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
            let jsonResult:NSDictionary = try NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            if (jsonResult.objectForKey("data") != nil){
                return (jsonResult.objectForKey("data") as! NSDictionary).objectForKey(jsonName) as! NSArray
            }
            else if(jsonResult.objectForKey("error") != nil)
            {
                status="error"
                return (jsonResult.objectForKey("error")as! NSDictionary).allValues
            }
            else
            {
                return NSArray()
            }
        }
        catch
        {
            return NSArray()
        }

    }

}

class Language {
    var targetLanguage: String = ""
    var supportedLanguageCode = ""
    var supportedLanguageName = ""
    
}

private enum TranslateQueryType:Int {
    case TRANSLATE = 1
    case GET_LANGUAGES = 2
    case DETECT = 3
}

