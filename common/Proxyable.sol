pragma solidity >=0.5.0 <0.7.0;


import "./Proxy.sol";
import "./Ownable.sol";


/**
 * 合约代理机制(后)
 */
contract Proxyable is Ownable {
    Proxy private _proxy;       // 一级代理
    Proxy private _delegate;    // 二级代理
    address public caller;      // 原始调用者

    constructor() public {}

    // 查询一级代理
    function proxy() public view returns (Proxy) {
        return _proxy;
    }

    // 设置一级代理
    function setProxy(Proxy newProxy) public onlyOwner {
        emit ProxyTransferred(_proxy, newProxy);
        _proxy = newProxy;
    }

    // 查询二级代理
    function delegate() public view returns (Proxy) {
        return _delegate;
    }

    // 设置二级代理
    function setDelegate(Proxy newDelegate) public onlyOwner {
        _delegate = newDelegate;
    }

    // 设置原始调用者
    function setCaller(address newCaller) public onlyProxy {
        caller = newCaller;
    }


    modifier onlyProxy() {
        require(Proxy(msg.sender) == _proxy || Proxy(msg.sender) == _delegate, "Proxyable: caller is not the proxy");
        _;
    }

    modifier optionalProxy() {
        if (Proxy(msg.sender) != _proxy && Proxy(msg.sender) != _delegate && caller != msg.sender) {
            caller = msg.sender;
        }
        _;
    }

    modifier optionalProxyAndOnlyOwner() {
        if (Proxy(msg.sender) != _proxy && Proxy(msg.sender) != _delegate && caller != msg.sender) {
            caller = msg.sender;
        }
        require(isOwner(caller), "Proxyable: caller is not the owner");
        _;
    }


    event ProxyTransferred(Proxy indexed previousProxy, Proxy indexed newProxy);
}
