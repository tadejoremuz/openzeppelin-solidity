pragma solidity ^ 0.4.24;

import "../Crowdsale.sol";
import "../../math/SafeMath.sol";
import "../../ownership/Ownable.sol";
import "../validation/CappedCrowdsale.sol";


/**
  * @title CapStagedCrowdsale
  * @dev Extension of Crowdsale contract that changes the price of tokens regarding of raised ETH. Each stage of crowdsale is defined in StageLimit (cap limit for the stage) and stageRate (stage rate)
  * Stages must be inserted from first to last with increasing stageLimit.
  */
contract CapStagedCrowdsale is CappedCrowdsale {
  using SafeMath for uint256;

  struct Stage {
    uint256 limit;
    uint256 rate;
  }

  Stage[] public stages;

  /**
   * @param _initialRate Number of tokens a buyer gets per wei - default parameter for crowdsale contract
   * @param _wallet Address where funds should be transferred
   * @param _token ERC20 token address
   * @param _cap max cap that can be reached in wei
   * @param _stageLimits Array of stage limits in wei
   * @param _stageRates Array of rates for every stage
   */
  constructor
  (
    uint256 _initialRate,
    address _wallet,
    ERC20 _token,
    uint256 _cap,
    uint256[] _stageLimits,
    uint256[] _stageRates
  )
    CappedCrowdsale(_cap)
    Crowdsale(_initialRate, _wallet, _token)
    public
  {
    require(_stageLimits.length == _stageRates.length);
    require(_stageLimits.length > 0);
    for (uint256 i = 0; i < _stageLimits.length; i++) {
      if (i+1 < _stageLimits.length) {
        if (_stageLimits[i] < _stageLimits[i+1]) {
          stages.push(Stage({
            limit: _stageLimits[i],
            rate: _stageRates[i]
          }));
        }
      } else {
        if (_stageLimits[i] > _stageLimits[i-1]) {
          stages.push(Stage({
            limit: _stageLimits[i],
            rate: _stageRates[i]
          }));
        } else {
          revert();
        }
      }
    }
  }

  /**
    * @dev Function for getting current rate of the stage.
    * @return uint256 Current rate of the stage
    */
  function getRate() public view returns(uint256) {
    for (uint256 i = 0; i < stages.length; i++) {
      if (stages[stages.length - 1].limit >= weiRaised) {
        if (stages[i].limit >= weiRaised) {
          return stages[i].rate;
        }
      } else {
        return stages[stages.length - 1].rate;
      }
    }
  }

  /**
    * @dev Overrides parent method taking into account variable rate.
    * @param _weiAmount The value in wei to be converted into tokens
    * @return The number of tokens _weiAmount wei will buy at current stage
    */
  function _getTokenAmount(uint256 _weiAmount) internal view returns(uint256) {
    uint256 currentRate = getRate();
    return currentRate.mul(_weiAmount);
  }
}
