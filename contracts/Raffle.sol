// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

// from ChainLink Doc
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";


contract Raffle {

  // State variable
  uint256  private immutable i_entranceFee;
  address payable[] private s_players;

  // events
  event RaffleEnter(address indexed player);
  event RequestSent(unit256 requestId, unit32 numWords);
  event RequestFulfilled(unit256 requestId,unit256[] randomWords);

  struct RequestStatus{
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
  }

   mapping(uint256 => RequestStatus) public s_requests; // requestId --> requestStatus
   VRFCoordinatorV2Interface COORDINATOR;

   // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 numWords = 2;

    // Address LINK - hardcoded for Sepolia
    address linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    // address WRAPPER - hardcoded for Sepolia
    address wrapperAddress = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;



  constructor(uint256 entranceFee) VRFV2WrapperConsumerBase(linkAddress, wrapperAddress){
    i_entranceFee= entranceFee;
  }

  function requestRandomWords()
        external
        returns (uint256 requestId)
    {
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            exists:true,
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (bool fulfilled, uint256[] memory randomWords)
    {
    require(s_requests[_requestId].exists, "request not found");
    RequestStatus memory request = s_requests[_requestId];
    return (request.fulfilled, request.randomWords);
    }


  function enterRaffle(){
    if(msg.vale < i_entranceFee){revert Raffle_NotEnoughETHEntered();}
    //neddes to wrap with payable as s_players is paybale
    s_players.push(payable(msg.sender));
    emit RaffleEnter(msg.sender);
  }

  function getEntrancefee() public view returns(uint256){

    return i_entranceFee;
  }

  function getPlayer(unit256 index) public view returns (address){

    return s_players[index];
  }

}