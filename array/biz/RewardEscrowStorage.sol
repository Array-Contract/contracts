pragma solidity >=0.5.0 <0.7.0;


import "../../common/Storage.sol";


/**
 * 奖励托管数据访问控制机制
 * 授权的合约(onlyWhitelisted)，可以修改数据
 */
contract RewardEscrowStorage is Storage {
    mapping(address => Escrow[]) private _vestingSchedules;         // 用户目前的行权计划
    mapping(address => uint256) private _totalDepositedBalance;     // 用户总共托管的资金
    mapping(address => uint256) private _totalWithdrawnBalance;     // 用户总共行权的资金
    uint256 private _totalBalance;                                  // 合约总共托管的资金

    struct Escrow {
        uint256 timestamp;                                          // 行权时间
        uint256 amount;                                             // 托管金额
    }

    constructor() public {}

    /**
     * @notice 查询用户行权计划数量(含已行权)
     * @param account 用户
     * @return 行权计划数量
     */
    function getVestingLength(address account) public view returns (uint256) {
        return _vestingSchedules[account].length;
    }

    /**
     * @notice 查询用户index处的行权数据
     * @param account 用户
     * @param index 索引
     * @return 行权时间,托管金额
     */
    function getVestingEntry(address account, uint256 index) public view returns (uint256, uint256) {
        Escrow memory escrow = _vestingSchedules[account][index];
        return (escrow.timestamp, escrow.amount);
    }

    /**
     * @notice 查询用户全部的行权数据
     * @param account 用户
     * @return 行权数据列表
     */
    function getVestingEntries(address account) public view returns (uint256[1460] memory) {
        uint256[1460] memory entries;

        uint256 length = getVestingLength(account);
        for (uint256 index = 0; index < length && index < 730; index++) {
            (uint256 timestamp, uint256 amount) = getVestingEntry(account, index);
            entries[index * 2] = timestamp;
            entries[index * 2 + 1] = amount;
        }

        return entries;
    }

    /**
     * @notice 查询用户index处的行权时间
     * @param account 用户
     * @param index 索引
     * @return 行权时间
     */
    function getVestingTime(address account, uint256 index) public view returns (uint256) {
        (uint256 timestamp,) = getVestingEntry(account, index);
        return timestamp;
    }

    /**
     * @notice 查询用户index处的行权金额
     * @param account 用户
     * @param index 索引
     * @return 行权金额
     */
    function getVestingAmount(address account, uint256 index) public view returns (uint256) {
        (, uint256 amount) = getVestingEntry(account, index);
        return amount;
    }

    /**
     * @notice 查询用户待行权index
     * @param account 用户
     * @return 待行权索引
     */
    function getNextVestingIndex(address account) public view returns (uint256) {
        uint256 length = getVestingLength(account);

        for (uint256 index = 0; index < length; index++) {
            if (getVestingTime(account, index) != 0) {
                return index;
            }
        }

        return length;
    }

    /**
     * @notice 查询用户待行权的行权数据
     * @param account 用户
     * @return 行权时间,托管金额
     */
    function getNextVestingEntry(address account) public view returns (uint256, uint256) {
        uint256 index = getNextVestingIndex(account);

        if (index == getVestingLength(account)) {
            return (uint256(0), uint256(0));
        }

        return getVestingEntry(account, index);
    }

    /**
     * @notice 查询用户待行权的行权时间
     * @param account 用户
     * @return 行权时间
     */
    function getNextVestingTime(address account) public view returns (uint256) {
        (uint256 timestamp,) = getNextVestingEntry(account);
        return timestamp;
    }

    /**
     * @notice 查询用户待行权的行权金额
     * @param account 用户
     * @return 托管金额
     */
    function getNextVestingAmount(address account) public view returns (uint256) {
        (, uint256 amount) = getNextVestingEntry(account);
        return amount;
    }

    /**
     * @notice 查询用户总共托管的资金
     * @param account 用户
     * @return 总共托管的资金
     */
    function deposited(address account) public view returns (uint256) {
        return _totalDepositedBalance[account];
    }

    /**
     * @notice 查询用户总共行权的资金
     * @param account 用户
     * @return 总共行权的资金
     */
    function withdrawn(address account) public view returns (uint256) {
        return _totalWithdrawnBalance[account];
    }

    /**
     * @notice 查询合约总共托管的资金
     * @return 合约总共托管的资金
     */
    function totalBalance() public view returns (uint256) {
        return _totalBalance;
    }


    /**
     * @notice 设置合约总共托管的资金
     * @param newTotalBalance 总共托管的资金
     */
    function setTotalBalance(uint256 newTotalBalance) public onlyWhitelisted {
        _totalBalance = newTotalBalance;
    }

    /**
     * @notice 添加一笔用户行权计划
     * @param account 用户
     * @param timestamp 行权时间
     * @param amount 行权金额
     */
    function addVestingSchedule(address account, uint256 timestamp, uint256 amount) public onlyWhitelisted {
        Escrow memory escrow = Escrow(timestamp, amount);
        _vestingSchedules[account].push(escrow);
    }

    /**
     * @notice 清空一笔用户行权计划
     * @param account 用户
     * @param index 索引
     */
    function delVestingSchedule(address account, uint256 index) public onlyWhitelisted {
        Escrow memory escrow = Escrow(uint256(0), uint256(0));
        _vestingSchedules[account][index] = escrow;
    }

    /**
     * @notice 设置用户总共托管的资金
     * @param account 用户
     * @param newTotalDepositedBalance 总共托管的资金
     */
    function setTotalDepositedBalance(address account, uint256 newTotalDepositedBalance) public onlyWhitelisted {
        _totalDepositedBalance[account] = newTotalDepositedBalance;
    }

    /**
     * @notice 设置用户总共行权的资金
     * @param account 用户
     * @param newTotalWithdrawnBalance 总共行权的资金
     */
    function setTotalWithdrawnBalance(address account, uint256 newTotalWithdrawnBalance) public onlyWhitelisted {
        _totalWithdrawnBalance[account] = newTotalWithdrawnBalance;
    }
}
