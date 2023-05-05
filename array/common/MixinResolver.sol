pragma solidity >=0.5.0 <0.7.0;


import "../../interface/IERC20.sol";
import "../../common/AddressResolver.sol";
import "../interface/IFoundry.sol";
import "../interface/IFoundryExtend.sol";
import "../interface/ICombo.sol";
import "../interface/IARAToken.sol";
import "../interface/IFeePool.sol";
import "../interface/IPrivatePlacement.sol";
import "../interface/IExchangeRates.sol";
import "../interface/IRewardEscrow.sol";
import "../interface/IRewardDistribution.sol";
import "../interface/IARAMortgage.sol";
import "../interface/IARAMinter.sol";
import "../interface/IRelationship.sol";
import "../interface/IProxyFee.sol";



/**
* 系统内的ENS服务
*/
contract MixinResolver is AddressResolver {

    /**
     * ARA原始合约
     */
    function araToken() public view returns (IARAToken) {
        return IARAToken(resolver().addr("ARAToken", "MixinResolver: missing araToken address"));
    }

    /**
     * ARA映射合约
     */
    function foundry() public view returns (IFoundry) {
        return IFoundry(resolver().addr("Foundry", "MixinResolver: missing foundry address"));
    }

    /**
     * ARA映射合约(扩展)
     */
    function foundryExtend() public view returns (IFoundryExtend) {
        return IFoundryExtend(resolver().addr("FoundryExtend", "MixinResolver: missing foundry-extend address"));
    }

    /**
     * usdr合约
     */
    function usdr() public view returns (ICombo) {
        return ICombo(resolver().addr("USDR", "MixinResolver: missing usdr address"));
    }

    /**
     * 系统行情合约
     */
    function rates() public view returns (IExchangeRates) {
        return IExchangeRates(resolver().addr("ExchangeRates", "MixinResolver: missing exchange-rates address"));
    }

    /**
     * 系统奖励托管合约
     */
    function reward() public view returns (IRewardEscrow) {
        return IRewardEscrow(resolver().addr("RewardEscrow", "MixinResolver: missing reward-escrow address"));
    }

    /**
     * 系统奖励分发合约
     */
    function distribution() public view returns (IRewardDistribution) {
        return IRewardDistribution(resolver().addr("RewardDistribution", "MixinResolver: missing reward-distribution address"));
    }

    /**
    * 质押ARA合约
    */
    function mortgage() public view returns (IARAMortgage) {
        return IARAMortgage(resolver().addr("Mortgage", "MixinResolver: missing mortgage address"));
    }

    /**
     * minter
     */
    function araMinter() public view returns (IARAMinter) {
        return IARAMinter(resolver().addr("ARAMinter", "MixinResolver: missing araMinter address"));
    }

}