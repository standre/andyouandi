//
//  ShareViewController.swift
//  ShareAction
//
//  Created by sga on 19.09.15.
//  Copyright © 2015 Stephan André. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices

let sharedDefaults = UserDefaults(suiteName: "group.eu.andyouandi")

// http://stackoverflow.com/questions/24297273/openurl-not-work-in-action-extension
extension NSObject
{
    func callSelector(_ selector: Selector, object: AnyObject?, delay: TimeInterval)
    {
        let delay = delay * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            Thread.detachNewThreadSelector(selector, toTarget:self, with: object)
        })
    }
}

class ShareViewController: SLComposeServiceViewController
{

    var attachedURL: URL?
    var attachedData: Data?
    var attachedType: NSString?

    override func isContentValid() -> Bool
    {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost()
    {
        sharedDefaults!.removeObject(forKey: "comment");
        sharedDefaults!.removeObject(forKey: "url");
        sharedDefaults!.removeObject(forKey: "data");
        sharedDefaults!.removeObject(forKey: "type");

        NSLog("*** ShareAction *** didSelectPost()")
        NSLog("contentText: %@", self.contentText)
        NSLog("inputItems: %@", (self.extensionContext?.inputItems)!)
        
        sharedDefaults!.set(self.contentText, forKey: "comment")
        sharedDefaults!.set(self.attachedURL, forKey: "url")
        sharedDefaults!.set(self.attachedData, forKey: "data")
        sharedDefaults!.set(self.attachedType, forKey: "type")
        sharedDefaults?.synchronize()
        
        let ayaiURL = URL(string: "andyouandi://home")
        var responder = self as UIResponder?

        let context = NSExtensionContext()
        context.open(ayaiURL! as URL, completionHandler: nil)
        
        while (responder != nil){
            if responder?.responds(to: Selector("openURL:")) == true{
                responder?.perform(Selector("openURL:"), with: ayaiURL)
            }
            responder = responder!.next
        }
        
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]!
    {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }
    
    override func presentationAnimationDidFinish()
    {
        let extensionItem = extensionContext?.inputItems[0] as! NSExtensionItem
        dataFromExtensionItem(extensionItem) {
            url, data, type in
            if let data = data as Data? {
                DispatchQueue.main.async {
                    self.attachedURL = url
                    self.attachedData = data
                    self.attachedType = type
                }
            }
        }
    }

    fileprivate func dataFromExtensionItem(_ extensionItem: NSExtensionItem,
        callback: @escaping (_ url: URL, _ data: Data, _ type: NSString) -> Void)
    {
        for attachment in extensionItem.attachments as! [NSItemProvider]
        {
            let registeredTypeIdentifiers = attachment.registeredTypeIdentifiers;
            if (attachment.hasItemConformingToTypeIdentifier(kUTTypeData as String))
            {
                DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
                    attachment.loadItem(forTypeIdentifier: kUTTypeData as String, options: nil) {
                        (itemProvider, error) in
                        if let error = error
                        {
                            NSLog("*** ShareAction: Item loading error: %@", (error.localizedDescription))
                        }
                        if let data = itemProvider as? Data?
                        {
                            DispatchQueue.main.async {
                                callback(URL(fileURLWithPath:""),
                                        data!,
                                        registeredTypeIdentifiers[0] as! NSString)
                            }
                        }
                        else
                        {
                            DispatchQueue.main.async {
                                callback(itemProvider as! URL,
                                        try! Data(contentsOf: itemProvider as! URL),
                                        registeredTypeIdentifiers[0] as! NSString)
                            }
                        }
                    }
                }
            }
        }
    }
}

