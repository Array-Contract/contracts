pragma solidity >=0.5.0 <0.7.0;


/**
 * 地址工具包
 */
library Address {
    // 地址是否是合约
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;

        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }

        return (codehash != 0x0 && codehash != accountHash);
    }

    // 地址转换成payable
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    // 地址转换成bytes32
    function encode(address account) internal pure returns (bytes32 result) {
        bytes memory packed = abi.encode(account);

        assembly {
            result := mload(add(packed, 32))
        }
    }
}
