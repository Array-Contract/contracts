pragma solidity >=0.5.0 <0.7.0;


import "../../access/WhitelistedRole.sol";
import "../common/MixinResolver.sol";
import "../../library/SafeMath.sol";


/**
 * ARAMinter合约
 */
contract ARAMinter is WhitelistedRole, MixinResolver {
    using SafeMath for uint256;

    uint256 public total = 0;
    uint256 public mortgageReward = 0;
    uint256 public liquidity = 0;
    uint256 public rankReward = 0;
    uint256 public others = 0;
    
    constructor() public {}


    /**
     * @notice 质押奖励通胀
     * @param _address 发放地址地址
     * @param _amount 金额，未处理精度
     */
    function mintMortgageReward(address _address, uint256 _amount) public onlyWhitelisted {
        require(_address != address(0), "ARAMinter: mint address is the zero address");
        total = total.add(_amount);
        mortgageReward = mortgageReward.add(_amount);
        araToken().mint(_address, _amount);

        emit MortgageReward(_address, _amount);
    }

    /**
     * @notice 增加流动性通胀
     * @param _address 发放地址地址
     * @param _amount 金额，未处理精度
     */
    function mintLiquidity(address _address, uint256 _amount) public onlyWhitelisted {
        require(_address != address(0), "ARAMinter: mint address is the zero address");
        total = total.add(_amount);
        liquidity = liquidity.add(_amount);
        araToken().mint(_address, _amount);

        emit Liquidity(_address, _amount);
    }

    /**
     * @notice 增加排名奖励通胀
     * @param _address 发放地址地址
     * @param _amount 金额，未处理精度
     */
    function mintRankReward(address _address, uint256 _amount) public onlyWhitelisted {
        require(_address != address(0), "ARAMinter: mint address is the zero address");
        total = total.add(_amount);
        rankReward = rankReward.add(_amount);
        araToken().mint(_address, _amount);

        emit RankReward(_address, _amount);
    }

    /**
     * @notice 其他通胀
     * @param _address 发放地址地址
     * @param _amount 金额，未处理精度
     */
    function mintOthers(address _address, uint256 _amount) public onlyWhitelisted {
        require(_address != address(0), "ARAMinter: mint address is the zero address");
        total = total.add(_amount);
        others = others.add(_amount);
        araToken().mint(_address, _amount);
    }

    event RankReward(address account, uint256 amount); //代理地址，发放数量（18位）
    event Liquidity(address account, uint256 amount); //地址，发放数量（18位）
    event MortgageReward(address account, uint256 amount); //地址，发放数量（18位）
}
