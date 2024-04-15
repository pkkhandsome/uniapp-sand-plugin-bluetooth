# uniapp-sand-plugin-bluetooth
uniapp 低功耗蓝牙API原生插件<br />

本项目Fork自 https://gitee.com/wangqianjiao/sand-plugin-bluetooth<br />

由于此项目作者太久没更新了 不适用于现在MTU比较大的情况 (作者只是在发送数据时限制了数据大小)。<br />
而且API格式也与uniapp的方式有些差异 所以有需要的人可自行引入 ble.js <br />
注意 IOS不支持MTU更改 需要在硬件端做修改 手机会自协商 <br />
安卓端默认mtu现改为247 建立连接createBLEConnection时可传入mtu参数 在连接设备且发现services后自动更改mtu<br />

<pre>
BLE.createBLEConnection({
    deviceId : deviceId,
    mtu : mtu,
    success(res) {

    }
});
</pre>

### API目录

#### openBluetoothAdapter(options)
初始化蓝牙模块

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|

示例代码

```javascript
BLE.openBluetoothAdapter({
    success(res){

    }
})
```

注意：

- 大部分操作类API（监听类API除外）都需要在openBluetoothAdapter之后进行调用，否则会失败，status返回2501-蓝牙未初始化或未开启
- 可通过 onBluetoothAdapterStateChange 监听手机蓝牙状态的改变

---
#### startBluetoothDevicesDiscovery(options)
开始搜寻附近的蓝牙外围设备。此操作比较耗费系统资源，请在搜索并连接到设备后调用 stopBluetoothDevicesDiscovery 方法停止搜索。

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|

示例代码

```javascript
BLE.startBluetoothDevicesDiscovery({
    success(res)=>{

    }
})
```

注意：开启后获取扫描到的设备需要使用 onBluetoothDeviceFound 进行异步获取，建议先进行监听再扫描

---
#### onBluetoothDeviceFound(callback)
监听寻找到新设备的事件

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|
|devices|Array|设备信息JSON格式数组|

devices的结构

| 属性 | 类型 | 说明 |
| --- | --- | --- |
|name|	string|	蓝牙设备名称，某些设备可能没有|
|deviceId|	string|	用于区分设备的 id|
|RSSI|	number	|当前蓝牙设备的信号强度|
|advertisData|	string	|当前蓝牙设备的广播数据段中的 ManufacturerData 数据段(十六进制字符串，每2个字符对应一个字节)|
|advertisServiceUUIDs|	Array<String>|	当前蓝牙设备的广播数据段中的 ServiceUUIDs 数据段|
|localName|	string|	当前蓝牙设备的广播数据段中的 LocalName 数据段|

示例代码

```javascript
BLE.onBluetoothDeviceFound(function(res){
    let devices = res.devices;
    console.log(res.devices);
})
```
注意：

- 受限于uni-app原生插件对返回类型的要求，第二层数据只能采用String类型，需要使用JSON.parse方式进行对象解析
- 监听在插件中只会保存一份，即最后一次调用 onBluetoothDeviceFound 的callback会触发回调事件

---
#### stopBluetoothDevicesDiscovery(options)
停止搜寻附近的蓝牙外围设备。若已经找到需要的蓝牙设备并不需要继续搜索时，建议调用该接口停止蓝牙搜索。

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|

示例代码

```javascript
BLE.stopBluetoothDevicesDiscovery({
    success(res){

    }
})
```

---

#### onBluetoothAdapterStateChange(callback)
监听蓝牙适配器状态变化事件

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| status | String | 接口调用状态 |
| message | String |状态说明|
|available|boolean|蓝牙是否可用|

示例代码

```javascript
BLE.onBluetoothAdapterStateChange(function(res){

})
```

---
#### getBluetoothDevices(options)
获取在蓝牙模块生效期间所有已发现的蓝牙设备。包括已经和本机处于连接状态的设备。

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| status | String | 接口调用状态 |
| message | String |状态说明|
|devices|Array|设备信息JSON格式数组|

devices的结构

| 属性 | 类型 | 说明 |
| --- | --- | --- |
|name|	string|	蓝牙设备名称，某些设备可能没有|
|deviceId|	string|	用于区分设备的 id|
|restore|boolean|是否是可以后台恢复的设备，true-可直接使用createBLEConnection进行恢复连接动作|
|RSSI|	number	|当前蓝牙设备的信号强度|
|advertisData|	string	|当前蓝牙设备的广播数据段中的 ManufacturerData 数据段(十六进制字符串，每2个字符对应一个字节)|
|advertisServiceUUIDs|	Array<String>|	当前蓝牙设备的广播数据段中的 ServiceUUIDs 数据段|
|localName|	string|	当前蓝牙设备的广播数据段中的 LocalName 数据段|

示例代码

```javascript
BLE.getBluetoothDevices({
    success(res)=>{
        //发现新设备
        let devices = res.devices;
        console.log(res.devices);
    }
})
```
---
#### getBluetoothAdapterState(options)
获取本机蓝牙适配器状态。

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|
|available|boolean|蓝牙是否可用|

示例代码

```javascript
BLE.getBluetoothAdapterState({
    success(res){

    }
})
```
---
#### closeBluetoothAdapter(options)
关闭蓝牙模块。调用该方法将断开所有已建立的连接并释放系统资源。建议在使用蓝牙流程后，与 openBluetoothAdapter 成对调用。

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|

示例代码

```javascript
BLE.closeBluetoothAdapter({
    success(res){

    }
})
```
---
#### writeBLECharacteristicValue(options)
向低功耗蓝牙设备特征值中写入二进制数据。注意：必须设备的特征值支持 write 才可以成功调用。

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|
|deviceId|	string	|	是	|蓝牙设备 id|
|serviceId|	string|		是	|蓝牙特征值对应服务的 uuid|
|characteristicId|	string	|	是	|蓝牙特征值的 uuid|
|value	|string	|	是|	蓝牙设备特征值二进制字节数组对应转换的十六进制字符串值|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|

示例代码

```javascript
BLE.writeBLECharacteristicValue({
    deviceId:'DDCC-EE-AA-BB-CC',
    serviceId:'0000-1902-C503',
    characteristicId:'0000-1902-C503-0001',
    value:'0010',
    success(res){

    }
})
```
---
#### readBLECharacteristicValue(options)
读取低功耗蓝牙设备的特征值的二进制数据值。注意：必须设备的特征值支持 read 才可以成功调用。

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|
|deviceId|	string	|	是	|蓝牙设备 id|
|serviceId|	string|		是	|蓝牙特征值对应服务的 uuid|
|characteristicId|	string	|	是	|蓝牙特征值的 uuid|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|

示例代码

```javascript
// 必须在这里的回调才能获取到值
BLE.onBLECharacteristicValueChange(
    function(res){
        console.log(res.deviceId);
        console.log(res.serviceId);
        console.log(res.characteristicId);
        console.log(res.value);
    }
);

BLE.readBLECharacteristicValue({
    deviceId:'DDCC-EE-AA-BB-CC',
    serviceId:'0000-1902-C503',
    characteristicId:'0000-1902-C503-0001',
    success(res){

    }
});
```
注意：

- 接口读取到的信息需要在 onBLECharacteristicValueChange 方法注册的回调中获取。

---
#### onBLEConnectionStateChange(callback)
监听低功耗蓝牙连接状态的改变事件。包括开发者主动连接或断开连接，设备丢失，连接异常断开等等

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|
|deviceId|	string|	蓝牙设备ID|
|connected	|boolean|	是否处于已连接状态|

示例代码

```javascript
ble.onBLEConnectionStateChange(function(res){
    console.log(res.deviceId,'连接状态变化',res.connected);
})
```
---
#### onBLECharacteristicValueChange(callback)
监听低功耗蓝牙设备的特征值变化事件。必须先启用 notifyBLECharacteristicValueChange 接口才能接收到设备推送的 notification。

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|
|deviceId|	string	|蓝牙设备 id|
|serviceId|	string|蓝牙特征值对应服务的 uuid|
|characteristicId	|	String	|蓝牙特征值的 uuid|
|value|String|蓝牙设备特征值二进制字节数组对应转换的十六进制字符串值|

示例代码

```javascript
ble.onBLECharacteristicValueChange(function(res){
    console.log(res.deviceId);
    console.log(res.serviceId);
    console.log(res.characteristicId);
    console.log(res.value);
});
```
---
#### notifyBLECharacteristicValueChange(options)
启用低功耗蓝牙设备特征值变化时的 notify 功能，订阅特征值。注意：必须设备的特征值支持 notify 或者 indicate 才可以成功调用。

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|
|deviceId|	string	|	是	|蓝牙设备 id|
|serviceId|	string|		是	|蓝牙特征值对应服务的 uuid|
|characteristicId|	string	|	是	|蓝牙特征值的 uuid|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|

示例代码

```javascript
// 必须在这里的回调才能获取到值
BLE.onBLECharacteristicValueChange(function(res){
    console.log(res.deviceId);
    console.log(res.serviceId);
    console.log(res.characteristicId);
    console.log(res.value);
});

BLE.notifyBLECharacteristicValueChange({
    deviceId:'DDCC-EE-AA-BB-CC',
    serviceId:'0000-1902-C503',
    characteristicId:'0000-1902-C503-0001',
    success(res){
        //订阅API调用成功,请在onBLECharacteristicValueChange获取特征值数据
    }
});
```
---
#### cancelNotifyBLECharacteristicValueChange(options)
取消特征值订阅

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|
|deviceId|	string	|	是	|蓝牙设备 id|
|serviceId|	string|		是	|蓝牙特征值对应服务的 uuid|
|characteristicId|	string	|	是	|蓝牙特征值的 uuid|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|

示例代码

```javascript
ble.cancelNotifyBLECharacteristicValueChange({
    deviceId:'DDCC-EE-AA-BB-CC',
    serviceId:'0000-1902-C503',
    characteristicId:'0000-1902-C503-0001',
    success(res){
        //订阅API调用成功，已取消订阅
    }
});
```
---
#### getBLEDeviceServices(options)
获取蓝牙设备所有服务(service)。

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|
|deviceId|	string	|	是	|蓝牙设备 id|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|
|services|Array|JSON数组|

services内对象结构

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| uuid	| string| 	蓝牙设备服务的 uuid| 
| isPrimary	| boolean| 	该服务是否为主服务| 


示例代码

```javascript
BLE.getBLEDeviceServices({
    deviceId:'DDCC-EE-AA-BB-CC',
    success(res){
        let services = res.services;
        console.log(services);
    }
});
```
---
#### getBLEDeviceRSSI(options)
获取蓝牙设备的实时信号强度。

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|
|deviceId|	string	|	是	|蓝牙设备 id|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|
|deviceId|	string	|蓝牙设备 id|
|RSSI|number|信号强度值|



示例代码

```javascript
ble.getBLEDeviceRSSI({
    deviceId:'DDCC-EE-AA-BB-CC',
    success(res)=>{
        console.log(res.RSSI);
    }
});
```
---
#### getBLEDeviceCharacteristics(options)
获取蓝牙设备某个服务中所有特征值(characteristic)。

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|
|deviceId|	string	|	是	|蓝牙设备 id|
|serviceId|	string|		是	|蓝牙特征值对应服务的 uuid|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|
|characteristics|Array|JSON数组|

characteristics内对象结构

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| uuid	| string| 	蓝牙设备特征值的 uuid| 
| properties| 	Object| 	该特征值支持的操作类型| 

properties 的结构

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| read	| boolean| 	该特征值是否支持 read 操作| 
| write	| boolean	| 该特征值是否支持 write 操作| 
| notify| 	boolean| 	该特征值是否支持 notify 操作| 
| indicate| 	boolean	| 该特征值是否支持 indicate 操作| 


示例代码

```javascript
ble.getBLEDeviceCharacteristics({
    deviceId:'DDCC-EE-AA-BB-CC',
    serviceId:'0000-1902-C503'
    success(res){
        let characteristics = res.characteristics;
        console.log(characteristics);
    }
});
```

---
#### createBLEConnection(options)
连接低功耗蓝牙设备。

若APP在之前已有搜索过某个蓝牙设备，并成功建立连接，可直接传入之前搜索获取的 deviceId 直接尝试连接该设备，无需进行搜索操作。

注意: 此处回调成功不表示连接成功 需要监听 onBLEConnectionStateChange 
options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|
|deviceId|	string	|	是	|蓝牙设备 id|
|mtu|	integer	|	否	| mtu |

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|


示例代码

```javascript
BLE.onBLEConnectionStateChange(function(res){
    console.log(res.deviceId,'连接状态变化',res.connected);
});
BLE.createBLEConnection({
    deviceId:'DDCC-EE-AA-BB-CC',
    success(res){
        //接口调用成功，请在onBLEConnectionStateChange 监听状态变化
    }
});
```
---
#### closeBLEConnection(options)
断开与低功耗蓝牙设备的连接。

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|
|deviceId|	string	|	是	|蓝牙设备 id|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|


示例代码

```javascript
BLE.onBLEConnectionStateChange(function(res){
    console.log(res.deviceId,'连接状态变化',res.connected);
});
BLE.closeBLEConnection({
    deviceId:'DDCC-EE-AA-BB-CC',
    success(res){
        //接口调用成功，请在onBLEConnectionStateChange 监听状态变化
    }
});
```
---
#### addAutoReconnect(options)
将设备加入断线重连队列中，设备断开后将自动进行重连操作

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|
|deviceId|	string	|	是	|蓝牙设备 id|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|


示例代码

```javascript
BLE.addAutoReconnect({
    deviceId:'DDCC-EE-AA-BB-CC'
    success(res){
        //接口调用成功，已成功加入断线重连队列
    }
});
```
---
#### removeAutoReconnect(options)
将设备从断线重连队列中移除，设备断开后不会自动重连，需要手动调用createBLEConnection重新连接

options 参数说明

| 属性 | 类型 |是否必填| 说明 |
| --- | --- | --- |---|
|deviceId|	string	|	是	|蓝牙设备 id|

callback 回调函数参数对象说明

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| code | String | 接口调用状态 |
| message | String |状态说明|


示例代码

```javascript
BLE.removeAutoReconnect({
    deviceId:'DDCC-EE-AA-BB-CC',
    success(res)=>{
        //接口调用成功，已成功从断线重连队列移除
    }
});
```

### 状态码status说明

| status | 说明 |
| --- |--- |
|2500|操作成功|
|2501|蓝牙不可用|
|2502|设备未发现|
|2503|服务或特征等未找到|
|2504|不支持的操作|
|2505|未知系统错误|

