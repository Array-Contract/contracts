pragma solidity >=0.5.0 <0.7.0;


interface IARAToken {
    /**
    * erc20 可选方法
    */
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
     * erc20 必须方法
     */
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address _address, uint256 _amount) external;
    function burn(address _address, uint256 _amount) external;

    /**
     * kpc
     */
    function unpausedTransfer(address recipient, uint256 amount) external returns (bool);
    function unpausedTransferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * 事件类型
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
