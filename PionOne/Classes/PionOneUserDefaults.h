//
//  PionOneUserDefaults.h
//  PionOne
//
//  Created by Qxn on 15/9/3.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#ifndef PionOne_PionOneUserDefaults_h
#define PionOne_PionOneUserDefaults_h

//#define PionOneDefaultBaseURL @"https://iot.seeed.cc"
#define PionOneDefaultBaseURL @"https://iot.seeed.cc"
#define PionOneDefaultOTAServerHostChina @"cn.iot.seeed.cc"
#define PionOneDefaultDataServerHostChina @"cn.iot.seeed.cc"
#define PionOneDefaultOTAServerHostInternational @"iot.seeed.cc"
#define PionOneDefaultDataServerHostInternational @"iot.seeed.cc"
#define PionOneConfigurationAddr @"192.168.4.1"
#define PionOneRegionNameInternational @"International"
#define PionOneRegionNameChina @"China"
#define PionOneRegionNameCustom @"Custom"

//apis
#define aPionOneUserCreate @"/v1/user/create"
#define aPionOneUserLogin @"/v1/user/login"
#define aPionOneUserRetrievepassword @"/v1/user/retrievepassword"
#define aPionOneUserChangePassword @"/v1/user/changepassword"
#define aPionOneUserDownload @"/v1/ota/trigger"
#define aPionOneOTAStatus @"/v1/ota/status"

#define aPionOneNodeCreate @"/v1/nodes/create"
#define aPionOneNodeList @"/v1/nodes/list"
#define aPionOneNodeRename @"/v1/nodes/rename"
#define aPionOneNodeDelete @"/v1/nodes/delete"
#define aPionOneNodeGetSettings @"/v1/node/config"
#define aPionOneDriverScan @"/v1/scan/drivers"

#define aPionOneNodeResources @"/v1/node/resources"
#define aPionOneNodeAPIs @"/v1/node/.well-known"

#define aPionOneNodeChangeDataServer @"/v1/node/setting/dataxserver"

//default keys
#define kPionOneUserEmail @"PionOneUserEmail"
#define kPionOneOTAServerBaseURL @"PionOneOTAServerBaseURL"
#define kPionOneDataServerBaseURL @"PionOneDataServerBaseURL"
#define kPionOneOTAServerIPAddress @"PionOneOTAServerIPAddress"
#define kPionOneDataServerIPAddress @"PionOneDataServerIPAddress"
#define kPionOneOTAServerHost @"PionOneOTAServerHost"
#define kPionOneDataServerHost @"PionOneDataServerHost"
#define kPionOneServerRegion @"PionOneServerRegion"
#define kPionOneUserToken @"PionOneUserToken"
#define kPionOneTmpNodeSN @"PionOneTmpNodeSN"
#define kPionOneTmpNodeKey @"PionOneTmpNodeKey"
#define PionOneConfigurationAddr @"192.168.4.1"

#define kName_WioLink   @"Wio Link v1.0"
#define kName_WioNode   @"Wio Node v1.0"
#define kTEMP_NODE_NAME @"YouShouldNeverSeeMeInYourApp"

#endif
