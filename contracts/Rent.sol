
// SPDX-License-Identifier: CC

pragma solidity ^0.8.16;
import "./IfAlchemistV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Rent{

  address vault;
  address token;
  address renter;
  address occupier;

  uint rent;
  uint public threshold;

  bytes32 irlRental_hash;

  bool guard;

  enum WorkflowStatus {
    Rental,
    PaiementProcessed,
    Liquidated
  }

  WorkflowStatus public workflowStatus;

  event PaiementOfRent(uint rent); 
  event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
  event ThresholdUpdated(uint newThreshold);
  event Debug(uint ts, uint x, uint th, uint rent);


  modifier onlyIfNotLiquidated() {
    require(workflowStatus != WorkflowStatus.Liquidated, "Rent: contract has been cancel");
    _;                   
  }

  constructor(address _vault, address _token ,address _renter, address _occupier, uint _rent){
    vault = _vault;
    token = _token;
    renter = _renter;
    occupier = _occupier;
    rent = _rent;
    threshold = 2000;
    irlRental_hash = keccak256("terms of rental contract");
    guard = false;
  }

  function payTheRent(uint amount) public onlyIfNotLiquidated{
    require(msg.sender == occupier, "Rent: access not granted");
    _update_threshold();
    uint _effective = threshold/1000 * rent;
    require(amount >= _effective, "Rent: the rent is not correct");
    IfAlchemistV2(vault).deposit(_effective, msg.sender);          
    workflowStatus = WorkflowStatus.PaiementProcessed;
    emit WorkflowStatusChange(WorkflowStatus.Rental, WorkflowStatus.PaiementProcessed);
    emit PaiementOfRent(_effective);
  }

  function claim_rent() external onlyIfNotLiquidated{
    require(msg.sender == renter, "Rent: access not granted");
    require(workflowStatus == WorkflowStatus.PaiementProcessed, "Rent: no claim");
    IfAlchemistV2(vault).craft_debt(rent, occupier);
    IERC20(token).transferFrom(occupier, renter, rent);
    workflowStatus = WorkflowStatus.Rental;
    emit WorkflowStatusChange(WorkflowStatus.PaiementProcessed, WorkflowStatus.Rental);
  }

  function _update_threshold() internal {
    uint balance;
    uint debt;
    uint _threshold; 
    uint ts = IfAlchemistV2(vault).balanceOf(vault);
    (balance, debt) = IfAlchemistV2(vault).get_accounts(occupier);
    if(balance!=0 || debt !=0){
      _threshold = 1000 + threshold - ((ts/1) / rent) * 1000;
      uint _x = 1000 * ts / rent;
      _threshold = 1000 + threshold - _x ;
      emit Debug(ts, _x, threshold, rent);
      emit ThresholdUpdated(_threshold);
      if(_threshold <= 1000){
        threshold = 0;  
      }
      else{ threshold = _threshold; }
    }
  }

  function getNextPaiement() public onlyIfNotLiquidated{
    _update_threshold();
  }

  function terminate() external returns(uint){
    require(msg.sender == occupier, "Rent: access not granted");
    uint amount = IfAlchemistV2(vault).liquidate(msg.sender);
    workflowStatus = WorkflowStatus.Liquidated;
    emit WorkflowStatusChange(WorkflowStatus.Rental, WorkflowStatus.Liquidated);
    return amount;
  }
}

