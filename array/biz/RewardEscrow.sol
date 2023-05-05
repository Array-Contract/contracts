pragma solidity >=0.5.0 <0.7.0;


import "../../library/SafeMath.sol";
import "../common/MixinResolver.sol";
import "./RewardEscrowStorage.sol";
import "../../access/WhitelistedRole.sol";


/**
 * 奖励托管逻辑
 * 1) 授权合约(onlyAuthorized)，通过deposit()锁定用户奖励；
 * 2) 行权计划到期后，用户通过withdraw()赎回奖励。
 */
contract RewardEscrow is MixinResolver, WhitelistedRole {
    using SafeMath for uint256;

    RewardEscrowStorage private _storage;
    uint256 private _period = 10 days;
    uint256 private maximum = 365 * 2;//奖励记录最大的长度

    constructor() public {}

    function database() public view returns (RewardEscrowStorage) {
        return _storage;
    }

    /**
     * @notice 授权用户设置存储DB
     * @param newStorage 存储DB
     */
    function setStorage(RewardEscrowStorage newStorage) public onlyOwner {
        emit StorageTransferred(_storage, newStorage);
        _storage = newStorage;
    }

    function period() public view returns (uint256) {
        return _period;
    }

    /**
     * @notice 授权用户设置托管时间
     * @param newPeriod 托管时间
     */
    function setPeriod(uint256 newPeriod) public onlyOwner {
        emit PeriodUpdated(_period, newPeriod);
        _period = newPeriod;
    }


    /**
     * @notice 查询用户行权计划数量(含已行权)
     * @param account 用户
     * @return 行权计划数量
     */
    function getVestingLength(address account) public view returns (uint256) {
        return _storage.getVestingLength(account);
    }

    /**
     * @notice 查询用户全部的行权数据
     * @param account 用户
     * @return 行权数据列表
     */
    function getVestingEntries(address account) public view returns (uint256[1460] memory) {//520 to 1460
        return _storage.getVestingEntries(account);
    }

    /**
     * @notice 查询用户index处的行权时间
     * @param account 用户
     * @param index 索引
     * @return 行权时间
     */
    function getVestingTime(address account, uint256 index) public view returns (uint256) {
        return _storage.getVestingTime(account, index);
    }

    /**
     * @notice 查询用户index处的行权金额
     * @param account 用户
     * @param index 索引
     * @return 行权金额
     */
    function getVestingAmount(address account, uint256 index) public view returns (uint256) {
        return _storage.getVestingAmount(account, index);
    }

    /**
     * @notice 查询用户待行权的行权时间
     * @param account 用户
     * @return 行权时间
     */
    function getNextVestingTime(address account) public view returns (uint256) {
        return _storage.getNextVestingTime(account);
    }

    /**
     * @notice 查询用户待行权的行权金额
     * @param account 用户
     * @return 托管金额
     */
    function getNextVestingAmount(address account) public view returns (uint256) {
        return _storage.getNextVestingAmount(account);
    }

    /**
     * @notice 查询用户总共托管的资金
     * @param account 用户
     * @return 总共托管的资金
     */
    function deposited(address account) public view returns (uint256) {
        return _storage.deposited(account);
    }

    /**
     * @notice 查询用户总共行权的资金
     * @param account 用户
     * @return 总共行权的资金
     */
    function withdrawn(address account) public view returns (uint256) {
        return _storage.withdrawn(account);
    }


    /**
     * @notice 锁定用户奖励
     * @param account 锁定用户
     * @param amount 锁定金额
     */
    function deposit(address account, uint256 amount) public onlyWhitelisted {
        require(account != address(0), "RewardEscrow: account is the zero address");
        require(amount != 0, "RewardEscrow: amount can not be zero");

        uint256 totalBalance = _storage.totalBalance().add(amount);
        require(totalBalance <= foundry().balanceOf(address(this)), "RewardEscrow: vesting amount exceeds balance");
        _storage.setTotalBalance(totalBalance);

        uint256 length = _storage.getVestingLength(account);
        require(length < maximum, "RewardEscrow: vesting length exceeds maximum");

        uint256 timestamp = now + _period;
        _storage.setTotalDepositedBalance(account, _storage.deposited(account).add(amount));
        if (length > 0) {
            require(_storage.getVestingTime(account, length - 1) < timestamp, "RewardEscrow: vesting timestamp should be asc");
        }
        _storage.addVestingSchedule(account, timestamp, amount);

        emit Deposited(account, now, amount);
    }

    /**
     * @notice 用户赎回奖励（到质押）
     */
    function withdraw() public {
        uint256 length = _storage.getVestingLength(msg.sender);
        uint256 total;

        for (uint256 index = 0; index < length; index++) {
            uint256 timestamp = _storage.getVestingTime(msg.sender, index);
            if (timestamp > now) {
                break;
            }

            uint256 amount = _storage.getVestingAmount(msg.sender, index);
            if (amount == 0) {
                continue;
            }

            _storage.delVestingSchedule(msg.sender, index);
            total = total.add(amount);
        }

        if (total != 0) {
            _storage.setTotalBalance(_storage.totalBalance().sub(total, "RewardEscrow: withdraw amount exceeds total balance"));
            _storage.setTotalDepositedBalance(msg.sender, _storage.deposited(msg.sender).sub(total));
            _storage.setTotalWithdrawnBalance(msg.sender, _storage.withdrawn(msg.sender).add(total));

            foundry().transfer(msg.sender, total);

            emit Withdrawn(msg.sender, now, total);
        }
    }

    /**
     * @notice 赎回并提出
     */
    function withdraw(address account) public onlyWhitelisted returns (uint256) {
        uint256 length = _storage.getVestingLength(account);
        uint256 total;

        for (uint256 index = 0; index < length; index++) {
            uint256 timestamp = _storage.getVestingTime(account, index);
            if (timestamp > now) {
                break;
            }

            uint256 amount = _storage.getVestingAmount(account, index);
            if (amount == 0) {
                continue;
            }

            _storage.delVestingSchedule(account, index);
            total = total.add(amount);
        }

        if (total != 0) {
            _storage.setTotalBalance(_storage.totalBalance().sub(total, "RewardEscrow: withdraw amount exceeds total balance"));
            _storage.setTotalDepositedBalance(account, _storage.deposited(account).sub(total));
            _storage.setTotalWithdrawnBalance(account, _storage.withdrawn(account).add(total));

            foundry().transfer(account, total);

            emit Withdrawn(account, now, total);
        }
        return total;
    }

    /**
     * @notice 查询可赎回用户奖励
     */
    function withdrawAble(address account) public view returns (uint256) {
        uint256 length = _storage.getVestingLength(account);
        uint256 total;

        for (uint256 index = 0; index < length; index++) {
            uint256 timestamp = _storage.getVestingTime(account, index);
            if (timestamp > now) {
                break;
            }

            uint256 amount = _storage.getVestingAmount(account, index);
            if (amount == 0) {
                continue;
            }
            total = total.add(amount);
        }
        
        return total;
    }

    event StorageTransferred(RewardEscrowStorage indexed previousStorage, RewardEscrowStorage indexed newStorage);
    event PeriodUpdated(uint256 indexed previousPeriod, uint256 indexed newPeriod);
    event Deposited(address indexed account, uint256 indexed timestamp, uint256 indexed amount); // 行权用户，行权时间，托管金额
    event Withdrawn(address indexed account, uint256 indexed timestamp, uint256 indexed amount); // 赎回用户，赎回时间，赎回金额
}
