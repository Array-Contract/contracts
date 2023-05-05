pragma solidity >=0.5.0 <0.7.0;


/**
 * 具备截止时间合约
 */
contract Deadline {
    uint256 private _deadline;                  // 截止时间

    constructor(uint256 period) public {
        _deadline = now + period;
    }

    function deadline() public view returns (uint256) {
        return _deadline;
    }

    function isBeforeDeadline() public view returns (bool) {
        return now < _deadline;
    }


    modifier beforeDeadline() {
        require(isBeforeDeadline(), "Deadline: can only perform this action before deadline");
        _;
    }

    modifier afterDeadline() {
        require(!isBeforeDeadline(), "Deadline: can only perform this action after deadline");
        _;
    }
}
