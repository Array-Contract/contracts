pragma solidity >=0.5.0 <0.7.0;

import "../../erc20/ERC20Proxyable.sol";
import "../../library/SafeMath.sol";
import "../../interface/IERC20.sol";
import "../common/MixinResolver.sol";

contract Mortgage is ERC20Proxyable, MixinResolver {

    using SafeMath for uint;

    uint totalMortgage;

    address public systemReward;

    constructor(string memory name, string memory symbol, uint8 decimals)
    ERC20Proxyable(name, symbol, decimals)
    public
    {
    }

    function setSystemReward(address _systemReward) onlyOwner public {
        systemReward = _systemReward;
        emitSystemRewardChange(systemReward);
    }

    /**
    * 抵押进入
    */
    function mortgage(address account, address sender, uint256 amount) onlyFoundry public returns (bool) {
        require(account != address(0), "Mortgage: transfer to the zero address");
        require(amount > 0, "Mortgage: transfer amount must bigger than zero");
        totalMortgage = totalMortgage.add(amount);
        database().setBalance(account, database().balanceOf(account).add(amount));
        //将源plat的余额划转到固定池;
        araToken().transferFrom(sender, address(this), amount);
        //划转事件
        noteTransfer(sender, address(this), amount);
        return true;
    }

    /**
    * 赎回
    */
    function redemption(address account, uint256 amount) onlyFoundry public returns (bool) {
        require(account != address(0), "Mortgage: transfer to the zero address");
        require(amount > 0, "Mortgage: transfer amount must bigger than zero");
        totalMortgage = totalMortgage.sub(amount);
        uint256 old = database().balanceOf(account);
        require(old >= amount, "Mortgage: not sufficient funds");
        database().setBalance(account, old.sub(amount));
        //划转对应amount回account地址;
        araToken().transfer(account, amount);
        //划转事件
        noteTransfer(address(this), account, amount);
        return true;
    }

    /**
    * 赎回
    */
    function redemptionTo(address account, address receiver, uint256 amount) onlyFoundry public returns (bool) {
        require(account != address(0), "Mortgage: account is zero address");
        require(receiver != address(0), "Mortgage: transfer to the zero address");
        require(amount > 0, "Mortgage: transfer amount must bigger than zero");
        totalMortgage = totalMortgage.sub(amount);
        uint256 old = database().balanceOf(account);
        require(old >= amount, "Mortgage: not sufficient funds");
        database().setBalance(account, old.sub(amount));
        //划转对应amount回receiver地址;
        araToken().transfer(receiver, amount);
        //划转事件
        noteTransfer(address(this), receiver, amount);
        return true;
    }

    /**
    * 赎回
    */
    function redemptionAll(address account, address receiver) onlyFoundry public returns (uint256) {
        require(account != address(0), "Mortgage: account is zero address");
        require(receiver != address(0), "Mortgage: transfer to the zero address");
        uint256 old = database().balanceOf(account);
        totalMortgage = totalMortgage.sub(old);

        database().setBalance(account, 0);
        //划转对应amount回receiver地址;
        araToken().transfer(receiver, old);
        //划转事件
        noteTransfer(address(this), receiver, old);
        return old;
    }

    /**
    * 赎回奖励
    */
    function redemptionReward(address account, uint256 amount) onlyFoundry public returns (bool) {
        require(account != address(0), "Mortgage: transfer to the zero address");
        require(amount > 0, "Mortgage: transfer amount must bigger than zero");
        totalMortgage = totalMortgage.sub(amount);
        uint256 old = database().balanceOf(account);
        require(old >= amount, "Mortgage: not sufficient funds");
        database().setBalance(account, old.sub(amount));
        //划转对应amount回account地址;
        araToken().transfer(account, amount);
        //划转事件
        noteTransfer(address(this), account, amount);
        return true;
    }

    /**
     * 系统账户奖励划入
     */
    function transferReward(uint256 amount) onlyFoundry public {
        require(amount > 0, "Mortgage: transfer amount must bigger than zero");
        totalMortgage = totalMortgage.add(amount);
        database().setBalance(address(distribution()), database().balanceOf(address(distribution())).add(amount));
        //ara增发铸币
        araMinter().mintMortgageReward(address(this), amount);
        //分发
        foundry().distribute(amount);
        //划转事件
        noteTransfer(systemReward, address(this), amount);
    }

    /**
    *  清算,将account对应的ARA划转到拍卖合约
    */
    function innerTransfer(address account, address receiver, uint256 amount) onlyFoundryOrFeePool public returns (bool) {
        require(account != address(0), "Mortgage: transfer to the zero address");
        require(amount > 0, "Mortgage: transfer amount must bigger than zero");
        uint256 old = database().balanceOf(account);
        require(old >= amount, "Mortgage: not sufficient funds");
        database().setBalance(account, old.sub(amount));
        database().setBalance(receiver, database().balanceOf(receiver).add(amount));
        //划转事件
        noteTransfer(address(this), receiver, amount);
        return true;
    }

    /** 扩展调用transferFrom */
    function innerTransferFrom(address from, address to, uint256 amount) onlyFoundry public returns (bool) {
        innerTransfer(from, to, amount);
        database().setAllowance(from, to, database().allowance(from, to).sub(amount, "Mortgage: transfer amount exceeds allowance"));
        noteApproval(from, to, amount);
        return true;
    }

    /**
    *  获取总抵押的ARA
    */
    function getTotalMortgage()
    public view
    returns (uint)
    {
        return totalMortgage;
    }

    modifier onlyFoundry {
        require(msg.sender == address(foundryExtend()), "Mortgage: Only foundryExtend Authorised");
        _;
    }

    modifier onlyFoundryOrFeePool {
        require(msg.sender == address(foundryExtend()), "Mortgage: Only foundryExtend or feePool Authorised");
        _;
    }

    bytes32 constant SYSTEM_REWARD_CHANGE_SIG = keccak256("SystemRewardChange(address)");

    function emitSystemRewardChange(address account) internal {
        proxy().note(abi.encode(account), 2, SYSTEM_REWARD_CHANGE_SIG, account.encode(), 0, 0);
    }
}