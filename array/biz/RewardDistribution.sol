pragma solidity >=0.5.0 <0.7.0;


import "../../library/SafeMath.sol";
import "../common/MixinResolver.sol";


/**
 * 奖励分发逻辑
 * 1) 领奖池主要保存系统流动性贡献者；
 * 2) 授权合约(onlyAuthorized)，通过distribute()分发奖励。
 */
contract RewardDistribution is MixinResolver {
    using SafeMath for uint256;

    Reward[] public rewards;                            // 领奖池

    struct Reward {
        address account;                                // 领奖地址
        uint256 amount;                                 // 领奖金额
    }

    constructor() public {}

    /**
     * @notice 查询优先领奖池长度
     * @return 优先领奖池长度
     */
    function getRewardsLength() public view returns (uint256) {
        return rewards.length;
    }

    /**
     * @notice 添加一条领奖记录
     * @param account 领奖地址
     * @param amount 领奖金额
     * @return 执行成功
     */
    function addRewardHook(address account, uint256 amount) public onlyOwner returns (bool) {
        require(account != address(0), "RewardDistribution: account is the zero address");
        require(amount != 0, "RewardDistribution: amount can not be zero");

        Reward memory reward = Reward(account, amount);
        rewards.push(reward);

        emit AddRewardHook(rewards.length - 1, account, amount);

        return true;
    }

    /**
     * @notice 修改一条领奖记录
     * @param index 领奖索引
     * @param account 领奖地址
     * @param amount 领奖金额
     * @return 执行成功
     */
    function revRewardHook(uint256 index, address account, uint256 amount) public onlyOwner returns (bool) {
        require(rewards.length != 0, "RewardDistribution: rewards length can not be zero");
        require(index < rewards.length, "RewardDistribution: index out of bounds");
        require(account != address(0), "RewardDistribution: account is the zero address");
        require(amount != 0, "RewardDistribution: amount can not be zero");

        rewards[index].account = account;
        rewards[index].amount = amount;

        emit RevRewardHook(index, account, amount);

        return true;
    }

    /**
     * @notice 删除一条领奖记录
     * @param index 领奖索引
     * @return 执行成功
     */
    function delRewardHook(uint256 index) public onlyOwner returns (bool) {
        require(rewards.length != 0, "RewardDistribution: rewards length can not be zero");
        require(index < rewards.length, "RewardDistribution: index out of bounds");

        Reward memory reward = rewards[index];
        for (uint256 i = index; i < rewards.length - 1; i++) {
            rewards[i] = rewards[i + 1];
        }
        rewards.length--;

        emit DelRewardHook(index, reward.account, reward.amount);

        return true;
    }

    /**
     * @notice 分发本期奖励
     * @param amount 奖励金额
     * @return 执行成功
     */
    function distribute(uint256 amount) public onlyAuthorized returns (bool) {
        require(amount > 0, "RewardDistribution: amount can not be zero");
        require(foundry().balanceOf(address(this)) >= amount, "RewardDistribution: distribute amount exceeds balance");

        uint256 remainder = amount;

        // 领奖池用户获取奖励
        for (uint256 index = 0; index < rewards.length; index++) {
            if (rewards[index].account != address(0) && rewards[index].amount != 0) {
                remainder = remainder.sub(rewards[index].amount);
                foundry().transfer(rewards[index].account, rewards[index].amount);
            }
        }

        // 托管所有用户的奖励到escrow
        foundry().transfer(address(reward()), remainder);

        // 费率池设置本期奖励金额
        // feePool().setReward(remainder);

        emit RewardDistributed(amount, address(reward()), remainder);

        return true;
    }

    /**
     * @notice 查询用户授权状态
     * @return 是否授权
     */
    function isAuthorized() public view returns (bool) {
        return msg.sender == address(foundry());
    }


    modifier onlyAuthorized() {
        require(isAuthorized(), "RewardDistribution: caller is not the authorized");
        _;
    }


    event AddRewardHook(uint256 indexed index, address indexed account, uint256 indexed amount);        // 索引，地址，金额
    event RevRewardHook(uint256 indexed index, address indexed account, uint256 indexed amount);        // 索引，地址，金额
    event DelRewardHook(uint256 indexed index, address indexed account, uint256 indexed amount);        // 索引，地址，金额
    event RewardDistributed(uint256 indexed amount, address indexed escrow, uint256 indexed remainder); // 总额，托管，金额
}
