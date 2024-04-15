//
//  Const.m
//  sand-plugin-bluetooth
//
//  Created by Qianjiao Wang on 2022/6/7.
//

#import <Foundation/Foundation.h>

NSString * const STATUS=@"status";
NSString * const MESSAGE=@"message";
NSString * const DEVICE_ID=@"deviceId";
NSString * const SERVICE_ID=@"serviceId";
NSString * const CHARACTERISTIC_ID=@"characteristicId";
NSString * const DEVICES=@"devices";
//正常
NSString * const STATUS_SUCCESS=@"2500";
//蓝牙适配器不可用
NSString * const STATUS_UN_INIT=@"2501";
//设备未发现
NSString * const STATUS_FAIL_NO_DEVICE=@"2502";
//其他服务特征等未发现
NSString * const STATUS_FAIL_NO_FOUND=@"2503";
//不支持的操作
NSString * const STATUS_UN_SUPPORT=@"2504";
//未知错误
NSString * const STATUS_UNKNOWN_ERROR=@"2505";
