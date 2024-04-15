const _oble = uni.requireNativePlugin('sand-plugin-bluetooth');

class BLE {

    //订阅蓝牙可用性变更  dicovering属性好像没用
    static onBluetoothAdapterStateChange(callback) {
        _oble.onBluetoothAdapterStateChange({},(res)=>{
            if(res.status=='2500'){
                callback && callback(res);
            }
        });
    }

    static onBluetoothDeviceFound(callback) {
        _oble.onBluetoothDeviceFound({},(res)=>{
            if(res.status=='2500'){
                if(res.devices) {
                    res.devices = JSON.parse(res.devices);
                }
                callback && callback(res);
            }
        });
    }

    static onBLEConnectionStateChange(callback) {
        _oble.onBLEConnectionStateChange({},(res)=>{
            if(res.status=='2500'){
                callback && callback(res);
            }
        });
    }

    static onBLECharacteristicValueChange(callback) {
        _oble.onBLECharacteristicValueChange({},(res)=>{
            if(res.status=='2500'){
                res.value = Utils.hex2ab(res.value);
                callback && callback(res);
            }
        });
    }

    static startBluetoothDevicesDiscovery(options) {
        _oble.startBluetoothDevicesDiscovery({},(res)=>{
            if(res.status=='2500') {
                if(options && options.success) {
                    options.success(res);
                }
            }
            if(options && options.complete) {
                options.complete();
            }
        });
    }

    static stopBluetoothDevicesDiscovery(options) {
        _oble.stopBluetoothDevicesDiscovery({},(res)=>{
            if(res.status=='2500') {
                if(options && options.success) {
                    options.success(res);
                }
            }
            if(options && options.complete) {
                options.complete();
            }
        });
    }

    static closeBLEConnection(options) {
        _oble.closeBLEConnection({
            deviceId : options.deviceId,
        },(res)=>{
            if(res.status=='2500') {
                if(options && options.success) {
                    options.success(res);
                }
            }
            if(options && options.complete) {
                options.complete();
            }
        });
    }

    static createBLEConnection(options) {
        _oble.createBLEConnection({
            deviceId : options.deviceId,
            mtu : options.mtu,
        },(res)=>{
            res.code = res.status;
            if(res.status=='2500') {
                if(options && options.success) {
                    options.success(res);
                }
            } else {
                if(options && options.fail) {
                    options.fail(res);
                }
            }
            if(options && options.complete) {
                options.complete();
            }
        });
    }

    static addAutoReconnect(options) {
        _oble.addAutoReconnect({
            deviceId : options.deviceId,
        },(res)=>{
            res.code = res.status;
            if(res.status=='2500') {
                if(options && options.success) {
                    options.success(res);
                }
            } else {
                if(options && options.fail) {
                    options.fail(res);
                }
            }
            if(options && options.complete) {
                options.complete();
            }
        });
    }

    static removeAutoReconnect(options) {
        _oble.removeAutoReconnect({
            deviceId : options.deviceId
        },(res)=>{
            res.code = res.status;
            if(res.status=='2500') {
                if(options && options.success) {
                    options.success(res);
                }
            } else {
                if(options && options.fail) {
                    options.fail(res);
                }
            }
            if(options && options.complete) {
                options.complete();
            }
        });
    }

    static getBLEDeviceServices(options) {
        _oble.getBLEDeviceServices({
            deviceId : options.deviceId
        },(res)=>{
            res.code = res.status;
            if(res.status=='2500') {
                res.services = JSON.parse(res.services);
                if(options && options.success) {
                    options.success(res);
                }
            } else {
                if(options && options.fail) {
                    options.fail(res);
                }
            }
            if(options && options.complete) {
                options.complete();
            }
        });
    }

    static getBLEDeviceCharacteristics(options) {
        _oble.getBLEDeviceCharacteristics({
            deviceId : options.deviceId,
            serviceId : options.serviceId
        },(res)=>{
            res.code = res.status;
            if(res.status=='2500') {
                res.characteristics = JSON.parse(res.characteristics);
                if(options && options.success) {
                    options.success(res);
                }
            } else {
                if(options && options.fail) {
                    options.fail(res);
                }
            }
            if(options && options.complete) {
                options.complete();
            }
        });
    }

    static getBLEDeviceRSSI(options) {
        _oble.getBLEDeviceRSSI({
            deviceId : options.deviceId
        },(res)=>{
            res.code = res.status;
            if(res.status=='2500') {
                if(options && options.success) {
                    options.success(res);
                }
            } else {
                if(options && options.fail) {
                    options.fail(res);
                }
            }
            if(options && options.complete) {
                options.complete();
            }
        });
    }

    static notifyBLECharacteristicValueChange(options) {
        _oble.notifyBLECharacteristicValueChange({
            deviceId : options.deviceId,
            serviceId : options.serviceId,
            characteristicId : options.characteristicId
        },(res)=>{
            res.code = res.status;
            if(res.status=='2500') {
                if(options && options.success) {
                    options.success(res);
                }
            } else {
                if(options && options.fail) {
                    options.fail(res);
                }
            }
            if(options && options.complete) {
                options.complete();
            }
        });
    }

    static cancelNotifyBLECharacteristicValueChange(options) {
        _oble.cancelNotifyBLECharacteristicValueChange({
            deviceId : options.deviceId,
            serviceId : options.serviceId,
            characteristicId : options.characteristicId
        },(res)=>{
            res.code = res.status;
            if(res.status=='2500') {
                if(options && options.success) {
                    options.success(res);
                }
            } else {
                if(options && options.fail) {
                    options.fail(res);
                }
            }
            if(options && options.complete) {
                options.complete();
            }
        });
    }

    static writeBLECharacteristicValue(options) {
        let myValue = Utils.ab2hex(options.value);
        _oble.writeBLECharacteristicValue({
            deviceId : options.deviceId,
            serviceId : options.serviceId,
            characteristicId : options.characteristicId,
            value : myValue
        },(res)=>{
            res.code = res.status;
            if(res.status=='2500') {
                if(options && options.success) {
                    options.success(res);
                }
            } else {
                if(options && options.fail) {
                    options.fail(res);
                }
            }
            if(options && options.complete) {
                options.complete();
            }
        });
    }

    static readBLECharacteristicValue(options) {
        _oble.readBLECharacteristicValue({
            deviceId : options.deviceId,
            serviceId : options.serviceId,
            characteristicId : options.characteristicId
        },(res)=>{
            res.code = res.status;
            if(res.status=='2500') {
                if(options && options.success) {
                    options.success(res);
                }
            } else {
                if(options && options.fail) {
                    options.fail(res);
                }
            }
            if(options && options.complete) {
                options.complete();
            }
        });
    }

    static getBluetoothDevices(options) {
        _oble.getBluetoothDevices({},(res)=>{
            res.code = res.status;
            if(res.status=='2500') {
                if(res.devices) {
                    res.devices = JSON.parse(res.devices);
                }
                if(options && options.success) {
                    options.success(res);
                }
            } else {
                if(options && options.fail) {
                    options.fail(res);
                }
            }
            if(options && options.complete) {
                options.complete();
            }
        });
    }

    static getBluetoothAdapterState(options) {
        _oble.getBluetoothAdapterState({},(res)=>{
            res.code = res.status;
            if(res.status=='2500') {
                if(options && options.success) {
                    options.success(res);
                }
            } else {
                if(options && options.fail) {
                    options.fail(res);
                }
            }
            if(options && options.complete) {
                options.complete();
            }
        });
    }

    static openBluetoothAdapter(options) {
        _oble.openBluetoothAdapter({},(res)=>{
            res.code = res.status;
            if(res.status=='2500') {
                if(options && options.success) {
                    options.success(res);
                }
            } else {
                if(options && options.fail) {
                    options.fail(res);
                }
            }
            if(options && options.complete) {
                options.complete();
            }
        });
    }

    static closeBluetoothAdapter(options) {
        _oble.closeBluetoothAdapter({},(res)=>{
            res.code = res.status;
            if(res.status=='2500') {
                if(options && options.success) {
                    options.success(res);
                }
            } else {
                if(options && options.fail) {
                    options.fail(res);
                }
            }
            if(options && options.complete) {
                options.complete();
            }
        });
    }
}

export default BLE;