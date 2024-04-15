# uniapp-sand-plugin-bluetooth
uniapp 低功耗蓝牙API原生插件

本项目Fork自 https://gitee.com/wangqianjiao/sand-plugin-bluetooth

由于此项目作者太久没更新了 不适用于现在MTU比较大的情况 (作者只是在发送数据时限制了数据大小)。
所以小小修改了一下 给有需要的人。 

// IOS不支持MTU更改 需要在硬件端做修改 手机会自协商
// 安卓端建立连接时可传入mtu参数 在连接设备 发现services后自动更改mtu
BLE.createBLEConnection({
    deviceId : deviceId,
    mtu : mtu,
    success(res) {

    }
});