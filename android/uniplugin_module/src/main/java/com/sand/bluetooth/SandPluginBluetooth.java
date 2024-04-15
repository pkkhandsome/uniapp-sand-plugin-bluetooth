package com.sand.bluetooth;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Handler;
import android.os.ParcelUuid;
import android.util.Log;
import android.util.SparseArray;

import androidx.annotation.NonNull;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.facebook.common.util.Hex;
import com.vise.baseble.ViseBle;
import com.vise.baseble.callback.IBleCallback;
import com.vise.baseble.callback.IConnectCallback;
import com.vise.baseble.callback.IRssiCallback;
import com.vise.baseble.callback.scan.IScanCallback;
import com.vise.baseble.callback.scan.ScanCallback;
import com.vise.baseble.common.ConnectState;
import com.vise.baseble.common.PropertyType;
import com.vise.baseble.core.BluetoothGattChannel;
import com.vise.baseble.core.DeviceMirror;
import com.vise.baseble.exception.BleException;
import com.vise.baseble.model.BluetoothLeDevice;
import com.vise.baseble.model.BluetoothLeDeviceStore;
import com.vise.baseble.model.adrecord.AdRecord;
import com.vise.baseble.model.adrecord.AdRecordStore;
import com.vise.baseble.utils.AdRecordUtil;
import com.vise.baseble.utils.HexUtil;

import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.ConcurrentHashMap;

import io.dcloud.feature.uniapp.annotation.UniJSMethod;
import io.dcloud.feature.uniapp.bridge.UniJSCallback;
import io.dcloud.feature.uniapp.common.UniModule;

public class SandPluginBluetooth extends UniModule {

    private static final int PERMISSION_REQUEST_COARSE_LOCATION = 1;
    //蓝牙管理对象
    private ViseBle bleManager;
    //缓存已经扫描到的蓝牙对象
    private ConcurrentHashMap<String, BluetoothLeDevice> deviceMap;
    //缓存断线重连蓝牙对象
    private ConcurrentHashMap<String, BluetoothLeDevice> reConnectDeviceMap;
    //缓存已获取到的服务对象
    private ConcurrentHashMap<String, List<BluetoothGattService>> serviceMap;
    //缓存已获取到的特征对象
    private ConcurrentHashMap<String, List<BluetoothGattCharacteristic>> characteristicMap;
    //缓存写通道对象
    private ConcurrentHashMap<String, BluetoothGattChannel> writeChannelMap;
    //缓存读通道对象
    private ConcurrentHashMap<String, BluetoothGattChannel> readChannelMap;
    //缓存订阅通道对象
    private ConcurrentHashMap<String, BluetoothGattChannel> notifyChannelMap;
    //缓存设备广播内容
    private ConcurrentHashMap<String, JSONObject> advCacheMap;
    //首次标志
    private boolean isInit=false;
    //监听-蓝牙适配器状态变化
    private UniJSCallback onBluetoothAdapterStateChangeCallback;
    //监听-扫描设备发现
    private UniJSCallback onBluetoothDeviceFoundCallback;
    //监听-设备链接状态变化
    private UniJSCallback onBLEConnectionStateChangeCallback;
    //异步回调-写值完成
    private ConcurrentHashMap<String,UniJSCallback> writeBLECharacteristicValueCallbackMap;
    //监听-设备特征值变化坚挺
    private UniJSCallback onBLECharacteristicValueChangeCallback;
    //异步回调-获取信号强度
    private ConcurrentHashMap<String,UniJSCallback> getBLEDeviceRSSICallbackMap;
    //统一事件监听-扫描
    private ScanCallback scanListener;
    //统一事件监听-连接
    private IConnectCallback connectListener;
    //统一事件监听-写数据
    private IBleCallback writeListener;
    //统一事件监听-订阅数据
    private IBleCallback notifyListener;
    //统一事件监听-读取数据
    private IBleCallback readListener;
    //统一事件监听-读取信号强度
    private IRssiCallback rssiListener;
    //统一事件监听-订阅状态结果
    private IBleCallback notifyStateListener;


    /**
     * 初始化蓝牙对象和事件统一回调等
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void openBluetoothAdapter(JSONObject options,UniJSCallback callback) {
        //初始化对象
        this.bleManager=ViseBle.getInstance();
        //初始化事件监听
        this.initListener();

        JSONObject data=new JSONObject();
        data.put(Const.STATUS,Const.STATUS_SUCCESS);
        data.put(Const.MESSAGE,"蓝牙初始化完成");
        this.callBack(callback,data,false);
    }
    /**
     * 监听蓝牙适配器状态
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void onBluetoothAdapterStateChange(JSONObject options,UniJSCallback callback) {
        onBluetoothAdapterStateChangeCallback=callback;
    }
    /**
     * 启动扫描
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void startBluetoothDevicesDiscovery(JSONObject options,UniJSCallback callback) {
        if(this.isAvailable(callback)){
            bleManager.startScan(scanListener);
            JSONObject cdata=new JSONObject();
            cdata.put(Const.STATUS,Const.STATUS_SUCCESS);
            cdata.put(Const.MESSAGE,"开启设备扫描完成");
            this.callBack(callback,cdata,false);
        }
    }
    /**
     * 停止扫描
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void stopBluetoothDevicesDiscovery(JSONObject options,UniJSCallback callback) {
        if(this.isAvailable(callback)){
            bleManager.stopScan(scanListener);
            JSONObject cdata=new JSONObject();
            cdata.put(Const.STATUS,Const.STATUS_SUCCESS);
            cdata.put(Const.MESSAGE,"停止设备扫描完成");
            this.callBack(callback,cdata,false);
        }
    }
    /**
     * 监听设备发现
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void onBluetoothDeviceFound(JSONObject options,UniJSCallback callback) {
        onBluetoothDeviceFoundCallback=callback;
    }
    /**
     * 和设备建立链接
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void createBLEConnection(JSONObject options,UniJSCallback callback) {
        if(this.isAvailable(callback)){
            String deviceId= options.getString(Const.DEVICE_ID);
            int mtu = 0;
            if (options.containsKey(Const.MTU)) {
                mtu = options.getInteger(Const.MTU);
            }
            BluetoothLeDevice device=this.getDevice(deviceId);
            if(device!=null){
                if(mtu > 0) {
                    device.setMTU(mtu);
                }
                if(bleManager.getConnectState(device)== ConnectState.CONNECT_SUCCESS){
                    //已连接直接触发回调
                    JSONObject cdata=new JSONObject();
                    cdata.put(Const.STATUS,Const.STATUS_SUCCESS);
                    cdata.put(Const.DEVICE_ID,device.getAddress());
                    cdata.put("connected",true);
                    cdata.put(Const.MESSAGE,"状态变化");
                    this.callBack(onBLEConnectionStateChangeCallback,cdata,true);
                    JSONObject ccdata=new JSONObject();
                    ccdata.put(Const.STATUS,Const.STATUS_SUCCESS);
                    ccdata.put(Const.MESSAGE,"接口调用成功，将在onBLEConnectionStateChange触发连接结果");
                    this.callBack(callback,ccdata,false);
                    return;
                }
                if(this.isReConnectDevice(device)){
                    device.setAutoReconnect(true);
                }else{
                    device.setAutoReconnect(false);
                }
                bleManager.connect(device,connectListener);
                JSONObject ccdata=new JSONObject();
                ccdata.put(Const.STATUS,Const.STATUS_SUCCESS);
                ccdata.put(Const.MESSAGE,"接口调用成功，将在onBLEConnectionStateChange触发连接结果");
                this.callBack(callback,ccdata,false);
            }else{
                JSONObject cdata=new JSONObject();
                cdata.put(Const.STATUS,Const.STATUS_FAIL_NO_DEVICE);
                cdata.put(Const.MESSAGE,"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备");
                this.callBack(callback,cdata,false);
            }
        }
    }

    /**
     * 断开设备连接
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void closeBLEConnection(JSONObject options,UniJSCallback callback) {
        if(this.isAvailable(callback)){
            String deviceId=options.getString(Const.DEVICE_ID);
            BluetoothLeDevice device=this.getDevice(deviceId);
            if(device!=null){
                bleManager.disconnect(device);
                JSONObject ccdata=new JSONObject();
                ccdata.put(Const.STATUS,Const.STATUS_SUCCESS);
                ccdata.put(Const.MESSAGE,"接口调用成功，将在onBLEConnectionStateChange触发连接结果");
                this.callBack(callback,ccdata,false);
            }else{
                JSONObject cdata=new JSONObject();
                cdata.put(Const.STATUS,Const.STATUS_FAIL_NO_DEVICE);
                cdata.put(Const.MESSAGE,"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备");
                this.callBack(callback,cdata,false);
            }
        }
    }
    /**
     * 监听设备连接变化变化
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void onBLEConnectionStateChange(JSONObject options,UniJSCallback callback) {
        onBLEConnectionStateChangeCallback=callback;
    }
    /**
     * 获取设备服务列表
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void getBLEDeviceServices(JSONObject options,UniJSCallback callback) {
        if(this.isAvailable(callback)){
            String deviceId=options.getString(Const.DEVICE_ID);
            List<BluetoothGattService> services=this.getService(deviceId);
            if(services!=null){
                JSONArray list=new JSONArray();
                for(BluetoothGattService service : services){
                    JSONObject obj=new JSONObject();
                    obj.put("uuid",service.getUuid().toString());
                    obj.put("isPrimary",service.getType()==BluetoothGattService.SERVICE_TYPE_PRIMARY);
                    list.add(obj);
                }
                JSONObject cdata=new JSONObject();
                cdata.put(Const.STATUS,Const.STATUS_SUCCESS);
                cdata.put(Const.MESSAGE,"获取服务完成");
                cdata.put("services",list.toJSONString());
                this.callBack(callback,cdata,false);
            }else{
                this.callBack(callback,Const.STATUS_FAIL_NO_FOUND,"设备还未连接，无法获取到服务",false);
            }
        }
    }
    /**
     * 获取设备服务的特征列表
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void getBLEDeviceCharacteristics(JSONObject options,UniJSCallback callback) {
        if(this.isAvailable(callback)){
            String deviceId=options.getString(Const.DEVICE_ID);
            String serviceId=options.getString(Const.SERVICE_ID);
            List<BluetoothGattCharacteristic> characteristics=this.getCharacteristic(deviceId,serviceId);
            if(characteristics!=null){
                JSONArray list=new JSONArray();
                for(BluetoothGattCharacteristic characteristic : characteristics){
                    JSONObject obj=new JSONObject();
                    obj.put("uuid",characteristic.getUuid().toString());
                    JSONObject pro=new JSONObject();
                    pro.put("read",(characteristic.getProperties()&BluetoothGattCharacteristic.PROPERTY_READ)!=0x0);
                    pro.put("write",(characteristic.getProperties()&BluetoothGattCharacteristic.PROPERTY_WRITE)!=0x0);
                    pro.put("notify",(characteristic.getProperties()&BluetoothGattCharacteristic.PROPERTY_NOTIFY)!=0x0);
                    pro.put("indicate",(characteristic.getProperties()&BluetoothGattCharacteristic.PROPERTY_INDICATE)!=0x0);
                    obj.put("properties",pro);
                    list.add(obj);
                }
                JSONObject cdata=new JSONObject();
                cdata.put(Const.STATUS,Const.STATUS_SUCCESS);
                cdata.put(Const.MESSAGE,"获取特征完成");
                cdata.put("characteristics",list.toJSONString());
                this.callBack(callback,cdata,false);
            }else{
                this.callBack(callback,Const.STATUS_FAIL_NO_FOUND,"设备还未连接，无法获取到特征",false);
            }
        }
    }

    /**
     * 监听设备特征值变化
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void onBLECharacteristicValueChange(JSONObject options,UniJSCallback callback) {
        onBLECharacteristicValueChangeCallback=callback;
    }

    /**
     * 触发特征值变化监听
     * @param device
     * @param channel
     */
    private void notifyBLECharacteristicValueChangeCallback(BluetoothLeDevice device,BluetoothGattChannel channel,byte[] data){
        String deviceId=device.getAddress();
        String serviceId=channel.getServiceUUID().toString();
        String characteristicId=channel.getCharacteristicUUID().toString();
        String value=HexUtil.encodeHexStr(data,false);
        JSONObject cdata=new JSONObject();
        cdata.put(Const.STATUS,Const.STATUS_SUCCESS);
        cdata.put(Const.DEVICE_ID,deviceId);
        cdata.put(Const.SERVICE_ID,serviceId);
        cdata.put(Const.CHARACTERISTIC_ID,characteristicId);
        cdata.put("value",value);
        cdata.put(Const.MESSAGE,"获取特征值完成");
        this.callBack(onBLECharacteristicValueChangeCallback,cdata,true);
    }
    /**
     * 写特征值数据
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void writeBLECharacteristicValue(JSONObject options,UniJSCallback callback) {
        if(this.isAvailable(callback)){
            String deviceId=options.getString(Const.DEVICE_ID);
            String serviceId=options.getString(Const.SERVICE_ID);
            String characteristicId=options.getString(Const.CHARACTERISTIC_ID);
            String value=options.getString("value");
            BluetoothLeDevice device=this.getDevice(deviceId);
            if(device!=null){
                if(bleManager.getConnectState(device)!= ConnectState.CONNECT_SUCCESS){
                    JSONObject cdata=new JSONObject();
                    cdata.put(Const.STATUS,Const.STATUS_UN_SUPPORT);
                    cdata.put(Const.MESSAGE,"设备未连接，无法写数据");
                    this.callBack(callback,cdata,false);
                    return;
                }
                BluetoothGattService service=this.getService(deviceId,serviceId);
                if(service!=null){
                    BluetoothGattCharacteristic characteristic=this.getCharacteristic(deviceId,serviceId,characteristicId);
                    if(characteristic!=null){
                        if((characteristic.getProperties()&BluetoothGattCharacteristic.PROPERTY_WRITE)!=0x0){
                            DeviceMirror deviceMirror=bleManager.getDeviceMirror(device);
                            String channelKey=String.format("%s-%s-%s",deviceId,serviceId,characteristicId);
                            BluetoothGattChannel channel=null;
                            if(writeChannelMap.containsKey(channelKey)){
                                channel=writeChannelMap.get(channelKey);
                            }else{
                                channel=new BluetoothGattChannel.Builder()
                                        .setBluetoothGatt(deviceMirror.getBluetoothGatt())
                                        .setPropertyType(PropertyType.PROPERTY_WRITE)
                                        .setServiceUUID(service.getUuid())
                                        .setCharacteristicUUID(characteristic.getUuid())
                                        .builder();
                                writeChannelMap.put(channelKey,channel);
                            }
                            deviceMirror.bindChannel(writeListener, channel);
                            deviceMirror.writeData(HexUtil.decodeHex(value));
                            this.setWriteBLECharacteristicValueCallback(channelKey,callback);
                        }else{
                            JSONObject cdata=new JSONObject();
                            cdata.put(Const.STATUS,Const.STATUS_UN_SUPPORT);
                            cdata.put(Const.MESSAGE,"当前特征不支持写操作");
                            this.callBack(callback,cdata,false);
                        }
                    }else{
                        JSONObject cdata=new JSONObject();
                        cdata.put(Const.STATUS,Const.STATUS_FAIL_NO_FOUND);
                        cdata.put(Const.MESSAGE,"无法找到指定特征");
                        this.callBack(callback,cdata,false);
                    }
                }else{
                    JSONObject cdata=new JSONObject();
                    cdata.put(Const.STATUS,Const.STATUS_FAIL_NO_FOUND);
                    cdata.put(Const.MESSAGE,"无法找到特征列表，设备可能正在同步服务，请稍后再试");
                    this.callBack(callback,cdata,false);
                }
            }else{
                JSONObject cdata=new JSONObject();
                cdata.put(Const.STATUS,Const.STATUS_FAIL_NO_DEVICE);
                cdata.put(Const.MESSAGE,"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备");
                this.callBack(callback,cdata,false);
            }
        }
    }

    /**
     * 设置写数据操作异步回调
     * @param key
     * @param callback
     */
    private void setWriteBLECharacteristicValueCallback(String key,UniJSCallback callback){
        writeBLECharacteristicValueCallbackMap.put(key,callback);
    }

    /**
     * 写数据异步回调通知
     * @param device
     * @param channel
     */
    private void notifyWriteBLECharacteristicValueCallback(BluetoothLeDevice device,BluetoothGattChannel channel){
        UniJSCallback callback=null;
        String key=String.format("%s-%s-%s",device.getAddress(),channel.getServiceUUID().toString(),channel.getCharacteristicUUID().toString());
        if(writeBLECharacteristicValueCallbackMap.containsKey(key)){
            callback=writeBLECharacteristicValueCallbackMap.get(key);
        }
        if(callback!=null){
            JSONObject cdata=new JSONObject();
            cdata.put(Const.STATUS,Const.STATUS_SUCCESS);
            cdata.put(Const.MESSAGE,"写特征值完成");
            this.callBack(callback,cdata,false);
            //释放异步函数
            writeBLECharacteristicValueCallbackMap.remove(key);
        }
    }
    /**
     * 读特征值数据
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void readBLECharacteristicValue(JSONObject options,UniJSCallback callback) {
        if(this.isAvailable(callback)){
            String deviceId=options.getString(Const.DEVICE_ID);
            String serviceId=options.getString(Const.SERVICE_ID);
            String characteristicId=options.getString(Const.CHARACTERISTIC_ID);
            BluetoothLeDevice device=this.getDevice(deviceId);
            if(device!=null){
                if(bleManager.getConnectState(device)!= ConnectState.CONNECT_SUCCESS){
                    this.callBack(callback,Const.STATUS_UN_SUPPORT,"设备未连接，无法读数据",false);
                    return;
                }
                BluetoothGattService service=this.getService(deviceId,serviceId);
                if(service!=null){
                    BluetoothGattCharacteristic characteristic=this.getCharacteristic(deviceId,serviceId,characteristicId);
                    if(characteristic!=null){
                        if((characteristic.getProperties()&BluetoothGattCharacteristic.PROPERTY_READ)!=0x0){
                            DeviceMirror deviceMirror=bleManager.getDeviceMirror(device);
                            String channelKey=String.format("%s-%s-%s",deviceId,serviceId,characteristicId);
                            BluetoothGattChannel channel=null;
                            if(readChannelMap.containsKey(channelKey)){
                                channel=readChannelMap.get(channelKey);
                            }else{
                                channel=new BluetoothGattChannel.Builder()
                                        .setBluetoothGatt(deviceMirror.getBluetoothGatt())
                                        .setPropertyType(PropertyType.PROPERTY_READ)
                                        .setServiceUUID(service.getUuid())
                                        .setCharacteristicUUID(characteristic.getUuid())
                                        .builder();
                                readChannelMap.put(channelKey,channel);
                            }
                            deviceMirror.bindChannel(readListener, channel);
                            deviceMirror.readData();
                            this.callBack(callback,Const.STATUS_SUCCESS,"已请求读取特征值，请在onBLECharacteristicValueChange中接收值",false);
                        }else{
                            this.callBack(callback,Const.STATUS_UN_SUPPORT,"当前特征不支持读操作",false);
                        }
                    }else{
                        this.callBack(callback,Const.STATUS_FAIL_NO_FOUND,"无法找到指定特征",false);
                    }
                }else{
                    this.callBack(callback,Const.STATUS_FAIL_NO_FOUND,"无法找到特征列表，设备可能正在同步服务，请稍后再试",false);
                }
            }else{
                this.callBack(callback,Const.STATUS_FAIL_NO_DEVICE,"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备",false);
            }
        }
    }
    /**
     * 订阅特征值数据
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void notifyBLECharacteristicValueChange(JSONObject options,UniJSCallback callback) {
        if(this.isAvailable(callback)){
            String deviceId=options.getString(Const.DEVICE_ID);
            String serviceId=options.getString(Const.SERVICE_ID);
            String characteristicId=options.getString(Const.CHARACTERISTIC_ID);
            BluetoothLeDevice device=this.getDevice(deviceId);
            if(device!=null){
                if(bleManager.getConnectState(device)!= ConnectState.CONNECT_SUCCESS){
                    this.callBack(callback,Const.STATUS_UN_SUPPORT,"设备未连接，无法订阅数据",false);
                    return;
                }
                BluetoothGattService service=this.getService(deviceId,serviceId);
                if(service!=null){
                    BluetoothGattCharacteristic characteristic=this.getCharacteristic(deviceId,serviceId,characteristicId);
                    if(characteristic!=null){
                        if((characteristic.getProperties()&BluetoothGattCharacteristic.PROPERTY_NOTIFY)!=0x0||
                                (characteristic.getProperties()&BluetoothGattCharacteristic.PROPERTY_INDICATE)!=0x0){
                            DeviceMirror deviceMirror=bleManager.getDeviceMirror(device);
                            String channelKey=String.format("%s-%s-%s",deviceId,serviceId,characteristicId);
                            BluetoothGattChannel channel=null;
                            if(notifyChannelMap.containsKey(channelKey)){
                                channel=notifyChannelMap.get(channelKey);
                            }else{
                                channel=new BluetoothGattChannel.Builder()
                                        .setBluetoothGatt(deviceMirror.getBluetoothGatt())
                                        .setPropertyType(PropertyType.PROPERTY_NOTIFY)
                                        .setServiceUUID(service.getUuid())
                                        .setCharacteristicUUID(characteristic.getUuid())
                                        .builder();
                                notifyChannelMap.put(channelKey,channel);
                            }
                            deviceMirror.bindChannel(notifyStateListener, channel);
                            deviceMirror.registerNotify(false);
                            deviceMirror.setNotifyListener(channel.getGattInfoKey(),notifyListener);
                            this.callBack(callback,Const.STATUS_SUCCESS,"已请求订阅特征值，请在onBLECharacteristicValueChange中接收值",false);
                        }else{
                            this.callBack(callback,Const.STATUS_UN_SUPPORT,"当前特征不支持订阅操作",false);
                        }
                    }else{
                        this.callBack(callback,Const.STATUS_FAIL_NO_FOUND,"无法找到指定特征",false);
                    }
                }else{
                    this.callBack(callback,Const.STATUS_FAIL_NO_FOUND,"无法找到特征列表，设备可能正在同步服务，请稍后再试",false);
                }
            }else{
                this.callBack(callback,Const.STATUS_FAIL_NO_DEVICE,"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备",false);
            }
        }
    }
    /**
     * 订阅特征值数据
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void cancelNotifyBLECharacteristicValueChange(JSONObject options,UniJSCallback callback) {
        if(this.isAvailable(callback)){
            String deviceId=options.getString(Const.DEVICE_ID);
            String serviceId=options.getString(Const.SERVICE_ID);
            String characteristicId=options.getString(Const.CHARACTERISTIC_ID);
            BluetoothLeDevice device=this.getDevice(deviceId);
            if(device!=null){
                if(bleManager.getConnectState(device)!= ConnectState.CONNECT_SUCCESS){
                    this.callBack(callback,Const.STATUS_UN_SUPPORT,"设备未连接，不支持此操作",false);
                    return;
                }
                BluetoothGattService service=this.getService(deviceId,serviceId);
                if(service!=null){
                    BluetoothGattCharacteristic characteristic=this.getCharacteristic(deviceId,serviceId,characteristicId);
                    if(characteristic!=null){
                        if((characteristic.getProperties()&BluetoothGattCharacteristic.PROPERTY_NOTIFY)!=0x0||
                                (characteristic.getProperties()&BluetoothGattCharacteristic.PROPERTY_INDICATE)!=0x0){
                            DeviceMirror deviceMirror=bleManager.getDeviceMirror(device);
                            String channelKey=String.format("%s-%s-%s",deviceId,serviceId,characteristicId);
                            BluetoothGattChannel channel=null;
                            if(notifyChannelMap.containsKey(channelKey)){
                                channel=notifyChannelMap.get(channelKey);
                            }
                            if(channel!=null){
                                deviceMirror.unbindChannel(channel);
                                deviceMirror.unregisterNotify(false);
                            }
                            this.callBack(callback,Const.STATUS_SUCCESS,"已取消订阅",false);
                        }else{
                            this.callBack(callback,Const.STATUS_UN_SUPPORT,"当前特征不支持订阅操作",false);
                        }
                    }else{
                        this.callBack(callback,Const.STATUS_FAIL_NO_FOUND,"无法找到指定特征",false);
                    }
                }else{
                    this.callBack(callback,Const.STATUS_FAIL_NO_FOUND,"无法找到特征列表，设备可能正在同步服务，请稍后再试",false);
                }
            }else{
                this.callBack(callback,Const.STATUS_FAIL_NO_DEVICE,"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备",false);
            }
        }
    }
    /**
     * 添加断线重连设备
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void addAutoReconnect(JSONObject options,UniJSCallback callback) {
        if(this.isAvailable(callback)){
            String deviceId=options.getString(Const.DEVICE_ID);
            BluetoothLeDevice device=this.getDevice(deviceId);
            if(device!=null){
                this.addReConnectDevice(device);
                this.callBack(callback,Const.STATUS_SUCCESS,"添加断线重连设备完成",false);
            }else{
                this.callBack(callback,Const.STATUS_FAIL_NO_DEVICE,"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备",false);
            }
        }
    }
    /**
     * 移除断线重连设备
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void removeAutoReconnect(JSONObject options,UniJSCallback callback) {
        if(this.isAvailable(callback)){
            String deviceId=options.getString(Const.DEVICE_ID);
            BluetoothLeDevice device=this.getDevice(deviceId);
            if(device!=null){
                this.removeReConnectDevice(device);
                this.callBack(callback,Const.STATUS_SUCCESS,"移除断线重连设备完成",false);
            }else{
                this.callBack(callback,Const.STATUS_FAIL_NO_DEVICE,"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备",false);
            }
        }
    }
    /**
     * 获取设备当前信号强度
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void getBLEDeviceRSSI(JSONObject options,UniJSCallback callback) {
        if(this.isAvailable(callback)){
            String deviceId=options.getString(Const.DEVICE_ID);
            BluetoothLeDevice device=this.getDevice(deviceId);
            if(device!=null){
                if(bleManager.getConnectState(device)==ConnectState.CONNECT_SUCCESS){
                    bleManager.getDeviceMirror(device).readRemoteRssi(rssiListener);
                    this.setGetBLEDeviceRSSICallback(deviceId,callback);
                }else{
                    this.callBack(callback,Const.STATUS_UN_SUPPORT,"设备未连接，无法获取信号强度",false);
                }
            }else{
                this.callBack(callback,Const.STATUS_FAIL_NO_DEVICE,"设备不存在，请确认设备是否是通过startBluetoothDevicesDiscovery获取的设备",false);
            }
        }
    }

    /**
     * 设置异步回调
     * @param key
     * @param callback
     */
    private void setGetBLEDeviceRSSICallback(String key,UniJSCallback callback){
        getBLEDeviceRSSICallbackMap.put(key,callback);
    }

    /**
     * 通知异步回调
     * @param device
     * @param rssi
     */
    private void notifyGetBLEDeviceRSSICallback(BluetoothLeDevice device,int rssi){
        UniJSCallback callback=null;
        String key=device.getAddress();
        if(getBLEDeviceRSSICallbackMap.containsKey(key)){
            callback= getBLEDeviceRSSICallbackMap.get(key);
        }
        if(callback!=null){
            JSONObject cdata=new JSONObject();
            cdata.put(Const.STATUS,Const.STATUS_SUCCESS);
            cdata.put(Const.DEVICE_ID,device.getAddress());
            cdata.put("RSSI",rssi);
            cdata.put(Const.MESSAGE,"获取设备最新信号强度完成");
            this.callBack(callback,cdata,false);
            //释放异步函数
            getBLEDeviceRSSICallbackMap.remove(key);
        }
    }
    /**
     * 获取已连接的设备列表
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void getConnectedBluetoothDevices(JSONObject options,UniJSCallback callback) {
        if(this.isAvailable(callback)){
            List<DeviceMirror> list=bleManager.getDeviceMirrorPool().getDeviceMirrorList();
            JSONArray devices=new JSONArray();
            if(list!=null){
                for(DeviceMirror dm : list){
                    if(dm.getConnectState()==ConnectState.CONNECT_SUCCESS){
                        JSONObject d=this.getDeviceData(dm.getBluetoothLeDevice().getAddress());
                        if(d!=null){
                            devices.add(d);
                        }
                    }
                }
            }
            JSONObject cdata=new JSONObject();
            cdata.put(Const.STATUS,Const.STATUS_SUCCESS);
            cdata.put(Const.DEVICES,devices.toJSONString());
            cdata.put(Const.MESSAGE,"获取已连接设备完成");
            this.callBack(callback,cdata,false);
        }
    }
    /**
     * 获取已发现的设备列表
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void getBluetoothDevices(JSONObject options,UniJSCallback callback) {
        if(this.isAvailable(callback)){
            JSONArray devices=new JSONArray();
            Iterator<String> it=advCacheMap.keySet().iterator();
            while (it.hasNext()){
                String key=it.next();
                JSONObject d=advCacheMap.get(key);
                if(d!=null){
                    devices.add(d);
                }
            }
            JSONObject cdata=new JSONObject();
            cdata.put(Const.STATUS,Const.STATUS_SUCCESS);
            cdata.put(Const.DEVICES,devices.toJSONString());
            cdata.put(Const.MESSAGE,"获取已发现的设备完成");
            this.callBack(callback,cdata,false);
        }
    }
    /**
     * 获取适配器状态
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void getBluetoothAdapterState(JSONObject options,UniJSCallback callback) {
        if(this.isAvailable(callback)){
            JSONObject cdata=this.getAdapterStatus();
            this.callBack(callback,cdata,false);
        }
    }
    /**
     * 关闭适配器
     * 异步方法（注：异步方法会在主线程（UI线程）执行）
     *   @param options js 端调用方法时传递的参数
     *   @param callback 回调方法，回传参数给 js 端
     */
    @UniJSMethod(uiThread = true)
    public void closeBluetoothAdapter(JSONObject options,UniJSCallback callback) {
        if(this.isAvailable(callback)){
            bleManager.stopScan(scanListener);
            bleManager.disconnect();
            this.callBack(callback,Const.STATUS_SUCCESS,"已断开所有连接和释放资源",false);
        }
    }
    /**
     * 初始化统一事件监听
     */
    private void initListener() {
        //检查权限
        this.checkPermission();
        if(isInit){
            Log.i("initListener","委托已设置过，不需要重新设置");
            return;
        }
        isInit=true;
        //蓝牙相关配置修改
        ViseBle.config()
                .setScanTimeout(-1)//扫描超时时间，这里设置为永久扫描
                .setConnectTimeout(1000*3600);//连接超时时间设置为一小时
        bleManager.init(this.mUniSDKInstance.getContext());
        //初始化蓝牙缓存对象
        deviceMap=new ConcurrentHashMap<>();
        reConnectDeviceMap=new ConcurrentHashMap<>();
        serviceMap=new ConcurrentHashMap<>();
        characteristicMap=new ConcurrentHashMap<>();
        writeChannelMap=new ConcurrentHashMap<>();
        readChannelMap=new ConcurrentHashMap<>();
        notifyChannelMap=new ConcurrentHashMap<>();
        advCacheMap=new ConcurrentHashMap<>();
        writeBLECharacteristicValueCallbackMap=new ConcurrentHashMap<>();
        getBLEDeviceRSSICallbackMap=new ConcurrentHashMap<>();
        //监听设备各种事件
        SandPluginBluetooth _this=this;
        //监听蓝牙适配器状态
        IntentFilter intentFilter = new IntentFilter();
        // 监视蓝牙关闭和打开的状态
        intentFilter.addAction(BluetoothAdapter.ACTION_STATE_CHANGED);
        BroadcastReceiver adapterListener=new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                if(action != null){
                    switch (action) {
                        case BluetoothAdapter.ACTION_STATE_CHANGED:
                            int blueState = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, 0);
                            switch (blueState) {
                                case BluetoothAdapter.STATE_ON:
                                case BluetoothAdapter.STATE_OFF:
                                    _this.updateAdapterStatus();
                                    break;
                            }
                            break;
                    }

                }
            }
        };
        // 动态注册广播
        this.mUniSDKInstance.getContext().registerReceiver(adapterListener, intentFilter);
        //扫描发现设备的监听(注：停止扫描也一定要使用这个callback)
        scanListener=new ScanCallback(new IScanCallback() {
            @Override
            public void onDeviceFound(BluetoothLeDevice bluetoothLeDevice) {
                _this.updateDevice(bluetoothLeDevice);
            }

            @Override
            public void onScanFinish(BluetoothLeDeviceStore bluetoothLeDeviceStore) {

            }

            @Override
            public void onScanTimeout() {

            }
        });
        //设置发现设备的Services的委托
        connectListener=new IConnectCallback() {
            @Override
            public void onConnectSuccess(DeviceMirror deviceMirror) {
                //框架在发现服务后才会回调这里，所以直接在这里就可以拿到服务特征等信息
                _this.updateService(deviceMirror);
                
                //更新设备状态并通知uni-app层回调
                _this.updateDeviceStatus(deviceMirror.getBluetoothLeDevice(),true);
            }

            @Override
            public void onConnectFailure(BluetoothLeDevice device, BleException exception) {
                Log.e("connectListener","连接设备失败，设备为"+device+",exception="+exception);
                if(device!=null){
                    _this.updateDeviceStatus(device,false);
                }
            }

            @Override
            public void onDisconnect(BluetoothLeDevice device, boolean isActive) {
                _this.updateDeviceStatus(device,false);
            }
        };
        //设置读取characteristics的值统一事件回调
        readListener=new IBleCallback() {
            @Override
            public void onSuccess(byte[] data, BluetoothGattChannel bluetoothGattChannel, BluetoothLeDevice bluetoothLeDevice) {
                _this.notifyBLECharacteristicValueChangeCallback(bluetoothLeDevice,bluetoothGattChannel,data);
            }

            @Override
            public void onFailure(BleException exception) {
                Log.e("readListener","读取特征值失败:"+exception);
            }
        };
        //设置写特征值完成的统一事件回调
        writeListener=new IBleCallback() {
            @Override
            public void onSuccess(byte[] data, BluetoothGattChannel bluetoothGattChannel, BluetoothLeDevice bluetoothLeDevice) {
                _this.notifyWriteBLECharacteristicValueCallback(bluetoothLeDevice, bluetoothGattChannel);
            }

            @Override
            public void onFailure(BleException exception) {
                Log.e("writeListener", "读取特征值失败:" + exception);
            }
        };
        notifyListener=new IBleCallback() {
            @Override
            public void onSuccess(byte[] data, BluetoothGattChannel bluetoothGattChannel, BluetoothLeDevice bluetoothLeDevice) {
                if(data!=null){
                    _this.notifyBLECharacteristicValueChangeCallback(bluetoothLeDevice,bluetoothGattChannel,data);
                }
            }

            @Override
            public void onFailure(BleException exception) {
                Log.e("notifyListener","读取特征值失败:"+exception);
            }
        };
        rssiListener=new IRssiCallback() {
            @Override
            public void onSuccess(BluetoothLeDevice device, int rssi) {
                _this.notifyGetBLEDeviceRSSICallback(device,rssi);
            }

            @Override
            public void onFailure(BluetoothLeDevice device, BleException exception) {
                Log.e("rssiListener","获取信号强度失败:"+device+","+exception);
            }
        };
        notifyStateListener=new IBleCallback() {
            @Override
            public void onSuccess(byte[] data, BluetoothGattChannel bluetoothGattChannel, BluetoothLeDevice bluetoothLeDevice) {
                Log.e("notifyStateListener","订阅成功："+bluetoothGattChannel);
            }

            @Override
            public void onFailure(BleException exception) {
                Log.e("notifyStateListener","订阅失败："+exception);
            }
        };
        if(!bleManager.getBluetoothAdapter().isEnabled()){
            bleManager.getBluetoothAdapter().enable();
        }
        Timer timer=new Timer();
        TimerTask task=new TimerTask() {
            @Override
            public void run() {
                Log.i("timer","timerTask");
            }
        };
        timer.schedule(task,0,5*1000);
    }

    /**
     * 更新服务特征缓存
     * @param deviceMirror
     */
    private void updateService(DeviceMirror deviceMirror){
        String deviceId=deviceMirror.getBluetoothLeDevice().getAddress();
        List<BluetoothGattService> services=deviceMirror.getGattServiceList();
        //更新服务
        serviceMap.put(deviceId,services);
        //更新特征
        for(BluetoothGattService service : services){
            List<BluetoothGattCharacteristic> chaList=service.getCharacteristics();
            characteristicMap.put(String.format("%s-%s",deviceId,service.getUuid().toString()),chaList);
        }
    }

    /**
     * 获取设备服务列表
     * @param deviceId
     * @return
     */
    private List<BluetoothGattService> getService(String deviceId){
        if(serviceMap.containsKey(deviceId)){
            return serviceMap.get(deviceId);
        }
        return null;
    }

    /**
     * 获取指定服务对象
     * @param deviceId
     * @param serviceId
     * @return
     */
    private BluetoothGattService getService(String deviceId,String serviceId){
        if(serviceMap.containsKey(deviceId)){
            List<BluetoothGattService> services=serviceMap.get(deviceId);
            for(BluetoothGattService service : services){
                if(service.getUuid().toString().equals(serviceId)){
                    return service;
                }
            }
        }
        return null;
    }

    /**
     * 获取特征列表
     * @param deviceId
     * @param serviceId
     * @return
     */
    private List<BluetoothGattCharacteristic> getCharacteristic(String deviceId,String serviceId){
        String key=String.format("%s-%s",deviceId,serviceId);
        if(characteristicMap.containsKey(key)){
            return characteristicMap.get(key);
        }
        return null;
    }

    /**
     * 获取指定特征
     * @param deviceId
     * @param serviceId
     * @param characteristicId
     * @return
     */
    private BluetoothGattCharacteristic getCharacteristic(String deviceId,String serviceId,String characteristicId){
        String key=String.format("%s-%s",deviceId,serviceId);
        if(characteristicMap.containsKey(key)){
            List<BluetoothGattCharacteristic> chaList=characteristicMap.get(key);
            for(BluetoothGattCharacteristic cha : chaList){
                if(cha.getUuid().toString().equals(characteristicId)){
                    return cha;
                }
            }
        }
        return null;
    }
    /**
     * 更新扫描到的设备
     * @param device
     */
    private void updateDevice(BluetoothLeDevice device){
        deviceMap.put(device.getAddress(),device);
        String localName;
        AdRecordStore store=device.getAdRecordStore();

        if (store.getLocalNameComplete()!=null) {
            localName = store.getLocalNameComplete();
        }else{
            localName = device.getName();
        }
        //广播服务列表
        List<AdRecord> servicelist=AdRecordUtil.parseScanRecordAsList(device.getScanRecord());
        JSONArray services=new JSONArray();
        if (servicelist!=null&&!servicelist.isEmpty()) {
            for(AdRecord ar :servicelist){
                if(ar.getType()==AdRecord.BLE_GAP_AD_TYPE_16BIT_SERVICE_UUID_COMPLETE){
                    byte[] arr=ar.getData();
                    services.add(HexUtil.encodeHexStr(new byte[]{arr[1],arr[0]},false));
                }
            }
        }
        //厂商数据
        AdRecord manufcData=store.getRecord(AdRecord.BLE_GAP_AD_TYPE_MANUFACTURER_SPECIFIC_DATA);

        String advertisData = "";
        if(manufcData!=null){
            advertisData=HexUtil.encodeHexStr(manufcData.getData(),false);
        }
        JSONObject data=new JSONObject();
        data.put("name",device.getName());
        data.put("localName",localName);
        data.put(Const.DEVICE_ID,device.getAddress());
        data.put("RSSI",device.getRssi());
        data.put("advertisData",advertisData);
        data.put("advertisServiceUUIDs",services);
        //缓存对象
        advCacheMap.put(device.getAddress(),data);
        //触发监听
        if(onBluetoothDeviceFoundCallback!=null){
            JSONObject cdata=new JSONObject();
            JSONArray devices=new JSONArray();
            devices.add(data);
            cdata.put(Const.STATUS,Const.STATUS_SUCCESS);
            cdata.put(Const.MESSAGE,"发现了一台设备");
            cdata.put(Const.DEVICES,devices.toJSONString());
            //广播数据
            this.callBack(onBluetoothDeviceFoundCallback,cdata,true);
        }
    }

    /**
     * 更新设备最新状态
     * @param device
     * @param status
     */
    private void updateDeviceStatus(BluetoothLeDevice device,boolean status){
        deviceMap.put(device.getAddress(),device);
        JSONObject data=new JSONObject();
        data.put(Const.STATUS,Const.STATUS_SUCCESS);
        data.put(Const.DEVICE_ID,device.getAddress());
        data.put("connected",status);
        data.put(Const.MESSAGE,"状态变化");
        this.callBack(onBLEConnectionStateChangeCallback,data,true);
        if(status==false){
            if(this.isReConnectDevice(device)){
                device.setAutoReconnect(true);
                bleManager.connect(device,connectListener);
            }
        }
    }

    /**
     * 获取设备对象
     * @param deviceId
     * @return
     */
    private BluetoothLeDevice getDevice(String deviceId){
        if(deviceMap.containsKey(deviceId)){
            return deviceMap.get(deviceId);
        }
        return null;
    }

    /**
     * 获取组装好的设备数据
     * @param deviceId
     * @return
     */
    private JSONObject getDeviceData(String deviceId){
        return advCacheMap.get(deviceId);
    }
    /**
     * 更新蓝牙适配器状态
     */
    private void updateAdapterStatus(){
        JSONObject data=this.getAdapterStatus();
        this.callBack(onBluetoothAdapterStateChangeCallback,data,true);
    }

    /**
     * 获取组装好的蓝牙适配器状态数据
     * @return
     */
    private JSONObject getAdapterStatus(){

        JSONObject data=new JSONObject();
        BluetoothAdapter adapter=bleManager.getBluetoothAdapter();
        switch (adapter.getState()){
            case BluetoothAdapter.STATE_ON:
                data.put(Const.STATUS,Const.STATUS_SUCCESS);
                data.put("available",adapter.isEnabled());
                data.put("discovering",scanListener.isScanning());
                data.put(Const.MESSAGE,"适配器状态变化-已开启可以正常使用");
                break;
            case BluetoothAdapter.STATE_OFF:
                data.put(Const.STATUS,Const.STATUS_SUCCESS);
                data.put("available",adapter.isEnabled());
                data.put("discovering",adapter.isDiscovering());
                data.put(Const.MESSAGE,"适配器状态变化-蓝牙开关关闭");
                break;
            default:
                data.put(Const.STATUS,Const.STATUS_SUCCESS);
                data.put("available",adapter.isEnabled());
                data.put("discovering",adapter.isDiscovering());
                data.put(Const.MESSAGE,"适配器状态变化-没有授予蓝牙权限");
                break;
        }
        return data;
    }
    /**
     * 统一回调
     * @param callback
     * @param data
     * @param repeat
     */
    private void callBack(UniJSCallback callback,JSONObject data,Boolean repeat){
        if(callback!=null){
            if(repeat){
                callback.invokeAndKeepAlive(data);
            }else{
                callback.invoke(data);
            }
        }
    }

    /**
     * 统一回调
     * @param callback
     * @param status
     * @param message
     * @param repeat
     */
    private void callBack(UniJSCallback callback,String status,String message,Boolean repeat){
        JSONObject cdata=new JSONObject();
        cdata.put(Const.STATUS,status);
        cdata.put(Const.MESSAGE,message);
        this.callBack(callback,cdata,repeat);
    }

    /**
     * 检查插件是否有初始化
     * @param callback
     * @return
     */
    private boolean isAvailable(UniJSCallback callback){
        if(bleManager!=null){
            if(bleManager.getBluetoothAdapter().isEnabled()){
                return true;
            }else{
                this.callBack(callback,Const.STATUS_UN_INIT,"蓝牙适配器未开启",false);
                return false;
            }
        }else{
            JSONObject data=new JSONObject();
            data.put(Const.STATUS,Const.STATUS_UN_INIT);
            data.put(Const.MESSAGE,"蓝牙未初始化，请调用openBluetoothAdapter进行初始化操作");
            this.callBack(callback,data,false);
            return false;
        }
    }

    /**
     * 判断是否是断线重连设备
     * @param device
     * @return
     */
    private boolean isReConnectDevice(BluetoothLeDevice device){
        String deviceId=device.getAddress();
        if(reConnectDeviceMap.containsKey(deviceId)){
            return true;
        }
        return false;
    }

    /**
     * 添加断线重连设备
     * @param device
     */
    private void addReConnectDevice(BluetoothLeDevice device){
        device.setAutoReconnect(true);
        String deviceId=device.getAddress();
        if(!reConnectDeviceMap.containsKey(deviceId)){
            reConnectDeviceMap.put(deviceId,device);
        }
    }

    /**
     * 移除断线重连设备
     * @param device
     */
    private void removeReConnectDevice(BluetoothLeDevice device){
        device.setAutoReconnect(false);
        String deviceId=device.getAddress();
        if(reConnectDeviceMap.containsKey(deviceId)){
            reConnectDeviceMap.remove(deviceId);
        }
    }

    /**
     * 检查授权
     */
    private void checkPermission(){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Android M Permission check
            if (this.mUniSDKInstance.getContext().checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                ((Activity)this.mUniSDKInstance.getContext()).requestPermissions(new String[]{Manifest.permission.ACCESS_COARSE_LOCATION}, PERMISSION_REQUEST_COARSE_LOCATION);
            }
        }
    }
}
