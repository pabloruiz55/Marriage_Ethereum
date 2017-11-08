pragma solidity ^0.4.8;
import "./MarriageRegistry.sol";

contract Marriage{

  address public spouseA;
  address public spouseB;
  uint public marriageDate;
  uint public proposalDate;
  MarriageRegistry marriageRegistry;

  //Divorce variables
  bool public spouseARequestedDivorce = false;
  bool public spouseBRequestedDivorce = false;
  uint public divorceDate;

  uint constant PROPOSAL_EXPIRY_TIME = 3 days;

  enum MarriageStatus {None, Proposed, Married}
  MarriageStatus public marriageStatus = MarriageStatus.None;

  //Constructor can only be called by the MarriageRegistry.
  //If someone wants to initiatiate a marriage proposal, it has to go through the registry.

  // The person initiating the contract selects another person to "propose to"
  // If both of them can marry (determined by their current marital status, E.G: they are not already married)
  // we add the marriage proposal to the Marriage Registry.
  function Marriage(address _registryAddress, address _marryFrom, address _marryTo) public {
    //Constructor can only be called by the MarriageRegistry.
    require(msg.sender == _registryAddress);

    marriageRegistry = MarriageRegistry(_registryAddress);

    spouseA = _marryFrom;
    spouseB = _marryTo;
    marriageStatus = MarriageStatus.Proposed;
    proposalDate = now;
    marriageRegistry.addMarriageToRegistry(this, spouseA, spouseB, proposalDate);
  }

  // Called by SpouseA, the person who proposed the marriage in case he/she got a cold feet.
  // Has to be called before SpouseB acts upon the proposal.
  function withdrawProposal() public {
    require(msg.sender == spouseA);
    require(marriageStatus == MarriageStatus.Proposed);

    //Do the cleanup in the registry first
    marriageRegistry.eliminateMarriage(this);

    selfdestruct(spouseA);
  }

  ////////////////////////////////
  // END OF SpouseA Functions ////
  ////////////////////////////////

  ///////////////////////////////
  // SpouseB functions (the receiving end of the proposal)
  ///////////////////////////////

  // If the receiving end of the proposal calls this function, they get married
  // Congrats!!
  function acceptProposal() public {
    //The person calling the function should be who received the proposal;
    require(msg.sender == spouseB);
    require(marriageStatus == MarriageStatus.Proposed);

    marriageDate = now;
    marriageStatus = MarriageStatus.Married;
    marriageRegistry.performMarriage(this);
  }


  // The receiving end of the proposal can call this function to reject the proposal.
  // For example, someone else could propose to the wrong address, if someone proposed
  // to me by mistake (or I suddenly realize I don't want to get married) I can reject it.
  function rejectProposal() public {
    //The person calling the function should be who received the proposal;
    require(msg.sender == spouseB);
    require(marriageStatus == MarriageStatus.Proposed);

    //Do the cleanup in the registry first
    marriageRegistry.eliminateMarriage(this);

    //If the person that received the proposal rejects it, we selfdestruct this contract after doing some cleanup.
    selfdestruct(spouseA);
  }

  ////////////////////////////////
  // END OF SpouseB Functions ////
  ////////////////////////////////

  //Called by canGetMarried().
  //This function adds an expiration date to the proposal.
  //Useful to prevent someone from proposing indiscriminately and having those people
  //manually reject each proposal.
  function proposalExpired() public returns(bool){
    require(msg.sender == address(marriageRegistry));
    if(now < proposalDate + PROPOSAL_EXPIRY_TIME ){
      return false;
    }else{
      expireProposal();
      return true;
    }
  }

  // Called by checkProposalExpiration if the proposal expired;
  function expireProposal() internal {
    require(marriageStatus == MarriageStatus.Proposed);

    //Do the cleanup in the registry first
    marriageRegistry.eliminateMarriage(this);

    selfdestruct(spouseA);
  }

  //Any of the two spouses can file for a divorce at any moment.
  // When both request the divorce, this contract gets destroyed, eliminating the marriage.
  function requestDivorce() public{
    require(msg.sender == spouseA || msg.sender == spouseB);
    require(marriageStatus == MarriageStatus.Married);
    if(msg.sender == spouseA)
      spouseARequestedDivorce = true;
    if(msg.sender == spouseB)
      spouseBRequestedDivorce = true;

    if(spouseARequestedDivorce && spouseBRequestedDivorce){
      divorceDate = now;

      //Do the cleanup in the registry first
      marriageRegistry.performDivorce(this); //Logs divorce
      marriageRegistry.eliminateMarriage(this);

      selfdestruct(spouseA);
    }
  }

  // Cancel the request for divorce.
  function cancelRequestForDivorce() public{
    require(msg.sender == spouseA || msg.sender == spouseB);
    require(marriageStatus == MarriageStatus.Married);
    if(msg.sender == spouseA)
      spouseARequestedDivorce = false;
    if(msg.sender == spouseB)
      spouseBRequestedDivorce = false;
  }

}
