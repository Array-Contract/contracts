pragma solidity >=0.5.0 <0.7.0;


import "../interface/IERC20.sol";
import "../library/SafeERC20.sol";
import "./Ownable.sol";
import "./Proxyable.sol";


/**
 * 合约代理机制(前)
 */
contract Proxy is Ownable {
    using SafeERC20 for IERC20;

    Proxyable private _proxyable;   // 后端被代理的合约地址
    bool private _delegate;         // 是否启用委托代理模式

    constructor() public {}

    // 查询被代理合约
    function proxyable() public view returns (Proxyable) {
        return _proxyable;
    }

    // 设置被代理的合约
    function setProxyable(Proxyable newProxyable) public onlyOwner {
        emit ProxyableTransferred(_proxyable, newProxyable);
        _proxyable = newProxyable;
    }

    // 查询委托模式
    function delegate() public view returns (bool) {
        return _delegate;
    }

    // 设置委托模式
    function setDelegate(bool newDelegate) public onlyOwner {
        _delegate = newDelegate;
    }

    // 由被代理合约调用，在Proxy中统一触发事件
    function note(bytes calldata cdata, uint256 topics, bytes32 topic1, bytes32 topic2, bytes32 topic3, bytes32 topic4) external onlyProxyable {
        uint256 length = cdata.length;
        bytes memory mdata = cdata;

        assembly {
            switch topics
            case 0 {
                log0(add(mdata, 32), length)
            }
            case 1 {
                log1(add(mdata, 32), length, topic1)
            }
            case 2 {
                log2(add(mdata, 32), length, topic1, topic2)
            }
            case 3 {
                log3(add(mdata, 32), length, topic1, topic2, topic3)
            }
            case 4 {
                log4(add(mdata, 32), length, topic1, topic2, topic3, topic4)
            }
        }
    }

    // 解锁授权
    function approve(IERC20 token, address spender, uint256 amount) public onlyAuthorized {
        token.safeApprove(spender, amount);
    }

    // 解锁转账
    function transfer(IERC20 token, address recipient, uint256 amount) public onlyAuthorized {
        token.safeTransfer(recipient, amount);
    }

    // 解锁代理转账
    function transferFrom(IERC20 token, address sender, address recipient, uint256 amount) public onlyAuthorized {
        token.safeTransferFrom(sender, recipient, amount);
    }

    // receive ether function
    function() external payable {
        if (_delegate) {
            assembly {
                let free_ptr := mload(0x40)
                calldatacopy(free_ptr, 0, calldatasize)

                let result := delegatecall(gas, sload(_proxyable_slot), free_ptr, calldatasize, 0, 0)
                returndatacopy(free_ptr, 0, returndatasize)

                if iszero(result) {revert(free_ptr, returndatasize)}
                return (free_ptr, returndatasize)
            }
        } else {
            // 主动设置调用者为msg.sender
            _proxyable.setCaller(msg.sender);

            assembly {
                let free_ptr := mload(0x40)
                calldatacopy(free_ptr, 0, calldatasize)

                let result := call(gas, sload(_proxyable_slot), callvalue, free_ptr, calldatasize, 0, 0)
                returndatacopy(free_ptr, 0, returndatasize)

                if iszero(result) {revert(free_ptr, returndatasize)}
                return (free_ptr, returndatasize)
            }
        }
    }


    modifier onlyProxyable() {
        require(msg.sender == address(_proxyable), "Proxy: caller is not the proxyable");
        _;
    }

    modifier onlyAuthorized() {
        require(msg.sender == address(_proxyable) || isOwner(msg.sender), "Proxy: caller is not the authorized");
        _;
    }


    event ProxyableTransferred(Proxyable indexed previousProxyable, Proxyable indexed newProxyable);
}
