pragma solidity >=0.5.0 <0.7.0;


import "../../library/SafeMath.sol";
import "../../common/Ownable.sol";
import "../../access/WhitelistedRole.sol";
import "./FoundryStorage.sol";
import "../common/MixinResolver.sol";
import "../interface/ICombo.sol";


contract FoundryExtend is WhitelistedRole, MixinResolver {
    using SafeMath for uint;

    FoundryStorage public foundryStorage;

    uint private UNIT = 10 ** 18;

    uint256 public lastMortgageRewardTimestamp = 0;
    uint256 public minimumRewardInterval = 20 hours;

    uint256 public rewardUpperBoundary = 500 * 10 ** 16;
    uint256 public rewardLowerBoundary = 400 * 10 ** 16;
    uint256 public rewardUpperDailyRate = 10 * 10 ** 14;
    uint256 public rewardLowerDailyRate = 5 * 10 ** 14;


    constructor()
    public
    {}

    function setRewardUpperBoundary(uint256 _rewardUpperBoundary) external onlyOwner {
        rewardUpperBoundary = _rewardUpperBoundary;
    }

    function setRewardLowerBoundary(uint256 _rewardLowerBoundary) external onlyOwner {
        rewardLowerBoundary = _rewardLowerBoundary;
    }

    function setRewardUpperDailyRate(uint256 _rewardUpperDailyRate) external onlyOwner {
        rewardUpperDailyRate = _rewardUpperDailyRate;
    }

    function setRewardLowerDailyRate(uint256 _rewardLowerDailyRate) external onlyOwner {
        rewardLowerDailyRate = _rewardLowerDailyRate;
    }

    function setFoundryStorage(FoundryStorage _foundryStorage) external onlyOwner {
        foundryStorage = _foundryStorage;
    }

    /**
    * 平台代抵押,并铸币
    */
    function executeMortgage(address account, address plat, uint256 amount) public onlyWhitelisted {
        //        foundryStorage.recordMortgagedAccount(account);
        mortgage().mortgage(account, plat, amount);
        uint256 usdrAmount = foundry().issueMaxCombos(account, plat);
        emit Mortgage(account, plat, amount, usdrAmount);
    }

    /**
    * 去中心化用户抵押，并铸币
    */
    function executeMortgage(uint256 amount) public returns (bool){
        foundryStorage.recordMortgagedAccount(msg.sender);
        mortgage().mortgage(msg.sender, msg.sender, amount);
        uint256 usdrAmount = foundry().issueMaxCombos(msg.sender, msg.sender);
        emit MortgageD(msg.sender, amount, usdrAmount);
    }

    /**
    * 去中心化用户全部抵押，并铸币
    */
    function executeMaxMortgage() public returns (bool){
        foundryStorage.recordMortgagedAccount(msg.sender);
        uint256 amount = araToken().balanceOf(msg.sender);
        mortgage().mortgage(msg.sender, msg.sender, amount);
        uint256 usdrAmount = foundry().issueMaxCombos(msg.sender, msg.sender);
        emit MortgageD(msg.sender, amount, usdrAmount);
    }

    /**
    *  平台代销毁，并赎回
    */
    function redemption(address account, address plat, uint256 amount) public onlyWhitelisted {
        uint usdr = foundry().burnCombos(account, plat, amount);
        uint256 araAmount;
        //实际已质押
        uint256 mortgagedAmount = mortgage().balanceOf(account);
        //当前债务
        uint256 debtBalance = foundry().debtBalanceOf(account);
        //价格
        uint256 price = effectiveValue("USDR",UNIT,"ARA");
        //铸币比例
        uint256 issueRate = foundryStorage.issuanceRatio();
        //当前债务对应的ARA
        uint256 lockedAmount = debtBalance.wmulRound(price).wdivRound(issueRate);
        if (mortgagedAmount <= lockedAmount)
        {
            araAmount = 0;
        } else {
            araAmount = mortgagedAmount - lockedAmount;
            require(mortgage().redemptionTo(account, plat, araAmount), "FoundryExtend: ara inner transfer failed");
        }

        emit Redemption(account, plat, usdr, araAmount);
    }

    /**
    *  去中心化用户销毁，并赎回
    */
    function redemption(uint256 amount) public {
        uint usdr = foundry().burnCombos(msg.sender, msg.sender, amount);
        uint256 araAmount;
        //实际已质押
        uint256 mortgagedAmount = mortgage().balanceOf(msg.sender);
        //当前债务
        uint256 debtBalance = foundry().debtBalanceOf(msg.sender);
        //价格
        uint256 price = effectiveValue("USDR",UNIT,"ARA");
        //铸币比例
        uint256 issueRate = foundryStorage.issuanceRatio();
        //当前债务对应的ARA
        uint256 lockedAmount = debtBalance.wmulRound(price).wmulRound(UNIT).wdivRound(issueRate);
        if (mortgagedAmount <= lockedAmount)
        {
            araAmount = 0;
        } else {
            araAmount = mortgagedAmount - lockedAmount;
            require(mortgage().redemptionTo(msg.sender, msg.sender, araAmount), "FoundryExtend: ara inner transfer failed");
        }

        emit Redemption(msg.sender, msg.sender, usdr, araAmount);
    }

    /**
    *  去中心化用, 全部赎回
    */
    function redemptionAll() public {
        uint256 usdrAmount = foundry().burnAllCombos(msg.sender, msg.sender);
        uint256 araAmount = mortgage().redemptionAll(msg.sender, msg.sender);
        emit RedemptionD(msg.sender, usdrAmount, araAmount);
    }

    /**
     * 将抵押的ARA划转到购买者
    */
    function flux(address seller, address buyer, uint256 amount) external onlyFoundry {
        require(seller != address(0), "FoundryExtend: seller address can not be zero");
        require(buyer != address(0), "FoundryExtend: buyer address can not be zero");
        mortgage().innerTransfer(seller, buyer, amount);
    }

    /** 划转 */
    function transferFrom(address from, address to, uint256 amount) external onlyFoundry returns (bool) {
        require(from != address(0), "FoundryExtend: from address can not be zero");
        require(to != address(0), "FoundryExtend: to address can not be zero");
        mortgage().innerTransferFrom(from, to, amount);
        return true;
    }

    /**
     * @notice A function that lets you easily convert an amount in a source currency to an amount in the destination currency
     * @param sourceCurrencyKey The currency the amount is specified in
     * @param sourceAmount The source amount, specified in UNIT base
     * @param destinationCurrencyKey The destination currency
     */
    function effectiveValue(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey)
    public
    view
    returns (uint)
    {
        if (sourceCurrencyKey == destinationCurrencyKey || sourceAmount == 0) {
            return sourceAmount;
        }
        return rates().ratio(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);
    }

    /**
    * 每日质押奖励发放时间间隔
    */
    function setMinimumRewardInterval(uint256 interval) public onlyOwner {
        minimumRewardInterval = interval;
    }

    /**
    * 每日质押奖励发放
    */
    function mortgageReward() public onlyWhitelisted {//改成白名单触发
        require(lastMortgageRewardTimestamp + minimumRewardInterval <= now, "Foundry: not reach the minimum inverval yet");
        address[] memory allMortgaged = foundryStorage.getAllMortgaged();
        uint256 payRewardAmount = _payRewardAmount(allMortgaged);
        if (payRewardAmount == 0) {
            emit MortgageReward(payRewardAmount, payRewardAmount);
            return;
        }
        mortgage().transferReward(payRewardAmount);
        uint256 payRewardAmountActual = _mortgageRewardIn(allMortgaged);
        lastMortgageRewardTimestamp = now;
        emit MortgageReward(payRewardAmount, payRewardAmountActual);
        // for test
    }

    /**
    * 每日质押奖励发放
    */
    function mortgageRewardIn(address[] memory accounts) public onlyWhitelisted {//改成白名单触发
        require(lastMortgageRewardTimestamp + minimumRewardInterval <= now, "Foundry: not reach the minimum inverval yet");
        uint256 payRewardAmount = _payRewardAmount(accounts);
        if (payRewardAmount == 0) {
            emit MortgageReward(payRewardAmount, payRewardAmount);
            return;
        }
        mortgage().transferReward(payRewardAmount);
        uint256 payRewardAmountActual = _mortgageRewardIn(accounts);
        emit MortgageReward(payRewardAmount, payRewardAmountActual);
        // for test
    }

    function _mortgageRewardIn(address[] memory accounts) internal returns (uint256) {//return for test, is going to be deleted
        uint256 totalRewardAmount = 0;
        uint priceRatio = effectiveValue("ARA", UNIT, "USDR");
        //unit * ara price/ usdr price
        for (uint index = 0; index < accounts.length; index ++) {
            uint256 araBalance = araBalanceOf(accounts[index]);
            uint256 dailyRate = rewardUpperDailyRate;
            uint256 rewardAmount = araBalance.wmulRound(dailyRate).wdivRound(UNIT);
            if (rewardAmount == 0) {
                continue;
            }
            reward().deposit(accounts[index], rewardAmount);
            totalRewardAmount.add(rewardAmount);
        }
        return totalRewardAmount;
    }

    function _payRewardAmount(address[] memory accounts) public view returns (uint256) {// public fot test
        uint256 totalRewardAmount = 0;
        uint priceRatio = effectiveValue("ARA", UNIT, "USDR");
        //unit * ara price/ usdr price
        for (uint index = 0; index < accounts.length; index ++) {
            uint256 araBalance = araBalanceOf(accounts[index]);
            uint256 dailyRate = rewardUpperDailyRate;
            uint256 rewardAmount = araBalance.wmulRound(dailyRate).wdivRound(UNIT);
            if (rewardAmount == 0) {
                continue;
            }
            totalRewardAmount = totalRewardAmount.add(rewardAmount);
        }
        return totalRewardAmount;
    }

    /**
    *  去中心化用户领取奖励
    */
    function withdraw() public returns (bool) {
        require(reward().withdrawAble(msg.sender) > 0, "Foundry: reward is zero");
        uint256 reward = reward().withdraw(msg.sender);
        return mortgage().redemptionReward(msg.sender, reward);
    }

    /**
    *  平台代领取质押奖励
    */
    function withdraw(address account, uint256 amount) public onlyWhitelisted {
        araMinter().mintMortgageReward(account, amount);
        emit WithdrawReward(account, amount);
    }

    function cRatio(address account) public view returns (uint256) {
        uint priceRatio = effectiveValue("ARA", UNIT, "USDR");
        uint256 araBalance = araBalanceOf(account);
        uint256 debtBalance = foundry().debtBalanceOf(account);
        require(debtBalance > 0, "Foundry: debtBalance is zero");
        uint256 cRatio = araBalance.wmulRound(priceRatio).wdivRound(debtBalance).wdivRound(UNIT);
        return cRatio;
    }

    /**
     * 获取用户当前可以转出的ARA数量
     */
    function transferableARA(address account)
    public
    view
    returns (uint)
    {
        uint balance = mortgage().balanceOf(account);

        uint256 priceRatio = uint256(effectiveValue("USDR", UNIT, "ARA"));
        //unit * ara price/ usdr price
        uint lockedARAValue = foundry().debtBalanceOf(account).wmulRound(priceRatio).wdivRound(foundryStorage.issuanceRatio());
        // If we exceed the balance, no ARA are transferable, otherwise the difference is.
        if (lockedARAValue >= balance) {
            return 0;
        } else {
            return balance.sub(lockedARAValue);
        }
    }

    /**
     * 获取用户当前用于铸币的ARA数量
     */
    function lockedARA(address account)
    public
    view
    returns (uint)
    {
        uint256 priceRatio = uint256(effectiveValue("USDR", UNIT, "ARA"));
        //unit * ara price/ usdr price
        uint lockedARAValue = foundry().debtBalanceOf(account).wmulRound(priceRatio).wdivRound(foundryStorage.issuanceRatio());
        return lockedARAValue;
    }

    /**
    *  获取用户总资产USDR
    */

    function getUserTotalCombos(address account) public view returns (uint256) {
        return usdr().balanceOf(account);
    }

    /**
    *  查询用户的ARA余额
    */
    function araBalanceOf(address account) public view returns (uint256) {
        return mortgage().balanceOf(account);
    }

    /**
    *  系统支付ARA奖励
    */
    function payReward(uint256 amount) public onlyFoundry {
        return mortgage().transferReward(amount);
    }

    modifier onlyFoundry() {
        require(msg.sender == address(foundry()), "FoundryExtend: Only foundry allowed");
        _;
    }

    event MortgageReward(uint256 total1, uint256 total2);//for test
    event Redemption(address account, address receiver, uint usdr, uint256 ara);
    event Mortgage(address account, address sender, uint256 ara, uint256 usdr);
    event RedemptionD(address account, uint256 usdr, uint256 ara);
    event MortgageD(address account, uint256 ara, uint256 usdr);
    event WithdrawReward(address account, uint256 amount);
}