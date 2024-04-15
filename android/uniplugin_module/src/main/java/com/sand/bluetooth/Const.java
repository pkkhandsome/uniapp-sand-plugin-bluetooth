package com.sand.bluetooth;

public class Const {
    public static final String STATUS = "status";
    public static final String MESSAGE = "message";
    public static final String DEVICE_ID = "deviceId";
    public static final String MTU = "mtu";
    public static final String SERVICE_ID = "serviceId";
    public static final String CHARACTERISTIC_ID = "characteristicId";
    public static final String DEVICES = "devices";
    //正常
    public static final String STATUS_SUCCESS = "2500";
    //蓝牙适配器不可用
    public static final String STATUS_UN_INIT = "2501";
    //设备未发现
    public static final String STATUS_FAIL_NO_DEVICE = "2502";
    //其他服务特征等未发现
    public static final String STATUS_FAIL_NO_FOUND = "2503";
    //不支持的操作
    public static final String STATUS_UN_SUPPORT = "2504";
    //未知错误
    public static final String STATUS_UNKNOWN_ERROR = "2505";
}
