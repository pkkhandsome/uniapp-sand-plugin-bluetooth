package com.vise.baseble.callback;

import com.vise.baseble.exception.BleException;
import com.vise.baseble.model.BluetoothLeDevice;

/**
 * @Description: 获取信号值回调
 * @author: <a href="http://xiaoyaoyou1212.360doc.com">DAWI</a>
 * @date: 2017/10/19 15:19
 */
public interface IRssiCallback {
    void onSuccess(BluetoothLeDevice device, int rssi);

    void onFailure(BluetoothLeDevice device,BleException exception);
}
