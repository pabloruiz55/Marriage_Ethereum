pragma solidity ^0.4.8;

import "./Marriage.sol";

contract MarriageRegistry{

  mapping (address => Marriage) marriageBySpouse;
  mapping (address => Marriage) marriages;

  ///Events
  event E_Proposals(address indexed _spouseA, address indexed _spouseB, uint _proposalDate);
  event E_Marriages(address indexed _spouseA, address indexed _spouseB, uint _marriageDate);
  event E_Divorces(address indexed _spouseA, address indexed _spouseB, uint _divorceDate);

  function proposeMarriage(address _marryTo) public{
    require (_marryTo != address(0));
    //They can only initiatiate a marriage process if neither is married already.
    require (canGetMarried(msg.sender) && canGetMarried(_marryTo));

    new Marriage(this, msg.sender, _marryTo);

  }

  // Called by the marriage contract
  function addMarriageToRegistry(Marriage _marriage, address _spouseA, address _spouseB, uint _proposalDate) external{
    require (_spouseA != address(0));
    require (_spouseB != address(0));

    //We add the contract to the mapping to be able to look it up with either spouse;
    marriageBySpouse[_spouseA] = _marriage;
    marriageBySpouse[_spouseB] = _marriage;

    marriages[address(_marriage)] = _marriage;

    E_Proposals(_spouseA, _spouseB, _proposalDate);
  }

  //Called by marriage contract to log marriage and divorce events
  function performMarriage(Marriage _marriage) external{
    require (msg.sender == address(_marriage));
    E_Marriages(_marriage.spouseA(), _marriage.spouseB(), _marriage.marriageDate());
  }

  function performDivorce(Marriage _marriage) external{
    require (msg.sender == address(_marriage));
    E_Divorces(_marriage.spouseA(), _marriage.spouseB(), _marriage.divorceDate());
  }

  // This function can only be called by the Marriage contract in the event the marriage
  // get's cancelled, either by the person who porposed it withdrawing the proposal or the
  // receiver rejecting it.
  // Also called when divorced.
  function eliminateMarriage(Marriage _marriage) external{
    require (msg.sender == address(_marriage));
    delete(marriageBySpouse[_marriage.spouseA()]);
    delete(marriageBySpouse[_marriage.spouseB()]);
    delete(marriages[address(_marriage)]);
  }

  //This function determines if any person can get married.
  //We are just checking in the registry if the person is already married or not
  //Later on, the registry itself could establish ground-rules about who can marry
  // E.G.: If the person is underage, or if they live in certain country, etc.
  function canGetMarried(address _spouse) internal returns (bool){
    Marriage _m = Marriage(getMarriageContract(_spouse));

    //If there's no associated contract, the person can marry.
    if(address(_m) == address(0) || _m.marriageStatus() == Marriage.MarriageStatus.None){
      return true;
    }else{
      if(_m.marriageStatus() == Marriage.MarriageStatus.Proposed){
        //Use this opportunity to expire a pending proposal if the proposal period ended
        //If there's an associated contract from a previous proposal and the proposal expired, they can marry.
        return (_m.proposalExpired());
      }else {
        return false;
      }
    }
  }

  ////////////////////////////////////////////////
  //Query functions to get data about marriages //
  ////////////////////////////////////////////////

  function getMarriageContract(address spouse) view public returns (address){
    return (marriageBySpouse[spouse]);
  }

  function getMarriageCertificate(address marriageAddress) view public returns (address, address, uint){
    Marriage _m = marriages[marriageAddress];
    require(_m.marriageStatus() == Marriage.MarriageStatus.Married);
    return (_m.spouseA(),_m.spouseB(),_m.marriageDate());
  }

  //Given two persons, return if they are married to each other.
  function areMarried(address _spouseA, address _spouseB) view public returns (bool){
    Marriage _m = Marriage(getMarriageContract(_spouseA));
    //If there's a contract that contains the spouse
    if(address(_m) == address(0)){
      return false;
    }else{
      if(_m.marriageStatus() == Marriage.MarriageStatus.Married &&
        (_spouseA == _m.spouseA() && _spouseB == _m.spouseB())
        || (_spouseA == _m.spouseB() && _spouseB == _m.spouseA()))
      {
        return true;
      }else{
        return false;
      }
    }
  }

  //Given one person, return if that person is married.
  function isMarried(address _spouse) view public returns (bool){
    Marriage _m = Marriage(getMarriageContract(_spouse));
    //If there's a contract that contains the spouse
    if(address(_m) == address(0)){
      return false;
    }else{
      if(_m.marriageStatus() == Marriage.MarriageStatus.Married){
        return true;
      }else{
        return false;
      }
    }
  }

  //Given one person, return who that person is married to
  function marriedTo(address _spouse) view public returns (address){
    Marriage _m = Marriage(getMarriageContract(_spouse));
    //If there's a contract that contains the spouse
    if(address(_m) == address(0)){
      return address(0);
    }else{
      if(_m.marriageStatus() == Marriage.MarriageStatus.Married){
        if(_m.spouseA() == _spouse)
          return _m.spouseB();
        else if(_m.spouseB() == _spouse)
          return _m.spouseA();
      }else{
        return address(0);
      }
    }
  }
}
