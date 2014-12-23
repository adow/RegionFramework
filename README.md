RegionFramework
===============

Execute scripts (Javascript) when enter or exit a region (iBeacon region or Circular region)

RegionFramework 是一组区域管理工具，在 `iOS` 中，我们可以监控很多 `区域`, 当进入退出这些区域时，我们会得到一次通知，`RegionFramework`为每个对应区域添加一组脚本，当进入离开区域时，我们可以来执行对应的脚本。

所以，我们在外部维护一组`区域`的列表，他可以就是一个`json`文件，或者是一个经常更新的接口(返回`json`格式内容)。 我们的 App 中定时从这个外部列表更新，以此来更新哪些区域需要监控，哪些区域将停止监控，并为各个区域加载需要执行的脚本。我们只需在外部更新这个列表就可以让 App 更新监控不同的区域，并执行不同的行为。

借助于 `javascript` 脚本(使用 `Objective-C` 中的 `JavascriptCore.framework`)，我们可以在进入/离开区域时执行一组完整的程序流程。我们可以在后台悄无声息的记录用户进入离开这个区域的时间，为用户发送一条本地通知，从网络上请求一个接口来更新后端数据。由于脚本化，我们甚至可以做出很多复杂的逻辑。

## 环境 

* 只能用于 `iOS 7` 以后的系统，但是 `iOS 6` 下也可以编译通过;
* 使用 `Objective-C ARC`;
* App 必须打开后台定位，如果使用 `iBeacon` 区域，必须打开蓝牙;

## 使用

* 包含 `WKRegionActivity.h`,`WKRegionActivity.m`,`WKRegionActivities.h`,`WKRegionActivities.m`,`WKJs.h`,`WKJs.m`;
* 确保使用ARC,如果项目是手工管理内存的，在 `Build Phases`，`Compiler Sources` 中的这几个文件添加 `-fobjc-arc`;
* 在 `Link Binary With Libraries` 中引入 `CoreLocation.framework`,`CoreBluetooth.framework`,`JavaScriptCore.framework`;
* 修改 `WKRegionActivities.h` 中`WKRegionActivitiesUpdatePath` 到新的外部json 文件地址;
* 可以在 `WKJs` 中添加更多的 `JS-Binding`的 `Objectivie-C` 代码;
* 由于一般都会用到推送，所以在 AppDelegate 中启动时注册通知

		if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]){
	        UIUserNotificationSettings *setting = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil];
	        [[UIApplication sharedApplication] registerUserNotificationSettings:setting];
	        [[UIApplication sharedApplication] registerForRemoteNotifications];
	    }
	    else{
	        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
	    }

	    
## 组成

### Json file

* 一个外部的接口文件，可以在服务器上动态生成，里面包含了每个区域的设置和脚本;

### WKRegionActivity

* 每个监控区域的数据,可以认为是 `CLRegion` 的一个扩展，每个 `CLRegion` 对应着一个 `WKRegionActivity`；
* 监控区域包括两种， 地理围栏区域(CircularRegion) 和 iBeacon 区域 (BeaconRegion), 他们的区别是，地理围栏区域需要设定围栏中心点的gps坐标(centerLat,centerLng) 和围栏的半径(centerRadius); 而 iBeacon 区域需要设定 uuid，major和minor(可选);
* 无论是CircularRegion 还是 BeaconRegion,都有一个对应的 WKRegionActivity，这个 WKRegionActivity 包含着监控区域需要的数据，包括坐标，uuid,major,minor,还有这个区域的进入和退出的脚本;
* 无论是CircularRegion, BeaconRegion， 还是他们对应的 WKRegionActivity数据，他们都有一个 identifier 用来进行关联;
* 数据结构:
 	* center_radius: 地理围栏中心半径
 	* center_lat: 地理围栏中心坐标latitude;
 	* center_lng: 地理为了中心坐标longtitue
 	* uuid: iBeacon 的uuid
 	* major: iBeacon 的major (可选)
	* minor: iBeaon 的minor (可选)
	* identifier: 监控区域的识别号
	* expire_at: 过期时间(1970到现在的秒数);
	* enter_scripts: 进入时运行的脚本;
	* exit_scripts: 退出时运行的脚本;

### WKRegionActivities

* App 启动时会从本地读取一份区域数据列表(json),如果这份文件过期(超过一天),就会从服务器接口上更新这个列表(同时保存到本地)，这个列表包含了多个WKRegionActitity数据,App 启动后就得到了所有要监控区域的列表，这是一个用来测试的区域列表接口: [https://github.com/adow/RegionFramework/blob/master/RegionFramework/RegionFramework/region.test.json](https://github.com/adow/RegionFramework/blob/master/RegionFramework/RegionFramework/region.test.json)；
* 根据这份区域列表,App更新需要监控的区域，如果是新的区域，将添加到新的监控中，如果这个区域过期，将从系统监控中移除；
* 每个正在监控的区域中，进入和退出区域时，运行对应的 javascript 脚本；
* 有一个全局的`on`属性，用来打开和关闭整个区域监控功能；在App的设置中，可以用来打开和关闭全部功能；
* 可以设置在后台更新中每隔几个小时来更新一次列表文件；

### WKJS

* 每个监控区域(WKRegionActivity)都包含 `enter_scripts`和 `exit_scripts` 脚本，当进入和退出时运行对应的脚本;
* 所有的脚本都是 `javascript`, WKJs 提供了一系列js函数，用来进行文件操作,http访问，用户数据存储，发送本地通知等功能 [https://github.com/adow/RegionFramework/blob/master/RegionFramework/RegionFramework/WKJs.md](https://github.com/adow/RegionFramework/blob/master/RegionFramework/RegionFramework/WKJs.md)；
* 可以在 `WKJs` 中添加更多扩展方法，每个方法必须在 `-(void)loadJs` 中被调用添加到 `JSContext` 中去;