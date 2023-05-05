pragma solidity >=0.5.0 <0.7.0;


import "../../erc20/ERC20.sol";
import "../../access/WhitelistedRole.sol";
import "../common/MixinResolver.sol";


/**
 * ARAToken合约
 */
contract ARAToken is WhitelistedRole, ERC20, MixinResolver {
    
    constructor() ERC20("ARA", "ARA", 18) public {
        _mint(msg.sender, 2000000 * 1e18);//初始发行量
        addWhitelisted(msg.sender);
    }


    /**
     * @notice 通胀奖励生成
     * @param _address 发放地址地址
     * @param _amount 金额，未处理精度
     */
    function mint(address _address, uint256 _amount) public onlyWhitelisted {
        require(_address != address(0), "ARAToken: mint address is the zero address");
        _mint(_address, _amount);
        emit Mint(_address, _amount);
    }

    /**
     * @notice 通胀奖励生成
     * @param _address 发放地址地址
     * @param _amount 金额，未处理精度
     */
    function burn(address _address, uint256 _amount) public onlyWhitelisted {
        require(_address != address(0), "ARAToken: mint address is the zero address");
        _burn(_address, _amount);
        emit Burn(_address, _amount);
    }

    event Mint(address indexed _address, uint256 indexed amount);
    event Burn(address indexed _address, uint256 indexed amount);
}
