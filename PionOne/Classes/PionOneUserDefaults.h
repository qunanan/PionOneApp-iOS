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
#define PionOneDefaultBaseURL @"https://45.79.4.239"
#define PionOneDefaultOTAServerIPAddressChina @"120.25.216.117"
#define PionOneDefaultDataServerIPAddressChina @"120.25.216.117"
#define PionOneDefaultOTAServerIPAddressInternational @"45.79.4.239"
#define PionOneDefaultDataServerIPAddressInternational @"45.79.4.239"
#define PionOneConfigurationAddr @"192.168.4.1"
#define PionOneRegionNameInternational @"International"
#define PionOneRegionNameChina @"China"
#define PionOneRegionNameCustom @"Custom"

//apis
#define aPionOneUserCreate @"/v1/user/create"
#define aPionOneUserLogin @"/v1/user/login"
#define aPionOneUserRetrievepassword @"/v1/user/retrievepassword"
#define aPionOneUserChangePassword @"/v1/user/changepassword"
#define aPionOneUserDownload @"/v1/user/download"
#define aPionOneOTAStatus @"/v1/ota/status"

#define aPionOneNodeCreate @"/v1/nodes/create"
#define aPionOneNodeList @"/v1/nodes/list"
#define aPionOneNodeRename @"/v1/nodes/rename"
#define aPionOneNodeDelete @"/v1/nodes/delete"
#define aPionOneNodeGetSettings @"/v1/node/config"
#define aPionOneDriverScan @"/v1/scan/drivers"

#define aPionOneNodeResources @"/v1/node/resources"
#define aPionOneNodeAPIs @"/v1/node/.well-known"

//default keys
#define kPionOneOTAServerBaseURL @"PionOneOTAServerBaseURL"
#define kPionOneDataServerBaseURL @"PionOneDataServerBaseURL"
#define kPionOneOTAServerIPAddress @"PionOneOTAServerIPAddress"
#define kPionOneDataServerIPAddress @"PionOneDataServerIPAddress"
#define kPionOneServerRegion @"PionOneServerRegion"
#define kPionOneUserToken @"PionOneUserToken"
#define kPionOneTmpNodeSN @"PionOneTmpNodeSN"
#define kPionOneTmpNodeKey @"PionOneTmpNodeKey"
#define PionOneConfigurationAddr @"192.168.4.1"

#endif
