//
//  SandPluginBluetooth.m
//  sand-plugin-bluetooth
//
//  Created by Qianjiao Wang on 2022/4/28.
//

#import "SandPluginBluetooth.h"
#import "Const.h"

@interface SandPluginBluetooth (){
    //蓝牙单例对象
    BabyBluetooth *baby;
    //缓存已经扫描到的蓝牙对象
    NSMutableDictionary *deviceMap;
    //缓存已获取到的服务对象
    NSMutableDictionary *serviceMap;
    //缓存已获取到的特征对象
    NSMutableDictionary *characteristicMap;
    //缓存已获取到的描述对象
    NSMutableDictionary *descriptorMap;
    //缓存设备广播内容
    NSMutableDictionary *advCacheMap;
    //首次标志
    BOOL isInit;
    //监听-蓝牙适配器状态变化
    UniModuleKeepAliveCallback onBluetoothAdapterStateChangeCallback;
    //监听-扫描设备发现
    UniModuleKeepAliveCallback onBluetoothDeviceFoundCallback;
    //监听-设备链接状态变化
    UniModuleKeepAliveCallback onBLEConnectionStateChangeCallback;
    //异步回调-写值完成
    NSMutableDictionary *writeBLECharacteristicValueCallbackMap;
    //监听-设备特征值变化坚挺
    UniModuleKeepAliveCallback onBLECharacteristicValueChangeCallback;
    //异步回调-获取信号强度
    NSMutableDictionary *getBLEDeviceRSSICallbackMap;
    //异步回调-获取服务
    NSMutableDictionary *getBLEDeviceServicesCallbackMap;
    //异步回调-获取特征
    NSMutableDictionary *getBLEDeviceCharacteristicsCallbackMap;
    
}
@end

@implementation SandPluginBluetooth


// 通过宏 UNI_EXPORT_METHOD 将异步方法暴露给 js 端
//初始化蓝牙模块
UNI_EXPORT_METHOD(@selector(openBluetoothAdapter:callback:))
//监听蓝牙适配器状态变化事件
UNI_EXPORT_METHOD(@selector(onBluetoothAdapterStateChange:callback:))
//开始搜寻附近的蓝牙外围设备
UNI_EXPORT_METHOD(@selector(startBluetoothDevicesDiscovery:callback:))
//停止搜寻附近的蓝牙外围设备
UNI_EXPORT_METHOD(@selector(stopBluetoothDevicesDiscovery:callback:))
//监听寻找到新设备的事件
UNI_EXPORT_METHOD(@selector(onBluetoothDeviceFound:callback:))
//连接低功耗蓝牙设备。
UNI_EXPORT_METHOD(@selector(createBLEConnection:callback:))
//断开与低功耗蓝牙设备的连接
UNI_EXPORT_METHOD(@selector(closeBLEConnection:callback:))
//监听低功耗蓝牙连接状态的改变事件。包括开发者主动连接或断开连接，设备丢失，连接异常断开等等
UNI_EXPORT_METHOD(@selector(onBLEConnectionStateChange:callback:))
//获取蓝牙设备所有服务
UNI_EXPORT_METHOD(@selector(getBLEDeviceServices:callback:))
//获取蓝牙设备某个服务中所有特征值(characteristic)。
UNI_EXPORT_METHOD(@selector(getBLEDeviceCharacteristics:callback:))
//向低功耗蓝牙设备特征值中写入二进制数据
UNI_EXPORT_METHOD(@selector(writeBLECharacteristicValue:callback:))
//读取低功耗蓝牙设备的特征值的二进制数据值
UNI_EXPORT_METHOD(@selector(readBLECharacteristicValue:callback:))
//监听低功耗蓝牙设备的特征值变化事件
UNI_EXPORT_METHOD(@selector(onBLECharacteristicValueChange:callback:))
//添加断线重连设备
UNI_EXPORT_METHOD(@selector(addAutoReconnect:callback:))
//移除断线重连设备
UNI_EXPORT_METHOD(@selector(removeAutoReconnect:callback:))
//启用低功耗蓝牙设备特征值变化时的 notify 功能，订阅特征值
UNI_EXPORT_METHOD(@selector(notifyBLECharacteristicValueChange:callback:))
//取消订阅
UNI_EXPORT_METHOD(@selector(cancelNotifyBLECharacteristicValueChange:callback:))
//获取当前信号强度
UNI_EXPORT_METHOD(@selector(getBLEDeviceRSSI:callback:))
//获取已连接的设备列表
UNI_EXPORT_METHOD(@selector(getConnectedBluetoothDevices:callback:))
//获取已扫描到的所有设备
UNI_EXPORT_METHOD(@selector(getBluetoothDevices:callback:))
//获取蓝牙适配器最新状态
UNI_EXPORT_METHOD(@selector(getBluetoothAdapterState:callback:))
//关闭蓝牙适配器
UNI_EXPORT_METHOD(@selector(closeBluetoothAdapter:callback:))


#pragma mark 初始化蓝牙
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)openBluetoothAdapter:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    // options 为 js 端调用此方法时传递的参数
    NSLog(@"%@",options);
    //初始化BabyBluetooth 蓝牙库
    baby = [BabyBluetooth shareBabyBluetooth];
    //设置蓝牙委托
    [self babyDelegate];
    // 回调方法，传递参数给 js 端 注：只支持返回 String 或 NSDictionary (map) 类型
    [self callBack:callback data:@{STATUS:STATUS_SUCCESS,
                                   MESSAGE:@"蓝牙初始化完成"
                                 } repeat:NO];
}

#pragma mark 监听蓝牙开关状态变化
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)onBluetoothAdapterStateChange:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    onBluetoothAdapterStateChangeCallback=callback;
}

#pragma mark 扫描设备
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)startBluetoothDevicesDiscovery:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    if([self isAvailable:callback]){
        baby.scanForPeripherals().begin();
        [self callBack:callback data:@{STATUS:STATUS_SUCCESS,
                                       MESSAGE:@"开启设备扫描完成"
                                     } repeat:NO];
    }
}

#pragma mark 停止扫描设备
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)stopBluetoothDevicesDiscovery:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    if([self isAvailable:callback]){
        //停止扫描
        [baby cancelScan];
        [self callBack:callback data:@{STATUS:STATUS_SUCCESS,
                                       MESSAGE:@"停止设备扫描完成"
                                     } repeat:NO];
    }
}

#pragma mark 监听设备发现
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)onBluetoothDeviceFound:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    onBluetoothDeviceFoundCallback=callback;
}

#pragma mark 和设备建立链接
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)createBLEConnection:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    if([self isAvailable:callback]){
        NSString *deviceId=[options objectForKey:DEVICE_ID];
        CBPeripheral *device=[self getDevice:deviceId];
        if(device){
//            if([self getConnectedDevice:deviceId]){
//                //已连接直接触发回调
//                [self callBack:onBLEConnectionStateChangeCallback data:@{STATUS:STATUS_SUCCESS,
//                     DEVICE_ID:device.identifier.UUIDString,
//                     @"connected":[NSNumber numberWithBool:YES],
//                     MESSAGE:@"状态变化"
//                   } repeat:YES];
//                [self callBack:callback data:@{STATUS:STATUS_SUCCESS,
//                                               MESSAGE:@"接口调用成功，将在onBLEConnectionStateChange触发连接结果"
//                                             } repeat:NO];
//                return;
//            }
            baby.having(device).and.then.connectToPeripherals().discoverServices().discoverCharacteristics().discoverDescriptorsForCharacteristic().begin();
            [self callBack:callback data:@{STATUS:STATUS_SUCCESS,
                                           MESSAGE:@"接口调用成功，将在onBLEConnectionStateChange触发连接结果"
                                         } repeat:NO];
        }else{
            [self callBack:callback data:@{STATUS:STATUS_FAIL_NO_DEVICE,
                                           MESSAGE:@"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备"
                                         } repeat:NO];
        }
    }
}

#pragma mark 断开设备连接
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)closeBLEConnection:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    if([self isAvailable:callback]){
        NSString *deviceId=[options objectForKey:DEVICE_ID];
        CBPeripheral *device=[self getDevice:deviceId];
        if(device){
            [baby cancelPeripheralConnection:device];
            [self callBack:callback data:@{STATUS:STATUS_SUCCESS,
                                           MESSAGE:@"接口调用成功，将在onBLEConnectionStateChange触发状态变化"
                                         } repeat:NO];
        }else{
            [self callBack:callback data:@{STATUS:STATUS_FAIL_NO_DEVICE,
                                           MESSAGE:@"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备"
                                         } repeat:NO];
        }
    }
}

#pragma mark 监听设备链接状态变化
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)onBLEConnectionStateChange:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    onBLEConnectionStateChangeCallback=callback;
}

#pragma mark 获取设备服务
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)getBLEDeviceServices:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    if([self isAvailable:callback]){
        NSString *deviceId=[options objectForKey:DEVICE_ID];
        NSArray<CBService *> *services=[self getService:deviceId];
        if(services){
            NSMutableArray *arr=[[NSMutableArray alloc] init];
            for(CBService *service in services){
                [arr addObject:@{
                    @"uuid":service.UUID.UUIDString,
                    @"isPrimary":[NSNumber numberWithBool:service.isPrimary]
                }];
            }
            [self callBack:callback data:@{STATUS:STATUS_SUCCESS,
                                           @"services":[self toJSON:arr],
                                           MESSAGE:@"获取服务完成"
                                         } repeat:NO];
        }else{
            if([self getConnectedDevice:deviceId]){
                //异步回调
                [self setGetBLEDeviceServicesCallback:deviceId callback:callback];
            }else{
                [self callBack:callback data:@{STATUS:STATUS_FAIL_NO_FOUND,
                                               MESSAGE:@"设备还未连接，无法获取到服务"
                                             } repeat:NO];
            }
        }
    }
}
#pragma mark 设置获取服务的异步回调
- (void)setGetBLEDeviceServicesCallback:(NSString *)deviceId callback:(UniModuleKeepAliveCallback)callback{
    [getBLEDeviceServicesCallbackMap setObject:callback forKey:deviceId];
}
#pragma mark 获取服务的异步回调
- (void)notifyGetBLEDeviceServicesCallback:(CBPeripheral *)device{
    UniModuleKeepAliveCallback callback=nil;
    NSString *key=device.identifier.UUIDString;
    if([getBLEDeviceServicesCallbackMap objectForKey:key]){
        callback=[getBLEDeviceServicesCallbackMap objectForKey:key];
    }
    if(callback){
        NSMutableArray *arr=[[NSMutableArray alloc] init];
        NSArray<CBService *> *services=device.services;
        for(CBService *service in services){
            [arr addObject:@{
                @"uuid":service.UUID.UUIDString,
                @"isPrimary":[NSNumber numberWithBool:service.isPrimary]
            }];
        }
        [self callBack:callback data:@{STATUS:STATUS_SUCCESS,
                                       @"services":[self toJSON:arr],
                                       MESSAGE:@"获取服务完成"
                                     } repeat:NO];
        //释放异步函数
        [getBLEDeviceServicesCallbackMap removeObjectForKey:key];
    }
}

#pragma mark 获取设备特征
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)getBLEDeviceCharacteristics:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    if([self isAvailable:callback]){
        NSString *deviceId=[options objectForKey:DEVICE_ID];
        NSString *serviceId=[options objectForKey:SERVICE_ID];
        NSArray<CBCharacteristic *> *characteristics=[self getCharacteristic:deviceId serviceId:serviceId];
        if(characteristics){
            NSMutableArray *arr=[[NSMutableArray alloc] init];
            for(CBCharacteristic *characteristic in characteristics){
               
                [arr addObject:@{
                    @"uuid":characteristic.UUID.UUIDString,
                    @"properties":@{
                        @"read":[NSNumber numberWithBool:characteristic.properties & CBCharacteristicPropertyRead],
                        @"write":[NSNumber numberWithBool:characteristic.properties & CBCharacteristicPropertyWrite],
                        @"notify":[NSNumber numberWithBool:characteristic.properties & CBCharacteristicPropertyNotify],
                        @"indicate":[NSNumber numberWithBool:characteristic.properties & CBCharacteristicPropertyIndicate]
                    }
                }];
            }
            [self callBack:callback data:@{STATUS:STATUS_SUCCESS,
                                           @"characteristics":[self toJSON:arr],
                                           MESSAGE:@"获取特征完成"
                                         } repeat:NO];
        }else{
            if([self getConnectedDevice:deviceId]){
                [self setGetBLEDeviceCharacteristicsCallback:[NSString stringWithFormat:@"%@-%@",deviceId,serviceId] callback:callback];
            }else{
                [self callBack:callback data:@{STATUS:STATUS_FAIL_NO_FOUND,
                                               MESSAGE:@"设备还未连接，无法获取到特征"
                                             } repeat:NO];
            }
        }
    }
}

#pragma mark 设置获取特征的异步回调
- (void)setGetBLEDeviceCharacteristicsCallback:(NSString *)key callback:(UniModuleKeepAliveCallback)callback{
    [getBLEDeviceCharacteristicsCallbackMap setObject:callback forKey:key];
}
#pragma mark 获取特征的异步回调
- (void)notifyGetBLEDeviceCharacteristicsCallback:(CBPeripheral *)device service:(CBService *)service{
    UniModuleKeepAliveCallback callback=nil;
    NSString *key=[NSString stringWithFormat:@"%@-%@",device.identifier.UUIDString,service.UUID.UUIDString];
    if([getBLEDeviceCharacteristicsCallbackMap objectForKey:key]){
        callback=[getBLEDeviceCharacteristicsCallbackMap objectForKey:key];
    }
    if(callback){
        NSMutableArray *arr=[[NSMutableArray alloc] init];
        NSArray<CBCharacteristic *> *characteristics=service.characteristics;
        for(CBCharacteristic *characteristic in characteristics){
            [arr addObject:@{
                @"uuid":characteristic.UUID.UUIDString,
                @"properties":@{
                    @"read":[NSNumber numberWithBool:characteristic.properties & CBCharacteristicPropertyRead],
                    @"write":[NSNumber numberWithBool:characteristic.properties & CBCharacteristicPropertyWrite],
                    @"notify":[NSNumber numberWithBool:characteristic.properties & CBCharacteristicPropertyNotify],
                    @"indicate":[NSNumber numberWithBool:characteristic.properties & CBCharacteristicPropertyIndicate]
                }
            }];
        }
        [self callBack:callback data:@{STATUS:STATUS_SUCCESS,
                                       @"characteristics":[self toJSON:arr],
                                       MESSAGE:@"获取特征完成"
                                     } repeat:NO];
        //释放异步函数
        [getBLEDeviceCharacteristicsCallbackMap removeObjectForKey:key];
    }
}

#pragma mark 写特征数据
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)writeBLECharacteristicValue:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    if([self isAvailable:callback]){
        NSString *deviceId=[options objectForKey:DEVICE_ID];
        NSString *serviceId=[options objectForKey:SERVICE_ID];
        NSString *characteristicId=[options objectForKey:CHARACTERISTIC_ID];
        NSString *data=[options objectForKey:@"value"];
        
        CBPeripheral *device=[self getDevice:deviceId];
        if(device){
            if(![self getConnectedDevice:deviceId]){
                [self callBack:callback data:@{STATUS:STATUS_UN_SUPPORT,
                                               MESSAGE:@"设备未连接，无法写数据"
                                             } repeat:NO];
                return;
            }
            NSArray<CBCharacteristic *> *characteristics=[self getCharacteristic:deviceId serviceId:serviceId];
            if(characteristics){
                CBCharacteristic *characteristic=nil;
                for(CBCharacteristic *cht in characteristics){
                    if([cht.UUID.UUIDString isEqualToString:characteristicId]){
                        characteristic=cht;
                        break;
                    }
                }
                if(characteristic){
                    if(characteristic.properties & CBCharacteristicPropertyWrite){
                        NSData *cdata = [self convertHexStrToData:data];
                        [device writeValue:cdata forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                        NSString *key=[NSString stringWithFormat:@"%@-%@-%@",deviceId,serviceId,characteristicId];
                        [self setWriteBLECharacteristicValueCallback:key callback:callback];
                    }else{
                        [self callBack:callback data:@{STATUS:STATUS_UN_SUPPORT,
                                                       MESSAGE:@"当前特征不支持写操作"
                                                     } repeat:NO];
                    }
                    
                }else{
                    [self callBack:callback data:@{STATUS:STATUS_FAIL_NO_FOUND,
                                                   MESSAGE:@"无法找到指定特征"
                                                 } repeat:NO];
                }
            }else{
                [self callBack:callback data:@{STATUS:STATUS_FAIL_NO_FOUND,
                                               MESSAGE:@"无法找到特征列表，设备可能正在同步服务，请稍后再试"
                                             } repeat:NO];
            }
        }else{
            [self callBack:callback data:@{STATUS:STATUS_FAIL_NO_DEVICE,
                                           MESSAGE:@"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备"
                                         } repeat:NO];
        }
    }
}
#pragma mark 设置特征值写入结果回调引用
-(void)setWriteBLECharacteristicValueCallback:(NSString *)key callback:(UniModuleKeepAliveCallback)callback{
    [writeBLECharacteristicValueCallbackMap setObject:callback forKey:key];
}
#pragma mark 异步通知特征值写入结果回调
-(void)notifyWriteBLECharacteristicValueCallback:(CBCharacteristic *) characteristic{
    UniModuleKeepAliveCallback callback=nil;
    NSString *key=[NSString stringWithFormat:@"%@-%@-%@",characteristic.service.peripheral.identifier.UUIDString,characteristic.service.UUID.UUIDString,characteristic.UUID.UUIDString];
    if([writeBLECharacteristicValueCallbackMap objectForKey:key]){
        callback=[writeBLECharacteristicValueCallbackMap objectForKey:key];
    }
    if(callback){
        [self callBack:callback data:@{STATUS:STATUS_SUCCESS,
                                       MESSAGE:@"写特征值完成"
                                     } repeat:NO];
        //释放异步函数
        [writeBLECharacteristicValueCallbackMap removeObjectForKey:key];
    }
}

#pragma mark 读特征数据
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)readBLECharacteristicValue:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    if([self isAvailable:callback]){
        NSString *deviceId=[options objectForKey:DEVICE_ID];
        NSString *serviceId=[options objectForKey:SERVICE_ID];
        NSString *characteristicId=[options objectForKey:CHARACTERISTIC_ID];
        CBPeripheral *device=[self getDevice:deviceId];
        if(device){
            if(![self getConnectedDevice:deviceId]){
                [self callBack:callback data:@{STATUS:STATUS_UN_SUPPORT,
                                               MESSAGE:@"设备未连接，无法读取数据"
                                             } repeat:NO];
                return;
            }
            NSArray<CBCharacteristic *> *characteristics=[self getCharacteristic:deviceId serviceId:serviceId];
            if(characteristics){
                CBCharacteristic *characteristic=nil;
                for(CBCharacteristic *cht in characteristics){
                    if([cht.UUID.UUIDString isEqualToString:characteristicId]){
                        characteristic=cht;
                        break;
                    }
                }
                if(characteristic){
                    if(characteristic.properties & CBCharacteristicPropertyRead){
                        [device readValueForCharacteristic:characteristic];
                        [self callBack:callback data:@{STATUS:STATUS_SUCCESS,
                                                       MESSAGE:@"已请求读取特征值，请在onBLECharacteristicValueChange中接收值"
                                                     } repeat:NO];
                    }else{
                        [self callBack:callback data:@{STATUS:STATUS_UN_SUPPORT,
                                                       MESSAGE:@"当前特征不支持读操作"
                                                     } repeat:NO];
                    }
                    
                }else{
                    [self callBack:callback data:@{STATUS:STATUS_FAIL_NO_FOUND,
                                                   MESSAGE:@"无法找到指定特征，设备可能不包含当前特征"
                                                 } repeat:NO];
                }
            }else{
                [self callBack:callback data:@{STATUS:STATUS_FAIL_NO_FOUND,
                                               MESSAGE:@"无法找到特征列表，设备可能正在同步服务，请稍后再试"
                                             } repeat:NO];
            }
        }else{
            [self callBack:callback data:@{STATUS:STATUS_FAIL_NO_DEVICE,
                                           MESSAGE:@"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备"
                                         } repeat:NO];
        }
    }
}

#pragma mark 监听设备特征值变化
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)onBLECharacteristicValueChange:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    onBLECharacteristicValueChangeCallback=callback;
}

#pragma mark 触发特征值变化监听
- (void)notifyBLECharacteristicValueChangeCallback:(CBPeripheral *)device characteristic:(CBCharacteristic *)characteristic {
    NSString *deviceId=device.identifier.UUIDString;
    NSString *serviceId=characteristic.service.UUID.UUIDString;
    NSString *characteristicId=characteristic.UUID.UUIDString;
    NSString *value=[self converDataToHexStr:characteristic.value];
    [self callBack:onBLECharacteristicValueChangeCallback data:@{
        STATUS:STATUS_SUCCESS,
        DEVICE_ID:deviceId,
        SERVICE_ID:serviceId,
        CHARACTERISTIC_ID:characteristicId,
        @"value":value,
        MESSAGE:@"获取特征值完成"
    } repeat:YES];
}

#pragma mark 订阅特征值变化
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)notifyBLECharacteristicValueChange:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    if([self isAvailable:callback]){
        NSString *deviceId=[options objectForKey:DEVICE_ID];
        NSString *serviceId=[options objectForKey:SERVICE_ID];
        NSString *characteristicId=[options objectForKey:CHARACTERISTIC_ID];
        CBPeripheral *device=[self getDevice:deviceId];
        if(device){
            CBPeripheral *cdevice=[self getConnectedDevice:deviceId];
            if(!cdevice){
                [self callBack:callback data:@{STATUS:STATUS_UN_SUPPORT,
                                               MESSAGE:@"设备未连接，无法订阅通知"
                                             } repeat:NO];
                return;
            }
            NSArray<CBCharacteristic *> *characteristics=[self getCharacteristic:deviceId serviceId:serviceId];
            if(characteristics){
                CBCharacteristic *characteristic=nil;
                for(CBCharacteristic *cht in characteristics){
                    if([cht.UUID.UUIDString isEqualToString:characteristicId]){
                        characteristic=cht;
                        break;
                    }
                }
                if(characteristic){
                    if (characteristic.properties & CBCharacteristicPropertyNotify ||  characteristic.properties & CBCharacteristicPropertyIndicate) {
                        __weak typeof(self)weakSelf = self;
                        NSLog(@"订阅特征Description:%@",characteristic.UUID.description);
                        [baby notify:device characteristic:characteristic block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
                            //订阅通知统一回调
                            [weakSelf notifyBLECharacteristicValueChangeCallback:peripheral characteristic:characteristics];
                        }];
                        [weakSelf callBack:callback data:@{STATUS:STATUS_SUCCESS,
                                                       MESSAGE:@"订阅成功，请在onBLECharacteristicValueChange中接收值"
                                                     } repeat:NO];
                        
                    }else{
                        [self callBack:callback data:@{STATUS:STATUS_UN_SUPPORT,
                                                       MESSAGE:@"当前特征没有订阅的权限"
                                                     } repeat:NO];
                    }
                }else{
                    [self callBack:callback data:@{STATUS:STATUS_FAIL_NO_FOUND,
                                                   MESSAGE:@"无法找到指定特征，设备可能不包含当前特征"
                                                 } repeat:NO];
                }
            }else{
                [self callBack:callback data:@{STATUS:STATUS_FAIL_NO_FOUND,
                                               MESSAGE:@"无法找到特征列表，设备可能还未连接或未启动"
                                             } repeat:NO];
            }
        }else{
            [self callBack:callback data:@{STATUS:STATUS_FAIL_NO_DEVICE,
                                           MESSAGE:@"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备"
                                         } repeat:NO];
        }
    }
}

#pragma mark 取消订阅特征值变化
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)cancelNotifyBLECharacteristicValueChange:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    if([self isAvailable:callback]){
        NSString *deviceId=[options objectForKey:DEVICE_ID];
        NSString *serviceId=[options objectForKey:SERVICE_ID];
        NSString *characteristicId=[options objectForKey:CHARACTERISTIC_ID];
        CBPeripheral *device=[self getDevice:deviceId];
        if(device){
            if(![self getConnectedDevice:deviceId]){
                [self callBack:callback data:@{STATUS:STATUS_UN_SUPPORT,
                                               MESSAGE:@"设备未连接，不支持此操作"
                                             } repeat:NO];
                return;
            }
            NSArray<CBCharacteristic *> *characteristics=[self getCharacteristic:deviceId serviceId:serviceId];
            if(characteristics){
                CBCharacteristic *characteristic=nil;
                for(CBCharacteristic *cht in characteristics){
                    if([cht.UUID.UUIDString isEqualToString:characteristicId]){
                        characteristic=cht;
                        break;
                    }
                }
                if(characteristic){
                    if (characteristic.properties & CBCharacteristicPropertyNotify ||  characteristic.properties & CBCharacteristicPropertyIndicate) {
                        
                        if(characteristic.isNotifying) {
                            [baby cancelNotify:device characteristic:characteristic];
                            [self callBack:callback data:@{STATUS:STATUS_SUCCESS,
                                                           MESSAGE:@"已取消订阅"
                                                         } repeat:NO];
                        }else{
                            [self callBack:callback data:@{STATUS:STATUS_SUCCESS,
                                                           MESSAGE:@"已取消订阅，当前特征未订阅无需取消"
                                                         } repeat:NO];
                        }
                    }else{
                        [self callBack:callback data:@{STATUS:STATUS_UN_SUPPORT,
                                                       MESSAGE:@"当前特征没有订阅的权限"
                                                     } repeat:NO];
                    }
                }else{
                    [self callBack:callback data:@{STATUS:STATUS_FAIL_NO_FOUND,
                                                   MESSAGE:@"无法找到指定特征，设备可能不包含当前特征"
                                                 } repeat:NO];
                }
            }else{
                [self callBack:callback data:@{STATUS:STATUS_FAIL_NO_FOUND,
                                               MESSAGE:@"无法找到特征列表，设备可能还未连接或未启动"
                                             } repeat:NO];
            }
        }else{
            [self callBack:callback data:@{STATUS:STATUS_FAIL_NO_DEVICE,
                                           MESSAGE:@"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备"
                                         } repeat:NO];
        }
    }
}

#pragma mark 添加断线重连的设备
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)addAutoReconnect:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    if([self isAvailable:callback]){
        NSString *deviceId=[options objectForKey:DEVICE_ID];
        CBPeripheral *device=[self getDevice:deviceId];
        if(device){
            [baby AutoReconnect:device];
            [self callBack:callback data:@{
                STATUS:STATUS_SUCCESS,
                MESSAGE:@"添加断线重连设备完成"
            } repeat:NO];
        }else{
            [self callBack:callback data:@{
                STATUS:STATUS_FAIL_NO_DEVICE,
                MESSAGE:@"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备"
            } repeat:NO];
        }
    }
}

#pragma mark 移除断线重连的设备
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)removeAutoReconnect:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    if([self isAvailable:callback]){
        NSString *deviceId=[options objectForKey:DEVICE_ID];
        CBPeripheral *device=[self getDevice:deviceId];
        if(device){
            [baby AutoReconnectCancel:device];
            [self callBack:callback data:@{
                STATUS:STATUS_SUCCESS,
                MESSAGE:@"移除断线重连设备完成"
            } repeat:NO];
        }else{
            [self callBack:callback data:@{
                STATUS:STATUS_FAIL_NO_DEVICE,
                MESSAGE:@"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备"
            } repeat:NO];
        }
    }
}

#pragma mark 获取设备最新信号强度
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)getBLEDeviceRSSI:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    if([self isAvailable:callback]){
        NSString *deviceId=[options objectForKey:DEVICE_ID];
        CBPeripheral *device=[self getDevice:deviceId];
        if(device){
            CBPeripheral *cdevice=[self getConnectedDevice:deviceId];
            if(cdevice){
                [self setGetBLEDeviceRSSICallback:deviceId callback:callback];
                [cdevice readRSSI];
            }else{
                [self callBack:callback data:@{STATUS:STATUS_UN_SUPPORT,
                                               MESSAGE:@"设备未连接，无法获取信号强度"
                                             } repeat:NO];
            }
        }else{
            [self callBack:callback data:@{
                STATUS:STATUS_FAIL_NO_DEVICE,
                MESSAGE:@"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备"
            } repeat:NO];
        }
    }
}

#pragma mark 设置获取信号强度回调引用
-(void)setGetBLEDeviceRSSICallback:(NSString *)key callback:(UniModuleKeepAliveCallback)callback{
    [getBLEDeviceRSSICallbackMap setObject:callback forKey:key];
}
#pragma mark 异步通知特征值写入结果回调
-(void)notifyGetBLEDeviceRSSICallback:(CBPeripheral *) device RSSI:(NSNumber *)RSSI{
    UniModuleKeepAliveCallback callback=nil;
    NSString *key=device.identifier.UUIDString;
    if([getBLEDeviceRSSICallbackMap objectForKey:key]){
        callback=[getBLEDeviceRSSICallbackMap objectForKey:key];
    }
    if(callback){
        [self callBack:callback data:@{STATUS:STATUS_SUCCESS,
                                       DEVICE_ID:key,
                                       @"RSSI":RSSI,
                                       MESSAGE:@"获取设备最新信号强度完成"
                                     } repeat:NO];
        //释放异步函数
        [getBLEDeviceRSSICallbackMap removeObjectForKey:key];
    }
}

#pragma mark 获取已处于连接状态的设备
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)getConnectedBluetoothDevices:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    if([self isAvailable:callback]){
        NSArray<CBPeripheral *> *arr=[baby findConnectedPeripherals];
        NSMutableArray *devices=[[NSMutableArray alloc] init];
        for(CBPeripheral *dev in arr){
            NSDictionary *d=[self getDeviceData:dev.identifier.UUIDString];
            if(d){
                [devices addObject:d];
            }else{
                //如果不包含，则可能恢复重连的设备
                if(dev&&dev.name){
                    NSDictionary *data=@{@"name":dev.name,
                                         @"localName":@"",
                                         DEVICE_ID:dev.identifier.UUIDString,
                                         @"RSSI":[NSNumber numberWithInt:-100],
                                         @"advertisData":@"",
                                         @"advertisServiceUUIDs":@"",
                                         @"tip":@"这台设备来自恢复的设备，可能缺少广播数据"
                    };
                    [devices addObject:data];
                }
            }
        }
        [self callBack:callback data:@{
            STATUS:STATUS_SUCCESS,
            DEVICES:[self toJSON:devices],
            MESSAGE:@"获取已连接设备完成"
        } repeat:NO];
    }
}

#pragma mark 获取已发现的设备
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)getBluetoothDevices:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    if([self isAvailable:callback]){
        NSMutableArray *devices=[[NSMutableArray alloc] init];
        NSDictionary *map=advCacheMap;
        for(NSString *k in map){
            NSDictionary *d=map[k];
            if(d){
                [devices addObject:d];
            }
        }
        NSArray<CBPeripheral *> *restoreDevices=[baby findReStorePeripherals];
        for(CBPeripheral *dev in restoreDevices){
            if(![self getDeviceData:dev.identifier.UUIDString]){
                if(dev&&dev.name){
                    //如果不包含，则可能是需要恢复重连的设备
                    NSDictionary *data=@{@"name":dev.name,
                                         @"localName":@"",
                                         DEVICE_ID:dev.identifier.UUIDString,
                                         @"RSSI":[NSNumber numberWithInt:-100],
                                         @"advertisData":@"",
                                         @"advertisServiceUUIDs":@"",
                                         @"restore":[NSNumber numberWithBool:YES],
                                         @"tip":@"这台设备是APP意外关闭，可能需要恢复重连的设备，可使用createBLEConnection进行重连"
                    };
                    [devices addObject:data];
                }
            }
        }
        [self callBack:callback data:@{
            STATUS:STATUS_SUCCESS,
            DEVICES:[self toJSON:devices],
            MESSAGE:@"获取已发现的设备完成"
        } repeat:NO];
    }
}

#pragma mark 获取蓝牙适配器当前状态
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)getBluetoothAdapterState:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    if([self isAvailable:callback]){
        NSDictionary *data=[self getAdapterStatus:[baby centralManager]];
        [self callBack:callback data:data repeat:NO];
    }
}

#pragma mark 关闭蓝牙适配器
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)closeBluetoothAdapter:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    if([self isAvailable:callback]){
        [baby cancelScan];
        [baby cancelAllPeripheralsConnection];
        [self callBack:callback data:@{
            STATUS:STATUS_SUCCESS,
            MESSAGE:@"已断开所有连接和释放资源"
        } repeat:NO];
    }
}

#pragma mark 蓝牙配置和操作

//蓝牙网关初始化和委托方法设置
-(void)babyDelegate{
    if(isInit==YES){
        NSLog(@"委托已设置过，不需要重新设置");
        return;
    }
    isInit=YES;
    //初始化蓝牙缓存对象
    deviceMap=[[NSMutableDictionary alloc]init];
    serviceMap=[[NSMutableDictionary alloc]init];
    characteristicMap=[[NSMutableDictionary alloc]init];
    descriptorMap=[[NSMutableDictionary alloc]init];
    advCacheMap=[[NSMutableDictionary alloc]init];
    writeBLECharacteristicValueCallbackMap=[[NSMutableDictionary alloc]init];
    getBLEDeviceRSSICallbackMap=[[NSMutableDictionary alloc]init];
    getBLEDeviceServicesCallbackMap=[[NSMutableDictionary alloc]init];
    getBLEDeviceCharacteristicsCallbackMap=[[NSMutableDictionary alloc]init];
    //监听设备各种事件
    __weak typeof(self) weakSelf = self;
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if (central.state == CBCentralManagerStatePoweredOn) {
            NSLog(@"蓝牙适配器电源开启");
        }else if(central.state == CBCentralManagerStatePoweredOff){
            NSLog(@"蓝牙适配器电源关闭");
        }else if(central.state == CBCentralManagerStateUnauthorized){
            NSLog(@"没有授予蓝牙权限");
        }
        [weakSelf updateAdapterStatus:central];
    }];
    
    //设置扫描到设备的委托
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"搜索到了设备:%@",peripheral);
        [weakSelf updateDevic:central peripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    }];
    
    //设置发现设备的Services的委托
    [baby setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
        NSLog(@"搜索到服务:%@",peripheral.services);
        [weakSelf updateService:peripheral];
    }];
    //设置发现设service的Characteristics的委托
    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        NSLog(@"发现服务【%@】的特征:%@",service.UUID,service.characteristics);
        [weakSelf updateCharacteristic:peripheral service:service];
    }];
    //设置读取characteristics的委托
    [baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        NSLog(@"读取到特征【%@】的值:%@",characteristics.UUID,characteristics.value);
        [weakSelf notifyBLECharacteristicValueChangeCallback:peripheral characteristic:characteristics];
    }];
    //设置发现characteristics的descriptors的委托
    [baby setBlockOnDiscoverDescriptorsForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"发现特征【%@】的描述:%@",characteristic.UUID,characteristic.descriptors);
        [weakSelf updateDescriptor:peripheral characteristic:characteristic];
    }];
    //设置读取Descriptor的委托
    [baby setBlockOnReadValueForDescriptors:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
        NSLog(@"读取到描述【%@】的值:%@",descriptor.UUID,descriptor.value);
        
    }];
    //设置写特征值完成的委托
    [baby setBlockOnDidWriteValueForCharacteristic:^(CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"写特征值完成,%@值:%@",characteristic.UUID.UUIDString,characteristic.value);
        [weakSelf notifyWriteBLECharacteristicValueCallback:characteristic];
    }];
    //设置查找设备的过滤器
    [baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        //设置查找规则是名称大于0 ， the search rule is peripheral.name length > 0
        if (peripheralName.length >0) {
            return YES;
        }
        return NO;
    }];
    
    
    [baby setBlockOnCancelAllPeripheralsConnectionBlock:^(CBCentralManager *centralManager) {
        NSLog(@"断开了所有链接");
    }];
//    [baby setBlockOnCancelScanBlock:^(CBCentralManager *centralManager) {
//        NSLog(@"停止扫描");
//        [weakSelf updateAdapterStatus:centralManager];
//    }];
    [baby setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        NSLog(@"设备已连接:%@",peripheral.name);
        [weakSelf updateDeviceStatus:peripheral status:YES];
    }];
    [baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备断开链接:%@",peripheral.name);
        [weakSelf updateDeviceStatus:peripheral status:NO];
    }];
    [baby setBlockOnDidUpdateNotificationStateForCharacteristic:^(CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"特征订阅状态变更,uid:%@,isNotifying:%@",characteristic.UUID,characteristic.isNotifying?@"on":@"off");
        [weakSelf updateCharacteristicStatus:characteristic];
    }];
    [baby setBlockOnDidReadRSSI:^(CBPeripheral *peripheral, NSNumber *RSSI, NSError *error) {
        NSLog(@"读取到信号强度:%@,%@",peripheral.identifier.UUIDString,RSSI);
        [weakSelf notifyGetBLEDeviceRSSICallback:peripheral RSSI:RSSI];
    }];
    /*设置babyOptions
     
     参数分别使用在下面这几个地方，若不使用参数则传nil
     - [centralManager scanForPeripheralsWithServices:scanForPeripheralsWithServices options:scanForPeripheralsWithOptions];
     - [centralManager connectPeripheral:peripheral options:connectPeripheralWithOptions];
     - [peripheral discoverServices:discoverWithServices];
     - [peripheral discoverCharacteristics:discoverWithCharacteristics forService:service];
     
     该方法支持channel版本:
     [baby setBabyOptionsAtChannel:<#(NSString *)#> scanForPeripheralsWithOptions:<#(NSDictionary *)#> connectPeripheralWithOptions:<#(NSDictionary *)#> scanForPeripheralsWithServices:<#(NSArray *)#> discoverWithServices:<#(NSArray *)#> discoverWithCharacteristics:<#(NSArray *)#>]
     */
    
    //示例:
    //扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    //连接设备->
    [baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:nil scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];
    //启动一个定时任务
    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(timerTask) userInfo:nil repeats:YES];
}
#pragma mark 清理设备的服务特征等缓存对象
- (void)cleanDeviceServiceCache:(CBPeripheral *)device{
    NSString *deviceId=device.identifier.UUIDString;
    //清理服务
    NSMutableDictionary *tempSer=[[NSMutableDictionary alloc] initWithDictionary:serviceMap];
    for(NSString *k in tempSer){
        if([k hasPrefix:deviceId]){
            [serviceMap removeObjectForKey:k];
        }
    }
    //清理特征
    NSMutableDictionary *tempCha=[[NSMutableDictionary alloc] initWithDictionary:characteristicMap];
    for(NSString *k in tempCha){
        if([k hasPrefix:deviceId]){
            [characteristicMap removeObjectForKey:k];
        }
    }
    //清理描述符
    NSMutableDictionary *tempDes=[[NSMutableDictionary alloc] initWithDictionary:descriptorMap];
    for(NSString *k in tempDes){
        if([k hasPrefix:deviceId]){
            [descriptorMap removeObjectForKey:k];
        }
    }
}

-(void)timerTask{
    NSLog(@"timerTask");
}
#pragma mark 字典转json
- (NSString *)toJSON:(id)theData{
    NSLog(@"转JSON前:%@",theData);
    NSString * jsonString = @"";
    if (theData) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:theData
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:nil];
        if ([jsonData length] != 0){
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
    }
    return jsonString;
}
#pragma mark 十六进制字符串转NSData
- (NSData *)convertHexStrToData:(NSString *)str
{
    if (!str || [str length] == 0) {
        return nil;
    }
    
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:1024];
    NSRange range;
    if ([str length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [str substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    return hexData;
}
#pragma mark NSData转十六进制字符串
-(NSString *)converDataToHexStr:(NSData *)data{
    Byte *bytes = (Byte *)[data bytes];
    NSString *hexStr=@"";
    for(int i=0;i<[data length];i++) {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        if([newHexStr length]==1){
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        }
        else{
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
        }
    }
    hexStr = [hexStr uppercaseString];
    return hexStr;
}

#pragma mark 通用的蓝牙未初始化返回操作
-(BOOL)isAvailable:(UniModuleKeepAliveCallback)callback {
    if(baby){
        return YES;
    }else{
        [self callBack:callback data:@{STATUS:STATUS_UN_INIT,
                                       MESSAGE:@"蓝牙未初始化，请调用openBluetoothAdapter进行初始化操作"
                                     } repeat:NO];
        return false;
    }
}
#pragma mark 通用返回操作
-(void)callBack:(UniModuleKeepAliveCallback)callback data:(NSDictionary *)data repeat:(BOOL)repeat {
    if(callback){
        callback(data,repeat);
    }
}
#pragma mark 更新适配器状态
-(void)updateAdapterStatus:(CBCentralManager *)central{
    NSDictionary *data=[self getAdapterStatus:central];
    [self callBack:onBluetoothAdapterStateChangeCallback data:data repeat:YES];
}
#pragma mark 获取组装好的蓝牙适配器状态数据
-(NSDictionary *)getAdapterStatus:(CBCentralManager *)central{
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            return @{STATUS:STATUS_FAIL_NO_DEVICE,
                       MESSAGE:@"适配器状态变化-蓝牙正在初始化或重置，等待完成后更新状态"
                    };
        case CBCentralManagerStateResetting:
            return @{STATUS:STATUS_FAIL_NO_DEVICE,
                       MESSAGE:@"适配器状态变化-蓝牙正在重置，等待完成后更新状态"
                    };
        case CBCentralManagerStateUnsupported:
            return @{STATUS:STATUS_FAIL_NO_DEVICE,
                       MESSAGE:@"此设备不支持低功耗蓝牙"
                    };
        case CBCentralManagerStateUnauthorized:
            return @{STATUS:STATUS_SUCCESS,
                       @"available":[NSNumber numberWithBool:false],
                       @"discovering":[NSNumber numberWithBool:central.isScanning],
                       MESSAGE:@"适配器状态变化-没有授予蓝牙权限"
                    };
        case CBCentralManagerStatePoweredOff:
            return @{STATUS:STATUS_SUCCESS,
                       @"available":[NSNumber numberWithBool:false],
                       @"discovering":[NSNumber numberWithBool:central.isScanning],
                       MESSAGE:@"适配器状态变化-蓝牙开关关闭"
                      };
        case CBCentralManagerStatePoweredOn:
            return @{STATUS:STATUS_SUCCESS,
                       @"available":[NSNumber numberWithBool:true],
                       @"discovering":[NSNumber numberWithBool:central.isScanning],
                       MESSAGE:@"适配器状态变化-已开启可以正常使用"
                      };
        default:
            return @{STATUS:STATUS_FAIL_NO_FOUND,
                       MESSAGE:@"适配器状态无法匹配到-未知"
                    };
    }
}

#pragma mark 获取已缓存的蓝牙对象
-(CBPeripheral *)getDevice:(NSString *)deviceId{
    if([deviceMap objectForKey:deviceId]){
        return [deviceMap objectForKey:deviceId];
    }
    NSArray<CBPeripheral *> *restoreDevices=[baby findReStorePeripherals];
    for(CBPeripheral *dev in restoreDevices){
        if([dev.identifier.UUIDString isEqualToString:deviceId]){
            [self updateDevic:dev];
            return dev;
        }
    }
    return nil;
}
#pragma mark 获取已缓存的蓝牙广播数据对象
-(NSDictionary *)getDeviceData:(NSString *)deviceId{
    return [advCacheMap objectForKey:deviceId];
}
#pragma mark 更新设备缓存
-(void)updateDevic:(CBPeripheral *)peripheral{
    [deviceMap setObject:peripheral forKey:peripheral.identifier.UUIDString];
}
#pragma mark 更新设备缓存
-(void)updateDevic:(CBCentralManager *)central peripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    [deviceMap setObject:peripheral forKey:peripheral.identifier.UUIDString];
    
    NSString *localName;
    if ([advertisementData objectForKey:CBAdvertisementDataLocalNameKey]) {
        localName = [NSString stringWithFormat:@"%@",[advertisementData objectForKey:CBAdvertisementDataLocalNameKey]];
    }else{
        localName = peripheral.name;
    }
    //广播服务列表
    NSArray<CBUUID *> *serviceUUIDs = [advertisementData objectForKey:CBAdvertisementDataServiceUUIDsKey];
    NSMutableArray *services=[[NSMutableArray alloc]init];
    if (serviceUUIDs) {
        for(CBUUID *uid in serviceUUIDs){
            [services addObject:uid.UUIDString];
        }
    }
    //厂商数据
    NSData *manufcData = advertisementData[CBAdvertisementDataManufacturerDataKey];
    NSMutableString *advertisData = [NSMutableString stringWithString:@""];
    if(manufcData){
        [advertisData appendString:[self converDataToHexStr:manufcData]];
    }
    
    NSLog(@"组装好的服务id:%@",services);
    NSDictionary *data=@{@"name":peripheral.name,
                         @"localName":localName,
                         DEVICE_ID:peripheral.identifier.UUIDString,
                         @"RSSI":RSSI,
                         @"advertisData":advertisData,
                         @"advertisServiceUUIDs":services
    };
    //缓存对象
    [advCacheMap setObject:data forKey:peripheral.identifier.UUIDString];
    //触发监听
    if(onBluetoothDeviceFoundCallback){
        NSMutableDictionary *cdata=[[NSMutableDictionary alloc] init];
        NSMutableArray *devices=[[NSMutableArray alloc] init];
        [devices addObject:data];
        [cdata setObject:STATUS_SUCCESS forKey:STATUS];
        [cdata setObject:@"发现了一台设备" forKey:MESSAGE];
        [cdata setObject:[self toJSON:devices] forKey:DEVICES];
        //广播数据
        [self callBack:onBluetoothDeviceFoundCallback data:cdata repeat:YES];
    }
}
#pragma mark 触发设备状态变化事件
-(void)updateDeviceStatus:(CBPeripheral *)device status:(BOOL)status{
    [deviceMap setObject:device forKey:device.identifier.UUIDString];
    if(status==YES){
        //重连后旧的服务和特征对象失效了，清理掉防止重用
        [self cleanDeviceServiceCache:device];
    }
    [self callBack:onBLEConnectionStateChangeCallback data:@{STATUS:STATUS_SUCCESS,
         DEVICE_ID:device.identifier.UUIDString,
         @"connected":[NSNumber numberWithBool:status],
         MESSAGE:@"状态变化"
       } repeat:YES];
}
#pragma mark 根据设备id获取服务列表
-(NSArray<CBService *> *)getService:(NSString *)deviceId{
    if([serviceMap objectForKey:deviceId]){
        return [serviceMap objectForKey:deviceId];
    }
    return nil;
}
#pragma mark 更新服务缓存
-(void)updateService:(CBPeripheral *)device{
    [serviceMap setObject:[NSMutableArray arrayWithArray:device.services] forKey:device.identifier.UUIDString];
    [self notifyGetBLEDeviceServicesCallback:device];
}
#pragma mark 根据服务id获取特征列表
-(NSMutableArray<CBCharacteristic *> *)getCharacteristic:(NSString *)deviceId serviceId:(NSString *)serviceId{
    NSString *key=[NSString stringWithFormat:@"%@-%@",deviceId,serviceId];
    if([characteristicMap objectForKey:key]){
        return [characteristicMap objectForKey:key];
    }
    return nil;
}
#pragma mark 更新特征缓存
-(void)updateCharacteristic:(CBPeripheral *)device service:(CBService *)service{
    [characteristicMap setObject:[NSMutableArray arrayWithArray:service.characteristics] forKey:[NSString stringWithFormat:@"%@-%@",device.identifier.UUIDString,service.UUID.UUIDString]];
    [self notifyGetBLEDeviceCharacteristicsCallback:device service:service];
}
#pragma mark 更新特征状态
-(void)updateCharacteristicStatus:(CBCharacteristic *)characteristic {
    NSString *deviceId=characteristic.service.peripheral.identifier.UUIDString;
    NSString *serviceId=characteristic.service.UUID.UUIDString;
    NSMutableArray<CBCharacteristic *> *arr=[self getCharacteristic:deviceId serviceId:serviceId];
    int index=-1;
    for(int i=0; i<arr.count; i++){
        CBCharacteristic *cht=[arr objectAtIndex:i];
        if([cht.UUID.UUIDString isEqualToString:characteristic.UUID.UUIDString]){
            index=i;
            break;
        }
    }
    //替换对象
    if(index>=0){
        [arr replaceObjectAtIndex:index withObject:characteristic];
    }
}
#pragma mark 根据特征id获取描述符列表
-(NSArray<CBDescriptor *> *)getDescriptor:(NSString *)deviceId serviceId:(NSString *)serviceId characteristicId:(NSString *)characteristicId{
    NSString *key=[NSString stringWithFormat:@"%@-%@-%@",deviceId,serviceId,characteristicId];
    if([descriptorMap objectForKey:key]){
        return [descriptorMap objectForKey:key];
    }
    return nil;
}
#pragma mark 更新描述符缓存
-(void)updateDescriptor:(CBPeripheral *)device characteristic:(CBCharacteristic *)characteristic{
    [descriptorMap setObject:[NSMutableArray arrayWithArray:characteristic.descriptors] forKey:[NSString stringWithFormat:@"%@-%@-%@",device.identifier.UUIDString,characteristic.service.UUID.UUIDString,characteristic.UUID.UUIDString]];
}
#pragma mark 根据设备id获取已连接的设备
-(CBPeripheral *) getConnectedDevice:(NSString *)deviceId{
    NSArray *arr=[baby findConnectedPeripherals];
    if(arr){
        for(CBPeripheral *dev in arr){
            if([dev.identifier.UUIDString isEqualToString:deviceId]){
                return dev;
            }
        }
    }
    return nil;
}

@end
