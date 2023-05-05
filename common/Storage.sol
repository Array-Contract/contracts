pragma solidity >=0.5.0 <0.7.0;


import "../access/WhitelistedRole.sol";


/**
 * 数据访问控制机制
 */
contract Storage is WhitelistedRole {
    constructor() public {}
}
